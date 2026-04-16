// SPDX-License-Identifier: GPL-3.0-or-later

import '../entities/magic_card.dart';

abstract class CardCatalogRepository {
  Future<void> seedIfNeeded();
  Future<List<MagicCard>> searchByNormalizedName(String query);
  Future<MagicCard?> getById(String id);
  Future<List<MagicCard>> getAll();
}
