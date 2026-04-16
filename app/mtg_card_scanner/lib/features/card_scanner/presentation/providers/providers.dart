// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/card_matcher_service.dart';
import '../../application/services/ocr_service.dart';
import '../../application/services/native_vision_service.dart';
import '../../application/services/recognition_pipeline_service.dart';
import '../../application/usecases/capture_card_usecase.dart';
import '../../application/usecases/load_scan_history_usecase.dart';
import '../../application/usecases/recognize_card_usecase.dart';
import '../../application/usecases/save_scan_history_usecase.dart';
import '../../application/usecases/search_local_card_database_usecase.dart';
import '../../domain/entities/card_recognition_result.dart';
import '../../domain/entities/magic_card.dart';
import '../../domain/entities/scan_history_entry.dart';
import '../../domain/repositories/card_catalog_repository.dart';
import '../../domain/repositories/scan_history_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/local_card_database.dart';
import '../../data/repositories/card_catalog_repository_impl.dart';
import '../../data/repositories/scan_history_repository_impl.dart';
import 'scanner_notifier.dart';
import 'scanner_state.dart';

final localCardDatabaseProvider = Provider<LocalCardDatabase>((ref) {
  return LocalCardDatabase();
});

final cardCatalogRepositoryProvider = Provider<CardCatalogRepository>((ref) {
  return CardCatalogRepositoryImpl(ref.read(localCardDatabaseProvider));
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryRepositoryImpl(ref.read(localCardDatabaseProvider));
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final cardMatcherServiceProvider = Provider<CardMatcherService>((ref) {
  return CardMatcherService();
});

final nativeVisionServiceProvider = Provider<NativeVisionService>((ref) {
  return NativeVisionService();
});

final recognitionPipelineServiceProvider =
    Provider<RecognitionPipelineService>((ref) {
  return RecognitionPipelineService(
    nativeVisionService: ref.read(nativeVisionServiceProvider),
    ocrService: ref.read(ocrServiceProvider),
    matcherService: ref.read(cardMatcherServiceProvider),
    catalogRepository: ref.read(cardCatalogRepositoryProvider),
  );
});

final captureCardUseCaseProvider = Provider<CaptureCardUseCase>((ref) {
  return CaptureCardUseCase();
});

final searchLocalCardDatabaseUseCaseProvider =
    Provider<SearchLocalCardDatabaseUseCase>((ref) {
  return SearchLocalCardDatabaseUseCase(
      ref.read(cardCatalogRepositoryProvider));
});

final recognizeCardUseCaseProvider = Provider<RecognizeCardUseCase>((ref) {
  return RecognizeCardUseCase(ref.read(recognitionPipelineServiceProvider));
});

final saveScanHistoryUseCaseProvider = Provider<SaveScanHistoryUseCase>((ref) {
  return SaveScanHistoryUseCase(ref.read(scanHistoryRepositoryProvider));
});

final loadScanHistoryUseCaseProvider = Provider<LoadScanHistoryUseCase>((ref) {
  return LoadScanHistoryUseCase(ref.read(scanHistoryRepositoryProvider));
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(cardCatalogRepositoryProvider).seedIfNeeded();
  } on AppException {
    rethrow;
  } catch (error, stackTrace) {
    debugPrint('[Bootstrap] Unexpected initialization failure: $error');
    debugPrintStack(stackTrace: stackTrace);
    throw AppException(
      'Unable to initialize the local catalog database. '
      'Confirm that the generated SQLite file was synced into app/mtg_card_scanner/assets/database.',
    );
  }
});

final rearCameraProvider = FutureProvider<CameraDescription?>((ref) async {
  final cameras = await availableCameras();
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back) {
      return camera;
    }
  }
  return cameras.isNotEmpty ? cameras.first : null;
});

final scannerNotifierProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(ScannerNotifier.new);

final scannerStateProvider = Provider<ScannerState>((ref) {
  return ref.watch(scannerNotifierProvider);
});

final recognitionResultProvider = Provider<CardRecognitionResult?>((ref) {
  return ref.watch(scannerNotifierProvider).recognitionResult;
});

final historyEntriesProvider =
    FutureProvider<List<ScanHistoryEntry>>((ref) async {
  await ref.watch(appBootstrapProvider.future);
  return ref.read(loadScanHistoryUseCaseProvider).execute();
});

final cardByIdProvider =
    FutureProvider.family<MagicCard?, String>((ref, cardId) async {
  await ref.watch(appBootstrapProvider.future);
  return ref.read(cardCatalogRepositoryProvider).getById(cardId);
});

final catalogCardsProvider = FutureProvider<List<MagicCard>>((ref) async {
  await ref.watch(appBootstrapProvider.future);
  return ref.read(cardCatalogRepositoryProvider).getAll();
});
