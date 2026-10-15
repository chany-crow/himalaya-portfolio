# Himalaya product portfolio

A three-page A4 portrait portfolio for the Himalaya Brightening Vitamin C range.

## Files

- `assets/products/`: supplied product photography.
- `output/01-vitamin-c-cream.png`, `output/02-vitamin-c-serum.png`, `output/03-vitamin-c-face-wash.png`: original design drafts, retained for reference.
- `output/scenes/`: distinct product scenes with no editorial lettering.
- `output/previews/`: current rendered portfolio pages.
- `output/Himalaya-Vitamin-C-Portfolio-A4.pdf`: current A4 portfolio, with full-bleed images and vector text inset 12 mm on all four sides.
- `output/build_pdf.py`: convenience wrapper for the Swift PDF builder (macOS with Swift required).
- `output/build_portfolio.swift`: image placement, editable text layout, PDF export, preview rendering, and text-bound validation.
- `output/prices.json`: prices and pack sizes from the supplied detailer; unknown values are omitted from the design.
- `output/layout-audit.json`: measured glyph bounds, checked against the text safe area during generation.
- `output/portfolio-requirements.md`: current design requirements.
- `output/generation-prompts.txt`: image generation prompts.

The cream page includes LKR 1,200 / 50 ml and the serum includes LKR 965 / 15 ml. The face wash price and size are missing from the supplied detailer, so they are omitted.

## Preview locally

From this directory:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Open http://localhost:8000/output/Himalaya-Vitamin-C-Portfolio-A4.pdf.

## Rebuild the PDF

```sh
python3 output/build_pdf.py
```
