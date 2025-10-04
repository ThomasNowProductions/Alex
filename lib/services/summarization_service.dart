import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversation_message.dart';

class SummarizationService {
  static String get _baseUrl => dotenv.env['OLLAMA_BASE_URL'] ?? 'https://ollama.com/api';
  static String get _apiKey => dotenv.env['OLLAMA_API_KEY'] ?? '';
  static String get _model => dotenv.env['OLLAMA_MODEL'] ?? 'gpt-oss:120b-cloud';

  static Future<String> summarizeConversation(List<ConversationMessage> messages) async {
    if (_apiKey.isEmpty || _apiKey.contains('your-ollama-api-key-here')) {
      throw Exception('Please set your OLLAMA_API_KEY in assets/.env file');
    }

    if (messages.isEmpty) {
      return 'No conversation to summarize.';
    }

    try {
      // Create a formatted conversation string for the summarizer
      final conversationText = _formatConversationForSummary(messages);

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
              'content': _getSummarizationPrompt()
            },
            {
              'role': 'user',
              'content': conversationText
            }
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'].trim();
      } else {
        throw Exception('Failed to get summarization: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to summarization API: $e');
    }
  }

  static String _formatConversationForSummary(List<ConversationMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('Please summarize the following conversation. Extract key facts, topics discussed, user preferences, important details, and any recurring themes.\n\n');

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final speaker = message.isUser ? 'User' : 'Alex';
      buffer.writeln('$speaker: ${message.text}');

      // Add timestamp for context
      buffer.writeln('[${message.timestamp.toIso8601String()}]');
      buffer.writeln();
    }

    buffer.writeln('\nPlease provide a comprehensive summary in JSON format that captures:');
    buffer.writeln('- Key topics and themes discussed');
    buffer.writeln('- Important facts and details mentioned');
    buffer.writeln('- User preferences, interests, or goals');
    buffer.writeln('- Any decisions made or plans discussed');
    buffer.writeln('- Recurring themes or patterns in the conversation');
    buffer.writeln('- Important context that might be relevant for future conversations');

    return buffer.toString();
  }

  static String _getSummarizationPrompt() {
    return '''
You are an expert conversation analyst. Your task is to analyze conversations and extract meaningful insights.

Please provide a comprehensive summary of the conversation in valid JSON format with the following structure:

{
  "keyTopics": ["topic1", "topic2", "topic3"],
  "importantFacts": ["fact1", "fact2", "fact3"],
  "userPreferences": ["preference1", "preference2"],
  "goalsAndPlans": ["goal1", "goal2"],
  "recurringThemes": ["theme1", "theme2"],
  "contextualDetails": ["detail1", "detail2"],
  "summary": "A concise paragraph summarizing the overall conversation"
}

Guidelines:
- Extract only meaningful, factual information
- Focus on actionable insights and important context
- Avoid including trivial or generic conversation elements
- Be specific and concrete in your extractions
- Ensure all arrays contain distinct, relevant items
- The summary should be a coherent paragraph that captures the essence of the conversation

Return only valid JSON, no additional text or explanation.
''';
  }
}