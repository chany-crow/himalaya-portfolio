"""Build the A4 portfolio using the approved reference's text placement."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
subprocess.run([
    "swift", "-module-cache-path",
    str(Path(tempfile.gettempdir()) / "himalaya-swift-cache"),
    str(root / "text-layout" / "build.swift"),
], check=True)
