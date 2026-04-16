# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import json
import logging
import lzma
import shutil
import sqlite3
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

from .models import SourceLocalization, SourcePrinting

logger = logging.getLogger(__name__)


class MtgJsonSqliteReader:
    def __init__(self, input_path: Path) -> None:
        self.input_path = Path(input_path)

    def load_printings(self) -> list[SourcePrinting]:
        with self._open_connection() as connection:
            cards_table = self._resolve_table(connection, ["cards"])
            sets_table = self._resolve_optional_table(connection, ["sets"])
            foreign_table = self._resolve_optional_table(
                connection,
                ["foreignData", "foreign_data", "cardForeignData", "card_foreign_data"],
            )

            set_names = self._load_set_names(connection, sets_table)
            foreign_rows = self._load_foreign_localizations(connection, foreign_table)
            rows = connection.execute(f"SELECT * FROM {cards_table}")

            printings: list[SourcePrinting] = []
            for row in rows:
                printing = self._row_to_printing(
                    row=row,
                    set_names=set_names,
                    foreign_rows=foreign_rows,
                )
                if printing is not None:
                    printings.append(printing)

            logger.info("Loaded %s raw printings from MTGJSON SQLite", len(printings))
            return printings

    @contextmanager
    def _open_connection(self) -> Iterator[sqlite3.Connection]:
        if not self.input_path.exists():
            raise FileNotFoundError(f"Input file not found: {self.input_path}")

        with self._prepared_input_path() as prepared_path:
            connection = sqlite3.connect(prepared_path)
            connection.row_factory = sqlite3.Row
            try:
                yield connection
            finally:
                connection.close()

    @contextmanager
    def _prepared_input_path(self) -> Iterator[Path]:
        if self.input_path.suffix != ".xz":
            yield self.input_path
            return

        with tempfile.NamedTemporaryFile(
            suffix=".sqlite", delete=False
        ) as temporary_file:
            temp_path = Path(temporary_file.name)

        try:
            logger.info("Decompressing %s to temporary SQLite file", self.input_path)
            with lzma.open(self.input_path, "rb") as compressed, temp_path.open(
                "wb"
            ) as output:
                shutil.copyfileobj(compressed, output)
            yield temp_path
        finally:
            temp_path.unlink(missing_ok=True)

    def _row_to_printing(
        self,
        row: sqlite3.Row,
        set_names: dict[str, str],
        foreign_rows: dict[str, list[SourceLocalization]],
    ) -> SourcePrinting | None:
        row_dict = dict(row)
        uuid = self._text(row_dict, "uuid", "id")
        if not uuid:
            return None

        identifiers = self._json_object(row_dict.get("identifiers"))
        foreign_localizations = list(foreign_rows.get(uuid, []))
        foreign_localizations.extend(
            self._parse_foreign_data_json(row_dict.get("foreignData"))
        )
        foreign_localizations.extend(
            self._parse_foreign_data_json(row_dict.get("foreign_data"))
        )

        deduplicated_localizations = self._deduplicate_localizations(
            foreign_localizations
        )

        set_code = self._text(row_dict, "setCode", "set_code")
        set_name = self._text(row_dict, "setName", "set_name") or set_names.get(
            set_code, ""
        )

        return SourcePrinting(
            uuid=uuid,
            name_en=self._text(row_dict, "name"),
            set_code=set_code,
            set_name=set_name,
            collector_number=self._text(
                row_dict, "number", "collectorNumber", "collector_number"
            ),
            language=self._text(row_dict, "language", default="en"),
            mana_cost=self._text(row_dict, "manaCost", "mana_cost"),
            type_line_en=self._text(row_dict, "type", "typeLine", "type_line"),
            oracle_text_en=self._text(row_dict, "text", "oracleText", "oracle_text"),
            rarity=self._text(row_dict, "rarity"),
            power=self._text(row_dict, "power"),
            toughness=self._text(row_dict, "toughness"),
            ascii_name=self._text(row_dict, "asciiName", "ascii_name"),
            scryfall_id=self._text(row_dict, "scryfallId")
            or self._text_from_dict(identifiers, "scryfallId", "scryfallOracleId"),
            multiverse_id=self._text(row_dict, "multiverseId", "multiverse_id")
            or self._text_from_dict(identifiers, "multiverseId"),
            face_name=self._text(row_dict, "faceName", "face_name"),
            layout=self._text(row_dict, "layout"),
            localizations=deduplicated_localizations,
        )

    def _load_set_names(
        self,
        connection: sqlite3.Connection,
        sets_table: str | None,
    ) -> dict[str, str]:
        if sets_table is None:
            return {}

        set_names: dict[str, str] = {}
        for row in connection.execute(f"SELECT * FROM {sets_table}"):
            row_dict = dict(row)
            set_code = self._text(row_dict, "code", "setCode", "keyruneCode")
            set_name = self._text(row_dict, "name")
            if set_code and set_name:
                set_names[set_code] = set_name
        return set_names

    def _load_foreign_localizations(
        self,
        connection: sqlite3.Connection,
        table_name: str | None,
    ) -> dict[str, list[SourceLocalization]]:
        if table_name is None:
            return {}

        index: dict[str, list[SourceLocalization]] = {}
        rows = connection.execute(f"SELECT * FROM {table_name}")
        for row in rows:
            row_dict = dict(row)
            card_uuid = self._text(row_dict, "uuid", "cardUuid", "card_uuid")
            language = self._text(row_dict, "language", "languageCode", "language_code")
            name = self._text(row_dict, "name")
            if not card_uuid or not language or not name:
                continue

            localization = SourceLocalization(
                language_code=language,
                name=name,
                type_text=self._text(row_dict, "typeText", "type_text"),
                rules_text=self._text(row_dict, "text", "rulesText", "rules_text"),
                face_name=self._text(row_dict, "faceName", "face_name"),
                flavor_text=self._text(row_dict, "flavorText", "flavor_text"),
                multiverse_id=self._text(row_dict, "multiverseId", "multiverse_id"),
            )
            index.setdefault(card_uuid, []).append(localization)
        return index

    def _parse_foreign_data_json(self, raw_value: object) -> list[SourceLocalization]:
        items = self._json_list(raw_value)
        localizations: list[SourceLocalization] = []
        for item in items:
            if not isinstance(item, dict):
                continue
            language = self._text_from_dict(item, "language", "languageCode")
            name = self._text_from_dict(item, "name")
            if not language or not name:
                continue
            localizations.append(
                SourceLocalization(
                    language_code=language,
                    name=name,
                    type_text=self._text_from_dict(item, "typeText", "type_text"),
                    rules_text=self._text_from_dict(
                        item, "text", "rulesText", "rules_text"
                    ),
                    face_name=self._text_from_dict(item, "faceName", "face_name"),
                    flavor_text=self._text_from_dict(item, "flavorText", "flavor_text"),
                    multiverse_id=self._text_from_dict(
                        item, "multiverseId", "multiverse_id"
                    ),
                )
            )
        return localizations

    def _deduplicate_localizations(
        self,
        localizations: list[SourceLocalization],
    ) -> list[SourceLocalization]:
        deduplicated: list[SourceLocalization] = []
        seen: set[tuple[str, str, str]] = set()
        for localization in localizations:
            key = (
                localization.language_code,
                localization.name,
                localization.rules_text,
            )
            if key in seen:
                continue
            seen.add(key)
            deduplicated.append(localization)
        return deduplicated

    def _resolve_table(
        self,
        connection: sqlite3.Connection,
        candidates: list[str],
    ) -> str:
        table = self._resolve_optional_table(connection, candidates)
        if table is None:
            raise RuntimeError(
                f"Required table not found. Checked: {', '.join(candidates)}"
            )
        return table

    def _resolve_optional_table(
        self,
        connection: sqlite3.Connection,
        candidates: list[str],
    ) -> str | None:
        existing = {
            row["name"]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
        }
        for candidate in candidates:
            if candidate in existing:
                return candidate
        return None

    def _json_object(self, raw_value: object) -> dict[str, object]:
        if raw_value is None or raw_value == "":
            return {}
        if isinstance(raw_value, dict):
            return raw_value
        if isinstance(raw_value, bytes):
            raw_value = raw_value.decode("utf-8")
        if isinstance(raw_value, str):
            try:
                parsed = json.loads(raw_value)
            except json.JSONDecodeError:
                return {}
            return parsed if isinstance(parsed, dict) else {}
        return {}

    def _json_list(self, raw_value: object) -> list[object]:
        if raw_value is None or raw_value == "":
            return []
        if isinstance(raw_value, list):
            return raw_value
        if isinstance(raw_value, bytes):
            raw_value = raw_value.decode("utf-8")
        if isinstance(raw_value, str):
            try:
                parsed = json.loads(raw_value)
            except json.JSONDecodeError:
                return []
            return parsed if isinstance(parsed, list) else []
        return []

    def _text(self, row: dict[str, object], *keys: str, default: str = "") -> str:
        for key in keys:
            value = row.get(key)
            if value is None:
                continue
            return str(value).strip()
        return default

    def _text_from_dict(self, row: dict[str, object], *keys: str) -> str:
        return self._text(row, *keys)
