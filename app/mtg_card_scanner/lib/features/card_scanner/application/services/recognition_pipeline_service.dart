// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import '../../domain/entities/card_candidate.dart';
import '../../domain/entities/card_recognition_result.dart';
import '../../domain/entities/magic_card.dart';
import '../../domain/entities/ocr_extraction_result.dart';
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
    final normalizedCandidateNames = [
      for (final candidate in ocrResult.candidateNames) normalizeText(candidate),
    ].where((candidate) => candidate.isNotEmpty).toSet().toList();
    final normalizedName = normalizedCandidateNames.isNotEmpty
        ? normalizedCandidateNames.first
        : normalizeText(ocrResult.detectedName);
    debugPrint(
      '[Pipeline] image="$imagePath" rectified="$rectifiedPath" '
      'normalizedCandidates=${normalizedCandidateNames.join(' || ')}',
    );
    if (normalizedName.isEmpty) {
      debugPrint('[Pipeline] No normalized name available after OCR.');
      return const CardRecognitionResult(
        bestMatch: null,
        candidates: [],
        requiresManualSelection: false,
      );
    }

    final cardsById = <String, MagicCard>{};
    for (final candidateName in normalizedCandidateNames) {
      final cards = await catalogRepository.searchByNormalizedName(candidateName);
      for (final card in cards) {
        cardsById[card.id] = card;
      }
    }

    List<MagicCard> cards = cardsById.values.toList();
    if (cards.isEmpty) {
      cards = await catalogRepository.getAll();
    }

    final bestCandidatesById = <String, CardCandidate>{};
    for (final candidateName in normalizedCandidateNames.isEmpty
        ? [ocrResult.detectedName]
        : ocrResult.candidateNames) {
      final extraction = OcrExtractionResult(
        detectedName: candidateName,
        candidateNames: ocrResult.candidateNames,
        detectedCollectorNumber: ocrResult.detectedCollectorNumber,
        detectedSetText: ocrResult.detectedSetText,
        confidence: ocrResult.confidence,
        detectedScript: ocrResult.detectedScript,
      );
      final matchedForCandidate = matcherService.matchCards(extraction, cards).take(5);
      for (final candidate in matchedForCandidate) {
        final existing = bestCandidatesById[candidate.card.id];
        if (existing == null || candidate.finalScore > existing.finalScore) {
          bestCandidatesById[candidate.card.id] = candidate;
        }
      }
    }

    final matched = bestCandidatesById.values.toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final topMatched = matched.take(3).toList();
    debugPrint('[Pipeline] catalogCandidates=${cards.length} matchedTop=${topMatched.length}');
    for (final candidate in topMatched) {
      debugPrint(
        '[Pipeline] candidate '
        'name="${candidate.card.name}" '
        'set="${candidate.card.setCode ?? '-'}" '
        'collector="${candidate.card.collectorNumber ?? '-'}" '
        'nameScore=${candidate.nameScore.toStringAsFixed(2)} '
        'finalScore=${candidate.finalScore.toStringAsFixed(2)}',
      );
    }

    if (topMatched.isEmpty) {
      debugPrint('[Pipeline] No local card candidates matched.');
      return const CardRecognitionResult(
        bestMatch: null,
        candidates: [],
        requiresManualSelection: false,
      );
    }

    if (topMatched.length == 1) {
      debugPrint('[Pipeline] Single candidate selected: "${topMatched.first.card.name}"');
      return CardRecognitionResult(
        bestMatch: topMatched.first.card,
        candidates: topMatched,
        requiresManualSelection: false,
      );
    }

    final best = topMatched.first;
    final second = topMatched.length > 1 ? topMatched[1] : null;
    final requiresManualSelection =
        second != null &&
        best.finalScore < 0.88 &&
        (best.finalScore - second.finalScore).abs() < 0.12;

    debugPrint(
      '[Pipeline] best="${best.card.name}" '
      'bestScore=${best.finalScore.toStringAsFixed(2)} '
      'secondScore=${second?.finalScore.toStringAsFixed(2) ?? '-'} '
      'requiresManualSelection=$requiresManualSelection',
    );

    return CardRecognitionResult(
      bestMatch: requiresManualSelection ? null : best.card,
      candidates: topMatched,
      requiresManualSelection: requiresManualSelection,
    );
  }
}
