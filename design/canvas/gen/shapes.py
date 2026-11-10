import sys, json, math
P = sys.argv[1] + '/project/'
O = '#3A2A20'
def shapes(c):
    # each shape in a 100x100 box; returns list of (name, svg inner)
    q = ''.join(f'<circle cx="{50+dx}" cy="{50+dy}" r="24" fill="{c}"></circle>' for dx, dy in ((-20,0),(20,0),(0,-20),(0,20))) + f'<rect x="30" y="30" width="40" height="40" fill="{c}"></rect>'
    hexpts = ' '.join(f'{50+44*math.cos(math.radians(60*i)):.1f},{50+40*math.sin(math.radians(60*i)):.1f}' for i in range(6))
    scal = f'<path d="M6 80V52a14 14 0 0 1 29 0a14 14 0 0 1 30 0a14 14 0 0 1 29 0V80Z" fill="{c}"></path>'
    flower = ''.join(f'<circle cx="{50+22*math.cos(math.radians(72*i-90)):.1f}" cy="{50+22*math.sin(math.radians(72*i-90)):.1f}" r="20" fill="{c}"></circle>' for i in range(5)) + f'<circle cx="50" cy="50" r="22" fill="{c}"></circle>'
    return [
     ('Quatrefoil', q),
     ('Pill', f'<rect x="4" y="30" width="92" height="40" rx="20" fill="{c}"></rect>'),
     ('Scallop', scal),
     ('Soft square', f'<rect x="10" y="10" width="80" height="80" rx="22" fill="{c}"></rect>'),
     ('Soft hexagon', f'<polygon points="{hexpts}" fill="{c}" stroke="{c}" stroke-width="14" stroke-linejoin="round"></polygon>'),
     ('Pebble', f'<path d="M50 12C78 12 92 30 90 54S70 90 46 88S8 72 10 48S24 12 50 12Z" fill="{c}"></path>'),
     ('Half pill', f'<path d="M8 22H58a28 28 0 0 1 0 56H8Z" fill="{c}"></path>'),
     ('Blossom', flower),
    ]
cols = ['#C24A36', '#BFD9F5', '#F4BE2C', '#3C9A5F', '#E5553B', '#8A5A3C', '#2A62B8', '#F3D9C9']
row = ''
for (name, inner), col in zip(shapes('X'), cols):
    inner = inner.replace('"X"', f'"{col}"')
    row += (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 8px"><svg role="img" aria-label="{name}" width="96" height="96" viewBox="0 0 100 100">{inner}</svg>'
            f'<div style="font-size: 13px; font-weight: 700">{name}</div></div>')
mono = ''.join(f'<svg aria-hidden="true" width="56" height="56" viewBox="0 0 100 100">{inner.replace(chr(34)+"X"+chr(34), chr(34)+O+chr(34))}</svg>' for name, inner in shapes('X'))
# pattern strip
seq = shapes('X'); strip = ''
pc = ['#F4BE2C', '#BFD9F5', '#C24A36', '#3C9A5F', '#F3D9C9']
for i in range(14):
    n, inner = seq[i % len(seq)]
    strip += f'<g transform="translate({i*72} {(i%2)*30}) scale(0.62)">{inner.replace(chr(34)+"X"+chr(34), chr(34)+pc[i % len(pc)]+chr(34))}</g>'
body = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #FBF6E9; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Soft shapes</h1>
<div style="display: flex; justify-content: space-between">{row}</div>
<div style="display: flex; align-items: center; gap: 18px"><div style="font-size: 14px; font-weight: 800; width: 90px">Mono</div><div style="display: flex; gap: 22px">{mono}</div></div>
<svg role="img" aria-label="Repeat pattern of the soft shapes" width="984" height="100" viewBox="0 0 984 100" style="background: #2A62B8">{strip}</svg>
<div style="display: flex; gap: 20px; align-items: center">
<div style="display: flex; align-items: center; gap: 0; font-size: 64px; font-weight: 800; letter-spacing: -0.04em; color: {O}">puggle<svg aria-hidden="true" width="40" height="40" viewBox="0 0 100 100" style="margin-left: 6px">{shapes('#C24A36')[0][1]}</svg></div>
<div style="font-size: 14px; font-weight: 500; color: #4A3B30; max-width: 440px; line-height: 1.4">Uses: pattern for fabric and app backgrounds, sticker shapes on the potty chart, buttons and chips, and a mark after the logotype in place of a full stop.</div>
</div>
</div>'''
link = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">'
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/shapes.html', 'w').write('<head>' + link + '</head><body style="margin:0">' + body.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Soft shapes</title>
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
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":640}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'Shapes.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['Shapes.dc.html'] = {'x': 0, 'y': 11070, 'w': 1080, 'h': 640, 'title': 'Soft shapes'}
if 'Shapes.dc.html' not in c['order']: c['order'].append('Shapes.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'), html.count('<g ') == html.count('</g>'))
