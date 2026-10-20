import AppKit
import CoreText
import CoreImage
import PDFKit
import Accelerate

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
for name in ["GothamCondensed-Medium", "MyriadPro-Regular"] {
    let url = root.deletingLastPathComponent().appendingPathComponent("assets/fonts/\(name).otf")
    var error: Unmanaged<CFError>?
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    precondition(NSFont(name: name, size: 12) != nil, "Missing supplied font: \(name)")
}
let heading = "GothamCondensed-Medium", body = "MyriadPro-Regular"
let W = 210.0 / 25.4 * 72, H = 297.0 / 25.4 * 72
let logoImage = NSImage(contentsOf:root.deletingLastPathComponent().appendingPathComponent("assets/branding/himalaya-logo.png"))!
var logoRect = CGRect(origin:.zero,size:logoImage.size)
let logoSource = logoImage.cgImage(forProposedRect:&logoRect,context:nil,hints:nil)!
let logoPixels = NSBitmapImageRep(cgImage:logoSource)
var lx=logoSource.width,ly=logoSource.height,rx=0,by=0
for y in 0..<logoSource.height {for x in 0..<logoSource.width {
    if (logoPixels.colorAt(x:x,y:y)?.alphaComponent ?? 0) > 0.05 {
        lx=min(lx,x);ly=min(ly,y);rx=max(rx,x);by=max(by,y)
    }
}}
// Ignore transparent outer padding when positioning the supplied logo.
let pageLogo=logoSource.cropping(to:CGRect(x:lx,y:ly,width:rx-lx+1,height:by-ly+1))!

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
func line(_ text: String, _ font: String, _ size: Double, _ tracking: Double, _ color: NSColor, _ emphasis: Bool = false) -> CTLine {
    CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font:NSFont(name:font,size:size)!, .kern:tracking, .foregroundColor:color, .strokeWidth:emphasis ? -0.7 : 0, .strokeColor:color]))
}
// Blur only the photographic detail column; all typography remains vector-sharp.
func softenDetails(_ image: CGImage, in page: CGContext, bounds: CGRect) {
    let density = 1.5
    let width = Int(ceil(bounds.width*density)), height = Int(ceil(bounds.height*density))
    let stride = width*4
    let data = UnsafeMutableRawPointer.allocate(byteCount:stride*height,alignment:64)
    let scratch = UnsafeMutableRawPointer.allocate(byteCount:stride*height,alignment:64)
    defer { data.deallocate(); scratch.deallocate() }
    let bitmap = CGContext(data:data,width:width,height:height,bitsPerComponent:8,bytesPerRow:stride,
        space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    bitmap.scaleBy(x:Double(width)/bounds.width,y:Double(height)/bounds.height)
    bitmap.translateBy(x:-bounds.minX,y:-bounds.minY)
    let scale=max(W/Double(image.width),H/Double(image.height))
    let iw=Double(image.width)*scale,ih=Double(image.height)*scale
    bitmap.draw(image,in:CGRect(x:(W-iw)/2,y:(H-ih)/2,width:iw,height:ih))
    var source=vImage_Buffer(data:data,height:vImagePixelCount(height),width:vImagePixelCount(width),rowBytes:stride)
    var target=vImage_Buffer(data:scratch,height:vImagePixelCount(height),width:vImagePixelCount(width),rowBytes:stride)
    for _ in 0..<3 {
        precondition(vImageBoxConvolve_ARGB8888(&source,&target,nil,0,0,23,23,nil,vImage_Flags(kvImageEdgeExtend)) == kvImageNoError)
        swap(&source,&target)
    }
    let pixels=source.data.assumingMemoryBound(to:UInt8.self)
    // Feather into the original photo without a visible rectangular edge.
    let feather=18.0*density
    for y in 0..<height { for x in 0..<width {
        let distance=Double(min(x,width-1-x,y,height-1-y))
        let t=min(1,max(0,distance/feather))
        let alpha=t*t*(3-2*t)
        let offset=y*stride+x*4
        for channel in 0..<3 { pixels[offset+channel]=UInt8(Double(pixels[offset+channel])*alpha) }
        pixels[offset+3]=UInt8(255*alpha)
    }}
    let provider=CGDataProvider(data:Data(bytes:source.data,count:stride*height) as CFData)!
    let blurred=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:stride,
        space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),
        provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
    page.draw(blurred,in:bounds)
}
for group in groups where selected == nil || selected == group {
 let ps = products.filter { $0.group == group }
 var media = CGRect(x:0,y:0,width:W,height:H)
 let out = root.appendingPathComponent(ps[0].pdf)
 let ctx = CGContext(out as CFURL, mediaBox:&media, nil)!
 @discardableResult
 func draw(_ text: String, x:Double, top:Double, font:String = body, size:Double, tracking:Double = 0, color:NSColor, align:String = "left", fitWidth:Double? = nil, fitHeight:Double? = nil, maxWidth:Double? = nil, emphasis:Bool = false, page:Int) -> CGRect {
    let l=line(text,font,size,tracking,color,emphasis), b=CTLineGetBoundsWithOptions(l,.useGlyphPathBounds)
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
    // Deep teal is taken from the Himalaya logo and product caps.
    let productNameInk=NSColor(srgbRed:0.0,green:0.31,blue:0.33,alpha:1)
    let image=NSImage(contentsOf:root.appendingPathComponent("\(group)/scenes/\(p.scene)"))!
    var rect=CGRect(origin:.zero,size:image.size)
    let cg=image.cgImage(forProposedRect:&rect,context:nil,hints:nil)!
    // Choose white or deep teal against the actual photograph under each label.
    let pixels = NSBitmapImageRep(cgImage: cg)
    func readableInk(left: Double, top: Double, width: Double, height: Double) -> NSColor {
        let dark = NSColor(srgbRed: 0, green: 0.16, blue: 0.17, alpha: 1)
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value/12.92 : pow((value+0.055)/1.055, 2.4)
        }
        let darkL = 0.7152*linear(0.16)+0.0722*linear(0.17)
        let scale = max(W/Double(cg.width), H/Double(cg.height))
        let cropX = (Double(cg.width)*scale-W)/2
        let cropY = (Double(cg.height)*scale-H)/2
        var whiteScores: [Double] = [], darkScores: [Double] = []
        for row in 0..<16 { for col in 0..<24 {
            let px = Int(((left+width*(Double(col)+0.5)/24)*W+cropX)/scale)
            let py = Int(((top+height*(Double(row)+0.5)/16)*H+cropY)/scale)
            guard let color = pixels.colorAt(x: min(cg.width-1,max(0,px)), y: min(cg.height-1,max(0,py)))?.usingColorSpace(.sRGB) else { continue }
            let l = 0.2126*linear(color.redComponent)+0.7152*linear(color.greenComponent)+0.0722*linear(color.blueComponent)
            whiteScores.append(1.05/(l+0.05))
            darkScores.append((max(l,darkL)+0.05)/(min(l,darkL)+0.05))
        }}
        whiteScores.sort(); darkScores.sort()
        let index = whiteScores.count/4
        return whiteScores[index] >= darkScores[index] ? .white : dark
    }
    ctx.beginPDFPage(nil)
    ctx.saveGState();ctx.clip(to:media)
    let scale=max(W/Double(cg.width),H/Double(cg.height)),iw=Double(cg.width)*scale,ih=Double(cg.height)*scale
    ctx.draw(cg,in:CGRect(x:(W-iw)/2,y:(H-ih)/2,width:iw,height:ih));ctx.restoreGState()
    let headerBox=draw("Premium Botanic Skin Care",x:W*0.215,top:H*0.060,font:heading,size:17,tracking:2.0,color:rightInk,align:"left",maxWidth:W*0.70,page:p.page)
    let logoWidth=W*0.12,logoHeight=logoWidth*Double(pageLogo.height)/Double(pageLogo.width)
    ctx.draw(pageLogo,in:CGRect(x:W*0.060,y:H-headerBox.midY-logoHeight/2,width:logoWidth,height:logoHeight))
    ctx.saveGState()
    if !p.mask.isEmpty {
        let mask=CGMutablePath();mask.addRect(media)
        mask.addLines(between:p.mask.map{CGPoint(x:W*$0[0],y:H*(1-$0[1]))});mask.closeSubpath()
        ctx.addPath(mask);ctx.clip(using:.evenOdd)
    }
    draw(p.headline,x:W*0.065,top:H*0.110,font:heading,size:130,color:ivory,fitWidth:W*0.88,fitHeight:H*0.163,page:p.page)
    ctx.restoreGState()
    for (n,name) in p.names.enumerated() {
        draw(name,x:W*0.060,top:H*(0.313+Double(n)*0.033),font:heading,size:27,color:productNameInk,maxWidth:W*0.30,page:p.page)
    }
    // Wider packaging needs a narrower detail column with a clear safety gap.
    let detailsLeft: Double = p.page == 2 ? 0.750 : p.page == 21 ? 0.785 : 0.685
    let detailsWidth = W*(0.945-detailsLeft)
    let descriptionHeight = H*((p.page == 2 || p.page == 21) ? 0.190 : 0.118)
    let descriptionInk = readableInk(left: detailsLeft, top: 0.326, width: 0.945-detailsLeft, height: descriptionHeight/H+0.030)
    let count=p.description.split(separator:" ").count
    precondition((35...40).contains(count))
    var descSize=11.5
    var lines=wrap(p.description,size:descSize,width:detailsWidth)
    while Double(lines.count)*descSize*1.12 > descriptionHeight {descSize-=0.25;lines=wrap(p.description,size:descSize,width:detailsWidth)}
    precondition(descSize >= 9)
    let lastLineHeight=CTLineGetBoundsWithOptions(line(lines.last!,body,descSize,0,descriptionInk),.useGlyphPathBounds).height
    let descriptionBottom=H*0.356+Double(lines.count-1)*descSize*1.12+lastLineHeight
    let estimatedPriceTop=max(H*0.490,descriptionBottom+15)
    let detailBottom=p.prices.isEmpty ? descriptionBottom : estimatedPriceTop+Double(p.prices.count-1)*H*0.072+H*0.052
    let blurTop=H*0.302, blurBottom=min(H*0.65,detailBottom+H*0.018)
    softenDetails(cg,in:ctx,bounds:CGRect(x:W*(detailsLeft-0.010),y:H-blurBottom,width:W*(0.98-detailsLeft+0.010),height:blurBottom-blurTop))
    draw("PRODUCT BENEFIT",x:W*0.945,top:H*0.326,font:body,size:12,tracking:1.0,color:descriptionInk,align:"right",maxWidth:detailsWidth,page:p.page)
    var bottom=H*0.356
    for (n,text) in lines.enumerated() {
        let box=draw(text,x:W*0.945,top:H*0.356+Double(n)*descSize*1.12,size:descSize,color:descriptionInk,align:"right",page:p.page)
        precondition(box.minX >= W*detailsLeft-0.1, "Description crosses product safety gap")
        bottom=box.maxY
    }
    let priceTop=max(H*0.490,bottom+15)
    for (n,price) in p.prices.enumerated() {
        let top=priceTop+Double(n)*H*0.072
        let priceInk = readableInk(left:detailsLeft,top:top/H,width:0.945-detailsLeft,height:0.052)
        draw("LKR "+price.price,x:W*0.945,top:top,size:26,color:priceInk,align:"right",maxWidth:detailsWidth,emphasis:true,page:p.page)
        draw(price.size,x:W*0.945,top:top+H*0.033,size:15,color:priceInk,align:"right",maxWidth:detailsWidth,emphasis:true,page:p.page)
    }
    // Opaque white quiet zone with brand-teal vector QR modules.
    let matrix=qrMatrices[p.page-1]
    precondition(matrix.url == p.productURL)
    let n=matrix.modules.count
    let qrSize=22.0/25.4*72,x=W*0.945-qrSize,y=H*0.055,unit=qrSize/Double(n+8)
    ctx.saveGState();ctx.setShouldAntialias(false)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(x:x,y:y,width:qrSize,height:qrSize))
    ctx.setFillColor(NSColor(srgbRed:1.0/255,green:99.0/255,blue:105.0/255,alpha:1).cgColor)
    for row in 0..<n {for col in 0..<n where matrix.modules[row][col] {
        ctx.fill(CGRect(x:x+Double(col+4)*unit,y:y+Double(n-1-row+4)*unit,width:unit,height:unit))
    }}
    ctx.restoreGState()
    draw(p.linkLabel,x:W*0.945,top:H-y-qrSize-11,font:body,size:8.5,tracking:0.8,color:readableInk(left:0.82,top:(H-y-qrSize-11)/H,width:0.125,height:0.012),align:"right",page:p.page)
    ctx.setURL(URL(string:p.productURL)! as CFURL,for:CGRect(x:x,y:y,width:qrSize,height:qrSize))
    // Plain page label, aligned with the left text column.
    draw(String(format:"Page %02d",p.page),x:W*0.060,top:H*0.927,font:body,size:10,color:readableInk(left:0.060,top:0.927,width:0.075,height:0.014),page:p.page)
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
