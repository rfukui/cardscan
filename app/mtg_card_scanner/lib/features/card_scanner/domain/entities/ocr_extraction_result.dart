// SPDX-License-Identifier: GPL-3.0-or-later

class OcrExtractionResult {
  final String detectedName;
  final List<String> candidateNames;
  final String? detectedCollectorNumber;
  final String? detectedSetText;
  final double confidence;
  final String? detectedScript;

  const OcrExtractionResult({
    required this.detectedName,
    this.candidateNames = const [],
    this.detectedCollectorNumber,
    this.detectedSetText,
    required this.confidence,
    this.detectedScript,
  });
}
