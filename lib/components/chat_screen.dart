import 'package:flutter/material.dart';
import '../models/chat_state.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_ui_components.dart';
import '../services/chat_business_logic.dart';
import '../services/chat_speech_handler.dart';
import '../services/chat_summarization_handler.dart';
import '../services/chat_safety_handler.dart';
import '../services/conversation_service.dart';
import '../utils/logger.dart';
import 'settings_screen.dart';

/// Main chat screen component that handles the chat interface
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatState _state = ChatState();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startSummarizationTimer();
    ChatSafetyHandler.resetSafetyDialogFlag(_state);
  }

  @override
  void dispose() {
    _state.dispose();
    _state.summarizationTimer?.cancel();
    ChatSummarizationHandler.triggerSummarizationIfNeeded(_state);
    super.dispose();
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    AppLogger.i('Initializing chat screen services');
    await ConversationService.initialize();
    await ChatSafetyHandler.initializeSafetyService();
    await ChatSpeechHandler.initializeSpeech(context, _state, (fn) => setState(fn));
    AppLogger.i('Chat screen services initialized');
  }

  /// Start periodic timer for time-based summarization
  void _startSummarizationTimer() {
    ChatSummarizationHandler.startSummarizationTimer(_state, (fn) => setState(fn));
  }

  /// Send a message using the business logic service
  Future<void> _sendMessage(String message) async {
    await ChatBusinessLogic.sendMessage(
      context,
      _state,
      message,
      (loading) => setState(() => _state.isLoading = loading),
      (messages) => setState(() {
        _state.messages.clear();
        _state.messages.addAll(messages);
      }),
    );
  }

  /// Toggle speech recognition
  Future<void> _toggleSpeechRecognition() async {
    await ChatSpeechHandler.toggleSpeechRecognition(_state);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChatUIComponents.buildChatLayout(
      context: context,
      child: _state.messages.isEmpty
          ? ChatUIComponents.buildEmptyState(context, _state.currentWelcomeMessage)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_state.messages.isNotEmpty)
                        _state.messages[0],
                    ],
                  ),
                ),
              ),
            ),
      bottomInput: Row(
        children: [
          Expanded(
            child: ChatUIComponents.buildInputField(
              context,
              _state,
              _state.currentPlaceholderText,
              _sendMessage,
              _toggleSpeechRecognition,
            ),
          ),
          const SizedBox(width: 12),
          ChatUIComponents.buildSendButton(
            context,
            _state.isLoading,
            () => _sendMessage(_state.messageController.text),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        mini: true,
        child: const Icon(Icons.settings, size: 16),
      ),
    );
  }
}