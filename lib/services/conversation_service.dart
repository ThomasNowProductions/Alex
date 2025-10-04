import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/conversation_message.dart';
import '../models/conversation_context.dart';

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