import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import '../widgets/floating_snackbar.dart';
import 'platform_utils.dart';

/// Utility class for speech recognition operations
class SpeechUtils {
  /// Initialize speech recognition
  static Future<bool> initializeSpeech({
    required Function(dynamic) onError,
    required Function(String) onStatus,
  }) async {
    try {
      final speech = stt.SpeechToText();

      return await speech.initialize(
        onError: onError,
        onStatus: onStatus,
      );
    } catch (e) {
      return false;
    }
  }

  /// Start listening for speech
  static Future<bool> startListening({
    required stt.SpeechToText speech,
    required Function(dynamic) onResult,
  }) async {
    try {
      return await speech.listen(
        onResult: onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    } catch (e) {
      return false;
    }
  }

  /// Stop listening for speech
  static Future<void> stopListening(stt.SpeechToText speech) async {
    try {
      await speech.stop();
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Handle speech recognition errors
  static void handleSpeechError(BuildContext context, dynamic error) {
    String errorMessage = 'Speech recognition error occurred';

    if (error.toString().contains('no speech input')) {
      errorMessage = 'No speech input detected. Please speak louder or check your microphone.';
    } else if (error.toString().contains('recognizer not available')) {
      errorMessage = 'Speech recognizer not available. Please check microphone permissions.';
    } else if (error.toString().contains('permission')) {
      errorMessage = 'Microphone permission denied. Please enable microphone access in settings.';
    } else if (error.toString().contains('network')) {
      errorMessage = 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Speech recognition timed out. Please try again.';
    }

    if (context.mounted) {
      FloatingSnackbar.show(
        context,
        message: errorMessage,
        actionLabel: error.toString().contains('permission') ? 'Settings' : null,
        onActionPressed: error.toString().contains('permission') ? () {
          // User should be directed to app settings
        } : null,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Show platform not supported message
  static void showPlatformNotSupportedMessage(BuildContext context) {
    if (context.mounted) {
      FloatingSnackbar.show(
        context,
        message: PlatformUtils.getSpeechRecognitionMessage(),
        actionLabel: 'Got it',
        onActionPressed: () {},
        duration: const Duration(seconds: 6),
      );
    }
  }
}