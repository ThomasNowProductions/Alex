import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/chat_state.dart';
import '../utils/platform_utils.dart';
import '../utils/permission_utils.dart';
import '../utils/speech_utils.dart';
import '../utils/logger.dart';

/// Speech recognition handler for chat functionality
class ChatSpeechHandler {
  /// Initialize speech recognition
  static Future<void> initializeSpeech(
    BuildContext context,
    ChatState state,
    Function(void Function()) setState,
  ) async {
    AppLogger.d('Initializing speech recognition');
    try {
      state.speech = stt.SpeechToText();

      // Request microphone permission first on Android
      if (PlatformUtils.isAndroid) {
        bool hasPermission = await PermissionUtils.requestMicrophonePermission(context);
        if (!hasPermission) {
          AppLogger.w('Microphone permission denied on Android');
          state.speechEnabled = false;
          setState(() {});
          return;
        }
      }

      state.speechEnabled = await SpeechUtils.initializeSpeech(
        onError: (error) => handleSpeechError(context, state, error),
        onStatus: (status) => handleSpeechStatus(state, status, setState),
      );

      AppLogger.i('Speech recognition initialized - enabled: ${state.speechEnabled}');
      setState(() {});

      // Show platform-specific messages if needed
      if (!state.speechEnabled && PlatformUtils.isLinux) {
        AppLogger.i('Speech not supported on Linux platform');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SpeechUtils.showPlatformNotSupportedMessage(context);
        });
      }
    } catch (e) {
      AppLogger.e('Failed to initialize speech recognition', e);
      state.speechEnabled = false;
      setState(() {});
    }
  }

  /// Start speech recognition
  static Future<void> startListening(ChatState state) async {
    if (!state.speechEnabled || state.isListening) return;

    AppLogger.userAction('Start speech recognition');
    state.isListening = true;
    state.lastWords = '';
    state.messageController.clear();

    await SpeechUtils.startListening(
      speech: state.speech,
      onResult: (result) => handleSpeechResult(state, result),
    );
  }

  /// Stop speech recognition
  static Future<void> stopListening(ChatState state) async {
    if (!state.isListening) return;

    AppLogger.userAction('Stop speech recognition');
    state.isListening = false;

    await SpeechUtils.stopListening(state.speech);

    // Populate text field with speech results
    if (state.lastWords.isNotEmpty) {
      state.messageController.text = state.lastWords;
      state.messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: state.lastWords.length),
      );
    }
  }

  /// Handle speech recognition results
  static void handleSpeechResult(ChatState state, dynamic result) {
    String recognizedWords = '';
    if (result != null) {
      if (result.recognizedWords != null) {
        recognizedWords = result.recognizedWords;
      } else if (result.recognizedText != null) {
        recognizedWords = result.recognizedText;
      } else if (result.text != null) {
        recognizedWords = result.text;
      } else if (result.toString().isNotEmpty) {
        recognizedWords = result.toString();
      }
    }

    AppLogger.d('Speech recognition result: ${recognizedWords.length} characters');
    state.lastWords = recognizedWords;
    state.messageController.text = recognizedWords;
  }

  /// Handle speech recognition errors
  static void handleSpeechError(BuildContext context, ChatState state, dynamic error) {
    state.isListening = false;
    SpeechUtils.handleSpeechError(context, error);
  }

  /// Handle speech recognition status changes
  static void handleSpeechStatus(ChatState state, String status, Function(void Function()) setState) {
    if (status == 'done' || status == 'notListening') {
      state.isListening = false;
      setState(() {});
    }
  }

  /// Toggle speech recognition (start/stop)
  static Future<void> toggleSpeechRecognition(ChatState state) async {
    if (state.isListening) {
      await stopListening(state);
    } else {
      await startListening(state);
    }
  }
}