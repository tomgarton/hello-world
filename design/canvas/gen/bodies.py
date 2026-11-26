import math, sys, json
P = sys.argv[1] + '/project/'
O = '#3A2A20'; FUR = '#9B6B43'; SPINE = '#F3E3C3'; SN = '#CFA277'; ST = '#D9614C'
def spines(cx, cy, r0, r1, a0, step, n, ky=0.92, w=0.26):
    s = ''
    for i in range(n):
        a = math.radians(a0 + i * step)
        pt = lambda r, da=0: f'{cx + r * math.cos(a + da):.1f} {cy + r * ky * math.sin(a + da):.1f}'
        s += f'<path d="M{pt(r0, -w)}L{pt(r1)}L{pt(r0, w)}z" fill="{SPINE}" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>'
    return s
def stitches(y=124, dx=58):
    s = ''
    for sx in (120 - dx, 120 + dx - 14):
        s += f'<path d="M{sx} {y+10}l6-10M{sx+10} {y+10}l6-10" fill="none" stroke="{ST}" stroke-width="4.500" stroke-linecap="round"></path>'
    return s
def eyes(y, dx=33, shut=False):
    if shut: return ''.join(f'<path d="M{x-9} {y}q9 8 18 0" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>' for x in (120-dx, 120+dx))
    return ''.join(f'<circle cx="{x}" cy="{y}" r="6.500" fill="{O}"></circle>' for x in (120-dx, 120+dx))
def head(shut=False):
    return (spines(120, 110, 58, 104, 198, 20.6, 8) + f'<ellipse cx="120" cy="110" rx="72" ry="62" fill="{FUR}" stroke="{O}" stroke-width="7"></ellipse>' + stitches() +
        f'<path d="M106 110Q120 98 134 110L128 168Q120 178 112 168z" fill="{SN}" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path><ellipse cx="120" cy="169" rx="7" ry="5" fill="{O}"></ellipse>' + eyes(104, shut=shut))
def arm(side, angle, j):
    sx = 92 if side < 0 else 148
    return (f'<g transform="rotate({angle} {sx} 176)"><rect x="{sx-12}" y="170" width="24" height="52" rx="12" fill="{j}" stroke="{O}" stroke-width="6"></rect>'
            f'<circle cx="{sx}" cy="226" r="10" fill="{FUR}" stroke="{O}" stroke-width="5"></circle></g>')
def garment(j, hem=254):
    return (f'<path d="M88 166Q120 156 152 166L180 {hem-10}Q182 {hem} 170 {hem}L70 {hem}Q58 {hem} 60 {hem-10}Z" fill="{j}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
            f'<path d="M98 {hem-44}h44v10a22 18 0 0 1-44 0z" fill="none" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>')
def svg(inner, size, label, vb='0 0 240 300'):
    w, h = [float(x) for x in vb.split()[2:]]
    return f'<svg role="img" aria-label="{label}" width="{size}" height="{size*h/w:.0f}" viewBox="{vb}">{inner}</svg>'
def stand(size, j='#2A62B8', wave=False):
    legs = ''.join(f'<rect x="{x}" y="244" width="20" height="34" rx="9" fill="{FUR}" stroke="{O}" stroke-width="6"></rect><ellipse cx="{x+10}" cy="282" rx="18" ry="9" fill="{FUR}" stroke="{O}" stroke-width="6"></ellipse>' for x in (90, 130))
    left = arm(-1, 42, j); right = arm(1, -42, j)
    if wave:
        return svg(legs + garment(j) + left + head() + arm(1, -122, j), size, 'Puggle waving')
    return svg(legs + garment(j) + left + right + head(), size, 'Puggle waving' if wave else 'Puggle standing')
def sit(size, j='#F4BE2C'):
    feet = ''.join(f'<ellipse cx="{x}" cy="246" rx="19" ry="15" fill="{FUR}" stroke="{O}" stroke-width="6"></ellipse>' for x in (84, 156))
    return svg(garment(j, 246) + arm(-1, 46, j) + arm(1, -46, j) + feet + head(), size, 'Baby puggle sitting', '0 0 240 272')
def ball(size):
    inner = (spines(120, 120, 70, 112, 150, 20, 13, ky=1, w=0.2) + f'<circle cx="120" cy="120" r="78" fill="{FUR}" stroke="{O}" stroke-width="7"></circle>' +
        stitches(134, 56) + eyes(118, 30, shut=True) + f'<path d="M110 128Q120 120 130 128L126 160Q120 168 114 160z" fill="{SN}" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path><ellipse cx="120" cy="161" rx="6" ry="4.500" fill="{O}"></ellipse>')
    return svg(inner, size, 'Puggle asleep, curled into a ball', '0 0 240 210')
def koala(size, mark):
    f = '#A9B0B8'
    ears = ''.join(f'<circle cx="{x}" cy="72" r="34" fill="{f}" stroke="{O}" stroke-width="7"></circle><circle cx="{x}" cy="72" r="17" fill="#F0DAD6"></circle>' for x in (54, 186))
    m = {'stitch': stitches(126, 56),
         'freckle': ''.join(f'<circle cx="{x+dx}" cy="{132+dy}" r="3" fill="{O}"></circle>' for x in (70, 170) for dx, dy in ((-8, 0), (0, -6), (8, 0))),
         'mouth': stitches(126, 56) + f'<path d="M110 150q10 9 20 0" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'}[mark]
    return svg(ears + f'<ellipse cx="120" cy="112" rx="68" ry="62" fill="{f}" stroke="{O}" stroke-width="7"></ellipse>' + m + f'<ellipse cx="120" cy="120" rx="14" ry="20" fill="{O}"></ellipse>' + eyes(102, 34), size, 'Koala face, option ' + mark, '14 28 212 152')

def panel(bg, inner, name, w=220, h=230):
    return (f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: {w}px; height: {h}px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 12px; box-sizing: border-box">{inner}</div>'
            f'<div style="font-size: 15px; font-weight: 700">{name}</div></div>')
row1 = (panel('#F4BE2C', stand(160), 'Standing') + panel('#CFE5D2', stand(160, '#E5553B', wave=True), 'Waving') +
        panel('#BFD9F5', sit(170), 'Sitting, for babies') + panel('#1B2440', ball(170), 'Asleep, curled into a ball'))
row2 = (panel('#FBF6E9', koala(150, 'stitch'), 'A. Stitched cheeks, no mouth', 220, 130) + panel('#FBF6E9', koala(150, 'freckle'), 'B. Freckles, no mouth', 220, 130) +
        panel('#FBF6E9', koala(150, 'mouth'), 'C. Stitched cheeks, small smile', 220, 130))
body = f'''<div style="width: 1080px; height: 620px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 44px 48px; display: flex; flex-direction: column; gap: 26px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Bodies, poses and a signature mark</h1>
<div style="display: flex; gap: 34px">
{row1}
</div>
<div style="display: flex; gap: 34px">
{row2}
</div>
</div>'''
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/bodies.html', 'w').write('<body style="margin:0">' + body.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Bodies, poses and a signature mark</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&display=swap">
<style>
body{{margin:0}}
a{{color:#2A1F18}}a:hover{{color:#5A4636}}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":620}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'CharacterBodies.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['CharacterBodies.dc.html'] = {'x': 0, 'y': 6220, 'w': 1080, 'h': 620, 'title': 'Bodies, poses and a signature mark'}
if 'CharacterBodies.dc.html' not in c['order']: c['order'].append('CharacterBodies.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'), html.count('<g ') == html.count('</g>'))
