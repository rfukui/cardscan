# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class SourceLocalization:
    language_code: str
    name: str
    type_text: str = ""
    rules_text: str = ""
    face_name: str = ""
    flavor_text: str = ""
    multiverse_id: str = ""


@dataclass(frozen=True)
class SourcePrinting:
    uuid: str
    name_en: str
    set_code: str
    set_name: str
    collector_number: str
    language: str
    mana_cost: str = ""
    type_line_en: str = ""
    oracle_text_en: str = ""
    rarity: str = ""
    power: str = ""
    toughness: str = ""
    ascii_name: str = ""
    scryfall_id: str = ""
    multiverse_id: str = ""
    face_name: str = ""
    layout: str = ""
    localizations: list[SourceLocalization] = field(default_factory=list)


@dataclass(frozen=True)
class CardRow:
    uuid: str
    name_en: str
    normalized_name_en: str
    set_code: str
    set_name: str
    collector_number: str
    language: str
    mana_cost: str
    type_line_en: str
    oracle_text_en: str
    rarity: str
    power: str
    toughness: str
    ascii_name: str
    scryfall_id: str
    multiverse_id: str


@dataclass(frozen=True)
class CardLocalizationRow:
    id: str
    card_uuid: str
    language_code: str
    name: str
    normalized_name: str
    type_text: str
    normalized_type_text: str
    rules_text: str
    face_name: str
    flavor_text: str
    multiverse_id: str


@dataclass(frozen=True)
class CardAliasRow:
    id: str
    card_uuid: str
    language_code: str
    alias: str
    normalized_alias: str
    alias_source: str


@dataclass(frozen=True)
class ScannerDataset:
    cards: list[CardRow]
    localizations: list[CardLocalizationRow]
    aliases: list[CardAliasRow]
