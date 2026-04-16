# MTG Data Extractor

Python tool responsible for transforming the MTGJSON database into the final SQLite database used by the Flutter app.

## Responsibility

This tool is part of the repository's build/data pipeline.

It is not part of the mobile UI and is not used by the app at runtime.

## Expected Input

- `data/raw/AllPrintings.sqlite`
- `data/raw/AllPrintings.sqlite.xz`

The compressed archive is not committed to the repository.

Download it from:

- `https://mtgjson.com/api/v5/AllPrintings.sqlite.xz`

Then place it at:

- `data/raw/AllPrintings.sqlite.xz`

## Output

- `data/generated/mtg_cards.sqlite`

Optionally, the generated database is synced to:

- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

## Commands

Download the source archive:

```bash
curl -L https://mtgjson.com/api/v5/AllPrintings.sqlite.xz -o ../../data/raw/AllPrintings.sqlite.xz
```

Build using default paths:

```bash
python -m mtg_data_extractor.cli build
```

Build using explicit paths:

```bash
python -m mtg_data_extractor.cli build \
  --input ../../data/raw/AllPrintings.sqlite \
  --output ../../data/generated/mtg_cards.sqlite
```

Sync to the app:

```bash
python -m mtg_data_extractor.cli sync
```

Inspect the final database:

```bash
python -m mtg_data_extractor.cli inspect
```

## Internal Structure

- `config.py`: default paths and configuration
- `normalize.py`: text normalization
- `sqlite_reader.py`: MTGJSON SQLite reading
- `transformer.py`: transformation into the scanner schema
- `exporter.py`: final SQLite creation
- `models.py`: internal dataclasses
- `cli.py`: command-line interface

## Note

The extractor accepts either an already decompressed `.sqlite` file or a `.sqlite.xz` file. When given `.xz`, it temporarily decompresses it for reading.
