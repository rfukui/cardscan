# Data Pipeline

## Goal

The data pipeline transforms the MTGJSON database into a final SQLite database optimized for the offline scanner.

The Flutter app does not run Python at runtime. It only consumes the prebuilt database bundled at `assets/database/mtg_cards.sqlite`.

## Source

Primary input:

- `data/raw/AllPrintings.sqlite`
- `data/raw/AllPrintings.sqlite.xz`

The compressed archive is not stored in the repository.

Download it from:

- `https://mtgjson.com/api/v5/AllPrintings.sqlite.xz`

Then place it at:

- `data/raw/AllPrintings.sqlite.xz`

## Output

Generated database:

- `data/generated/mtg_cards.sqlite`

Database synced to the app:

- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

## Steps

1. Read the MTGJSON SQLite database.
2. Extract printings.
3. Extract multilingual localizations.
4. Generate aliases useful for OCR and matching.
5. Filter out objects that should not be part of the main scanner flow.
6. Export the final database with search indexes.
7. Copy the final database into the app assets.

## Final Schema

Main tables:

- `cards`
- `card_localizations`
- `card_aliases`

The app uses `cards` as its primary source and can query `card_localizations` and `card_aliases` for multilingual matching.

## Commands

Download the source archive:

```bash
curl -L https://mtgjson.com/api/v5/AllPrintings.sqlite.xz -o data/raw/AllPrintings.sqlite.xz
```

Build:

```bash
cd tools/mtg_data_extractor
python -m mtg_data_extractor.cli build
```

Sync:

```bash
cd tools/mtg_data_extractor
python -m mtg_data_extractor.cli sync
```

Inspect:

```bash
cd tools/mtg_data_extractor
python -m mtg_data_extractor.cli inspect
```
