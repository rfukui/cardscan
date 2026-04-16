# MTG Card Scanner Monorepo

This repository contains an offline Magic: The Gathering scanner and the internal data pipeline that prepares its local card database.

The project is intentionally split into two parts:

- `app/mtg_card_scanner`
  Flutter mobile app for scanning cards, matching them locally, and storing scan history.
- `tools/mtg_data_extractor`
  Python tool that reads MTGJSON data and generates the SQLite database used by the app.

Additional repository folders:

- `data/raw`
  Local MTGJSON source files.
- `data/generated`
  Locally generated scanner database output.
- `docs`
  Project documentation, including the data pipeline description.

## What the Repository Does

The app works fully on-device:

- opens the camera
- captures a card image
- runs OCR locally
- looks up candidates in a local SQLite catalog
- shows the best result or a manual candidate selection screen
- stores scan history locally

The app does not depend on Python at runtime. Python is only used to build the SQLite catalog during development and data refresh workflows.

## Quick Start

### 1. Download the MTGJSON source archive

The repository does not commit the raw MTGJSON SQLite file.

```bash
curl -L https://mtgjson.com/api/v5/AllPrintings.sqlite.xz -o data/raw/AllPrintings.sqlite.xz
```

### 2. Build and sync the local SQLite database

```bash
cd tools/mtg_data_extractor
python3 -m mtg_data_extractor.cli build
python3 -m mtg_data_extractor.cli sync
```

This produces:

- `data/generated/mtg_cards.sqlite`
- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

Both files are generated locally and are not committed.

### 3. Run the Flutter app

```bash
cd ../../app/mtg_card_scanner
flutter pub get
flutter run
```

If the SQLite asset is missing, the app now reports a clear initialization error telling you to run the extractor build and sync steps.

## Important Paths

- Raw MTGJSON archive:
  `data/raw/AllPrintings.sqlite.xz`
- Generated scanner database:
  `data/generated/mtg_cards.sqlite`
- Flutter asset database:
  `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

## What Is Generated vs. What Is Committed

Committed:

- Flutter app source
- extractor source
- repository docs
- placeholder directories such as `.gitkeep`

Generated locally and ignored:

- `data/raw/AllPrintings.sqlite.xz`
- `data/generated/mtg_cards.sqlite`
- `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

That means a new clone is expected to run the data pipeline before the scanner can identify cards.

## How Collaborators Should Work

1. Generate or refresh the database when card data changes.
2. Sync the generated SQLite file into the Flutter app assets.
3. Run the app locally and validate the scanner flow.
4. Keep app work and extractor work separated by directory and responsibility.
5. Follow [CONTRIBUTING.md](CONTRIBUTING.md), including Conventional Commits.

## Additional Documentation

- App-specific usage:
  [app/mtg_card_scanner/README.md](app/mtg_card_scanner/README.md)
- Extractor usage:
  [tools/mtg_data_extractor/README.md](tools/mtg_data_extractor/README.md)
- Data pipeline details:
  [docs/data-pipeline.md](docs/data-pipeline.md)

## Repository Tooling

Root-level Git tooling uses `npm` for `commitlint` and hook setup:

```bash
npm install
```

## License

This repository is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
