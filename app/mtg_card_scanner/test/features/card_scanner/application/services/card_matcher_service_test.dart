// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/card_matcher_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/magic_card.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/ocr_extraction_result.dart';

void main() {
  const englishRare = MagicCard(
    id: 'soa-33',
    name: 'Smallpox',
    normalizedName: 'smallpox',
    setCode: 'SOA',
    collectorNumber: '33',
    lang: 'English',
    rarity: 'rare',
  );
  const japanesePrinting = MagicCard(
    id: 'soa-98',
    name: 'Smallpox',
    normalizedName: 'smallpox',
    setCode: 'SOA',
    collectorNumber: '98',
    lang: 'Japanese',
    rarity: 'rare',
  );
  const japaneseLocalized = MagicCard(
    id: 'sta-42-jp',
    name: '神々の思し召し',
    normalizedName: '神々の思し召し',
    setCode: 'STA',
    collectorNumber: '70',
    lang: 'Japanese',
    rarity: 'rare',
  );

  group('CardMatcherService', () {
    test('prefers English latin reading over non-latin printing with same name',
        () {
      final service = CardMatcherService();

      final matches = service.matchCards(
        const OcrExtractionResult(
          detectedName: 'Smallpox',
          confidence: 1,
          detectedScript: 'latin',
        ),
        const [japanesePrinting, englishRare],
      );

      expect(matches.first.card.id, englishRare.id);
    });

    test('matches exact multilingual names without stripping unicode', () {
      final service = CardMatcherService();

      final matches = service.matchCards(
        const OcrExtractionResult(
          detectedName: '神々の思し召し',
          confidence: 1,
          detectedScript: 'japanese',
        ),
        const [englishRare, japaneseLocalized],
      );

      expect(matches.first.card.id, japaneseLocalized.id);
      expect(matches.first.nameScore, greaterThan(0.8));
    });
  });
}
