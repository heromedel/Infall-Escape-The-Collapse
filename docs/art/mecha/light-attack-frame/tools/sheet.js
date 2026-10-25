// Lays several SVGs side by side on one background and saves a PNG, for reviewing versions and stages.
// Usage: node sheet.js out.png background height file1.svg[:label] file2.svg[:label] ...
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }
const fs = require('fs');
(async () => {
  const [, , output, background, height, ...items] = process.argv;
  const cells = items.map(item => {
    const [file, label = ''] = item.split(':');
    // each SVG goes in as its own image, so part ids in different files can't collide
    const data = Buffer.from(fs.readFileSync(file, 'utf8')).toString('base64');
    return `<div class="cell"><img style="height:${height}px;display:block" src="data:image/svg+xml;base64,${data}"><div class="label">${label}</div></div>`;
  }).join('');
  const html = `<html><body style="margin:0;background:${background}">
    <style>.row{display:inline-flex;gap:18px;padding:16px;align-items:flex-end}
    .cell{text-align:center}.label{font:13px sans-serif;color:#9aa4b4;margin-top:4px}
    svg{display:block}</style><div class="row">${cells}</div></body></html>`;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 4000, height: 2000 } });
  await page.setContent(html);
  await page.waitForLoadState('networkidle');
  await page.locator('.row').screenshot({ path: output });
  await browser.close();
})();
