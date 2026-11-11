const { chromium } = require('playwright');
(async () => { const b = await chromium.launch();
  for (const [n, dur] of [['hooray_snap', 1.3], ['wave_snap', 2.0], ['nod', 0.5]]) {
    const p = await b.newPage({ viewport: { width: 290, height: 354 } });
    await p.goto('file://' + process.cwd() + '/strip_' + n + '.html');
    for (let i = 0; i < 12; i++) { await p.evaluate(t => { const s = document.getElementById('s'); s.pauseAnimations(); s.setCurrentTime(t); }, dur * i / 12); await p.screenshot({ path: `f_${n}_${i}.png` }); }
    await p.close(); }
  await b.close(); })();
