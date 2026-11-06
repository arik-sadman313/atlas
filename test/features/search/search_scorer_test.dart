import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/features/search/data/services/search_scorer.dart';

void main() {
  group('SearchScorer Scoring Rubric', () {
    final now = DateTime(2026, 11, 7, 12, 0, 0);

    test('exact title match scores 100 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'Architecture Plan',
        title: 'Architecture Plan',
        updatedAt: now,
        now: now,
      );
      // Base: 100, Recency (0 days): 10 => 110
      expect(score, closeTo(110.0, 0.01));
    });

    test('prefix title match scores 80 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'Architecture',
        title: 'Architecture Decision Records',
        updatedAt: now,
        now: now,
      );
      // Base: 80, Recency: 10 => 90
      expect(score, closeTo(90.0, 0.01));
    });

    test('word-prefix title match scores 70 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'Decision',
        title: 'Architecture Decision Records',
        updatedAt: now,
        now: now,
      );
      // Base: 70, Recency: 10 => 80
      expect(score, closeTo(80.0, 0.01));
    });

    test('tag or project match scores 60 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'Sprint-42',
        title: 'Refactor Auth Pipeline',
        tagOrProject: 'Sprint-42',
        updatedAt: now,
        now: now,
      );
      // Base: 60, Recency: 10 => 70
      expect(score, closeTo(70.0, 0.01));
    });

    test('content body match scores 40 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'Fruchterman-Reingold',
        title: 'General Graph Notes',
        content: 'We use the Fruchterman-Reingold algorithm for 2D force simulation.',
        updatedAt: now,
        now: now,
      );
      // Base: 40, Recency: 10 => 50
      expect(score, closeTo(50.0, 0.01));
    });

    test('fuzzy subsequence match scores 25 + recency boost', () {
      final score = SearchScorer.computeScore(
        query: 'actplan',
        title: 'Architecture Plan',
        updatedAt: now,
        now: now,
      );
      // Base: 25, Recency: 10 => 35
      expect(score, closeTo(35.0, 0.01));
    });

    test('recency boost decays gracefully over time', () {
      final updated30DaysAgo = now.subtract(const Duration(days: 30));
      final score = SearchScorer.computeScore(
        query: 'Architecture Plan',
        title: 'Architecture Plan',
        updatedAt: updated30DaysAgo,
        now: now,
      );
      // Base: 100, Recency: 10 - 30 * 0.3 = 1.0 => 101
      expect(score, closeTo(101.0, 0.01));
    });

    test('returns 0 for empty query or unrelated item', () {
      expect(
        SearchScorer.computeScore(
          query: '',
          title: 'Hello World',
          updatedAt: now,
        ),
        0.0,
      );
      expect(
        SearchScorer.computeScore(
          query: 'Quantum',
          title: 'Gardening Notes',
          content: 'Tomatoes need daily sunlight and water.',
          updatedAt: now,
        ),
        0.0,
      );
    });
  });

  group('SearchScorer.isSubsequence', () {
    test('correctly identifies subsequences', () {
      expect(SearchScorer.isSubsequence('arch', 'architecture'), isTrue);
      expect(SearchScorer.isSubsequence('artr', 'architecture'), isTrue);
      expect(SearchScorer.isSubsequence('z', 'architecture'), isFalse);
      expect(SearchScorer.isSubsequence('reac', 'architecture'), isFalse);
    });
  });

  group('SearchScorer.extractSnippet', () {
    test('extracts snippet window surrounding query', () {
      const fullText =
          'The quick brown fox jumps over the lazy dog. In computer science, force-directed graph drawing algorithms are a class of algorithms for drawing graphs in an aesthetically pleasing way.';
      final snippet = SearchScorer.extractSnippet(
        fullText,
        'force-directed',
        maxLength: 60,
      );
      expect(snippet, isNotNull);
      expect(snippet!.toLowerCase(), contains('force-directed'));
      expect(
        snippet.length,
        lessThanOrEqualTo(90),
      ); // includes prefix/suffix ellipsis
    });
  });
}
