import 'dart:math' as math;

class SearchScorer {
  /// Computes relevance score for an item based on the prompt's scoring rubric.
  /// Exact title match = 100
  /// Prefix title match = 80
  /// Tag / Project match = 60
  /// Content body match = 40
  /// Fuzzy / Subsequence match = 20-30
  /// Recency boost = +1 to +10 based on updatedAt
  static double computeScore({
    required String query,
    required String title,
    String? content,
    String? tagOrProject,
    required DateTime updatedAt,
    DateTime? now,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return 0.0;

    final cleanTitle = title.trim().toLowerCase();
    double baseScore = 0.0;

    // 1. Title Scoring
    if (cleanTitle == cleanQuery) {
      baseScore = math.max(baseScore, 100.0);
    } else if (cleanTitle.startsWith(cleanQuery)) {
      baseScore = math.max(baseScore, 80.0);
    } else {
      final words = cleanTitle.split(RegExp(r'\s+'));
      if (words.any((w) => w.startsWith(cleanQuery))) {
        baseScore = math.max(baseScore, 70.0);
      } else if (cleanTitle.contains(cleanQuery)) {
        baseScore = math.max(baseScore, 50.0);
      } else if (isSubsequence(cleanQuery, cleanTitle)) {
        baseScore = math.max(baseScore, 25.0);
      }
    }

    // 2. Tag / Project Scoring
    if (tagOrProject != null && tagOrProject.trim().isNotEmpty) {
      final cleanTag = tagOrProject.trim().toLowerCase();
      if (cleanTag == cleanQuery || cleanTag.contains(cleanQuery)) {
        baseScore = math.max(baseScore, 60.0);
      }
    }

    // 3. Content Body Scoring
    if (content != null && content.trim().isNotEmpty) {
      final cleanContent = content.toLowerCase();
      if (cleanContent.contains(cleanQuery)) {
        baseScore = math.max(baseScore, 40.0);
      } else {
        final queryTokens = cleanQuery
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty);
        if (queryTokens.any((t) => cleanContent.contains(t))) {
          baseScore = math.max(baseScore, 20.0);
        }
      }
    }

    if (baseScore <= 0.0) return 0.0;

    // 4. Recency Boost (+1 to +10 pts based on updatedAt)
    final referenceTime = now ?? DateTime.now();
    final difference = referenceTime.difference(updatedAt);
    final daysAgo = math.max(0, difference.inDays);
    final recencyBoost = (10.0 - (daysAgo * 0.3)).clamp(1.0, 10.0);

    return baseScore + recencyBoost;
  }

  /// Checks if [query] is a subsequence of [target] in order.
  static bool isSubsequence(String query, String target) {
    if (query.isEmpty) return true;
    if (target.isEmpty) return false;

    int qIdx = 0;
    int tIdx = 0;
    while (qIdx < query.length && tIdx < target.length) {
      if (query[qIdx] == target[tIdx]) {
        qIdx++;
      }
      tIdx++;
    }
    return qIdx == query.length;
  }

  /// Extracts a context snippet of approximately [maxLength] characters surrounding [query].
  static String? extractSnippet(
    String? content,
    String query, {
    int maxLength = 120,
  }) {
    if (content == null || content.trim().isEmpty) return null;
    final cleanContent = content.trim();
    final lowerContent = cleanContent.toLowerCase();
    final lowerQuery = query.trim().toLowerCase();

    final matchIndex = lowerContent.indexOf(lowerQuery);
    if (matchIndex == -1) {
      if (cleanContent.length <= maxLength) return cleanContent;
      return '${cleanContent.substring(0, maxLength)}...';
    }

    final start = math.max(0, matchIndex - (maxLength ~/ 3));
    final end = math.min(
      cleanContent.length,
      matchIndex + lowerQuery.length + (maxLength * 2 ~/ 3),
    );

    String snippet = cleanContent
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ');
    if (start > 0) snippet = '...$snippet';
    if (end < cleanContent.length) snippet = '$snippet...';

    return snippet;
  }
}
