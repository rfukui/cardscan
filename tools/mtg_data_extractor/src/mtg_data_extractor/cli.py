# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from .config import default_paths
from .exporter import ScannerDatabaseExporter
from .sqlite_reader import MtgJsonSqliteReader
from .transformer import ScannerTransformer

logger = logging.getLogger(__name__)


def build_parser() -> argparse.ArgumentParser:
    defaults = default_paths()

    parser = argparse.ArgumentParser(description="MTG scanner data pipeline")
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Logging verbosity.",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build", help="Build scanner SQLite from MTGJSON.")
    build_parser.add_argument(
        "--input",
        type=Path,
        default=defaults.default_input,
        help="Path to AllPrintings.sqlite or AllPrintings.sqlite.xz.",
    )
    build_parser.add_argument(
        "--output",
        type=Path,
        default=defaults.default_output,
        help="Path to generated scanner SQLite.",
    )
    build_parser.add_argument(
        "--include-non-scannables",
        action="store_true",
        help="Include tokens, emblems and other non-primary scanner objects.",
    )
    build_parser.add_argument(
        "--sync-to-app",
        action="store_true",
        help="Copy the generated database to the Flutter app assets after build.",
    )
    build_parser.add_argument(
        "--app-assets",
        type=Path,
        default=defaults.app_assets_database,
        help="Destination app asset database path.",
    )

    sync_parser = subparsers.add_parser("sync", help="Copy generated SQLite to app assets.")
    sync_parser.add_argument(
        "--input",
        type=Path,
        default=defaults.default_output,
        help="Generated scanner SQLite path.",
    )
    sync_parser.add_argument(
        "--app-assets",
        type=Path,
        default=defaults.app_assets_database,
        help="Destination app asset database path.",
    )

    inspect_parser = subparsers.add_parser("inspect", help="Inspect generated scanner SQLite.")
    inspect_parser.add_argument(
        "--input",
        type=Path,
        default=defaults.default_output,
        help="Generated scanner SQLite path.",
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(levelname)s %(name)s: %(message)s",
    )

    try:
        if args.command == "build":
            return _run_build(args)
        if args.command == "sync":
            return _run_sync(args)
        if args.command == "inspect":
            return _run_inspect(args)
    except Exception as exc:  # pragma: no cover - CLI boundary
        logger.error("%s", exc)
        return 1

    parser.print_help()
    return 1


def _run_build(args: argparse.Namespace) -> int:
    reader = MtgJsonSqliteReader(args.input)
    transformer = ScannerTransformer(
        include_non_scannables=args.include_non_scannables,
    )
    exporter = ScannerDatabaseExporter()

    printings = reader.load_printings()
    dataset = transformer.transform(printings)
    exporter.export(args.output, dataset)

    if args.sync_to_app:
        exporter.sync_to_app_assets(args.output, args.app_assets)

    logger.info(
        "Build complete: %s cards, %s localizations, %s aliases",
        len(dataset.cards),
        len(dataset.localizations),
        len(dataset.aliases),
    )
    return 0


def _run_sync(args: argparse.Namespace) -> int:
    exporter = ScannerDatabaseExporter()
    exporter.sync_to_app_assets(args.input, args.app_assets)
    return 0


def _run_inspect(args: argparse.Namespace) -> int:
    exporter = ScannerDatabaseExporter()
    report = exporter.inspect(args.input)

    print("cards:", report["cards"])
    print("card_localizations:", report["card_localizations"])
    print("card_aliases:", report["card_aliases"])
    print("languages:")
    for language, count in report["languages"]:
        print(f"  - {language}: {count}")
    print("top_sets:")
    for set_code, count in report["top_sets"]:
        print(f"  - {set_code}: {count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
