import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
            ),
        ],
      ),
    );
  }
}