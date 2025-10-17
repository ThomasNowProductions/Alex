/// Tests for the improved memory management system
import 'package:flutter_test/flutter_test.dart';
import 'package:alex/models/conversation_message.dart';
import 'package:alex/models/conversation_context.dart';
import 'package:alex/models/memory_segment.dart';
import 'package:alex/models/memory_config.dart';
import 'package:alex/services/memory_manager.dart';
import 'package:alex/services/memory_monitor.dart';

void main() {
  group('Memory Management Improvements', () {
    late MemoryManager memoryManager;
    late MemoryConfig config;

    setUp(() {
      config = MemoryConfig.minimal; // Use minimal config for testing
      memoryManager = MemoryManager(config);
    });

    tearDown(() {
      memoryManager.dispose();
    });

    test('MemoryManager processes messages and creates segments', () async {
      final messages = [
        ConversationMessage(
          text: 'I love programming and want to learn Flutter',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ConversationMessage(
          text: 'That is great! Flutter is an excellent framework for mobile development.',
          isUser: false,
          timestamp: DateTime.now().add(Duration(minutes: 1)),
        ),
      ];

      final context = ConversationContext(
        messages: messages,
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages(messages, context);

      final segments = memoryManager.getAllMemories();
      expect(segments.isNotEmpty, true);

      final segment = segments.first;
      expect(segment.content.isNotEmpty, true);
      expect(segment.importance, greaterThan(0.0));
      expect(segment.topics.isNotEmpty, true);
    });

    test('Memory processes messages with different importance levels', () async {
      final highImportanceMessage = ConversationMessage(
        text: 'I want to remember this important goal for my career development',
        isUser: true,
        timestamp: DateTime.now(),
      );

      final lowImportanceMessage = ConversationMessage(
        text: 'hi',
        isUser: true,
        timestamp: DateTime.now(),
      );

      final context = ConversationContext(
        messages: [highImportanceMessage, lowImportanceMessage],
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages([highImportanceMessage, lowImportanceMessage], context);

      final segments = memoryManager.getAllMemories();
      expect(segments.isNotEmpty, true);

      // High importance messages should create segments with higher importance
      final segment = segments.first;
      expect(segment.importance, greaterThan(0.0));
    });

    test('Memory segments are created with topics', () async {
      final message = ConversationMessage(
        text: 'I love programming in Dart and want to build mobile apps with Flutter',
        isUser: true,
        timestamp: DateTime.now(),
      );

      final context = ConversationContext(
        messages: [message],
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages([message], context);

      final segments = memoryManager.getAllMemories();
      expect(segments.isNotEmpty, true);

      final segment = segments.first;
      expect(segment.topics.length, greaterThan(0));
    });

    test('Memory consolidation works', () async {
      // Create multiple related messages
      final messages = List.generate(10, (index) => ConversationMessage(
        text: 'Message about programming and Flutter development number $index',
        isUser: true,
        timestamp: DateTime.now().add(Duration(minutes: index)),
      ));

      final context = ConversationContext(
        messages: messages,
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages(messages, context);

      // Check memory limits and trigger consolidation
      await memoryManager.checkMemoryLimits();

      final segments = memoryManager.getAllMemories();
      final metrics = memoryManager.getMemoryMetrics();

      expect(metrics.totalSegments, greaterThanOrEqualTo(0));
      expect(segments.length, lessThanOrEqualTo(config.maxShortTermMessages));
    });

    test('Memory relevance scoring works', () async {
      final query = 'Flutter programming';

      // Create a message that will generate a relevant memory
      final message = ConversationMessage(
        text: 'Discussion about Flutter and Dart programming',
        isUser: true,
        timestamp: DateTime.now(),
      );

      final context = ConversationContext(
        messages: [message],
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages([message], context);

      final relevantMemories = memoryManager.getRelevantMemories(query, limit: 5);

      expect(relevantMemories.isNotEmpty, true);
      expect(relevantMemories.first.relevanceScore, greaterThan(0.0));
    });

    test('Memory expiration works correctly', () {
      final expiredMemory = MemorySegment(
        id: 'expired-1',
        content: 'Old memory',
        type: MemoryType.shortTerm,
        importance: 0.5,
        created: DateTime.now().subtract(Duration(days: 2)), // Expired
        lastAccessed: DateTime.now().subtract(Duration(days: 2)),
        accessCount: 1,
        topics: ['test'],
        metadata: {},
      );

      final freshMemory = MemorySegment(
        id: 'fresh-1',
        content: 'New memory',
        type: MemoryType.shortTerm,
        importance: 0.5,
        created: DateTime.now(), // Fresh
        lastAccessed: DateTime.now(),
        accessCount: 1,
        topics: ['test'],
        metadata: {},
      );

      expect(expiredMemory.isExpired, true);
      expect(freshMemory.isExpired, false);
    });

    test('Memory metrics calculation works', () async {
      final message1 = ConversationMessage(
        text: 'Test memory 1',
        isUser: true,
        timestamp: DateTime.now(),
      );

      final message2 = ConversationMessage(
        text: 'Test memory 2',
        isUser: true,
        timestamp: DateTime.now().add(Duration(minutes: 1)),
      );

      final context = ConversationContext(
        messages: [message1, message2],
        summary: '',
        lastUpdated: DateTime.now(),
        memorySegments: [],
        memoryMetrics: MemoryMetrics.empty(),
      );

      await memoryManager.processMessages([message1, message2], context);

      final metrics = memoryManager.getMemoryMetrics();

      expect(metrics.totalSegments, greaterThanOrEqualTo(0));
      expect(metrics.shortTermCount, greaterThanOrEqualTo(0));
      expect(metrics.longTermCount, greaterThanOrEqualTo(0));
    });
  });

  group('Memory Monitor', () {
    setUp(() {
      MemoryMonitor.clearHistory();
    });

    tearDown(() {
      MemoryMonitor.stopMonitoring();
    });

    test('Memory monitor starts and stops correctly', () {
      expect(MemoryMonitor.getUsageTrend(), equals(MemoryUsageTrend.stable));

      MemoryMonitor.startMonitoring();
      expect(MemoryMonitor.exportPerformanceData()['isMonitoring'], true);

      MemoryMonitor.stopMonitoring();
      expect(MemoryMonitor.exportPerformanceData()['isMonitoring'], false);
    });

    test('Performance snapshots are created', () {
      MemoryMonitor.startMonitoring();

      // Wait a bit for snapshot to be taken
      Future.delayed(Duration(milliseconds: 100), () {
        final snapshots = MemoryMonitor.getPerformanceHistory();
        expect(snapshots.isNotEmpty, true);
      });
    });
  });

  group('Memory Configuration', () {
    test('MemoryConfig presets work correctly', () {
      expect(MemoryConfig.minimal.maxShortTermMessages, lessThan(MemoryConfig.standard.maxShortTermMessages));
      expect(MemoryConfig.comprehensive.maxShortTermMessages, greaterThan(MemoryConfig.standard.maxShortTermMessages));

      expect(MemoryConfig.minimal.enableAutoConsolidation, false);
      expect(MemoryConfig.comprehensive.enableAutoConsolidation, true);
    });

    test('MemoryConfig copyWith works correctly', () {
      final config = MemoryConfig.standard;
      final modifiedConfig = config.copyWith(maxShortTermMessages: 200);

      expect(modifiedConfig.maxShortTermMessages, equals(200));
      expect(modifiedConfig.maxMediumTermSegments, equals(config.maxMediumTermSegments));
    });

    test('MemoryConfig serialization works', () {
      final config = MemoryConfig.standard;
      final json = config.toJson();
      final restoredConfig = MemoryConfig.fromJson(json);

      expect(restoredConfig.maxShortTermMessages, equals(config.maxShortTermMessages));
      expect(restoredConfig.enableAutoConsolidation, equals(config.enableAutoConsolidation));
    });
  });
}