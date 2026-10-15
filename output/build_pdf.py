"""Build the A4 portfolio using the approved reference's text placement."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
for script in ["text-layout/build.swift", "turmeric/build.swift", "face-creams/build.swift", "face-washes/build.swift", "lip-balm/build.swift", "nourishing-cream/build.swift", "neem-pack/build.swift", "neem-serum/build.swift", "combine.swift"]:
    subprocess.run([
        "swift", "-module-cache-path",
        str(Path(tempfile.gettempdir()) / "himalaya-swift-cache"),
        str(root / script),
    ], check=True)
