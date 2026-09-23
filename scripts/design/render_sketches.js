// Renders the SVGs from extract_sketches.py to transparent PNGs @2x/@3x with Playwright's Chromium
// (the "wobble" SVG filter is frozen at export, as the handoff requires).
// Usage (from the output dir of extract_sketches.py): NODE_PATH=$(npm root -g) node render_sketches.js
const { chromium } = require('playwright');
const fs = require('fs');
fs.mkdirSync('png', { recursive: true });
const meta = JSON.parse(fs.readFileSync('meta.json'));
(async () => {
  const browser = await chromium.launch();
  for (const scale of [2, 3]) {
    const page = await browser.newPage({ deviceScaleFactor: scale });
    for (const [name, [w, h]] of Object.entries(meta)) {
      const svg = fs.readFileSync(`svg/${name}.svg`, 'utf8');
      await page.setViewportSize({ width: w, height: h });
      await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
      await page.locator('svg').first().screenshot({ path: `png/${name}@${scale}x.png`, omitBackground: true });
    }
    await page.close();
  }
  await browser.close();
})();
