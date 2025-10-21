import 'dart:async';
import '../models/chat_state.dart';
import '../services/conversation_service.dart';
import '../services/summarization_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../widgets/chat_message.dart';

/// Summarization handler for chat functionality
class ChatSummarizationHandler {
  /// Check and trigger summarization if needed (improved batching logic)
  static Future<void> checkAndTriggerSummarization(
    ChatState state,
    Function(List<ChatMessage>) updateMessages,
  ) async {
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
    if (state.lastSummarizationTime != null) {
      final timeSinceLastSummary = DateTime.now().difference(state.lastSummarizationTime!);
      shouldSummarizeByTime = timeSinceLastSummary.inMinutes >= AppConstants.summarizationTimeIntervalMinutes;
    } else if (context.summary.isNotEmpty) {
      // If we have a summary but no recorded time, assume it was recent
      shouldSummarizeByTime = false;
    }

    // Only summarize if we have enough messages and meet either criteria
    if (messageCount > 10 && (shouldSummarizeByCount || shouldSummarizeByTime)) {
      AppLogger.i('Triggering batched summarization - messages: $messageCount, time-based: $shouldSummarizeByTime');
      try {
        await performSummarization(state);
        state.lastSummarizationTime = DateTime.now();
      } catch (e) {
        AppLogger.e('Summarization failed during check', e);
        // Don't break chat flow on summarization error
      }
    }
  }

  /// Perform conversation summarization
  static Future<void> performSummarization(ChatState state) async {
    try {
      final messages = ConversationService.context.messages;
      AppLogger.d('Performing batched summarization for ${messages.length} messages');
      final summary = await SummarizationService.summarizeConversation(messages);
      ConversationService.updateSummary(summary);
      await ConversationService.saveContext();
      state.lastSummarizationTime = DateTime.now();
      AppLogger.i('Batched conversation summarization completed successfully');
      // Note: _lastSummarizationTime is tracked in memory for this session
      // In a production app, you might want to persist this to shared preferences
    } catch (e) {
      // Log the UI error message for debugging
      AppLogger.e('Summarization failed - showing user-friendly message in chat: $e');

      // Show user-friendly error message as AI response in chat
      String errorMessage = "I'm so sorry, but your hourly limit is reached.";

      rethrow;
    }
  }

  /// Trigger summarization if needed when app is closing
  static Future<void> triggerSummarizationIfNeeded(ChatState state) async {
    final context = ConversationService.context;
    final messageCount = context.messages.length;

    // Always summarize any conversation when app closes (user's preference)
    if (messageCount > 0) {
      AppLogger.i('Triggering summarization on app close - $messageCount messages');
      try {
        await performSummarization(state);
      } catch (e) {
        AppLogger.e('Summarization failed on app close: $e');
        // Ignore summarization errors on app close - don't break the close process
      }
    } else {
      AppLogger.d('No messages to summarize on app close');
    }
  }

  /// Start periodic timer for time-based summarization
  static void startSummarizationTimer(ChatState state, Function(void Function()) setState) {
    state.summarizationTimer = Timer.periodic(
      const Duration(minutes: AppConstants.summarizationTimeIntervalMinutes),
      (timer) {
        if (timer.tick > 0) { // Skip the first immediate execution
          checkAndTriggerSummarization(state, (messages) {
            setState(() {
              // Update UI if needed
            });
          });
        }
      },
    );
  }
}