# SPDX-License-Identifier: GPL-3.0-or-later

from mtg_data_extractor.normalize import ascii_fold, normalize_text


def test_ascii_fold() -> None:
    assert ascii_fold("Éowyn, Señora") == "Eowyn, Senora"


def test_normalize_text() -> None:
    assert normalize_text("  Swords-to-Plowshares! ") == "swords to plowshares"


def test_normalize_text_preserves_japanese() -> None:
    assert normalize_text("弱者選別") == "弱者選別"


def test_normalize_text_preserves_cyrillic() -> None:
    assert normalize_text("Ёж, Ночь") == "ёж ночь"


def test_normalize_text_folds_latin_diacritics() -> None:
    assert normalize_text("Æther Gust") == "aether gust"
