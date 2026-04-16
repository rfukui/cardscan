import pytest

from mtg_data_extractor.models import SourceLocalization, SourcePrinting


@pytest.fixture
def sample_printing() -> SourcePrinting:
    return SourcePrinting(
        uuid="card-1",
        name_en="Lightning Bolt",
        set_code="M11",
        set_name="Magic 2011",
        collector_number="146",
        language="English",
        mana_cost="{R}",
        type_line_en="Instant",
        oracle_text_en="Lightning Bolt deals 3 damage to any target.",
        rarity="common",
        ascii_name="Lightning Bolt",
        scryfall_id="scryfall-1",
        multiverse_id="123",
        localizations=[
            SourceLocalization(
                language_code="Japanese",
                name="稲妻",
                type_text="インスタント",
                rules_text="稲妻は、クリーチャー1体かプレイヤー1人を対象とする。それに3点のダメージを与える。",
            ),
            SourceLocalization(
                language_code="Japanese",
                name="稲妻",
                type_text="インスタント",
                rules_text="稲妻は、クリーチャー1体かプレイヤー1人を対象とする。それに3点のダメージを与える。",
            ),
            SourceLocalization(
                language_code="Portuguese (Brazil)",
                name="Raio",
                type_text="Mágica Instantânea",
                rules_text="Raio causa 3 pontos de dano a qualquer alvo.",
            ),
        ],
    )
