// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/card_candidate.dart';
import '../../domain/entities/magic_card.dart';
import '../../domain/entities/card_recognition_result.dart';
import '../../domain/entities/scan_history_entry.dart';
import '../../domain/value_objects/scanner_status.dart';
import '../../application/usecases/load_scan_history_usecase.dart';
import '../../application/usecases/recognize_card_usecase.dart';
import '../../application/usecases/save_scan_history_usecase.dart';
import 'providers.dart';
import '../providers/scanner_state.dart';

class ScannerNotifier extends Notifier<ScannerState> {
  RecognizeCardUseCase get _recognizeCardUseCase =>
      ref.read(recognizeCardUseCaseProvider);
  SaveScanHistoryUseCase get _saveScanHistoryUseCase =>
      ref.read(saveScanHistoryUseCaseProvider);
  LoadScanHistoryUseCase get _loadScanHistoryUseCase =>
      ref.read(loadScanHistoryUseCaseProvider);

  @override
  ScannerState build() {
    // Keep the history use case wired into the notifier scope for future expansion.
    _loadScanHistoryUseCase;
    return const ScannerState();
  }

  void setPreviewStatus(String message, {ScannerStatus status = ScannerStatus.analyzing}) {
    if (state.status == ScannerStatus.processing || state.status == ScannerStatus.capturing) {
      return;
    }
    state = state.copyWith(
      status: status,
      message: message,
      clearError: true,
    );
  }

  void reset() {
    state = const ScannerState();
  }

  Future<void> captureImage(String imagePath) async {
    state = state.copyWith(
      status: ScannerStatus.capturing,
      message: 'Capturing',
      capturedImagePath: imagePath,
      clearError: true,
      clearRecognitionResult: true,
      selectedManually: false,
    );

    state = state.copyWith(
      status: ScannerStatus.processing,
      message: 'Processing',
    );

    try {
      final result = await _recognizeCardUseCase.execute(imagePath);
      if (result.bestMatch == null && result.candidates.isEmpty) {
        state = state.copyWith(
          status: ScannerStatus.error,
          message: 'No matching card found',
          error: 'OCR did not produce a usable local match.',
        );
        return;
      }

      state = state.copyWith(
        status: ScannerStatus.result,
        message: result.requiresManualSelection ? 'Select the correct card' : 'Result ready',
        capturedImagePath: imagePath,
        recognitionResult: result,
      );

      if (!result.requiresManualSelection) {
        final selectedCard = result.bestMatch ?? result.candidates.first.card;
        await _saveHistory(selectedCard, imagePath, selectedManually: false);
      }
    } catch (e) {
      state = state.copyWith(
        status: ScannerStatus.error,
        message: 'Something went wrong',
        error: e.toString(),
      );
    }
  }

  Future<void> selectCandidate(CardCandidate candidate) async {
    final currentResult = state.recognitionResult;
    final imagePath = state.capturedImagePath;
    if (currentResult == null || imagePath == null) {
      return;
    }

    final resolved = CardRecognitionResult(
      bestMatch: candidate.card,
      candidates: currentResult.candidates,
      requiresManualSelection: false,
    );

    state = state.copyWith(
      status: ScannerStatus.result,
      message: 'Result ready',
      recognitionResult: resolved,
      selectedManually: true,
    );

    await _saveHistory(candidate.card, imagePath, selectedManually: true);
  }

  Future<void> _saveHistory(
    MagicCard card,
    String imagePath, {
    required bool selectedManually,
  }) async {
    await _saveScanHistoryUseCase.execute(
      ScanHistoryEntry(
        id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
        cardId: card.id,
        cardName: card.name,
        scannedAt: DateTime.now(),
        imagePath: imagePath,
        selectedManually: selectedManually,
      ),
    );
  }
}
