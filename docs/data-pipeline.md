# Data Pipeline

This repository ships an offline scanner, so the card catalog must be prepared ahead of time and bundled into the Flutter app as a SQLite asset.

The pipeline is intentionally split from the app:

- Python builds the database
- Flutter only reads the finished database

## Source File

The extractor expects a local MTGJSON SQLite export:

- `data/raw/AllPrintings.sqlite`
- or `data/raw/AllPrintings.sqlite.xz`

Recommended download source:

- `https://mtgjson.com/api/v5/AllPrintings.sqlite.xz`

Expected local path:

- `data/raw/AllPrintings.sqlite.xz`

## Extractor Responsibilities

`tools/mtg_data_extractor` is responsible for:

- reading the MTGJSON SQLite source
- loading printings and foreign-language rows
- normalizing search text
- filtering out objects that should not pollute the main scanner flow
- generating the final scanner schema
- exporting the final SQLite database
- syncing that database into Flutter assets when requested

The Flutter app is not responsible for any of those build-time steps.

## Output Files

Intermediate generated artifact:

- `data/generated/mtg_cards.sqlite`

Runtime asset consumed by Flutter:

- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

These SQLite files are generated locally and are not committed to the repository.

## Build and Sync Flow

From the repository root:

```bash
cd tools/mtg_data_extractor
python3 -m mtg_data_extractor.cli build
python3 -m mtg_data_extractor.cli sync
```

Or in a single step:

```bash
cd tools/mtg_data_extractor
python3 -m mtg_data_extractor.cli build --sync-to-app
```

## Output Schema

The generated database contains:

### `cards`

Primary printing rows used by the scanner UI and result screens.

Notable fields include:

- UUID
- English name
- normalized English name
- set code and set name
- collector number
- language
- mana cost
- type line
- oracle text
- rarity

### `card_localizations`

Localized card text by language, keyed to the printing UUID.

This is the main bridge between foreign-language OCR results and the canonical printing data.

### `card_aliases`

Additional aliases derived from names, face names, ASCII names, and foreign-language rows.

These aliases improve search resilience when OCR is noisy or when multiple printed forms of a name exist.

## Multilingual Strategy

The pipeline preserves:

- one primary row per printing in `cards`
- language-specific localized rows in `card_localizations`
- search aliases in `card_aliases`

This enables the app to search by:

- canonical English names
- localized names from the source data
- alias values useful for OCR matching

The normalization layer preserves non-Latin scripts needed by the scanner goal, including Japanese, Chinese, Korean, and Cyrillic data when they exist in MTGJSON.

## OCR and Search Implications

At runtime the app:

1. runs OCR on a captured image
2. normalizes OCR candidate text
3. searches `cards`, `card_localizations`, and `card_aliases`
4. scores and ranks local candidates

That means the pipeline directly affects scanner quality. If a name or alias is missing here, Flutter cannot recover it later without a new generated database.

## Failure Modes to Expect

- If the MTGJSON archive is missing, the extractor cannot build the database.
- If `build` is not followed by `sync`, the app asset will remain missing or stale.
- If the Flutter asset is missing, the app now reports an explicit initialization error telling contributors to run the extractor build and sync steps.
