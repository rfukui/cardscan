// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/core/errors/app_exception.dart';
import 'package:mtg_card_scanner/features/card_scanner/presentation/providers/providers.dart';

import '../../../../support/test_fakes.dart';

void main() {
  test('rethrows missing catalog asset errors unchanged', () async {
    final container = ProviderContainer(
      overrides: [
        cardCatalogRepositoryProvider.overrideWith(
          (ref) => FakeCardCatalogRepository(
            seedError: MissingCatalogAssetException(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen<AsyncValue<void>>(
      appBootstrapProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.pump();

    final state = container.read(appBootstrapProvider);
    expect(state.hasError, isTrue);
    expect(
      state.error,
      isA<MissingCatalogAssetException>(),
    );
  });

  test('wraps unexpected bootstrap failures in AppException', () async {
    final container = ProviderContainer(
      overrides: [
        cardCatalogRepositoryProvider.overrideWith(
          (ref) => FakeCardCatalogRepository(seedError: StateError('broken')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen<AsyncValue<void>>(
      appBootstrapProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.pump();

    final state = container.read(appBootstrapProvider);
    expect(state.hasError, isTrue);
    expect(
      state.error,
      isA<AppException>().having(
        (error) => error.message,
        'message',
        contains('Unable to initialize the local catalog database'),
      ),
    );
  });
}
