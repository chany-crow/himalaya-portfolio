# Himalaya product portfolio

A nineteen-page A4 portrait portfolio covering the Himalaya Brightening Vitamin C, Dark Spot Clearing Turmeric, Natural Glow Face Cream, and Face Wash ranges.

## Files

- `output/Himalaya-Face-Wash-Portfolio-A4.pdf`: nine additional face washes, appended as pages 11–19.
- `output/face-washes/`: product data, generation prompts, scenes, previews, and build script.

- `output/Himalaya-Face-Cream-Portfolio-A4.pdf`: Rose and Kesar Face Cream pages, with both 25 g and 50 g prices.
- `output/face-creams/`: source details, scenes, prompts, page previews, and typesetting.
- `output/combine.swift`: combines all three ranges into the main portfolio.

- `output/Himalaya-Product-Portfolio-A4.pdf`: combined nineteen-page portfolio.
- `output/Himalaya-Turmeric-Portfolio-A4.pdf`: five turmeric pages with prices and sizes from the supplied detailer.
- `output/turmeric/`: product data, generated scenes, prompts, previews, and reproducible Swift typesetting.

- `assets/products/`: supplied product photography.
- `output/01-vitamin-c-cream.png`, `output/02-vitamin-c-serum.png`, `output/03-vitamin-c-face-wash.png`: unchanged first-design artwork.
- `output/Himalaya-Vitamin-C-Portfolio-A4.pdf`: current A4 portfolio with the user's PURE-reference text placement.
- `output/build_pdf.py`: PDF assembly wrapper; requires Python 3 and macOS Swift.
- `output/text-layout/build.swift`: vector typography positioned by measured reference-page coordinates.
- `output/text-layout/scenes/`: first-design artwork cleaned for typesetting, with carton placement adjusted where necessary.
- `output/text-layout/previews/`: rendered previews of the current pages.
- `output/text-layout/Original-Approved-Portfolio.pdf`: preserved first-design PDF.
- `output/text-layout/placement-reference.md`: reference text coordinates and design constraints.
- `output/generation-prompts.txt`: image generation prompts.

The cream page includes LKR 1,200 / 50ml from the original design reference. Serum and face wash prices are not included.

## Preview locally

From this directory:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Open http://localhost:8000/output/Himalaya-Product-Portfolio-A4.pdf.

## Rebuild the PDF

```sh
python3 output/build_pdf.py
```

To rebuild only the turmeric range and combined portfolio:

```sh
swift -module-cache-path /tmp/himalaya-swift-cache output/turmeric/build.swift
swift -module-cache-path /tmp/himalaya-swift-cache output/combine.swift
```
