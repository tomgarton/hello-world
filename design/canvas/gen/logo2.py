import sys, json
P = sys.argv[1] + '/project/'
O = '#3A2A20'
HEAD = ('<svg role="img" aria-label="Puggle the platypus" width="{w}" height="{h}" viewBox="36 34 168 150">'
  '<ellipse cx="120" cy="108" rx="70" ry="60" fill="#8A5A3C" stroke="#3A2A20" stroke-width="7"></ellipse>'
  '<circle cx="64" cy="116" r="10" fill="#EE9C88"></circle><circle cx="176" cy="116" r="10" fill="#EE9C88"></circle>'
  '<ellipse cx="120" cy="146" rx="54" ry="25" fill="#6E7F8D" stroke="#3A2A20" stroke-width="6"></ellipse>'
  '<circle cx="110" cy="136" r="3" fill="#3A2A20"></circle><circle cx="130" cy="136" r="3" fill="#3A2A20"></circle>'
  '<circle cx="90" cy="98" r="6.500" fill="#3A2A20"></circle><circle cx="150" cy="98" r="6.500" fill="#3A2A20"></circle></svg>')
opts = [
 ('A', 'Bagel Fat One', 400, '0', 1.0, '#F4BE2C'),
 ('D', 'Climate Crisis', 400, '0', 0.58, '#3C9A5F'),
 ('E', 'Bricolage Grotesque', 800, '-0.04em', 1.0, '#F3D9C9'),
 ('F', 'Gasoek One', 400, '0', 0.74, '#BFD9F5'),
]
fam = '&'.join('family=' + f[1].replace(' ', '+') + (':opsz,wght@12..96,800' if f[1] == 'Bricolage Grotesque' else '') for f in opts)
def t(font, w, ls, px, color, extra=''):
    return f'<div style="font-family: \'{font}\', system-ui, sans-serif; font-weight: {w}; letter-spacing: {ls}; font-size: {px}px; line-height: 1; color: {color}{extra}">'
rows = ''
for key, font, w, ls, k, bg in opts:
    fg = '#FBF6E9' if key == 'D' else O
    rows += (f'<div style="display: flex; align-items: center; gap: 26px">'
      f'<div style="width: 34px; font-size: 26px; font-weight: 800">{key}</div>'
      f'<div style="width: 360px; height: 128px; background: {bg}; display: flex; align-items: center; justify-content: center; gap: 14px">{HEAD.format(w=80, h=71)}{t(font, w, ls, round(74*k), fg)}puggle</div></div>'
      f'<div style="width: 190px; height: 128px; display: flex; align-items: center; justify-content: center"><div style="width: 176px; height: 64px; background: #FBF6E9; border: 2px dashed #C9B89F; outline: 6px solid {O}; display: flex; align-items: center; justify-content: center">{t(font, w, ls, round(38*k), O)}puggle</div></div></div>'
      f'<div style="width: 110px; height: 110px; border-radius: 26px; background: {O}; display: flex; align-items: center; justify-content: center">{t(font, w, "0", round(72*min(1, k*1.3)), "#F4BE2C", "; padding-bottom: 8px")}p</div></div>'
      f'<div style="width: 200px; height: 110px; border-radius: 22px; background: #0F1326; display: flex; flex-direction: column; justify-content: center; padding: 0 18px; box-sizing: border-box; gap: 6px">{t(font, w, ls, round(30*k), "#F3E0B8")}puggle</div><div style="font-family: \'Bricolage Grotesque\', system-ui, sans-serif; font-size: 13px; font-weight: 600; color: #D5CEC0">Wednesday, 2:10 am</div></div>'
      f'</div>')
body = f'''<div style="width: 1080px; height: 760px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Logotype shortlist in use</h1>
<div style="display: flex; gap: 26px; padding-left: 60px; font-size: 14px; font-weight: 700; color: #4A3B30"><div style="width: 360px">Lockup</div><div style="width: 190px">Woven label</div><div style="width: 110px">Icon</div><div style="width: 200px">App header at night</div></div>
{rows}
</div>'''
link = f'<link rel="stylesheet" href="https://fonts.googleapis.com/css2?{fam}&display=swap">'
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/logo2.html', 'w').write('<head>' + link + '</head><body style="margin:0">' + body + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Logotype shortlist in use</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{link}
<style>
body{{margin:0}}
a{{color:#2A1F18}}a:hover{{color:#5A4636}}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":760}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'LogotypeShortlist.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['LogotypeShortlist.dc.html'] = {'x': 0, 'y': 8660, 'w': 1080, 'h': 760, 'title': 'Logotype shortlist in use'}
if 'LogotypeShortlist.dc.html' not in c['order']: c['order'].append('LogotypeShortlist.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'))
