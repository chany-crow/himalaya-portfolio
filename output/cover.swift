import AppKit
import CoreText
import PDFKit
import ImageIO
let root = URL(fileURLWithPath:#filePath).deletingLastPathComponent()
let workspace=root.deletingLastPathComponent()
for name in ["GothamCondensed-Medium", "MyriadPro-Regular"] {
 CTFontManagerRegisterFontsForURL(workspace.appendingPathComponent("assets/fonts/\(name).otf") as CFURL, .process, nil)
}
let W=210.0/25.4*72, H=297.0/25.4*72
struct CoverProduct:Decodable {let page:Int;let name:String;let source:String}
let products=try JSONDecoder().decode([CoverProduct].self,from:Data(contentsOf:root.appendingPathComponent("cover/product-manifest.json")))
precondition(products.count==27 && Set(products.map(\.page)).count==27 && Set(products.map(\.source)).count==27)
func load(_ url:URL, max:Int=1800)->CGImage {
 let source=CGImageSourceCreateWithURL(url as CFURL,nil)!
 return CGImageSourceCreateThumbnailAtIndex(source,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:max,kCGImageSourceCreateThumbnailWithTransform:true] as CFDictionary)!
}
// Find the packshot bounds without altering the supplied photograph.
func productImage(_ url:URL)->CGImage {
 let image=load(url,max:1000), sample=load(url,max:300)
 let bitmap=NSBitmapImageRep(cgImage:sample)
 var x0=sample.width,y0=sample.height,x1=0,y1=0
 for y in 0..<sample.height {for x in 0..<sample.width {
  let c=bitmap.colorAt(x:x,y:y)!.usingColorSpace(.sRGB)!
  if c.alphaComponent>0.3 && min(c.redComponent,c.greenComponent,c.blueComponent)<0.92 {
   x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
  }
 }}
 let padding=8
 let sx=Double(image.width)/Double(sample.width),sy=Double(image.height)/Double(sample.height)
 let box=CGRect(x:Double(max(0,x0-padding))*sx,y:Double(max(0,y0-padding))*sy,width:Double(min(sample.width,x1+padding)-max(0,x0-padding))*sx,height:Double(min(sample.height,y1+padding)-max(0,y0-padding))*sy)
 return image.cropping(to:box.integral)!
}
// Raster photographic layer; logo and typography remain sharp PDF elements.
let pw=1800, ph=Int(1800*H/W)
let canvas=CGContext(data:nil,width:pw,height:ph,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
canvas.scaleBy(x:Double(pw)/W,y:Double(ph)/H)
canvas.draw(load(root.appendingPathComponent("cover/collection-background-refined.png")),in:CGRect(x:0,y:0,width:W,height:H))
let rowCounts=[7,7,7,6]
var index=0
for (row,count) in rowCounts.enumerated() {
 let pitch=W*0.119
 let baseline=H*(1-(0.475+Double(row)*0.145))
 for column in 0..<count {
  let p=products[index];index+=1
  let image=productImage(workspace.appendingPathComponent(p.source))
  let cellWidth=pitch*0.91, maxHeight=H*0.128
  let scale=min(cellWidth/Double(image.width),maxHeight/Double(image.height))
  let width=Double(image.width)*scale,height=Double(image.height)*scale
  let center=W/2+(Double(column)-Double(count-1)/2)*pitch
  canvas.saveGState();canvas.setBlendMode(.multiply)
  canvas.draw(image,in:CGRect(x:center-width/2,y:baseline,width:width,height:height))
  canvas.restoreGState()
 }
}
precondition(index==27)
let bitmap=NSBitmapImageRep(cgImage:canvas.makeImage()!)
let photo=root.appendingPathComponent("cover/collection-layout.jpg")
try bitmap.representation(using:.jpeg,properties:[.compressionFactor:0.94])!.write(to:photo)
var media=CGRect(x:0,y:0,width:W,height:H)
let out=root.appendingPathComponent("Himalaya-Cover-A4.pdf")
let ctx=CGContext(out as CFURL,mediaBox:&media,nil)!
ctx.beginPDFPage(nil)
ctx.draw(load(photo,max:1800),in:media)
let logo=load(root.appendingPathComponent("cover/himalaya-logo.png"),max:1600)
let lw=W*0.43,lh=lw*Double(logo.height)/Double(logo.width)
ctx.draw(logo,in:CGRect(x:(W-lw)/2,y:H*(1-0.065)-lh,width:lw,height:lh))
func title(_ text:String,top:Double,font:String,size:Double,tracking:Double=0) {
 let line=CTLineCreateWithAttributedString(NSAttributedString(string:text,attributes:[.font:NSFont(name:font,size:size)!, .foregroundColor:NSColor(srgbRed:1.0/255,green:99.0/255,blue:105.0/255,alpha:1),.kern:tracking]))
 let bounds=CTLineGetBoundsWithOptions(line,.useGlyphPathBounds)
 precondition(bounds.width<W*0.88)
 ctx.textMatrix = .identity
 ctx.textPosition=CGPoint(x:(W-bounds.width)/2-bounds.minX,y:H-top*H-bounds.maxY)
 CTLineDraw(line,ctx)
}
title("PRODUCT PORTFOLIO",top:0.222,font:"GothamCondensed-Medium",size:53,tracking:1)
title("SKIN CARE  ·  HAIR CARE  ·  LIP CARE",top:0.295,font:"MyriadPro-Regular",size:10,tracking:1.2)
ctx.endPDFPage();ctx.closePDF()
let pdf=PDFDocument(url:out)!
let preview=pdf.page(at:0)!.thumbnail(of:NSSize(width:1050,height:1485),for:.mediaBox)
let previewBitmap=NSBitmapImageRep(data:preview.tiffRepresentation!)!
try previewBitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("cover/preview.png"))
print("Built A4 cover with Himalaya logo and all 27 unique products.")
