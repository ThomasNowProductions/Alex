import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/chat_state.dart';

/// UI components for the chat screen
class ChatUIComponents {
  /// Build empty state widget
  static Widget buildEmptyState(BuildContext context, String currentWelcomeMessage) {
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
                currentWelcomeMessage,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
  static Widget buildSendButton(BuildContext context, bool isLoading, VoidCallback onPressed) {
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
        onPressed: isLoading ? null : onPressed,
        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
        iconSize: 20,
      ),
    );
  }

  /// Build input field with speech recognition
  static Widget buildInputField(
    BuildContext context,
    ChatState state,
    String currentPlaceholderText,
    Function(String) onSubmitted,
    VoidCallback onSpeechToggle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: state.messageController,
        focusNode: state.focusNode,
        decoration: InputDecoration(
          hintText: currentPlaceholderText,
          hintStyle: GoogleFonts.playfairDisplay(
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: state.speechEnabled ? Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: state.isLoading ? null : onSpeechToggle,
              icon: Icon(
                state.isListening ? Icons.mic_off : Icons.mic,
                color: state.isListening ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ) : null,
        ),
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
        ),
        onSubmitted: onSubmitted,
        autofocus: true,
      ),
    );
  }

  /// Build the main chat interface layout
  static Widget buildChatLayout({
    required BuildContext context,
    required Widget child,
    required Widget bottomInput,
    required Widget? floatingActionButton,
  }) {
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: child,
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: AppConstants.inputPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: bottomInput,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton != null ? Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(top: 16),
        child: floatingActionButton,
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}