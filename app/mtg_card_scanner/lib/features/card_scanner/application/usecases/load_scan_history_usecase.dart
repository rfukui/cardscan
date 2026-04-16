// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/scan_history_entry.dart';
import '../../domain/repositories/scan_history_repository.dart';

class LoadScanHistoryUseCase {
  final ScanHistoryRepository repository;

  LoadScanHistoryUseCase(this.repository);

  Future<List<ScanHistoryEntry>> execute() async {
    return repository.listRecent();
  }
}
