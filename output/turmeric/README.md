# Dark Spot Clearing Turmeric range

Five A4 pages using the approved portfolio's photographic style and PURE-reference text positions.

- Source product photos: `assets/products/Dark Spot Clearing Turmeric Range/`.
- Price and size source: supplied `Product Detailer v3 (1).pdf`, pages recorded in `products.json`. That PDF is used only for prices and sizes.
- Benefit wording is paraphrased from the supplied product packaging.
- `scenes/`: generated product photography with editorial text excluded.
- `previews/`: rendered page images.
- `build.swift`: uses the same text anchors, typography and full-bleed A4 format as the Vitamin C pages.
- `image-prompts.txt`: built-in image-generation prompts.

Outputs in the parent directory:

- `Himalaya-Turmeric-Portfolio-A4.pdf`: these five pages.
- `Himalaya-Product-Portfolio-A4.pdf`: three Vitamin C pages, five turmeric pages, and two Natural Glow Face Cream pages.

Rebuild this range with `swift -module-cache-path /tmp/himalaya-swift-cache output/turmeric/build.swift` from the project root.

Run `swift -module-cache-path /tmp/himalaya-swift-cache output/combine.swift` afterward to update the combined portfolio.
