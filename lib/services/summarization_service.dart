import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
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
    if (_cache.length > 10) {
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
        final summary = data['message']['content'].trim();
        AppLogger.i('Conversation summarization completed successfully, length: ${summary.length}');

        // Cache the result for future use
        _cache[cacheKey] = _SummaryCache(summary, DateTime.now());

        return summary;
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
    final maxLength = 4000; // Conservative limit for token efficiency

    if (formattedText.length > maxLength) {
      AppLogger.d('Conversation too long (${formattedText.length}), truncating for token efficiency');
      return '${formattedText.substring(0, maxLength - 100)}\n\n[Conversation truncated for efficiency]';
    }

    AppLogger.d('Conversation formatted for summarization, total length: ${formattedText.length}');
    return formattedText;
  }

  static Future<String> _loadSummarizationPrompt() async {
    try {
      final jsonString = await rootBundle.loadString('assets/summarization_prompt.json');
      final jsonMap = json.decode(jsonString);
      return jsonMap['summarizationPrompt'] as String;
    } catch (e) {
      AppLogger.e('Failed to load summarization prompt from JSON, using fallback', e);
      // Fallback prompt in case JSON file fails to load
      return 'Analyze this conversation and return a JSON summary with key topics, important facts, user preferences, goals, and a brief summary paragraph. Focus on meaningful content only. Return only valid JSON.';
    }
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
    // Create a simple hash of message count and total content length
    // This provides a good balance between cache efficiency and accuracy
    final messageCount = messages.length;
    final totalLength = messages.fold(0, (sum, msg) => sum + msg.text.length);
    return '$messageCount:$totalLength';
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
}