"""Build the A4 portfolio with supplied fonts, product links and page numbers."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parent
subprocess.run(["node", str(root / "generate-qr.cjs")], check=True)
for script in ["render.swift", "introduction.swift", "combine.swift"]:
    subprocess.run(["swift", "-module-cache-path", str(Path(tempfile.gettempdir()) / "himalaya-swift-cache"), str(root / script)], check=True)
