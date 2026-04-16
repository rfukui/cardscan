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
      final languageBonus = _languageBonus(extraction.detectedScript, query, card.lang);
      final rarityBonus = _rarityBonus(card.rarity);
      final finalScore =
          (nameScore * 0.80) +
          (collectorScore * 0.15) +
          (setScore * 0.05) +
          languageBonus +
          rarityBonus;
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

  double _languageBonus(String? detectedScript, String query, String? cardLanguage) {
    if (cardLanguage == null || cardLanguage.isEmpty) {
      return 0.0;
    }

    final normalizedLanguage = cardLanguage.toLowerCase();
    switch (detectedScript) {
      case 'japanese':
        return normalizedLanguage.contains('japanese') ? 0.03 : 0.0;
      case 'chinese':
        return normalizedLanguage.contains('chinese') ? 0.03 : 0.0;
      case 'korean':
        return normalizedLanguage.contains('korean') ? 0.03 : 0.0;
      case 'latin':
        if (RegExp(r'^[a-z0-9 ]+$').hasMatch(query)) {
          if (normalizedLanguage.contains('english')) {
            return 0.03;
          }
          if (normalizedLanguage.contains('portuguese') ||
              normalizedLanguage.contains('spanish') ||
              normalizedLanguage.contains('french') ||
              normalizedLanguage.contains('german') ||
              normalizedLanguage.contains('italian')) {
            return 0.015;
          }
        }
        return 0.0;
      default:
        return 0.0;
    }
  }

  double _rarityBonus(String? rarity) {
    switch ((rarity ?? '').toLowerCase()) {
      case 'mythic':
        return 0.025;
      case 'rare':
        return 0.02;
      case 'special':
        return 0.018;
      case 'uncommon':
        return 0.012;
      case 'common':
        return 0.008;
      default:
        return 0.0;
    }
  }
}
