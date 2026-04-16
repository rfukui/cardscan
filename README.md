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

1. Download the raw MTGJSON SQLite archive into `data/raw/`.
   Recommended source:
   `https://mtgjson.com/api/v5/AllPrintings.sqlite.xz`
   Expected path:
   `data/raw/AllPrintings.sqlite.xz`
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

## Downloading MTGJSON

The raw MTGJSON SQLite archive is not committed to this repository.

Download it manually:

```bash
curl -L https://mtgjson.com/api/v5/AllPrintings.sqlite.xz -o data/raw/AllPrintings.sqlite.xz
```

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

## Android Setup

To run the Flutter app locally on Android, you need the Android SDK.

### Option 1: Android Studio

This is the recommended setup for most contributors.

1. Download Android Studio from the official Android Developers page:
   `https://developer.android.com/studio`
2. Install Android Studio.
3. Open Android Studio and install:
   `Android SDK`
   `Android SDK Platform-Tools`
   `Android SDK Command-line Tools (latest)`
4. Run:

```bash
flutter doctor
flutter doctor --android-licenses
```

### Option 2: No Android Studio

If you do not want to install Android Studio, you can use the Android command-line tools only.

1. Download the official Android command-line tools:
   `https://developer.android.com/tools`
2. Create an SDK directory, for example:

```bash
mkdir -p ~/Android/Sdk
```

3. Extract the downloaded archive so that `sdkmanager` ends up at:
   `$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager`
4. Add these environment variables to your shell profile:

```bash
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
```

5. Install the minimum Android SDK components:

```bash
sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" "cmdline-tools;latest"
flutter doctor --android-licenses
flutter doctor
```

### Running the App

Once Flutter and the Android toolchain are ready:

```bash
cd app/mtg_card_scanner
flutter pub get
flutter devices
flutter run
```

### Running on a Physical Android Device

1. Enable Developer Options on your Android phone.
2. Enable `USB debugging`.
3. Connect the device over USB.
4. Verify that Flutter can see it:

```bash
flutter devices
```

5. Run the app:

```bash
cd app/mtg_card_scanner
flutter run
```

If the device does not appear, verify that `adb` is available and that the phone accepted the debugging authorization prompt.

### Running on an Android Emulator

If you installed Android Studio, the easiest way is to create and manage an emulator from the Android Studio Device Manager.

If you are using command-line tools only, you also need:

- `emulator`
- at least one Android system image
- `avdmanager`

Example setup:

```bash
sdkmanager --install "emulator" "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n pixel-test -k "system-images;android-34;google_apis;x86_64"
emulator -avd pixel-test
```

Then, in another terminal:

```bash
cd app/mtg_card_scanner
flutter devices
flutter run
```

## License

This repository is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
