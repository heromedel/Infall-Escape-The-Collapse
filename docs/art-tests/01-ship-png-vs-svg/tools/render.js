// Usage: node render.js in.svg out.png [scale]
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }
const fs = require('fs');
(async () => {
  const [, , input, output, scale = '1'] = process.argv;
  const svg = fs.readFileSync(input, 'utf8');
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: Number(scale) });
  await page.setContent(`<html><body style="margin:0;background:#ececec">${svg}</body></html>`);
  await page.locator('svg').screenshot({ path: output });
  await browser.close();
})();
