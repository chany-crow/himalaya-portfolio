import AppKit
import CoreText
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let W = 210.0 / 25.4 * 72, H = 297.0 / 25.4 * 72
let output = root.deletingLastPathComponent().appendingPathComponent("Himalaya-Vitamin-C-Portfolio-A4.pdf")
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

let scenes = ["01-cream.png", "02-serum.png", "03-face-wash.png"]
let benefits = [
    ["Vitamin C helps brighten", "dull skin, boost radiance,", "and support a fresh,", "hydrated glow."],
    ["For brighter-looking,", "radiant skin."],
    ["For youthful and", "radiant-looking skin."]
]
let ink = NSColor(srgbRed: 0.40, green: 0.075, blue: 0.025, alpha: 1)
let ivory = NSColor(srgbRed: 1, green: 0.975, blue: 0.87, alpha: 1)
for i in 0..<3 {
    let image = NSImage(contentsOf: root.appendingPathComponent("scenes/"+scenes[i]))!
    var rect = CGRect(origin: .zero, size: image.size)
    let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    ctx.beginPDFPage(nil)
    ctx.saveGState()
    ctx.clip(to: media)
    let scale = max(W/Double(cg.width), H/Double(cg.height))
    let iw = Double(cg.width)*scale, ih = Double(cg.height)*scale
    ctx.draw(cg, in: CGRect(x: (W-iw)/2, y: (H-ih)/2, width: iw, height: ih))
    ctx.restoreGState()

    draw("PREMIUM VITAMIN C SKINCARE", x: W*0.5, top: H*0.060,
         size: 14, tracking: 3.2, color: ink, align: "center", fitWidth: W*0.66, page: i+1)
    ctx.saveGState()
    // The large headline sits visually behind the product, as in the reference.
    if i == 2 {
        let clip = CGMutablePath()
        clip.addRect(media)
        clip.move(to: CGPoint(x: W*0.340, y: H*(1-0.234)))
        clip.addLine(to: CGPoint(x: W*0.671, y: H*(1-0.234)))
        clip.addLine(to: CGPoint(x: W*0.666, y: H*(1-0.280)))
        clip.addLine(to: CGPoint(x: W*0.346, y: H*(1-0.280)))
        clip.closeSubpath()
        ctx.addPath(clip)
        ctx.clip(using: .evenOdd)
    } else if i == 1 {
        let clip = CGMutablePath()
        clip.addRect(media)
        clip.addRect(CGRect(x: W*0.423, y: H*(1-0.280), width: W*0.300, height: H*(0.280-0.269)))
        ctx.addPath(clip)
        ctx.clip(using: .evenOdd)
    }
    draw("BRIGHT", x: W*0.065, top: H*0.110, font: "Didot", size: 130,
         color: ivory, fitWidth: W*0.88, fitHeight: H*0.163, page: i+1)
    ctx.restoreGState()

    draw("Himalaya", x: W*0.060, top: H*0.313, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)
    draw("Brightening", x: W*0.060, top: H*0.346, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)
    draw("Vitamin C", x: W*0.060, top: H*0.379, font: "Times-Roman", size: 26,
         color: ink, maxWidth: W*0.30, page: i+1)
    let detail = ["Orange Face Serum Cream", "Orange Face Serum", "Orange Face Wash"][i]
    draw(detail, x: W*0.060, top: H*0.412, font: "Times-Roman", size: i == 0 ? 17 : 21,
         color: ink, maxWidth: W*0.30, page: i+1)

    draw("PRODUCT BENEFIT", x: W*0.945, top: H*0.326, font: "HelveticaNeue-Medium",
         size: 10.5, tracking: 1.6, color: ink, align: "right", maxWidth: W*0.222, page: i+1)
    for (n, text) in benefits[i].enumerated() {
        draw(text, x: W*0.815, top: H*(0.356+Double(n)*0.020), size: 12.5,
             color: ink, align: "center", maxWidth: W*0.26, page: i+1)
    }
    // Preserve the approved first design's price content; this update only changes placement.
    if i == 0 {
        let box = draw("LKR 1,200", x: W*0.945, top: H*0.478, font: "Times-Roman", size: 27,
                       color: ink, align: "right", page: i+1)
        draw("50ml", x: box.minX, top: H*0.511, size: 15, color: ink, page: i+1)
    }
    ctx.endPDFPage()
}
ctx.closePDF()
let pdf = PDFDocument(url: output)!
precondition(pdf.pageCount == 3)
for i in 0..<3 {
    let im = pdf.page(at: i)!.thumbnail(of: NSSize(width: 1050, height: 1485), for: .mediaBox)
    let bitmap = NSBitmapImageRep(data: im.tiffRepresentation!)!
    try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(String(format:"previews/%02d-page.png", i+1)))
}
try JSONSerialization.data(withJSONObject: audit, options: [.prettyPrinted,.sortedKeys]).write(to: root.appendingPathComponent("text-positions.json"))
print("Built 3 A4 pages with text anchors measured from the supplied PURE reference.")
