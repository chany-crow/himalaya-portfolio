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
          tracking: Double = 0, color: NSColor, align: String = "left", verticalScale: Double = 1, page: Int) {
    let value = line(text, font: font, size: size, tracking: tracking, color: color)
    let bounds = CTLineGetBoundsWithOptions(value, .useGlyphPathBounds)
    let left = align == "right" ? x - bounds.width : align == "center" ? x - bounds.width / 2 : x
    precondition(left >= inset - 0.01 && left + bounds.width <= width - inset + 0.01,
                 "Text outside horizontal safe area: \(text)")
    precondition(top >= inset - 0.01 && top + bounds.height * verticalScale <= height - inset + 0.01,
                 "Text outside vertical safe area: \(text)")
    context.saveGState()
    context.translateBy(x: left - bounds.minX, y: height - top - bounds.maxY * verticalScale)
    context.scaleBy(x: 1, y: verticalScale)
    context.textMatrix = .identity
    context.textPosition = .zero
    CTLineDraw(value, context)
    context.restoreGState()
    audit.append(["page": page, "text": text, "left_pt": left, "top_pt": top,
                  "width_pt": bounds.width, "height_pt": bounds.height * verticalScale])
}

let scenes = ["01-cream.png", "02-serum.png", "03-face-wash.png"]
let names = ["Orange Face Serum Cream", "Orange Face Serum", "Orange Face Wash"]
let benefits = [
    ["Vitamin C helps brighten dull skin,", "boost radiance, and support a", "fresh, hydrated glow."],
    ["For brighter-looking,", "radiant skin."],
    ["For youthful and", "radiant-looking skin."]
]
for i in 0..<scenes.count {
    let imageURL = root.appendingPathComponent("scenes-reference-style/" + scenes[i])
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

    let ink = NSColor(srgbRed: 0.40, green: 0.065, blue: 0.015, alpha: 1)
    let headline = NSColor(srgbRed: 1, green: 0.97, blue: 0.85, alpha: 1)
    draw("PREMIUM VITAMIN C SKINCARE", x: width/2, top: 54,
         size: 10, tracking: 3.2, color: ink, align: "center", page: i+1)
    let base = line("BRIGHT", font: "Didot", size: 100, color: headline)
    let titleSize = 100 * usable / CTLineGetBoundsWithOptions(base, .useGlyphPathBounds).width
    draw("BRIGHT", x: inset, top: 94, font: "Didot", size: titleSize, color: headline,
         verticalScale: 1.2, page: i+1)
    let nameTop = i == 0 ? 232.0 : 266.0
    let nameSize = i == 0 ? 23.0 : 21.0
    draw("Himalaya", x: inset, top: nameTop, size: nameSize, color: ink, page: i+1)
    draw("Brightening", x: inset, top: nameTop+28, size: nameSize, color: ink, page: i+1)
    draw("Vitamin C", x: inset, top: nameTop+56, size: nameSize, color: ink, page: i+1)
    if i == 0 {
        draw(names[i], x: inset, top: nameTop+84, size: 21, color: ink, page: i+1)
    } else {
        draw("Orange Face", x: inset, top: nameTop+84, size: nameSize, color: ink, page: i+1)
        draw(i == 1 ? "Serum" : "Wash", x: inset, top: nameTop+112, size: nameSize, color: ink, page: i+1)
    }

    let benefitTop = i == 0 ? 228.0 : 274.0
    let benefitInk = i == 2 ? NSColor(srgbRed: 1, green: 0.98, blue: 0.91, alpha: 1) : ink
    draw("PRODUCT BENEFIT", x: width-inset, top: benefitTop, font: "HelveticaNeue-Medium",
         size: 10, tracking: 1.3, color: benefitInk, align: "right", page: i+1)
    for (n, text) in benefits[i].enumerated() {
        draw(text, x: width-inset, top: benefitTop + 24 + Double(n)*18, size: 12,
             color: benefitInk, align: "right", page: i+1)
    }
    if i < 2 {
        let priceTop = i == 0 ? 306.0 : 410.0
        draw(i == 0 ? "LKR 1,200" : "LKR 965", x: width-inset, top: priceTop,
             size: 23, color: ink, align: "right", page: i+1)
        draw(i == 0 ? "50 ml" : "15 ml", x: width-inset, top: priceTop+30,
             size: 13, color: ink, align: "right", page: i+1)
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
