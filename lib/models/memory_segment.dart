/// Model representing a segment of memory with importance scoring and metadata
class MemorySegment {
  final String id;
  final String content;
  final MemoryType type;
  final double importance;
  final DateTime created;
  final DateTime lastAccessed;
  final int accessCount;
  final List<String> topics;
  final Map<String, dynamic> metadata;

  MemorySegment({
    required this.id,
    required this.content,
    required this.type,
    required this.importance,
    required this.created,
    required this.lastAccessed,
    required this.accessCount,
    required this.topics,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.toString(),
    'importance': importance,
    'created': created.toIso8601String(),
    'lastAccessed': lastAccessed.toIso8601String(),
    'accessCount': accessCount,
    'topics': topics,
    'metadata': metadata,
  };

  factory MemorySegment.fromJson(Map<String, dynamic> json) => MemorySegment(
    id: json['id'],
    content: json['content'],
    type: MemoryType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => MemoryType.shortTerm,
    ),
    importance: json['importance'] ?? 0.5,
    created: DateTime.parse(json['created']),
    lastAccessed: DateTime.parse(json['lastAccessed']),
    accessCount: json['accessCount'] ?? 0,
    topics: (json['topics'] as List<dynamic>?)?.cast<String>() ?? [],
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );

  MemorySegment copyWith({
    String? id,
    String? content,
    MemoryType? type,
    double? importance,
    DateTime? created,
    DateTime? lastAccessed,
    int? accessCount,
    List<String>? topics,
    Map<String, dynamic>? metadata,
  }) {
    return MemorySegment(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      importance: importance ?? this.importance,
      created: created ?? this.created,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      topics: topics ?? this.topics,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    final age = now.difference(created);

    switch (type) {
      case MemoryType.shortTerm:
        return age > Duration(hours: 24);
      case MemoryType.mediumTerm:
        return age > Duration(days: 7);
      case MemoryType.longTerm:
        return age > Duration(days: 30);
      case MemoryType.critical:
        return false; // Critical memories never expire
    }
  }

  double get relevanceScore {
    final age = DateTime.now().difference(lastAccessed);
    final ageDays = age.inDays;

    // Decay importance based on time since last access
    double decayFactor = 1.0;
    if (ageDays > 0) {
      decayFactor = 1.0 / (1.0 + ageDays * 0.1);
    }

    // Boost score based on access count
    double accessBoost = 1.0 + (accessCount * 0.1);

    return importance * decayFactor * accessBoost;
  }
}

enum MemoryType {
  shortTerm,    // Recent conversations, expires quickly
  mediumTerm,   // Important topics, expires in days
  longTerm,     // Core preferences and facts, expires in weeks
  critical,     // Essential information, never expires
}

class MemoryMetrics {
  final int totalSegments;
  final int shortTermCount;
  final int mediumTermCount;
  final int longTermCount;
  final int criticalCount;
  final double averageImportance;
  final DateTime lastConsolidation;
  final int totalAccessCount;

  MemoryMetrics({
    required this.totalSegments,
    required this.shortTermCount,
    required this.mediumTermCount,
    required this.longTermCount,
    required this.criticalCount,
    required this.averageImportance,
    required this.lastConsolidation,
    required this.totalAccessCount,
  });

  factory MemoryMetrics.empty() => MemoryMetrics(
    totalSegments: 0,
    shortTermCount: 0,
    mediumTermCount: 0,
    longTermCount: 0,
    criticalCount: 0,
    averageImportance: 0.0,
    lastConsolidation: DateTime.now(),
    totalAccessCount: 0,
  );

  Map<String, dynamic> toJson() => {
    'totalSegments': totalSegments,
    'shortTermCount': shortTermCount,
    'mediumTermCount': mediumTermCount,
    'longTermCount': longTermCount,
    'criticalCount': criticalCount,
    'averageImportance': averageImportance,
    'lastConsolidation': lastConsolidation.toIso8601String(),
    'totalAccessCount': totalAccessCount,
  };

  factory MemoryMetrics.fromJson(Map<String, dynamic> json) => MemoryMetrics(
    totalSegments: json['totalSegments'] ?? 0,
    shortTermCount: json['shortTermCount'] ?? 0,
    mediumTermCount: json['mediumTermCount'] ?? 0,
    longTermCount: json['longTermCount'] ?? 0,
    criticalCount: json['criticalCount'] ?? 0,
    averageImportance: json['averageImportance'] ?? 0.0,
    lastConsolidation: DateTime.parse(json['lastConsolidation']),
    totalAccessCount: json['totalAccessCount'] ?? 0,
  );

  MemoryMetrics copyWith({
    int? totalSegments,
    int? shortTermCount,
    int? mediumTermCount,
    int? longTermCount,
    int? criticalCount,
    double? averageImportance,
    DateTime? lastConsolidation,
    int? totalAccessCount,
  }) {
    return MemoryMetrics(
      totalSegments: totalSegments ?? this.totalSegments,
      shortTermCount: shortTermCount ?? this.shortTermCount,
      mediumTermCount: mediumTermCount ?? this.mediumTermCount,
      longTermCount: longTermCount ?? this.longTermCount,
      criticalCount: criticalCount ?? this.criticalCount,
      averageImportance: averageImportance ?? this.averageImportance,
      lastConsolidation: lastConsolidation ?? this.lastConsolidation,
      totalAccessCount: totalAccessCount ?? this.totalAccessCount,
    );
  }
}