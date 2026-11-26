import sys, math, json
ROOT = sys.argv[1]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
INK, A = '#3A2A20', '#F4BE2C'
PAPER, SAND, SKY, SHELL, MINT, SUN, MOON, HARB, GUM, WAR, NIGHT = '#FBF6E9', '#F2ECDD', '#BFD9F5', '#F3D9C9', '#CFE5D2', '#F4E7B0', '#F3E0B8', '#2A62B8', '#3C9A5F', '#E5553B', '#1B2440'
OFF = 1.3  # the slip: accent prints this far down and right of the line

def rr(x, y, wd, h, r): return f'M{x+r} {y}H{x+wd-r}Q{x+wd} {y} {x+wd} {y+r}V{y+h-r}Q{x+wd} {y+h} {x+wd-r} {y+h}H{x+r}Q{x} {y+h} {x} {y+h-r}V{y+r}Q{x} {y} {x+r} {y}Z'
def circle(cx, cy, r): return f'M{cx-r} {cy}a{r} {r} 0 1 0 {2*r} 0a{r} {r} 0 1 0 {-2*r} 0Z'
def ellipse(cx, cy, rx, ry): return f'M{cx-rx} {cy}a{rx} {ry} 0 1 0 {2*rx} 0a{rx} {ry} 0 1 0 {-2*rx} 0Z'
def quatre(cx, cy, r):
    """Quatrefoil sparkle, from Puggle's hair clip: four round petals."""
    p = r * 0.5
    return ''.join(circle(cx + dx * p, cy + dy * p, p * 1.05) for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0))) + circle(cx, cy, p * 0.9)
def star(cx, cy, ro, ri, rad):
    pts = [(cx + (ro if i % 2 == 0 else ri) * math.cos(math.radians(-90 + i*36)), cy + (ro if i % 2 == 0 else ri) * math.sin(math.radians(-90 + i*36))) for i in range(10)]
    n = len(pts); out = ''
    def cut(p, q, d):
        dx, dy = q[0]-p[0], q[1]-p[1]; l = math.hypot(dx, dy); k = min(d, l/2)/l; return (p[0]+dx*k, p[1]+dy*k)
    segs = [(cut(pts[i], pts[i-1], rad), pts[i], cut(pts[i], pts[(i+1) % n], rad)) for i in range(n)]
    s = segs[-1][2]; out = f'M{s[0]:.2f} {s[1]:.2f}'
    for a, c, b in segs: out += f'L{a[0]:.2f} {a[1]:.2f}Q{c[0]:.2f} {c[1]:.2f} {b[0]:.2f} {b[1]:.2f}'
    return out + 'Z'

# Each icon: bodies (shape, sticker colour), accents (shape), lines (stroke paths)
BOT_BODY = 'M9 9.2H15Q16 9.2 16 10.5Q16 12 15.2 13.2Q16.3 14.4 16.3 16V18.8Q16.3 21 14 21H10Q7.7 21 7.7 18.8V16Q7.7 14.4 8.8 13.2Q8 12 8 10.5Q8 9.2 9 9.2Z'
POT_BODY = 'M4.8 17.8C4.6 13.5 4.8 9.3 6.1 7C7.2 5.1 9.9 4.8 11.2 6.5C12 7.7 12.5 9.3 14.4 9.5C15.9 9.7 16.7 8.9 17.9 9.4C19.3 10 19.3 12.2 19.2 17.8'
NAP = 'M4.2 6.5H19.8A1.6 1.6 0 0 1 21.4 8.1V10C18.4 10.8 16.6 12.5 15.8 15Q15.2 18.6 12 18.8Q8.8 18.6 8.2 15C7.4 12.5 5.6 10.8 2.6 10V8.1A1.6 1.6 0 0 1 4.2 6.5Z'
BOWL = 'M4.7 11h14.6a1.2 1.2 0 0 1 1.2 1.3c-.6 4.3-4.2 7.2-8.5 7.2s-7.9-2.9-8.5-7.2A1.2 1.2 0 0 1 4.7 11z'
MOONP = 'M18.5 15A8 8 0 0 1 9 4.5a8 8 0 1 0 9.5 10.5z'
ICONS = {
 'Bottle': dict(bodies=[(BOT_BODY, SKY), (rr(7.6, 7, 8.8, 2.2, 1.1), SHELL), ('M10 7V5.2a2 2 0 0 1 4 0V7Z', SHELL)],
                acc=['M7.7 15.5H16.3V18.8Q16.3 21 14 21H10Q7.7 21 7.7 18.8Z'],
                lines=['M10 7V5.2a2 2 0 0 1 4 0V7', rr(7.6, 7, 8.8, 2.2, 1.1), BOT_BODY, 'M8.3 17h1.8M8.3 19h1.8']),
 'Sleep': dict(bodies=[(MOONP, MOON)], acc=[quatre(17.2, 6.2, 2.6)], lines=[MOONP]),
 'Nappy': dict(bodies=[(NAP, PAPER)], acc=[rr(4.2, 7.3, 3.4, 1.7, .8), rr(16.4, 7.3, 3.4, 1.7, .8)], lines=[NAP, 'M2.7 10H21.3']),
 'Potty': dict(bodies=[(POT_BODY + 'Z', MINT), (rr(3.3, 17.8, 17.4, 2.7, 1.35), MINT)], acc=[ellipse(13.3, 12.4, 3.5, 1.35)],
               lines=[rr(3.3, 17.8, 17.4, 2.7, 1.35), POT_BODY, 'M7.3 8.8C7.7 10.9 8.6 12.2 9.7 12.5', ellipse(13.3, 12.4, 3.5, 1.35)]),
 'Solids': dict(bodies=[(BOWL, SKY)], acc=['M7 11c.8-2.2 2.8-3.5 5-3.5s4.2 1.3 5 3.5z'], lines=['M7 11c.8-2.2 2.8-3.5 5-3.5s4.2 1.3 5 3.5', BOWL, 'M15.5 7.5l4-4']),
 'Play': dict(bodies=[(rr(3.5, 13, 7, 7, 1.6), SHELL), (rr(13.5, 13, 7, 7, 1.6), MINT)], acc=[rr(8.5, 4, 7, 7, 1.6)],
              lines=[rr(8.5, 4, 7, 7, 1.6), rr(3.5, 13, 7, 7, 1.6), rr(13.5, 13, 7, 7, 1.6)]),
 'Walk': dict(bodies=[('M4 11.5A6 6 0 0 1 10 5.5V11.5Z', SHELL), ('M4 11.5h13.5a6.75 6.75 0 0 1-13.5 0z', SKY)], acc=['M10 11.5L4.8 8.5A6 6 0 0 1 7 6.3Z'],
              lines=['M4 11.5A6 6 0 0 1 10 5.5V11.5Z', 'M10 11.5L4.8 8.5M10 11.5L7 6.3', 'M4 11.5h13.5a6.75 6.75 0 0 1-13.5 0z', 'M17.5 11.5l1.2-4a1.5 1.5 0 0 1 1.4-1h.9',
                     circle(7.5, 20, 1.5), circle(15, 20, 1.5)], dots=[(10, 11.5, 1.0)]),
 'Milestone': dict(bodies=[(star(12, 12.4, 8.8, 3.8, 1.3), SUN)], acc=[quatre(12, 12.6, 3.2)], lines=[star(12, 12.4, 8.8, 3.8, 1.3)]),
}
ORDER = list(ICONS)

def lines(ic, sw=1.4, col=INK, dx=0, dy=0):
    t = f' transform="translate({dx} {dy})"'
    out = ''.join(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"></path>' for d in ic['lines'])
    out += ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{col}"></circle>' for x, y, r in ic.get('dots', []))
    return f'<g{t}>{out}</g>'
def accents(ic, col=A, off=OFF):
    return f'<g transform="translate({off} {off})">' + ''.join(f'<path d="{d}" fill="{col}" fill-rule="nonzero"></path>' for d in ic['acc']) + '</g>'
def bodies(ic, shade=True, uid=''):
    out = ''.join(f'<path d="{d}" fill="{c}"></path>' for d, c in ic['bodies'])
    if shade:  # two-tone: the right half is a touch deeper, as if lit from the left
        out += f'<g clip-path="url(#half{uid})">' + ''.join(f'<path d="{d}" fill="{INK}" opacity="0.09"></path>' for d, _ in ic['bodies']) + '</g>'
    return out

def line_icon(n, aligned=False, accent=True):  # app tier
    ic = ICONS[n]
    return (accents(ic, off=0 if aligned else OFF) if accent else '') + lines(ic)
def sticker_icon(n, uid):
    ic = ICONS[n]
    die = ''.join(f'<path d="{d}" fill="{PAPER}" stroke="{PAPER}" stroke-width="4.2" stroke-linejoin="round"></path>' for d, _ in ic['bodies']) + \
          ''.join(f'<path d="{d}" fill="none" stroke="{PAPER}" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round"></path>' for d in ic['lines'])
    return (f'<defs><clipPath id="half{uid}"><rect x="12" y="0" width="12" height="24"></rect></clipPath>'
            f'<filter id="sh{uid}" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="0.5" stdDeviation="0.45" flood-color="#3A2A20" flood-opacity="0.22"></feDropShadow></filter></defs>'
            f'<g filter="url(#sh{uid})">{die}</g>' + bodies(ic, True, uid) + accents(ic) + lines(ic, 1.4))
def print_icon(n, ink=INK):  # flat colour shapes, the line slips the other way
    ic = ICONS[n]
    return (''.join(f'<path d="{d}" fill="{c}"></path>' for d, c in ic['bodies']) + ''.join(f'<path d="{d}" fill="{A}"></path>' for d in ic['acc'])
            + lines(ic, 1.3, ink, -1.1, -1.1))

def svg(inner, size, label=None, bg=None, rad=0):
    a = f'role="img" aria-label="{label}"' if label else 'aria-hidden="true"'
    st = f' style="background: {bg}; border-radius: {rad}px"' if bg else ''
    return f'<svg {a} width="{size}" height="{size}" viewBox="0 0 24 24"{st}>{inner}</svg>'

H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'

# 1. Lineage: one bottle, five finishes
steps = [('Line', 'Lucide and most system sets', line_icon('Bottle', accent=False)),
         ('Duotone', 'Phosphor: colour fits the line', line_icon('Bottle', aligned=True)),
         ('Puggle line', 'The colour slips, like a screen print', line_icon('Bottle')),
         ('Puggle sticker', 'Same drawing, filled, die-cut', sticker_icon('Bottle', 'lin')),
         ('Puggle print', 'No outline; the line slips instead', print_icon('Bottle'))]
lineage = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 176px"><div style="width: 176px; height: 120px; border-radius: 18px; background: {PAPER if i < 4 else MINT}; display: flex; align-items: center; justify-content: center">{svg(s, 92, n + " bottle")}</div>'
                  f'<div style="font-size: 15px; font-weight: 800">{n}{" ★" if i >= 2 else ""}</div><div style="{T}">{d}</div></div>' for i, (n, d, s) in enumerate(steps))

# 2. Rules
rules = [('Chubby', 'Squat, toddler proportions. Wide bodies, short necks, nothing spindly; most icons fill the 20 pt keyshape.'),
         ('Soft', '1.4 pt line, round caps and joins, every corner rounded. No sharp points, even on stars.'),
         ('One slipped colour', 'A single Wattle fill, printed 1.3 pt down and right of the line, like a slightly off screen print on a kids’ T-shirt. It’s Puggle’s signature.'),
         ('Quatrefoil sparkle', 'Sparkles and highlights use the four-petal shape from Puggle’s hair clip, never a plain star.'),
         ('No faces in the app', 'Objects stay objects. Faces and expressions belong to the characters, in stickers, books and print.'),
         ('One drawing, three finishes', 'Line for the app, sticker for celebrations and widgets, print for clothing and wallpapers. Draw once.')]
rule_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 4px; width: 312px"><div style="font-size: 16px; font-weight: 800">{i+1}. {n}</div><div style="{T}">{d}</div></div>' for i, (n, d) in enumerate(rules))

# 3. Tiers
line_row = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 86px">{svg(line_icon(n), 52, n + " line icon", PAPER, 14)}'
                   f'<div style="display: flex; gap: 6px; align-items: flex-end">{svg(line_icon(n), 24)}{svg(line_icon(n), 17)}</div><div style="font-size: 12px; font-weight: 700">{n}</div></div>' for n in ORDER)
stick_row = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 86px">{svg(sticker_icon(n, "s" + str(i)), 72, n + " sticker")}<div style="font-size: 12px; font-weight: 700">{n}</div></div>' for i, n in enumerate(ORDER))

# Context: Today rows in the line style
def today_row(n, title, sub, who):
    return (f'<div style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; background: {PAPER}; border-radius: 18px">'
            f'<div style="width: 40px; height: 40px; border-radius: 12px; background: {SAND}; display: flex; align-items: center; justify-content: center">{svg(line_icon(n), 28)}</div>'
            f'<div style="flex: 1; display: flex; flex-direction: column; gap: 1px"><div style="font-size: 15px; font-weight: 700; font-family: system-ui">{title}</div><div style="font-size: 12px; color: #6B5E52; font-family: system-ui">{sub}</div></div>'
            f'<div style="font-size: 12px; font-weight: 700; font-family: system-ui; color: #6B5E52">{who}</div></div>')
today = (f'<div style="width: 300px; display: flex; flex-direction: column; gap: 8px; padding: 12px; background: {SAND}; border-radius: 24px; border: 1px solid #E2D8C6">'
         + today_row('Bottle', 'Bottle, 150 ml', '2:40 pm, formula', 'Baby') + today_row('Sleep', 'Asleep 42 min', 'since 1:58 pm', 'Baby')
         + today_row('Potty', 'Potty, a wee!', '1:30 pm, 3 today', 'Toddler') + today_row('Walk', 'Walk', '11:00 am, 50 min', 'Both') + '</div>')
# Context: potty sticker chart
days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
got = [['Potty', 'Potty'], ['Potty', 'Milestone'], ['Potty'], ['Potty', 'Potty', 'Potty'], ['Milestone'], [], []]
chart = (f'<div style="width: 340px; padding: 14px; background: {PAPER}; border-radius: 24px; display: flex; flex-direction: column; gap: 10px">'
         f'<div style="font-size: 17px; font-weight: 800">Sticker chart, this week</div><div style="display: flex; gap: 4px">'
         + ''.join(f'<div style="flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 6px 0; min-height: 132px; border-radius: 12px; background: {SAND}">'
                   f'<div style="font-size: 12px; font-weight: 800">{d}</div>' + ''.join(svg(sticker_icon(n, f'c{i}{j}'), 36, n + ' sticker') for j, n in enumerate(g)) + '</div>' for i, (d, g) in enumerate(zip(days, got)))
         + '</div></div>')
# Context: print swatch (tossed repeat)
import random
random.seed(7)
toss = ''
for row in range(5):
    for col in range(6):
        n = ORDER[(row * 3 + col) % len(ORDER)]
        x = col * 56 + (28 if row % 2 else 0) - 14; y = row * 56 - 6
        rot = random.choice([-14, -8, 0, 8, 14])
        toss += f'<g transform="translate({x} {y}) rotate({rot} 24 24) scale(2)">{print_icon(n)}</g>'
swatch = f'<svg role="img" aria-label="Fabric repeat of print-finish icons" width="300" height="250" viewBox="0 0 300 250" style="border-radius: 20px; background: {MINT}">{toss}</svg>'

body = f'''<div style="width: 1080px; height: 1380px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">The Puggle style</h1>
<div style="font-size: 15px; font-weight: 500; color: #4A3B30; max-width: 900px; line-height: 1.45">Taken from everything so far: the calm line of system icon sets, the duotone accent from Phosphor, the two-tone fills and sticker energy of the nursery sets, and our own clothing label. What makes it Puggle is the slipped print colour, the chubby shapes and the quatrefoil sparkle.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Where it sits</div><div style="display: flex; gap: 22px">{lineage}</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Six rules</div><div style="display: flex; flex-wrap: wrap; gap: 16px 24px">{rule_html}</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Line: the app (Today, log sheet, history, SF Symbols)</div>
<div style="display: flex; gap: 28px; align-items: flex-start"><div style="display: flex; flex-wrap: wrap; gap: 14px 6px; width: 380px">{line_row}</div>{today}
<div style="width: 250px; {T}">In single-colour places (tinted Home Screen, Lock Screen, menus) the slipped fill drops out and the line stands alone, so every icon must read without it.</div></div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Sticker and print: celebrations, widgets, clothing, wallpapers</div>
<div style="display: flex; gap: 28px; align-items: flex-start"><div style="display: flex; flex-wrap: wrap; gap: 10px 6px; width: 380px">{stick_row}</div>{chart}{swatch}</div>
<div style="{T}; max-width: 980px">Sticker: the palette fills, a gentle two-tone (the right half a touch deeper), the slipped Wattle and a paper die-cut edge. Print: flat colour with no outline; the ink line slips up and left instead, which is how a two-screen print really misregisters.</div></div>
</div>'''
wrap('The Puggle style', body, 1080, 1380, 'PuggleStyle.dc.html', 2700)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['PuggleStyle.dc.html'].update(page='app', x=0, y=2700)
c['boards']['IconSystem3.dc.html'].update(page='app', x=1200, y=1968)
c['boards']['Icons.dc.html']['page'] = 'archive'; c['boards']['Icons.dc.html']['y'] = 8700
o = c['order']; o.remove('PuggleStyle.dc.html'); o.insert(o.index('IconSystem3.dc.html'), 'PuggleStyle.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
