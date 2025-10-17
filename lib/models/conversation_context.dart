/// Model representing the entire conversation context including messages and summary
library;
import 'conversation_message.dart';
import 'memory_segment.dart';

/// Model representing the entire conversation context including messages and summary

class ConversationContext {
  final List<ConversationMessage> messages;
  final String summary;
  final DateTime lastUpdated;
  final List<MemorySegment> memorySegments;
  final MemoryMetrics memoryMetrics;

  ConversationContext({
    required this.messages,
    required this.summary,
    required this.lastUpdated,
    required this.memorySegments,
    required this.memoryMetrics,
  });

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    'summary': summary,
    'lastUpdated': lastUpdated.toIso8601String(),
    'memorySegments': memorySegments.map((m) => m.toJson()).toList(),
    'memoryMetrics': memoryMetrics.toJson(),
  };

  factory ConversationContext.fromJson(Map<String, dynamic> json) => ConversationContext(
    messages: (json['messages'] as List<dynamic>?)
        ?.map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    summary: json['summary'] ?? '',
    lastUpdated: DateTime.parse(json['lastUpdated']),
    memorySegments: (json['memorySegments'] as List<dynamic>?)
        ?.map((m) => MemorySegment.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    memoryMetrics: json['memoryMetrics'] != null
        ? MemoryMetrics.fromJson(json['memoryMetrics'])
        : MemoryMetrics.empty(),
  );

  ConversationContext copyWith({
    List<ConversationMessage>? messages,
    String? summary,
    DateTime? lastUpdated,
    List<MemorySegment>? memorySegments,
    MemoryMetrics? memoryMetrics,
  }) {
    return ConversationContext(
      messages: messages ?? this.messages,
      summary: summary ?? this.summary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      memorySegments: memorySegments ?? this.memorySegments,
      memoryMetrics: memoryMetrics ?? this.memoryMetrics,
    );
  }
}