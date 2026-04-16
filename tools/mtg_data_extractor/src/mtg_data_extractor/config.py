# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


@dataclass(frozen=True)
class PathConfig:
    repo_root: Path
    raw_data_dir: Path
    generated_data_dir: Path
    app_assets_database: Path

    @property
    def default_input(self) -> Path:
        sqlite_path = self.raw_data_dir / "AllPrintings.sqlite"
        compressed_path = self.raw_data_dir / "AllPrintings.sqlite.xz"
        if sqlite_path.exists():
            return sqlite_path
        return compressed_path

    @property
    def default_output(self) -> Path:
        return self.generated_data_dir / "mtg_cards.sqlite"


def default_paths() -> PathConfig:
    repo_root = _repo_root()
    return PathConfig(
        repo_root=repo_root,
        raw_data_dir=repo_root / "data" / "raw",
        generated_data_dir=repo_root / "data" / "generated",
        app_assets_database=repo_root
        / "app"
        / "mtg_card_scanner"
        / "assets"
        / "database"
        / "mtg_cards.sqlite",
    )
