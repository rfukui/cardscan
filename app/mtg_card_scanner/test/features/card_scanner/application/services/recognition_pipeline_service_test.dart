// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/card_matcher_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/native_vision_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/ocr_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/application/services/recognition_pipeline_service.dart';
import 'package:mtg_card_scanner/features/card_scanner/domain/entities/magic_card.dart';

import '../../../../support/channel_mocks.dart';
import '../../../../support/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const helpingHand = MagicCard(
    id: 'soa-70',
    name: 'Helping Hand',
    normalizedName: 'helping hand',
    setCode: 'SOA',
    collectorNumber: '70',
    lang: 'Japanese',
    rarity: 'uncommon',
  );

  setUp(() async {
    await mockNativeVisionChannel(rectifiedPath: 'rectified.jpg');
  });

  tearDown(() async {
    await clearTestChannels();
  });

  test('uses multiple OCR candidate lines when the card name is not at the top',
      () async {
    await mockTextRecognizerChannel(
      scriptLines: {
        0: [
          makeTextLine(text: 'Sorcery', top: 60),
          makeTextLine(text: 'Helping Hand', top: 320),
          makeTextLine(text: '070', top: 540),
        ],
        3: [
          makeTextLine(text: 'ソーサリー', top: 60),
          makeTextLine(text: 'Helping Hand', top: 320),
        ],
      },
    );

    final service = RecognitionPipelineService(
      nativeVisionService: NativeVisionService(),
      ocrService: OcrService(),
      matcherService: CardMatcherService(),
      catalogRepository: FakeCardCatalogRepository(
        searchResults: const {
          'helping hand': [helpingHand],
        },
      ),
    );

    final result = await service.recognize('captured.jpg');

    expect(result.bestMatch?.id, helpingHand.id);
    expect(result.requiresManualSelection, isFalse);
  });

  test('returns no match when OCR produces no usable text', () async {
    await mockTextRecognizerChannel(scriptLines: const {});

    final service = RecognitionPipelineService(
      nativeVisionService: NativeVisionService(),
      ocrService: OcrService(),
      matcherService: CardMatcherService(),
      catalogRepository: FakeCardCatalogRepository(),
    );

    final result = await service.recognize('captured.jpg');

    expect(result.bestMatch, isNull);
    expect(result.candidates, isEmpty);
  });
}
