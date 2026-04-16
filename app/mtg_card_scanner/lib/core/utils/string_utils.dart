// SPDX-License-Identifier: GPL-3.0-or-later

String normalizeText(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäåā]'), 'a')
      .replaceAll(RegExp(r'[èéêëēė]'), 'e')
      .replaceAll(RegExp(r'[ìíîïī]'), 'i')
      .replaceAll(RegExp(r'[òóôõöøō]'), 'o')
      .replaceAll(RegExp(r'[ùúûüū]'), 'u')
      .replaceAll(RegExp(r'[ýÿ]'), 'y')
      .replaceAll(RegExp(r'[çćč]'), 'c')
      .replaceAll(RegExp(r'[ñń]'), 'n')
      .replaceAll(RegExp(r'[šş]'), 's')
      .replaceAll(RegExp(r'[žż]'), 'z')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int levenshtein(String a, String b) {
  final n = a.length;
  final m = b.length;
  if (n == 0) return m;
  if (m == 0) return n;
  final matrix = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    matrix[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((value, element) => value < element ? value : element);
    }
  }
  return matrix[n][m];
}

double normalizedSimilarity(String input, String target) {
  if (input.isEmpty && target.isEmpty) return 1.0;
  final distance = levenshtein(input, target);
  final maxLen = input.length > target.length ? input.length : target.length;
  if (maxLen == 0) return 0.0;
  return 1.0 - (distance / maxLen);
}
