import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/conversation_message.dart';
import '../models/conversation_context.dart';
import '../models/memory_segment.dart';
import '../models/memory_config.dart';
import '../utils/logger.dart';
import 'summarization_service.dart';

/// Advanced memory manager with intelligent importance scoring and hierarchical memory
class MemoryManager {
  static const Uuid _uuid = Uuid();
  final MemoryConfig _config;
  final Map<String, MemorySegment> _memorySegments = {};
  final Map<String, DateTime> _lastConsolidation = {};
  Timer? _consolidationTimer;

  MemoryManager(this._config) {
    if (_config.enableAutoConsolidation) {
      _startAutoConsolidation();
    }
  }

  /// Calculate importance score for a message based on multiple factors
  double _calculateMessageImportance(ConversationMessage message, List<ConversationMessage> context) {
    double importance = 0.0;

    // Base importance from message length (longer messages tend to be more important)
    importance += min(message.text.length / 100.0, 1.0) * 0.3;

    // Priority keywords boost
    final lowerText = message.text.toLowerCase();
    for (final keyword in _config.priorityKeywords) {
      if (lowerText.contains(keyword)) {
        importance += 0.2;
        break;
      }
    }

    // Question messages are often more important
    if (message.text.contains('?')) {
      importance += 0.1;
    }

    // User messages are generally more important than AI responses
    if (message.isUser) {
      importance += 0.1;
    }

    // Context-based importance (messages that follow important messages)
    if (context.isNotEmpty) {
      final previousMessage = context.last;
      if (previousMessage.isUser && message.isUser) {
        // Consecutive user messages might indicate persistence
        importance += 0.05;
      }
    }

    // Recency boost (very recent messages are more important)
    final age = DateTime.now().difference(message.timestamp);
    if (age.inMinutes < 5) {
      importance += 0.1;
    } else if (age.inMinutes < 30) {
      importance += 0.05;
    }

    // Emotional indicators
    final emotionalWords = ['love', 'hate', 'angry', 'happy', 'sad', 'excited', 'worried', 'frustrated'];
    for (final word in emotionalWords) {
      if (lowerText.contains(word)) {
        importance += 0.15;
        break;
      }
    }

    // Personal information indicators
    final personalWords = ['my name', 'i am', 'i work', 'i live', 'my goal', 'i want', 'i need'];
    for (final word in personalWords) {
      if (lowerText.contains(word)) {
        importance += 0.2;
        break;
      }
    }

    return min(importance, 1.0);
  }

  /// Extract topics from a message using simple keyword analysis
  List<String> _extractTopics(String text) {
    final topics = <String>{};
    final lowerText = text.toLowerCase();

    // Define topic keywords
    final topicKeywords = {
      'work': ['work', 'job', 'career', 'office', 'project', 'meeting', 'colleague'],
      'family': ['family', 'parent', 'child', 'sibling', 'relative', 'home'],
      'hobbies': ['hobby', 'game', 'sport', 'music', 'movie', 'book', 'reading'],
      'goals': ['goal', 'objective', 'plan', 'target', 'aim', 'want to', 'need to'],
      'preferences': ['like', 'love', 'prefer', 'favorite', 'enjoy', 'hate', 'dislike'],
      'schedule': ['schedule', 'time', 'when', 'meeting', 'appointment', 'calendar'],
      'location': ['live', 'location', 'city', 'country', 'address', 'place'],
      'technical': ['code', 'programming', 'computer', 'software', 'app', 'website'],
    };

    for (final topic in topicKeywords.entries) {
      for (final keyword in topic.value) {
        if (lowerText.contains(keyword)) {
          topics.add(topic.key);
          break;
        }
      }
    }

    return topics.toList();
  }

  /// Determine memory type based on importance and context
  MemoryType _determineMemoryType(double importance, List<String> topics) {
    if (importance >= _config.criticalImportanceThreshold) {
      return MemoryType.critical;
    } else if (importance >= _config.longTermImportanceThreshold) {
      return MemoryType.longTerm;
    } else if (importance >= _config.mediumTermImportanceThreshold) {
      return MemoryType.mediumTerm;
    } else {
      return MemoryType.shortTerm;
    }
  }

  /// Create a memory segment from conversation messages
  MemorySegment _createMemorySegment(List<ConversationMessage> messages, String content) {
    final allTopics = <String>{};
    double totalImportance = 0.0;

    for (final message in messages) {
      final topics = _extractTopics(message.text);
      allTopics.addAll(topics);
      totalImportance += _calculateMessageImportance(message, messages);
    }

    final averageImportance = messages.isEmpty ? 0.0 : totalImportance / messages.length;
    final memoryType = _determineMemoryType(averageImportance, allTopics.toList());

    return MemorySegment(
      id: _uuid.v4(),
      content: content,
      type: memoryType,
      importance: averageImportance,
      created: DateTime.now(),
      lastAccessed: DateTime.now(),
      accessCount: 1,
      topics: allTopics.toList(),
      metadata: {
        'messageCount': messages.length,
        'startTime': messages.isEmpty ? DateTime.now().toIso8601String() : messages.first.timestamp.toIso8601String(),
        'endTime': messages.isEmpty ? DateTime.now().toIso8601String() : messages.last.timestamp.toIso8601String(),
        'containsUserMessages': messages.any((m) => m.isUser),
        'containsAIMessages': messages.any((m) => !m.isUser),
      },
    );
  }

  /// Process new messages and create appropriate memory segments
  Future<void> processMessages(List<ConversationMessage> newMessages, ConversationContext context) async {
    if (newMessages.isEmpty) return;

    AppLogger.d('Processing ${newMessages.length} messages for memory management');

    // Group messages into logical segments (e.g., by topic or time gaps)
    final segments = await _createMessageSegments(newMessages, context);

    for (final segment in segments) {
      final memorySegment = _createMemorySegment(segment.messages, segment.summary);

      // Check if we need to consolidate or cleanup before adding
      await _checkMemoryLimits();

      _memorySegments[memorySegment.id] = memorySegment;
      AppLogger.d('Created memory segment: ${memorySegment.id} (${memorySegment.type}, importance: ${memorySegment.importance})');
    }

    // Update memory metrics
    _updateMemoryMetrics();
  }

  /// Create logical segments from messages
  Future<List<_MessageSegment>> _createMessageSegments(List<ConversationMessage> messages, ConversationContext context) async {
    final segments = <_MessageSegment>[];
    final currentSegment = <_MessageSegment>[];

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final segment = _MessageSegment([message], '');

      // Check if we should start a new segment
      if (i == 0 || _shouldStartNewSegment(messages[i - 1], message)) {
        if (currentSegment.isNotEmpty) {
          // Summarize the current segment before starting a new one
          final summary = await _summarizeMessageSegment(currentSegment);
          segments.add(_MessageSegment(
            currentSegment.expand((s) => s.messages).toList(),
            summary,
          ));
        }
        currentSegment.clear();
      }

      currentSegment.add(segment);
    }

    // Add the final segment
    if (currentSegment.isNotEmpty) {
      final summary = await _summarizeMessageSegment(currentSegment);
      segments.add(_MessageSegment(
        currentSegment.expand((s) => s.messages).toList(),
        summary,
      ));
    }

    return segments;
  }

  /// Determine if we should start a new memory segment
  bool _shouldStartNewSegment(ConversationMessage previous, ConversationMessage current) {
    final timeGap = current.timestamp.difference(previous.timestamp);

    // Start new segment if there's a significant time gap
    if (timeGap > Duration(minutes: 30)) {
      return true;
    }

    // Start new segment if topics change significantly
    final prevTopics = _extractTopics(previous.text);
    final currTopics = _extractTopics(current.text);

    final commonTopics = prevTopics.toSet().intersection(currTopics.toSet());
    final topicSimilarity = commonTopics.length / max(prevTopics.length, 1);

    return topicSimilarity < 0.3; // Less than 30% topic overlap
  }

  /// Summarize a message segment
  Future<String> _summarizeMessageSegment(List<_MessageSegment> segments) async {
    if (segments.isEmpty) return '';

    try {
      final allMessages = segments.expand((s) => s.messages).toList();
      return await SummarizationService.summarizeConversation(allMessages);
    } catch (e) {
      AppLogger.e('Failed to summarize message segment', e);
      // Fallback to simple concatenation
      return segments.map((s) => s.messages.map((m) => m.text).join(' ')).join(' ');
    }
  }

  /// Check memory limits and consolidate if necessary
  Future<void> _checkMemoryLimits() async {
    final metrics = _calculateCurrentMetrics();

    // Check if we need to consolidate short-term memories
    if (metrics.shortTermCount >= _config.maxShortTermMessages) {
      await _consolidateShortTermMemories();
    }

    // Check if we need to consolidate medium-term memories
    if (metrics.mediumTermCount >= _config.maxMediumTermSegments) {
      await _consolidateMediumTermMemories();
    }

    // Check if we need to consolidate long-term memories
    if (metrics.longTermCount >= _config.maxLongTermSegments) {
      await _consolidateLongTermMemories();
    }

    // Clean up expired memories
    await _cleanupExpiredMemories();
  }

  /// Consolidate short-term memories into medium-term
  Future<void> _consolidateShortTermMemories() async {
    AppLogger.d('Consolidating short-term memories');

    final shortTermMemories = _memorySegments.values
        .where((m) => m.type == MemoryType.shortTerm && !m.isExpired)
        .toList();

    if (shortTermMemories.length < 2) return;

    // Group by topics for better consolidation
    final topicGroups = <String, List<MemorySegment>>{};
    for (final memory in shortTermMemories) {
      for (final topic in memory.topics) {
        topicGroups[topic] = (topicGroups[topic] ?? [])..add(memory);
      }
    }

    // Consolidate each topic group
    for (final group in topicGroups.values) {
      if (group.length >= 2) {
        final combinedContent = group.map((m) => m.content).join(' ');
        final averageImportance = group.map((m) => m.importance).reduce((a, b) => a + b) / group.length;

        final consolidatedMemory = MemorySegment(
          id: _uuid.v4(),
          content: await _compressContent(combinedContent),
          type: averageImportance >= _config.mediumTermImportanceThreshold
              ? MemoryType.mediumTerm
              : MemoryType.shortTerm,
          importance: averageImportance,
          created: DateTime.now(),
          lastAccessed: DateTime.now(),
          accessCount: group.map((m) => m.accessCount).reduce((a, b) => a + b),
          topics: group.isEmpty ? [] : group.first.topics,
          metadata: {
            'consolidatedFrom': group.map((m) => m.id).toList(),
            'originalCount': group.length,
          },
        );

        _memorySegments[consolidatedMemory.id] = consolidatedMemory;

        // Remove original memories
        for (final memory in group) {
          _memorySegments.remove(memory.id);
        }
      }
    }
  }

  /// Consolidate medium-term memories into long-term
  Future<void> _consolidateMediumTermMemories() async {
    AppLogger.d('Consolidating medium-term memories');

    final mediumTermMemories = _memorySegments.values
        .where((m) => m.type == MemoryType.mediumTerm && !m.isExpired)
        .toList();

    if (mediumTermMemories.length < 3) return;

    // Find highly related memories for consolidation
    final consolidatedGroups = await _findRelatedMemories(mediumTermMemories);

    for (final group in consolidatedGroups) {
      final combinedContent = group.map((m) => m.content).join(' ');
      final averageImportance = group.map((m) => m.importance).reduce((a, b) => a + b) / group.length;

      final consolidatedMemory = MemorySegment(
        id: _uuid.v4(),
        content: await _compressContent(combinedContent),
        type: averageImportance >= _config.longTermImportanceThreshold
            ? MemoryType.longTerm
            : MemoryType.mediumTerm,
        importance: averageImportance,
        created: DateTime.now(),
        lastAccessed: DateTime.now(),
        accessCount: group.map((m) => m.accessCount).reduce((a, b) => a + b),
        topics: group.isEmpty ? [] : group.first.topics,
        metadata: {
          'consolidatedFrom': group.map((m) => m.id).toList(),
          'originalCount': group.length,
        },
      );

      _memorySegments[consolidatedMemory.id] = consolidatedMemory;

      // Remove original memories
      for (final memory in group) {
        _memorySegments.remove(memory.id);
      }
    }
  }

  /// Consolidate long-term memories (less aggressive)
  Future<void> _consolidateLongTermMemories() async {
    AppLogger.d('Consolidating long-term memories');

    final longTermMemories = _memorySegments.values
        .where((m) => m.type == MemoryType.longTerm && !m.isExpired)
        .toList();

    if (longTermMemories.length < 5) return;

    // Only consolidate very old, low-access long-term memories
    final oldMemories = longTermMemories
        .where((m) => m.lastAccessed.isBefore(DateTime.now().subtract(Duration(days: 7))))
        .toList();

    if (oldMemories.length >= 3) {
      await _consolidateMediumTermMemories(); // Use same logic but for long-term
    }
  }

  /// Find related memories for consolidation
  Future<List<List<MemorySegment>>> _findRelatedMemories(List<MemorySegment> memories) async {
    final groups = <List<MemorySegment>>[];

    for (final memory in memories) {
      bool addedToGroup = false;

      for (final group in groups) {
        final similarity = _calculateMemorySimilarity(memory, group.first);
        if (similarity > 0.6) { // 60% similarity threshold
          group.add(memory);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        groups.add([memory]);
      }
    }

    // Only return groups with multiple memories
    return groups.where((group) => group.length > 1).toList();
  }

  /// Calculate similarity between two memory segments
  double _calculateMemorySimilarity(MemorySegment a, MemorySegment b) {
    // Topic overlap similarity
    final commonTopics = a.topics.toSet().intersection(b.topics.toSet());
    final maxTopics = max(a.topics.length, b.topics.length);
    final topicSimilarity = maxTopics == 0 ? 0.0 : commonTopics.length / maxTopics;

    // Content similarity (simple word overlap)
    final wordsA = a.content.toLowerCase().split(RegExp(r'\s+')).toSet();
    final wordsB = b.content.toLowerCase().split(RegExp(r'\s+')).toSet();
    final commonWords = wordsA.intersection(wordsB);
    final maxWords = max(wordsA.length, wordsB.length);
    final contentSimilarity = maxWords == 0 ? 0.0 : commonWords.length / maxWords;

    // Time proximity (more recent memories are more similar)
    final timeDiff = a.created.difference(b.created).inDays.abs();
    final timeSimilarity = max(0, 1.0 - (timeDiff / 30.0)); // Decay over 30 days

    return (topicSimilarity * 0.4) + (contentSimilarity * 0.4) + (timeSimilarity * 0.2);
  }

  /// Compress content for storage efficiency
  Future<String> _compressContent(String content) async {
    if (!_config.enableMemoryCompression) {
      return content;
    }

    // Simple compression: remove extra whitespace and truncate if too long
    final compressed = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (compressed.length <= _config.maxSummarizationLength) {
      return compressed;
    }

    // If still too long, summarize the content itself
    try {
      final messages = [
        ConversationMessage(
          text: 'Please summarize this content concisely: $compressed',
          isUser: true,
          timestamp: DateTime.now(),
        )
      ];
      return await SummarizationService.summarizeConversation(messages);
    } catch (e) {
      AppLogger.e('Failed to compress content, truncating instead', e);
      return compressed.substring(0, _config.maxSummarizationLength - 100) + '...';
    }
  }

  /// Clean up expired memories
  Future<void> _cleanupExpiredMemories() async {
    final expiredKeys = _memorySegments.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memorySegments.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.d('Cleaned up ${expiredKeys.length} expired memories');
    }
  }

  /// Update memory metrics
  void _updateMemoryMetrics() {
    // This would be used to update the metrics in the conversation context
    // Implementation depends on how we want to expose this
  }

  /// Calculate current memory metrics
  MemoryMetrics _calculateCurrentMetrics() {
    final segments = _memorySegments.values;

    return MemoryMetrics(
      totalSegments: segments.length,
      shortTermCount: segments.where((m) => m.type == MemoryType.shortTerm).length,
      mediumTermCount: segments.where((m) => m.type == MemoryType.mediumTerm).length,
      longTermCount: segments.where((m) => m.type == MemoryType.longTerm).length,
      criticalCount: segments.where((m) => m.type == MemoryType.critical).length,
      averageImportance: segments.isEmpty
          ? 0.0
          : segments.map((m) => m.importance).reduce((a, b) => a + b) / segments.length,
      lastConsolidation: _lastConsolidation.values.isEmpty
          ? DateTime.now()
          : _lastConsolidation.values.reduce((a, b) => a.isAfter(b) ? a : b),
      totalAccessCount: segments.isEmpty
          ? 0
          : segments.map((m) => m.accessCount).reduce((a, b) => a + b),
    );
  }

  /// Start automatic consolidation timer
  void _startAutoConsolidation() {
    _consolidationTimer?.cancel();
    _consolidationTimer = Timer.periodic(_config.consolidationInterval, (timer) async {
      await _checkMemoryLimits();
    });
  }

  /// Get relevant memories for a given context
  List<MemorySegment> getRelevantMemories(String query, {int limit = 10}) {
    final queryTopics = _extractTopics(query);

    final scoredMemories = _memorySegments.values.map((memory) {
      double relevance = 0.0;

      // Topic relevance
      final commonTopics = queryTopics.toSet().intersection(memory.topics.toSet());
      final maxTopics = max(queryTopics.length, memory.topics.length);
      relevance += (maxTopics == 0 ? 0.0 : commonTopics.length / maxTopics) * 0.5;

      // Content similarity
      final queryWords = query.toLowerCase().split(RegExp(r'\s+')).toSet();
      final memoryWords = memory.content.toLowerCase().split(RegExp(r'\s+')).toSet();
      final commonWords = queryWords.intersection(memoryWords);
      final maxWords = max(queryWords.length, memoryWords.length);
      relevance += (maxWords == 0 ? 0.0 : commonWords.length / maxWords) * 0.3;

      // Importance factor
      relevance += memory.relevanceScore * 0.2;

      return (memory: memory, relevance: relevance);
    }).toList();

    // Sort by relevance and return top results
    scoredMemories.sort((a, b) => b.relevance.compareTo(a.relevance));

    return scoredMemories
        .take(limit)
        .map((scored) => scored.memory)
        .toList();
  }

  /// Access a memory segment (increases access count and updates last accessed time)
  void accessMemory(String memoryId) {
    final memory = _memorySegments[memoryId];
    if (memory != null) {
      _memorySegments[memoryId] = memory.copyWith(
        lastAccessed: DateTime.now(),
        accessCount: memory.accessCount + 1,
      );
    }
  }

  /// Get all memory segments
  List<MemorySegment> getAllMemories() => _memorySegments.values.toList();

  /// Get memory metrics
  MemoryMetrics getMemoryMetrics() => _calculateCurrentMetrics();

  /// Clear all memories
  void clearAllMemories() {
    _memorySegments.clear();
    _lastConsolidation.clear();
    _consolidationTimer?.cancel();
    AppLogger.i('Cleared all memories');
  }

  /// Restore a memory segment (for loading from saved context)
  void restoreMemorySegment(MemorySegment segment) {
    _memorySegments[segment.id] = segment;
  }

  /// Public method to check memory limits (for external access)
  Future<void> checkMemoryLimits() async {
    await _checkMemoryLimits();
  }

  /// Dispose of resources
  void dispose() {
    _consolidationTimer?.cancel();
  }
}

/// Helper class for grouping messages during segmentation
class _MessageSegment {
  final List<ConversationMessage> messages;
  final String summary;

  _MessageSegment(this.messages, this.summary);
}