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

      final shouldOfferTools = _isWebSearchEnabled && !_userOptedOutOfSearch(prompt);
      final List<Map<String, dynamic>> messages = [
        {
          'role': 'system',
          'content': enhancedSystemPrompt,
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ];

      final webResults = <WebSearchResult>[];
      const maxToolIterations = 4;
      for (var iteration = 0; iteration < maxToolIterations; iteration++) {
        final response = await _callChatEndpoint(
          messages,
          tools: shouldOfferTools ? _webTools : null,
        );

        stopwatch.stop();
        AppLogger.i('AI API call took ${stopwatch.elapsed.inMilliseconds}ms');

        final message = response['message'] as Map<String, dynamic>? ?? {};
        final content = (message['content'] ?? '').toString();
        final thinking = (message['thinking'] ?? '').toString();
        final toolCalls = (message['tool_calls'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        final assistantMessage = <String, dynamic>{'role': 'assistant'};
        if (content.isNotEmpty) {
          assistantMessage['content'] = content;
        }
        if (thinking.isNotEmpty) {
          assistantMessage['thinking'] = thinking;
        }
        if (toolCalls.isNotEmpty) {
          assistantMessage['tool_calls'] = toolCalls;
        }
        messages.add(assistantMessage);

        if (toolCalls.isEmpty) {
          final trimmed = content.trim();
          if (trimmed.isEmpty) {
            throw Exception('Received empty response from Ollama.');
          }
          AppLogger.i('AI completion successful with ${webResults.length} web results');
          return AIResponse(content: trimmed, webResults: webResults);
        }

        if (!shouldOfferTools) {
          AppLogger.w('Received tool calls despite tools being disabled; breaking loop.');
          final trimmed = content.trim();
          return AIResponse(content: trimmed.isEmpty ? content : trimmed, webResults: webResults);
        }

        for (final call in toolCalls) {
          final function = call['function'] as Map<String, dynamic>? ?? {};
          final name = (function['name'] ?? '').toString();
          final arguments = _parseToolArguments(function['arguments']);

          switch (name) {
            case 'web_search':
              final query = (arguments['query'] ?? '').toString().trim();
              if (query.isEmpty) {
                AppLogger.w('web_search tool called without a query');
                messages.add({
                  'role': 'tool',
                  'tool_name': name,
                  'content': jsonEncode({
                    'error': 'Missing query parameter for web_search tool.',
                  }),
                });
                continue;
              }

              final maxResultsArg = arguments['max_results'];
              final maxResults = maxResultsArg is num
                  ? maxResultsArg.toInt()
                  : int.tryParse(maxResultsArg?.toString() ?? '');

              final searchResults = await _performWebSearch(
                query: query,
                maxResultsOverride: maxResults,
              );

              for (final result in searchResults) {
                final existingIndex =
                    webResults.indexWhere((element) => element.url == result.url && result.url.isNotEmpty);
                if (existingIndex >= 0) {
                  webResults[existingIndex] = result;
                } else {
                  webResults.add(result);
                }
              }

              messages.add({
                'role': 'tool',
                'tool_name': name,
                'content': jsonEncode({
                  'results': searchResults.map((r) => r.toJson()).toList(),
                }),
              });
              break;
            case 'web_fetch':
              final url = (arguments['url'] ?? '').toString();
              if (url.isEmpty) {
                AppLogger.w('web_fetch tool called without a url');
                messages.add({
                  'role': 'tool',
                  'tool_name': name,
                  'content': jsonEncode({
                    'error': 'Missing url parameter for web_fetch tool.',
                  }),
                });
                continue;
              }

              final fetched = await _fetchWebContent(url);
              messages.add({
                'role': 'tool',
                'tool_name': name,
                'content': jsonEncode(fetched ?? {
                  'url': url,
                  'error': 'Failed to retrieve content for the provided URL.',
                }),
              });

              if (fetched != null) {
                var matched = false;
                for (var i = 0; i < webResults.length; i++) {
                  if (webResults[i].url == url) {
                    webResults[i] = webResults[i].copyWith(
                      fullContent: (fetched['content'] ?? '').toString(),
                      links: (fetched['links'] as List<dynamic>? ?? [])
                          .map((e) => e.toString())
                          .toList(),
                    );
                    matched = true;
                    break;
                  }
                }

                if (!matched) {
                  webResults.add(
                    WebSearchResult(
                      title: (fetched['title'] ?? '').toString(),
                      url: url,
                      snippet: (fetched['content'] ?? '').toString(),
                      fullContent: (fetched['content'] ?? '').toString(),
                      links: (fetched['links'] as List<dynamic>? ?? [])
                          .map((e) => e.toString())
                          .toList(),
                    ),
                  );
                }
              }
              break;
            default:
              AppLogger.w('Unknown tool requested: $name');
              messages.add({
                'role': 'tool',
                'tool_name': name,
                'content': jsonEncode({
                  'error': 'Unknown tool requested: $name',
                }),
              });
          }
        }

        stopwatch.reset();
        stopwatch.start();
      }

      throw Exception('Exceeded maximum tool call iterations with Ollama.');
    } catch (e) {
      AppLogger.e('Error connecting to Ollama Cloud API', e);
      throw Exception('Error connecting to Ollama Cloud API: $e');
    }
  }

  static Future<Map<String, dynamic>> _callChatEndpoint(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>>? tools,
  }) async {
    AppLogger.d('API POST $_baseUrl/chat');
    final payload = {
      'model': _model,
      'messages': messages,
      'stream': false,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      AppLogger.e('AI API request failed with status: ${response.statusCode}');
      throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> get _webTools => [
        {
          'type': 'function',
          'function': {
            'name': 'web_search',
            'description':
                'Use this tool to retrieve up-to-date information from the web when the user requests recent data or current events. Only call it when necessary.',
            'parameters': {
              'type': 'object',
              'required': ['query'],
              'properties': {
                'query': {
                  'type': 'string',
                  'description': 'The search query to send to the web_search endpoint.',
                },
                'max_results': {
                  'type': 'integer',
                  'description':
                      'Optional maximum number of results to return (1-10). Defaults to the user configured limit.',
                  'minimum': 1,
                  'maximum': 10,
                },
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'web_fetch',
            'description':
                'Fetch the full contents of a specific URL previously discovered via web_search when more context is required.',
            'parameters': {
              'type': 'object',
              'required': ['url'],
              'properties': {
                'url': {
                  'type': 'string',
                  'description': 'The URL to fetch detailed content from.',
                },
              },
            },
          },
        },
      ];

  static Map<String, dynamic> _parseToolArguments(dynamic rawArguments) {
    if (rawArguments is Map<String, dynamic>) {
      return rawArguments;
    }

    if (rawArguments is String && rawArguments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArguments);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        AppLogger.w('Failed to decode tool arguments: $e');
      }
    }

    return {};
  }

  static bool _userOptedOutOfSearch(String prompt) {
    final normalized = prompt.toLowerCase();
    const optOutPhrases = [
      "don't search",
      'do not search',
      'no search',
      'no need to search',
      'without searching',
      'no internet',
    ];

    return optOutPhrases.any((phrase) => normalized.contains(phrase));
  }

  static Future<List<WebSearchResult>> _performWebSearch({
    required String query,
    int? maxResultsOverride,
  }) async {
    if (!_isWebSearchEnabled) {
      AppLogger.d('Web search disabled; skipping enrichment');
      return [];
    }

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
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
          'query': trimmedQuery,
          'max_results': _determineMaxResults(maxResultsOverride),
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

  static int _determineMaxResults(int? override) {
    if (override == null) {
      return _webSearchMaxResults;
    }

    final sanitized = override.clamp(1, 10);
    return sanitized <= _webSearchMaxResults ? sanitized : _webSearchMaxResults;
  }
}
