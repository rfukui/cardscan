# SPDX-License-Identifier: GPL-3.0-or-later

from mtg_data_extractor.normalize import ascii_fold, normalize_text


def test_ascii_fold() -> None:
    assert ascii_fold("Éowyn, Señora") == "Eowyn, Senora"


def test_normalize_text() -> None:
    assert normalize_text("  Swords-to-Plowshares! ") == "swords to plowshares"
