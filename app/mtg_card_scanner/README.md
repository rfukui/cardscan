# MTG Card Scanner App

`app/mtg_card_scanner` contains the Flutter mobile client for this monorepo.

The app is an offline Magic: The Gathering card scanner. It uses the device
camera, runs OCR on-device, matches recognized text against a local SQLite
catalog, and stores scan history locally. It does not call a backend at
runtime.

## Runtime Dependencies

The app depends on a generated SQLite asset at:

- `assets/database/mtg_cards.sqlite`

That file is produced by the Python extractor in `tools/mtg_data_extractor` and is intentionally not committed. A clean clone must generate and sync the database before the scanner can identify cards.

## High-Level Scanner Flow

1. Open the rear camera.
2. Capture a frame manually.
3. Run local OCR on the captured image.
4. Normalize OCR text and search the bundled SQLite catalog.
5. Score candidate printings locally.
6. Show the best result or ask the user to pick from ambiguous candidates.
7. Save the final scan to local history.

## Current Limitations

- Capture is still manual. Automatic card detection and auto-capture are not implemented yet.
- Native computer vision hooks exist, but perspective correction and region extraction are still stubbed.
- OCR quality depends on card layout, framing, glare, and the mobile ML Kit recognizers available on the target platform.
- Matching works fully offline, but unusual layouts can still require manual candidate selection.

## Run the App Locally

From the repository root:

```bash
cd tools/mtg_data_extractor
python3 -m mtg_data_extractor.cli build
python3 -m mtg_data_extractor.cli sync

cd ../../app/mtg_card_scanner
flutter pub get
flutter run
```

If the database asset is missing, the app now shows an explicit initialization error telling you to run the extractor build and sync steps.

## Regenerate the Database

The app does not generate its own database. Use the extractor whenever the card catalog needs to be refreshed.

```bash
cd tools/mtg_data_extractor
python3 -m mtg_data_extractor.cli build
python3 -m mtg_data_extractor.cli sync
```

Useful paths:

- Raw MTGJSON archive: `data/raw/AllPrintings.sqlite.xz`
- Generated database: `data/generated/mtg_cards.sqlite`
- Synced Flutter asset: `app/mtg_card_scanner/assets/database/mtg_cards.sqlite`

## Project Boundaries

The Flutter app is responsible for:

- camera preview and capture
- OCR orchestration
- local matching and result flow
- SQLite reads at runtime
- local scan history

The app does not:

- run Python at runtime
- download card data
- call external APIs to identify cards

Use the repository root [README](../../README.md) for monorepo onboarding and
[`docs/data-pipeline.md`](../../docs/data-pipeline.md) for the extractor-to-app
data flow.
