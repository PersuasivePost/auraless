int _levenshtein(String a, String b) {
  final la = a.length;
  final lb = b.length;
  if (la == 0) return lb;
  if (lb == 0) return la;

  List<int> prev = List<int>.generate(lb + 1, (i) => i);
  List<int> cur = List<int>.filled(lb + 1, 0);

  for (var i = 0; i < la; i++) {
    cur[0] = i + 1;
    for (var j = 0; j < lb; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      cur[j + 1] = [
        prev[j + 1] + 1, // deletion
        cur[j] + 1, // insertion
        prev[j] + cost, // substitution
      ].reduce((v, e) => v < e ? v : e);
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[lb];
}

String? findBestMatch(
  String query,
  List<String> candidates, {
  int threshold = 3,
}) {
  if (query.isEmpty || candidates.isEmpty) return null;
  final q = query.toLowerCase().trim();
  String? best;
  int bestScore = 1 << 30;
  for (final c in candidates) {
    final cand = c.toLowerCase();
    if (cand == q) return c; // exact
    final score = _levenshtein(q, cand);
    if (score < bestScore) {
      bestScore = score;
      best = c;
    }
  }
  if (best == null) return null;
  // dynamic threshold: allow slightly larger for longer strings
  final dynamicThreshold = (q.length <= 4)
      ? threshold
      : (threshold + (q.length ~/ 6));
  return (bestScore <= dynamicThreshold) ? best : null;
}
