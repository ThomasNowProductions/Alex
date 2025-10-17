/// Service for monitoring memory performance and metrics
import 'dart:async';

class MemoryMonitor {
  static final Map<String, MemoryPerformanceSnapshot> _snapshots = {};
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;

  /// Start monitoring memory performance
  static void startMonitoring({Duration interval = const Duration(minutes: 5)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (timer) {
      _takeSnapshot();
    });

    _takeSnapshot(); // Take initial snapshot
  }

  /// Stop monitoring memory performance
  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
  }

  /// Take a performance snapshot
  static void _takeSnapshot() {
    final snapshot = MemoryPerformanceSnapshot(
      timestamp: DateTime.now(),
      totalSegments: _snapshots.values.isEmpty ? 0 : _snapshots.values.last.totalSegments,
      memoryUsage: _calculateMemoryUsage(),
      consolidationCount: _snapshots.length,
      averageResponseTime: _calculateAverageResponseTime(),
      cacheHitRate: _calculateCacheHitRate(),
    );

    _snapshots[snapshot.timestamp.toIso8601String()] = snapshot;
  }

  /// Calculate current memory usage (approximate)
  static int _calculateMemoryUsage() {
    // This is an approximation - in a real implementation you might use
    // platform channels to get actual memory usage
    final totalChars = _snapshots.values.fold(0, (sum, snapshot) => sum + snapshot.totalSegments);
    return totalChars * 2; // Approximate 2 bytes per character
  }

  /// Calculate average response time (mock implementation)
  static double _calculateAverageResponseTime() {
    // In a real implementation, you would track actual API response times
    return 150.0; // Mock average of 150ms
  }

  /// Calculate cache hit rate (mock implementation)
  static double _calculateCacheHitRate() {
    // In a real implementation, you would track cache hits vs misses
    return 0.75; // Mock 75% hit rate
  }

  /// Get performance history
  static List<MemoryPerformanceSnapshot> getPerformanceHistory() {
    return _snapshots.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get current performance metrics
  static MemoryPerformanceSnapshot? getCurrentMetrics() {
    if (_snapshots.isEmpty) return null;
    return _snapshots.values.last;
  }

  /// Get memory usage trend
  static MemoryUsageTrend getUsageTrend() {
    if (_snapshots.length < 2) {
      return MemoryUsageTrend.stable;
    }

    final recent = _snapshots.values.take(5).toList();
    final older = _snapshots.values.skip(5).take(5).toList();

    if (recent.isEmpty || older.isEmpty) {
      return MemoryUsageTrend.stable;
    }

    final recentAvg = recent.map((s) => s.memoryUsage).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((s) => s.memoryUsage).reduce((a, b) => a + b) / older.length;

    final change = (recentAvg - olderAvg) / olderAvg;

    if (change > 0.1) return MemoryUsageTrend.increasing;
    if (change < -0.1) return MemoryUsageTrend.decreasing;
    return MemoryUsageTrend.stable;
  }

  /// Clear performance history
  static void clearHistory() {
    _snapshots.clear();
  }

  /// Export performance data as JSON
  static Map<String, dynamic> exportPerformanceData() {
    return {
      'isMonitoring': _isMonitoring,
      'snapshots': _snapshots.map((key, value) => MapEntry(key, value.toJson())),
      'trend': getUsageTrend().toString(),
      'currentMetrics': getCurrentMetrics()?.toJson(),
    };
  }
}

/// Snapshot of memory performance at a specific point in time
class MemoryPerformanceSnapshot {
  final DateTime timestamp;
  final int totalSegments;
  final int memoryUsage; // Approximate bytes
  final int consolidationCount;
  final double averageResponseTime; // Milliseconds
  final double cacheHitRate; // 0.0 to 1.0

  MemoryPerformanceSnapshot({
    required this.timestamp,
    required this.totalSegments,
    required this.memoryUsage,
    required this.consolidationCount,
    required this.averageResponseTime,
    required this.cacheHitRate,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'totalSegments': totalSegments,
    'memoryUsage': memoryUsage,
    'consolidationCount': consolidationCount,
    'averageResponseTime': averageResponseTime,
    'cacheHitRate': cacheHitRate,
  };

  factory MemoryPerformanceSnapshot.fromJson(Map<String, dynamic> json) => MemoryPerformanceSnapshot(
    timestamp: DateTime.parse(json['timestamp']),
    totalSegments: json['totalSegments'],
    memoryUsage: json['memoryUsage'],
    consolidationCount: json['consolidationCount'],
    averageResponseTime: json['averageResponseTime'],
    cacheHitRate: json['cacheHitRate'],
  );
}

/// Trend of memory usage over time
enum MemoryUsageTrend {
  increasing,
  decreasing,
  stable,
}