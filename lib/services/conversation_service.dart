import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/conversation_message.dart';
import '../models/conversation_context.dart';
import '../utils/logger.dart';

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
    AppLogger.d('Loading conversation context from local storage');
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _context = ConversationContext.fromJson(data);
        AppLogger.i('Conversation context loaded successfully. Messages: ${_context.messages.length}, Summary length: ${_context.summary.length}');
      } else {
        AppLogger.i('No existing conversation context file found, starting fresh');
        _context = ConversationContext(
          messages: [],
          summary: '',
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      AppLogger.e('Error loading conversation context', e);
      _context = ConversationContext(
        messages: [],
        summary: '',
        lastUpdated: DateTime.now(),
      );
    }
  }

  static Future<void> saveContext() async {
    AppLogger.d('Saving conversation context to local storage');
    try {
      final file = await _localFile;
      final contents = jsonEncode(_context.toJson());
      await file.writeAsString(contents);
      AppLogger.i('Conversation context saved successfully. Messages: ${_context.messages.length}, Summary length: ${_context.summary.length}');
    } catch (e) {
      AppLogger.e('Error saving conversation context', e);
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

    AppLogger.userAction('Message added - isUser: $isUser, length: ${text.length}, total: ${_context.messages.length}');
  }

  static void updateSummary(String summary) {
    _context = ConversationContext(
      messages: _context.messages,
      summary: summary,
      lastUpdated: DateTime.now(),
    );

    AppLogger.i('Conversation summary updated, length: ${summary.length}');
  }

  static void clearContext() {
    final previousMessageCount = _context.messages.length;
    _context = ConversationContext(
      messages: [],
      summary: '',
      lastUpdated: DateTime.now(),
    );

    AppLogger.userAction('Conversation context cleared - previous messages: $previousMessageCount');
  }

  static Future<void> clearAllHistory() async {
    final previousMessageCount = _context.messages.length;
    _context = ConversationContext(
      messages: [],
      summary: '',
      lastUpdated: DateTime.now(),
    );

    // Delete the conversation context file
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
      AppLogger.userAction('All conversation history cleared - previous messages: $previousMessageCount');
    } catch (e) {
      AppLogger.e('Error deleting conversation history file', e);
      rethrow;
    }
  }

  static List<ConversationMessage> getRecentMessages({int limit = 50}) {
    final recentMessages = _context.messages.length <= limit
        ? _context.messages
        : _context.messages.sublist(_context.messages.length - limit);

    AppLogger.d('Retrieved recent messages - requested: $limit, actual: ${recentMessages.length}, total: ${_context.messages.length}');

    return recentMessages;
  }
}