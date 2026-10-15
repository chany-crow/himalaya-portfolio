import AppKit
import CoreText
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let W = 210.0 / 25.4 * 72, H = 297.0 / 25.4 * 72
let output = root.deletingLastPathComponent().appendingPathComponent("Himalaya-Face-Cream-Portfolio-A4.pdf")
var media = CGRect(x: 0, y: 0, width: W, height: H)
let ctx = CGContext(output as CFURL, mediaBox: &media, nil)!
var audit: [[String: Any]] = []

func makeLine(_ text: String, _ font: String, _ size: Double, _ tracking: Double, _ color: NSColor) -> CTLine {
    CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
        .font: NSFont(name: font, size: size)!, .kern: tracking, .foregroundColor: color
    ]))
}

@discardableResult
func draw(_ text: String, x: Double, top: Double, font: String = "HelveticaNeue", size: Double,
          tracking: Double = 0, color: NSColor, align: String = "left",
          fitWidth: Double? = nil, fitHeight: Double? = nil, maxWidth: Double? = nil, page: Int) -> CGRect {
    let line = makeLine(text, font, size, tracking, color)
    let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let sx = fitWidth.map { $0 / b.width } ?? min(1, (maxWidth ?? b.width) / b.width)
    let sy = fitHeight.map { $0 / b.height } ?? 1
    let bw = b.width*sx, bh = b.height*sy
    let left = align == "right" ? x-bw : align == "center" ? x-bw/2 : x
    precondition(left >= 0.055*W-0.1 && left+bw <= 0.945*W+0.1, "Horizontal overflow: \(text)")
    precondition(top >= 0.055*H && top+bh < 0.95*H, "Vertical overflow: \(text)")
    ctx.saveGState()
    ctx.translateBy(x: left-b.minX*sx, y: H-top-b.maxY*sy)
    ctx.scaleBy(x: sx, y: sy)
    ctx.textMatrix = .identity
    ctx.textPosition = .zero
    CTLineDraw(line, ctx)
    ctx.restoreGState()
    audit.append(["page": page, "text": text, "left": left/W, "top": top/H, "width": bw/W, "height": bh/H])
    return CGRect(x: left, y: top, width: bw, height: bh)
}

struct Product: Decodable {
    let scene: String
    let type: String
    let headline: String
    let price: String
    let size: String
    let secondPrice: String
    let secondSize: String
    let benefit: [String]
}
let products = try JSONDecoder().decode([Product].self, from: Data(contentsOf: root.appendingPathComponent("products.json")))
let ink = NSColor(srgbRed: 0.36, green: 0.025, blue: 0.12, alpha: 1)
let ivory = NSColor(srgbRed: 1, green: 0.975, blue: 0.87, alpha: 1)
for (i, product) in products.enumerated() {
    let image = NSImage(contentsOf: root.appendingPathComponent("scenes/"+product.scene))!
    var rect = CGRect(origin: .zero, size: image.size)
    let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    ctx.beginPDFPage(nil)
    ctx.saveGState()
    ctx.clip(to: media)
    let scale = max(W/Double(cg.width), H/Double(cg.height))
    let iw = Double(cg.width)*scale, ih = Double(cg.height)*scale
    ctx.draw(cg, in: CGRect(x: (W-iw)/2, y: (H-ih)/2, width: iw, height: ih))
    ctx.restoreGState()

    draw("PREMIUM NATURAL SKINCARE", x: W*0.5, top: H*0.060,
         size: 14, tracking: 3.2, color: ink, align: "center", fitWidth: W*0.66, page: i+1)
    // Keep the headline behind the photographed tube, as in the reference.
    ctx.saveGState()
    let mask = CGMutablePath()
    mask.addRect(media)
    let silhouettes: [[(Double, Double)]] = [
        [(0.379,0.216),(0.609,0.216),(0.613,0.231),(0.608,0.280),(0.386,0.280)],
        [(0.384,0.238),(0.612,0.238),(0.607,0.280),(0.390,0.280)]
    ]
    mask.addLines(between: silhouettes[i].map { CGPoint(x: W*$0.0, y: H*(1-$0.1)) })
    mask.closeSubpath()
    ctx.addPath(mask)
    ctx.clip(using: .evenOdd)
    draw(product.headline, x: W*0.065, top: H*0.110, font: "Didot", size: 130,
         color: ivory, fitWidth: W*0.88, fitHeight: H*0.163, page: i+1)

    ctx.restoreGState()

    draw("Himalaya", x: W*0.060, top: H*0.313, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)
    draw("Natural Glow", x: W*0.060, top: H*0.346, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)
    draw(product.type, x: W*0.060, top: H*0.379, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)

    draw("PRODUCT BENEFIT", x: W*0.945, top: H*0.326, font: "HelveticaNeue-Medium",
         size: 10.5, tracking: 1.6, color: ink, align: "right", maxWidth: W*0.222, page: i+1)
    for (n, text) in product.benefit.enumerated() {
        draw(text, x: W*0.815, top: H*(0.356+Double(n)*0.020), size: 12.5,
             color: ink, align: "center", maxWidth: W*0.26, page: i+1)
    }
    let box = draw("LKR " + product.price, x: W*0.945, top: H*0.478, font: "Times-Roman", size: 27,
                   color: ink, align: "right", page: i+1)
    draw(product.size, x: box.minX, top: H*0.511, size: 15, color: ink, page: i+1)
    let second = draw("LKR " + product.secondPrice, x: W*0.945, top: H*0.550, font: "Times-Roman", size: 27,
                      color: ink, align: "right", page: i+1)
    draw(product.secondSize, x: second.minX, top: H*0.583, size: 15, color: ink, page: i+1)
    ctx.endPDFPage()
}
ctx.closePDF()
let pdf = PDFDocument(url: output)!
precondition(pdf.pageCount == products.count)
for i in 0..<products.count {
    let im = pdf.page(at: i)!.thumbnail(of: NSSize(width: 1050, height: 1485), for: .mediaBox)
    let bitmap = NSBitmapImageRep(data: im.tiffRepresentation!)!
    try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(String(format:"previews/%02d-page.png", i+1)))
}
try JSONSerialization.data(withJSONObject: audit, options: [.prettyPrinted,.sortedKeys]).write(to: root.appendingPathComponent("text-positions.json"))
print("Built \(pdf.pageCount) face cream A4 pages.")
