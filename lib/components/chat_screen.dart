import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../widgets/chat_message.dart';
import '../services/conversation_service.dart';
import '../services/ollama_service.dart';
import '../services/summarization_service.dart';
import '../utils/platform_utils.dart';
import '../utils/permission_utils.dart';
import '../utils/speech_utils.dart';
import '../constants/app_constants.dart';

/// Main chat screen component that handles the chat interface
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Speech recognition variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _speech.stop();
    _triggerSummarizationIfNeeded();
    super.dispose();
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    await _initializeConversationService();
    await _initializeSpeech();
  }

  /// Initialize conversation service
  Future<void> _initializeConversationService() async {
    try {
      await ConversationService.loadContext();
    } catch (e) {
      // Error handled in service
    }
  }

  /// Initialize speech recognition
  Future<void> _initializeSpeech() async {
    try {
      _speech = stt.SpeechToText();

      // Request microphone permission first on Android
      if (PlatformUtils.isAndroid) {
        bool hasPermission = await PermissionUtils.requestMicrophonePermission(context);
        if (!hasPermission) {
          _speechEnabled = false;
          setState(() {});
          return;
        }
      }

      _speechEnabled = await SpeechUtils.initializeSpeech(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      setState(() {});

      // Show platform-specific messages if needed
      if (!_speechEnabled && PlatformUtils.isLinux) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SpeechUtils.showPlatformNotSupportedMessage(context);
        });
      }
    } catch (e) {
      _speechEnabled = false;
      setState(() {});
    }
  }

  /// Send a message
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Stop speech recognition if it's active
    if (_isListening) {
      await _stopListening();
    }

    // Save user message to conversation history
    ConversationService.addMessage(message, true);

    // Clear input immediately
    _messageController.clear();
    _focusNode.requestFocus();

    setState(() {
      _isLoading = true;
      _messages.clear();
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    try {
      // Get AI response
      final aiResponse = await _getAIResponse(message);

      // Save AI response to conversation history
      ConversationService.addMessage(aiResponse, false);

      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't process your message right now.",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      await ConversationService.saveContext();
      await _checkAndTriggerSummarization();
    }
  }

  /// Get AI response from Ollama service
  Future<String> _getAIResponse(String userMessage) async {
    return await OllamaService.getCompletion(userMessage);
  }

  /// Start speech recognition
  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening) return;

    setState(() {
      _isListening = true;
      _lastWords = '';
      _messageController.clear();
    });

    await SpeechUtils.startListening(
      speech: _speech,
      onResult: _onSpeechResult,
    );
  }

  /// Stop speech recognition
  Future<void> _stopListening() async {
    if (!_isListening) return;

    setState(() {
      _isListening = false;
    });

    await SpeechUtils.stopListening(_speech);

    // Populate text field with speech results
    if (_lastWords.isNotEmpty) {
      _messageController.text = _lastWords;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _lastWords.length),
      );
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(dynamic result) {
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

    setState(() {
      _lastWords = recognizedWords;
      _messageController.text = recognizedWords;
    });
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    setState(() {
      _isListening = false;
    });
    SpeechUtils.handleSpeechError(context, error);
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Check and trigger summarization if needed
  Future<void> _checkAndTriggerSummarization() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    if ((messageCount > AppConstants.summarizationThreshold && context.summary.isEmpty) ||
        messageCount > AppConstants.summarizationUpdateThreshold) {
      try {
        await _performSummarization();
      } catch (e) {
        // Don't break chat flow on summarization error
      }
    }
  }

  /// Perform conversation summarization
  Future<void> _performSummarization() async {
    try {
      final messages = ConversationService.context.messages;
      final summary = await SummarizationService.summarizeConversation(messages);
      ConversationService.updateSummary(summary);
      await ConversationService.saveContext();
    } catch (e) {
      rethrow;
    }
  }

  /// Trigger summarization if needed when app is closing
  Future<void> _triggerSummarizationIfNeeded() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    bool shouldSummarize = false;
    if (messageCount > 20 && context.summary.isEmpty) {
      shouldSummarize = true;
    } else if (messageCount > 50) {
      shouldSummarize = true;
    } else if (messageCount > 0) {
      shouldSummarize = true;
    }

    if (shouldSummarize) {
      try {
        await _performSummarization();
      } catch (e) {
        // Ignore summarization errors on app close
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Centered chat content
            Positioned.fill(
              top: 0,
              bottom: 120,
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _messages.isNotEmpty
                      ? Center(child: _messages[0])
                      : const SizedBox(),
            ),

            // Floating input at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: AppConstants.inputPadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Express yourself...',
                            hintStyle: GoogleFonts.playfairDisplay(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.playfairDisplay(),
                          onSubmitted: _sendMessage,
                          autofocus: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Microphone button for speech recognition
                    if (_speechEnabled)
                      _buildMicrophoneButton(),
                    if (_speechEnabled) const SizedBox(width: 8),
                    // Send button
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                    blurRadius: 80,
                    spreadRadius: 15,
                  ),
                ],
              ),
              width: AppConstants.glowEffectWidth,
              height: AppConstants.glowEffectWidth,
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * AppConstants.chatBubbleMaxWidth,
              ),
              child: Text(
                'Hey, whatsup?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build microphone button
  Widget _buildMicrophoneButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isListening ? Colors.red : Theme.of(context).colorScheme.secondary,
        boxShadow: [
          BoxShadow(
            color: (_isListening
                ? Colors.red
                : Theme.of(context).colorScheme.secondary).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _isLoading || !_speechEnabled ? null : () {
          if (_isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
        icon: Icon(
          _isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
        iconSize: 20,
      ),
    );
  }


  /// Build send button
  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
        icon: const Icon(Icons.send, color: Colors.white),
        iconSize: 20,
      ),
    );
  }
}