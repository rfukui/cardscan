// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/scan_history_entry.dart';
import '../../domain/repositories/scan_history_repository.dart';
import '../datasources/local_card_database.dart';

class ScanHistoryRepositoryImpl implements ScanHistoryRepository {
  final LocalCardDatabase database;

  ScanHistoryRepositoryImpl(this.database);

  @override
  Future<void> save(ScanHistoryEntry entry) async {
    await database.saveScanHistory({
      'id': entry.id,
      'card_id': entry.cardId,
      'card_name': entry.cardName,
      'scanned_at': entry.scannedAt.toIso8601String(),
      'image_path': entry.imagePath,
      'selected_manually': entry.selectedManually ? 1 : 0,
    });
  }

  @override
  Future<List<ScanHistoryEntry>> listRecent() async {
    final rows = await database.listScanHistory();
    return rows.map((row) {
      return ScanHistoryEntry(
        id: row['id'] as String,
        cardId: row['card_id'] as String?,
        cardName: row['card_name'] as String,
        scannedAt: DateTime.parse(row['scanned_at'] as String),
        imagePath: row['image_path'] as String?,
        selectedManually: (row['selected_manually'] as int) == 1,
      );
    }).toList();
  }
}
