import 'package:flutter/material.dart';
import '../models/chat_state.dart';
import '../services/safety_service.dart';
import '../utils/logger.dart';

/// Safety handler for chat functionality
class ChatSafetyHandler {
  /// Initialize safety service
  static Future<void> initializeSafetyService() async {
    AppLogger.d('Initializing safety service');
    try {
      await SafetyService.initialize();
      AppLogger.i('Safety service initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize safety service', e);
      // Error handled in service
    }
  }

  /// Check if message contains sensitive content
  static bool containsSensitiveContent(String message) {
    return SafetyService.containsSensitiveContent(message);
  }

  /// Get help resources from safety service
  static List<String> getHelpResources() {
    return SafetyService.getHelpResources();
  }

  /// Generate safe response from safety service
  static String generateSafeResponse() {
    return SafetyService.generateSafeResponse();
  }

  /// Reset safety dialog flag for new session
  static void resetSafetyDialogFlag(ChatState state) {
    state.safetyDialogShownThisSession = false;
  }
}