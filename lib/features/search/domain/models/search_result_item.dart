enum SearchEntityType { document, notebook, task, calendarEvent, journal, tag }

enum SearchFilter { all, document, notebook, task, calendar, journal }

class SearchResultItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? snippet;
  final SearchEntityType type;
  final String route;
  final double score;
  final DateTime updatedAt;
  final String? parentBreadcrumb;
  final List<String> matchedTerms;

  const SearchResultItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.snippet,
    required this.type,
    required this.route,
    required this.score,
    required this.updatedAt,
    this.parentBreadcrumb,
    this.matchedTerms = const [],
  });

  SearchResultItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? snippet,
    SearchEntityType? type,
    String? route,
    double? score,
    DateTime? updatedAt,
    String? parentBreadcrumb,
    List<String>? matchedTerms,
  }) {
    return SearchResultItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      snippet: snippet ?? this.snippet,
      type: type ?? this.type,
      route: route ?? this.route,
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
      parentBreadcrumb: parentBreadcrumb ?? this.parentBreadcrumb,
      matchedTerms: matchedTerms ?? this.matchedTerms,
    );
  }
}
