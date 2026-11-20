import sys, json
ROOT = sys.argv[1]; P = ROOT + '/project/'
rs = open(ROOT + '/gen/refined.py').read(); rs = rs[:rs.index('# --- components sheet')]
x = {}; exec(rs, x)
head, clip, page, FONT, D, SAND, INK = [x[k] for k in ('head', 'clip', 'page', 'FONT', 'D', 'SAND', 'INK')]
inner = f'''<div style="width: 390px; height: 844px; box-sizing: border-box; background: {SAND}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 14px">
<div style="width: 132px; height: 132px; border-radius: 30px; background: #F4BE2C; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="Puggle" width="120" height="108" viewBox="40 34 160 146">{head("happy") + clip(160, 56, "#E5553B")}</svg></div>
<div style="{D}; font-size: 44px; font-weight: 800; letter-spacing: -0.04em; color: {INK}">puggle</div>
</div>'''
html = page('Splash', inner)
open(P + 'Splash.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['Splash.dc.html'] = {'x': 1880, 'y': 26600, 'w': 390, 'h': 844, 'title': 'Splash: the only in-app use of the name', 'radius': 44}
if 'Splash.dc.html' not in c['order']: c['order'].append('Splash.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print('ok')
