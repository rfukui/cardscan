// SPDX-License-Identifier: GPL-3.0-or-later

class MagicCard {
  final String id;
  final String name;
  final String normalizedName;
  final String? setCode;
  final String? setName;
  final String? collectorNumber;
  final String? lang;
  final String? manaCost;
  final String? typeLine;
  final String? oracleText;
  final String? rarity;
  final String? power;
  final String? toughness;
  final String? imageThumbPath;

  const MagicCard({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.setCode,
    this.setName,
    this.collectorNumber,
    this.lang,
    this.manaCost,
    this.typeLine,
    this.oracleText,
    this.rarity,
    this.power,
    this.toughness,
    this.imageThumbPath,
  });
}
