import sys, math, json
ROOT = sys.argv[1]
src = open(ROOT + '/gen/style.py').read()
exec(src[:src.index('# ---- BOARD ----')])
exec(src[src.index('# ---- BOARD ----'):src.index('# 1. Lineage')])  # svg(), H, T
P = ROOT + '/project/'

def rpoly(pts, rad):
    n = len(pts)
    def cut(p, q, d):
        dx, dy = q[0]-p[0], q[1]-p[1]; l = math.hypot(dx, dy); k = min(d, l/2)/l; return (p[0]+dx*k, p[1]+dy*k)
    segs = [(cut(pts[i], pts[i-1], rad), pts[i], cut(pts[i], pts[(i+1) % n], rad)) for i in range(n)]
    s = segs[-1][2]; out = f'M{s[0]:.2f} {s[1]:.2f}'
    for a, c, b in segs: out += f'L{a[0]:.2f} {a[1]:.2f}Q{c[0]:.2f} {c[1]:.2f} {b[0]:.2f} {b[1]:.2f}'
    return out + 'Z'
def petals(n, R, r, cx=12, cy=12, start=-90):
    """Outline of n round petals (centre distance R, radius r) as one path of arcs."""
    cs = [(cx + R*math.cos(math.radians(start + i*360/n)), cy + R*math.sin(math.radians(start + i*360/n))) for i in range(n)]
    def outer(c1, c2):
        mx, my = (c1[0]+c2[0])/2, (c1[1]+c2[1])/2; d = math.hypot(c2[0]-c1[0], c2[1]-c1[1]); h = math.sqrt(r*r - d*d/4)
        ux, uy = mx - cx, my - cy; l = math.hypot(ux, uy); return (mx + ux/l*h, my + uy/l*h)
    pts = [outer(cs[i-1], cs[i]) for i in range(n)]
    d = f'M{pts[0][0]:.2f} {pts[0][1]:.2f}'
    for i in range(n):
        p, q, c = pts[i], pts[(i+1) % n], cs[i]
        mid = ((p[0]+q[0])/2, (p[1]+q[1])/2)
        large = 1 if math.hypot(c[0]-cx, c[1]-cy) > math.hypot(mid[0]-cx, mid[1]-cy) else 0
        d += f'A{r} {r} 0 {large} 1 {q[0]:.2f} {q[1]:.2f}'
    return d + 'Z'

# ---------- Soft shapes, redrawn on the 24 grid ----------
QUAT = petals(4, 4.4, 4.7)
BLOSSOM = petals(5, 4.6, 4.3)
HEX = rpoly([(12 + 9.2*math.cos(math.radians(60*i)), 12 + 8.4*math.sin(math.radians(60*i))) for i in range(6)], 2.6)
SCAL = 'M4.5 18.5a1.5 1.5 0 0 1-1.5-1.5V12.5a3 3 0 0 1 6 0a3 3 0 0 1 6 0a3 3 0 0 1 6 0V17a1.5 1.5 0 0 1-1.5 1.5Z'
PEBBLE = 'M12 3.5C18.5 3.5 21.3 7.5 20.8 12.6S16.6 20.8 11 20.4S2.8 16.8 3.3 11.4S6 3.5 12 3.5Z'
HALF = 'M5 6H14a6 6 0 0 1 0 12H5a1.5 1.5 0 0 1-1.5-1.5V7.5A1.5 1.5 0 0 1 5 6Z'
def shape(d, c): return dict(bodies=[(d, c)], acc=[], lines=[d], fills=[(d, c)])
SHAPES = [('Quatrefoil', shape(QUAT, STITCH)), ('Pill', shape(rr(2.5, 8, 19, 8, 4), SKY)), ('Scallop', shape(SCAL, A)), ('Soft square', shape(rr(3.5, 3.5, 17, 17, 5), GUM)),
          ('Soft hexagon', shape(HEX, WARATAH)), ('Pebble', shape(PEBBLE, FUR)), ('Half pill', shape(HALF, HARBOUR)), ('Blossom', shape(BLOSSOM, SHELL))]

# ---------- Australiana, redrawn in the house style ----------
THONG = 'M12 2.8C15.4 2.8 16.9 5.4 16.7 9.3C16.5 12.8 15.7 14.8 15.9 17.3C16.1 19.9 14.4 21.4 12 21.4S7.9 19.9 8.1 17.3C8.3 14.8 7.5 12.8 7.3 9.3C7.1 5.4 8.6 2.8 12 2.8Z'
ESKY_LID = rr(2.5, 6.5, 19, 3.6, 1.6)
ESKY = 'M4 10.1V18a2 2 0 0 0 2 2H18a2 2 0 0 0 2-2V10.1'
LAM_TOP = 'M4.5 9L12 5.8L19.5 9L12 12.2Z'
LAM_SIDES = 'M4.5 9V15.6L12 19.4L19.5 15.6V9L12 12.2Z'
BREAD = rpoly([(4.5, 4.5), (19.5, 19.5), (4.5, 19.5)], 2.2)
PAV = 'M5 18.5V13Q5 10.8 7.2 10.8H16.8Q19 10.8 19 13V18.5Z'
BERRY = 'M12 4.6C13.9 4.6 14.6 5.9 14.2 7.4C13.8 8.8 12.8 9.9 12 10.4C11.2 9.9 10.2 8.8 9.8 7.4C9.4 5.9 10.1 4.6 12 4.6Z'
BOARD = 'M12 1.8C15.6 5.4 16.3 11.4 15.8 15.6S13.6 22.2 12 22.2S8.7 19.8 8.2 15.6S8.4 5.4 12 1.8Z'
BOARD_STRIPE = 'M8.6 9.2H15.4Q15.7 10.6 15.8 12H8.2Q8.3 10.6 8.6 9.2Z'
ZINC_TOP = 'M9.6 11V6.8a2.4 2.4 0 0 1 4.8 0V11Z'
ZINC = rr(8.3, 11, 7.4, 10, 2)
AUS = [
 ('Thong', dict(bodies=[(THONG, SKY)], acc=[circle(12, 6.6, 1.1)], lines=[THONG, 'M12 6.6L8.4 12.6M12 6.6L15.6 12.6'], fills=[(THONG, SKY)], rot=-18)),
 ('Esky', dict(bodies=[(ESKY + 'Z', PAPER), (ESKY_LID, WARATAH)], acc=[], lines=[ESKY_LID, ESKY, 'M9 6.5V5.5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1', 'M4 13.5H20'], fills=[(ESKY_LID, BLUSH)])),
 ('Hills Hoist', dict(bodies=[(rr(14.2, 9.4, 4.4, 4.8, 1), SKY)], acc=[], lines=['M12 4.8L20.8 8.3L12 11.8L3.2 8.3Z', 'M3.2 8.3L20.8 8.3M12 4.8V11.8', 'M12 8.3V20.5M8.5 20.5H15.5', rr(14.2, 9.4, 4.4, 4.8, 1)], fills=[(rr(14.2, 9.4, 4.4, 4.8, 1), SKY)])),
 ('Lamington', dict(bodies=[(LAM_SIDES, FUR), (LAM_TOP, '#A9714B')], acc=[], lines=[LAM_SIDES, LAM_TOP], fills=[(LAM_TOP, SHELL)],
                    dots=[(9.2, 9.0, .45), (12, 8.2, .45), (14.8, 9.4, .45), (12, 10.4, .45), (7.4, 14.2, .45), (9.6, 16.4, .45), (15.8, 15.6, .45), (16.6, 12.6, .45)])),
 ('Fairy bread', dict(bodies=[(BREAD, SUN)], acc=[], lines=[BREAD, rpoly([(7, 9.6), (15.4, 18), (7, 18)], 1.2)],
                      fills=[(BREAD, SUN)], dots=[(8.6, 15.8, .55), (10.6, 16.6, .55), (8.6, 13.2, .55), (12.4, 16.2, .55)])),
 ('Pavlova', dict(bodies=[(PAV, PAPER), (BERRY, WARATAH)], acc=[], lines=['M3 20.5H21', PAV, 'M5 13.2Q6.75 14.8 8.5 13.2T12 13.2T15.5 13.2T19 13.2', BERRY], fills=[(BERRY, BLUSH)])),
 ('Surfboard', dict(bodies=[(BOARD, PAPER), (BOARD_STRIPE, WARATAH)], acc=[], lines=[BOARD, BOARD_STRIPE, 'M12 18.5V20.6'], fills=[(BOARD_STRIPE, A)], rot=32)),
 ('Zinc stick', dict(bodies=[(ZINC, PAPER), (ZINC_TOP, BLUSH)], acc=[], lines=[ZINC, ZINC_TOP, 'M8.3 13.6H15.7'], fills=[(ZINC_TOP, MINT)])),
]
# The fairy-bread sprinkles and lamington coconut need colour in the sticker; plain dots in the line finish.

def cell(inner, size, label, name, bg=None):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 104px">{svg(inner, size, label, bg, 14 if bg else 0)}'
            f'<div style="font-size: 12px; font-weight: 700; text-align: center">{name}</div></div>')
def line_cell(n, ic):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 104px">{svg(line_icon(ic), 56, n + " line", PAPER, 14)}'
            f'<div style="display: flex; gap: 6px; align-items: flex-end">{svg(line_icon(ic), 24)}{svg(line_icon(ic), 17)}</div><div style="font-size: 12px; font-weight: 700">{n}</div></div>')
def label_row(title, items):
    return f'<div style="display: flex; align-items: flex-start; gap: 6px"><div style="width: 92px; padding-top: 18px; font-size: 13px; font-weight: 800">{title}</div><div style="display: flex; gap: 8px">{items}</div></div>'

shape_rows = (label_row('Line', ''.join(line_cell(n, ic) for n, ic in SHAPES))
              + label_row('Sticker', ''.join(cell(sticker_icon(ic, f'sh{i}'), 64, n + ' sticker', n) for i, (n, ic) in enumerate(SHAPES)))
              + label_row('Print', ''.join(cell(print_icon(ic), 56, n + ' print', n, MINT if i % 2 else SKY) for i, (n, ic) in enumerate(SHAPES))))
aus_rows = (label_row('Line', ''.join(line_cell(n, ic) for n, ic in AUS))
            + label_row('Sticker', ''.join(cell(sticker_icon(ic, f'au{i}'), 72, n + ' sticker', n) for i, (n, ic) in enumerate(AUS))))

# Sticker sheet: shapes, props and activities together
import random
random.seed(3)
sheet = ''
items = [ic for _, ic in AUS] + [ic for _, ic in SHAPES[:6]] + [ICONS[k] for k in ('Bottle', 'Sleep', 'Milestone', 'Potty')]
pos = [(14, 10), (78, 4), (146, 14), (214, 6), (20, 74), (90, 70), (160, 80), (226, 72), (8, 140), (76, 138), (146, 150), (216, 140), (30, 204), (104, 206), (176, 210), (244, 200), (250, 120), (258, 30)]
for i, (ic, (x, y)) in enumerate(zip(items, pos)):
    r = random.choice([-12, -6, 0, 6, 12])
    sheet += f'<g transform="translate({x} {y}) rotate({r} 26 26) scale(2.2)">{sticker_icon(ic, f"sw{i}")}</g>'
sheet_svg = f'<svg role="img" aria-label="Sticker sheet mixing shapes, Australiana and activities" width="320" height="270" viewBox="0 0 320 270" style="background: {PAPER}; border-radius: 22px">{sheet}</svg>'
toss = ''
pr = [ic for _, ic in AUS] + [ic for _, ic in SHAPES]
for row in range(5):
    for col in range(6):
        ic = pr[(row * 5 + col) % len(pr)]
        x = col * 56 + (28 if row % 2 else 0) - 14; y = row * 54 - 6
        toss += f'<g transform="translate({x} {y}) rotate({random.choice([-12, -6, 0, 6, 12])} 24 24) scale(2)">{print_icon(ic)}</g>'
toss_svg = f'<svg role="img" aria-label="Fabric repeat of shapes and Australiana in the print finish" width="320" height="270" viewBox="0 0 320 270" style="background: {SKY}; border-radius: 22px">{toss}</svg>'

body = f'''<div style="width: 1080px; height: 1080px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Shapes and Australiana, in the Puggle style</h1>
<div style="{T}; font-size: 15px; max-width: 920px">The same rules as the activity icons: 24 pt grid, 1.4 pt line, every corner rounded, brand palette only, one drawing finished three ways. Shapes keep their brand colours; props take the soft palette so they sit with the app icons.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Soft shapes</div>{shape_rows}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Australiana props</div>{aus_rows}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Together</div>
<div style="display: flex; gap: 24px; align-items: flex-start">{sheet_svg}{toss_svg}<div style="width: 300px; {T}">Left: a sticker sheet (rewards, the potty chart, a printed insert with a Puggle &amp; Co. order). Right: the print finish as a fabric repeat, where the line slips off-register like a real two-screen print.<br><br>Thong, esky, Hills Hoist, lamington, fairy bread, pavlova, surfboard and zinc are everyday suburban things, with no Indigenous motifs.</div></div></div>
</div>'''
wrap('Shapes and Australiana, in the Puggle style', body, 1080, 1080, 'StyleWorld.dc.html', 4300)

# ---------- Holographic stickers ----------
HOLO = ['#BFD9F5', '#CFE5D2', '#F4E7B0', '#F3D9C9', '#EE9C88', '#C9C3EE', '#BFD9F5']
def holo(ic, uid, dur=5, glint=A):
    ic = ic if isinstance(ic, dict) else ICONS[ic]
    stops = ''.join(f'<stop offset="{i/(len(HOLO)-1):.2f}" stop-color="{c}"></stop>' for i, c in enumerate(HOLO))
    clip = ''.join(f'<path d="{d}"></path>' for d, _ in ic['bodies'])
    die_b = ''.join(f'<path d="{d}" fill="url(#hg{uid})" stroke="url(#hg{uid})" stroke-width="4.6" stroke-linejoin="round"></path>' for d, _ in ic['bodies']) + \
            ''.join(f'<path d="{d}" fill="none" stroke="url(#hg{uid})" stroke-width="4.6" stroke-linecap="round" stroke-linejoin="round"></path>' for d in ic['lines'])
    die_p = die_b.replace(f'url(#hg{uid})', PAPER).replace('4.6', '3.2')
    sparkles = ''.join(f'<path d="{quatre(x, y, s)}" fill="{glint}" opacity="0"><animate attributeName="opacity" values="0;1;0" dur="{d}s" begin="{b}s" repeatCount="indefinite"></animate></path>'
                       for x, y, s, d, b in ((5, 5, 1.6, 2.2, 0), (19.5, 18, 1.3, 2.6, .9), (18.5, 4.5, 1.0, 1.9, 1.5), (4.5, 19, 1.0, 2.4, .4)))
    return (f'<defs><linearGradient id="hg{uid}" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="12" y2="12" spreadMethod="reflect">{stops}'
            f'<animateTransform attributeName="gradientTransform" type="translate" values="-12 -12;12 12;-12 -12" dur="{dur}s" repeatCount="indefinite"></animateTransform></linearGradient>'
            f'<linearGradient id="gl{uid}" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="24" y2="24"><stop offset="0.38" stop-color="#FFFFFF" stop-opacity="0"></stop><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.75"></stop><stop offset="0.62" stop-color="#FFFFFF" stop-opacity="0"></stop>'
            f'<animateTransform attributeName="gradientTransform" type="translate" values="-24 -24;24 24" dur="{dur*0.7:.1f}s" repeatCount="indefinite"></animateTransform></linearGradient>'
            f'<clipPath id="hc{uid}">{clip}</clipPath>'
            f'<filter id="hs{uid}" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="0.5" stdDeviation="0.5" flood-color="#3A2A20" flood-opacity="0.25"></feDropShadow></filter></defs>'
            + _rot(ic, f'<g filter="url(#hs{uid})">{die_b}</g>{die_p}'
                   + ''.join(f'<path d="{d}" fill="url(#hg{uid})"></path>' for d, _ in ic['bodies'])
                   + f'<g clip-path="url(#hc{uid})"><rect x="0" y="0" width="24" height="24" fill="url(#gl{uid})"></rect></g>'
                   + ''.join(f'<path d="{d}" fill="{A}"></path>' for d in ic['acc'])
                   + lines(ic, 1.4)) + sparkles)
PUGCLIP = dict(bodies=[(QUAT, STITCH)], acc=[circle(12, 12, 2.2)], lines=[QUAT, circle(12, 12, 2.2)])
DRY = dict(ICONS['Potty'])
special = [('First steps', 'Milestone', 'A milestone: first steps, first word, first tooth.'), ('Dry all week', DRY, 'Potty training: seven dry days in a row.'),
           ('Puggle’s clip', PUGCLIP, 'The rarest: a surprise, maybe once a month, for showing up.')]
cards = ''.join(f'<div style="display: flex; flex-direction: column; gap: 8px; width: 250px"><div style="width: 250px; height: 250px; border-radius: 28px; background: {NIGHT if i == 2 else PAPER}; display: flex; align-items: center; justify-content: center">'
                f'{svg(holo(ic, "h" + str(i), 4 + i, "#FFFFFF" if i == 2 else A), 190, n + " holographic sticker")}</div><div style="font-size: 17px; font-weight: 800">{n}</div><div style="{T}">{d}</div></div>' for i, (n, ic, d) in enumerate(special))
hbody = f'''<div style="width: 1080px; height: 580px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Holographic stickers</h1>
<div style="{T}; font-size: 15px; max-width: 900px">The super special ones. Same sticker drawing, but the fill and the die-cut edge are a foil of the brand pastels, with a glare that slides across and quatrefoil glints. On the canvas they shimmer on a loop; on iPhone the shimmer follows how you tilt the phone.</div></div>
<div style="display: flex; gap: 28px; align-items: flex-start">{cards}
<div style="width: 220px; display: flex; flex-direction: column; gap: 12px; {T}">
<div><b>On iPhone.</b> Core Motion gives the phone's tilt; it moves the foil gradient and the glare with a SwiftUI Metal shader, so the sticker catches the light like a real one.</div>
<div><b>Calm by default.</b> With Reduce Motion on, the foil stays still with a soft sheen. No sound, no confetti storm.</div>
<div><b>Rare on purpose.</b> Only big moments earn one, so they stay special. They live in the sticker book and can be shared as an image.</div></div></div>
</div>'''
wrap('Holographic stickers', hbody, 1080, 580, 'Holo.dc.html', 5900)

c = json.load(open(P + 'canvas.json'))
c['boards']['PuggleStyle.dc.html'].update(page='app', x=0, y=2700, h=1450)
c['boards']['StyleWorld.dc.html'].update(page='app', x=0, y=4260)
c['boards']['Holo.dc.html'].update(page='app', x=1200, y=4260, is_interactive=True)
o = c['order']
for k in ('StyleWorld.dc.html', 'Holo.dc.html'):
    o.remove(k)
o[o.index('PuggleStyle.dc.html') + 1:o.index('PuggleStyle.dc.html') + 1] = ['StyleWorld.dc.html', 'Holo.dc.html']
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
