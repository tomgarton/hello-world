const { chromium } = require('playwright');
(async () => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1420 } });
  await p.goto('file://' + process.cwd() + '/IconSystem3.html', { waitUntil: 'networkidle' }); await p.waitForTimeout(800); await p.screenshot({ path: 'IconSystem3.png' }); await b.close(); })();
