/// Model representing the entire conversation context including messages and summary
library;
import 'conversation_message.dart';

/// Model representing the entire conversation context including messages and summary

class ConversationContext {
  final List<ConversationMessage> messages;
  final String summary;
  final DateTime lastUpdated;

  ConversationContext({
    required this.messages,
    required this.summary,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    'summary': summary,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ConversationContext.fromJson(Map<String, dynamic> json) => ConversationContext(
    messages: (json['messages'] as List<dynamic>?)
        ?.map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    summary: json['summary'] ?? '',
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}