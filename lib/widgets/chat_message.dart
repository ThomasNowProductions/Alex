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
      margin: const EdgeInsets.only(bottom: 32),
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
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
            width: 220,
            height: 220,
          ),
          // Text content - only show when there's actual text
          if (isLoading)
            const SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else if (text.isNotEmpty)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 220, // Match the background circle height
              child: Center(
                child: MarkdownWidget(
                  data: text,
                  config: MarkdownConfig(
                    configs: [
                      PConfig(
                        textStyle: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                      H1Config(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      H2Config(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      H3Config(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      CodeConfig(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      PreConfig(
                        textStyle: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}