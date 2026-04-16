// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/core/errors/app_exception.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/providers/providers.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/screens/camera_screen.dart';

void main() {
  testWidgets('shows a clear message when the catalog asset is missing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith(
            (ref) async => throw MissingCatalogAssetException(),
          ),
          rearCameraProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: CameraScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Database initialization failed'), findsOneWidget);
    expect(find.textContaining('The SQLite asset is missing.'), findsOneWidget);
    expect(
      find.textContaining('python3 -m mtg_data_extractor.cli build'),
      findsOneWidget,
    );
  });
}
