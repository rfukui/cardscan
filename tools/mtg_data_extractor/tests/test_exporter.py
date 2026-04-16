# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import sqlite3

from mtg_data_extractor.exporter import ScannerDatabaseExporter
from mtg_data_extractor.models import ScannerDataset
from mtg_data_extractor.transformer import ScannerTransformer


def test_exporter_creates_schema_and_inspect_report(
    tmp_path, sample_printing
) -> None:
    dataset: ScannerDataset = ScannerTransformer().transform([sample_printing])
    exporter = ScannerDatabaseExporter()
    output_path = tmp_path / "mtg_cards.sqlite"

    exporter.export(output_path, dataset)

    connection = sqlite3.connect(output_path)
    try:
        tables = {
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
        }
    finally:
        connection.close()

    assert {"cards", "card_localizations", "card_aliases"} <= tables

    report = exporter.inspect(output_path)
    assert report["cards"] == 1
    assert report["card_localizations"] == 3
    assert report["card_aliases"] >= 3


def test_exporter_sync_copies_database(tmp_path, sample_printing) -> None:
    dataset = ScannerTransformer().transform([sample_printing])
    exporter = ScannerDatabaseExporter()
    source_path = tmp_path / "generated.sqlite"
    destination_path = tmp_path / "assets" / "database" / "mtg_cards.sqlite"

    exporter.export(source_path, dataset)
    exporter.sync_to_app_assets(source_path, destination_path)

    assert destination_path.exists()
    assert destination_path.read_bytes() == source_path.read_bytes()
