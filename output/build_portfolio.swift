import AppKit
import CoreText
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let width = 210.0 / 25.4 * 72.0
let height = 297.0 / 25.4 * 72.0
let inset = 12.0 / 25.4 * 72.0
let usable = width - 2 * inset
let output = root.appendingPathComponent("Himalaya-Vitamin-C-Portfolio-A4.pdf")
var media = CGRect(x: 0, y: 0, width: width, height: height)
let context = CGContext(output as CFURL, mediaBox: &media, nil)!
var audit: [[String: Any]] = []

func line(_ text: String, font: String, size: Double, tracking: Double = 0, color: NSColor) -> CTLine {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: font, size: size)!,
        .foregroundColor: color,
        .kern: tracking
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
}

func draw(_ text: String, x: Double, top: Double, font: String = "HelveticaNeue", size: Double,
          tracking: Double = 0, color: NSColor, align: String = "left", page: Int) {
    let value = line(text, font: font, size: size, tracking: tracking, color: color)
    let bounds = CTLineGetBoundsWithOptions(value, .useGlyphPathBounds)
    let left = align == "right" ? x - bounds.width : align == "center" ? x - bounds.width / 2 : x
    precondition(left >= inset - 0.01 && left + bounds.width <= width - inset + 0.01,
                 "Text outside horizontal safe area: \(text)")
    precondition(top >= inset - 0.01 && top + bounds.height <= height - inset + 0.01,
                 "Text outside vertical safe area: \(text)")
    context.textMatrix = .identity
    context.textPosition = CGPoint(x: left - bounds.minX, y: height - top - bounds.maxY)
    CTLineDraw(value, context)
    audit.append(["page": page, "text": text, "left_pt": left, "top_pt": top,
                  "width_pt": bounds.width, "height_pt": bounds.height])
}

let scenes = ["01-cream.png", "02-serum.png", "03-face-wash.png"]
let names = ["Orange Face Serum Cream", "Orange Face Serum", "Orange Face Wash"]
let benefits = [
    ["Vitamin C helps brighten dull skin,", "boost radiance, and support a", "fresh, hydrated glow."],
    ["For brighter-looking,", "radiant skin."],
    ["For youthful and", "radiant-looking skin."]
]
for i in 0..<scenes.count {
    let imageURL = root.appendingPathComponent("scenes/" + scenes[i])
    let image = NSImage(contentsOf: imageURL)!
    var rect = CGRect(origin: .zero, size: image.size)
    let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    context.beginPDFPage(nil)
    context.saveGState()
    context.clip(to: media)
    let scale = max(width / Double(cg.width), height / Double(cg.height))
    let iw = Double(cg.width) * scale, ih = Double(cg.height) * scale
    context.draw(cg, in: CGRect(x: (width-iw)/2, y: (height-ih)/2, width: iw, height: ih))
    context.restoreGState()

    let ink = i == 2 ? NSColor(srgbRed: 0.02, green: 0.24, blue: 0.20, alpha: 1)
                     : NSColor(srgbRed: 0.40, green: 0.09, blue: 0.025, alpha: 1)
    let headline = i == 2 ? NSColor(srgbRed: 0.13, green: 0.36, blue: 0.25, alpha: 1)
                          : NSColor(srgbRed: 0.60, green: 0.24, blue: 0.07, alpha: 1)
    draw("PREMIUM VITAMIN C SKINCARE", x: width/2, top: inset,
         size: 10, tracking: 3.2, color: ink, align: "center", page: i+1)
    let base = line("BRIGHT", font: "Didot", size: 100, color: headline)
    let titleSize = 100 * usable / CTLineGetBoundsWithOptions(base, .useGlyphPathBounds).width
    draw("BRIGHT", x: inset, top: 65, font: "Didot", size: titleSize, color: headline, page: i+1)
    draw("Himalaya", x: inset, top: 197, size: 23, color: ink, page: i+1)
    draw("Brightening", x: inset, top: 225, size: 23, color: ink, page: i+1)
    draw("Vitamin C", x: inset, top: 253, size: 23, color: ink, page: i+1)
    draw(names[i], x: inset, top: 283, size: 17, color: ink, page: i+1)

    draw("PRODUCT BENEFIT", x: width-inset, top: 198, font: "HelveticaNeue-Medium",
         size: 10, tracking: 1.3, color: ink, align: "right", page: i+1)
    for (n, text) in benefits[i].enumerated() {
        draw(text, x: width-inset, top: 222 + Double(n)*18, size: 12,
             color: ink, align: "right", page: i+1)
    }
    if i < 2 {
        let priceX = i == 0 ? width-inset : inset
        let priceAlign = i == 0 ? "right" : "left"
        draw(i == 0 ? "LKR 1,200" : "LKR 965", x: priceX, top: 318,
             size: 23, color: ink, align: priceAlign, page: i+1)
        draw(i == 0 ? "50 ml" : "15 ml", x: priceX, top: 348,
             size: 13, color: ink, align: priceAlign, page: i+1)
    }

    for (text, anchor, alignment) in [("HIMALAYA  /  VITAMIN C", inset, "left"),
                                       (String(format: "%02d / 03", i+1), width-inset, "right")] {
        let footer = line(text, font: "HelveticaNeue-Medium", size: 8, tracking: 1, color: ink)
        let footerHeight = CTLineGetBoundsWithOptions(footer, .useGlyphPathBounds).height
        draw(text, x: anchor, top: height-inset-footerHeight, font: "HelveticaNeue-Medium",
             size: 8, tracking: 1, color: ink, align: alignment, page: i+1)
    }
    context.endPDFPage()
}
context.closePDF()
let doc = PDFDocument(url: output)!
precondition(doc.pageCount == 3)
for i in 0..<doc.pageCount {
    let page = doc.page(at: i)!
    let thumbnail = page.thumbnail(of: NSSize(width: 1050, height: 1485), for: .mediaBox)
    let bitmap = NSBitmapImageRep(data: thumbnail.tiffRepresentation!)!
    try bitmap.representation(using: .png, properties: [:])!.write(
        to: root.appendingPathComponent(String(format: "previews/%02d-page.png", i+1)))
}
let auditData = try JSONSerialization.data(withJSONObject: ["page_mm": [210, 297], "text_inset_mm": 12, "text_bounds": audit], options: [.prettyPrinted, .sortedKeys])
try auditData.write(to: root.appendingPathComponent("layout-audit.json"))
print("Built and validated 3 A4 pages, full-bleed backgrounds, all text within 12 mm safe area.")
