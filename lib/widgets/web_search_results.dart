import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/web_search_result.dart';

/// Widget for rendering the live web search results below the AI response.
class WebSearchResults extends StatelessWidget {
  final List<WebSearchResult> results;

  const WebSearchResults({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest web insights',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Powered by Ollama web search',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < results.length; i++) ...[
            _WebSearchResultTile(result: results[i]),
            if (i != results.length - 1) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _WebSearchResultTile extends StatelessWidget {
  final WebSearchResult result;

  const _WebSearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = result.title.isNotEmpty ? result.title : 'Untitled result';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (result.url.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.url,
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            result.displayContent,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          if (result.links.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Related links',
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            ...result.links.take(3).map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  link,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
