import 'web_search_result.dart';

/// Container representing an AI completion along with any metadata needed by the UI.
class AIResponse {
  final String content;
  final List<WebSearchResult> webResults;

  const AIResponse({
    required this.content,
    this.webResults = const [],
  });
}
