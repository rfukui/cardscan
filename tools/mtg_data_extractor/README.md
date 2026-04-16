# MTG Data Extractor

`tools/mtg_data_extractor` is the internal data pipeline for this repository.

It reads MTGJSON SQLite data, transforms it into a scanner-oriented schema, and produces the SQLite file consumed by the Flutter app. The extractor is a build-time tool only. The mobile app does not depend on Python at runtime.

## Input

Expected source file:

- `data/raw/AllPrintings.sqlite`
- or `data/raw/AllPrintings.sqlite.xz`

The repository does not commit the raw MTGJSON archive. Download it manually and place it at:

- `data/raw/AllPrintings.sqlite.xz`

Example:

```bash
curl -L https://mtgjson.com/api/v5/AllPrintings.sqlite.xz -o data/raw/AllPrintings.sqlite.xz
```

## Output

Generated database:

- `data/generated/mtg_cards.sqlite`

Synced Flutter asset:

- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

Neither SQLite file is committed. Contributors are expected to generate them locally.

## Main Commands

Run these commands from `tools/mtg_data_extractor`.

Build the scanner database:

```bash
python3 -m mtg_data_extractor.cli build
```

Build and sync in one step:

```bash
python3 -m mtg_data_extractor.cli build --sync-to-app
```

Sync an already generated database into the Flutter app:

```bash
python3 -m mtg_data_extractor.cli sync
```

Inspect the generated output:

```bash
python3 -m mtg_data_extractor.cli inspect
```

## Build Flow

1. Read `AllPrintings.sqlite` or `AllPrintings.sqlite.xz`.
2. Load card printings and optional foreign-language rows from the MTGJSON schema.
3. Normalize printable names for OCR-friendly search.
4. Generate the final scanner schema.
5. Export the SQLite database to `data/generated/mtg_cards.sqlite`.
6. Optionally copy the generated database into the Flutter app assets.

## Generated Tables

The extractor produces three main tables:

- `cards`
  One row per printing. Holds primary card metadata used by the app.
- `card_localizations`
  Multilingual names and text rows associated with each card UUID.
- `card_aliases`
  Search aliases used to improve OCR and fuzzy matching.

## Why Multilingual Extraction Exists

The scanner is designed to work offline across all printed languages represented in the source data. That requires:

- a primary printing record
- localized names for OCR matching
- alternate aliases that improve lookup quality when OCR is imperfect

Without the multilingual tables, the app would be limited to English name matching and would miss many foreign printings.

## Module Boundaries

- `config.py`
  Repository paths and default CLI locations.
- `normalize.py`
  Text normalization used during export and search preparation.
- `sqlite_reader.py`
  MTGJSON SQLite reading and decompression handling.
- `transformer.py`
  Conversion from MTGJSON rows into scanner rows.
- `exporter.py`
  Final schema creation and SQLite export.
- `models.py`
  Internal dataclasses for the transformation pipeline.
- `cli.py`
  Command-line entry point.

See [`docs/data-pipeline.md`](../../docs/data-pipeline.md) for the full repository-level data flow.
