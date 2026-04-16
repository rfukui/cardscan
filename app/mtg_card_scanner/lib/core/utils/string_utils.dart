// SPDX-License-Identifier: GPL-3.0-or-later

String normalizeText(String input) {
  final lowerCased = input.toLowerCase();
  final buffer = StringBuffer();
  var lastWasSpace = true;

  for (final rune in lowerCased.runes) {
    final mapped = _latinFolds[String.fromCharCode(rune)];
    final normalizedChunk = mapped ?? String.fromCharCode(rune);

    for (final normalizedRune in normalizedChunk.runes) {
      if (isSupportedScannerRune(normalizedRune)) {
        buffer.writeCharCode(normalizedRune);
        lastWasSpace = false;
      } else if (!lastWasSpace) {
        buffer.write(' ');
        lastWasSpace = true;
      }
    }
  }

  return buffer.toString().trim();
}

const Map<String, String> _latinFolds = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'æ': 'ae',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ĉ': 'c',
  'ċ': 'c',
  'ď': 'd',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ĕ': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'ġ': 'g',
  'ģ': 'g',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ĩ': 'i',
  'ī': 'i',
  'ĭ': 'i',
  'į': 'i',
  'ı': 'i',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'ņ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'ŏ': 'o',
  'ő': 'o',
  'œ': 'oe',
  'ŕ': 'r',
  'ř': 'r',
  'ş': 's',
  'ś': 's',
  'š': 's',
  'ș': 's',
  'ß': 'ss',
  'ť': 't',
  'ţ': 't',
  'ț': 't',
  'þ': 'th',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ũ': 'u',
  'ū': 'u',
  'ŭ': 'u',
  'ů': 'u',
  'ű': 'u',
  'ų': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ž': 'z',
  'ź': 'z',
  'ż': 'z',
};

bool isSupportedScannerRune(int rune) {
  return _isAsciiAlphaNumeric(rune) ||
      _isJapaneseRune(rune) ||
      _isCjkRune(rune) ||
      _isHangulRune(rune) ||
      _isCyrillicRune(rune);
}

bool _isAsciiAlphaNumeric(int rune) =>
    (rune >= 0x30 && rune <= 0x39) || (rune >= 0x61 && rune <= 0x7A);

bool _isJapaneseRune(int rune) =>
    (rune >= 0x3040 && rune <= 0x309F) ||
    (rune >= 0x30A0 && rune <= 0x30FF) ||
    (rune >= 0x31F0 && rune <= 0x31FF) ||
    (rune >= 0xFF66 && rune <= 0xFF9F);

bool _isCjkRune(int rune) =>
    (rune >= 0x3400 && rune <= 0x4DBF) ||
    (rune >= 0x4E00 && rune <= 0x9FFF);

bool _isHangulRune(int rune) =>
    (rune >= 0x1100 && rune <= 0x11FF) ||
    (rune >= 0x3130 && rune <= 0x318F) ||
    (rune >= 0xAC00 && rune <= 0xD7AF);

bool _isCyrillicRune(int rune) =>
    (rune >= 0x0400 && rune <= 0x04FF) ||
    (rune >= 0x0500 && rune <= 0x052F);

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
