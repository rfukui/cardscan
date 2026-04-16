# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import sqlite3
from pathlib import Path


def write_sample_mtgjson_sqlite(database_path: Path) -> None:
    connection = sqlite3.connect(database_path)
    try:
        connection.executescript(
            """
            CREATE TABLE cards (
              uuid TEXT PRIMARY KEY,
              name TEXT,
              setCode TEXT,
              number TEXT,
              language TEXT,
              manaCost TEXT,
              type TEXT,
              text TEXT,
              rarity TEXT,
              power TEXT,
              toughness TEXT,
              asciiName TEXT,
              scryfallId TEXT,
              multiverseId TEXT,
              faceName TEXT,
              layout TEXT
            );

            CREATE TABLE sets (
              code TEXT PRIMARY KEY,
              name TEXT
            );

            CREATE TABLE foreignData (
              uuid TEXT,
              language TEXT,
              name TEXT,
              typeText TEXT,
              text TEXT,
              faceName TEXT,
              flavorText TEXT,
              multiverseId TEXT
            );
            """
        )
        connection.execute(
            """
            INSERT INTO cards (
              uuid, name, setCode, number, language, manaCost, type, text,
              rarity, power, toughness, asciiName, scryfallId, multiverseId,
              faceName, layout
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "card-1",
                "Lightning Bolt",
                "M11",
                "146",
                "English",
                "{R}",
                "Instant",
                "Lightning Bolt deals 3 damage to any target.",
                "common",
                "",
                "",
                "Lightning Bolt",
                "scryfall-1",
                "123",
                "",
                "normal",
            ),
        )
        connection.execute(
            "INSERT INTO sets (code, name) VALUES (?, ?)",
            ("M11", "Magic 2011"),
        )
        connection.execute(
            """
            INSERT INTO foreignData (
              uuid, language, name, typeText, text, faceName, flavorText, multiverseId
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "card-1",
                "Japanese",
                "稲妻",
                "インスタント",
                "クリーチャー1体かプレイヤー1人を対象とする。稲妻はそれに3点のダメージを与える。",
                "",
                "",
                "456",
            ),
        )
        connection.commit()
    finally:
        connection.close()
