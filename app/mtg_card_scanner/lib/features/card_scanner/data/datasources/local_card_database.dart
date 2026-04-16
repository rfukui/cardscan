// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/magic_card.dart';
import '../models/magic_card_model.dart';

class LocalCardDatabase {
  static const _scanHistoryTable = 'scan_history';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = await _ensureBundledDatabaseAvailable();
    _database = await openDatabase(
      path,
      version: 1,
      onOpen: _onOpen,
    );
    return _database!;
  }

  static Future<void> _onOpen(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_scanHistoryTable (
        id TEXT PRIMARY KEY,
        card_id TEXT,
        card_name TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        image_path TEXT,
        selected_manually INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scan_history_scanned_at ON $_scanHistoryTable(scanned_at);',
    );
  }

  Future<void> seedIfNeeded() async {
    await database;
  }

  Future<List<MagicCard>> searchByNormalizedName(String query) async {
    final db = await database;
    if (query.isEmpty) {
      return getAll();
    }
    final likeQuery = '%$query%';
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT
        cards.uuid AS id,
        COALESCE(localizations.name, cards.name_en) AS name,
        COALESCE(localizations.normalized_name, cards.normalized_name_en) AS normalized_name,
        cards.set_code,
        cards.set_name,
        cards.collector_number,
        cards.language AS lang,
        cards.mana_cost,
        cards.type_line_en AS type_line,
        cards.oracle_text_en AS oracle_text,
        cards.rarity,
        cards.power,
        cards.toughness,
        NULL AS image_thumb_path
      FROM cards
      LEFT JOIN card_localizations AS localizations
        ON localizations.card_uuid = cards.uuid
        AND localizations.normalized_name LIKE ?
      LEFT JOIN card_aliases AS aliases
        ON aliases.card_uuid = cards.uuid
        AND aliases.normalized_alias LIKE ?
      WHERE cards.normalized_name_en LIKE ?
         OR localizations.card_uuid IS NOT NULL
         OR aliases.card_uuid IS NOT NULL
      ORDER BY
        CASE
          WHEN cards.normalized_name_en = ? THEN 0
          WHEN localizations.normalized_name = ? THEN 1
          WHEN aliases.normalized_alias = ? THEN 2
          ELSE 3
        END,
        cards.name_en ASC,
        cards.set_code ASC,
        cards.collector_number ASC
      LIMIT 50;
      ''',
      [likeQuery, likeQuery, likeQuery, query, query, query],
    );
    return results.map((row) => MagicCardModel.fromMap(row)).toList();
  }

  Future<MagicCard?> getById(String id) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT
        uuid AS id,
        name_en AS name,
        normalized_name_en AS normalized_name,
        set_code,
        set_name,
        collector_number,
        language AS lang,
        mana_cost,
        type_line_en AS type_line,
        oracle_text_en AS oracle_text,
        rarity,
        power,
        toughness,
        NULL AS image_thumb_path
      FROM cards
      WHERE uuid = ?
      LIMIT 1;
      ''',
      [id],
    );
    if (results.isEmpty) return null;
    return MagicCardModel.fromMap(results.first);
  }

  Future<List<MagicCard>> getAll() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT
        uuid AS id,
        name_en AS name,
        normalized_name_en AS normalized_name,
        set_code,
        set_name,
        collector_number,
        language AS lang,
        mana_cost,
        type_line_en AS type_line,
        oracle_text_en AS oracle_text,
        rarity,
        power,
        toughness,
        NULL AS image_thumb_path
      FROM cards
      ORDER BY name_en ASC, set_code ASC, collector_number ASC;
    ''');
    return results.map((row) => MagicCardModel.fromMap(row)).toList();
  }

  Future<void> saveScanHistory(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(_scanHistoryTable, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> listScanHistory() async {
    final db = await database;
    final results = await db.query(
      _scanHistoryTable,
      orderBy: 'scanned_at DESC',
      limit: 50,
    );
    return results;
  }

  Future<String> _ensureBundledDatabaseAvailable() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);

    final databasePath = p.join(
      directory.path,
      AppConstants.writableCatalogDatabaseName,
    );
    final databaseFile = File(databasePath);
    final versionFile = File(
      p.join(
          directory.path, AppConstants.writableCatalogDatabaseVersionFileName),
    );
    final currentVersion = await _readWritableDatabaseVersion(versionFile);
    final shouldRefreshDatabase = !await databaseFile.exists() ||
        currentVersion != AppConstants.bundledCatalogDatabaseVersion;

    if (!shouldRefreshDatabase) {
      return databasePath;
    }

    final asset = await _loadBundledDatabaseAsset();
    await databaseFile.writeAsBytes(
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      flush: true,
    );
    await versionFile.writeAsString(
      AppConstants.bundledCatalogDatabaseVersion.toString(),
      flush: true,
    );
    return databasePath;
  }

  Future<int?> _readWritableDatabaseVersion(File versionFile) async {
    if (!await versionFile.exists()) {
      return null;
    }
    final value = await versionFile.readAsString();
    return int.tryParse(value.trim());
  }

  Future<ByteData> _loadBundledDatabaseAsset() async {
    try {
      return await rootBundle.load(AppConstants.bundledCatalogAssetPath);
    } on FlutterError catch (error) {
      debugPrint(
        '[Bootstrap] Missing database asset: ${AppConstants.bundledCatalogAssetPath}. '
        'Run the extractor build and sync steps before starting the app.',
      );
      debugPrint('[Bootstrap] Asset load error: $error');
      throw MissingCatalogAssetException();
    }
  }
}
