// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/card_recognition_result.dart';
import '../../domain/repositories/card_catalog_repository.dart';
import '../../../../core/utils/string_utils.dart';
import 'card_matcher_service.dart';
import 'native_vision_service.dart';
import 'ocr_service.dart';

class RecognitionPipelineService {
  final NativeVisionService nativeVisionService;
  final OcrService ocrService;
  final CardMatcherService matcherService;
  final CardCatalogRepository catalogRepository;

  RecognitionPipelineService({
    required this.nativeVisionService,
    required this.ocrService,
    required this.matcherService,
    required this.catalogRepository,
  });

  Future<CardRecognitionResult> recognize(String imagePath) async {
    final rectifiedPath = await nativeVisionService.rectifyCard(imagePath);
    final ocrResult = await ocrService.extractText(rectifiedPath);
    final normalizedName = normalizeText(ocrResult.detectedName);
    if (normalizedName.isEmpty) {
      return const CardRecognitionResult(
        bestMatch: null,
        candidates: [],
        requiresManualSelection: false,
      );
    }

    var cards = await catalogRepository.searchByNormalizedName(normalizedName);
    if (cards.isEmpty) {
      cards = await catalogRepository.getAll();
    }
    final matched = matcherService.matchCards(ocrResult, cards).take(3).toList();

    if (matched.isEmpty) {
      return const CardRecognitionResult(
        bestMatch: null,
        candidates: [],
        requiresManualSelection: false,
      );
    }

    if (matched.length == 1) {
      return CardRecognitionResult(
        bestMatch: matched.first.card,
        candidates: matched,
        requiresManualSelection: false,
      );
    }

    final best = matched.first;
    final second = matched.length > 1 ? matched[1] : null;
    final requiresManualSelection =
        second != null &&
        best.finalScore < 0.88 &&
        (best.finalScore - second.finalScore).abs() < 0.12;

    return CardRecognitionResult(
      bestMatch: requiresManualSelection ? null : best.card,
      candidates: matched,
      requiresManualSelection: requiresManualSelection,
    );
  }
}
