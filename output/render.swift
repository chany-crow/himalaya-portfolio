import AppKit
import CoreText
import CoreImage
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
for name in ["GothamCondensed-Medium", "MyriadPro-Regular"] {
    let url = root.deletingLastPathComponent().appendingPathComponent("assets/fonts/\(name).otf")
    var error: Unmanaged<CFError>?
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    precondition(NSFont(name: name, size: 12) != nil, "Missing supplied font: \(name)")
}
let heading = "GothamCondensed-Medium", body = "MyriadPro-Regular"
let W = 210.0 / 25.4 * 72, H = 297.0 / 25.4 * 72
struct Price: Decodable { let price: String; let size: String }
struct Product: Decodable {
    let scene: String; let names: [String]; let headline: String; let header: String
    let prices: [Price]; let color: [Double]; let whiteRight: Bool; let mask: [[Double]]
    let group: String; let pdf: String; let page: Int; let description: String
    let productURL: String; let linkLabel: String
}
let products = try JSONDecoder().decode([Product].self, from: Data(contentsOf: root.appendingPathComponent("portfolio-products.json")))
let selected = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil
let groups = products.map(\.group).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
var audit: [[String: Any]] = []
struct QRMatrix: Decodable { let url: String; let modules: [[Bool]] }
let qrMatrices = try JSONDecoder().decode([QRMatrix].self, from: Data(contentsOf: root.appendingPathComponent("qr-matrices.json")))
func line(_ text: String, _ font: String, _ size: Double, _ tracking: Double, _ color: NSColor) -> CTLine {
    CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font:NSFont(name:font,size:size)!, .kern:tracking, .foregroundColor:color]))
}
for group in groups where selected == nil || selected == group {
 let ps = products.filter { $0.group == group }
 var media = CGRect(x:0,y:0,width:W,height:H)
 let out = root.appendingPathComponent(ps[0].pdf)
 let ctx = CGContext(out as CFURL, mediaBox:&media, nil)!
 @discardableResult
 func draw(_ text: String, x:Double, top:Double, font:String = body, size:Double, tracking:Double = 0, color:NSColor, align:String = "left", fitWidth:Double? = nil, fitHeight:Double? = nil, maxWidth:Double? = nil, page:Int) -> CGRect {
    let l=line(text,font,size,tracking,color), b=CTLineGetBoundsWithOptions(l,.useGlyphPathBounds)
    let sx=fitWidth.map{$0/b.width} ?? min(1,(maxWidth ?? b.width)/b.width)
    let sy=fitHeight.map{$0/b.height} ?? 1
    let bw=b.width*sx,bh=b.height*sy
    let left=align == "right" ? x-bw : align == "center" ? x-bw/2 : x
    precondition(left >= 0.055*W-0.1 && left+bw <= 0.945*W+0.1, "Horizontal overflow: \(text)")
    precondition(top >= 0.055*H && top+bh < 0.95*H, "Vertical overflow: \(text)")
    ctx.saveGState();ctx.translateBy(x:left-b.minX*sx,y:H-top-b.maxY*sy);ctx.scaleBy(x:sx,y:sy)
    ctx.textMatrix = .identity;ctx.textPosition = .zero;CTLineDraw(l,ctx);ctx.restoreGState()
    audit.append(["page":page,"text":text,"font":font,"align":align,"left":left/W,"top":top/H,"width":bw/W,"height":bh/H])
    return CGRect(x:left,y:top,width:bw,height:bh)
 }
 func wrap(_ text:String, size:Double, width:Double) -> [String] {
    var lines:[String]=[],current=""
    for word in text.split(separator:" ") {
        let next=current.isEmpty ? String(word) : current+" "+word
        if CTLineGetTypographicBounds(line(next,body,size,0,.black),nil,nil,nil) > width && !current.isEmpty {lines.append(current);current=String(word)} else {current=next}
    }
    if !current.isEmpty {lines.append(current)}
    return lines
 }
 for p in ps {
    let ink=NSColor(srgbRed:p.color[0],green:p.color[1],blue:p.color[2],alpha:1)
    let ivory=NSColor(srgbRed:1,green:0.975,blue:0.90,alpha:1)
    let rightInk=p.whiteRight ? ivory : ink
    let image=NSImage(contentsOf:root.appendingPathComponent("\(group)/scenes/\(p.scene)"))!
    var rect=CGRect(origin:.zero,size:image.size)
    let cg=image.cgImage(forProposedRect:&rect,context:nil,hints:nil)!
    ctx.beginPDFPage(nil)
    ctx.saveGState();ctx.clip(to:media)
    let scale=max(W/Double(cg.width),H/Double(cg.height)),iw=Double(cg.width)*scale,ih=Double(cg.height)*scale
    ctx.draw(cg,in:CGRect(x:(W-iw)/2,y:(H-ih)/2,width:iw,height:ih));ctx.restoreGState()
    draw(p.header,x:W*0.5,top:H*0.060,font:heading,size:17,tracking:3.2,color:rightInk,align:"center",fitWidth:W*0.66,page:p.page)
    ctx.saveGState()
    if !p.mask.isEmpty {
        let mask=CGMutablePath();mask.addRect(media)
        mask.addLines(between:p.mask.map{CGPoint(x:W*$0[0],y:H*(1-$0[1]))});mask.closeSubpath()
        ctx.addPath(mask);ctx.clip(using:.evenOdd)
    }
    draw(p.headline,x:W*0.065,top:H*0.110,font:heading,size:130,color:ivory,fitWidth:W*0.88,fitHeight:H*0.163,page:p.page)
    ctx.restoreGState()
    for (n,name) in p.names.enumerated() {
        draw(name,x:W*0.060,top:H*(0.313+Double(n)*0.033),font:heading,size:27,color:.white,maxWidth:W*0.30,page:p.page)
    }
    draw("PRODUCT BENEFIT",x:W*0.945,top:H*0.326,font:body,size:12,tracking:1.0,color:.white,align:"right",maxWidth:W*0.26,page:p.page)
    let count=p.description.split(separator:" ").count
    precondition((35...40).contains(count))
    var descSize=11.5
    var lines=wrap(p.description,size:descSize,width:W*0.26)
    while Double(lines.count)*descSize*1.12 > H*0.118 {descSize-=0.25;lines=wrap(p.description,size:descSize,width:W*0.26)}
    precondition(descSize >= 9)
    var bottom=H*0.356
    for (n,text) in lines.enumerated() {
        let box=draw(text,x:W*0.945,top:H*0.356+Double(n)*descSize*1.12,size:descSize,color:.white,align:"right",page:p.page)
        bottom=box.maxY
    }
    let priceTop=max(H*0.490,bottom+15)
    for (n,price) in p.prices.enumerated() {
        let top=priceTop+Double(n)*H*0.072
        draw("LKR "+price.price,x:W*0.945,top:top,size:26,color:rightInk,align:"right",page:p.page)
        draw(price.size,x:W*0.945,top:top+H*0.033,size:15,color:rightInk,align:"right",page:p.page)
    }
    // Vector QR modules retain sharp edges in print; four-module quiet zone.
    let matrix=qrMatrices[p.page-1]
    precondition(matrix.url == p.productURL)
    let n=matrix.modules.count
    let qrSize=22.0/25.4*72,x=W*0.945-qrSize,y=H*0.055,unit=qrSize/Double(n+8)
    ctx.setFillColor(NSColor(srgbRed:0.015,green:0.13,blue:0.11,alpha:1).cgColor)
    ctx.fill(CGRect(x:x,y:y,width:qrSize,height:qrSize))
    ctx.saveGState();ctx.setShouldAntialias(false);ctx.setFillColor(NSColor.white.cgColor)
    for row in 0..<n {for col in 0..<n where matrix.modules[row][col] {
        ctx.fill(CGRect(x:x+Double(col+4)*unit,y:y+Double(n-1-row+4)*unit,width:unit,height:unit))
    }}
    ctx.restoreGState()
    draw(p.linkLabel,x:W*0.945,top:H-y-qrSize-11,font:body,size:8.5,tracking:0.8,color:.white,align:"right",page:p.page)
    ctx.setURL(URL(string:p.productURL)! as CFURL,for:CGRect(x:x,y:y,width:qrSize,height:qrSize))
    // A small ivory page-number plaque stays readable over every photograph.
    let plaque=CGRect(x:W*0.060,y:H*0.055,width:49,height:21)
    ctx.setFillColor(NSColor(srgbRed:1,green:0.975,blue:0.90,alpha:0.94).cgColor)
    ctx.addPath(CGPath(roundedRect:plaque,cornerWidth:3,cornerHeight:3,transform:nil));ctx.fillPath()
    draw(String(format:"Page %02d",p.page),x:W*0.060+7,top:H-plaque.maxY+6,font:body,size:10,color:NSColor(srgbRed:0.02,green:0.22,blue:0.18,alpha:1),page:p.page)
    ctx.endPDFPage()
 }
 ctx.closePDF()
 let pdf=PDFDocument(url:out)!
 precondition(pdf.pageCount == ps.count)
 for i in 0..<ps.count {
    let image=pdf.page(at:i)!.thumbnail(of:NSSize(width:1050,height:1485),for:.mediaBox)
    let bitmap=NSBitmapImageRep(data:image.tiffRepresentation!)!
    try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent(String(format:"%@/previews/%02d-page.png",group,i+1)))
 }
 try JSONSerialization.data(withJSONObject:audit.filter{ row in ps.contains{$0.page == row["page"] as? Int}},options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("\(group)/text-positions.json"))
 print("Built \(ps.count) \(group) pages with supplied fonts and product QR codes.")
}
