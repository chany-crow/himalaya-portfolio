# Himalaya product portfolio

A three-page A4 portrait portfolio for the Himalaya Brightening Vitamin C range.

## Files

- `assets/products/`: supplied product photography.
- `output/01-vitamin-c-cream.png`, `output/02-vitamin-c-serum.png`, `output/03-vitamin-c-face-wash.png`: generated page artwork.
- `output/Himalaya-Vitamin-C-Portfolio-A4.pdf`: original artwork fitted to A4 pages without added margins.
- `output/build_pdf.py`: PDF assembly script; requires Python 3 and Pillow.
- `output/generation-prompts.txt`: image generation prompts.

The cream page includes LKR 1,200 / 50ml from the original design reference. Serum and face wash prices are not included.

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
