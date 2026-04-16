// SPDX-License-Identifier: GPL-3.0-or-later

class ScanHistoryEntry {
  final String id;
  final String? cardId;
  final String cardName;
  final DateTime scannedAt;
  final String? imagePath;
  final bool selectedManually;

  const ScanHistoryEntry({
    required this.id,
    this.cardId,
    required this.cardName,
    required this.scannedAt,
    this.imagePath,
    this.selectedManually = false,
  });
}
