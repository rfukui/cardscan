# SPDX-License-Identifier: GPL-3.0-or-later

from pathlib import Path
from pkgutil import extend_path

__path__ = extend_path(__path__, __name__)

_src_package_dir = Path(__file__).resolve().parent.parent / "src" / "mtg_data_extractor"
if _src_package_dir.exists():
    __path__.append(str(_src_package_dir))

__all__ = ["__version__"]
__version__ = "0.1.0"
