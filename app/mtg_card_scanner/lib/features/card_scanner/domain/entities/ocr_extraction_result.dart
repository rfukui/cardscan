// SPDX-License-Identifier: GPL-3.0-or-later

class OcrExtractionResult {
  final String detectedName;
  final String? detectedCollectorNumber;
  final String? detectedSetText;
  final double confidence;

  const OcrExtractionResult({
    required this.detectedName,
    this.detectedCollectorNumber,
    this.detectedSetText,
    required this.confidence,
  });
}
