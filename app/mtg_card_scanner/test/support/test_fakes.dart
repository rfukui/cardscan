// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:mtg_card_scanner/features/card_scanner/application/services/card_matcher_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/native_vision_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/ocr_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/recognition_pipeline_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/card_recognition_result.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/magic_card.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/scan_history_entry.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/repositories/card_catalog_repository.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/repositories/scan_history_repository.dart';

class FakeCardCatalogRepository implements CardCatalogRepository {
  FakeCardCatalogRepository({
    this.seedError,
    this.searchResults = const {},
    this.allCards = const [],
    this.cardsById = const {},
  });

  final Object? seedError;
  final Map<String, List<MagicCard>> searchResults;
  final List<MagicCard> allCards;
  final Map<String, MagicCard> cardsById;

  @override
  Future<void> seedIfNeeded() async {
    if (seedError != null) {
      throw seedError!;
    }
  }

  @override
  Future<List<MagicCard>> getAll() async => allCards;

  @override
  Future<MagicCard?> getById(String id) async => cardsById[id];

  @override
  Future<List<MagicCard>> searchByNormalizedName(String query) async =>
      searchResults[query] ?? const [];
}

class FakeScanHistoryRepository implements ScanHistoryRepository {
  final List<ScanHistoryEntry> savedEntries = [];

  @override
  Future<List<ScanHistoryEntry>> listRecent() async =>
      savedEntries.reversed.toList();

  @override
  Future<void> save(ScanHistoryEntry entry) async {
    savedEntries.add(entry);
  }
}

class FakeRecognitionPipelineService extends RecognitionPipelineService {
  FakeRecognitionPipelineService(this.handler)
      : super(
          nativeVisionService: NativeVisionService(),
          ocrService: OcrService(),
          matcherService: CardMatcherService(),
          catalogRepository: FakeCardCatalogRepository(),
        );

  final Future<CardRecognitionResult> Function(String imagePath) handler;

  @override
  Future<CardRecognitionResult> recognize(String imagePath) =>
      handler(imagePath);
}
