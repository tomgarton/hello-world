import sys, json, re, math
ROOT = sys.argv[1]; P = ROOT + '/project/'
src = open(ROOT + '/gen/builder.py').read()
src = src[:src.index('def btn_row')].replace("P = sys.argv[1] + '/project/'", '')
ns = {}; exec(src, ns)
SVG = ns['svg']; O = '#3A2A20'
FURS = {'platypus': ('#8A5A3C', '#6E7F8D'), 'echidna': ('#9B6B43', '#CFA277'), 'koala': ('#A9B0B8', '#A9B0B8'), 'wombat': ('#8C7B6E', '#8C7B6E')}
def char(animal, outfit, garment, w=60, mono=None, label=None):
    if mono:
        vals = dict(fur=mono[0], ext=mono[0], garment=mono[0], paper=mono[0], spine=mono[0], inner=mono[0], blush=mono[0], blushShow='none', stitch=mono[1], line=mono[1])
    else:
        f, e = FURS[animal]
        vals = dict(fur=f, ext=e, garment=garment, paper='#FBF6E9', spine='#F3E3C3', inner='#F0DAD6', blush='#EE9C88', blushShow='inline', stitch='#C24A36', line=O)
    s = re.sub(r'\{\{c\.(\w+)\}\}', lambda m: vals[m.group(1)], SVG)
    s = re.sub(r'\{\{[do]\.(\w+)\}\}', lambda m: 'inline' if m.group(1) in (animal, outfit) else 'none', s)
    s = s.replace('{{label}}', label or f'{animal} character').replace('width="300" height="375"', f'width="{w}" height="{w*1.25:.0f}"')
    return s
def inner(animal, outfit, garment, mono=None):
    s = char(animal, outfit, garment, mono=mono)
    return s[s.index('>') + 1:s.rindex('</svg>')]
# shapes
def shape(kind, c):
    if kind == 'quatre': return ''.join(f'<circle cx="{50+dx}" cy="{50+dy}" r="24" fill="{c}"></circle>' for dx, dy in ((-20,0),(20,0),(0,-20),(0,20))) + f'<rect x="30" y="30" width="40" height="40" fill="{c}"></rect>'
    if kind == 'pill': return f'<rect x="4" y="30" width="92" height="40" rx="20" fill="{c}"></rect>'
    if kind == 'blossom': return ''.join(f'<circle cx="{50+22*math.cos(math.radians(72*i-90)):.1f}" cy="{50+22*math.sin(math.radians(72*i-90)):.1f}" r="20" fill="{c}"></circle>' for i in range(5)) + f'<circle cx="50" cy="50" r="22" fill="{c}"></circle>'
    if kind == 'pebble': return f'<path d="M50 12C78 12 92 30 90 54S70 90 46 88S8 72 10 48S24 12 50 12Z" fill="{c}"></path>'
    if kind == 'scallop': return f'<path d="M6 80V52a14 14 0 0 1 29 0a14 14 0 0 1 30 0a14 14 0 0 1 29 0V80Z" fill="{c}"></path>'
    if kind == 'square': return f'<rect x="10" y="10" width="80" height="80" rx="22" fill="{c}"></rect>'
def place(x, y, s, body, rot=0, box=100):
    k = s / box
    return f'<g transform="translate({x} {y}) rotate({rot}) scale({k:.3f}) translate({-box/2} {-box/2})">{body}</g>'
def wall_grid(w, h):
    # half-drop grid: characters alternate with shapes
    out = f'<rect width="{w}" height="{h}" fill="#F4BE2C"></rect>'
    cast = [('platypus', 'jumper', '#2A62B8'), ('koala', 'dress', '#E5553B'), ('echidna', 'dungarees', '#3C9A5F'), ('wombat', 'tee', '#2A62B8')]
    sh = [('quatre', '#E5553B'), ('pill', '#FBF6E9'), ('blossom', '#3C9A5F'), ('pebble', '#BFD9F5')]
    i = 0
    for row in range(-1, 8):
        for col in range(-1, 5):
            x = col * 80 + (40 if row % 2 else 0); y = row * 100 + 40
            if (row + col) % 2 == 0:
                a = cast[i % 4]; out += place(x, y, 74, inner(*a), 0, 240); i += 1
            else:
                k, c = sh[(row * 3 + col) % 4]; out += place(x, y, 30, shape(k, c), 0)
    return out
def wall_toss(w, h):
    out = f'<rect width="{w}" height="{h}" fill="#1B2440"></rect>'
    import random; rnd = random.Random(7)
    for j in range(46):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        k = rnd.choice(['quatre', 'blossom', 'pill', 'pebble', 'scallop']); c = rnd.choice(['#2C3670', '#3A4690', '#F3E0B8'])
        if c == '#F3E0B8' and rnd.random() < 0.6: c = '#2C3670'
        out += place(x, y, rnd.uniform(14, 30), shape(k, c), rnd.choice([0, 15, -20, 30]))
    for x, y in ((70, 150), (210, 330), (110, 560), (240, 730)):
        out += place(x, y, 92, inner('platypus', 'jumper', '#BFD9F5', mono=('#1B2440', '#F3E0B8')), 0, 240)
    return out
def wall_stripe(w, h):
    out = f'<rect width="{w}" height="{h}" fill="#FBF6E9"></rect>'
    cols = ['#BFD9F5', '#F3D9C9', '#CFE5D2', '#F4BE2C']
    for r in range(0, h // 120 + 1):
        y = r * 120
        out += f'<rect x="0" y="{y}" width="{w}" height="60" fill="{cols[r % 4]}"></rect>'
        for c in range(4):
            x = c * 82 + (41 if r % 2 else 0) + 20
            out += place(x, y + 30, 26, shape(['scallop', 'quatre', 'pill', 'blossom'][(r + c) % 4], '#FBF6E9'))
            out += place(x + 41, y + 92, 60, inner(['platypus', 'echidna', 'koala', 'wombat'][(r + c) % 4], 'jumper', ['#2A62B8', '#E5553B', '#3C9A5F', '#F4BE2C'][(r + c + 1) % 4]), 0, 240)
    return out
def phone(fn, label):
    w, h = 320, 692
    return (f'<div style="display: flex; flex-direction: column; gap: 10px"><div style="width: {w//1.6:.0f}px; height: {h//1.6:.0f}px; border-radius: 30px; overflow: hidden; border: 6px solid #2A1F18">'
            f'<svg role="img" aria-label="{label}" width="{w/1.6:.0f}" height="{h/1.6:.0f}" viewBox="0 0 {w} {h}">{fn(w, h)}'
            f'</svg></div>'
            f'<div style="font-size: 15px; font-weight: 700">{label}</div></div>')
def fabric():
    out = ''; n = 0
    cast = [('platypus', 'jumper', '#2A62B8'), ('koala', 'dress', '#E5553B'), ('echidna', 'dungarees', '#3C9A5F'), ('wombat', 'tee', '#2A62B8')]
    for r in range(4):
        for c in range(4):
            x = c * 70 + (35 if r % 2 else 0) + 20; y = r * 80 + 40
            if (r + c) % 2: out += place(x, y, 54, inner(*cast[n % 4], mono=('#F3D9C9', '#C24A36')), 0, 240); n += 1
            else: out += place(x, y, 22, shape(['quatre', 'blossom'][r % 2], '#C24A36'))
    return f'<svg role="img" aria-label="Single-colour fabric repeat" width="250" height="320" viewBox="0 0 290 370"><rect width="290" height="370" fill="#F3D9C9"></rect>{out}</svg>'

FONT = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">'
# ---- Coloured outlines (Tom, 12 November 2026): each line is a darker shade of the colour it goes round ----
import colorsys as _cs, re as _re2
_LINE = {'#8A5A3C': '#5E3A24', '#6E7F8D': '#465668', '#2A62B8': '#1B4387', '#E5553B': '#B23A26', '#F4C95D': '#B8892A', '#F4BE2C': '#B8892A', '#8FB4E3': '#1B4387'}
NOTINT = ('Logo', 'IconSystem', 'Icons', 'PuggleStyle', 'StyleWorld', 'Holo', 'References', 'ModelSheet', 'Flow', 'Motion')
def shade(c):
    c = c.upper()
    if c in _LINE: return _LINE[c]
    r, g, b = (int(c[i:i+2], 16) / 255 for i in (1, 3, 5))
    h, s_, v = _cs.rgb_to_hsv(r, g, b)
    r, g, b = _cs.hsv_to_rgb(h, min(1, s_ * 1.2 + 0.1), v * (0.5 if s_ < 0.25 else 0.62))
    return '#%02X%02X%02X' % (round(r * 255), round(g * 255), round(b * 255))
def tint(svg, ink='#3A2A20'):
    """Recolours dark outlines. A filled shape takes a darker shade of its fill; a wide stroke-only
    path under a coloured one (an arm) and the cuff after it take a darker shade of that colour.
    Thin stroke-only lines (eyes, marks) stay dark."""
    tags = _re2.split(r'(<[^>]+>)', svg); arm = None
    for i, t in enumerate(tags):
        if not t.startswith('<') or 'stroke="' + ink + '"' not in t: 
            if t.startswith('<circle') or t.startswith('<ellipse') or t.startswith('<rect'): arm = None
            continue
        f = _re2.search(r'fill="(#[0-9A-Fa-f]{6})"', t)
        wd = _re2.search(r'stroke-width="([\d.]+)"', t); wd = float(wd.group(1)) if wd else 1
        if f and f.group(1).upper() != ink:
            tags[i] = t.replace('stroke="' + ink + '"', 'stroke="' + shade(f.group(1)) + '"'); arm = arm if t.startswith('<circle') else None
        elif not f and wd >= 28:
            nxt = next((u for u in tags[i+1:i+4] if u.startswith('<path')), '')
            m = _re2.search(r'stroke="(#[0-9A-Fa-f]{6})"', nxt)
            if m and m.group(1).upper() != ink:
                arm = shade(m.group(1)); tags[i] = t.replace('stroke="' + ink + '"', 'stroke="' + arm + '"')
        elif not f and arm and wd <= 4.5 and 'L' in t:
            tags[i] = t.replace('stroke="' + ink + '"', 'stroke="' + arm + '"'); arm = None
    return ''.join(tags)
def wrap(title, body, w, h, fname, y, tinted=None):
    if tinted is None: tinted = not fname.startswith(NOTINT)
    if tinted: body = tint(body)
    html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONT}
<style>
body{{margin:0}}
a{{color:#2A1F18}}a:hover{{color:#5A4636}}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
    open(P + fname, 'w').write(html)
    c = json.load(open(P + 'canvas.json'))
    prev = c['boards'].get(fname, {})   # keep a board's place and page when it is regenerated
    c['boards'][fname] = {**prev, 'x': prev.get('x', 0), 'y': prev.get('y', y), 'w': w, 'h': h, 'title': title}
    if fname not in c['order']: c['order'].append(fname)
    json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
    open(ROOT + '/gen/' + fname.replace('.dc.html', '.html'), 'w').write('<head>' + FONT + '</head><body style="margin:0">' + body.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>')
    assert html.count('<div') == html.count('</div>') and html.count('<g ') == html.count('</g>'), fname

walls = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Wallpapers and repeats</h1>
<div style="display: flex; gap: 36px; align-items: flex-start">
{phone(wall_grid, 'Grid: friends and shapes')}
{phone(wall_toss, 'Night: tossed shapes, mono Puggle')}
{phone(wall_stripe, 'Stripes: Breton, with friends')}
<div style="display: flex; flex-direction: column; gap: 10px">{fabric()}<div style="font-size: 15px; font-weight: 700">Fabric: one-colour repeat</div></div>
</div>
</div>'''
wrap('Wallpapers and repeats', walls, 1080, 640, 'Wallpapers.dc.html', 11830)
