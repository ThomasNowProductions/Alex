import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for displaying chat messages with markdown support
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
              child: Center(
                child: MarkdownWidget(
                  data: text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}