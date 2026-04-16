// SPDX-License-Identifier: GPL-3.0-or-later

import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/card_candidate.dart';
import '../../domain/entities/magic_card.dart';
import '../../domain/entities/ocr_extraction_result.dart';

class CardMatcherService {
  List<CardCandidate> matchCards(
    OcrExtractionResult extraction,
    List<MagicCard> cards,
  ) {
    final query = normalizeText(extraction.detectedName);
    final candidates = <CardCandidate>[];

    for (final card in cards) {
      final cardName = card.normalizedName.isEmpty ? normalizeText(card.name) : card.normalizedName;
      final nameScore = _scoreName(query, cardName);
      if (nameScore <= 0.0) {
        continue;
      }
      var collectorScore = 0.0;
      if (extraction.detectedCollectorNumber != null &&
          extraction.detectedCollectorNumber == card.collectorNumber) {
        collectorScore = 1.0;
      }
      final setScore = 0.0;
      final finalScore = (nameScore * 0.80) + (collectorScore * 0.15) + (setScore * 0.05);
      candidates.add(CardCandidate(
        card: card,
        nameScore: nameScore,
        collectorScore: collectorScore,
        setScore: setScore,
        finalScore: finalScore,
      ));
    }

    candidates.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return candidates.take(3).toList();
  }

  double _scoreName(String query, String target) {
    if (query.isEmpty || target.isEmpty) return 0.0;
    if (query == target) return 1.0;
    if (target.contains(query) || query.contains(target)) {
      return 0.9;
    }
    final similarity = normalizedSimilarity(query, target);
    if (similarity > 0.6) {
      return similarity;
    }
    return 0.0;
  }
}
