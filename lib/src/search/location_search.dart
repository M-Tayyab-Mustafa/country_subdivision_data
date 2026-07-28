import '../utilities/text_normalizer.dart';

/// Ranks values by exact, prefix, then substring name matches.
List<T> rankedLocationSearch<T>({
  required Iterable<T> values,
  required String query,
  required String Function(T value) name,
  required int limit,
  Iterable<String> Function(T value)? aliases,
}) {
  if (limit <= 0) {
    throw ArgumentError.value(limit, 'limit', 'must be positive');
  }
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return <T>[];
  }

  final scored = <({T value, int score, String name})>[];
  final seen = <T>{};
  for (final value in values) {
    if (!seen.add(value)) {
      continue;
    }
    final normalizedName = normalizeSearchText(name(value));
    var score = _score(normalizedName, normalizedQuery);
    if (aliases != null) {
      for (final alias in aliases(value)) {
        final aliasScore = _score(normalizeSearchText(alias), normalizedQuery);
        if (aliasScore < score) {
          score = aliasScore;
        }
      }
    }
    if (score < 3) {
      scored.add((value: value, score: score, name: normalizedName));
    }
  }
  scored.sort((left, right) {
    final score = left.score.compareTo(right.score);
    if (score != 0) {
      return score;
    }
    final valueName = left.name.compareTo(right.name);
    if (valueName != 0) {
      return valueName;
    }
    return name(left.value).compareTo(name(right.value));
  });
  return scored.take(limit).map((item) => item.value).toList(growable: false);
}

int _score(String candidate, String query) {
  if (candidate == query) {
    return 0;
  }
  if (candidate.startsWith(query)) {
    return 1;
  }
  if (candidate.contains(query)) {
    return 2;
  }
  return 3;
}
