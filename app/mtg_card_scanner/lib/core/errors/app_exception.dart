// SPDX-License-Identifier: GPL-3.0-or-later

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class MissingCatalogAssetException extends AppException {
  MissingCatalogAssetException()
      : super(
          'Missing SQLite asset at assets/database/mtg_cards.sqlite. '
          'Run the extractor build and sync steps before launching the app.',
        );
}
