"""Build the portfolio with full-bleed scenes and precisely inset vector text."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
subprocess.run([
    "swift", "-module-cache-path",
    str(Path(tempfile.gettempdir()) / "himalaya-swift-cache"),
    str(root / "build_portfolio.swift"),
], check=True)
