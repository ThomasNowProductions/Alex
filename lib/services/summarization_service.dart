import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:crypto/crypto.dart' show sha256;
import '../models/conversation_message.dart';
import '../models/memory_segment.dart';
import '../utils/logger.dart';

// Simple cache entry for summarization results
class _SummaryCache {
  final String summary;
  final DateTime timestamp;

  _SummaryCache(this.summary, this.timestamp);

  bool get isExpired => DateTime.now().difference(timestamp) > SummarizationService._cacheExpiry;
}

class SummarizationService {
   static String get _baseUrl => dotenv.env['OLLAMA_BASE_URL'] ?? 'https://ollama.com/api';
   static String get _apiKey => dotenv.env['OLLAMA_API_KEY'] ?? '';
   static String get _model => dotenv.env['OLLAMA_MODEL'] ?? 'deepseek-v3.1:671b';

   // Simple in-memory cache to avoid redundant API calls
   static final Map<String, _SummaryCache> _cache = {};
   static const Duration _cacheExpiry = Duration(hours: 1);

   // Cache for the summarization prompt
   static String? _cachedPrompt;

   // Configuration constants
   static const int _maxConversationLength = 4000; // Maximum conversation length for token efficiency
   static const int _cacheCleanupThreshold = 10; // Cache size threshold before cleanup

  static Future<String> summarize(
    List<ConversationMessage> messages, {
    List<MemorySegment>? relevantMemories,
    String? previousSummary,
  }) async {
    AppLogger.d('Starting conversation summarization');
    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      AppLogger.w('OLLAMA_API_KEY not properly configured for summarization');
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    if (messages.isEmpty) {
      AppLogger.i('No messages to summarize, returning default message');
      return previousSummary ?? 'No conversation to summarize.';
    }

    // Clean up expired cache entries periodically
    if (_cache.length > _cacheCleanupThreshold) {
      _cleanupExpiredCache();
    }

    // Check cache first to avoid redundant API calls
    final cacheKey = _generateCacheKey(messages, relevantMemories: relevantMemories);
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.i('Using cached summarization result');
        return cached.summary;
      } else {
        _cache.remove(cacheKey);
      }
    }

    try {
      AppLogger.d('Formatting ${messages.length} messages for summarization');
      // Create a formatted conversation string for the summarizer
      final conversationText = _formatConversationForSummary(
        messages,
        relevantMemories: relevantMemories,
        previousSummary: previousSummary,
      );

      // Load the summarization prompt
      final prompt = await _getSummarizationPrompt(
        useEnhanced: relevantMemories != null && relevantMemories.isNotEmpty,
        isIncremental: previousSummary != null && previousSummary.isNotEmpty,
      );

      AppLogger.d('API POST $_baseUrl/chat');
      final stopwatch = Stopwatch()..start();

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': conversationText}
          ],
          'stream': false,
        }),
      );

      stopwatch.stop();
      AppLogger.i('Summarization API call took ${stopwatch.elapsed.inMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely extract the summary content with null checking
        if (data is Map<String, dynamic> &&
            data.containsKey('message') &&
            data['message'] is Map<String, dynamic> &&
            data['message'].containsKey('content')) {
          final content = data['message']['content'];
          if (content is String) {
            final summary = content.trim();
            AppLogger.i('Conversation summarization completed successfully, length: ${summary.length}');

            // Cache the result for future use
            _cache[cacheKey] = _SummaryCache(summary, DateTime.now());

            return summary;
          } else {
            AppLogger.e('API response content is not a string: ${content.runtimeType}');
            throw Exception('Invalid response format: content is not a string');
          }
        } else {
          AppLogger.e('Unexpected API response structure: missing message.content');
          throw Exception('Invalid API response format: missing message.content');
        }
      } else {
        // Log the original technical error for debugging
        AppLogger.e('Summarization API request failed with status: ${response.statusCode} - ${response.body}');

        // Check for hourly limit exceeded (402 status)
        if (response.statusCode == 402) {
          AppLogger.e('Hourly usage limit reached - 402 error from summarization API');
          throw Exception("I'm so sorry, but your hourly limit is reached.");
        }

        throw Exception('Failed to get summarization: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Error during conversation summarization', e);
      throw Exception('Error connecting to summarization API: $e');
    }
  }

  static List<ConversationMessage> _filterMessagesForSummarization(List<ConversationMessage> messages) {
    return messages.where((message) {
      // Filter out very short messages (less than 3 characters)
      if (message.text.trim().length < 3) return false;

      // Filter out common system/greeting messages that don't add value
      final lowerText = message.text.toLowerCase();
      if (lowerText.contains('hello') && message.text.length < 20) return false;
      if (lowerText.contains('hi') && message.text.length < 15) return false;
      if (lowerText.contains('thanks') && message.text.length < 20) return false;
      if (lowerText.contains('thank you') && message.text.length < 25) return false;

      return true;
    }).toList();
  }

  static String _formatConversationForSummary(
    List<ConversationMessage> messages, {
    List<MemorySegment>? relevantMemories,
    String? previousSummary,
  }) {
    AppLogger.d('Formatting conversation with memory context');

    final filteredMessages = _filterMessagesForSummarization(messages);

    if (filteredMessages.isEmpty) {
      return 'No meaningful conversation to summarize.';
    }

    final buffer = StringBuffer();

    // Add memory context if available
    if (relevantMemories != null && relevantMemories.isNotEmpty) {
      buffer.writeln('RELEVANT MEMORIES AND CONTEXT:');
      buffer.writeln('The following memories may be relevant to understanding this conversation:\n');

      for (var i = 0; i < min(relevantMemories.length, 5); i++) {
        final memory = relevantMemories[i];
        buffer.writeln('Memory ${i + 1} (${memory.type}, importance: ${memory.importance.toStringAsFixed(2)}):');
        buffer.writeln('${memory.content}');
        buffer.writeln();
      }
      buffer.writeln('--- End of relevant memories ---\n');
    }

    // Add previous summary for incremental summarization
    if (previousSummary != null && previousSummary.isNotEmpty) {
      buffer.writeln('PREVIOUS SUMMARY:');
      buffer.writeln('This is the summary of the conversation so far. Please update it with the new messages below:\n');
      buffer.writeln(previousSummary);
      buffer.writeln('\n--- End of previous summary ---\n');
      buffer.writeln('NEW MESSAGES TO INTEGRATE:');
    } else {
      buffer.writeln('CURRENT CONVERSATION TO ANALYZE:');
    }

    buffer.writeln('Please summarize this conversation in the context of the above memories:\n\n');

    for (var i = 0; i < filteredMessages.length; i++) {
      final message = filteredMessages[i];
      final speaker = message.isUser ? 'User' : 'Alex';
      buffer.writeln('$speaker: ${message.text}');
      buffer.writeln();
    }

    // Apply length limit to prevent excessive token usage
    final formattedText = buffer.toString();

    if (formattedText.length > _maxConversationLength) {
      AppLogger.d('Memory-aware conversation too long (${formattedText.length}), truncating for token efficiency');
      return '${formattedText.substring(0, _maxConversationLength - 100)}\n\n[Conversation truncated for efficiency]';
    }

    AppLogger.d('Memory-aware conversation formatted for summarization, total length: ${formattedText.length}');
    return formattedText;
  }

  static Future<String> _loadSummarizationPrompt() async {
    try {
      final jsonString = await rootBundle.loadString('assets/summarization_prompt.json');
      final jsonMap = json.decode(jsonString);

      // Check if the expected key exists in the JSON
      if (jsonMap is Map<String, dynamic> && jsonMap.containsKey('summarizationPrompt')) {
        final prompt = jsonMap['summarizationPrompt'];
        if (prompt is String && prompt.isNotEmpty) {
          return prompt;
        } else {
          AppLogger.w('summarizationPrompt key exists but is not a valid string, using fallback');
        }
      } else {
        AppLogger.w('summarizationPrompt key not found in JSON file, using fallback');
      }
    } catch (e) {
      AppLogger.e('Failed to load summarization prompt from JSON, using fallback', e);
    }

    // Fallback prompt in case JSON file fails to load or doesn't contain expected key
    return 'Analyze this conversation and return a JSON summary with key topics, important facts, user preferences, goals, and a brief summary paragraph. Focus on meaningful content only. Return only valid JSON.';
  }

  static Future<String> _getSummarizationPrompt({
    bool useEnhanced = false,
    bool isIncremental = false,
  }) async {
    // Load and cache the prompt if not already cached
    if (_cachedPrompt == null) {
      _cachedPrompt = await _loadSummarizationPrompt();
      AppLogger.d('Loaded summarization prompt from JSON file');
    }

    // Determine which prompt to use
    if (isIncremental) {
      return 'Please update the previous summary with the new messages, keeping the key information.';
    }
    if (useEnhanced) {
      return 'Analyze this conversation in the context of the provided memories. Return a JSON summary with key topics, important facts, user preferences, goals, and a brief summary paragraph that connects current conversation with relevant memories. Focus on meaningful content and how it relates to existing knowledge. Return only valid JSON.';
    }
    return _cachedPrompt!;
  }

  static String _generateCacheKey(
    List<ConversationMessage> messages, {
    List<MemorySegment>? relevantMemories,
  }) {
    // Create a unique hash based on message content to avoid collisions
    // Include message count, total length, and content hash for better uniqueness
    final messageCount = messages.length;
    final totalLength = messages.fold(0, (sum, msg) => sum + msg.text.length);

    // Create a content hash from all message texts
    final contentString = messages.map((msg) => '${msg.isUser}:${msg.text}').join('|');
    final contentBytes = utf8.encode(contentString);
    final contentHash = sha256.convert(contentBytes).toString().substring(0, 16);

    // Include memory context in cache key
    final memoryHash = relevantMemories == null || relevantMemories.isEmpty
        ? 'no-memories'
        : sha256.convert(utf8.encode(relevantMemories.map((m) => m.id).join(','))).toString().substring(0, 8);

    return '$messageCount:$totalLength:$contentHash:$memoryHash';
  }

  static void _cleanupExpiredCache() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.d('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear the cached prompt to force reload from JSON file
  /// Useful for testing prompt changes or if JSON file is updated
  static void clearPromptCache() {
    _cachedPrompt = null;
    AppLogger.d('Cleared summarization prompt cache');
  }

  /// Clear all cached summarization results
  /// Useful for wiping all memories when "Destroy Alex" is pressed
  static void clearAllMemories() {
    _cache.clear();
    AppLogger.i('Cleared all cached summarization memories');
  }

  /// Summarize conversation with memory context for better understanding
  static Future<String> summarizeWithMemoryContext(
    List<ConversationMessage> messages,
    List<MemorySegment> relevantMemories,
  ) async {
    AppLogger.d('Starting memory-aware conversation summarization');

    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      AppLogger.w('OLLAMA_API_KEY not properly configured for summarization');
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    if (messages.isEmpty) {
      AppLogger.i('No messages to summarize, returning default message');
      return 'No conversation to summarize.';
    }

    // Clean up expired cache entries periodically
    if (_cache.length > _cacheCleanupThreshold) {
      _cleanupExpiredCache();
    }

    // Check cache first to avoid redundant API calls
    final cacheKey = _generateMemoryAwareCacheKey(messages, relevantMemories);
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.i('Using cached memory-aware summarization result');
        return cached.summary;
      } else {
        _cache.remove(cacheKey);
      }
    }

    try {
      AppLogger.d('Formatting ${messages.length} messages with ${relevantMemories.length} memories for summarization');

      // Create enhanced conversation text with memory context
      final conversationText = _formatConversationWithMemoryContext(messages, relevantMemories);

      // Load the enhanced summarization prompt
      final prompt = await _loadEnhancedSummarizationPrompt();

      AppLogger.d('API POST $_baseUrl/chat');
      final stopwatch = Stopwatch()..start();

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': prompt
            },
            {
              'role': 'user',
              'content': conversationText
            }
          ],
          'stream': false,
        }),
      );

      stopwatch.stop();
      AppLogger.i('Memory-aware summarization API call took ${stopwatch.elapsed.inMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> &&
            data.containsKey('message') &&
            data['message'] is Map<String, dynamic> &&
            data['message'].containsKey('content')) {

          final content = data['message']['content'];
          if (content is String) {
            final summary = content.trim();
            AppLogger.i('Memory-aware conversation summarization completed successfully, length: ${summary.length}');

            // Cache the result for future use
            _cache[cacheKey] = _SummaryCache(summary, DateTime.now());

            return summary;
          } else {
            AppLogger.e('API response content is not a string: ${content.runtimeType}');
            throw Exception('Invalid response format: content is not a string');
          }
        } else {
          AppLogger.e('Unexpected API response structure: missing message.content');
          throw Exception('Invalid API response format: missing message.content');
        }
      } else {
        if (response.statusCode == 402) {
          AppLogger.e('Hourly usage limit reached - 402 error from summarization API');
          throw Exception("I'm so sorry, but your hourly limit is reached.");
        }

        throw Exception('Failed to get summarization: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Error during memory-aware conversation summarization', e);
      throw Exception('Error connecting to summarization API: $e');
    }
  }

  /// Format conversation with memory context for better summarization
  static String _formatConversationWithMemoryContext(
    List<ConversationMessage> messages,
    List<MemorySegment> relevantMemories,
  ) {
    AppLogger.d('Formatting conversation with memory context');

    final filteredMessages = _filterMessagesForSummarization(messages);

    if (filteredMessages.isEmpty) {
      return 'No meaningful conversation to summarize.';
    }

    final buffer = StringBuffer();

    // Add memory context if available
    if (relevantMemories.isNotEmpty) {
      buffer.writeln('RELEVANT MEMORIES AND CONTEXT:');
      buffer.writeln('The following memories may be relevant to understanding this conversation:\n');

      for (var i = 0; i < min(relevantMemories.length, 5); i++) {
        final memory = relevantMemories[i];
        buffer.writeln('Memory ${i + 1} (${memory.type}, importance: ${memory.importance.toStringAsFixed(2)}):');
        buffer.writeln('${memory.content}');
        buffer.writeln();
      }
      buffer.writeln('--- End of relevant memories ---\n');
    }

    buffer.writeln('CURRENT CONVERSATION TO ANALYZE:');
    buffer.writeln('Please summarize this conversation in the context of the above memories:\n\n');

    for (var i = 0; i < filteredMessages.length; i++) {
      final message = filteredMessages[i];
      final speaker = message.isUser ? 'User' : 'Alex';
      buffer.writeln('$speaker: ${message.text}');
      buffer.writeln();
    }

    // Apply length limit to prevent excessive token usage
    final formattedText = buffer.toString();

    if (formattedText.length > _maxConversationLength) {
      AppLogger.d('Memory-aware conversation too long (${formattedText.length}), truncating for token efficiency');
      return '${formattedText.substring(0, _maxConversationLength - 100)}\n\n[Conversation truncated for efficiency]';
    }

    AppLogger.d('Memory-aware conversation formatted for summarization, total length: ${formattedText.length}');
    return formattedText;
  }

  /// Load enhanced summarization prompt that considers memory context
  static Future<String> _loadEnhancedSummarizationPrompt() async {
    try {
      final jsonString = await rootBundle.loadString('assets/summarization_prompt.json');
      final jsonMap = json.decode(jsonString);

      if (jsonMap is Map<String, dynamic> && jsonMap.containsKey('enhancedSummarizationPrompt')) {
        final prompt = jsonMap['enhancedSummarizationPrompt'];
        if (prompt is String && prompt.isNotEmpty) {
          return prompt;
        } else {
          AppLogger.w('enhancedSummarizationPrompt key exists but is not a valid string, using fallback');
        }
      } else {
        AppLogger.w('enhancedSummarizationPrompt key not found in JSON file, using fallback');
      }
    } catch (e) {
      AppLogger.e('Failed to load enhanced summarization prompt from JSON, using fallback', e);
    }

    // Enhanced fallback prompt that considers memory context
    return 'Analyze this conversation in the context of the provided memories. Return a JSON summary with key topics, important facts, user preferences, goals, and a brief summary paragraph that connects current conversation with relevant memories. Focus on meaningful content and how it relates to existing knowledge. Return only valid JSON.';
  }

  /// Generate cache key that includes memory context
  static String _generateMemoryAwareCacheKey(
    List<ConversationMessage> messages,
    List<MemorySegment> relevantMemories,
  ) {
    final messageCount = messages.length;
    final totalLength = messages.fold(0, (sum, msg) => sum + msg.text.length);

    final contentString = messages.map((msg) => '${msg.isUser}:${msg.text}').join('|');
    final contentBytes = utf8.encode(contentString);
    final contentHash = sha256.convert(contentBytes).toString().substring(0, 16);

    // Include memory context in cache key
    final memoryHash = relevantMemories.isEmpty
        ? 'no-memories'
        : sha256.convert(utf8.encode(relevantMemories.map((m) => m.id).join(','))).toString().substring(0, 8);

    return '$messageCount:$totalLength:$contentHash:$memoryHash';
  }

  /// Extract key topics from conversation for memory retrieval
  static List<String> extractKeyTopics(List<ConversationMessage> messages) {
    final allTopics = <String>{};

    for (final message in messages) {
      final topics = _extractTopicsFromMessage(message.text);
      allTopics.addAll(topics);
    }

    return allTopics.take(10).toList(); // Return top 10 topics
  }

  /// Extract topics from a single message
  static List<String> _extractTopicsFromMessage(String text) {
    final topics = <String>{};
    final lowerText = text.toLowerCase();

    // Enhanced topic keywords with more categories
    final topicKeywords = {
      'work': ['work', 'job', 'career', 'office', 'project', 'meeting', 'colleague', 'boss', 'client'],
      'family': ['family', 'parent', 'child', 'sibling', 'relative', 'home', 'mother', 'father', 'brother', 'sister'],
      'hobbies': ['hobby', 'game', 'sport', 'music', 'movie', 'book', 'reading', 'gaming', 'sports'],
      'goals': ['goal', 'objective', 'plan', 'target', 'aim', 'want to', 'need to', 'dream', 'aspiration'],
      'preferences': ['like', 'love', 'prefer', 'favorite', 'enjoy', 'hate', 'dislike', 'prefer'],
      'schedule': ['schedule', 'time', 'when', 'meeting', 'appointment', 'calendar', 'deadline'],
      'location': ['live', 'location', 'city', 'country', 'address', 'place', 'travel', 'move'],
      'technical': ['code', 'programming', 'computer', 'software', 'app', 'website', 'technology', 'ai'],
      'emotions': ['feel', 'feeling', 'happy', 'sad', 'angry', 'excited', 'worried', 'frustrated', 'love'],
      'health': ['health', 'doctor', 'medical', 'sick', 'pain', 'exercise', 'diet', 'fitness'],
    };

    for (final topic in topicKeywords.entries) {
      for (final keyword in topic.value) {
        if (lowerText.contains(keyword)) {
          topics.add(topic.key);
          break;
        }
      }
    }

    return topics.toList();
  }
}