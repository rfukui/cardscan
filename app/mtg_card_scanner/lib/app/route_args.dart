// SPDX-License-Identifier: GPL-3.0-or-later

class CardResultRouteArgs {
  final String? cardId;
  final String? imagePath;
  final bool selectedManually;

  const CardResultRouteArgs({
    this.cardId,
    this.imagePath,
    this.selectedManually = false,
  });
}
