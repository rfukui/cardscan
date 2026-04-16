// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/ocr_extraction_result.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrExtractionResult> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);
    final lines = recognizedText.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const OcrExtractionResult(
        detectedName: '',
        detectedCollectorNumber: null,
        detectedSetText: null,
        confidence: 0.0,
      );
    }

    String bestName = '';
    double bestScore = -1;

    for (var i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i];
      final normalized = normalizeText(line);
      if (normalized.isEmpty) {
        continue;
      }
      if (RegExp(r'^\d+$').hasMatch(normalized)) {
        continue;
      }
      final wordCount = normalized.split(' ').where((part) => part.isNotEmpty).length;
      if (wordCount > 5) {
        continue;
      }
      var score = 1.0 - (i * 0.08);
      if (wordCount >= 1 && wordCount <= 3) {
        score += 0.25;
      }
      if (normalized.length >= 4 && normalized.length <= 26) {
        score += 0.2;
      }
      if (RegExp(r'^[a-z0-9 ]+$').hasMatch(normalized)) {
        score += 0.1;
      }
      if (score > bestScore) {
        bestScore = score;
        bestName = line;
      }
    }

    String? collectorNumber;
    for (final line in lines) {
      if (RegExp(r'^[0-9]+(\/)[0-9]+').hasMatch(line) || RegExp(r'^[0-9]+$').hasMatch(line)) {
        collectorNumber = line;
        break;
      }
    }

    return OcrExtractionResult(
      detectedName: bestName,
      detectedCollectorNumber: collectorNumber,
      detectedSetText: null,
      confidence: bestScore < 0 ? 0.0 : bestScore.clamp(0.0, 1.0).toDouble(),
    );
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
