// SPDX-License-Identifier: GPL-3.0-or-later

import '../entities/scan_history_entry.dart';

abstract class ScanHistoryRepository {
  Future<void> save(ScanHistoryEntry entry);
  Future<List<ScanHistoryEntry>> listRecent();
}
