import Foundation
import PDFKit
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let names = ["Himalaya-Vitamin-C-Portfolio-A4.pdf", "Himalaya-Turmeric-Portfolio-A4.pdf", "Himalaya-Face-Cream-Portfolio-A4.pdf", "Himalaya-Face-Wash-Portfolio-A4.pdf", "Himalaya-Lip-Balm-Portfolio-A4.pdf", "Himalaya-Nourishing-Cream-Portfolio-A4.pdf", "Himalaya-Neem-Pack-Portfolio-A4.pdf"]
let combined = PDFDocument()
for name in names {
    let document = PDFDocument(url: root.appendingPathComponent(name))!
    for i in 0..<document.pageCount {
        let page = document.page(at: i)!.copy() as! PDFPage
        let bounds = page.bounds(for: .mediaBox)
        precondition(abs(bounds.width - 210.0/25.4*72) < 0.01 && abs(bounds.height - 297.0/25.4*72) < 0.01)
        combined.insert(page, at: combined.pageCount)
    }
}
precondition(combined.pageCount == 22)
precondition(combined.write(to: root.appendingPathComponent("Himalaya-Product-Portfolio-A4.pdf")))
print("Combined \(combined.pageCount) A4 pages.")
