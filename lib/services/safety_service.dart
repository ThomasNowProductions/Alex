import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/logger.dart';

class SafetyService {
  static List<String> _sensitiveKeywords = [];
  static Map<String, List<String>> _helpResources = {};
  static bool _initialized = false;

  /// Initialize the safety service by loading sensitive keywords and help resources
  static Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.i('Initializing safety service');
    try {
      await _loadSensitiveKeywords();
      await _loadHelpResources();
      _initialized = true;
      AppLogger.i('Safety service initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize safety service', e);
      throw Exception('Failed to initialize safety service: $e');
    }
  }

  /// Load sensitive keywords from assets
  static Future<void> _loadSensitiveKeywords() async {
    try {
      AppLogger.d('Loading sensitive keywords from assets/sensitive_keywords.json');
      final String response = await rootBundle.loadString('assets/sensitive_keywords.json');
      final data = jsonDecode(response);
      _sensitiveKeywords = List<String>.from(data['keywords'] ?? []);
      AppLogger.i('Loaded ${_sensitiveKeywords.length} sensitive keywords');
    } catch (e) {
      AppLogger.e('Failed to load sensitive keywords', e);
      // Fallback keywords if file doesn't exist
      _sensitiveKeywords = [
        'kill myself', 'kill me', 'end it all', 'end my life', 'take my life',
        'hang myself', 'shoot myself', 'jump off', 'jump from', 'overdose',
        'cut myself', 'cutting', 'self harm', 'self-harm', 'hurt myself',
        'harm myself', 'suicide', 'suicidal', 'want to die', 'wish I was dead',
        'rather be dead', 'feel like dying', 'thinking about ending it',
        'planning to end it', 'how to kill myself', 'ways to die',
        'not worth living', 'life not worth living', 'can\'t go on',
        'don\'t want to live', 'no reason to live', 'life is meaningless',
        'can\'t take it anymore', 'at my breaking point', 'feel like ending it'
      ];
      AppLogger.i('Using fallback sensitive keywords: ${_sensitiveKeywords.length}');
    }
  }

  /// Load help resources from assets
  static Future<void> _loadHelpResources() async {
    try {
      AppLogger.d('Loading help resources from assets/help_resources.json');
      final String response = await rootBundle.loadString('assets/help_resources.json');
      final data = jsonDecode(response);
      final Map<String, dynamic> resourcesData = data['resources'] ?? {};

      // Convert List<dynamic> to List<String> for each category
      _helpResources = {};
      resourcesData.forEach((category, resourceList) {
        _helpResources[category] = List<String>.from(resourceList ?? []);
      });

      AppLogger.i('Loaded help resources for ${_helpResources.length} categories');
    } catch (e) {
      AppLogger.e('Failed to load help resources', e);
      // Fallback help resources if file doesn't exist
      _helpResources = {
        'crisis': [
          '988 Suicide & Crisis Lifeline (US): Call or text 988',
          'Crisis Text Line: Text HOME to 741741',
          'International Association for Suicide Prevention: Find local help at befrienders.org'
        ],
        'mental_health': [
          'National Alliance on Mental Illness (NAMI): 1-800-950-6264',
          'Mental Health America: mhanational.org/find-support',
          'Psychology Today: psychologytoday.com to find therapists'
        ],
        'emergency': [
          'Emergency Services: Call 911 (US) or your local emergency number',
          'If you are in immediate danger, please contact emergency services immediately'
        ]
      };
      AppLogger.i('Using fallback help resources');
    }
  }

  /// Check if a message contains sensitive content
  static bool containsSensitiveContent(String message) {
    if (!_initialized) {
      AppLogger.w('Safety service not initialized, skipping content check');
      return false;
    }

    final lowerMessage = message.toLowerCase();

    // Check for sensitive keywords
    for (final keyword in _sensitiveKeywords) {
      if (lowerMessage.contains(keyword.toLowerCase())) {
        AppLogger.w('Sensitive content detected: $keyword');
        return true;
      }
    }

    return false;
  }

  /// Get appropriate help resources for sensitive content
  static List<String> getHelpResources() {
    if (!_initialized) {
      AppLogger.w('Safety service not initialized, returning empty resources');
      return [];
    }

    // Return all available resources for maximum support
    final allResources = <String>[];
    _helpResources.forEach((category, resources) {
      allResources.addAll(resources);
    });

    return allResources;
  }

  /// Get specific help resources by category
  static List<String> getHelpResourcesByCategory(String category) {
    if (!_initialized) {
      AppLogger.w('Safety service not initialized, returning empty resources');
      return [];
    }

    return _helpResources[category] ?? [];
  }

  /// Generate a safe response for sensitive content
  static String generateSafeResponse() {
    return "I'm really concerned about what you're going through, and I want you to know that you're not alone. Please reach out to professionals who are trained to help in situations like this. Here are some resources that can provide immediate support:";
  }

  /// Check if safety service is initialized
  static bool get isInitialized => _initialized;
}