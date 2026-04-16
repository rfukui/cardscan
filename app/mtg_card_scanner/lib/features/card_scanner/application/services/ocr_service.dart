// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/ocr_extraction_result.dart';

class OcrService {
  OcrService()
      : _recognizers = {
          for (final script in _scriptOrder)
            script: TextRecognizer(script: script),
        };

  static const _scriptOrder = [
    TextRecognitionScript.latin,
    TextRecognitionScript.japanese,
    TextRecognitionScript.chinese,
    TextRecognitionScript.korean,
  ];

  final Map<TextRecognitionScript, TextRecognizer> _recognizers;

  Future<OcrExtractionResult> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    _OcrAttempt? bestAttempt;

    for (final script in _scriptOrder) {
      final recognizer = _recognizers[script]!;
      final recognizedText = await recognizer.processImage(inputImage);
      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .where((line) => line.text.trim().isNotEmpty)
          .toList();
      final attempt = _buildAttempt(script, lines);
      final previewLines = lines.take(8).map((line) => line.text.trim()).join(' | ');
      debugPrint(
        '[OCR][${attempt.scriptLabel}] '
        'lines=${lines.length} '
        'best="${attempt.result.detectedName}" '
        'candidates=${attempt.result.candidateNames.join(' || ')} '
        'confidence=${attempt.result.confidence.toStringAsFixed(2)} '
        'preview=$previewLines',
      );
      if (bestAttempt == null || attempt.score > bestAttempt.score) {
        bestAttempt = attempt;
      }
    }

    final selectedAttempt = bestAttempt;
    if (selectedAttempt == null || selectedAttempt.result.detectedName.isEmpty) {
      debugPrint('[OCR] No usable text detected for image: $imagePath');
      return const OcrExtractionResult(
        detectedName: '',
        detectedCollectorNumber: null,
        detectedSetText: null,
        confidence: 0.0,
      );
    }

    final result = selectedAttempt.result;
    debugPrint(
      '[OCR] detectedName="${result.detectedName}" '
      'candidates=${result.candidateNames.join(' || ')} '
      'collector="${result.detectedCollectorNumber ?? '-'}" '
      'confidence=${result.confidence.toStringAsFixed(2)} '
      'script=${result.detectedScript ?? '-'}',
    );

    return result;
  }

  _OcrAttempt _buildAttempt(
    TextRecognitionScript script,
    List<TextLine> lines,
  ) {
    if (lines.isEmpty) {
      return _OcrAttempt(
        script: script,
        result: OcrExtractionResult(
          detectedName: '',
          candidateNames: const [],
          detectedCollectorNumber: null,
          detectedSetText: null,
          confidence: 0.0,
          detectedScript: _labelForScript(script),
        ),
        score: 0.0,
      );
    }

    final scoredLines = <_ScoredOcrLine>[];

    for (var i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];
      final text = line.text.trim();
      final normalized = normalizeText(text);
      if (normalized.isEmpty) {
        continue;
      }
      if (RegExp(r'^\d+$').hasMatch(normalized)) {
        continue;
      }

      final compactLength = normalized.replaceAll(' ', '').length;
      final wordCount = normalized.split(' ').where((part) => part.isNotEmpty).length;
      if (wordCount > 6 || compactLength > 40) {
        continue;
      }

      var score = 0.9 - (i * 0.04);
      if (compactLength >= 2 && compactLength <= 28) {
        score += 0.25;
      }
      if (wordCount >= 1 && wordCount <= 4) {
        score += 0.2;
      }
      if (_looksLikeMostlyNameText(text)) {
        score += 0.15;
      }
      final verticalCenter = line.boundingBox.top + (line.boundingBox.height / 2);
      if (verticalCenter <= 220) {
        score += 0.08;
      } else if (verticalCenter <= 360) {
        score += 0.04;
      }
      if (_looksLikeSetOrTypeLine(normalized)) {
        score -= 0.25;
      }

      scoredLines.add(
        _ScoredOcrLine(
          text: text,
          score: score,
        ),
      );
    }

    scoredLines.sort((a, b) => b.score.compareTo(a.score));
    final candidateNames = scoredLines
        .map((line) => line.text)
        .where((text) => text.isNotEmpty)
        .toSet()
        .take(5)
        .toList();
    final bestName = candidateNames.isNotEmpty ? candidateNames.first : '';

    String? collectorNumber;
    for (final line in lines) {
      final text = line.text.trim();
      if (RegExp(r'^[0-9]+/[0-9]+').hasMatch(text) || RegExp(r'^[0-9]+$').hasMatch(text)) {
        collectorNumber = text;
        break;
      }
    }

    final bestNameScore = scoredLines.isEmpty ? -1.0 : scoredLines.first.score;
    final confidence = bestNameScore < 0 ? 0.0 : bestNameScore.clamp(0.0, 1.0).toDouble();
    final result = OcrExtractionResult(
      detectedName: bestName,
      candidateNames: candidateNames,
      detectedCollectorNumber: collectorNumber,
      detectedSetText: null,
      confidence: confidence,
      detectedScript: _labelForScript(script),
    );

    final score = confidence + (lines.length >= 3 ? 0.05 : 0.0);
    return _OcrAttempt(
      script: script,
      result: result,
      score: score,
    );
  }

  bool _looksLikeMostlyNameText(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    var supportedChars = 0;
    var unsupportedChars = 0;
    for (final rune in trimmed.runes) {
      if (isSupportedScannerRune(rune)) {
        supportedChars += 1;
      } else if (!_isIgnoredNamePunctuation(rune)) {
        unsupportedChars += 1;
      }
    }
    return supportedChars > 0 && unsupportedChars <= 2;
  }

  bool _looksLikeSetOrTypeLine(String normalized) {
    final lower = normalized.toLowerCase();
    const markers = {
      'instant',
      'sorcery',
      'creature',
      'artifact',
      'enchantment',
      'planeswalker',
      'land',
      'battle',
      'インスタント',
      'ソーサリー',
      'クリーチャー',
      'アーティファクト',
      'エンチャント',
      'プレインズウォーカー',
      '土地',
    };
    return markers.contains(lower);
  }

  bool _isIgnoredNamePunctuation(int rune) {
    const ignored = {
      0x20,
      0x2D,
      0x2F,
      0x27,
      0x2019,
      0x3000,
      0x30FB,
      0xFF0F,
      0xFF5C,
    };
    return ignored.contains(rune);
  }

  String _labelForScript(TextRecognitionScript script) {
    switch (script) {
      case TextRecognitionScript.latin:
        return 'latin';
      case TextRecognitionScript.japanese:
        return 'japanese';
      case TextRecognitionScript.chinese:
        return 'chinese';
      case TextRecognitionScript.korean:
        return 'korean';
      case TextRecognitionScript.devanagiri:
        return 'devanagiri';
    }
  }

  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
  }
}

class _OcrAttempt {
  const _OcrAttempt({
    required this.script,
    required this.result,
    required this.score,
  });

  final TextRecognitionScript script;
  final OcrExtractionResult result;
  final double score;

  String get scriptLabel {
    switch (script) {
      case TextRecognitionScript.latin:
        return 'latin';
      case TextRecognitionScript.japanese:
        return 'japanese';
      case TextRecognitionScript.chinese:
        return 'chinese';
      case TextRecognitionScript.korean:
        return 'korean';
      case TextRecognitionScript.devanagiri:
        return 'devanagiri';
    }
  }
}

class _ScoredOcrLine {
  const _ScoredOcrLine({
    required this.text,
    required this.score,
  });

  final String text;
  final double score;
}
