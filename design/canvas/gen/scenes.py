import sys, math, json
ROOT = sys.argv[1]
src = open(ROOT + '/gen/style.py').read()
exec(src[:src.index('# ---- BOARD ----')])
exec(src[src.index('# ---- BOARD ----'):src.index('# 1. Lineage')])
P = ROOT + '/project/'
BILL = '#6E7F8D'
SEA, HAZE1, HAZE2, HAZE3, LAWN, LAWN2, DUSK = '#7FA9E0', '#D5E5F7', '#A9C6EC', '#7FA9E0', '#CFE5D2', '#B9D8BF', '#F7D9B5'
SW = 2.2
def sl(d, w=SW, col=INK, extra=''): return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"{extra}></path>'
def fp(d, c, w=SW): return f'<path d="{d}" fill="{c}" stroke="{INK}" stroke-width="{w}" stroke-linejoin="round"></path>'
def flat(d, c): return f'<path d="{d}" fill="{c}"></path>'
def ci(cx, cy, r, c, w=SW): return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="{c}" stroke="{INK}" stroke-width="{w}"></circle>'
def R(x, y, w, h, r): return rr(round(x, 2), round(y, 2), round(w, 2), round(h, 2), r)
def scallop(cx, cy, rx, ry, n, flat_bottom=False):
    pts = [(cx + rx*math.cos(math.radians(180 + i*360/n)), cy + ry*math.sin(math.radians(180 + i*360/n))) for i in range(n)]
    if flat_bottom:
        pts = [(cx + rx*math.cos(math.radians(180 + i*180/(n-1))), cy + ry*math.sin(math.radians(180 + i*180/(n-1)))) for i in range(n)]
    d = f'M{pts[0][0]:.1f} {pts[0][1]:.1f}'
    rng = range(1, n) if flat_bottom else range(1, n + 1)
    for i in rng:
        p, q = pts[i-1], pts[i % n]; r = math.hypot(q[0]-p[0], q[1]-p[1]) * 0.62
        d += f'A{r:.1f} {r:.1f} 0 0 1 {q[0]:.1f} {q[1]:.1f}'
    return d + 'Z'
def quat(cx, cy, r, c): return flat(quatre(cx, cy, r), c)

# ---- elements (anchored at base centre unless noted) ----
def cloud(cx, cy, w): return fp(scallop(cx, cy, w/2, w/5, 7, True), PAPER)
def sun(cx, cy, r, rays=True):
    out = ci(cx, cy, r, A)
    if rays:
        for i in range(8):
            a = math.radians(i*45 + 22.5); out += sl(f'M{cx + math.cos(a)*(r+7):.1f} {cy + math.sin(a)*(r+7):.1f}L{cx + math.cos(a)*(r+14):.1f} {cy + math.sin(a)*(r+14):.1f}')
    return out
def gum(x, y, h, c=GUM, lean=6):
    t = f'M{x-4} {y}C{x-3} {y-h*0.3} {x+lean-3} {y-h*0.45} {x+lean-2} {y-h*0.62}M{x+4} {y}C{x+4} {y-h*0.3} {x+lean+3} {y-h*0.45} {x+lean+3} {y-h*0.62}'
    trunk = flat(f'M{x-4} {y}C{x-3} {y-h*0.3} {x+lean-3} {y-h*0.45} {x+lean-2} {y-h*0.62}H{x+lean+3}C{x+lean+3} {y-h*0.45} {x+4} {y-h*0.3} {x+4} {y}Z', SHELL) + sl(t)
    can = fp(scallop(x+lean, y-h*0.72, h*0.34, h*0.26, 8), c) + fp(scallop(x+lean-h*0.22, y-h*0.55, h*0.16, h*0.12, 6), c)
    return trunk + can
def pine(x, y, h):
    out = sl(f'M{x} {y}V{y-h*0.2}', 3)
    for i in range(4):
        w = h*(0.42 - i*0.08); yy = y - h*0.15 - i*h*0.2
        out += fp(rpoly([(x-w, yy), (x+w, yy), (x, yy - h*0.3)], 4), GUM)
    return out
def rpoly(pts, rad):
    n = len(pts)
    def cut(p, q, d):
        dx, dy = q[0]-p[0], q[1]-p[1]; l = math.hypot(dx, dy); k = min(d, l/2)/l; return (p[0]+dx*k, p[1]+dy*k)
    segs = [(cut(pts[i], pts[i-1], rad), pts[i], cut(pts[i], pts[(i+1) % n], rad)) for i in range(n)]
    s = segs[-1][2]; out = f'M{s[0]:.1f} {s[1]:.1f}'
    for a, c, b in segs: out += f'L{a[0]:.1f} {a[1]:.1f}Q{c[0]:.1f} {c[1]:.1f} {b[0]:.1f} {b[1]:.1f}'
    return out + 'Z'
def waves(x0, x1, y, amp=4, step=18, col=PAPER, w=SW):
    d = f'M{x0} {y}'; x = x0
    while x < x1: d += f'q{step/4} {-amp} {step/2} 0t{step/2} 0'; x += step
    return sl(d, w, col)
def gull(x, y, s=1): return sl(f'M{x} {y}q{6*s} {-7*s} {12*s} 0q{6*s} {-7*s} {12*s} 0')
def umbrella(x, y, r=42, c=WARATAH):
    top = y - 70
    out = sl(f'M{x} {top}L{x+8} {y}', 2.6)
    can = f'M{x-r} {top+4}A{r} {r*0.8} 0 0 1 {x+r} {top+4}Q{x} {top-6} {x-r} {top+4}Z'
    out += fp(can, PAPER)
    for i in (0, 2, 4):
        a0, a1 = math.radians(180 + i*36), math.radians(180 + (i+1)*36)
        p0 = (x + r*math.cos(a0), top + 4 + r*0.8*math.sin(a0)); p1 = (x + r*math.cos(a1), top + 4 + r*0.8*math.sin(a1))
        out += flat(f'M{x} {top-1}L{p0[0]:.1f} {p0[1]:.1f}A{r} {r*0.8} 0 0 1 {p1[0]:.1f} {p1[1]:.1f}Z', c)
    out += sl(can) + ci(x, top - r*0.8 + 3, 2.6, A, 1.8)
    return out
def flags(x, y):
    out = ''
    for dx in (0, 34):
        px = x + dx
        out += sl(f'M{px} {y}V{y-62}', 2.4)
        out += flat(f'M{px} {y-60}h20v8h-20z', WARATAH) + flat(f'M{px} {y-52}h20v8h-20z', A) + sl(f'M{px} {y-60}h20v16h-20')
    return out
def castle(x, y):
    b = f'M{x-26} {y}V{y-22}h7v-6h6v6h7v-6h6v6h7v-6h6v6h4V{y}Z'
    t = f'M{x-9} {y-28}V{y-44}h4v-5h5v5h4v-5h4v16Z'
    return fp(t, SUN) + fp(b, SUN) + fp(R(x-5, y-12, 9, 12, 4.5), '#E8D696') + sl(f'M{x+1} {y-49}V{y-62}') + flat(f'M{x+1} {y-62}l10 3.5-10 3.5z', WARATAH)
def bucket(x, y):
    return fp(f'M{x-12} {y-22}h24l-3 22h-18z', WARATAH) + sl(f'M{x-11} {y-22}q11 -14 22 0') + sl(f'M{x+16} {y}l12 -26', 2.4) + fp(R(x+25, y-34, 8, 10, 3), A)
def towel(x, y):
    out = flat(f'M{x} {y}l70 -10l8 26l-70 10z', BLUSH)
    for k in (0.33, 0.66): out += flat(f'M{x + 70*k:.1f} {y - 10*k:.1f}l8 26l-6 1l-8 -26z', PAPER)
    return out + sl(f'M{x} {y}l70 -10l8 26l-70 10z')
def ferry(x, y, s=1):
    hull = f'M{x-50*s} {y-14*s}H{x+50*s}L{x+42*s} {y}H{x-42*s}Z'
    cab = R(x-36*s, y-30*s, 72*s, 16*s, 4*s); top = R(x-20*s, y-42*s, 40*s, 12*s, 3*s)
    out = fp(hull, GUM) + fp(cab, PAPER) + flat(R(x-36*s, y-20*s, 72*s, 6*s, 0), A) + sl(cab) + fp(top, PAPER)
    for i in range(6): out += f'<circle cx="{x - 28*s + i*11.2*s:.1f}" cy="{y-25*s:.1f}" r="{2.2*s:.1f}" fill="{INK}"></circle>'
    out += sl(f'M{x} {y-42*s}V{y-52*s}') + flat(f'M{x} {y-52*s}l{10*s} {3.5*s}-{10*s} {3.5*s}z', WARATAH)
    return out
def sailboat(x, y, s=1, c=WARATAH):
    return (fp(f'M{x-20*s} {y-8*s}H{x+20*s}L{x+14*s} {y}H{x-14*s}Z', c) + sl(f'M{x} {y-8*s}V{y-58*s}')
            + fp(f'M{x+2*s} {y-56*s}L{x+22*s} {y-14*s}H{x+2*s}Z', PAPER) + fp(f'M{x-2*s} {y-46*s}L{x-16*s} {y-14*s}H{x-2*s}Z', PAPER))
def bridge(x0, x1, y):
    span = x1 - x0; mid = (x0 + x1) / 2; top = y - span*0.42
    outer = f'M{x0} {y}Q{mid} {top - span*0.42} {x1} {y}'
    inner = f'M{x0+14} {y}Q{mid} {top - span*0.18} {x1-14} {y}'
    band = f'M{x0} {y}Q{mid} {top - span*0.42} {x1} {y}L{x1-14} {y}Q{mid} {top - span*0.18} {x0+14} {y}Z'
    out = flat(band, BILL)
    for i in range(1, 12):
        t = i/12; xx = x0 + 14 + (span-28)*t
        # height of inner arc at xx (quadratic Bezier approx)
        u = (xx - x0 - 14)/(span - 28); yy = (1-u)**2*y + 2*(1-u)*u*(top - span*0.18) + u*u*y
        out += sl(f'M{xx:.1f} {yy:.1f}V{y}', 1.4)
    out += sl(outer) + sl(inner) + sl(f'M{x0-40} {y}H{x1+40}', 3)
    for px in (x0 - 14, x1 + 14):
        out += fp(R(px-10, y-44, 20, 44, 3), SHELL) + sl(f'M{px-10} {y-30}h20', 1.4)
    return out
def skyline(x, y):
    out = ''
    for i, (w, h, c) in enumerate([(26, 60, SHELL), (20, 84, PAPER), (30, 50, SKY), (22, 96, SHELL), (28, 70, PAPER), (20, 54, SUN)]):
        out += fp(R(x, y-h, w, h, 4), c)
        for row in range(int(h/14) - 1):
            out += flat(R(x+5, y-h+8+row*14, w-10, 3, 1.5), INK if (i+row) % 3 else A).replace('fill="' + INK + '"', f'fill="{INK}" opacity="0.35"')
        x += w + 4
    return out
def ridges(layers):
    return ''.join(fp(d, c) for d, c in layers)
def hoist(x, y, h=120):
    top = y - h
    out = sl(f'M{x} {y}V{top}', 2.6) + sl(f'M{x-60} {top+6}L{x} {top-12}L{x+60} {top+6}L{x} {top+24}Z') + sl(f'M{x-60} {top+6}H{x+60}M{x} {top-12}V{top+24}', 1.6)
    for dx, dy, c, w in ((-44, 8, BLUSH, 16), (-20, 16, SKY, 14), (16, 15, A, 18), (40, 8, MINT, 14)):
        out += fp(R(x+dx, top+dy, w, 18, 3), c, 1.8)
    return out + fp(R(x-10, y-3, 20, 6, 3), BILL, 1.8)
def lemon(x, y, h=110):
    out = fp(f'M{x-4} {y}V{y-h*0.5}h8V{y}Z', FUR) + fp(scallop(x, y-h*0.68, h*0.36, h*0.3, 9), GUM)
    for dx, dy in ((-18, -78), (10, -88), (22, -66), (-6, -62), (-24, -58)):
        out += f'<ellipse cx="{x+dx*h/110:.1f}" cy="{y+dy*h/110:.1f}" rx="4.6" ry="3.6" fill="{A}" stroke="{INK}" stroke-width="1.6"></ellipse>'
    return out
def fence(x0, x1, y, h=56):
    out = ''; x = x0
    while x < x1:
        out += fp(f'M{x} {y}V{y-h+6}Q{x+7} {y-h-2} {x+14} {y-h+6}V{y}Z', PAPER, 1.8); x += 16
    return out + sl(f'M{x0} {y-h*0.3}H{x1}M{x0} {y-h*0.75}H{x1}', 1.6)
def pool(x, y): return f'<ellipse cx="{x}" cy="{y}" rx="46" ry="15" fill="{BLUSH}" stroke="{INK}" stroke-width="{SW}"></ellipse><ellipse cx="{x}" cy="{y+1}" rx="36" ry="9" fill="{SKY}" stroke="{INK}" stroke-width="1.6"></ellipse>'
def sprinkler(x, y):
    out = sl(f'M{x-6} {y}h12', 2.6) + sl(f'M{x} {y}v-6', 2.2)
    for r in (22, 36, 50):
        out += sl(f'M{x-r} {y-6}A{r} {r*0.9} 0 0 1 {x+r} {y-6}', 1.6, HARBOUR, ' stroke-dasharray="2 7"')
    return out
def slide(x, y):
    return (sl(f'M{x} {y}V{y-80}M{x+18} {y}V{y-80}', 2.6) + sl(''.join(f'M{x} {y-14-i*16}h18' for i in range(4)), 1.8)
            + fp(f'M{x+18} {y-80}C{x+50} {y-80} {x+60} {y-6} {x+96} {y-4}l-2 8C{x+52} {y+4} {x+44} {y-70} {x+18} {y-70}Z', WARATAH) + fp(R(x-4, y-88, 26, 10, 4), A))
def swing(x, y):
    out = sl(f'M{x-40} {y}L{x-28} {y-86}L{x-16} {y}M{x+40} {y}L{x+28} {y-86}L{x+16} {y}M{x-30} {y-86}H{x+30}', 2.6)
    for sx, c in ((-12, SKY), (12, MINT)):
        out += sl(f'M{x+sx-6} {y-86}V{y-28}M{x+sx+6} {y-86}V{y-28}', 1.4) + fp(R(x+sx-9, y-30, 18, 6, 3), c, 1.8)
    return out
def rug(x, y):
    d = f'M{x} {y}l90 -14l14 34l-90 14z'
    out = flat(d, PAPER)
    for i in range(1, 6):
        t = i/6; out += sl(f'M{x+90*t:.1f} {y-14*t:.1f}l14 34', 3.2, BLUSH) + sl(f'M{x+14*t:.1f} {y+34*t:.1f}l90 -14', 3.2, BLUSH)
    return out + sl(d)
def kite(x, y):
    d = rpoly([(x, y-26), (x+18, y), (x, y+30), (x-18, y)], 3)
    return fp(d, A) + sl(f'M{x} {y-26}V{y+30}M{x-18} {y}H{x+18}', 1.4) + sl(f'M{x} {y+30}q-10 18 4 30q12 14 -2 30', 1.6) + \
           ''.join(fp(rpoly([(bx-6, by-4), (bx+6, by+4), (bx+6, by-4), (bx-6, by+4)], 1), c, 1.4) for bx, by, c in ((x-2, y+48, WARATAH), (x+2, y+74, SKY)))
def terrace(x, y, w, h, c, lit=(True, False)):
    roof = f'M{x} {y-h}V{y-h-12}Q{x+w/2} {y-h-30} {x+w} {y-h-12}V{y-h}'
    out = fp(f'M{x} {y}V{y-h-12}Q{x+w/2} {y-h-30} {x+w} {y-h-12}V{y}Z', c) + sl(f'M{x} {y-h}H{x+w}', 1.6)
    out += fp(R(x+w*0.18, y-h*0.62, w*0.26, h*0.34, 4), A if lit[0] else NIGHT, 1.8) + fp(R(x+w*0.56, y-h*0.62, w*0.26, h*0.34, 4), A if lit[1] else NIGHT, 1.8)
    out += fp(R(x+w*0.38, y-h*0.22, w*0.24, h*0.22, 3), FUR, 1.8)
    out += sl(f'M{x+4} {y-h*0.08}H{x+w-4}', 1.4)
    return out
def lamp(x, y):
    return (f'<circle cx="{x}" cy="{y-92}" r="26" fill="{A}" opacity="0.22"></circle>' + sl(f'M{x} {y}V{y-84}', 2.6) + fp(R(x-8, y-100, 16, 16, 5), A))
def moon(cx, cy, r):
    return fp(f'M{cx+r*0.3} {cy-r}A{r} {r} 0 1 0 {cx+r} {cy+r*0.35}A{r*0.8} {r*0.8} 0 0 1 {cx+r*0.3} {cy-r}Z', MOON)
def waterfall(x, y0, y1):
    out = fp(R(x, y0, 18, y1-y0, 6), PAPER)
    for i in range(3): out += sl(f'M{x+5+i*4} {y0+8+i*6}v{(y1-y0)*0.5}', 1.4, SEA)
    return out
def lookout(x, y):
    return sl(f'M{x} {y}V{y-26}M{x+30} {y}V{y-26}M{x+60} {y}V{y-26}M{x-4} {y-26}H{x+64}M{x} {y-13}H{x+60}', 2.4)
def sign(x, y):
    return sl(f'M{x} {y}V{y-48}', 2.6) + fp(f'M{x-4} {y-46}h28l8 7-8 7h-28z', PAPER, 1.8) + sl(f'M{x+2} {y-39}h16', 1.4)
def shell_(x, y):
    d = f'M{x-12} {y}Q{x-14} {y-16} {x} {y-18}Q{x+14} {y-16} {x+12} {y}Z'
    return fp(d, BLUSH, 1.8) + sl(f'M{x} {y}V{y-16}M{x-5} {y}L{x-7} {y-14}M{x+5} {y}L{x+7} {y-14}', 1.2)


def rainbow(cx, cy, r):
    out = ''
    for i, c in enumerate((WARATAH, A, GUM, SKY)):
        rr_ = r - i*9; out += sl(f'M{cx-rr_} {cy}A{rr_} {rr_} 0 0 1 {cx+rr_} {cy}', 9, c)
    return out
def rain(x0, x1, y0, y1, seed=1):
    import random; rnd = random.Random(seed); out = ''
    for _ in range(46):
        x = rnd.uniform(x0, x1); y = rnd.uniform(y0, y1); out += sl(f'M{x:.1f} {y:.1f}l-3 9', 1.6, HARBOUR)
    return out
def puddle(x, y, w):
    return (f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="{w*0.22:.1f}" fill="{SKY}" stroke="{INK}" stroke-width="1.8"></ellipse>'
            + f'<ellipse cx="{x+w*0.15:.1f}" cy="{y}" rx="{w*0.4:.1f}" ry="{w*0.08:.1f}" fill="none" stroke="{PAPER}" stroke-width="1.6"></ellipse>')
def boot(x, y, flip=1):
    d = f'M{x} {y-34}h14v22q0 4 {4*flip if flip > 0 else 4} 6h{8 if flip > 0 else 8}q4 0 4 6H{x}Z'
    return fp(d, A) + sl(f'M{x} {y-28}h14', 1.4)
def snail(x, y):
    return (fp(f'M{x-14} {y}h30q4 0 4 -4l-3 -10-3 6h-6', MINT, 1.8) + ci(x, y-11, 10, BLUSH, 1.8)
            + sl(f'M{x} {y-11}m-5 0a5 5 0 1 1 5 5a2.5 2.5 0 1 1 -2.5 -2.5', 1.4) + sl(f'M{x+14} {y-12}l-2 -8M{x+18} {y-12}l2 -8', 1.4))
def bunting(x0, x1, y, cols):
    out = sl(f'M{x0} {y}Q{(x0+x1)/2} {y+22} {x1} {y}', 1.4); n = 9
    for i in range(n):
        t = (i + 0.5)/n; xx = x0 + (x1-x0)*t; yy = y + 22*2*t*(1-t)*1.0
        out += fp(rpoly([(xx-7, yy), (xx+7, yy), (xx, yy+14)], 2), cols[i % len(cols)], 1.6)
    return out
def ring(x, y, r=20):
    out = f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}" stroke="{INK}" stroke-width="{SW}"></circle>'
    for a in (0, 90, 180, 270):
        out += f'<path d="M{x} {y}L{x + r*math.cos(math.radians(a-25)):.1f} {y + r*math.sin(math.radians(a-25)):.1f}A{r} {r} 0 0 1 {x + r*math.cos(math.radians(a+25)):.1f} {y + r*math.sin(math.radians(a+25)):.1f}Z" fill="{WARATAH}"></path>'
    return out + f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="{INK}" stroke-width="{SW}"></circle>' + ci(x, y, r*0.45, SKY, 1.8)
def ladder(x, y):
    return sl(f'M{x} {y}V{y-30}q0-8 8-8M{x+20} {y}V{y-30}q0-8 8-8', 2.6) + sl(f'M{x} {y-10}h20', 1.6)
def cottage(x, y):
    w, h = 230, 96
    out = fp(f'M{x+150} {y-h-40}h18v34h-18z', SHELL)  # chimney
    out += sl(f'M{x+156} {y-h-48}q-8 -8 0 -16q8 -8 0 -16', 1.6, PAPER)
    out += fp(f'M{x} {y}V{y-h}H{x+w}V{y}Z', MINT)
    out += ''.join(sl(f'M{x} {y-h+i*12}H{x+w}', 1, INK, ' opacity="0.25"') for i in range(1, 8))
    out += fp(f'M{x-14} {y-h+4}L{x+40} {y-h-50}H{x+w-40}L{x+w+14} {y-h+4}Z', WARATAH)
    out += ''.join(sl(f'M{x+40+i*15} {y-h-48}L{x+i*17-4} {y-h+2}', 1, INK, ' opacity="0.3"') for i in range(1, 10))
    out += fp(f'M{x-10} {y-h+16}H{x+w+10}V{y-h+26}H{x-10}Z', PAPER, 1.8)  # verandah roof edge
    for px in (x, x+56, x+w-56, x+w): out += sl(f'M{px} {y-h+26}V{y}', 2.6)
    out += fp(R(x+w/2-16, y-58, 32, 58, 4), A) + ci(x+w/2+9, y-30, 2, INK, 1)
    for wx in (x+20, x+w-62):
        out += fp(R(wx, y-66, 42, 38, 4), SKY) + sl(f'M{wx+21} {y-66}V{y-28}M{wx} {y-47}H{wx+42}', 1.4)
    out += fp(f'M{x-6} {y}H{x+w+6}V{y+8}H{x-6}Z', SHELL, 1.8)
    return out
def picket(x0, x1, y, h=34):
    out = ''; x = x0
    while x < x1:
        out += fp(f'M{x} {y}V{y-h+6}L{x+5} {y-h}L{x+10} {y-h+6}V{y}Z', PAPER, 1.6); x += 14
    return out + sl(f'M{x0} {y-h*0.35}H{x1}M{x0} {y-h*0.75}H{x1}', 1.4)
def hydrangea(x, y, c):
    return fp(scallop(x, y, 24, 16, 8), GUM, 1.8) + fp(scallop(x-8, y-6, 9, 8, 6), c, 1.6) + fp(scallop(x+10, y-4, 9, 8, 6), c, 1.6)
def letterbox(x, y):
    return sl(f'M{x} {y}V{y-30}', 3) + fp(R(x-12, y-48, 24, 20, 6), WARATAH) + sl(f'M{x-6} {y-38}h12', 1.6)
def birdbath(x, y):
    return fp(f'M{x-6} {y}h12l-2-26h-8z', SHELL, 1.8) + fp(f'M{x-22} {y-30}q22 14 44 0z', SHELL, 1.8) + sl(f'M{x-14} {y-32}h28', 1.4, HARBOUR)

W, Hh = 390, 300
def frame(inner, label):
    return f'<svg role="img" aria-label="{label}" width="312" height="240" viewBox="0 0 {W} {Hh}" style="border-radius: 22px; display: block">{inner}</svg>'
def bg(c): return f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{c}"></rect>'

beach = (bg(SKY) + sun(322, 62, 22) + cloud(96, 70, 92) + cloud(214, 40, 60) + gull(150, 104) + gull(178, 92, 0.8)
         + fp('M-4 152Q46 116 118 152Z', GUM) + flat(f'M0 150H{W}V230H0Z', SEA) + sl(f'M0 150H{W}') + waves(20, 380, 176) + waves(0, 360, 198, 3, 22)
         + fp(f'M-4 214Q120 196 200 206T394 200V304H-4Z', SUN) + waves(-4, 394, 206, 3, 16, PAPER, 3)
         + pine(30, 262, 150) + umbrella(250, 252) + towel(150, 258) + castle(88, 268) + bucket(214, 286) + flags(322, 236) + shell_(30, 290) + shell_(370, 284))
bush = (bg(HAZE1) + sun(300, 70, 18, False)
        + ridges([('M-4 150Q60 92 130 118T260 96T394 110V304H-4Z', HAZE2), ('M-4 180Q80 132 170 160T320 140T394 150V304H-4Z', HAZE3),
                  ('M-4 214Q90 188 190 206T394 196V304H-4Z', LAWN)])
        + gull(210, 76, 0.8) + gull(150, 96, 0.7)
        + sl('M120 304C140 272 230 268 236 244S300 226 330 214', 7, SAND) + sl('M120 304C140 272 230 268 236 244S300 226 330 214', 1.6, INK, ' stroke-dasharray="1 9"')
        + gum(52, 290, 170) + gum(372, 280, 130, GUM, -6) + gum(190, 236, 70) + lookout(300, 214) + sign(84, 296))
harbour = (bg(DUSK) + sun(206, 44, 20, False) + cloud(70, 60, 80) + cloud(250, 46, 54)
           + skyline(232, 150) + flat(f'M0 150H{W}V{Hh}H0Z', SEA) + bridge(24, 196, 150)
           + waves(10, 380, 190, 3, 26) + waves(30, 380, 240, 3, 30) + waves(0, 360, 282, 3, 22)
           + sl('M164 268q-24 6-56 2', 2, PAPER) + sl('M168 276q-30 8-70 4', 2, PAPER) + ferry(228, 270, 1.1) + sailboat(330, 214, 0.8) + sailboat(60, 222, 0.6, A) + gull(286, 80))
yard = (bg(SKY) + sun(60, 54, 20) + cloud(250, 52, 90) + fence(0, W, 200) + flat(f'M0 196H{W}V{Hh}H0Z', LAWN) + sl(f'M0 196H{W}')
        + ''.join(flat(f'M{x} 196L{x+30} 300H{x+70}L{x+40} 196Z', LAWN2) for x in range(-20, 400, 80))
        + hoist(130, 262) + lemon(330, 236) + pool(250, 272) + sprinkler(64, 286))
park = (bg(SKY) + cloud(300, 44, 70) + kite(190, 70) + flat(f'M0 214H{W}V{Hh}H0Z', LAWN) + sl('M0 214Q200 200 390 216')
        + gum(56, 260, 210) + slide(250, 250) + swing(150, 252) + rug(96, 268))
night = (bg(NIGHT) + moon(312, 64, 28) + ''.join(quat(x, y, s, MOON) for x, y, s in ((60, 50, 6), (130, 30, 4), (200, 70, 5), (250, 30, 4), (370, 120, 4), (30, 110, 4)))
         + sl('M0 120Q150 160 390 118', 1.2, MOON)
         + terrace(0, 252, 76, 96, SHELL, (True, False)) + terrace(78, 252, 76, 110, SKY, (False, True)) + terrace(156, 252, 76, 96, MINT, (True, True))
         + terrace(234, 252, 76, 110, BLUSH, (False, False)) + terrace(312, 252, 78, 96, SUN, (True, False))
         + flat(f'M0 252H{W}V{Hh}H0Z', '#2C3658') + sl(f'M0 252H{W}', SW, MOON) + lamp(196, 292) + sl(f'M0 284H{W}', 1.4, MOON, ' stroke-dasharray="14 12" opacity="0.6"'))

RAINSKY = '#C9D5E2'
rainy = (bg(RAINSKY) + rainbow(330, 200, 70) + fp(scallop(120, 60, 90, 26, 9, True), PAPER) + fp(scallop(290, 44, 70, 20, 8, True), PAPER)
         + rain(10, 380, 70, 230, 2) + flat(f'M0 214H{W}V{Hh}H0Z', LAWN2) + sl(f'M0 214Q190 204 390 216')
         + puddle(110, 262, 46) + puddle(270, 282, 32) + umbrella(220, 244, 40, A) + boot(70, 280) + boot(92, 282) + snail(318, 248) + gum(30, 226, 110))
pool_ = (bg(SKY) + sun(60, 50, 18) + fp('M140 30L380 60L250 120Z', MINT) + sl('M140 30L120 150M380 60L380 170M250 120L250 150', 1.8)
         + fp(f'M-4 150H{W+4}V{Hh+4}H-4Z', SHELL) + fp('M30 178H360L384 290H6Z', SEA)
         + ''.join(sl(f'M{30 + 330*k/1:.1f} 178', 1) for k in ())
         + sl('M128 178L104 290', 3, WARATAH, ' stroke-dasharray="4 6"') + sl('M226 178L240 290', 3, A, ' stroke-dasharray="4 6"')
         + waves(40, 340, 210, 2.5, 22) + waves(20, 360, 250, 2.5, 26)
         + bunting(30, 360, 150, [WARATAH, A, SKY, MINT, BLUSH]) + ring(300, 236) + ladder(330, 182) + fp(R(60, 262, 34, 16, 6), A, 1.8))
grandma = (bg(SKY) + cloud(320, 40, 70) + sun(52, 46, 16)
           + flat(f'M0 236H{W}V{Hh}H0Z', LAWN) + cottage(80, 236) + sl(f'M0 236H{W}')
           + fp('M170 236L150 300H240L220 236Z', SAND, 1.8)
           + picket(0, 160, 284) + picket(230, 392, 284) + hydrangea(40, 244, SKY) + hydrangea(120, 252, BLUSH) + hydrangea(290, 250, SKY) + hydrangea(360, 244, BLUSH)
           + letterbox(246, 296) + birdbath(340, 296))
SCENES = [('Beach', beach, 'Norfolk pines, surf flags, an umbrella, a sandcastle. Bondi to Manly, but nowhere in particular.'),
          ('Bush walk', bush, 'Blue haze ridges, gums, a lookout and a track. Generic on purpose: no named rock formations.'),
          ('Sydney Harbour', harbour, 'A ferry, a coat-hanger arch and the city at dusk. We leave out the Opera House: its image is a registered trade mark.'),
          ('Backyard', yard, 'Hills Hoist with the washing, a paling fence, the lemon tree, a paddling pool and the sprinkler.'),
          ('The park', park, 'A big gum, a slide, swings, a picnic rug and a kite.'),
          ('Rainy day', rainy, 'Puddles, gumboots, a yellow umbrella, a snail and a rainbow breaking through.'),
          ('The pool', pool_, 'The local outdoor pool: lane ropes, a shade sail, flag bunting, a ring, a kickboard and the ladder.'),
          ("Grandma's house", grandma, 'A cottage with a red tin roof and a verandah, hydrangeas, a picket fence, the letterbox and a birdbath.'),
          ('Night street', night, 'Inner-west terraces, lit windows, a street lamp and quatrefoil stars. The bedtime scene.')]
scene_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 312px">{frame(s, n + " scene")}<div style="font-size: 16px; font-weight: 800">{n}</div><div style="{T}">{d}</div></div>' for n, s, d in SCENES)

KIT = [('Cloud', cloud(40, 44, 64), '0 0 80 70'), ('Sun', sun(40, 36, 16), '0 0 80 72'), ('Gum tree', gum(40, 100, 100), '0 0 80 104'), ('Norfolk pine', pine(40, 104, 100), '0 0 80 108'),
       ('Ferry', ferry(60, 66, 1), '0 0 120 72'), ('Sailboat', sailboat(40, 70), '0 0 80 76'), ('Umbrella', umbrella(40, 82, 32), '0 -4 80 90'), ('Surf flags', flags(22, 76), '0 0 80 80'),
       ('Sandcastle', castle(40, 70), '0 0 80 76'), ('Bucket and spade', bucket(32, 60), '0 10 80 56'), ('Hills Hoist', hoist(70, 140, 112), '0 10 140 136'), ('Lemon tree', lemon(50, 112), '0 0 100 116'),
       ('Kite', kite(40, 34), '0 0 80 112'), ('Terrace', terrace(8, 120, 64, 84, SHELL), '0 0 80 124'), ('Street lamp', lamp(40, 116), '0 0 80 120'), ('Moon', moon(40, 40, 26), '0 0 80 80'),
       ('Slide', slide(10, 96), '0 0 120 100'), ('Shell', shell_(40, 50), '0 20 80 36')]
kit_html = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 100px"><div style="width: 100px; height: 88px; border-radius: 16px; background: {PAPER}; display: flex; align-items: center; justify-content: center">'
                   f'<svg role="img" aria-label="{n}" width="80" height="74" viewBox="{vb}" preserveAspectRatio="xMidYMid meet">{s}</svg></div><div style="font-size: 12px; font-weight: 700; text-align: center">{n}</div></div>' for n, s, vb in KIT)

body = f'''<div style="width: 1080px; height: 1500px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Set pieces and backgrounds</h1>
<div style="{T}; font-size: 15px; max-width: 940px">Places from a Sydney family's week, in the house style: brand palette (plus soft tints of Sky and Harbour for water and distance), Ink line, everything rounded, quatrefoil stars. Each scene leaves the lower middle clear for the cast, and works as a book spread, a wallpaper or a header on Today.</div></div>
<div style="display: flex; flex-wrap: wrap; gap: 22px 24px">{scene_html}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Kit of parts</div><div style="display: flex; flex-wrap: wrap; gap: 10px 8px">{kit_html}</div></div>
</div>'''
wrap('Set pieces and backgrounds', body, 1080, 1500, 'Scenes.dc.html', 0)
c = json.load(open(P + 'canvas.json'))
c['boards']['Scenes.dc.html'].update(page='brand', x=1200, y=3640)
for k, y in (('Shapes.dc.html', 9500), ('Props2.dc.html', 10300)):
    c['boards'][k].update(page='archive', x=0, y=y)
o = c['order']; o.remove('Scenes.dc.html'); o.insert(o.index('Wallpapers.dc.html'), 'Scenes.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
