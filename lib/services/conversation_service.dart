import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../models/conversation_message.dart';
import '../models/conversation_context.dart';
import '../models/memory_config.dart';
import '../models/memory_segment.dart';
import '../utils/logger.dart';
import 'memory_manager.dart';
import 'memory_monitor.dart';

class ConversationService {
  static const String _fileName = 'conversation_context.json';
  static const String _memoryConfigFileName = 'memory_config.json';
  static ConversationContext _context = ConversationContext(
    messages: [],
    summary: '',
    lastUpdated: DateTime.now(),
    memorySegments: [],
    memoryMetrics: MemoryMetrics.empty(),
  );

  static late MemoryManager _memoryManager;
  static MemoryConfig _memoryConfig = MemoryConfig.standard;

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  static Future<File> get _memoryConfigFile async {
    final path = await _localPath;
    return File('$path/$_memoryConfigFileName');
  }

  static ConversationContext get context => _context;

  /// Initialize the conversation service with memory management
  static Future<void> initialize() async {
    await _loadMemoryConfig();
    _memoryManager = MemoryManager(_memoryConfig);

    // Start memory performance monitoring
    MemoryMonitor.startMonitoring();

    await loadContext();

    AppLogger.i('Conversation service initialized with enhanced memory management');
  }

  static Future<void> loadContext() async {
    AppLogger.d('Loading conversation context from local storage');
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _context = ConversationContext.fromJson(data);

        // Restore memory segments to memory manager
        for (final segment in _context.memorySegments) {
          _memoryManager.restoreMemorySegment(segment);
        }

        AppLogger.i('Conversation context loaded successfully. Messages: ${_context.messages.length}, Summary length: ${_context.summary.length}, Memory segments: ${_context.memorySegments.length}');
      } else {
        AppLogger.i('No existing conversation context file found, starting fresh');
        _context = ConversationContext(
          messages: [],
          summary: '',
          lastUpdated: DateTime.now(),
          memorySegments: [],
          memoryMetrics: MemoryMetrics.empty(),
        );
      }
    } catch (e) {
      AppLogger.e('Error loading conversation context', e);
      _context = ConversationContext(
        messages: [],
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );
    }
  }

  static Future<void> _loadMemoryConfig() async {
    try {
      final file = await _memoryConfigFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _memoryConfig = MemoryConfig.fromJson(data);
        AppLogger.i('Memory configuration loaded successfully');
      } else {
        AppLogger.i('No memory configuration file found, using defaults');
        _memoryConfig = MemoryConfig.standard;
      }
    } catch (e) {
      AppLogger.e('Error loading memory configuration, using defaults', e);
      _memoryConfig = MemoryConfig.standard;
    }
  }

  static Future<void> saveMemoryConfig() async {
    try {
      final file = await _memoryConfigFile;
      final contents = jsonEncode(_memoryConfig.toJson());
      await file.writeAsString(contents);
      AppLogger.i('Memory configuration saved successfully');
    } catch (e) {
      AppLogger.e('Error saving memory configuration', e);
    }
  }

  static Future<void> saveContext() async {
    AppLogger.d('Saving conversation context to local storage');
    try {
      // Update context with latest memory segments before saving
      _context = _context.copyWith(
        memorySegments: _memoryManager.getAllMemories(),
        memoryMetrics: _memoryManager.getMemoryMetrics(),
      );

      final file = await _localFile;
      final contents = jsonEncode(_context.toJson());
      await file.writeAsString(contents);
      AppLogger.i('Conversation context saved successfully. Messages: ${_context.messages.length}, Summary length: ${_context.summary.length}, Memory segments: ${_context.memorySegments.length}');
    } catch (e) {
      AppLogger.e('Error saving conversation context', e);
    }
  }

  /// Get relevant memories for a given query
  static List<MemorySegment> getRelevantMemories(String query, {int limit = 10}) {
    return _memoryManager.getRelevantMemories(query, limit: limit);
  }

  /// Get memory metrics
  static MemoryMetrics getMemoryMetrics() {
    return _memoryManager.getMemoryMetrics();
  }

  /// Update memory configuration
  static void updateMemoryConfig(MemoryConfig config) {
    _memoryConfig = config;
    _memoryManager = MemoryManager(_memoryConfig);
    AppLogger.i('Memory configuration updated');
  }

  /// Get current memory configuration
  static MemoryConfig getMemoryConfig() {
    return _memoryConfig;
  }

  /// Clear all memories and reset memory manager
  static void clearAllMemories() {
    _memoryManager.clearAllMemories();
    _context = _context.copyWith(
      memorySegments: [],
      memoryMetrics: MemoryMetrics.empty(),
    );
    AppLogger.i('Cleared all memories');
  }

  /// Get memory performance metrics
  static Map<String, dynamic> getMemoryPerformanceMetrics() {
    return MemoryMonitor.exportPerformanceData();
  }

  /// Get memory usage trend
  static String getMemoryUsageTrend() {
    return MemoryMonitor.getUsageTrend().toString();
  }

  /// Clear memory performance history
  static void clearMemoryPerformanceHistory() {
    MemoryMonitor.clearHistory();
    AppLogger.d('Memory performance history cleared');
  }

  /// Get detailed memory statistics
  static Map<String, dynamic> getDetailedMemoryStats() {
    final metrics = getMemoryMetrics();
    final performance = getMemoryPerformanceMetrics();

    return {
      'memoryMetrics': metrics.toJson(),
      'performanceData': performance,
      'config': _memoryConfig.toJson(),
      'totalMessages': _context.messages.length,
      'summaryLength': _context.summary.length,
    };
  }

  /// Optimize memory usage based on current trends
  static Future<void> optimizeMemoryUsage() async {
    AppLogger.d('Optimizing memory usage');

    final trend = MemoryMonitor.getUsageTrend();
    final metrics = getMemoryMetrics();

    // Adjust configuration based on usage patterns
    if (trend == MemoryUsageTrend.increasing && metrics.totalSegments > 100) {
      // Memory usage is increasing and getting high, be more aggressive with consolidation
      final optimizedConfig = _memoryConfig.copyWith(
        consolidationInterval: Duration(hours: 3),
        maxShortTermMessages: max(50, _memoryConfig.maxShortTermMessages - 20),
        maxMediumTermSegments: max(30, _memoryConfig.maxMediumTermSegments - 10),
      );

      updateMemoryConfig(optimizedConfig);
      await saveMemoryConfig();

      AppLogger.i('Memory configuration optimized for high usage');
    } else if (trend == MemoryUsageTrend.decreasing || metrics.totalSegments < 50) {
      // Memory usage is low, can be more permissive
      final optimizedConfig = _memoryConfig.copyWith(
        consolidationInterval: Duration(hours: 12),
        maxShortTermMessages: _memoryConfig.maxShortTermMessages + 20,
        maxMediumTermSegments: _memoryConfig.maxMediumTermSegments + 10,
      );

      updateMemoryConfig(optimizedConfig);
      await saveMemoryConfig();

      AppLogger.i('Memory configuration optimized for low usage');
    }

    // Trigger immediate consolidation if needed
    await _memoryManager.checkMemoryLimits();
  }

  /// Dispose of resources
  static void dispose() {
    MemoryMonitor.stopMonitoring();
    _memoryManager.dispose();
  }

  static void addMessage(String text, bool isUser) {
    final message = ConversationMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    final previousMessages = _context.messages;
    _context = ConversationContext(
      messages: [...previousMessages, message],
      summary: _context.summary,
      lastUpdated: DateTime.now(),
      memorySegments: _context.memorySegments,
      memoryMetrics: _context.memoryMetrics,
    );

    // Process the new message with memory manager
    _processMessageWithMemoryManager(message, previousMessages);

    AppLogger.userAction('Message added - isUser: $isUser, length: ${text.length}, total: ${_context.messages.length}');
  }

  static Future<void> _processMessageWithMemoryManager(ConversationMessage message, List<ConversationMessage> previousMessages) async {
    try {
      // Process the new message along with recent context for memory management
      final recentMessages = getRecentMessages(limit: 20);
      await _memoryManager.processMessages(recentMessages, _context);

      // Update context with new memory segments and metrics
      _context = _context.copyWith(
        memorySegments: _memoryManager.getAllMemories(),
        memoryMetrics: _memoryManager.getMemoryMetrics(),
      );
    } catch (e) {
      AppLogger.e('Error processing message with memory manager', e);
      // Continue without memory processing if it fails
    }
  }

  static void updateSummary(String summary) {
    _context = ConversationContext(
      messages: _context.messages,
      summary: summary,
      lastUpdated: DateTime.now(),
      memorySegments: _context.memorySegments,
      memoryMetrics: _context.memoryMetrics,
    );

    AppLogger.i('Conversation summary updated, length: ${summary.length}');
  }

  static void clearContext() {
    final previousMessageCount = _context.messages.length;
    _context = ConversationContext(
      messages: [],
      summary: '',
      lastUpdated: DateTime.now(),
      memorySegments: [],
      memoryMetrics: MemoryMetrics.empty(),
    );

    AppLogger.userAction('Conversation context cleared - previous messages: $previousMessageCount');
  }

  static Future<void> clearAllHistory() async {
    final previousMessageCount = _context.messages.length;
    _context = ConversationContext(
      messages: [],
      summary: '',
      lastUpdated: DateTime.now(),
      memorySegments: [],
      memoryMetrics: MemoryMetrics.empty(),
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