import Foundation
import AppKit
import PDFKit
import Vision
let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent()
let rows=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("portfolio-products.json"))) as! [[String:Any]]
let pdf=PDFDocument(url:root.appendingPathComponent("Himalaya-Product-Portfolio-A4.pdf"))!
precondition(pdf.pageCount == rows.count+1 && rows.count == 27)
precondition(pdf.page(at:0)!.string!.contains("PORTFOLIO"))
for (i,r) in rows.enumerated() {
 let p=pdf.page(at:i+1)!,text=p.string!
 let bounds=p.bounds(for:.mediaBox)
 precondition(abs(bounds.width-210/25.4*72)<0.01 && abs(bounds.height-297/25.4*72)<0.01)
 let description=r["description"] as! String
 precondition((35...40).contains(description.split(separator:" ").count))
 for price in r["prices"] as! [[String:String]] {precondition(text.contains("LKR "+price["price"]!))}
 precondition(text.contains(String(format:"Page %02d",i+1)))
 let image=p.thumbnail(of:NSSize(width:1680,height:2376),for:.mediaBox)
 var rect=CGRect(origin:.zero,size:image.size)
 let cg=image.cgImage(forProposedRect:&rect,context:nil,hints:nil)!
 let request=VNDetectBarcodesRequest();request.symbologies=[.qr];request.revision=1;request.usesCPUOnly=true
 try VNImageRequestHandler(cgImage:cg).perform([request])
 let decoded=request.results?.compactMap(\.payloadStringValue) ?? []
 precondition(decoded.contains(r["productURL"] as! String), "QR mismatch on page \(i+1): \(decoded)")
 print("Page \(i+1): A4, copy length, price, page number and QR verified")
}
precondition(pdf.page(at:27)!.string!.contains("LKR 490"))
print("All 27 portfolio pages verified.")
