# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import re
import unicodedata

_SPACE_RE = re.compile(r"\s+")
_LATIN_SPECIAL_FOLDS = {
    "ß": "ss",
    "æ": "ae",
    "œ": "oe",
    "ø": "o",
    "ł": "l",
    "đ": "d",
    "ð": "d",
    "þ": "th",
}


def ascii_fold(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKD", value)
    return normalized.encode("ascii", "ignore").decode("ascii")


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    lowered = unicodedata.normalize("NFKC", value).lower()
    output: list[str] = []

    for char in lowered:
        folded = _LATIN_SPECIAL_FOLDS.get(char)
        if folded is not None:
            output.append(folded)
            continue

        latin_folded = _fold_latin_char(char)
        if latin_folded is not None:
            output.append(latin_folded)
            continue

        if char.isalnum():
            output.append(char)
        else:
            output.append(" ")

    normalized = "".join(output)
    normalized = _SPACE_RE.sub(" ", normalized)
    return normalized.strip()


def _fold_latin_char(char: str) -> str | None:
    decomposed = unicodedata.normalize("NFKD", char)
    stripped = "".join(
        component for component in decomposed if not unicodedata.combining(component)
    )
    if not stripped:
        return None
    if all(component.isascii() and component.isalnum() for component in stripped):
        return stripped
    return None
