# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

from .models import (
    CardAliasRow,
    CardLocalizationRow,
    CardRow,
    ScannerDataset,
    SourceLocalization,
    SourcePrinting,
)
from .normalize import ascii_fold, normalize_text


class ScannerTransformer:
    EXCLUDED_LAYOUTS = {
        "token",
        "emblem",
        "plane",
        "scheme",
        "phenomenon",
        "art_series",
        "double_faced_token",
        "vanguard",
    }

    EXCLUDED_TYPE_MARKERS = (
        "token",
        "emblem",
        "sticker",
        "plane",
        "scheme",
        "phenomenon",
        "attraction",
        "contraption",
    )

    def __init__(self, include_non_scannables: bool = False) -> None:
        self.include_non_scannables = include_non_scannables

    def transform(self, printings: list[SourcePrinting]) -> ScannerDataset:
        cards: list[CardRow] = []
        localizations: list[CardLocalizationRow] = []
        aliases: list[CardAliasRow] = []

        localization_seen: set[tuple[str, str, str]] = set()
        alias_seen: set[tuple[str, str, str]] = set()

        for printing in printings:
            if not printing.name_en.strip():
                continue
            if self._should_exclude(printing):
                continue

            cards.append(
                CardRow(
                    uuid=printing.uuid,
                    name_en=printing.name_en,
                    normalized_name_en=normalize_text(printing.name_en),
                    set_code=printing.set_code,
                    set_name=printing.set_name,
                    collector_number=printing.collector_number,
                    language=printing.language or "en",
                    mana_cost=printing.mana_cost,
                    type_line_en=printing.type_line_en,
                    oracle_text_en=printing.oracle_text_en,
                    rarity=printing.rarity,
                    power=printing.power,
                    toughness=printing.toughness,
                    ascii_name=ascii_fold(printing.ascii_name or printing.name_en),
                    scryfall_id=printing.scryfall_id,
                    multiverse_id=printing.multiverse_id,
                )
            )

            primary_localization = SourceLocalization(
                language_code=printing.language or "en",
                name=printing.name_en,
                type_text=printing.type_line_en,
                rules_text=printing.oracle_text_en,
                face_name=printing.face_name,
                flavor_text="",
                multiverse_id=printing.multiverse_id,
            )
            self._add_localization(
                printing.uuid,
                primary_localization,
                localizations,
                localization_seen,
            )

            self._add_alias(
                printing.uuid,
                primary_localization.language_code,
                printing.name_en,
                "name_en",
                aliases,
                alias_seen,
            )
            self._add_alias(
                printing.uuid,
                primary_localization.language_code,
                printing.ascii_name or ascii_fold(printing.name_en),
                "ascii_name",
                aliases,
                alias_seen,
            )
            self._add_alias(
                printing.uuid,
                primary_localization.language_code,
                printing.face_name,
                "face_name",
                aliases,
                alias_seen,
            )

            for localization in printing.localizations:
                self._add_localization(
                    printing.uuid,
                    localization,
                    localizations,
                    localization_seen,
                )
                self._add_alias(
                    printing.uuid,
                    localization.language_code,
                    localization.name,
                    "foreign_name",
                    aliases,
                    alias_seen,
                )
                self._add_alias(
                    printing.uuid,
                    localization.language_code,
                    localization.face_name,
                    "foreign_face_name",
                    aliases,
                    alias_seen,
                )

        return ScannerDataset(
            cards=cards,
            localizations=localizations,
            aliases=aliases,
        )

    def _add_localization(
        self,
        card_uuid: str,
        localization: SourceLocalization,
        output: list[CardLocalizationRow],
        seen: set[tuple[str, str, str]],
    ) -> None:
        normalized_name = normalize_text(localization.name)
        if not normalized_name:
            return

        key = (card_uuid, localization.language_code, normalized_name)
        if key in seen:
            return
        seen.add(key)

        row_id = f"{card_uuid}:{localization.language_code}:{len(output) + 1}"
        output.append(
            CardLocalizationRow(
                id=row_id,
                card_uuid=card_uuid,
                language_code=localization.language_code,
                name=localization.name,
                normalized_name=normalized_name,
                type_text=localization.type_text,
                normalized_type_text=normalize_text(localization.type_text),
                rules_text=localization.rules_text,
                face_name=localization.face_name,
                flavor_text=localization.flavor_text,
                multiverse_id=localization.multiverse_id,
            )
        )

    def _add_alias(
        self,
        card_uuid: str,
        language_code: str,
        alias: str,
        alias_source: str,
        output: list[CardAliasRow],
        seen: set[tuple[str, str, str]],
    ) -> None:
        normalized_alias = normalize_text(alias)
        if not normalized_alias:
            return

        key = (card_uuid, language_code, normalized_alias)
        if key in seen:
            return
        seen.add(key)

        row_id = f"{card_uuid}:{language_code}:alias:{len(output) + 1}"
        output.append(
            CardAliasRow(
                id=row_id,
                card_uuid=card_uuid,
                language_code=language_code,
                alias=alias,
                normalized_alias=normalized_alias,
                alias_source=alias_source,
            )
        )

    def _should_exclude(self, printing: SourcePrinting) -> bool:
        if self.include_non_scannables:
            return False

        layout = normalize_text(printing.layout)
        if layout in self.EXCLUDED_LAYOUTS:
            return True

        type_line = normalize_text(printing.type_line_en)
        for marker in self.EXCLUDED_TYPE_MARKERS:
            if marker in type_line:
                return True

        return False
