# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

from mtg_data_extractor.models import SourcePrinting
from mtg_data_extractor.transformer import ScannerTransformer


def test_transformer_generates_multilingual_rows_and_aliases(
    sample_printing: SourcePrinting,
) -> None:
    dataset = ScannerTransformer().transform([sample_printing])

    assert len(dataset.cards) == 1
    assert dataset.cards[0].normalized_name_en == "lightning bolt"

    localization_pairs = {
        (row.language_code, row.normalized_name) for row in dataset.localizations
    }
    assert ("English", "lightning bolt") in localization_pairs
    assert ("Japanese", "稲妻") in localization_pairs
    assert ("Portuguese (Brazil)", "raio") in localization_pairs

    aliases = {(row.language_code, row.normalized_alias) for row in dataset.aliases}
    assert ("English", "lightning bolt") in aliases
    assert ("Japanese", "稲妻") in aliases
    assert ("Portuguese (Brazil)", "raio") in aliases


def test_transformer_deduplicates_duplicate_localizations_and_aliases(
    sample_printing: SourcePrinting,
) -> None:
    dataset = ScannerTransformer().transform([sample_printing])

    japanese_localizations = [
        row for row in dataset.localizations if row.language_code == "Japanese"
    ]
    japanese_aliases = [row for row in dataset.aliases if row.language_code == "Japanese"]

    assert len(japanese_localizations) == 1
    assert len(japanese_aliases) == 1


def test_transformer_filters_non_scannable_layouts() -> None:
    token_printing = SourcePrinting(
        uuid="token-1",
        name_en="Goblin",
        set_code="TST",
        set_name="Token Set",
        collector_number="1",
        language="English",
        type_line_en="Token Creature — Goblin",
        layout="token",
    )

    dataset = ScannerTransformer().transform([token_printing])

    assert dataset.cards == []
    assert dataset.localizations == []
    assert dataset.aliases == []


def test_transformer_skips_printings_without_primary_name() -> None:
    missing_name = SourcePrinting(
        uuid="blank-1",
        name_en="   ",
        set_code="TST",
        set_name="Test Set",
        collector_number="2",
        language="English",
    )

    dataset = ScannerTransformer().transform([missing_name])

    assert dataset.cards == []
