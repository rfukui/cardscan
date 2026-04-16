// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/card_recognition_result.dart';
import '../../domain/value_objects/scanner_status.dart';

class ScannerState {
  final ScannerStatus status;
  final String message;
  final String? capturedImagePath;
  final CardRecognitionResult? recognitionResult;
  final String? error;
  final bool selectedManually;

  const ScannerState({
    this.status = ScannerStatus.idle,
    this.message = 'Position the card inside the frame',
    this.capturedImagePath,
    this.recognitionResult,
    this.error,
    this.selectedManually = false,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    String? message,
    String? capturedImagePath,
    CardRecognitionResult? recognitionResult,
    String? error,
    bool? selectedManually,
    bool clearCapturedImagePath = false,
    bool clearRecognitionResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      message: message ?? this.message,
      capturedImagePath: clearCapturedImagePath ? null : capturedImagePath ?? this.capturedImagePath,
      recognitionResult: clearRecognitionResult ? null : recognitionResult ?? this.recognitionResult,
      error: clearError ? null : error ?? this.error,
      selectedManually: selectedManually ?? this.selectedManually,
    );
  }
}
