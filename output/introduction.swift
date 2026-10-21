import AppKit
import PDFKit
import ImageIO
let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent()
var media=CGRect(x:0,y:0,width:210.0/25.4*72,height:297.0/25.4*72)
let ctx=CGContext(root.appendingPathComponent("Himalaya-Introduction-A4.pdf") as CFURL,mediaBox:&media,nil)!
for n in 1...3 {
 let source=CGImageSourceCreateWithURL(root.appendingPathComponent("introduction/page-\(n).png") as CFURL,nil)!
 let original=CGImageSourceCreateImageAtIndex(source,0,nil)!
 let bitmap=NSBitmapImageRep(cgImage:original)
 let jpeg=bitmap.representation(using:.jpeg,properties:[.compressionFactor:0.97])!
 let image=CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(jpeg as CFData,nil)!,0,nil)!
 ctx.beginPDFPage(nil)
 ctx.draw(image,in:media)
 ctx.endPDFPage()
}
ctx.closePDF()
print("Built three A4 pages from the supplied finished artwork.")
