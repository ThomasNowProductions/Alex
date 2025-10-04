import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'conversation_service.dart';

class OllamaService {
  static String get _baseUrl => dotenv.env['OLLAMA_BASE_URL'] ?? 'https://ollama.com/api';
  static String get _apiKey => dotenv.env['OLLAMA_API_KEY'] ?? '';
  static String get _model => dotenv.env['OLLAMA_MODEL'] ?? 'gpt-oss:120b-cloud';

  static Future<String> _loadSystemPrompt() async {
    try {
      final String response = await rootBundle.loadString('assets/system_prompt.json');
      final data = jsonDecode(response);
      return data['systemPrompt'] ?? '';
    } catch (e) {
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

  static Future<String> getCompletion(String prompt) async {
    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    try {
      // Load system prompt from JSON file
      final baseSystemPrompt = await _loadSystemPrompt();

      // Get conversation context
      final conversationContext = ConversationService.context;
      final contextPrompt = _buildContextPrompt(conversationContext);

      // Combine system prompt with conversation context
      final enhancedSystemPrompt = '$baseSystemPrompt\n\n$contextPrompt';

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
              'content': enhancedSystemPrompt
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'].trim();
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to Ollama Cloud API: $e');
    }
  }
}