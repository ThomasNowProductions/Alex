import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'conversation_service.dart';

/// Service for managing user settings and preferences
class SettingsService {
  static const String _fileName = 'user_settings.json';

  // Default settings - only theme preferences
  static const Map<String, dynamic> _defaultSettings = {
    'themeMode': 'system', // 'light', 'dark', 'system'
  };

  static Map<String, dynamic> _settings = Map.from(_defaultSettings);

  // Stream controller for theme changes
  static final StreamController<String> _themeController = StreamController<String>.broadcast();
  static Stream<String> get themeChangeStream => _themeController.stream;

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  static Map<String, dynamic> get settings => Map.from(_settings);

  /// Load settings from local storage
  static Future<void> loadSettings() async {
    AppLogger.d('Loading user settings from local storage');
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _settings = Map.from(_defaultSettings)..addAll(data);
        AppLogger.i('User settings loaded successfully');
      } else {
        AppLogger.i('No existing settings file found, using defaults');
        _settings = Map.from(_defaultSettings);
      }
    } catch (e) {
      AppLogger.e('Error loading user settings', e);
      _settings = Map.from(_defaultSettings);
    }
  }

  /// Save settings to local storage
  static Future<void> saveSettings() async {
    AppLogger.d('Saving user settings to local storage');
    try {
      final file = await _localFile;
      final contents = jsonEncode(_settings);
      await file.writeAsString(contents);
      AppLogger.i('User settings saved successfully');
    } catch (e) {
      AppLogger.e('Error saving user settings', e);
    }
  }

  /// Get a specific setting value
  static T getSetting<T>(String key, T defaultValue) {
    return _settings.containsKey(key) ? _settings[key] as T : defaultValue;
  }

  /// Set a specific setting value
  static void setSetting(String key, dynamic value) {
    _settings[key] = value;
    AppLogger.d('Setting updated: $key = $value');

    // Notify listeners if theme mode changed
    if (key == 'themeMode') {
      _themeController.add(value);
    }
  }

  /// Reset settings to default
  static void resetSettings() {
    _settings = Map.from(_defaultSettings);
    AppLogger.i('User settings reset to defaults');
  }

  // Convenience getter for theme setting
  static String get themeMode => getSetting('themeMode', 'system');

  /// Clear all conversation history
  static Future<void> clearAllHistory() async {
    AppLogger.i('Clearing all conversation history');
    await ConversationService.clearAllHistory();
  }
}