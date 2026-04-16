# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import logging
import shutil
import sqlite3
from pathlib import Path

from .models import ScannerDataset

logger = logging.getLogger(__name__)


SCHEMA_SQL = """
CREATE TABLE cards (
  uuid TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  normalized_name_en TEXT NOT NULL,
  set_code TEXT,
  set_name TEXT,
  collector_number TEXT,
  language TEXT,
  mana_cost TEXT,
  type_line_en TEXT,
  oracle_text_en TEXT,
  rarity TEXT,
  power TEXT,
  toughness TEXT,
  ascii_name TEXT,
  scryfall_id TEXT,
  multiverse_id TEXT
);

CREATE TABLE card_localizations (
  id TEXT PRIMARY KEY,
  card_uuid TEXT NOT NULL,
  language_code TEXT NOT NULL,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  type_text TEXT,
  normalized_type_text TEXT,
  rules_text TEXT,
  face_name TEXT,
  flavor_text TEXT,
  multiverse_id TEXT
);

CREATE TABLE card_aliases (
  id TEXT PRIMARY KEY,
  card_uuid TEXT NOT NULL,
  language_code TEXT NOT NULL,
  alias TEXT NOT NULL,
  normalized_alias TEXT NOT NULL,
  alias_source TEXT NOT NULL
);

CREATE INDEX idx_cards_normalized_name_en ON cards(normalized_name_en);
CREATE INDEX idx_cards_set_code ON cards(set_code);
CREATE INDEX idx_cards_collector_number ON cards(collector_number);
CREATE INDEX idx_card_localizations_card_uuid ON card_localizations(card_uuid);
CREATE INDEX idx_card_localizations_language_code ON card_localizations(language_code);
CREATE INDEX idx_card_localizations_normalized_name ON card_localizations(normalized_name);
CREATE INDEX idx_card_aliases_card_uuid ON card_aliases(card_uuid);
CREATE INDEX idx_card_aliases_language_code ON card_aliases(language_code);
CREATE INDEX idx_card_aliases_normalized_alias ON card_aliases(normalized_alias);
"""


class ScannerDatabaseExporter:
    def export(self, output_path: Path, dataset: ScannerDataset) -> None:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        if output_path.exists():
            output_path.unlink()

        connection = sqlite3.connect(output_path)
        try:
            connection.executescript(SCHEMA_SQL)
            self._insert_cards(connection, dataset)
            self._insert_localizations(connection, dataset)
            self._insert_aliases(connection, dataset)
            connection.commit()
        finally:
            connection.close()

        logger.info(
            "Exported scanner SQLite with %s cards, %s localizations, %s aliases to %s",
            len(dataset.cards),
            len(dataset.localizations),
            len(dataset.aliases),
            output_path,
        )

    def sync_to_app_assets(self, input_path: Path, app_assets_path: Path) -> None:
        source = Path(input_path)
        destination = Path(app_assets_path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        logger.info("Copied %s to %s", source, destination)

    def inspect(self, database_path: Path) -> dict[str, object]:
        database_path = Path(database_path)
        connection = sqlite3.connect(database_path)
        try:
            counts = {
                "cards": self._count(connection, "cards"),
                "card_localizations": self._count(connection, "card_localizations"),
                "card_aliases": self._count(connection, "card_aliases"),
                "languages": self._language_counts(connection),
                "top_sets": self._set_counts(connection),
            }
            return counts
        finally:
            connection.close()

    def _insert_cards(self, connection: sqlite3.Connection, dataset: ScannerDataset) -> None:
        connection.executemany(
            """
            INSERT INTO cards (
              uuid, name_en, normalized_name_en, set_code, set_name,
              collector_number, language, mana_cost, type_line_en, oracle_text_en,
              rarity, power, toughness, ascii_name, scryfall_id, multiverse_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    row.uuid,
                    row.name_en,
                    row.normalized_name_en,
                    row.set_code,
                    row.set_name,
                    row.collector_number,
                    row.language,
                    row.mana_cost,
                    row.type_line_en,
                    row.oracle_text_en,
                    row.rarity,
                    row.power,
                    row.toughness,
                    row.ascii_name,
                    row.scryfall_id,
                    row.multiverse_id,
                )
                for row in dataset.cards
            ],
        )

    def _insert_localizations(
        self,
        connection: sqlite3.Connection,
        dataset: ScannerDataset,
    ) -> None:
        connection.executemany(
            """
            INSERT INTO card_localizations (
              id, card_uuid, language_code, name, normalized_name,
              type_text, normalized_type_text, rules_text, face_name,
              flavor_text, multiverse_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    row.id,
                    row.card_uuid,
                    row.language_code,
                    row.name,
                    row.normalized_name,
                    row.type_text,
                    row.normalized_type_text,
                    row.rules_text,
                    row.face_name,
                    row.flavor_text,
                    row.multiverse_id,
                )
                for row in dataset.localizations
            ],
        )

    def _insert_aliases(
        self,
        connection: sqlite3.Connection,
        dataset: ScannerDataset,
    ) -> None:
        connection.executemany(
            """
            INSERT INTO card_aliases (
              id, card_uuid, language_code, alias, normalized_alias, alias_source
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    row.id,
                    row.card_uuid,
                    row.language_code,
                    row.alias,
                    row.normalized_alias,
                    row.alias_source,
                )
                for row in dataset.aliases
            ],
        )

    def _count(self, connection: sqlite3.Connection, table_name: str) -> int:
        row = connection.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()
        return int(row[0]) if row else 0

    def _language_counts(self, connection: sqlite3.Connection) -> list[tuple[str, int]]:
        return [
            (str(row[0]), int(row[1]))
            for row in connection.execute(
                """
                SELECT language_code, COUNT(*)
                FROM card_localizations
                GROUP BY language_code
                ORDER BY COUNT(*) DESC, language_code ASC
                """
            )
        ]

    def _set_counts(self, connection: sqlite3.Connection) -> list[tuple[str, int]]:
        return [
            (str(row[0]), int(row[1]))
            for row in connection.execute(
                """
                SELECT set_code, COUNT(*)
                FROM cards
                GROUP BY set_code
                ORDER BY COUNT(*) DESC, set_code ASC
                LIMIT 20
                """
            )
        ]
