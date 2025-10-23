/// Model representing a single web search result used to enrich AI responses.
class WebSearchResult {
  final String title;
  final String url;
  final String snippet;
  final String? fullContent;
  final List<String> links;

  const WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.fullContent,
    this.links = const [],
  });

  factory WebSearchResult.fromSearchJson(Map<String, dynamic> json) {
    return WebSearchResult(
      title: (json['title'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      snippet: (json['content'] ?? '') as String,
    );
  }

  WebSearchResult copyWith({
    String? title,
    String? url,
    String? snippet,
    String? fullContent,
    List<String>? links,
  }) {
    return WebSearchResult(
      title: title ?? this.title,
      url: url ?? this.url,
      snippet: snippet ?? this.snippet,
      fullContent: fullContent ?? this.fullContent,
      links: links ?? this.links,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'snippet': snippet,
        'fullContent': fullContent,
        'links': links,
      };

  /// Prefer the expanded content returned by the web_fetch endpoint when available.
  String get displayContent =>
      (fullContent != null && fullContent!.trim().isNotEmpty) ? fullContent! : snippet;
}
