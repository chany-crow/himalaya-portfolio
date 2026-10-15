# Himalaya product portfolio

A three-page A4 portrait portfolio for the Himalaya Brightening Vitamin C range.

## Files

- `assets/products/`: supplied product photography.
- `output/01-vitamin-c-cream.png`, `output/02-vitamin-c-serum.png`, `output/03-vitamin-c-face-wash.png`: generated page artwork.
- `output/Himalaya-Vitamin-C-Portfolio-A4.pdf`: assembled portfolio with equal 10 mm margins and confirmed serum pricing.
- `output/build_pdf.py`: PDF assembly script; requires Python 3 and Pillow.
- `output/confirmed-prices.csv`: prices and sizes extracted from the supplied detailer.
- `output/portfolio-requirements.md`: layout and background requirements.
- `output/generation-prompts.txt`: image generation prompts.

The serum price is added by the PDF assembly script; the standalone serum PNG does not include it. Vitamin C face wash price and size are pending; the supplied detailer lists TBC.

## Preview locally

From this directory:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Open http://localhost:8000/output/Himalaya-Vitamin-C-Portfolio-A4.pdf.

## Rebuild the PDF

```sh
python3 -m pip install Pillow
python3 output/build_pdf.py
```

Use the old detailer only as a source of prices and pack sizes. Future products should have distinct backgrounds suited to their ingredients while preserving the portfolio style.
