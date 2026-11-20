import sys, re, json, math, random
ROOT = sys.argv[1]
_s = open(ROOT + '/gen/scenes.py').read()
exec(_s[:_s.index('\nW, Hh = 390, 300')])
W, Hh = 390, 300
HL, HH = 120, 210          # the two horizons: open places, enclosed places
STAGE = (120, 205, 270, 295)  # x0, y0, x1, y1: keep clear for the cast
PUG = 70                   # Puggle's height, the scale reference
def frame(inner, label):
    return f'<svg role="img" aria-label="{label}" width="312" height="240" viewBox="0 0 {W} {Hh}" style="border-radius: 22px; display: block">{inner}</svg>'

# ---- planes: line weight shows distance ----
def _sw(svg, f): return re.sub(r'stroke-width="([\d.]+)"', lambda m: f'stroke-width="{float(m.group(1))*f:.2f}"', svg)
def far(svg): return _sw(svg, 0.55).replace(f'stroke="{INK}"', f'stroke="{INK}" stroke-opacity="0.5"')
def mid(svg): return _sw(svg, 0.82)
def place(el, x, y, s=1, k=1):
    """Draw el (built at the origin) at x, y, scaled by s, keeping line weight k regardless of scale."""
    return f'<g transform="translate({x} {y}) scale({s})">{_sw(el, k/s)}</g>'
def bg(c): return f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{c}"></rect>'
def ground(y, c, edge=True, curve=0):
    d = f'M-4 {y}Q{W/2} {y-curve} {W+4} {y}V{Hh+4}H-4Z'
    return flat(d, c) + (sl(f'M-4 {y}Q{W/2} {y-curve} {W+4} {y}', 1.8) if edge else '')

# ---- cloud family: three shapes, not one ----
def cloudA(cx, cy, w): return fp(scallop(cx, cy, w/2, w/5, 7, True), PAPER)
def cloudB(cx, cy, w): return fp(scallop(cx, cy, w/2, w/3.2, 5, True), PAPER)
def cloudC(cx, cy, w, c='#E9EDF2'): return fp(scallop(cx, cy, w/2, w/6, 10, True), c)

# ---- redrawn or new elements ----
def bridge2(x0, x1, y):
    span = x1 - x0; mid_ = (x0 + x1)/2
    top_o, top_i = y - span*0.72, y - span*0.42
    band = f'M{x0} {y}Q{mid_} {top_o} {x1} {y}L{x1-12} {y}Q{mid_} {top_i} {x0+12} {y}Z'
    out = flat(band, BILL)
    for i in range(1, 11):
        u = i/11; xx = x0 + 12 + (x1 - x0 - 24)*u; yy = (1-u)**2*y + 2*(1-u)*u*top_i + u*u*y
        out += sl(f'M{xx:.1f} {yy:.1f}V{y}', 1.2)
    out += sl(f'M{x0} {y}Q{mid_} {top_o} {x1} {y}') + sl(f'M{x0+12} {y}Q{mid_} {top_i} {x1-12} {y}')
    out += sl(f'M{x0-44} {y}H{x1+44}', 2.6)
    for px in (x0 - 18, x1 + 18):  # sandstone towers, the bridge's character
        t = R(px-14, y-58, 28, 58, 3); out += fp(t, SAND) + sl(f'M{px-14} {y-40}h28M{px-14} {y-20}h28', 1.2) + fp(R(px-16, y-64, 32, 7, 2), SAND, 1.8)
    return out
def skyline2(x, y):
    out = ''
    for w, h, c in ((34, 54, SHELL), (26, 82, PAPER), (38, 44, SKY), (30, 66, SHELL)):
        out += fp(R(x, y-h, w, h, 5), c)
        for row in range(2, int(h/16)): out += flat(R(x+6, y-h+row*16-6, w-12, 3, 1.5), INK).replace('fill="' + INK + '"', f'fill="{INK}" opacity="0.2"')
        x += w + 6
    return out
def wake(x, y): return sl(f'M{x} {y}q-26 4-60 0', 2, PAPER) + sl(f'M{x+4} {y+8}q-34 6-82 2', 2, PAPER)
def promenade(y):
    out = flat(f'M-4 {y}H{W+4}V{Hh+4}H-4Z', SAND) + sl(f'M-4 {y}H{W+4}', 2.2)
    out += sl(''.join(f'M{x} {y}V{y-24}' for x in range(10, 400, 38)), 2.2) + sl(f'M-4 {y-24}H{W+4}M-4 {y-12}H{W+4}', 1.6)
    return out
def hoist2(h=170):
    top = -h
    out = sl(f'M0 0V{top}', 2.6) + sl(f'M-70 {top+8}L0 {top-12}L70 {top+8}L0 {top+28}Z') + sl(f'M-70 {top+8}H70M0 {top-12}V{top+28}', 1.4)
    out += fp(f'M-58 {top+12}h24v8l-4 3v15h-16v-15l-4-3z', BLUSH, 1.8)                      # little T-shirt
    out += fp(f'M-24 {top+20}h20v26q-10 6-20 0z', SKY, 1.8)                              # onesie
    out += fp(R(6, top+16, 26, 30, 4), A, 1.8) + fp(R(38, top+10, 18, 22, 4), MINT, 1.8)  # towel, nappy cloth
    out += sl(f'M-52 {top+12}v-3M-38 {top+12}v-3M-20 {top+20}v-3M-8 {top+20}v-3M12 {top+16}v-3M26 {top+16}v-3M44 {top+10}v-3M50 {top+10}v-3', 1.4)
    return out + fp(R(-10, -3, 20, 6, 3), BILL, 1.8)
def pool3d(rx=46):
    ry = rx*0.3
    return (fp(f'M{-rx} 0V8A{rx} {ry} 0 0 0 {rx} 8V0Z', BLUSH) + f'<ellipse cx="0" cy="0" rx="{rx}" ry="{ry:.1f}" fill="{BLUSH}" stroke="{INK}" stroke-width="2.2"></ellipse>'
            + f'<ellipse cx="0" cy="1" rx="{rx-9}" ry="{ry-5:.1f}" fill="{SKY}" stroke="{INK}" stroke-width="1.6"></ellipse>' + sl(f'M{-rx*0.4:.1f} 1q{rx*0.2:.1f}-3 {rx*0.4:.1f} 0', 1.4, PAPER))
def sprinkler2():
    out = ''
    for a in (-60, -35, -12, 12, 35, 60):
        r = math.radians(a - 90); ex, ey = 46*math.cos(r), 40*math.sin(r) - 4
        cx, cy = ex*0.35, ey*1.05
        out += sl(f'M0 -6Q{cx:.1f} {cy:.1f} {ex:.1f} {ey:.1f}', 1.6, HARBOUR)
        out += f'<circle cx="{ex + 3*math.cos(r):.1f}" cy="{ey + 6:.1f}" r="1.8" fill="{HARBOUR}"></circle><circle cx="{ex + 6*math.cos(r):.1f}" cy="{ey + 14:.1f}" r="1.4" fill="{HARBOUR}"></circle>'
    return out + fp(R(-7, -6, 14, 6, 3), A, 1.8)
def rain2(x0, x1, y0, y1):
    out = ''; rnd = random.Random(4); row = 0; y = y0
    while y < y1:
        x = x0 + (row % 2)*14
        while x < x1:
            out += sl(f'M{x + rnd.uniform(-3, 3):.1f} {y:.1f}l-4 10', 1.6, HARBOUR); x += 28
        y += 22; row += 1
    return out
def ripples(x, y, w):
    return (f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="{w*0.24:.1f}" fill="{SKY}"></ellipse><ellipse cx="{x}" cy="{y}" rx="{w}" ry="{w*0.24:.1f}" fill="none" stroke="{INK}" stroke-width="1.8"></ellipse>'
            + f'<ellipse cx="{x}" cy="{y}" rx="{w*0.55:.1f}" ry="{w*0.12:.1f}" fill="none" stroke="{PAPER}" stroke-width="1.6"></ellipse><ellipse cx="{x}" cy="{y}" rx="{w*0.22:.1f}" ry="{w*0.05:.1f}" fill="none" stroke="{PAPER}" stroke-width="1.4"></ellipse>')
def boots():
    def one(x):
        return fp(f'M{x} -30h12v18q0 3 4 5h6q4 1 4 5v2H{x}Z', A, 2) + sl(f'M{x} -24h12', 1.3)
    return one(0) + one(22)
def tiles(x0, y0, x1, y1, step=18):
    out = flat(f'M{x0} {y0}H{x1}V{y1}H{x0}Z', PAPER)
    out += sl(''.join(f'M{x} {y0}V{y1}' for x in range(int(x0), int(x1), step)), 0.8, INK, ' opacity="0.18"')
    out += sl(''.join(f'M{x0} {y}H{x1}' for y in range(int(y0), int(y1), step)), 0.8, INK, ' opacity="0.18"')
    return out
def lane(y, c1, c2, x0=-4, x1=W+4):
    out = sl(f'M{x0} {y}H{x1}', 1.2)
    x = x0 + 4; i = 0
    while x < x1:
        out += f'<circle cx="{x}" cy="{y}" r="3.2" fill="{c1 if i % 2 else c2}" stroke="{INK}" stroke-width="1"></circle>'; x += 9; i += 1
    return out
def sail(x0, x1, y):
    return sl(f'M{x0} {y+70}V{y}M{x1} {y+70}V{y+14}', 2.2) + fp(f'M{x0} {y}L{x1} {y+14}L{(x0+x1)/2+10} {y+36}Z', MINT)
def puffs(x, y):
    return ''.join(f'<circle cx="{x+dx}" cy="{y-dy}" r="{r}" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"></circle>' for dx, dy, r in ((0, 0, 5), (5, 11, 6.5), (1, 24, 8)))
def cat():
    return (fp('M-12 0Q-14 -18 -4 -22Q6 -24 10 -14Q12 -6 12 0Z', FUR) + fp('M0 -22a8 8 0 1 1 0.1 0Z', FUR).replace('M0 -22a8 8 0 1 1 0.1 0Z', 'M-6 -24a8 8 0 1 0 16 0a8 8 0 1 0 -16 0Z')
            + fp('M-5 -30l1 -9 6 5z', FUR, 1.6) + fp('M9 -30l-1 -9-6 5z', FUR, 1.6)
            + sl('M12 -2q12 0 10 -14', 2.2) + f'<circle cx="-1" cy="-25" r="1.3" fill="{A}"></circle><circle cx="6" cy="-25" r="1.3" fill="{A}"></circle>')
def terrace2(x, y, w, h, c, roof='pitch', lit=(True, False), door=FUR):
    if roof == 'pitch': top = f'M{x} {y-h}L{x+w/2} {y-h-28}L{x+w} {y-h}'
    else: top = f'M{x} {y-h}V{y-h-16}Q{x+w/2} {y-h-30} {x+w} {y-h-16}V{y-h}'
    out = fp(f'M{x} {y}V{y-h}' + top[top.index('L') if roof == 'pitch' else top.index('V'):] + f'V{y}Z', c)
    out += sl(f'M{x} {y-h}H{x+w}', 1.4)
    out += fp(R(x+w*0.16, y-h*0.78, w*0.28, h*0.3, 4), A if lit[0] else NIGHT, 1.8) + fp(R(x+w*0.56, y-h*0.78, w*0.28, h*0.3, 4), A if lit[1] else NIGHT, 1.8)
    out += fp(R(x+w*0.36, y-h*0.36, w*0.28, h*0.36, 3), door, 1.8)
    return out
def lowwall(x0, x1, y, h=16):
    return fp(f'M{x0} {y}V{y-h}H{x1}V{y}Z', SHELL, 1.8) + sl(''.join(f'M{x} {y-h}V{y}' for x in range(int(x0)+24, int(x1), 24)), 1, INK, ' opacity="0.3"')
def hedge(y, c=GUM):
    return ''.join(fp(scallop(x, y, 30, 16, 7, True), c, 1.8) for x in range(10, 410, 52))
def egg_ghost(x, y, h=PUG):
    w = h*0.72
    return (f'<path d="M{x} {y-h}C{x+w*0.7} {y-h} {x+w*0.7} {y} {x} {y}C{x-w*0.7} {y} {x-w*0.7} {y-h} {x} {y-h}Z" fill="{PAPER}" fill-opacity="0.75" stroke="{INK}" stroke-width="1.6" stroke-dasharray="4 4"></path>'
            + f'<ellipse cx="{x+w*0.36:.1f}" cy="{y-h*0.6:.1f}" rx="{w*0.26:.1f}" ry="{h*0.08:.1f}" fill="{BILL}" opacity="0.6"></ellipse>')


def fern(x, y, s=1, c=GUM):
    out = ''
    for a, l in ((-70, 34), (-45, 42), (-20, 46), (5, 44), (30, 40), (55, 32)):
        r = math.radians(a - 90); ex, ey = l*s*math.cos(r), l*s*math.sin(r)
        out += fp(f'M{x} {y}Q{x + ex*0.3 - ey*0.25:.1f} {y + ey*0.6 + ex*0.1:.1f} {x+ex:.1f} {y+ey:.1f}Q{x + ex*0.6 + ey*0.15:.1f} {y + ey*0.3 - ex*0.15:.1f} {x} {y}Z', c, 1.6)
        out += sl(f'M{x} {y}Q{x + ex*0.45:.1f} {y + ey*0.45 - 3:.1f} {x+ex:.1f} {y+ey:.1f}', 1, INK, ' opacity="0.5"')
    return out
def log(x, y, w=76):
    return (fp(R(x, y-16, w, 16, 8), FUR) + sl(f'M{x+14} {y-11}h{w*0.4:.0f}M{x+24} {y-5}h{w*0.35:.0f}', 1.2, PAPER, ' opacity="0.6"')
            + f'<ellipse cx="{x+w-6}" cy="{y-8}" rx="6" ry="8" fill="{SHELL}" stroke="{INK}" stroke-width="2"></ellipse>'
            + f'<ellipse cx="{x+w-6}" cy="{y-8}" rx="2.5" ry="3.5" fill="none" stroke="{FUR}" stroke-width="1.2"></ellipse>')
def sail2(x0, x1, y):
    p1, p2, p3 = (x0, y), (x1, y+10), ((x0+x1)/2+14, y+40)
    cx, cy = (p1[0]+p2[0]+p3[0])/3, (p1[1]+p2[1]+p3[1])/3
    def edge(a, b, k=0.28):
        mx, my = (a[0]+b[0])/2, (a[1]+b[1])/2; return f'Q{mx + (cx-mx)*k:.1f} {my + (cy-my)*k:.1f} {b[0]:.1f} {b[1]:.1f}'
    d = f'M{p1[0]} {p1[1]}' + edge(p1, p2) + edge(p2, p3) + edge(p3, p1) + 'Z'
    inner = f'M{p1[0]+6} {p1[1]+3}' + edge((p1[0]+6, p1[1]+3), (p2[0]-7, p2[1]+2), 0.3) + edge((p2[0]-7, p2[1]+2), (p3[0], p3[1]-6), 0.3) + edge((p3[0], p3[1]-6), (p1[0]+6, p1[1]+3), 0.3)
    shadow = f'<ellipse cx="{cx+6:.1f}" cy="196" rx="{(x1-x0)*0.42:.1f}" ry="7" fill="{INK}" opacity="0.08"></ellipse>'
    return (shadow + sl(f'M{x0} {y+90}V{y}M{x1} {y+90}V{y+10}', 2.4) + sl(f'M{p3[0]:.1f} {p3[1]:.1f}L{p3[0]+40:.1f} {y+90}', 1.2)
            + fp(d, MINT) + sl(inner, 1.2, INK, ' stroke-dasharray="3 3" opacity="0.6"')
            + ''.join(f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="2.6" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"></circle>' for p in (p1, p2, p3)))

# ---- café, farm and shops ----
def awning(x0, x1, y, c, h=22):
    n = max(int((x1 - x0)/20), 3); w = (x1 - x0)/n
    out = flat(f'M{x0} {y}H{x1}V{y+h}H{x0}Z', PAPER)
    out += ''.join(flat(f'M{x0+i*w:.1f} {y}h{w:.1f}v{h}h{-w:.1f}z', c) for i in range(0, n, 2))
    edge = f'M{x0} {y+h}' + ''.join(f'a{w/2:.1f} {w/2.4:.1f} 0 0 0 {w:.1f} 0' for _ in range(n))
    out += ''.join(f'<path d="M{x0+i*w:.1f} {y+h}a{w/2:.1f} {w/2.4:.1f} 0 0 0 {w:.1f} 0z" fill="{c if i % 2 == 0 else PAPER}"></path>' for i in range(n))
    return out + sl(f'M{x0} {y}H{x1}V{y+h}M{x0} {y}V{y+h}') + sl(edge)
def window(x, y, w, h, c=SKY):
    return fp(R(x, y, w, h, 6), c) + sl(f'M{x+w*0.18:.1f} {y+h*0.75:.1f}l{w*0.18:.1f} {-h*0.5:.1f}M{x+w*0.32:.1f} {y+h*0.8:.1f}l{w*0.12:.1f} {-h*0.34:.1f}', 2, PAPER)
def cupicon(x, y, s=1):
    return sl(f'M{x-8*s} {y-6*s}h14v6a7 7 0 0 1 -14 0z', 1.8) + sl(f'M{x+6*s} {y-4*s}a3.5 3.5 0 0 1 0 7', 1.6)
def table_set(x, y):
    chair = lambda cx: (sl(f'M{cx} {y}V{y-26}M{cx+16} {y}V{y-26}M{cx-1} {y-26}h18', 2.2) + f'<circle cx="{cx+8}" cy="{y-40}" r="12" fill="none" stroke="{INK}" stroke-width="2.2"></circle>')
    return (chair(x-44) + chair(x+28) + sl(f'M{x} {y}V{y-34}M{x-12} {y}h24', 2.4)
            + f'<ellipse cx="{x}" cy="{y-36}" rx="26" ry="6" fill="{PAPER}" stroke="{INK}" stroke-width="2.2"></ellipse>'
            + fp(f'M{x-6} {y-50}h12v7a6 6 0 0 1 -12 0z', PAPER, 1.6) + flat(f'M{x-5} {y-49}h10v2h-10z', SHELL) + sl(f'M{x-9} {y-42}h18', 1.6))
def aframe(x, y):
    return (fp(f'M{x-20} {y}L{x-14} {y-56}H{x+14}L{x+20} {y}', FUR) + fp(R(x-13, y-50, 26, 34, 3), NIGHT, 1.6)
            + sl(f'M{x-6} {y-36}h10v5a5 5 0 0 1 -10 0z', 1.4, PAPER) + sl(f'M{x+4} {y-35}a2.5 2.5 0 0 1 0 5M{x-4} {y-40}q2 -3 0 -6M{x} {y-40}q2 -3 0 -6', 1.2, PAPER))
def planter(x, y, c=WARATAH):
    return fern(x, y-20, 0.9) + fp(f'M{x-16} {y-22}h32l-4 22h-24z', c)
def crate(x, y, fruit):
    out = fp(R(x, y-22, 46, 22, 3), '#D9B48A') + sl(f'M{x} {y-11}h46', 1.2)
    for i in range(5): out += f'<circle cx="{x+6+i*8.5:.1f}" cy="{y-24}" r="5.4" fill="{fruit}" stroke="{INK}" stroke-width="1.6"></circle>'
    return out
def flowers(x, y):
    out = ''.join(sl(f'M{x} {y-24}L{x+dx} {y-46}', 1.6, GUM) + flat(quatre(x+dx, y-48, 8), c) + f'<circle cx="{x+dx}" cy="{y-48}" r="1.8" fill="{INK}"></circle>'
                  for dx, c in ((-10, BLUSH), (0, A), (10, SKY), (-4, WARATAH), (6, BLUSH)))
    return out + fp(f'M{x-14} {y-26}h28l-3 26h-22z', BILL)
def shopfront(x, w, wall, aw, icon):
    out = fp(f'M{x} {HH}V48H{x+w}V{HH}Z', wall) + fp(R(x+14, 58, w-28, 24, 6), PAPER, 1.8) + icon(x + w/2, 70)
    out += awning(x+6, x+w-6, 90, aw)
    out += window(x+12, 128, w*0.5, 70) + fp(R(x+w*0.66, 128, w*0.26, 82, 4), FUR) + fp(R(x+w*0.69, 136, w*0.2, 30, 3), SKY, 1.4)
    return out
def apple_icon(x, y): return fp(f'M{x} {y-4}c-6-4-12 0-11 6s5 8 11 6c6 2 12-1 11-6s-5-10-11-6z', WARATAH, 1.6) + sl(f'M{x} {y-4}q1-4 4-6', 1.4)
def loaf_icon(x, y): return fp(f'M{x-12} {y+6}V{y}a12 8 0 0 1 24 0v6z', '#D9A066', 1.6) + sl(f'M{x-5} {y-4}l3 4M{x+2} {y-6}l3 4', 1.2)
def flower_icon(x, y): return flat(quatre(x, y, 12), BLUSH) + f'<circle cx="{x}" cy="{y}" r="2.6" fill="{A}" stroke="{INK}" stroke-width="1.2"></circle>'
def windmill(x, y, h=150):
    top = y - h
    out = sl(f'M{x-18} {y}L{x-4} {top+12}M{x+18} {y}L{x+4} {top+12}', 2.2) + sl(''.join(f'M{x-18+14*t/1:.1f} {y-(h-12)*t:.1f}L{x+18-14*t:.1f} {y-(h-12)*t:.1f}' for t in (0.25, 0.5, 0.75)), 1.4)
    out += sl(f'M{x-18} {y}L{x+12} {y-(h-12)*0.5:.1f}M{x+18} {y}L{x-12} {y-(h-12)*0.5:.1f}', 1)
    for i in range(12):
        a = math.radians(i*30); out += sl(f'M{x + 8*math.cos(a):.1f} {top + 8*math.sin(a):.1f}L{x + 34*math.cos(a):.1f} {top + 34*math.sin(a):.1f}', 3.2, BILL)
    out += f'<circle cx="{x}" cy="{top}" r="34" fill="none" stroke="{INK}" stroke-width="1.4"></circle>' + ci(x, top, 7, A, 1.8)
    out += fp(f'M{x+6} {top-2}h40l8 -10v24l-8 -10z', WARATAH, 1.8)
    return out
def tank(x, y, w=52, h=56):
    out = fp(R(x, y-h, w, h, 4), BILL) + sl(''.join(f'M{x} {y-h+i*8}h{w}' for i in range(1, int(h/8))), 1, PAPER, ' opacity="0.5"')
    return out + fp(f'M{x-3} {y-h}L{x+w/2} {y-h-12}L{x+w+3} {y-h}Z', BILL) + sl(f'M{x-3} {y-h}L{x+w/2} {y-h-12}L{x+w+3} {y-h}Z')
def shed(x, y, w=120, h=60):
    out = fp(f'M{x} {y}V{y-h}H{x+w}V{y}Z', WARATAH) + sl(''.join(f'M{x+i*10} {y-h}V{y}' for i in range(1, int(w/10))), 1, INK, ' opacity="0.2"')
    out += fp(f'M{x-8} {y-h+2}L{x+w*0.5} {y-h-30}L{x+w+8} {y-h+2}Z', BILL) + fp(R(x+w*0.36, y-h*0.7, w*0.28, h*0.7, 2), FUR)
    return out + sl(f'M{x+w*0.36} {y-h*0.7}l{w*0.28} {h*0.7}M{x+w*0.64} {y-h*0.7}l{-w*0.28} {h*0.7}', 1.4, PAPER)
def sheep(x, y, s=1, flip=False):
    b = fp(scallop(x, y-22*s, 22*s, 13*s, 9), PAPER) + sl(f'M{x-12*s} {y-12*s}V{y}M{x-4*s} {y-11*s}V{y}M{x+6*s} {y-11*s}V{y}M{x+13*s} {y-12*s}V{y}', 2.2)
    hx = x + (24 if not flip else -24)*s
    return sl(f'M{x-12*s} {y-12*s}V{y}M{x-4*s} {y-11*s}V{y}M{x+6*s} {y-11*s}V{y}M{x+13*s} {y-12*s}V{y}', 2.2) + fp(scallop(x, y-22*s, 22*s, 13*s, 9), PAPER) + f'<ellipse cx="{hx:.1f}" cy="{y-26*s:.1f}" rx="{7*s:.1f}" ry="{9*s:.1f}" fill="{INK}"></ellipse>'
def bale(x, y, r=20):
    return ci(x, y-r, r, SUN) + sl(f'M{x} {y-r}m-4 0a4 4 0 1 1 4 4a8 8 0 1 1 -8 -8a12 12 0 1 1 12 12', 1.2, '#B89A3A')
def wirefence(x0, x1, y, h=26):
    return sl(''.join(f'M{x} {y}V{y-h}' for x in range(int(x0), int(x1), 46)), 3, FUR) + sl(f'M{x0} {y-h*0.4}H{x1}M{x0} {y-h*0.8}H{x1}', 1)

# ---------------- the nine scenes ----------------
beach = (bg(SKY) + sun(338, 50, 16) + far(cloudA(110, 46, 84)) + far(cloudB(236, 30, 46)) + gull(160, 74) + gull(186, 64, .8)
         + flat(f'M-4 {HL}H{W+4}V190H-4Z', SEA) + sl(f'M-4 {HL}H{W+4}', 1.8) + far(waves(10, 380, 146, 2.5, 26, PAPER, 2.2))
         + ground(186, SUN, False, 12) + waves(-4, 394, 186, 2.5, 18, PAPER, 3)
         + mid(flags(150, 200)) + mid(pine(330, 226, 124))
         + place(towel(0, 0), 18, 268, 0.9) + place(umbrella(0, 0, 40), 70, 270, 1.05)
         + place(castle(0, 0), 308, 286, 0.6) + place(bucket(0, 0), 344, 292, 0.6))
bush = (bg(HAZE1) + far(sun(110, 100, 16, False)) + far(fp('M-4 112Q70 66 150 96T280 78T394 96V304H-4Z', HAZE2))
        + far(place(gum(0, 0, 50), 230, 94, 1)) + far(place(gum(0, 0, 40), 262, 92, 1))
        + mid(fp('M-4 150Q90 116 190 140T394 128V304H-4Z', HAZE3)) + ground(176, LAWN, True, 14)
        + sl('M168 304C168 270 230 252 262 226S300 200 318 192', 9, SAND) + sl('M168 304C168 270 230 252 262 226S300 200 318 192', 1.4, INK, ' stroke-dasharray="1 9"')
        + mid(lookout(292, 192)) + place(sign(0, 0), 98, 286, 1) + gull(200, 66, .7) + gull(222, 58, .6)
        + log(286, 292) + fern(372, 298, 1.1) + fern(132, 300, 0.6) + place(gum(0, 0, 300), 18, 312, 1))
harbour = (bg(DUSK) + sun(121, 100, 18, False) + far(cloudA(92, 46, 76)) + far(skyline2(232, HL))
           + flat(f'M-4 {HL}H{W+4}V{Hh+4}H-4Z', SEA) + sl(f'M-4 {HL}H{W+4}', 1.8) + ''.join(sl(f'M{121-w} {y}h{2*w}', 2.4, A) for y, w in ((132, 16), (142, 11), (152, 7))) + mid(bridge2(46, 196, HL))
           + far(waves(10, 380, 160, 2.5, 30, PAPER, 2.2)) + mid(place(sailboat(0, 0, 0.7), 330, 182, 1))
           + mid(wake(92, 222)) + mid(place(ferry(0, 0, 1), 140, 224, 0.95)) + promenade(262) + gull(240, 60))
yard = (bg(SKY) + far(cloudA(260, 50, 92)) + far(cloudB(90, 40, 50)) + mid(fence(-4, W + 4, HH, 70))
        + ground(HH, LAWN) + ''.join(flat(f'M{x} {HH}L{x+40} 304H{x+96}L{x+56} {HH}Z', '#C4DEC9') for x in (-40, 120, 280))
        + mid(place(lemon(0, 0, 120), 344, 238, 1)) + mid(place(sprinkler2(), 236, 232, 1))
        + place(hoist2(), 72, 286, 1) + place(pool3d(48), 322, 278, 1))
park = (bg(SKY) + far(cloudB(330, 40, 60)) + kite(132, 62) + ground(HH, LAWN)
        + mid(place(swing(0, 0), 70, 222, 1.05)) + mid(place(slide(0, 0), 168, 222, 1))
        + place(gum(0, 0, 220), 330, 262, 1) + place(rug(0, 0), 10, 262, 1))
rainy = (bg('#C9D5E2') + far(rainbow(350, 150, 62)) + far(cloudC(110, 50, 200)) + far(cloudC(310, 34, 150))
         + mid(rain2(-4, 394, 70, 200)) + ground(HH, LAWN2) + mid(place(gum(0, 0, 150), 52, 232, 1))
         + place(ripples(0, 0, 30), 312, 238, 1) + place(ripples(0, 0, 50), 66, 280, 1) + place(boots(), 92, 292, 0.8) + place(snail(0, 0), 344, 288, 0.9))
pool = (bg(SKY) + sun(350, 96, 14) + bunting(-10, 400, 24, [WARATAH, A, SKY, MINT, BLUSH])
        + far(hedge(160)) + tiles(-4, 166, W + 4, 206) + sl(f'M-4 166H{W+4}', 1.6) + mid(sail2(30, 160, 92))
        + flat(f'M-4 206H{W+4}V262H-4Z', SEA) + sl(f'M-4 206H{W+4}', 2.2)
        + lane(222, WARATAH, PAPER) + lane(244, A, PAPER) + place(ring(0, 0, 18), 300, 236, 1)
        + tiles(-4, 262, W + 4, 304) + sl(f'M-4 262H{W+4}', 2.2) + ladder(344, 262) + fp(R(30, 274, 40, 14, 6), A, 1.8))
grandma = (bg(SKY) + far(cloudA(300, 44, 84)) + sun(356, 92, 14) + mid(picket(176, 400, HH, 30)) + ground(HH, LAWN)
           + place(cottage(0, 0), 14, 230, 0.78) + place(puffs(0, 0), 133, 117, 1)
           + fp('M108 230C112 262 200 268 250 304H300C246 266 150 252 126 230Z', SAND, 1.8)
           + ''.join(place(hydrangea(0, 0, c), x, 238, 0.85) for x, c in ((20, SKY), (58, BLUSH), (176, SKY), (204, BLUSH)))
           + mid(place(birdbath(0, 0), 330, 240, 1)) + place(letterbox(0, 0), 362, 294, 1))
night = (bg(NIGHT) + moon(318, 60, 26) + ''.join(quat(x, y, s, MOON) for x, y, s in ((54, 46, 6), (130, 28, 4), (196, 66, 5), (250, 30, 4), (372, 116, 4), (26, 104, 4)))
         + terrace2(0, 232, 78, 96, SHELL, 'pitch', (True, False)) + terrace2(78, 232, 78, 118, SKY, 'parapet', (False, True))
         + terrace2(156, 232, 78, 104, MINT, 'pitch', (True, True), A) + terrace2(234, 232, 78, 124, BLUSH, 'parapet', (False, False))
         + terrace2(312, 232, 82, 100, SUN, 'pitch', (True, False))
         + flat(f'M-4 232H{W+4}V{Hh+4}H-4Z', '#2C3658') + lowwall(-4, W + 4, 246) + place(cat(), 262, 230, 1) + lamp(78, 300))

cafe = (bg(SKY) + fp(f'M-4 {HH}V34H{W+4}V{HH}Z', SHELL) + sl(''.join(f'M-4 {y}H{W+4}' for y in range(50, HH, 18)), 1, INK, ' opacity="0.12"')
        + fp(R(70, 46, 160, 30, 8), PAPER) + cupicon(150, 66, 1.2) + awning(20, 290, 84, WARATAH, 24)
        + window(30, 122, 200, 82) + fp(R(248, 116, 54, 94, 4), GUM) + fp(R(256, 126, 38, 40, 3), SKY, 1.4) + ci(288, 172, 2, A, 1)
        + tiles(-4, HH, W + 4, Hh + 4, 24) + sl(f'M-4 {HH}H{W+4}', 2.2) + far(cloudB(340, 18, 40))
        + place(table_set(0, 0), 64, 292, 1) + place(aframe(0, 0), 300, 290, 1) + place(planter(0, 0), 362, 294, 1) + place(planter(0, 0, GUM), 330, 210, 0.7))
farm = (bg(SKY) + sun(80, 54, 16) + far(cloudA(250, 40, 80)) + far(fp('M-4 112Q90 82 200 104T394 96V304H-4Z', LAWN2))
        + far(place(gum(0, 0, 54), 236, 102, 1)) + far(place(gum(0, 0, 44), 264, 100, 1)) + far(place(sheep(0, 0, 0.4), 150, 108, 1))
        + ground(150, LAWN, True, 16) + mid(shed(26, 172, 112, 56)) + mid(tank(152, 172)) + mid(windmill(320, 210, 156))
        + mid(wirefence(-4, W + 4, 206)) + place(bale(0, 0, 22), 362, 276, 1) + place(sheep(0, 0, 1), 52, 290, 1) + place(sheep(0, 0, 0.9, True), 312, 292, 1))
shops = (bg(SKY) + far(cloudA(196, 22, 70)) + shopfront(-4, 132, MINT, GUM, apple_icon) + shopfront(128, 132, SUN, WARATAH, loaf_icon) + shopfront(260, 134, BLUSH, HARBOUR, flower_icon)
         + tiles(-4, HH, W + 4, Hh + 4, 24) + sl(f'M-4 {HH}H{W+4}', 2.2)
         + place(crate(0, 0, '#F2994A'), 10, 286, 1) + place(crate(0, 0, WARATAH), 58, 290, 1) + place(crate(0, 0, GUM), 30, 262, 0.85) + place(flowers(0, 0), 330, 292, 1) + place(flowers(0, 0), 364, 290, 0.9))

SCENES = [('Beach', beach, 'Morning. Low horizon, one wave row, the pine fully in frame, flags planted behind; umbrella and towel left, castle and bucket right.'),
          ('Bush walk', bush, 'Afternoon haze. Far ridges in a soft line; a foreground gum frames the left, a log and ferns hold the right corner; the track runs to the lookout.'),
          ('Sydney Harbour', harbour, 'Golden hour, the sun setting inside the arch. Sandstone towers on the arch, a calmer skyline, the ferry with its wake; the cast stands at the railing.'),
          ('Backyard', yard, 'Hills Hoist with real washing (tee, onesie, towel), a water-fan sprinkler, the lemon tree and a paddling pool with depth.'),
          ('The park', park, 'Swings and slide share the back ground line; the gum sits in frame on the right; the rug comes forward on the left.'),
          ('Rainy day', rainy, 'Overcast. Rain falls in an even slant, puddles ripple, toddler-sized gumboots by the big puddle, a snail, a rainbow far off.'),
          ('The pool', pool, 'Flat-on: back hedge, a tensioned shade sail with stitched edge and its shadow, lane ropes across the water, light tiles, bunting along the top, the ring in the pool.'),
          ("Grandma's house", grandma, 'The cottage moves left; the garden is the stage. The path comes in from the side; a low fence lets the hydrangeas show; puffs of chimney smoke.'),
          ('The café', cafe, 'A corner café: striped awning, big window, a table with a babyccino, the A-frame board and potted ferns.'),
          ('The farm', farm, 'Open country: a red shed, the water tank and a windmill, a wire fence, sheep and a hay bale.'),
          ('The shops', shops, 'The local strip: grocer, bakery and florist with picture signs, fruit crates and buckets of flowers on the footpath.'),
          ('Night street', night, 'Terraces set back with mixed roofs, the lamp between houses, a low wall with the cat, one lit doorway.')]
scene_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 312px">{frame(s, n + " scene")}<div style="font-size: 16px; font-weight: 800">{n}</div><div style="{T}">{d}</div></div>' for n, s, d in SCENES)

# ---------------- rules diagram ----------------
x0, y0, x1, y1 = STAGE
rules_svg = (bg(PAPER) + sl(f'M0 {HL}H{W}', 1.6, HARBOUR, ' stroke-dasharray="6 5"') + sl(f'M0 {HH}H{W}', 1.6, GUM, ' stroke-dasharray="6 5"')
             + f'<text x="8" y="{HL-6}" font-size="12" font-weight="700" fill="{HARBOUR}" font-family="system-ui">Open places: horizon at 40%</text>'
             + f'<text x="8" y="{HH-6}" font-size="12" font-weight="700" fill="{GUM}" font-family="system-ui">Enclosed places: horizon at 70%</text>'
             + f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" rx="12" fill="{A}" fill-opacity="0.15" stroke="{A}" stroke-width="1.6" stroke-dasharray="5 4"></rect>'
             + f'<text x="{x0+8}" y="{y0+16}" font-size="12" font-weight="700" fill="#8A6A10" font-family="system-ui">Stage: keep clear</text>'
             + egg_ghost(196, y1 - 4) + f'<text x="236" y="{y1-36}" font-size="11" font-weight="700" fill="{INK}" font-family="system-ui">Puggle, 70</text>'
             + sl('M16 40H86', 1.2*1, INK, ' stroke-opacity="0.5"') + sl('M16 58H86', 1.8) + sl('M16 76H86', 2.2)
             + ''.join(f'<text x="94" y="{y+4}" font-size="11" font-weight="700" fill="{INK}" font-family="system-ui">{t}</text>' for y, t in ((40, 'Far: 1.2, softened'), (58, 'Middle: 1.8'), (76, 'Front: 2.2'))))
rules_card = (f'<div style="display: flex; gap: 24px; align-items: flex-start">{frame(rules_svg, "Scene rules diagram")}'
              f'<div style="display: flex; flex-direction: column; gap: 10px; width: 600px; {T}">'
              '<div><b>Two horizons.</b> Open places (beach, bush, harbour) at 40%; enclosed places (backyard, park, rain, pool, Grandma’s, street) at 70%. The set reads as one world.</div>'
              '<div><b>A stage.</b> The lower middle stays clear for the cast. Props go to the sides and the back.</div>'
              '<div><b>One scale.</b> Puggle is 70 units tall in a 390 × 300 scene. Props are sized to her: gumboots to her shin, a bucket to her knee, the umbrella about twice her height.</div>'
              '<div><b>Line weight shows distance.</b> Far things get a thin, softened line; the middle 1.8; the front 2.2. Big flat areas (sea, sand, lawn) have no outline, only a line at the horizon.</div>'
              '<div><b>Light and weather per scene.</b> The sun appears only where it helps; three cloud shapes; one hero object and two or three supporting ones.</div></div></div>')

KIT = [('Cloud, puffy', cloudA(40, 44, 64), '0 0 80 70'), ('Cloud, small', cloudB(40, 44, 50), '0 0 80 70'), ('Cloud, overcast', cloudC(40, 44, 72), '0 0 80 70'),
       ('Gum tree', gum(40, 100, 100), '0 0 80 104'), ('Norfolk pine', pine(40, 104, 100), '0 0 80 108'), ('Ferry', ferry(60, 66, 1), '0 0 120 72'),
       ('Arch bridge', bridge2(40, 110, 70), '-4 8 158 68'), ('Umbrella', umbrella(40, 82, 32), '0 -4 80 90'), ('Surf flags', flags(22, 76), '0 0 80 80'),
       ('Sandcastle', castle(40, 70), '0 0 80 76'), ('Hills Hoist', place(hoist2(150), 80, 160, 1), '0 0 160 170'), ('Sprinkler', place(sprinkler2(), 50, 56, 1), '0 0 100 64'),
       ('Paddling pool', place(pool3d(40), 50, 30, 1), '0 0 100 50'), ('Gumboots', place(boots(), 22, 36, 1), '10 0 60 40'), ('Lane rope', lane(20, WARATAH, PAPER, 0, 100), '0 0 100 40'),
       ('Terrace', terrace2(8, 150, 64, 100, SHELL), '0 0 80 156'), ('Windmill', windmill(50, 200, 150), '0 10 100 196'), ('Sheep', sheep(36, 40, 1), '0 6 70 38'), ('Café table', table_set(60, 66), '0 4 120 64'), ('Fruit crate', crate(17, 40, WARATAH), '10 6 60 36'), ('Awning', awning(0, 120, 10, WARATAH), '-4 4 128 36'), ('Cat', place(cat(), 40, 50, 1.2), '0 0 80 56'), ('Street lamp', lamp(40, 116), '0 0 80 120')]
kit_html = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 100px"><div style="width: 100px; height: 88px; border-radius: 16px; background: {PAPER}; display: flex; align-items: center; justify-content: center">'
                   f'<svg role="img" aria-label="{n}" width="80" height="74" viewBox="{vb}" preserveAspectRatio="xMidYMid meet">{s}</svg></div><div style="font-size: 12px; font-weight: 700; text-align: center">{n}</div></div>' for n, s, vb in KIT)

body = f'''<div style="width: 1080px; height: 2300px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Set pieces and backgrounds</h1>
<div style="{T}; font-size: 15px; max-width: 940px">Places from a Sydney family's week, in the house style. Second pass: one set of scene rules, so every place feels like the same world.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Scene rules</div>{rules_card}</div>
<div style="display: flex; flex-wrap: wrap; gap: 22px 24px">{scene_html}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Kit of parts</div><div style="display: flex; flex-wrap: wrap; gap: 10px 8px">{kit_html}</div></div>
</div>'''
wrap('Set pieces and backgrounds', body, 1080, 2300, 'Scenes.dc.html', 0)
c = json.load(open(P + 'canvas.json'))
c['boards']['Scenes.dc.html'].update(page='brand', x=1200, y=3640)
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
