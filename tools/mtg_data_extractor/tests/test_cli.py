# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import sqlite3

from mtg_data_extractor.cli import main

from .helpers import write_sample_mtgjson_sqlite


def test_cli_build_and_sync_generates_expected_database(tmp_path) -> None:
    input_path = tmp_path / "AllPrintings.sqlite"
    output_path = tmp_path / "generated" / "mtg_cards.sqlite"
    asset_path = tmp_path / "app" / "assets" / "database" / "mtg_cards.sqlite"
    write_sample_mtgjson_sqlite(input_path)

    build_exit_code = main(
        [
            "build",
            "--input",
            str(input_path),
            "--output",
            str(output_path),
            "--sync-to-app",
            "--app-assets",
            str(asset_path),
        ]
    )

    assert build_exit_code == 0
    assert output_path.exists()
    assert asset_path.exists()

    connection = sqlite3.connect(output_path)
    try:
        row = connection.execute(
            "SELECT COUNT(*) FROM card_localizations WHERE normalized_name = '稲妻'"
        ).fetchone()
    finally:
        connection.close()

    assert row is not None
    assert row[0] == 1


def test_cli_inspect_returns_success_for_generated_database(tmp_path, capsys) -> None:
    input_path = tmp_path / "AllPrintings.sqlite"
    output_path = tmp_path / "generated" / "mtg_cards.sqlite"
    write_sample_mtgjson_sqlite(input_path)

    assert (
        main(
            [
                "build",
                "--input",
                str(input_path),
                "--output",
                str(output_path),
            ]
        )
        == 0
    )

    inspect_exit_code = main(["inspect", "--input", str(output_path)])
    captured = capsys.readouterr()

    assert inspect_exit_code == 0
    assert "cards:" in captured.out
    assert "languages:" in captured.out


def test_cli_returns_error_for_missing_input(tmp_path) -> None:
    missing_input = tmp_path / "missing.sqlite"
    output_path = tmp_path / "generated" / "mtg_cards.sqlite"

    exit_code = main(
        [
            "build",
            "--input",
            str(missing_input),
            "--output",
            str(output_path),
        ]
    )

    assert exit_code == 1
