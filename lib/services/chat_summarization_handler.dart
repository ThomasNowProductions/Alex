import 'dart:async';
import '../models/chat_state.dart';
import '../services/conversation_service.dart';
import '../services/summarization_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../widgets/chat_message.dart';

/// Summarization handler for chat functionality
class ChatSummarizationHandler {
  static Timer? _debounceTimer;

  /// Check and trigger summarization if needed (improved batching logic)
  static void checkAndTriggerSummarization(
    ChatState state,
    Function(List<ChatMessage>) updateMessages,
  ) {
    // Cancel any existing timer to reset the debounce period
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Start a new timer to trigger summarization after a delay
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
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
    });
  }

  /// Perform conversation summarization
  static Future<void> performSummarization(ChatState state) async {
    try {
      final allMessages = ConversationService.context.messages;
      final previousSummary = ConversationService.context.summary;
      final messagesToSummarize = allMessages.sublist(state.lastSummarizedMessageCount);

      if (messagesToSummarize.isEmpty) {
        AppLogger.i('No new messages to summarize.');
        return;
      }

      AppLogger.d('Performing incremental summarization for ${messagesToSummarize.length} new messages');
      final newSummary = await SummarizationService.summarize(
        messagesToSummarize,
        previousSummary: previousSummary,
      );

      ConversationService.updateSummary(newSummary);
      await ConversationService.saveContext();
      state.lastSummarizationTime = DateTime.now();
      state.lastSummarizedMessageCount = allMessages.length;
      AppLogger.i('Incremental conversation summarization completed successfully');
    } catch (e) {
      AppLogger.e('Summarization failed - showing user-friendly message in chat: $e');
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