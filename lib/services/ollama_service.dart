import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  static Future<String> getCompletion(String prompt) async {
    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    try {
      // Load system prompt from JSON file
      final systemPrompt = await _loadSystemPrompt();

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
              'content': systemPrompt
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