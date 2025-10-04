import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

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

class ConversationService {
  static const String _fileName = 'conversation_context.json';
  static ConversationContext _context = ConversationContext(
    messages: [],
    summary: '',
    lastUpdated: DateTime.now(),
  );

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  static ConversationContext get context => _context;

  static Future<void> loadContext() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _context = ConversationContext.fromJson(data);
      }
    } catch (e) {
      print('Error loading conversation context: $e');
      _context = ConversationContext(
        messages: [],
        summary: '',
        lastUpdated: DateTime.now(),
      );
    }
  }

  static Future<void> saveContext() async {
    try {
      final file = await _localFile;
      final contents = jsonEncode(_context.toJson());
      await file.writeAsString(contents);
    } catch (e) {
      print('Error saving conversation context: $e');
    }
  }

  static void addMessage(String text, bool isUser) {
    final message = ConversationMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    _context = ConversationContext(
      messages: [..._context.messages, message],
      summary: _context.summary,
      lastUpdated: DateTime.now(),
    );
  }

  static void updateSummary(String summary) {
    _context = ConversationContext(
      messages: _context.messages,
      summary: summary,
      lastUpdated: DateTime.now(),
    );
  }

  static void clearContext() {
    _context = ConversationContext(
      messages: [],
      summary: '',
      lastUpdated: DateTime.now(),
    );
  }

  static List<ConversationMessage> getRecentMessages({int limit = 50}) {
    if (_context.messages.length <= limit) {
      return _context.messages;
    }
    return _context.messages.sublist(_context.messages.length - limit);
  }
}