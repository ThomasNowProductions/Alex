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
import '../utils/logger.dart';
import '../constants/app_constants.dart';
import 'settings_screen.dart';

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

  // Summarization batching variables
  Timer? _summarizationTimer;
  DateTime? _lastSummarizationTime;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startSummarizationTimer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _speech.stop();
    _summarizationTimer?.cancel();
    _triggerSummarizationIfNeeded();
    super.dispose();
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    AppLogger.i('Initializing chat screen services');
    await _initializeConversationService();
    await _initializeSpeech();
    AppLogger.i('Chat screen services initialized');
  }

  /// Initialize conversation service
  Future<void> _initializeConversationService() async {
    AppLogger.d('Initializing conversation service');
    try {
      await ConversationService.loadContext();
      AppLogger.i('Conversation service initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize conversation service', e);
      // Error handled in service
    }
  }

  /// Initialize speech recognition
  Future<void> _initializeSpeech() async {
    AppLogger.d('Initializing speech recognition');
    try {
      _speech = stt.SpeechToText();

      // Request microphone permission first on Android
      if (PlatformUtils.isAndroid) {
        bool hasPermission = await PermissionUtils.requestMicrophonePermission(context);
        if (!hasPermission) {
          AppLogger.w('Microphone permission denied on Android');
          _speechEnabled = false;
          setState(() {});
          return;
        }
      }

      _speechEnabled = await SpeechUtils.initializeSpeech(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      AppLogger.i('Speech recognition initialized - enabled: $_speechEnabled');
      setState(() {});

      // Show platform-specific messages if needed
      if (!_speechEnabled && PlatformUtils.isLinux) {
        AppLogger.i('Speech not supported on Linux platform');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SpeechUtils.showPlatformNotSupportedMessage(context);
        });
      }
    } catch (e) {
      AppLogger.e('Failed to initialize speech recognition', e);
      _speechEnabled = false;
      setState(() {});
    }
  }

  /// Send a message
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    AppLogger.userAction('Send message');

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
      AppLogger.d('Getting AI response for user message');
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

      AppLogger.i('AI response sent to user, length: ${aiResponse.length}');
    } catch (e) {
      AppLogger.e('Failed to get AI response', e);
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

    AppLogger.userAction('Start speech recognition');
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

    AppLogger.userAction('Stop speech recognition');
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

    AppLogger.d('Speech recognition result: ${recognizedWords.length} characters');
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

  /// Check and trigger summarization if needed (improved batching logic)
  Future<void> _checkAndTriggerSummarization() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    // Check if we should summarize based on message count thresholds
    bool shouldSummarizeByCount = false;
    if (context.summary.isEmpty) {
      // No summary exists yet - wait for initial threshold
      shouldSummarizeByCount = messageCount >= AppConstants.summarizationThreshold;
    } else {
      // Summary exists - wait for update threshold
      shouldSummarizeByCount = messageCount >= AppConstants.summarizationUpdateThreshold;
    }

    // Check if we should summarize based on time interval
    bool shouldSummarizeByTime = false;
    if (_lastSummarizationTime != null) {
      final timeSinceLastSummary = DateTime.now().difference(_lastSummarizationTime!);
      shouldSummarizeByTime = timeSinceLastSummary.inMinutes >= AppConstants.summarizationTimeIntervalMinutes;
    } else if (context.summary.isNotEmpty) {
      // If we have a summary but no recorded time, assume it was recent
      shouldSummarizeByTime = false;
    }

    // Only summarize if we have enough messages and meet either criteria
    if (messageCount > 10 && (shouldSummarizeByCount || shouldSummarizeByTime)) {
      AppLogger.i('Triggering batched summarization - messages: $messageCount, time-based: $shouldSummarizeByTime');
      try {
        await _performSummarization();
        _lastSummarizationTime = DateTime.now();
      } catch (e) {
        AppLogger.e('Summarization failed during check', e);
        // Don't break chat flow on summarization error
      }
    }
  }

  /// Perform conversation summarization
  Future<void> _performSummarization() async {
    try {
      final messages = ConversationService.context.messages;
      AppLogger.d('Performing batched summarization for ${messages.length} messages');
      final summary = await SummarizationService.summarizeConversation(messages);
      ConversationService.updateSummary(summary);
      await ConversationService.saveContext();
      _lastSummarizationTime = DateTime.now();
      AppLogger.i('Batched conversation summarization completed successfully');
      // Note: _lastSummarizationTime is tracked in memory for this session
      // In a production app, you might want to persist this to shared preferences
    } catch (e) {
      // Log the UI error message for debugging
      AppLogger.e('Summarization failed - showing user-friendly message in chat: $e');

      // Show user-friendly error message as AI response in chat
      if (mounted) {
        String errorMessage = "I'm so sorry, but your hourly limit is reached.";
        setState(() {
          _messages.clear();
          _messages.add(ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
            isLoading: false,
          ));
        });
      }

      rethrow;
    }
  }

  /// Trigger summarization if needed when app is closing
  Future<void> _triggerSummarizationIfNeeded() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    // Always summarize any conversation when app closes (user's preference)
    if (messageCount > 0) {
      AppLogger.i('Triggering summarization on app close - $messageCount messages');
      try {
        await _performSummarization();
      } catch (e) {
        AppLogger.e('Summarization failed on app close: $e');
        // Ignore summarization errors on app close - don't break the close process
      }
    } else {
      AppLogger.d('No messages to summarize on app close');
    }
  }

  /// Start periodic timer for time-based summarization
  void _startSummarizationTimer() {
    _summarizationTimer = Timer.periodic(
      const Duration(minutes: AppConstants.summarizationTimeIntervalMinutes),
      (timer) {
        if (mounted) {
          _checkAndTriggerSummarization();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
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
                               fontSize: 20,
                               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                             ),
                             border: InputBorder.none,
                             contentPadding: const EdgeInsets.symmetric(
                               horizontal: 20,
                               vertical: 18,
                             ),
                             suffixIcon: _speechEnabled ? Container(
                               margin: const EdgeInsets.only(right: 8),
                               child: IconButton(
                                 onPressed: _isLoading ? null : () {
                                   if (_isListening) {
                                     _stopListening();
                                   } else {
                                     _startListening();
                                   }
                                 },
                                 icon: Icon(
                                   _isListening ? Icons.mic_off : Icons.mic,
                                   color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                                   size: 20,
                                 ),
                               ),
                             ) : null,
                           ),
                           style: GoogleFonts.playfairDisplay(
                             fontSize: 20,
                           ),
                           onSubmitted: _sendMessage,
                           autofocus: true,
                         ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  fontSize: 30,
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