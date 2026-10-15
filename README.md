# Himalaya product portfolio

An eight-page A4 portrait portfolio covering the Himalaya Brightening Vitamin C and Dark Spot Clearing Turmeric ranges.

## Files

- `output/Himalaya-Product-Portfolio-A4.pdf`: combined eight-page portfolio.
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
```
