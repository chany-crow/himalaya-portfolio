# Natural Glow Face Creams

Two A4 pages appended as pages 9 and 10 of the main portfolio: Rose, then Kesar.

Source photos are in `assets/products/Face Cream Range/`. Both products have 25 g / LKR 395 and 50 g / LKR 645 variants, taken only from pages 20 and 19 respectively of the supplied Product Detailer v3 (1).pdf. Benefit copy follows the product packaging. Product prices printed in older photographs are not used.

Scenes were generated with the built-in image-generation tool. Prompts are saved alongside this file. Typography uses the approved PURE-reference page coordinates. Headlines are clipped behind the tube silhouettes.

Build these pages with `swift -module-cache-path /tmp/himalaya-swift-cache output/face-creams/build.swift`, then assemble the full portfolio with `swift -module-cache-path /tmp/himalaya-swift-cache output/combine.swift`. The main `python3 output/build_pdf.py` command rebuilds all ranges and combines them.
