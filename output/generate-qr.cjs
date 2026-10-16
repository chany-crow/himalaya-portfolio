const fs = require('fs');
const path = require('path');
const QRCode = require('./vendor/QRCode');
const levels = require('./vendor/QRCode/QRErrorCorrectLevel');
const products = JSON.parse(fs.readFileSync(path.join(__dirname, 'portfolio-products.json')));
const result = products.map(p => {
  const qr = new QRCode(-1, levels.M);
  qr.addData(p.productURL);
  qr.make();
  return {url: p.productURL, modules: qr.modules};
});
fs.writeFileSync(path.join(__dirname, 'qr-matrices.json'), JSON.stringify(result));
console.log(`Generated ${result.length} product QR matrices`);
