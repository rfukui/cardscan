# SPDX-License-Identifier: GPL-3.0-or-later

from __future__ import annotations

import re
import unicodedata

_PUNCTUATION_RE = re.compile(r"[^a-z0-9\s]")
_SPACE_RE = re.compile(r"\s+")


def ascii_fold(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKD", value)
    return normalized.encode("ascii", "ignore").decode("ascii")


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    lowered = ascii_fold(value).lower()
    lowered = _PUNCTUATION_RE.sub(" ", lowered)
    lowered = _SPACE_RE.sub(" ", lowered)
    return lowered.strip()
