import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/conversation_service.dart';

/// Settings screen for displaying conversation summaries
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversation Summary',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final conversationContext = ConversationService.context;
    final messages = conversationContext.messages;

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    if (conversationContext.summary.isEmpty) {
      return _buildNoSummaryState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildStructuredSummaryCard(conversationContext.summary),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            width: 100,
            height: 100,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 45,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Conversations Yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation with Alex to see\nyour summary appear here',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSummaryState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            width: 90,
            height: 90,
            child: Icon(
              Icons.summarize_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Building Summary...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Continue your conversation and a summary\nwill be generated automatically',
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredSummaryCard(String summary) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.psychology_alt,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation Summary',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Key insights from our discussion',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Structured summary content
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildStructuredSummary(summary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredSummary(String summary) {
    List<SummarySection> sections = _parseSummaryIntoSections(summary);

    if (sections.isEmpty) {
      return _buildPlainTextSummary(summary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.expand((section) => [
        _buildSummarySection(section),
        if (section != sections.last) const SizedBox(height: 16),
      ]).toList(),
    );
  }

  List<SummarySection> _parseSummaryIntoSections(String summary) {
    List<SummarySection> sections = [];

    // Common patterns for section headers
    List<String> headerPatterns = [
      r'^Key Points?:',
      r'^Main Topics?:',
      r'^Summary:',
      r'^Discussion:',
      r'^Insights?:',
      r'^Overview:',
      r'^Highlights?:',
      r'^Important:',
      r'^Topics?:',
      r'^Themes?:',
      r'^Conclusions?:',
      r'^Takeaways?:',
    ];

    List<String> lines = summary.split('\n').where((line) => line.trim().isNotEmpty).toList();

    SummarySection? currentSection;
    List<String> currentContent = [];

    for (String line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Check if line matches header pattern
      bool isHeader = headerPatterns.any((pattern) =>
          RegExp(pattern, caseSensitive: false).hasMatch(trimmedLine));

      if (isHeader && currentContent.isNotEmpty) {
        // Save previous section
        if (currentSection != null) {
          currentSection.content = currentContent.join('\n').trim();
          sections.add(currentSection);
        }

        // Start new section
        currentSection = SummarySection(
          title: trimmedLine,
          content: '',
          type: SummarySectionType.header,
        );
        currentContent = [];
      } else if (isHeader) {
        // First section
        currentSection = SummarySection(
          title: trimmedLine,
          content: '',
          type: SummarySectionType.header,
        );
        currentContent = [];
      } else if (currentSection != null) {
        // Add to current section content
        currentContent.add(trimmedLine);
      } else {
        // No section yet, treat as general content
        currentContent.add(trimmedLine);
      }
    }

    // Add final section
    if (currentSection != null) {
      currentSection.content = currentContent.join('\n').trim();
      sections.add(currentSection);
    } else if (currentContent.isNotEmpty) {
      // No headers found, treat as general summary
      sections.add(SummarySection(
        title: 'Summary',
        content: currentContent.join('\n').trim(),
        type: SummarySectionType.general,
      ));
    }

    return sections;
  }

  Widget _buildSummarySection(SummarySection section) {
    switch (section.type) {
      case SummarySectionType.header:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              section.content,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case SummarySectionType.general:
        return Text(
          section.content,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _buildPlainTextSummary(String summary) {
    return Text(
      summary,
      style: GoogleFonts.playfairDisplay(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Model for summary sections
class SummarySection {
  final String title;
  late String content;
  final SummarySectionType type;

  SummarySection({
    required this.title,
    required this.content,
    required this.type,
  });
}

enum SummarySectionType {
  header,
  general,
}