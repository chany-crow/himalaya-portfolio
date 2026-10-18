import AppKit
import CoreText
import PDFKit
let root = URL(fileURLWithPath:#filePath).deletingLastPathComponent()
for name in ["GothamCondensed-Medium", "MyriadPro-Regular"] {
 CTFontManagerRegisterFontsForURL(root.deletingLastPathComponent().appendingPathComponent("assets/fonts/\(name).otf") as CFURL, .process, nil)
}
let W=210.0/25.4*72, H=297.0/25.4*72
var media=CGRect(x:0,y:0,width:W,height:H)
let out=root.appendingPathComponent("Himalaya-Cover-A4.pdf")
let ctx=CGContext(out as CFURL,mediaBox:&media,nil)!
ctx.beginPDFPage(nil)
let image=NSImage(contentsOf:root.appendingPathComponent("cover/botanical-cover.png"))!
var rect=CGRect(origin:.zero,size:image.size)
let cg=image.cgImage(forProposedRect:&rect,context:nil,hints:nil)!
let scale=max(W/Double(cg.width),H/Double(cg.height))
ctx.draw(cg,in:CGRect(x:(W-Double(cg.width)*scale)/2,y:(H-Double(cg.height)*scale)/2,width:Double(cg.width)*scale,height:Double(cg.height)*scale))
func title(_ text:String,top:Double,font:String,size:Double,tracking:Double=0) {
 let line=CTLineCreateWithAttributedString(NSAttributedString(string:text,attributes:[.font:NSFont(name:font,size:size)!, .foregroundColor:NSColor.white,.kern:tracking]))
 let bounds=CTLineGetBoundsWithOptions(line,.useGlyphPathBounds)
 precondition(bounds.width<W*0.88)
 ctx.textMatrix = .identity
 ctx.textPosition=CGPoint(x:(W-bounds.width)/2-bounds.minX,y:H-top*H-bounds.maxY)
 CTLineDraw(line,ctx)
}
title("Himalaya",top:0.145,font:"MyriadPro-Regular",size:43)
title("SINCE 1930",top:0.210,font:"MyriadPro-Regular",size:10,tracking:3)
title("PRODUCT",top:0.300,font:"GothamCondensed-Medium",size:88,tracking:2)
title("PORTFOLIO",top:0.402,font:"GothamCondensed-Medium",size:88,tracking:2)
title("SKIN CARE  ·  HAIR CARE  ·  LIP CARE",top:0.530,font:"MyriadPro-Regular",size:11,tracking:1.2)
ctx.endPDFPage();ctx.closePDF()
let pdf=PDFDocument(url:out)!
let preview=pdf.page(at:0)!.thumbnail(of:NSSize(width:1050,height:1485),for:.mediaBox)
let bitmap=NSBitmapImageRep(data:preview.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("cover/preview.png"))
print("Built A4 botanical cover.")
