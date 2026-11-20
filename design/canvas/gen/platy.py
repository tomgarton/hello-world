import math, sys, json
P = sys.argv[1] + '/project/'
O = '#3A2A20'; PF = '#8A5A3C'; BILL = '#6E7F8D'; EF = '#9B6B43'; SPINE = '#F3E3C3'; SN = '#CFA277'; ST = '#C24A36'; BL = '#EE9C88'
def cheeks(y, dx):
    # soft ovals, no marks at rest (12 November 2026)
    return ''.join(f'<ellipse cx="{x}" cy="{y}" rx="12" ry="7.5" fill="#C27C66"></ellipse>' for x in (120 - dx, 120 + dx))
def eyes(y, dx, shut=False):
    if shut: return ''.join(f'<path d="M{x-8} {y-1}q8 7 16 0" fill="none" stroke="{O}" stroke-width="4.5" stroke-linecap="round"></path>' for x in (120-dx, 120+dx))
    return ''.join(f'<circle cx="{x}" cy="{y}" r="6.8" fill="{O}"></circle>' for x in (120-dx, 120+dx))
def phead(shut=False):
    return (f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>' + cheeks(132, 50) +
        f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>' + eyes(117, 32, shut))
def ehead(shut=False):
    sp = ''
    for i in range(8):
        a = math.radians(198 + i * 20.6)
        pt = lambda r, da=0: f'{120 + r * math.cos(a + da):.1f} {110 + r * 0.92 * math.sin(a + da):.1f}'
        sp += f'<path d="M{pt(58, -0.26)}L{pt(104)}L{pt(58, 0.26)}z" fill="{SPINE}" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>'
    return (sp + f'<ellipse cx="120" cy="110" rx="72" ry="62" fill="{EF}" stroke="{O}" stroke-width="7"></ellipse>' + cheeks(128, 54) +
        f'<path d="M106 110Q120 98 134 110L128 168Q120 178 112 168z" fill="{SN}" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path><ellipse cx="120" cy="169" rx="7" ry="5" fill="{O}"></ellipse>' + eyes(104, 33, shut))
def trap(col, hem=254, flare=28):
    return f'<path d="M88 166Q120 156 152 166L{152+flare} {hem-10}Q{154+flare} {hem} {142+flare} {hem}L{98-flare} {hem}Q{86-flare} {hem} {88-flare} {hem-10}Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
def lighter(c, k=0.5):
    return '#%02X%02X%02X' % tuple(round(int(c[i:i+2], 16) + (255 - int(c[i:i+2], 16)) * k) for i in (1, 3, 5))
def pocket(y, col=None):
    fill = 'none' if not col else ('#8FB4E3' if col.upper() == '#2A62B8' else lighter(col))
    return f'<path d="M100 {y}h40v9a20 16 0 0 1-40 0z" fill="{fill}" stroke="{O}" stroke-width="5" stroke-linejoin="round" data-pocket="1"></path>'
def arm(side, angle, col, hand):
    sx = 92 if side < 0 else 148
    return (f'<g transform="rotate({angle} {sx} 176)"><rect x="{sx-12}" y="170" width="24" height="50" rx="12" fill="{col}" stroke="{O}" stroke-width="6"></rect>'
            f'<circle cx="{sx}" cy="224" r="10" fill="{hand}" stroke="{O}" stroke-width="5"></circle></g>')
def legs(col, y=244):
    return ''.join(f'<rect x="{x}" y="{y}" width="28" height="{278-y}" rx="11" fill="{col}" stroke="{O}" stroke-width="6"></rect>' for x in (86, 126))
def feet(col, y=282):
    # webbed, with toes, each turned out a little
    out = ''
    for cx, rot in ((100, 7), (140, -7)):
        d = (f'M{cx-9} 273 L{cx+9} 273 Q{cx+20} 277 {cx+19} 285 Q{cx+19} 292 {cx+12.5} 291 Q{cx+9.5} 287 {cx+6.3} 291 Q{cx} 294 {cx-6.3} 291 Q{cx-9.5} 287 {cx-12.5} 291 Q{cx-19} 292 {cx-19} 285 Q{cx-20} 277 {cx-9} 273 Z')
        out += (f'<g data-p="foot" transform="translate(0 {y-282}) rotate({rot} {cx} 274)"><path d="{d}" fill="{col}" stroke="{O}" stroke-width="5.5" stroke-linejoin="round"></path>'
                f'<path d="M{cx-6.3} 290 L{cx-4.7} 283 M{cx+6.3} 290 L{cx+4.7} 283" fill="none" stroke="{O}" stroke-width="2.4" stroke-linecap="round" opacity="0.55"></path></g>')
    return out
def tail(col):
    return (f'<g data-p="tail" transform="rotate(-28 184 246)"><ellipse cx="184" cy="246" rx="34" ry="15" fill="{col}" stroke="{O}" stroke-width="6"></ellipse>'
            f'<path d="M176 238 Q180 246 176 254 M191 237 Q196 246 191 255 M170 246 L203 246" fill="none" stroke="{O}" stroke-width="2.5" stroke-linecap="round" opacity="0.5"></path></g>')
def svg(inner, size, label, vb='0 0 240 300'):
    w, h = [float(x) for x in vb.split()[2:]]
    return f'<svg role="img" aria-label="{label}" width="{size}" height="{size*h/w:.0f}" viewBox="{vb}">{inner}</svg>'

def outfit(kind, head, fur, ext, size, label, a=42, shut=False, extra_back=''):
    A = lambda col: arm(-1, a, col, ext) + arm(1, -a, col, ext)
    if kind == 'jumper':
        b = legs(fur) + feet(ext) + trap('#2A62B8') + pocket(210) + A('#2A62B8')
    elif kind == 'dungarees':
        b = (feet(ext, 284) + trap('#FBF6E9', 232, 16) + f'<path d="M72 208H168L174 270H127L120 250L113 270H66Z" fill="#3C9A5F" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
             f'<rect x="97" y="180" width="46" height="34" rx="6" fill="#3C9A5F" stroke="{O}" stroke-width="6"></rect><path d="M100 182L93 164M140 182L147 164" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>' + pocket(190).replace('h40v9a20 16', 'h40v5a20 12') + A('#FBF6E9'))
    elif kind == 'dress':
        b = (legs(fur) + feet(ext) + trap('#E5553B', 254, 42) + f'<path d="M100 164a12 10 0 0 0 20 4a12 10 0 0 0 20-4" fill="#FBF6E9" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>' + pocket(214) + A('#E5553B'))
    elif kind == 'shorts':
        tee = trap('#FBF6E9', 228, 16) + ''.join(f'<path d="M{80-i*3} {186+i*14}H{160+i*3}" stroke="#2A62B8" stroke-width="6"></path>' for i in range(3))
        b = (legs(fur, 250) + feet(ext) + f'<path d="M74 220H166L170 258H127L120 244L113 258H70Z" fill="#F4BE2C" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>' + tee + A('#FBF6E9'))
    elif kind == 'pyjamas':
        b = legs('#BFD9F5') + feet(ext) + trap('#BFD9F5') + ''.join(f'<circle cx="{x}" cy="{y}" r="3.500" fill="#FBF6E9"></circle>' for x, y in ((104, 190), (136, 196), (96, 224), (122, 216), (148, 230), (112, 240))) + A('#BFD9F5')
    return svg(extra_back + b + head(shut), size, label)
def platypus(kind, size, label, shut=False):
    return outfit(kind, phead, PF, BILL, size, label, shut=shut, extra_back=tail(PF))
def baby(size):
    f = ''.join(f'<ellipse cx="{x}" cy="246" rx="19" ry="15" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' for x in (84, 156))
    return svg(tail(PF) + trap('#F4BE2C', 246, 28) + pocket(204) + arm(-1, 46, '#F4BE2C', BILL) + arm(1, -46, '#F4BE2C', BILL) + f + phead(), size, 'Baby platypus puggle sitting in a yellow romper', '0 0 240 272')
def icon(size):
    return svg(phead(), size, 'App icon with the platypus face', '36 34 168 150')

def panel(bg, inner, name, w=220, h=226):
    return (f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: {w}px; height: {h}px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; gap: 2px; padding-bottom: 10px; box-sizing: border-box; position: relative">{inner}</div>'
            f'<div style="font-size: 15px; font-weight: 700">{name}</div></div>')
moon = f'<svg aria-hidden="true" width="40" height="40" viewBox="0 0 44 44" style="position: absolute; right: 14px; top: 14px"><path d="M26 6a17 17 0 1 0 12 28A14 14 0 0 1 26 6z" fill="#F4BE2C" stroke="{O}" stroke-width="4" stroke-linejoin="round"></path></svg>'
row1 = (panel('#F4BE2C', platypus('jumper', 160, 'Platypus puggle in a blue jumper with a pouch pocket'), 'Jumper with pouch pocket') +
        panel('#F3D9C9', platypus('dungarees', 160, 'Platypus puggle in green dungarees'), 'Dungarees') +
        panel('#BFD9F5', platypus('dress', 160, 'Platypus puggle in a red dress with a collar'), 'Dress') +
        panel('#CFE5D2', platypus('shorts', 160, 'Platypus puggle in a striped T-shirt and yellow shorts'), 'T-shirt and shorts'))
row2 = (panel('#CFE5D2', baby(168), 'Baby, sitting') +
        panel('#1B2440', moon + platypus('pyjamas', 160, 'Platypus puggle asleep in spotted pyjamas', shut=True), 'Asleep, in pyjamas') +
        panel('#F4BE2C', platypus('jumper', 118, 'Platypus puggle') + outfit('dungarees', ehead, EF, EF, 118, 'Echidna puggle in dungarees'), 'Two puggles: platypus and echidna') +
        f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: 220px; height: 226px; display: flex; align-items: center; justify-content: center"><div style="width: 150px; height: 150px; border-radius: 34px; background: #F4BE2C; display: flex; align-items: center; justify-content: center; overflow: hidden">{icon(140)}</div></div><div style="font-size: 15px; font-weight: 700">App icon</div></div>')
body = f'''<div style="width: 1080px; height: 660px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle the platypus, with a wardrobe</h1>
<div style="display: flex; gap: 34px">
{row1}
</div>
<div style="display: flex; gap: 34px">
{row2}
</div>
</div>'''
if len(sys.argv) > 2:
    open(sys.argv[1] + '/gen/platy.html', 'w').write('<body style="margin:0">' + body.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>'); sys.exit()
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Puggle the platypus</title>
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
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":660}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'PugglePlatypus.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['PugglePlatypus.dc.html'] = {'x': 0, 'y': 6960, 'w': 1080, 'h': 660, 'title': 'Puggle the platypus, with a wardrobe'}
if 'PugglePlatypus.dc.html' not in c['order']: c['order'].append('PugglePlatypus.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'), html.count('<g ') == html.count('</g>'))
