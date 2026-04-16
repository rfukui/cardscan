// SPDX-License-Identifier: GPL-3.0-or-later

import '../../domain/entities/magic_card.dart';

class MagicCardModel extends MagicCard {
  MagicCardModel({
    required super.id,
    required super.name,
    required super.normalizedName,
    super.setCode,
    super.setName,
    super.collectorNumber,
    super.lang,
    super.manaCost,
    super.typeLine,
    super.oracleText,
    super.rarity,
    super.power,
    super.toughness,
    super.imageThumbPath,
  });

  factory MagicCardModel.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['name_en']) as String;
    final normalizedName =
        (map['normalized_name'] ?? map['normalized_name_en']) as String;

    return MagicCardModel(
      id: (map['id'] ?? map['uuid']) as String,
      name: name,
      normalizedName: normalizedName,
      setCode: map['set_code'] as String?,
      setName: map['set_name'] as String?,
      collectorNumber: map['collector_number'] as String?,
      lang: (map['lang'] ?? map['language']) as String?,
      manaCost: map['mana_cost'] as String?,
      typeLine: (map['type_line'] ?? map['type_line_en']) as String?,
      oracleText: (map['oracle_text'] ?? map['oracle_text_en']) as String?,
      rarity: map['rarity'] as String?,
      power: map['power'] as String?,
      toughness: map['toughness'] as String?,
      imageThumbPath: map['image_thumb_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'set_code': setCode,
      'set_name': setName,
      'collector_number': collectorNumber,
      'lang': lang,
      'mana_cost': manaCost,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'rarity': rarity,
      'power': power,
      'toughness': toughness,
      'image_thumb_path': imageThumbPath,
    };
  }
}
