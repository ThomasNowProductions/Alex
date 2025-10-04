import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'services/ollama_service.dart';
import 'services/conversation_service.dart';
import 'services/summarization_service.dart';
import 'dart:async';
import 'dart:io' show Platform;

// Custom floating snackbar widget
class FloatingSnackbar extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Duration duration;
  final bool showCloseButton;

  const FloatingSnackbar({
    super.key,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.duration = const Duration(seconds: 4),
    this.showCloseButton = true,
  });

  @override
  State<FloatingSnackbar> createState() => _FloatingSnackbarState();

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool showCloseButton = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: FloatingSnackbar(
            message: message,
            actionLabel: actionLabel,
            onActionPressed: onActionPressed,
            duration: duration,
            showCloseButton: showCloseButton,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _FloatingSnackbarState extends State<FloatingSnackbar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      // Find the OverlayEntry and remove it
      Overlay.of(context).mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onActionPressed!();
                        _dismiss();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  if (widget.showCloseButton) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _dismiss,
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void main() async {
  await dotenv.load(fileName: 'assets/.env');
  runApp(const FraintedApp());
}

class FraintedApp extends StatelessWidget {
  const FraintedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alex - AI Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}

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
    // Request focus to keep input field focused
    _focusNode.requestFocus();

    setState(() {
      _isLoading = true;
      // Show thinking state with blue glow (no text)
      _messages.clear();
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    try {
      // Get AI response from Ollama Cloud API with conversation context
      final aiResponse = await _getAIResponse(message);

      // Save AI response to conversation history
      ConversationService.addMessage(aiResponse, false);

      setState(() {
        // Only keep the most recent response
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
        // Only keep the most recent error response
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
      // Save conversation context after each exchange
      await ConversationService.saveContext();

      // Check if we should trigger summarization after this exchange
      await _checkAndTriggerSummarization();
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    return await OllamaService.getCompletion(userMessage);
  }

  // Conversation service initialization
  Future<void> _initializeConversationService() async {
    print('=== INITIALIZING CONVERSATION SERVICE ===');
    try {
      await ConversationService.loadContext();
      print('✅ Conversation context loaded successfully');
      print('📊 Loaded ${ConversationService.context.messages.length} previous messages');
      if (ConversationService.context.summary.isNotEmpty) {
        print('📋 Found existing summary');
      }
    } catch (e) {
      print('❌ Error initializing conversation service: $e');
    }
  }

  // Permission methods
  Future<bool> _requestMicrophonePermission() async {
    print('=== MICROPHONE PERMISSION REQUEST STARTED ===');
    print('Platform: ${Platform.operatingSystem}');

    if (Platform.isAndroid) {
      print('🔍 Requesting microphone permission on Android...');

      try {
        // Check current permission status first
        PermissionStatus currentStatus = await Permission.microphone.status;
        print('Current microphone permission status: $currentStatus');

        print('📱 Requesting microphone permission...');
        PermissionStatus status = await Permission.microphone.request();
        print('Permission request result: $status');

        if (status.isGranted) {
          print('✅ Microphone permission granted successfully');
          return true;
        } else if (status.isDenied) {
          print('❌ Microphone permission denied by user');
          if (mounted) {
            FloatingSnackbar.show(
              context,
              message: 'Microphone permission is required for speech recognition. Please grant permission in app settings.',
              actionLabel: 'Settings',
              onActionPressed: openAppSettings,
              duration: const Duration(seconds: 4),
            );
          }
          return false;
        } else if (status.isPermanentlyDenied) {
          print('🚫 Microphone permission permanently denied');
          if (mounted) {
            FloatingSnackbar.show(
              context,
              message: 'Microphone permission is permanently denied. Please enable it in app settings to use speech recognition.',
              actionLabel: 'Settings',
              onActionPressed: openAppSettings,
              duration: const Duration(seconds: 4),
            );
          }
          return false;
        } else {
          print('❓ Unknown permission status: $status');
          return false;
        }
      } catch (e) {
        print('❌ Error requesting microphone permission: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS handles permissions differently, rely on speech_to_text package
      print('🍎 iOS - letting speech_to_text handle permissions');
      return true;
    } else {
      print('❓ Unknown platform: ${Platform.operatingSystem}');
    }

    print('❌ Permission request failed for unknown reason');
    return false;
  }

  // Speech recognition methods
    Future<void> _initializeSpeech() async {
      print('=== SPEECH RECOGNITION INITIALIZATION STARTED ===');
      print('Creating SpeechToText instance...');

      try {
        _speech = stt.SpeechToText();
        print('✅ SpeechToText instance created successfully');
      } catch (e) {
        print('❌ Failed to create SpeechToText instance: $e');
        _speechEnabled = false;
        setState(() {});
        return;
      }

      // Request microphone permission first on Android
      if (Platform.isAndroid) {
        print('🤖 Android platform detected - requesting microphone permission first');
        bool hasPermission = await _requestMicrophonePermission();
        if (!hasPermission) {
          print('❌ Cannot initialize speech recognition without microphone permission');
          _speechEnabled = false;
          setState(() {});
          return;
        } else {
          print('✅ Microphone permission granted, proceeding with speech initialization');
        }
      } else {
        print('🍎 Non-Android platform (${Platform.operatingSystem}) - skipping manual permission request');
      }

      // Platform-specific checks
      if (Platform.isAndroid) {
        print('🤖 Running on Android - checking speech recognition compatibility...');
      } else if (Platform.isIOS) {
        print('🍎 Running on iOS - speech recognition should be available');
      } else {
        print('❌ Running on ${Platform.operatingSystem} - speech recognition not supported');
        print('Speech recognition is only available on Android and iOS devices');
        _speechEnabled = false;
        setState(() {});

        // Show message after widget is built to avoid ScaffoldMessenger error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showPlatformNotSupportedMessage();
          }
        });
        return;
      }

      try {
        print('🎤 Initializing speech recognition...');
        print('Calling _speech.initialize() with callbacks...');

        _speechEnabled = await _speech.initialize(
          onError: _onSpeechError,
          onStatus: _onSpeechStatus,
        );

        print('🎤 Speech recognition initialization result: $_speechEnabled');

        if (!_speechEnabled) {
          print('❌ Speech recognition not available on this device');
          String platformMessage = Platform.isAndroid
              ? 'Speech recognition not available. Please check microphone permissions and try restarting the app.'
              : 'Speech recognition not available on this device';

          print('Platform message: $platformMessage');

          // Show user-friendly message
          if (mounted) {
            FloatingSnackbar.show(
              context,
              message: platformMessage,
              duration: const Duration(seconds: 4),
            );
          }
        } else {
          print('✅ Speech recognition is available and ready to use');
          if (Platform.isAndroid) {
            print('🤖 Android speech recognition successfully initialized');
          } else {
            print('✅ Speech recognition successfully initialized on ${Platform.operatingSystem}');
          }
        }
        print('🔄 Calling setState() to update UI...');
        setState(() {});
        print('✅ setState() completed');
      } catch (e) {
        print('❌ Speech initialization error: $e');
        print('Error type: ${e.runtimeType}');
        print('Platform: ${Platform.operatingSystem}');
        print('Error message: ${e.toString()}');

        _speechEnabled = false;

        print('🔄 Calling setState() after error...');
        setState(() {});
        print('✅ setState() completed after error');

        // Platform-specific error messages
        String errorMessage = 'Speech recognition is not available on this device.';
        String actionLabel = '';
        VoidCallback? action;

        if (e.toString().contains('MissingPluginException') || e.toString().contains('No implementation found')) {
          errorMessage = 'Speech recognition is not supported on ${Platform.operatingSystem}. Please use an Android or iOS device.';
        } else if (Platform.isAndroid && e.toString().contains('permission')) {
          errorMessage = 'Microphone permission required for speech recognition. Please grant permission in app settings.';
          actionLabel = 'Settings';
          action = () {
            print('Opening Android app settings for microphone permission');
            openAppSettings();
          };
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else {
          errorMessage = 'Speech recognition initialization failed. Please try restarting the app.';
        }

        print('Error message to show user: $errorMessage');

        // Show error to user
        if (mounted) {
          FloatingSnackbar.show(
            context,
            message: errorMessage,
            actionLabel: action != null ? actionLabel : null,
            onActionPressed: action,
            duration: const Duration(seconds: 5),
          );
        }
      }
    }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening) {
      print('❌ Cannot start listening - Speech enabled: $_speechEnabled, Is listening: $_isListening');
      return;
    }

    print('=== STARTING SPEECH LISTENING ===');
    print('Speech enabled: $_speechEnabled');
    print('Currently listening: $_isListening');

    setState(() {
      _isListening = true;
      _lastWords = '';
      _messageController.clear(); // Clear text field when starting
    });

    print('✅ UI state updated - Is listening: $_isListening');

    try {
      print('🎤 Calling _speech.listen()...');
      print('Listen parameters:');
      print('  listenFor: 30 seconds');
      print('  pauseFor: 5 seconds');
      print('  onResult callback: ${_onSpeechResult.toString()}');

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );

      print('✅ _speech.listen() completed successfully');
    } catch (e) {
      print('❌ Speech listening error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) {
      print('❌ Cannot stop listening - not currently listening');
      return;
    }

    print('=== STOPPING SPEECH LISTENING ===');
    print('Currently listening: $_isListening');
    print('Last words before stop: "$_lastWords"');
    print('Text field content before stop: "${_messageController.text}"');

    setState(() {
      _isListening = false;
    });

    print('✅ UI state updated - Is listening: $_isListening');

    try {
      print('🛑 Calling _speech.stop()...');
      await _speech.stop();
      print('✅ _speech.stop() completed successfully');
    } catch (e) {
      print('❌ Error stopping speech recognition: $e');
    }

    // If we have speech results, populate the text field
    if (_lastWords.isNotEmpty) {
      print('📝 Populating text field with final results: "$_lastWords"');
      _messageController.text = _lastWords;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _lastWords.length),
      );
    } else {
      print('⚠️ No speech results to populate');
    }

    print('=== SPEECH LISTENING STOPPED ===');
  }

  void _onSpeechResult(dynamic result) {
    print('=== SPEECH RESULT RECEIVED ===');
    print('Result type: ${result.runtimeType}');
    print('Result: $result');

    // Log all available properties of the result object
    if (result != null) {
      print('Available result properties:');
      result.toString().split(',').forEach((prop) {
        print('  $prop');
      });
    }

    // Try multiple ways to get recognized words
    String recognizedWords = '';
    if (result != null) {
      // Try different property names that might exist
      if (result.recognizedWords != null) {
        recognizedWords = result.recognizedWords;
        print('✅ Found recognizedWords: "$recognizedWords"');
      } else if (result.recognizedText != null) {
        recognizedWords = result.recognizedText;
        print('✅ Found recognizedText: "$recognizedWords"');
      } else if (result.text != null) {
        recognizedWords = result.text;
        print('✅ Found text: "$recognizedWords"');
      } else if (result.toString().isNotEmpty) {
        recognizedWords = result.toString();
        print('✅ Using toString(): "$recognizedWords"');
      } else {
        print('❌ No recognizable text found in result');
      }
    }

    print('Final recognized words: "$recognizedWords"');
    print('Previous lastWords: "$_lastWords"');

    setState(() {
      _lastWords = recognizedWords;
      // Also update the text field in real-time for better UX
      _messageController.text = recognizedWords;
      print('✅ Updated text field with: "$recognizedWords"');
    });

    print('=== SPEECH RESULT PROCESSING COMPLETE ===');
  }

  void _onSpeechError(dynamic error) {
    print('Speech recognition error: $error');
    print('Error type: ${error.runtimeType}');
    setState(() {
      _isListening = false;
    });

    // Enhanced error handling with specific error types
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

    print('User-friendly error message: $errorMessage');

    if (mounted) {
      FloatingSnackbar.show(
        context,
        message: errorMessage,
        actionLabel: error.toString().contains('permission') ? 'Settings' : null,
        onActionPressed: error.toString().contains('permission') ? () {
          print('User should be directed to app settings');
        } : null,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _onSpeechStatus(String status) {
    print('Speech recognition status: $status');
    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _showPlatformNotSupportedMessage() {
    print('Showing platform not supported message');
    String platformMessage = 'Speech recognition is not supported on ${Platform.operatingSystem}. ';
    platformMessage += 'Please use an Android or iOS device for voice input features.';

    if (mounted) {
      FloatingSnackbar.show(
        context,
        message: platformMessage,
        actionLabel: 'Got it',
        onActionPressed: () {
          print('User acknowledged platform limitation');
        },
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    print('=== ChatScreen initState - STARTING INITIALIZATION ===');
    print('Platform: ${Platform.operatingSystem}');

    // Initialize conversation service
    _initializeConversationService();

    // Initialize speech recognition
    print('Current _speechEnabled state: $_speechEnabled');
    _initializeSpeech();

    // Add a delay to check speech status after initialization
    Future.delayed(const Duration(seconds: 2), () {
      print('=== SPEECH STATUS CHECK AFTER 2 SECONDS ===');
      print('Speech enabled: $_speechEnabled');
      print('Is listening: $_isListening');
      print('Last words: $_lastWords');
      if (!_speechEnabled) {
        print('❌ WARNING: Speech recognition is not enabled after initialization');
        print('This means either:');
        print('1. Permission request failed');
        print('2. Speech initialization failed');
        print('3. Platform doesn\'t support speech recognition');
      } else {
        print('✅ Speech recognition is enabled and ready');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _speech.stop();

    // Trigger summarization when app is closed if we have enough conversation
    _triggerSummarizationIfNeeded();

    super.dispose();
  }

  Future<void> _triggerSummarizationIfNeeded() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    print('=== CHECKING SUMMARIZATION TRIGGER ===');
    print('Total messages: $messageCount');
    print('Has summary: ${context.summary.isNotEmpty}');

    // Trigger summarization if:
    // 1. We have more than 20 messages AND no summary yet, OR
    // 2. We have more than 50 messages (update existing summary), OR
    // 3. App is being closed and we have any conversation
    bool shouldSummarize = false;
    if (messageCount > 20 && context.summary.isEmpty) {
      shouldSummarize = true;
      print('Trigger: More than 20 messages and no summary');
    } else if (messageCount > 50) {
      shouldSummarize = true;
      print('Trigger: More than 50 messages, updating summary');
    } else if (messageCount > 0) {
      shouldSummarize = true;
      print('Trigger: App closing with conversation');
    }

    if (shouldSummarize) {
      print('🚀 Starting summarization process...');
      try {
        await _performSummarization();
        print('✅ Summarization completed successfully');
      } catch (e) {
        print('❌ Summarization failed: $e');
      }
    } else {
      print('⏭️ No summarization needed');
    }
  }

  Future<void> _performSummarization() async {
    try {
      final messages = ConversationService.context.messages;
      print('📝 Summarizing ${messages.length} messages...');

      final summary = await SummarizationService.summarizeConversation(messages);
      ConversationService.updateSummary(summary);

      await ConversationService.saveContext();
      print('💾 Conversation context saved with summary');
    } catch (e) {
      print('❌ Error during summarization: $e');
      throw e;
    }
  }

  Future<void> _checkAndTriggerSummarization() async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    // Trigger summarization if we have more than 10 messages and no summary yet
    // Or if we have more than 25 messages (update existing summary)
    if ((messageCount > 10 && context.summary.isEmpty) || messageCount > 25) {
      print('📊 Triggering summarization after $messageCount messages...');
      try {
        await _performSummarization();
        print('✅ Summarization completed');
      } catch (e) {
        print('❌ Summarization failed: $e');
        // Don't throw here - we don't want to break the chat flow
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug speech recognition state
    print('=== BUILDING UI ===');
    print('Speech enabled: $_speechEnabled');
    print('Is listening: $_isListening');
    print('Last words: "$_lastWords"');
    print('Platform: ${Platform.operatingSystem}');
    print('Is loading: $_isLoading');
    print('Message controller text length: ${_messageController.text.length}');

    // Check microphone button visibility conditions
    bool shouldShowMicButton = _speechEnabled;
    bool shouldShowSendButton = true; // Always show send button

    print('Button visibility logic:');
    print('Should show microphone button: $shouldShowMicButton');
    print('Should show send button: $shouldShowSendButton');

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
              bottom: 120, // Leave space for floating input
              child: _messages.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft glowing background - always show with dynamic color
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
                              width: 180,
                              height: 180,
                            ),
                            // Text content - only show when there's actual text
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
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
                    )
                  : _messages.isNotEmpty
                      ? Center(
                          child: _messages[0], // Show only the most recent message
                        )
                      : const SizedBox(), // Empty state when no messages
            ),


            // Floating input at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
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
                      Container(
                        key: const ValueKey('microphone_button'), // For testing
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? Colors.red
                              : Theme.of(context).colorScheme.secondary,
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
                            print('=== MICROPHONE BUTTON PRESSED ===');
                            print('Current state - Listening: $_isListening, Speech enabled: $_speechEnabled');
                            print('Text field content: "${_messageController.text}"');
                            print('Last words: "$_lastWords"');

                            if (_isListening) {
                              print('🔊 Stopping speech recognition...');
                              _stopListening();
                            } else {
                              print('🎤 Starting speech recognition...');
                              _startListening();
                            }
                          },
                          icon: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                          iconSize: 20,
                        ),
                      ),
                    if (_speechEnabled) const SizedBox(width: 8),
                    // Show info icon when speech recognition is not available
                    if (!_speechEnabled && Platform.isLinux)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () {
                            print('Info button pressed - showing speech recognition limitations');
                            _showPlatformNotSupportedMessage();
                          },
                          icon: Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          tooltip: 'Speech recognition not available on ${Platform.operatingSystem}',
                        ),
                      ),
                    // Send button
                    Container(
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glowing background - always show with dynamic color
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLoading
                      ? Colors.blue.withValues(alpha: 0.15)  // Blue when thinking
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), // Original color after response
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: isLoading
                      ? Colors.blue.withValues(alpha: 0.08)  // Blue when thinking
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06), // Original color after response
                  blurRadius: 80,
                  spreadRadius: 15,
                ),
              ],
            ),
            width: 180,
            height: 180,
          ),
          // Text content - only show when there's actual text
          if (text.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  // Base text style matching the original design
                  p: GoogleFonts.playfairDisplay(
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
                  // Bold text styling
                  strong: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700, // Bold weight for **bold** text
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
                  // Italic text styling
                  em: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic, // Italic style for *italic* text
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
                  // Disable headers by making them look like regular text
                  h1: GoogleFonts.playfairDisplay(
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
                  h2: GoogleFonts.playfairDisplay(
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
                  h3: GoogleFonts.playfairDisplay(
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
                  h4: GoogleFonts.playfairDisplay(
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
                  h5: GoogleFonts.playfairDisplay(
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
                  h6: GoogleFonts.playfairDisplay(
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
                ),
                selectable: true, // Keep text selectable like before
              ),
            ),
        ],
      ),
    );
  }
}
