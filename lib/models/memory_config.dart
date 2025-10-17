/// Configuration for memory management strategies and thresholds
class MemoryConfig {
  // Conversation length thresholds
  final int maxShortTermMessages;
  final int maxMediumTermSegments;
  final int maxLongTermSegments;

  // Importance thresholds
  final double criticalImportanceThreshold;
  final double longTermImportanceThreshold;
  final double mediumTermImportanceThreshold;

  // Timing configurations
  final Duration shortTermExpiry;
  final Duration mediumTermExpiry;
  final Duration longTermExpiry;
  final Duration consolidationInterval;

  // Performance configurations
  final int maxSummarizationLength;
  final int cacheCleanupThreshold;
  final Duration cacheExpiry;
  final bool enableAutoConsolidation;
  final bool enableMemoryCompression;

  // Quality configurations
  final double minMessageImportance;
  final int minMessageLength;
  final List<String> priorityKeywords;

  const MemoryConfig({
    this.maxShortTermMessages = 100,
    this.maxMediumTermSegments = 50,
    this.maxLongTermSegments = 25,
    this.criticalImportanceThreshold = 0.9,
    this.longTermImportanceThreshold = 0.7,
    this.mediumTermImportanceThreshold = 0.4,
    this.shortTermExpiry = const Duration(hours: 24),
    this.mediumTermExpiry = const Duration(days: 7),
    this.longTermExpiry = const Duration(days: 30),
    this.consolidationInterval = const Duration(hours: 6),
    this.maxSummarizationLength = 4000,
    this.cacheCleanupThreshold = 20,
    this.cacheExpiry = const Duration(hours: 2),
    this.enableAutoConsolidation = true,
    this.enableMemoryCompression = true,
    this.minMessageImportance = 0.1,
    this.minMessageLength = 3,
    this.priorityKeywords = const [
      'important', 'remember', 'never forget', 'critical',
      'urgent', 'priority', 'essential', 'key', 'main',
      'preferences', 'goals', 'objectives', 'plans'
    ],
  });

  MemoryConfig copyWith({
    int? maxShortTermMessages,
    int? maxMediumTermSegments,
    int? maxLongTermSegments,
    double? criticalImportanceThreshold,
    double? longTermImportanceThreshold,
    double? mediumTermImportanceThreshold,
    Duration? shortTermExpiry,
    Duration? mediumTermExpiry,
    Duration? longTermExpiry,
    Duration? consolidationInterval,
    int? maxSummarizationLength,
    int? cacheCleanupThreshold,
    Duration? cacheExpiry,
    bool? enableAutoConsolidation,
    bool? enableMemoryCompression,
    double? minMessageImportance,
    int? minMessageLength,
    List<String>? priorityKeywords,
  }) {
    return MemoryConfig(
      maxShortTermMessages: maxShortTermMessages ?? this.maxShortTermMessages,
      maxMediumTermSegments: maxMediumTermSegments ?? this.maxMediumTermSegments,
      maxLongTermSegments: maxLongTermSegments ?? this.maxLongTermSegments,
      criticalImportanceThreshold: criticalImportanceThreshold ?? this.criticalImportanceThreshold,
      longTermImportanceThreshold: longTermImportanceThreshold ?? this.longTermImportanceThreshold,
      mediumTermImportanceThreshold: mediumTermImportanceThreshold ?? this.mediumTermImportanceThreshold,
      shortTermExpiry: shortTermExpiry ?? this.shortTermExpiry,
      mediumTermExpiry: mediumTermExpiry ?? this.mediumTermExpiry,
      longTermExpiry: longTermExpiry ?? this.longTermExpiry,
      consolidationInterval: consolidationInterval ?? this.consolidationInterval,
      maxSummarizationLength: maxSummarizationLength ?? this.maxSummarizationLength,
      cacheCleanupThreshold: cacheCleanupThreshold ?? this.cacheCleanupThreshold,
      cacheExpiry: cacheExpiry ?? this.cacheExpiry,
      enableAutoConsolidation: enableAutoConsolidation ?? this.enableAutoConsolidation,
      enableMemoryCompression: enableMemoryCompression ?? this.enableMemoryCompression,
      minMessageImportance: minMessageImportance ?? this.minMessageImportance,
      minMessageLength: minMessageLength ?? this.minMessageLength,
      priorityKeywords: priorityKeywords ?? this.priorityKeywords,
    );
  }

  Map<String, dynamic> toJson() => {
    'maxShortTermMessages': maxShortTermMessages,
    'maxMediumTermSegments': maxMediumTermSegments,
    'maxLongTermSegments': maxLongTermSegments,
    'criticalImportanceThreshold': criticalImportanceThreshold,
    'longTermImportanceThreshold': longTermImportanceThreshold,
    'mediumTermImportanceThreshold': mediumTermImportanceThreshold,
    'shortTermExpiry': shortTermExpiry.inMilliseconds,
    'mediumTermExpiry': mediumTermExpiry.inMilliseconds,
    'longTermExpiry': longTermExpiry.inMilliseconds,
    'consolidationInterval': consolidationInterval.inMilliseconds,
    'maxSummarizationLength': maxSummarizationLength,
    'cacheCleanupThreshold': cacheCleanupThreshold,
    'cacheExpiry': cacheExpiry.inMilliseconds,
    'enableAutoConsolidation': enableAutoConsolidation,
    'enableMemoryCompression': enableMemoryCompression,
    'minMessageImportance': minMessageImportance,
    'minMessageLength': minMessageLength,
    'priorityKeywords': priorityKeywords,
  };

  factory MemoryConfig.fromJson(Map<String, dynamic> json) => MemoryConfig(
    maxShortTermMessages: json['maxShortTermMessages'] ?? 100,
    maxMediumTermSegments: json['maxMediumTermSegments'] ?? 50,
    maxLongTermSegments: json['maxLongTermSegments'] ?? 25,
    criticalImportanceThreshold: json['criticalImportanceThreshold'] ?? 0.9,
    longTermImportanceThreshold: json['longTermImportanceThreshold'] ?? 0.7,
    mediumTermImportanceThreshold: json['mediumTermImportanceThreshold'] ?? 0.4,
    shortTermExpiry: Duration(milliseconds: json['shortTermExpiry'] ?? 86400000),
    mediumTermExpiry: Duration(milliseconds: json['mediumTermExpiry'] ?? 604800000),
    longTermExpiry: Duration(milliseconds: json['longTermExpiry'] ?? 2592000000),
    consolidationInterval: Duration(milliseconds: json['consolidationInterval'] ?? 21600000),
    maxSummarizationLength: json['maxSummarizationLength'] ?? 4000,
    cacheCleanupThreshold: json['cacheCleanupThreshold'] ?? 20,
    cacheExpiry: Duration(milliseconds: json['cacheExpiry'] ?? 7200000),
    enableAutoConsolidation: json['enableAutoConsolidation'] ?? true,
    enableMemoryCompression: json['enableMemoryCompression'] ?? true,
    minMessageImportance: json['minMessageImportance'] ?? 0.1,
    minMessageLength: json['minMessageLength'] ?? 3,
    priorityKeywords: (json['priorityKeywords'] as List<dynamic>?)?.cast<String>() ?? const [
      'important', 'remember', 'never forget', 'critical',
      'urgent', 'priority', 'essential', 'key', 'main',
      'preferences', 'goals', 'objectives', 'plans'
    ],
  );

  // Preset configurations for different use cases
  static const MemoryConfig minimal = MemoryConfig(
    maxShortTermMessages: 50,
    maxMediumTermSegments: 20,
    maxLongTermSegments: 10,
    criticalImportanceThreshold: 0.95,
    longTermImportanceThreshold: 0.8,
    mediumTermImportanceThreshold: 0.5,
    enableAutoConsolidation: false,
    enableMemoryCompression: false,
  );

  static const MemoryConfig standard = MemoryConfig();

  static const MemoryConfig comprehensive = MemoryConfig(
    maxShortTermMessages: 200,
    maxMediumTermSegments: 100,
    maxLongTermSegments: 50,
    criticalImportanceThreshold: 0.85,
    longTermImportanceThreshold: 0.6,
    mediumTermImportanceThreshold: 0.3,
    consolidationInterval: Duration(hours: 3),
    enableAutoConsolidation: true,
    enableMemoryCompression: true,
  );
}