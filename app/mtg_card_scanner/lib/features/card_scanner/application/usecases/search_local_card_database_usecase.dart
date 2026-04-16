// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/magic_card.dart';
import '../../domain/repositories/card_catalog_repository.dart';

class SearchLocalCardDatabaseUseCase {
  final CardCatalogRepository repository;

  SearchLocalCardDatabaseUseCase(this.repository);

  Future<List<MagicCard>> execute(String normalizedName) async {
    return repository.searchByNormalizedName(normalizedName);
  }
}
