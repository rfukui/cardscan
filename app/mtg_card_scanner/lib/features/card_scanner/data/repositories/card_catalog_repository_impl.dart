// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/magic_card.dart';
import '../../domain/repositories/card_catalog_repository.dart';
import '../datasources/local_card_database.dart';

class CardCatalogRepositoryImpl implements CardCatalogRepository {
  final LocalCardDatabase database;

  CardCatalogRepositoryImpl(this.database);

  @override
  Future<void> seedIfNeeded() async {
    await database.seedIfNeeded();
  }

  @override
  Future<List<MagicCard>> searchByNormalizedName(String query) async {
    return database.searchByNormalizedName(query);
  }

  @override
  Future<MagicCard?> getById(String id) async {
    return database.getById(id);
  }

  @override
  Future<List<MagicCard>> getAll() async {
    return database.getAll();
  }
}
