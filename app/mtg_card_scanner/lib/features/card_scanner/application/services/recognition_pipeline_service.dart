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
  RecognitionPipelineService({
    required this.nativeVisionService,
    required this.ocrService,
    required this.matcherService,
    required this.catalogRepository,
  });

  final NativeVisionService nativeVisionService;
  final OcrService ocrService;
  final CardMatcherService matcherService;
  final CardCatalogRepository catalogRepository;

  Future<CardRecognitionResult> recognize(String imagePath) async {
    final preparedImagePath = await _prepareImagePath(imagePath);
    final ocrResult = await ocrService.extractText(preparedImagePath);
    final normalizedCandidates = _normalizedCandidateNames(ocrResult);

    debugPrint(
      '[Pipeline] image="$imagePath" rectified="$preparedImagePath" '
      'normalizedCandidates=${normalizedCandidates.join(' || ')}',
    );

    if (normalizedCandidates.isEmpty) {
      debugPrint('[Pipeline] No normalized name available after OCR.');
      return _emptyResult();
    }

    final candidatePool = await _loadCandidatePool(normalizedCandidates);
    final matchedCandidates = _matchAcrossCandidates(
      ocrResult: ocrResult,
      cards: candidatePool,
    );

    debugPrint(
      '[Pipeline] catalogCandidates=${candidatePool.length} '
      'matchedTop=${matchedCandidates.length}',
    );
    for (final candidate in matchedCandidates) {
      debugPrint(
        '[Pipeline] candidate '
        'name="${candidate.card.name}" '
        'set="${candidate.card.setCode ?? '-'}" '
        'collector="${candidate.card.collectorNumber ?? '-'}" '
        'nameScore=${candidate.nameScore.toStringAsFixed(2)} '
        'finalScore=${candidate.finalScore.toStringAsFixed(2)}',
      );
    }

    return _buildRecognitionResult(matchedCandidates);
  }

  Future<String> _prepareImagePath(String imagePath) async {
    final rectifiedPath = await nativeVisionService.rectifyCard(imagePath);
    if (rectifiedPath.trim().isEmpty) {
      debugPrint(
        '[Pipeline] Native vision returned an empty rectified path. '
        'Falling back to original image.',
      );
      return imagePath;
    }
    return rectifiedPath;
  }

  List<String> _normalizedCandidateNames(OcrExtractionResult ocrResult) {
    return [
      for (final candidate in ocrResult.candidateNames)
        normalizeText(candidate),
    ].where((candidate) => candidate.isNotEmpty).toSet().toList();
  }

  Future<List<MagicCard>> _loadCandidatePool(
    List<String> normalizedCandidates,
  ) async {
    final cardsById = <String, MagicCard>{};

    for (final candidateName in normalizedCandidates) {
      final cards =
          await catalogRepository.searchByNormalizedName(candidateName);
      for (final card in cards) {
        cardsById[card.id] = card;
      }
    }

    if (cardsById.isNotEmpty) {
      return cardsById.values.toList();
    }

    return catalogRepository.getAll();
  }

  List<CardCandidate> _matchAcrossCandidates({
    required OcrExtractionResult ocrResult,
    required List<MagicCard> cards,
  }) {
    final bestCandidatesById = <String, CardCandidate>{};
    final attemptedNames = ocrResult.candidateNames.isEmpty
        ? [ocrResult.detectedName]
        : ocrResult.candidateNames;

    for (final candidateName in attemptedNames) {
      final extraction = OcrExtractionResult(
        detectedName: candidateName,
        candidateNames: ocrResult.candidateNames,
        detectedCollectorNumber: ocrResult.detectedCollectorNumber,
        detectedSetText: ocrResult.detectedSetText,
        confidence: ocrResult.confidence,
        detectedScript: ocrResult.detectedScript,
      );

      final matchedForCandidate =
          matcherService.matchCards(extraction, cards).take(5);
      for (final candidate in matchedForCandidate) {
        final existing = bestCandidatesById[candidate.card.id];
        if (existing == null || candidate.finalScore > existing.finalScore) {
          bestCandidatesById[candidate.card.id] = candidate;
        }
      }
    }

    final matched = bestCandidatesById.values.toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return matched.take(3).toList();
  }

  CardRecognitionResult _buildRecognitionResult(
      List<CardCandidate> topMatched) {
    if (topMatched.isEmpty) {
      debugPrint('[Pipeline] No local card candidates matched.');
      return _emptyResult();
    }

    if (topMatched.length == 1) {
      debugPrint(
        '[Pipeline] Single candidate selected: "${topMatched.first.card.name}"',
      );
      return CardRecognitionResult(
        bestMatch: topMatched.first.card,
        candidates: topMatched,
        requiresManualSelection: false,
      );
    }

    final best = topMatched.first;
    final second = topMatched[1];
    final requiresManualSelection = best.finalScore < 0.88 &&
        (best.finalScore - second.finalScore).abs() < 0.12;

    debugPrint(
      '[Pipeline] best="${best.card.name}" '
      'bestScore=${best.finalScore.toStringAsFixed(2)} '
      'secondScore=${second.finalScore.toStringAsFixed(2)} '
      'requiresManualSelection=$requiresManualSelection',
    );

    return CardRecognitionResult(
      bestMatch: requiresManualSelection ? null : best.card,
      candidates: topMatched,
      requiresManualSelection: requiresManualSelection,
    );
  }

  CardRecognitionResult _emptyResult() {
    return const CardRecognitionResult(
      bestMatch: null,
      candidates: [],
      requiresManualSelection: false,
    );
  }
}
