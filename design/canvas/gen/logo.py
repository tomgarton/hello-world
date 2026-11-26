import sys, json
sys.path.insert(0, sys.argv[1] + '/gen')
P = sys.argv[1] + '/project/'
import importlib.util
spec = importlib.util.spec_from_file_location('platy', sys.argv[1] + '/gen/platy.py')
O = '#3A2A20'
opts = [
 ('Bagel Fat One', "'Bagel Fat One'", 400, '#F4BE2C', O, 'A. Bagel Fat One', 'Puffy and soft-cornered. The friendliest; closest to a toy or a sweet wrapper', '0'),
 ('Dela Gothic One', "'Dela Gothic One'", 400, '#E5553B', '#FBF6E9', 'B. Dela Gothic One', 'Heavy, squared, slightly Japanese-poster. Graphic and fashion-led', '0'),
 ('Rubik Mono One', "'Rubik Mono One'", 400, '#2A62B8', '#FBF6E9', 'C. Rubik Mono One', 'Wide, geometric, all caps only. Bold on a tag; less warm', '0'),
 ('Climate Crisis', "'Climate Crisis'", 400, '#3C9A5F', '#FBF6E9', 'D. Climate Crisis', 'Ultra-heavy, tight. Loudest; risks feeling aggressive for babies', '0'),
 ('Bricolage Grotesque', "'Bricolage Grotesque'", 800, '#F3D9C9', O, 'E. Bricolage Grotesque ExtraBold', 'Quirky grotesque with ink traps. Matches the app type already in the mockups', '-0.04em'),
 ('Gasoek One', "'Gasoek One'", 400, '#BFD9F5', O, 'F. Gasoek One', 'Very heavy with rounded counters. Blocky but still cheerful', '0'),
]
fam = '&'.join('family=' + f[0].replace(' ', '+') + (':opsz,wght@12..96,800' if f[0] == 'Bricolage Grotesque' else '') for f in opts)
cards = ''
for name, css, w, bg, fg, title, note, ls in opts:
    word = 'PUGGLE' if name == 'Rubik Mono One' else 'puggle'
    size = {'Bagel Fat One': 84, 'Dela Gothic One': 64, 'Rubik Mono One': 50, 'Climate Crisis': 48, 'Bricolage Grotesque': 84, 'Gasoek One': 62}[name]
    cards += (f'<div style="display: flex; flex-direction: column; gap: 10px">'
              f'<div style="width: 310px; height: 170px; background: {bg}; display: flex; align-items: center; justify-content: center"><div style="font-family: {css}, system-ui, sans-serif; font-weight: {w}; font-size: {size}px; line-height: 1; letter-spacing: {ls}; color: {fg}">{word}</div></div>'
              f'<div style="font-size: 16px; font-weight: 800">{title}</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.35; max-width: 310px">{note}</div></div>')
O2 = '#3A2A20'
HEAD = ('<svg role="img" aria-label="Puggle the platypus" width="{w}" height="{h}" viewBox="36 34 168 150">'
  '<ellipse cx="120" cy="108" rx="70" ry="60" fill="#8A5A3C" stroke="#3A2A20" stroke-width="7"></ellipse>'
  '<circle cx="64" cy="116" r="10" fill="#EE9C88"></circle><circle cx="176" cy="116" r="10" fill="#EE9C88"></circle>'
  '<ellipse cx="120" cy="146" rx="54" ry="25" fill="#6E7F8D" stroke="#3A2A20" stroke-width="6"></ellipse>'
  '<circle cx="110" cy="136" r="3" fill="#3A2A20"></circle><circle cx="130" cy="136" r="3" fill="#3A2A20"></circle>'
  '<circle cx="90" cy="98" r="6.500" fill="#3A2A20"></circle><circle cx="150" cy="98" r="6.500" fill="#3A2A20"></circle></svg>')
lock = ('<div style="display: flex; gap: 34px; align-items: stretch">'
  '<div style="width: 480px; height: 150px; background: #F4BE2C; display: flex; align-items: center; justify-content: center; gap: 18px">' + HEAD.format(w=104, h=93) +
  '<div style="font-family: \'Bagel Fat One\', system-ui, sans-serif; font-size: 88px; line-height: 1; color: #3A2A20">puggle</div></div>'
  '<div style="width: 220px; height: 150px; display: flex; align-items: center; justify-content: center"><div style="width: 200px; height: 74px; background: #FBF6E9; border: 2px dashed #C9B89F; outline: 6px solid #3A2A20; display: flex; align-items: center; justify-content: center; font-family: \'Bagel Fat One\', system-ui, sans-serif; font-size: 44px; color: #3A2A20">puggle</div></div>'
  '<div style="width: 150px; height: 150px; border-radius: 34px; background: #3A2A20; display: flex; align-items: center; justify-content: center; font-family: \'Bagel Fat One\', system-ui, sans-serif; font-size: 92px; line-height: 1; color: #F4BE2C; padding-bottom: 10px; box-sizing: border-box">p</div>'
  '</div><div style="font-size: 14px; font-weight: 600; color: #4A3B30">A in use: lockup with Puggle, a woven clothing label, and a letter-only icon</div>')
body = f'''<div style="width: 1080px; height: 900px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 44px 48px; display: flex; flex-direction: column; gap: 28px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Logotype: bold and blocky</h1>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 24px 34px">
{cards}
</div>
{lock}
</div>'''
link = f'<link rel="stylesheet" href="https://fonts.googleapis.com/css2?{fam}&display=swap">'
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/logo.html', 'w').write('<head>' + link + '</head><body style="margin:0">' + body + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Logotype options</title>
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
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":900}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'Logotype.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['Logotype.dc.html'] = {'x': 0, 'y': 7740, 'w': 1080, 'h': 900, 'title': 'Logotype: bold and blocky'}
if 'Logotype.dc.html' not in c['order']: c['order'].append('Logotype.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'))
