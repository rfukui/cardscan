// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/app/app.dart';

void main() {
  testWidgets('app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MtgCardScannerApp(),
      ),
    );

    expect(find.text('MTG Card Scanner'), findsOneWidget);
  });
}
