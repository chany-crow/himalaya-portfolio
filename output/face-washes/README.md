# Face Wash range

Nine A4 pages added after the existing ten pages: Neem, Kesar, Aloe Vera, Lemon, Clear Complexion, Apricot, Orange, Rose, and Charcoal.

The supplied product photos are retained in `assets/products/Face Wash Range/`. Product names, ingredient visuals and conservative benefit copy follow those packages. This includes the supplied Moisturizing Aloe Vera name and the older Orange pack. The old detailer is used only for pack sizes and prices; its Aloe Vera entry is titled Hydrating Aloe Vera. Clear Complexion imagery uses licorice and saffron from the supplied label.

Prices from Product Detailer v3 (1).pdf, with page numbers in products.json:
- Neem, Kesar, Aloe Vera, Lemon, Clear Complexion: 50 ml / LKR 545 and 100 ml / LKR 885.
- Apricot, Orange: 100 ml / LKR 885.
- Rose, Charcoal: 50 ml / LKR 545.

Scenes use built-in image generation with prompts saved in image-prompts.txt. Each uses a distinct ingredient arrangement and palette in the approved sunbeam, botanical bokeh, wet reflection style. Vector text follows the PURE-reference coordinates.

Build with `swift -module-cache-path /tmp/himalaya-swift-cache output/face-washes/build.swift`, then `swift -module-cache-path /tmp/himalaya-swift-cache output/combine.swift`. To rebuild every range: `python3 output/build_pdf.py`.
