import sys, json
P = sys.argv[1] + '/project/'
O = '#3A2A20'
HEAD = ('<svg role="img" aria-label="Puggle the platypus" width="{w}" height="{h}" viewBox="36 34 168 150">'
  '<ellipse cx="120" cy="108" rx="70" ry="60" fill="#8A5A3C" stroke="#3A2A20" stroke-width="7"></ellipse>'
  '<circle cx="64" cy="116" r="10" fill="#EE9C88"></circle><circle cx="176" cy="116" r="10" fill="#EE9C88"></circle>'
  '<ellipse cx="120" cy="146" rx="54" ry="25" fill="#6E7F8D" stroke="#3A2A20" stroke-width="6"></ellipse>'
  '<circle cx="110" cy="136" r="3" fill="#3A2A20"></circle><circle cx="130" cy="136" r="3" fill="#3A2A20"></circle>'
  '<circle cx="90" cy="98" r="6.500" fill="#3A2A20"></circle><circle cx="150" cy="98" r="6.500" fill="#3A2A20"></circle></svg>')
def w(px, wdth=100, wght=800, ls='-0.04em', color=O, extra=''):
    return (f'<div style="font-family: \'Bricolage Grotesque\', system-ui, sans-serif; font-weight: {wght}; font-stretch: {wdth}%; font-variation-settings: \'opsz\' 96, \'wdth\' {wdth}; '
            f'letter-spacing: {ls}; font-size: {px}px; line-height: 1; color: {color}{extra}">')
variants = [
 ('E1. As set', 'ExtraBold, normal width, tight', w(76) + 'puggle</div>'),
 ('E2. Condensed', 'ExtraBold at 75% width. Taller and more fashion-label', w(88, 75, ls='-0.03em') + 'puggle</div>'),
 ('E3. Two-tone gg', 'The double g picked out in the accent: a small, ownable detail', w(76) + 'pu<span style="color: #C24A36">gg</span>le</div>'),
]
cards = ''.join(f'<div style="display: flex; flex-direction: column; gap: 10px"><div style="width: 310px; height: 150px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">{html}</div>'
                f'<div style="font-size: 16px; font-weight: 800">{t}</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30">{n}</div></div>' for t, n, html in variants)
lock = (f'<div style="display: flex; gap: 30px; align-items: center">'
  f'<div style="width: 400px; height: 150px; background: #F4BE2C; display: flex; align-items: center; justify-content: center; gap: 16px">{HEAD.format(w=88, h=79)}{w(80)}puggle</div></div>'
  f'<div style="width: 220px; height: 150px; background: #0F1326; display: flex; align-items: center; justify-content: center">{w(52, color="#F3E0B8")}puggle</div></div>'
  f'<div style="width: 190px; height: 90px; display: flex; align-items: center; justify-content: center"><div style="width: 176px; height: 64px; background: #FBF6E9; border: 2px dashed #C9B89F; outline: 6px solid {O}; display: flex; align-items: center; justify-content: center">{w(40, 75, ls="-0.03em")}puggle</div></div></div>'
  f'<div style="width: 120px; height: 120px; border-radius: 28px; background: #2A62B8; display: flex; align-items: center; justify-content: center">{w(96, color="#FBF6E9", extra="; padding-bottom: 14px")}p</div></div>'
  f'</div>')
typesys = (f'<div style="display: flex; gap: 40px; align-items: flex-end">'
  f'<div style="display: flex; flex-direction: column; gap: 4px">{w(40, ls="-0.02em")}One down, one to go.</div><div style="font-size: 13px; font-weight: 600; color: #4A3B30">Headlines: Bricolage Grotesque ExtraBold</div></div>'
  f'<div style="display: flex; flex-direction: column; gap: 4px"><div style="font-family: -apple-system, \'SF Pro Text\', system-ui, sans-serif; font-size: 17px; font-weight: 600; color: {O}">Last bottle 150 ml at 12:15</div><div style="font-size: 13px; font-weight: 600; color: #4A3B30">Interface: the iOS system font, for Dynamic Type</div></div></div>')
body = f'''<div style="width: 1080px; height: 650px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Logotype E, refined</h1>
<div style="display: flex; gap: 34px">{cards}</div>
{lock}
{typesys}
</div>'''
link = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">'
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/logo3.html', 'w').write('<head>' + link + '</head><body style="margin:0">' + body + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Logotype E, refined</title>
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
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":650}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'LogotypeE.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['LogotypeE.dc.html'] = {'x': 0, 'y': 9540, 'w': 1080, 'h': 650, 'title': 'Logotype E, refined'}
if 'LogotypeE.dc.html' not in c['order']: c['order'].append('LogotypeE.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'))
