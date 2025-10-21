import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_state.dart';
import '../services/conversation_service.dart';
import '../services/ollama_service.dart';
import '../services/safety_service.dart';
import '../utils/logger.dart';
import '../widgets/chat_message.dart';

/// Business logic service for chat functionality
class ChatBusinessLogic {
  /// Send a message
  static Future<void> sendMessage(
    BuildContext context,
    ChatState state,
    String message,
    Function(bool) setLoading,
    Function(List<ChatMessage>) updateMessages,
  ) async {
    if (message.trim().isEmpty) return;

    AppLogger.userAction('Send message');

    // Check for sensitive content before processing
    if (SafetyService.containsSensitiveContent(message)) {
      AppLogger.w('Sensitive content detected in user message');
      await handleSensitiveContent(context, state, setLoading, updateMessages);
      return;
    }

    // Save user message to conversation history
    ConversationService.addMessage(message, true);

    // Clear input immediately
    state.messageController.clear();
    state.focusNode.requestFocus();

    setLoading(true);
    updateMessages([
      ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      )
    ]);

    try {
      AppLogger.d('Getting AI response for user message');
      // Get AI response
      final aiResponse = await getAIResponse(message);

      // Save AI response to conversation history
      ConversationService.addMessage(aiResponse, false);

      updateMessages([
        ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        )
      ]);

      AppLogger.i('AI response sent to user, length: ${aiResponse.length}');
    } catch (e) {
      AppLogger.e('Failed to get AI response', e);
      updateMessages([
        ChatMessage(
          text: "Sorry, I couldn't process your message right now.",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        )
      ]);
    } finally {
      setLoading(false);
      await ConversationService.saveContext();
    }
  }

  /// Get AI response from Ollama service
  static Future<String> getAIResponse(String userMessage) async {
    return await OllamaService.getCompletion(userMessage);
  }

  /// Handle sensitive content by showing help resources
  static Future<void> handleSensitiveContent(
    BuildContext context,
    ChatState state,
    Function(bool) setLoading,
    Function(List<ChatMessage>) updateMessages,
  ) async {
    AppLogger.i('Handling sensitive content with help resources');

    // Clear input
    state.messageController.clear();
    state.focusNode.requestFocus();

    // Check if dialog already shown this session
    if (state.safetyDialogShownThisSession) {
      AppLogger.i('Safety dialog already shown this session, showing brief reminder');

      updateMessages([
        ChatMessage(
          text: "I've noticed you're struggling. Please consider reaching out to a crisis hotline - they have trained professionals who can help. Resources like the 988 Lifeline are available 24/7.",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        )
      ]);
      setLoading(false);
      return;
    }

    // Get help resources
    final helpResources = SafetyService.getHelpResources();
    final safeResponse = SafetyService.generateSafeResponse();

    updateMessages([
      ChatMessage(
        text: safeResponse,
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: false,
      )
    ]);

    setLoading(false);

    // Show help resources dialog after a brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (context.mounted) {
      showHelpResourcesDialog(context, helpResources, state);
    }
  }

  /// Show help resources dialog
  static void showHelpResourcesDialog(
    BuildContext context,
    List<String> helpResources,
    ChatState state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Need Immediate Help?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here are resources for professional support',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crisis resources
                      ...helpResources.take(4).map((resource) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          resource,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            height: 1.4,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )),

                      const SizedBox(height: 16),

                      // Emergency message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'If you are in immediate danger, call emergency services (911) right now.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            // Mark dialog as shown for this session
                            state.safetyDialogShownThisSession = true;
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Got it',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}