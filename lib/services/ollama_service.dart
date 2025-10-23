import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/ai_response.dart';
import '../models/conversation_context.dart';
import '../models/web_search_result.dart';
import 'conversation_service.dart';
import 'settings_service.dart';
import '../utils/logger.dart';

class OllamaService {
  static String get _baseUrl => dotenv.env['OLLAMA_BASE_URL'] ?? 'https://ollama.com/api';
  static String get _model => dotenv.env['OLLAMA_MODEL'] ?? 'deepseek-v3.1:671b';

  static String get _apiKey {
    final apiKeySource = SettingsService.apiKeySource;
    if (apiKeySource == 'custom') {
      return SettingsService.customApiKey;
    }
    // Use inbuilt API key from .env
    return dotenv.env['OLLAMA_API_KEY'] ?? '';
  }

  static Future<String> _loadSystemPrompt() async {
    AppLogger.d('Loading system prompt from assets/system_prompt.json');
    try {
      final String response = await rootBundle.loadString('assets/system_prompt.json');
      final data = jsonDecode(response);
      final systemPrompt = data['systemPrompt'] ?? '';
      AppLogger.i('System prompt loaded successfully');
      return systemPrompt;
    } catch (e) {
      AppLogger.e('Failed to load system prompt', e);
      throw Exception('Failed to load system prompt: $e');
    }
  }

  static String _buildContextPrompt(ConversationContext context) {
    if (context.messages.isEmpty && context.summary.isEmpty) {
      return 'This is the beginning of our conversation. Get to know the user and start building a friendship.';
    }

    final buffer = StringBuffer();
    buffer.writeln('CONVERSATION CONTEXT:');
    buffer.writeln('===================');

    // Add conversation summary if available
    if (context.summary.isNotEmpty) {
      buffer.writeln('SUMMARY OF OUR CONVERSATION SO FAR:');
      buffer.writeln(context.summary);
      buffer.writeln();
    }

    // Add recent messages for immediate context (last 10 messages)
    if (context.messages.isNotEmpty) {
      final recentMessages = ConversationService.getRecentMessages(limit: 10);
      buffer.writeln('RECENT CONVERSATION (last ${recentMessages.length} exchanges):');
      buffer.writeln();

      for (var message in recentMessages) {
        final speaker = message.isUser ? 'User' : 'Alex';
        buffer.writeln('$speaker: ${message.text}');
      }
      buffer.writeln();
    }

    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('- Use this context to inform your responses and maintain continuity');
    buffer.writeln('- Reference previous topics naturally when relevant');
    buffer.writeln('- Remember important details the user has shared');
    buffer.writeln('- Build on our established friendship and conversation history');
    buffer.writeln('- Be consistent with your personality and our relationship');

    return buffer.toString();
  }

  static bool get _isWebSearchEnabled {
    final envOverride = dotenv.env['OLLAMA_WEB_SEARCH_ENABLED'];
    if (envOverride != null) {
      return envOverride.toLowerCase() == 'true';
    }
    return SettingsService.webSearchEnabled;
  }

  static int get _webSearchMaxResults {
    final envOverride = int.tryParse(dotenv.env['OLLAMA_WEB_SEARCH_MAX_RESULTS'] ?? '');
    if (envOverride != null) {
      return envOverride.clamp(1, 10).toInt();
    }
    return SettingsService.webSearchMaxResults.clamp(1, 10).toInt();
  }

  static int get _webFetchResultCount {
    final envOverride = int.tryParse(dotenv.env['OLLAMA_WEB_FETCH_COUNT'] ?? '');
    if (envOverride != null) {
      return envOverride.clamp(0, 5).toInt();
    }
    return SettingsService.webFetchResultCount.clamp(0, 5).toInt();
  }

  static Future<AIResponse> getCompletion(String prompt) async {
    AppLogger.d('Starting AI completion request');
    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      AppLogger.w('OLLAMA_API_KEY not properly configured');
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Load system prompt from JSON file
      AppLogger.d('Loading system prompt');
      final baseSystemPrompt = await _loadSystemPrompt();

      // Get conversation context
      AppLogger.d('Building conversation context');
      final conversationContext = ConversationService.context;
      final contextPrompt = _buildContextPrompt(conversationContext);

      // Combine system prompt with conversation context
      final enhancedSystemPrompt = '$baseSystemPrompt\n\n$contextPrompt';
      AppLogger.d('Enhanced system prompt created, length: ${enhancedSystemPrompt.length}');

      // Optionally enrich with live web data
      final webResults = await _performWebSearch(prompt);
      final webContext = _buildWebSearchContext(webResults);

      final messages = [
        {
          'role': 'system',
          'content': enhancedSystemPrompt,
        },
        if (webContext != null)
          {
            'role': 'system',
            'content': webContext,
          },
        {
          'role': 'user',
          'content': prompt,
        },
      ];

      AppLogger.d('API POST $_baseUrl/chat');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'stream': false,
        }),
      );

      stopwatch.stop();
      AppLogger.i('AI API call took ${stopwatch.elapsed.inMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['message']['content'].trim();
        AppLogger.i('AI completion successful, status: ${response.statusCode}, response length: ${content.length}');
        return AIResponse(content: content, webResults: webResults);
      } else {
        AppLogger.e('AI API request failed with status: ${response.statusCode}');
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Error connecting to Ollama Cloud API', e);
      throw Exception('Error connecting to Ollama Cloud API: $e');
    }
  }

  static Future<List<WebSearchResult>> _performWebSearch(String prompt) async {
    if (!_isWebSearchEnabled) {
      AppLogger.d('Web search disabled; skipping enrichment');
      return [];
    }

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return [];
    }

    try {
      AppLogger.d('API POST $_baseUrl/web_search');
      final response = await http.post(
        Uri.parse('$_baseUrl/web_search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'query': trimmedPrompt,
          'max_results': _webSearchMaxResults,
        }),
      );

      if (response.statusCode != 200) {
        AppLogger.w('Web search request failed with status: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (decoded['results'] as List<dynamic>? ?? [])
          .map((raw) => WebSearchResult.fromSearchJson(raw as Map<String, dynamic>))
          .where((result) => result.title.isNotEmpty || result.snippet.isNotEmpty)
          .toList();

      if (results.isEmpty || _webFetchResultCount <= 0) {
        return results;
      }

      final fetchTargets = results.take(_webFetchResultCount).toList();
      final enriched = <WebSearchResult>[];

      for (final result in fetchTargets) {
        if (result.url.isEmpty) {
          enriched.add(result);
          continue;
        }

        final fetched = await _fetchWebContent(result.url);
        if (fetched == null) {
          enriched.add(result);
          continue;
        }

        enriched.add(result.copyWith(
          fullContent: (fetched['content'] ?? '') as String,
          links: (fetched['links'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
        ));
      }

      return [
        ...enriched,
        ...results.skip(_webFetchResultCount),
      ];
    } catch (e) {
      AppLogger.e('Web search enrichment failed', e);
      return [];
    }
  }

  static Future<Map<String, dynamic>?> _fetchWebContent(String url) async {
    try {
      AppLogger.d('API POST $_baseUrl/web_fetch for $url');
      final response = await http.post(
        Uri.parse('$_baseUrl/web_fetch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode != 200) {
        AppLogger.w('Web fetch failed for $url with status: ${response.statusCode}');
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Failed to fetch web content for $url', e);
      return null;
    }
  }

  static String? _buildWebSearchContext(List<WebSearchResult> results) {
    if (results.isEmpty) {
      return null;
    }

    final buffer = StringBuffer();
    buffer.writeln('WEB SEARCH RESULTS:');
    buffer.writeln('===================');

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('Result ${i + 1}: ${result.title}');
      if (result.url.isNotEmpty) {
        buffer.writeln('URL: ${result.url}');
      }
      if (result.displayContent.isNotEmpty) {
        var excerpt = result.displayContent.trim();
        const maxLength = 1200;
        if (excerpt.length > maxLength) {
          excerpt = '${excerpt.substring(0, maxLength)}...';
        }
        buffer.writeln(excerpt);
      }
      if (result.links.isNotEmpty) {
        buffer.writeln('Links referenced: ${result.links.join(', ')}');
      }
      buffer.writeln();
    }

    buffer.writeln('Use the search findings to provide up-to-date information where relevant.');
    return buffer.toString();
  }
}
