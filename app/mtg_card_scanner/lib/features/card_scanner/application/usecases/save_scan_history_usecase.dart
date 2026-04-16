// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/scan_history_entry.dart';
import '../../domain/repositories/scan_history_repository.dart';

class SaveScanHistoryUseCase {
  final ScanHistoryRepository repository;

  SaveScanHistoryUseCase(this.repository);

  Future<void> execute(ScanHistoryEntry entry) async {
    await repository.save(entry);
  }
}
