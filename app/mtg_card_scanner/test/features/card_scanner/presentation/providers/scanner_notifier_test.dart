// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/usecases/load_scan_history_usecase.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/usecases/recognize_card_usecase.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/usecases/save_scan_history_usecase.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/card_candidate.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/card_recognition_result.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/magic_card.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/providers/providers.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/providers/scanner_route_target.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/providers/scanner_state.dart';

import '../../../../support/test_fakes.dart';

void main() {
  const card = MagicCard(
    id: 'card-1',
    name: 'Lightning Bolt',
    normalizedName: 'lightning bolt',
    setCode: 'M11',
    collectorNumber: '146',
    lang: 'English',
    rarity: 'common',
  );

  ProviderContainer buildContainer({
    required Future<CardRecognitionResult> Function(String imagePath) recognize,
    FakeScanHistoryRepository? historyRepository,
  }) {
    final repository = historyRepository ?? FakeScanHistoryRepository();
    return ProviderContainer(
      overrides: [
        recognizeCardUseCaseProvider.overrideWith(
          (ref) =>
              RecognizeCardUseCase(FakeRecognitionPipelineService(recognize)),
        ),
        saveScanHistoryUseCaseProvider.overrideWith(
          (ref) => SaveScanHistoryUseCase(repository),
        ),
        loadScanHistoryUseCaseProvider.overrideWith(
          (ref) => LoadScanHistoryUseCase(repository),
        ),
      ],
    );
  }

  test('captureImage moves through processing to result and saves history',
      () async {
    final historyRepository = FakeScanHistoryRepository();
    final container = buildContainer(
      historyRepository: historyRepository,
      recognize: (_) async => const CardRecognitionResult(
        bestMatch: card,
        candidates: [
          CardCandidate(
            card: card,
            nameScore: 1,
            collectorScore: 0,
            setScore: 0,
            finalScore: 0.82,
          ),
        ],
        requiresManualSelection: false,
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(scannerNotifierProvider.notifier)
        .captureImage('scan.jpg');

    final state = container.read(scannerNotifierProvider);
    expect(state.status.name, 'result');
    expect(state.recognitionResult?.bestMatch?.id, card.id);
    expect(state.pendingRoute, ScannerRouteTarget.result);
    expect(historyRepository.savedEntries, hasLength(1));
  });

  test('captureImage reports an error when nothing matches', () async {
    final container = buildContainer(
      recognize: (_) async => const CardRecognitionResult(
        bestMatch: null,
        candidates: [],
        requiresManualSelection: false,
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(scannerNotifierProvider.notifier)
        .captureImage('scan.jpg');

    final ScannerState state = container.read(scannerNotifierProvider);
    expect(state.status.name, 'error');
    expect(state.error, contains('usable local match'));
    expect(state.pendingRoute, isNull);
  });

  test('selectCandidate resolves manual selection and persists history',
      () async {
    final historyRepository = FakeScanHistoryRepository();
    final container = buildContainer(
      historyRepository: historyRepository,
      recognize: (_) async => const CardRecognitionResult(
        bestMatch: null,
        candidates: [
          CardCandidate(
            card: card,
            nameScore: 0.91,
            collectorScore: 0,
            setScore: 0,
            finalScore: 0.75,
          ),
        ],
        requiresManualSelection: true,
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(scannerNotifierProvider.notifier)
        .captureImage('scan.jpg');
    await container.read(scannerNotifierProvider.notifier).selectCandidate(
          const CardCandidate(
            card: card,
            nameScore: 0.91,
            collectorScore: 0,
            setScore: 0,
            finalScore: 0.75,
          ),
        );

    final state = container.read(scannerNotifierProvider);
    expect(state.selectedManually, isTrue);
    expect(state.recognitionResult?.bestMatch?.id, card.id);
    expect(state.pendingRoute, ScannerRouteTarget.result);
    expect(historyRepository.savedEntries.single.selectedManually, isTrue);
  });

  test('restartScanFlow resets state and requests camera navigation', () async {
    final container = buildContainer(
      recognize: (_) async => const CardRecognitionResult(
        bestMatch: card,
        candidates: [
          CardCandidate(
            card: card,
            nameScore: 1,
            collectorScore: 0,
            setScore: 0,
            finalScore: 0.82,
          ),
        ],
        requiresManualSelection: false,
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(scannerNotifierProvider.notifier)
        .captureImage('scan.jpg');
    container.read(scannerNotifierProvider.notifier).restartScanFlow();

    final state = container.read(scannerNotifierProvider);
    expect(state.status.name, 'idle');
    expect(state.pendingRoute, ScannerRouteTarget.camera);
    expect(state.recognitionResult, isNull);
  });
}
