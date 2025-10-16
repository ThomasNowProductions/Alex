import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:crypto/crypto.dart' show sha256;
import '../models/conversation_message.dart';
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

  static Future<String> summarizeConversation(List<ConversationMessage> messages) async {
    AppLogger.d('Starting conversation summarization');
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
    final cacheKey = _generateCacheKey(messages);
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
      final conversationText = _formatConversationForSummary(messages);

      // Load the summarization prompt
      final prompt = await _getSummarizationPrompt();

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

  static String _formatConversationForSummary(List<ConversationMessage> messages) {
    AppLogger.d('Formatting ${messages.length} messages for summarization');

    // Filter out very short messages and system messages to reduce token count
    final filteredMessages = _filterMessagesForSummarization(messages);

    if (filteredMessages.isEmpty) {
      return 'No meaningful conversation to summarize.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Summarize this conversation:\n\n');

    for (var i = 0; i < filteredMessages.length; i++) {
      final message = filteredMessages[i];
      final speaker = message.isUser ? 'User' : 'Alex';
      buffer.writeln('$speaker: ${message.text}');
      buffer.writeln();
    }

    // Apply length limit to prevent excessive token usage
    final formattedText = buffer.toString();

    if (formattedText.length > _maxConversationLength) {
      AppLogger.d('Conversation too long (${formattedText.length}), truncating for token efficiency');
      return '${formattedText.substring(0, _maxConversationLength - 100)}\n\n[Conversation truncated for efficiency]';
    }

    AppLogger.d('Conversation formatted for summarization, total length: ${formattedText.length}');
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

  static Future<String> _getSummarizationPrompt() async {
    // Load and cache the prompt if not already cached
    if (_cachedPrompt == null) {
      _cachedPrompt = await _loadSummarizationPrompt();
      AppLogger.d('Loaded summarization prompt from JSON file');
    }
    return _cachedPrompt!;
  }

  static String _generateCacheKey(List<ConversationMessage> messages) {
    // Create a unique hash based on message content to avoid collisions
    // Include message count, total length, and content hash for better uniqueness
    final messageCount = messages.length;
    final totalLength = messages.fold(0, (sum, msg) => sum + msg.text.length);

    // Create a content hash from all message texts
    final contentString = messages.map((msg) => '${msg.isUser}:${msg.text}').join('|');
    final contentBytes = utf8.encode(contentString);
    final contentHash = sha256.convert(contentBytes).toString().substring(0, 16);

    return '$messageCount:$totalLength:$contentHash';
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
}