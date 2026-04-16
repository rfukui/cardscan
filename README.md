# MTG Card Scanner Monorepo

This repository contains two clearly separated parts within the same project:

- `app/mtg_card_scanner`: an offline Flutter app for scanning Magic: The Gathering cards.
- `tools/mtg_data_extractor`: a Python tool that generates the SQLite database consumed by the app.

## Structure

```text
repo-root/
  app/mtg_card_scanner/
  tools/mtg_data_extractor/
  data/raw/
  data/generated/
  docs/
```

## Data Flow

1. Place the raw MTGJSON file in `data/raw/`.
   The repository currently expects: `data/raw/AllPrintings.sqlite.xz`.
2. Generate the final scanner database:

```bash
cd tools/mtg_data_extractor
python -m mtg_data_extractor.cli build
```

3. Sync the generated database into the Flutter app assets:

```bash
cd tools/mtg_data_extractor
python -m mtg_data_extractor.cli sync
```

## Important Paths

- Raw source database: `data/raw/AllPrintings.sqlite` or `data/raw/AllPrintings.sqlite.xz`
- Generated scanner database: `data/generated/mtg_cards.sqlite`
- Flutter app asset database: `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

## Documentation

- Data pipeline: [docs/data-pipeline.md](docs/data-pipeline.md)
- Python extractor: [tools/mtg_data_extractor/README.md](tools/mtg_data_extractor/README.md)
- Contribution guidelines: [CONTRIBUTING.md](CONTRIBUTING.md)

## Repository Tooling

Root-level repository tooling is managed with npm.

Install it once to enable `commitlint` and the Git hook setup:

```bash
npm install
```

## License

This repository is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
