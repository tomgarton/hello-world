import sys, math, re, os, glob
ROOT = sys.argv[1]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
INK, A, SKY = '#3A2A20', '#F4BE2C', '#BFD9F5'
SWD = 1.4
L = f'fill="none" stroke="{INK}" stroke-width="{SWD}" stroke-linecap="round" stroke-linejoin="round"'
def f(v): return f'{v:.2f}'.rstrip('0').rstrip('.')
def rp(pts, r=1.6, closed=True):
    """Polyline/polygon with rounded corners (quadratic through each vertex)."""
    n = len(pts); d = ''
    def cut(p, q, dist):
        dx, dy = q[0]-p[0], q[1]-p[1]; L_ = math.hypot(dx, dy) or 1; k = min(dist, L_/2)/L_
        return (p[0]+dx*k, p[1]+dy*k)
    idx = range(n) if closed else range(1, n-1)
    segs = []
    for i in idx:
        p, c, q = pts[i-1], pts[i], pts[(i+1) % n]
        segs.append((cut(c, p, r), c, cut(c, q, r)))
    if closed:
        s = segs[-1][2]; d = f'M{f(s[0])} {f(s[1])}'
        for a, c, b in segs: d += f'L{f(a[0])} {f(a[1])}Q{f(c[0])} {f(c[1])} {f(b[0])} {f(b[1])}'
        return d + 'Z'
    d = f'M{f(pts[0][0])} {f(pts[0][1])}'
    for a, c, b in segs: d += f'L{f(a[0])} {f(a[1])}Q{f(c[0])} {f(c[1])} {f(b[0])} {f(b[1])}'
    return d + f'L{f(pts[-1][0])} {f(pts[-1][1])}'
def ln(d): return f'<path d="{d}" {L}></path>'
def fill(d, c=A): return f'<path d="{d}" fill="{c}"></path>'
def both(d, c=A): return fill(d, c) + ln(d)
def rr(x, y, wd, h, r): return f'M{x+r} {y}H{x+wd-r}Q{x+wd} {y} {x+wd} {y+r}V{y+h-r}Q{x+wd} {y+h} {x+wd-r} {y+h}H{x+r}Q{x} {y+h} {x} {y+h-r}V{y+r}Q{x} {y} {x+r} {y}Z'
def circ(cx, cy, r, c=None): return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"></circle>' if c else '') + f'<circle cx="{cx}" cy="{cy}" r="{r}" {L}></circle>'
def star(cx, cy, ro, ri, rad):
    pts = [(cx + (ro if i % 2 == 0 else ri) * math.cos(math.radians(-90 + i*36)), cy + (ro if i % 2 == 0 else ri) * math.sin(math.radians(-90 + i*36))) for i in range(10)]
    return rp(pts, rad)
ICONS = [
 ('Bottle', 'Teat, collar, and a body with a slight waist, which reads as a baby bottle faster. Milk level and ticks.',
  fill('M7.700 15.500H16.300V18.800Q16.300 21 14 21H10Q7.700 21 7.700 18.800Z') + ln('M10 7V5.200a2 2 0 0 1 4 0V7') + ln(rr(8.500, 7, 7, 2.200, 1)) +
  ln('M9 9.200H15Q16 9.200 16 10.500Q16 12 15.200 13.200Q16.300 14.400 16.300 16V18.800Q16.300 21 14 21H10Q7.700 21 7.700 18.800V16Q7.700 14.400 8.800 13.200Q8 12 8 10.500Q8 9.200 9 9.200Z') + ln('M8.200 17h2M8.200 19h2')),
 ('Breastfeed', 'A parent holding a baby close: two heads, a shoulder, and an arm wrapped under the baby.',
  circ(9, 7, 3) + circ(15.800, 12.300, 2.200, A) + ln('M3.500 20.500c0-5 2.500-8 5.500-8') + ln('M7 15.800c2.500 3.400 8.500 3.800 11.700.4')),
 ('Pump', 'Rounded funnel narrowing into a small bottle.',
  '<ellipse cx="5.500" cy="8" rx="1.600" ry="3.500" ' + L + '></ellipse>' + ln('M5.500 4.500L11.600 6.800M5.500 11.500L11.600 9.700') + ln(rr(11.600, 6.300, 4.200, 4, 1.200)) + fill(rr(12, 14.500, 5, 6, 2)) + ln(rr(12, 10.300, 5, 10.200, 2.200))),
 ('Solids', 'Food heaped above a bowl, with a spoon.',
  both('M7 11c.8-2.200 2.800-3.500 5-3.500s4.200 1.300 5 3.500z') + ln(rp([(3.500, 11), (20.500, 11), (12, 19.500)], 1.200).replace('L12 19.5', 'L12 19.5')) .replace(ln(rp([(3.500, 11), (20.500, 11), (12, 19.500)], 1.200)), ln('M4.700 11h14.600a1.200 1.200 0 0 1 1.200 1.300c-.6 4.300-4.200 7.200-8.500 7.200s-7.900-2.900-8.500-7.200A1.200 1.200 0 0 1 4.700 11z')) + ln('M15.500 7.500l4-4')),
 ('Sleep', 'Crescent moon with a small four-point twinkle, softly rounded.',
  ln('M18.500 15A8 8 0 0 1 9 4.500a8 8 0 1 0 9.500 10.500z') + f'<path d="M17 3.800l.75 1.700 1.700.75-1.700.75L17 8.700l-.75-1.700-1.700-.75 1.700-.75z" fill="{A}" stroke="{A}" stroke-width="0.900" stroke-linejoin="round"></path>'),
 ('Nappy', 'Front view with clear curved leg cut-outs, waistband and tabs.',
  ln('M4.200 6.500H19.800A1.600 1.600 0 0 1 21.400 8.100V10C18.400 10.800 16.600 12.500 15.800 15Q15.200 18.600 12 18.800Q8.800 18.600 8.200 15C7.400 12.500 5.600 10.800 2.600 10V8.100A1.600 1.600 0 0 1 4.200 6.500Z') +
  ln('M2.700 10H21.300') + fill(rr(4.200, 7.300, 3.400, 1.700, .8)) + fill(rr(16.400, 7.300, 3.400, 1.700, .8))),
 ('Potty', 'Three-quarter view of a child\u2019s potty: rounded backrest, seat opening (accent), front lip, wide base.',
  ln(rr(3.300, 17.800, 17.400, 2.700, 1.350)) + ln('M4.800 17.800C4.600 13.500 4.800 9.300 6.100 7C7.200 5.100 9.900 4.800 11.200 6.500C12 7.700 12.500 9.300 14.400 9.500C15.900 9.700 16.700 8.900 17.900 9.400C19.300 10 19.300 12.200 19.200 17.800') + ln('M7.300 8.800C7.700 10.900 8.600 12.200 9.700 12.500') +
  '<ellipse cx="13.300" cy="12.400" rx="3.500" ry="1.350" fill="#F4BE2C"></ellipse><ellipse cx="13.300" cy="12.400" rx="3.500" ry="1.350" ' + L + '></ellipse>'),
 ('Bath', 'Tub on feet, bubbles rising.',
  ln('M4 11.500h16a1 1 0 0 1 1 1v1a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5v-1a1 1 0 0 1 1-1z') + ln('M6.500 18.300l-1 1.700M17.500 18.300l1 1.700') + circ(9, 7.500, 2, A) + circ(13.500, 6, 1.300, A) + circ(15.500, 9, 1, A)),
 ('Growth', 'Rounded height chart with a soft arrow.',
  ln(rr(15, 3.500, 4.500, 17, 1.500)) + ln('M15 7h1.800M15 10.500h2.400M15 14h1.800M15 17.500h2.400') + both(rr(4.500, 12.500, 8, 2.200, 1.100)) + ln('M8.500 12.500V5.200M5.800 7.800l2.700-2.700 2.700 2.700')),
 ('Weight', 'Baby scale: rounded tray, base and readout.',
  ln('M4.300 8.500h15.400a.8.8 0 0 1 .8.9c-.6 2.800-3.200 4.600-8.500 4.600s-7.900-1.800-8.500-4.600a.8.8 0 0 1 .8-.9z') + ln('M8.200 13.700L7.200 16.500M15.800 13.700l1 2.800') + ln(rr(5, 16.500, 14, 3.500, 1.300)) + fill(rr(10, 17.500, 4, 1.300, .6))),
 ('Temperature', 'Thermometer with a filled bulb.',
  ln('M10 14V5.500a2 2 0 0 1 4 0V14a3.500 3.500 0 1 1-4 0z') + circ(12, 17, 1.800, A) + ln('M12 15.200V9')),
 ('Medicine', 'Dropper bottle, softened.',
  fill(rr(8, 14, 8, 6, 1.800)) + ln(rr(8, 11, 8, 9, 1.800)) + ln(rr(9.500, 8.500, 5, 2.500, .8)) + ln('M10.500 8.500V6a1.500 1.500 0 0 1 3 0v2.500')),
 ('Vaccine', 'Syringe with rounded barrel and plunger.',
  fill(rp([(8.300, 13.700), (12.300, 9.700), (14.700, 12.100), (10.700, 16.100)], 0.800)) + ln(rp([(6, 13.500), (13.500, 6), (18, 10.500), (10.500, 18)], 1.300)) + ln('M6 13.500l-2.500 2.500 4.500 4.500 2.500-2.500M15.750 8.250l2.500-2.500M17 4.500l2.500 2.500M4.750 19.250L3 21')),
 ('Teeth', 'One tooth with a shine.',
  ln('M7 4c-2 0-3 2-3 4 0 3 1.500 4 2 7 .5 3 1 5 2.500 5S10 17 12 17s2 3 3.500 3 2-2 2.500-5c.5-3 2-4 2-7 0-2-1-4-3-4-2.500 0-3 1.500-5 1.500S9.500 4 7 4z') + f'<path d="M15.500 7.500q2 .5 2 3" fill="none" stroke="{A}" stroke-width="1.800" stroke-linecap="round"></path>'),
 ('Milestone', 'Star with softly rounded points and a filled centre.',
  fill(star(12, 12.400, 3.400, 1.500, 0.500)) + ln(star(12, 12.400, 8.800, 3.800, 1.300))),
 ('Tummy time', 'Baby on a mat, head lifted.',
  fill(rr(2.500, 19, 19, 1.800, .9), SKY) + ln('M2.500 19h19') + ln('M5 19a2.500 2.500 0 0 1 0-5h8.500a2.500 2.500 0 0 1 0 5') + circ(17.500, 12.500, 3, A) + ln('M14.500 17l2 2')),
 ('Play', 'Three identical stacked blocks, so they read as equal.',
  both(rr(8.500, 4, 7, 7, 1.600)) + ln(rr(3.500, 13, 7, 7, 1.600)) + ln(rr(13.500, 13, 7, 7, 1.600))),
 ('Walk', 'Pram with a segmented hood (one panel in the accent), basket, handle, wheels.',
  fill('M10 11.500L4.800 8.500A6 6 0 0 1 7 6.300Z') + ln('M4 11.500A6 6 0 0 1 10 5.500V11.500Z') + ln('M10 11.500L4.800 8.500M10 11.500L7 6.300') +
  ln('M4 11.500h13.500a6.750 6.750 0 0 1-13.500 0z') + ln('M17.500 11.500l1.200-4a1.500 1.500 0 0 1 1.400-1h.9') + circ(7.500, 20, 1.500) + circ(15, 20, 1.500)),
 ('Note', 'Page with a rounded folded corner.',
  fill(rp([(14.500, 3.500), (18.500, 7.500), (14.500, 7.500)], 0.800)) + ln(rp([(5.500, 3.500), (14.500, 3.500), (18.500, 7.500), (18.500, 20.500), (5.500, 20.500)], 1.600)) + ln('M14.500 3.700v3.800h3.800M8.500 11h7M8.500 14h7M8.500 17h4.500')),
 ('Photo', 'Rounded camera body and lens.',
  ln('M8.700 6.500l1-1.600a1 1 0 0 1 .9-.4h2.800a1 1 0 0 1 .9.4l1 1.600') + ln(rr(3.500, 6.500, 17, 12.500, 2.500)) + circ(12, 12.700, 3.800, A) + '<circle cx="17.300" cy="9.300" r=".8" fill="#3A2A20"></circle>'),
]
LIB = glob.glob(ROOT + '/../libs/lucide-static-*/package/icons')[0]
PH = glob.glob(ROOT + '/../libs/phosphor-icons-core-*/package/assets/duotone')[0]
def lucide(name):
    s = open(f'{LIB}/{name}.svg').read(); inner = s[s.index('>', s.index('<svg')) + 1:s.rindex('</svg>')]
    return f'<g fill="none" stroke="{INK}" stroke-width="1.400" stroke-linecap="round" stroke-linejoin="round">{inner}</g>'
def phos(name):
    s = open(f'{PH}/{name}-duotone.svg').read(); inner = s[s.index('>', s.index('<svg')) + 1:s.rindex('</svg>')]
    inner = inner.replace('currentColor', INK).replace('opacity="0.2"', f'opacity="1" fill="{A}"')
    return f'<g transform="scale(0.09375)">{inner}</g>'
CMP = [('Bottle', 'milk', None), ('Breastfeed', 'baby', 'baby'), ('Sleep', 'moon', 'moon'), ('Bath', 'bath', 'bathtub'), ('Growth', 'ruler', 'ruler'), ('Weight', 'weight', 'scales'),
       ('Medicine', 'pill', 'pill'), ('Vaccine', 'syringe', 'syringe'), ('Milestone', 'star', 'star'), ('Play', 'blocks', 'lego'), ('Walk', None, 'baby-carriage'), ('Photo', 'camera', 'camera')]
OURS = {n: s for n, _, s in ICONS}
grid = ''.join(f'<path d="M{i} 0V24M0 {i}H24" stroke="#E2D8C6" stroke-width="0.060"></path>' for i in range(25))
key = '<rect x="2" y="2" width="20" height="20" fill="none" stroke="#E5553B" stroke-width="0.100" opacity="0.6"></rect><circle cx="12" cy="12" r="10" fill="none" stroke="#2A62B8" stroke-width="0.100" opacity="0.5"></circle>'
def tile(n, note, svg, k):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px; width: 182px">'
            f'<div style="display: flex; gap: 8px; align-items: flex-end"><svg role="img" aria-label="{n} icon on the grid" width="132" height="132" viewBox="0 0 24 24" style="background: #FBF6E9; border-radius: 10px">{grid}{key}{svg}</svg>'
            f'<div style="display: flex; flex-direction: column; gap: 8px; align-items: center"><svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">{svg}</svg><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24">{svg}</svg></div></div>'
            f'<div style="font-size: 15px; font-weight: 800">{k:02d}. {n}</div><div style="font-size: 12px; font-weight: 500; color: #4A3B30; line-height: 1.35">{note}</div></div>')
tiles = ''.join(tile(n, note, s, i + 1) for i, (n, note, s) in enumerate(ICONS))
def cell(svg, label):
    return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 3px; width: 70px"><div style="width: 56px; height: 56px; border-radius: 14px; background: #ECE4D4; display: flex; align-items: center; justify-content: center">{f"<svg aria-hidden={chr(34)}true{chr(34)} width={chr(34)}32{chr(34)} height={chr(34)}32{chr(34)} viewBox={chr(34)}0 0 24 24{chr(34)}>{svg}</svg>" if svg else "<div style=" + chr(34) + "font-size: 11px; color: #6B5E52" + chr(34) + ">none</div>"}</div></div>'
rows = ''
for label, src in (('Puggle', lambda n, l, p: OURS[n]), ('Lucide (ISC)', lambda n, l, p: lucide(l) if l else None), ('Phosphor duotone (MIT)', lambda n, l, p: phos(p) if p else None)):
    rows += f'<div style="display: flex; align-items: center; gap: 4px"><div style="width: 150px; font-size: 13px; font-weight: 800">{label}</div>' + ''.join(cell(src(n, l, p), n) for n, l, p in CMP) + '</div>'
names = '<div style="display: flex; gap: 4px"><div style="width: 150px"></div>' + ''.join(f'<div style="width: 70px; font-size: 11px; font-weight: 700; text-align: center">{n}</div>' for n, _, _ in CMP) + '</div>'
body = f'''<div style="width: 1080px; height: 1420px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; flex-direction: column; gap: 4px"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Activity icons, rounded</h1><div style="font-size: 14px; font-weight: 500; color: #4A3B30">1.4 pt stroke. Every corner rounded (about 1.2 to 1.8 pt radius), round caps and joins. On the 24 pt grid, and at 24 and 17 pt.</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Compared with Lucide and Phosphor, same stroke and accent</div>{rows}{names}</div>
<div style="display: flex; flex-wrap: wrap; gap: 22px 12px">{tiles}</div>
</div>'''
wrap('Activity icons, rounded', body, 1080, 1420, 'IconSystem3.dc.html', 33800)
