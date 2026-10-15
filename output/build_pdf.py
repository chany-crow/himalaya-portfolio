from pathlib import Path
from io import BytesIO
from PIL import Image

root = Path(__file__).resolve().parent
files = sorted(root.glob('[0-9][0-9]-*.png'))
assert len(files) == 3, 'Expected all three product pages'
w, h = 210 / 25.4 * 72, 297 / 25.4 * 72
margin = 10 / 25.4 * 72
objects = [b'<< /Type /Catalog /Pages 2 0 R >>', b'']
objects.append(b'<< /Type /Font /Subtype /Type1 /BaseFont /Times-Roman >>')
pages = []
for path in files:
    im = Image.open(path).convert('RGB')
    buffer = BytesIO()
    im.save(buffer, format='JPEG', quality=98, subsampling=0)
    data = buffer.getvalue()
    page_id = len(objects) + 1
    pages.append(page_id)
    image_id, content_id = page_id + 1, page_id + 2
    scale = max((w - 2 * margin) / im.width, (h - 2 * margin) / im.height)
    iw, ih = im.width * scale, im.height * scale
    command = f'q {margin:.5f} {margin:.5f} {w-2*margin:.5f} {h-2*margin:.5f} re W n {iw:.5f} 0 0 {ih:.5f} {(w-iw)/2:.5f} {(h-ih)/2:.5f} cm /Im0 Do Q'.encode()
    if 'serum' in path.name:
        tx, ty = (w-iw)/2 + iw*0.80, (h-ih)/2 + ih*0.56
        command += f'\nq 0.40 0.08 0.02 rg BT /F1 19 Tf 1 0 0 1 {tx:.5f} {ty:.5f} Tm (LKR 965) Tj /F1 13 Tf 0 -19 Td (15 ml) Tj ET Q'.encode()
    objects.append(f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {w:.6f} {h:.6f}] /Resources << /Font << /F1 3 0 R >> /XObject << /Im0 {image_id} 0 R >> >> /Contents {content_id} 0 R >>'.encode())
    objects.append(f'<< /Type /XObject /Subtype /Image /Width {im.width} /Height {im.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length {len(data)} >>\nstream\n'.encode() + data + b'\nendstream')
    objects.append(f'<< /Length {len(command)} >>\nstream\n'.encode() + command + b'\nendstream')
objects[1] = ('<< /Type /Pages /Kids [' + ' '.join(f'{p} 0 R' for p in pages) + f'] /Count {len(pages)} >>').encode()
pdf = bytearray(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')
offsets = [0]
for i, obj in enumerate(objects, 1):
    offsets.append(len(pdf))
    pdf.extend(f'{i} 0 obj\n'.encode() + obj + b'\nendobj\n')
xref = len(pdf)
pdf.extend(f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode())
for offset in offsets[1:]:
    pdf.extend(f'{offset:010} 00000 n \n'.encode())
pdf.extend(f'trailer\n<< /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode())
out = root / 'Himalaya-Vitamin-C-Portfolio-A4.pdf'
out.write_bytes(pdf)
print(f'{out}: {len(pages)} pages, 210 x 297 mm, {len(pdf):,} bytes')
