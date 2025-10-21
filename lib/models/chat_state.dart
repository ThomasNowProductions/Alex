import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../constants/chat_constants.dart';
import '../widgets/chat_message.dart';

/// State management class for the chat screen
class ChatState {
  // Controllers
  final TextEditingController messageController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // Messages and UI state
  final List<ChatMessage> messages = [];
  bool isLoading = false;

  // Current dynamic content
  late String currentWelcomeMessage;
  late String currentPlaceholderText;

  // Speech recognition state
  late stt.SpeechToText speech;
  bool isListening = false;
  bool speechEnabled = false;
  String lastWords = '';

  // Summarization state
  Timer? summarizationTimer;
  DateTime? lastSummarizationTime;

  // Safety state
  bool safetyDialogShownThisSession = false;

  /// Constructor - initialize dynamic content
  ChatState() {
    currentWelcomeMessage = _getRandomWelcomeMessage();
    currentPlaceholderText = _getRandomPlaceholderText();
  }

  /// Get a random welcome message from the available options
  String _getRandomWelcomeMessage() {
    final random = DateTime.now().millisecondsSinceEpoch % ChatConstants.welcomeMessages.length;
    return ChatConstants.welcomeMessages[random];
  }

  /// Get a random placeholder text from the available options
  String _getRandomPlaceholderText() {
    final random = DateTime.now().millisecondsSinceEpoch % ChatConstants.placeholderTexts.length;
    return ChatConstants.placeholderTexts[random];
  }

  /// Refresh the welcome message with a new random selection
  void refreshWelcomeMessage() {
    currentWelcomeMessage = _getRandomWelcomeMessage();
  }

  /// Dispose of all resources
  void dispose() {
    focusNode.dispose();
    messageController.dispose();
    speech.stop();
    summarizationTimer?.cancel();
  }
}