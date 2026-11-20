import sys, json, math, random
ROOT = sys.argv[1]
_l = open(ROOT + '/gen/lineup.py').read()
cx = {'__name__': 'x', 'sys': sys}
exec(_l[:_l.index('GROUND = 470')], cx)
X = cx['x']; ACC = cx['A']; wrap = cx['w']['wrap']
p, limb, head, pbody, small = X['p'], X['limb'], X['head'], X['body'], X['small']
O, PF, BILL, BL, ST = '#3A2A20', '#8A5A3C', '#6E7F8D', '#EE9C88', '#C24A36'
PAPER, SAND, SKY, SHELL, MINT, SUN, MOON = '#FBF6E9', '#F2ECDD', '#BFD9F5', '#F3D9C9', '#CFE5D2', '#F4E7B0', '#F3E0B8'
A, HARBOUR, GUM, WARATAH, BLUSH, NIGHT = '#F4BE2C', '#2A62B8', '#3C9A5F', '#E5553B', '#EE9C88', '#1B2440'
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
def mix(c1, c2, t):
    a_, b_ = [int(c1[i:i+2], 16) for i in (1, 3, 5)], [int(c2[i:i+2], 16) for i in (1, 3, 5)]
    return '#' + ''.join(f'{round(u + (v - u)*t):02X}' for u, v in zip(a_, b_))
def quatre(cx_, cy, r):
    q = r*0.5
    return ''.join(f'<circle cx="{cx_+dx*q:.1f}" cy="{cy+dy*q:.1f}" r="{q*1.05:.1f}"></circle>' for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0))) + f'<circle cx="{cx_:.1f}" cy="{cy:.1f}" r="{q*0.9:.1f}"></circle>'
TRAP = 'M88 166Q120 156 152 166L180 244Q182 254 170 254L70 254Q58 254 60 244Z'

# ---------- 1. patterned outfits ----------
def pat_quatre(c):
    return f'<g fill="{c}">' + ''.join(quatre(60 + col*22 + (11 if row % 2 else 0), 164 + row*19, 8) for row in range(6) for col in range(7)) + '</g>'
def pat_leaf(c):
    rnd = random.Random(3); out = ''
    for row in range(6):
        for col in range(7):
            x, y = 58 + col*24 + (12 if row % 2 else 0), 166 + row*20
            out += f'<path d="M0 -9C7 -4 7 5 0 9C-7 5 -7 -4 0 -9Z" fill="{c}" transform="translate({x} {y}) rotate({rnd.choice([-40, -15, 20, 45])})"></path>'
    return out
def pat_wattle(c, c2):
    rnd = random.Random(6); out = ''
    for row in range(6):
        for col in range(7):
            x, y = 58 + col*24 + (12 if row % 2 else 0), 164 + row*20
            out += f'<circle cx="{x}" cy="{y}" r="5.5" fill="{c}"></circle><circle cx="{x+8}" cy="{y+5}" r="4" fill="{c}"></circle><path d="M{x-8} {y+8}q6 -2 10 -8" fill="none" stroke="{c2}" stroke-width="2.4" stroke-linecap="round"></path>'
    return out
def outfit(col, pattern, uid, e='happy', arms='down'):
    L = ''.join(limb(*a[:4], col, a[4]) for a in X['ARMS'][arms])
    return (p['tail'](PF) + p['legs'](PF) + p['feet'](BILL) + p['trap'](col)
            + f'<clipPath id="tp{uid}"><path d="{TRAP}"></path></clipPath><g clip-path="url(#tp{uid})">{pattern}</g>'
            + f'<path d="{TRAP}" fill="none" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>' + L + head(e) + ACC['clip'](160, 56, WARATAH))
plain = pbody('down', 'happy', HARBOUR) + ACC['clip'](160, 56, WARATAH)

# ---------- 2. flat version, no outline ----------
def flat(col, e='happy', arms='down', fur=PF, small_=False):
    fd, cd = mix(fur, '#3A2A20', 0.22), mix(col, '#3A2A20', 0.16)
    s = f'<ellipse cx="184" cy="246" rx="36" ry="16" transform="rotate(-28 184 246)" fill="{fd}"></ellipse>'
    s += ''.join(f'<rect x="{x0}" y="240" width="28" height="40" rx="11" fill="{fd}"></rect>' for x0 in (86, 126))
    s += ''.join(f'<ellipse cx="{x0}" cy="282" rx="26" ry="11" fill="{BILL}"></ellipse>' for x0 in (100, 140))
    s += f'<path d="{TRAP}" fill="{col}" stroke="{col}" stroke-width="6" stroke-linejoin="round"></path>'
    for x0, y0, x1, y1, bend in X['ARMS'][arms]:
        mx, my = (x0 + x1)/2, (y0 + y1)/2; dx, dy = y1 - y0, x0 - x1; n = math.hypot(dx, dy) or 1
        s += f'<path d="M{x0} {y0}Q{mx + dx/n*bend:.1f} {my + dy/n*bend:.1f} {x1} {y1}" fill="none" stroke="{cd}" stroke-width="28" stroke-linecap="round"></path><circle cx="{x1}" cy="{y1}" r="15" fill="{fur}"></circle>'
    s += f'<ellipse cx="120" cy="108" rx="74" ry="64" fill="{fur}"></ellipse>'
    s += ''.join(f'<circle cx="{x0}" cy="127" r="11" fill="{BL}"></circle>' for x0 in (67, 173))
    s += f'<ellipse cx="120" cy="151" rx="50" ry="22" fill="{BILL}"></ellipse>'
    if e == 'happy': s += ''.join(f'<path d="M{x0-10} 111q10 -12 20 0" fill="none" stroke="{O}" stroke-width="7" stroke-linecap="round"></path>' for x0 in (93, 147))
    else: s += ''.join(f'<circle cx="{x0}" cy="108" r="8" fill="{O}"></circle>' for x0 in (93, 147))
    s += f'<g fill="{WARATAH}">{quatre(160, 56, 34)}</g><circle cx="160" cy="56" r="5" fill="{mix(WARATAH, "#3A2A20", 0.25)}"></circle>'
    return s

# ---------- 3. walking, side on ----------
def leg(hx, hy, fx, fy, lift=0):
    return (f'<path d="M{hx} {hy}L{fx} {fy}" stroke="{O}" stroke-width="28" stroke-linecap="round"></path><path d="M{hx} {hy}L{fx} {fy}" stroke="{PF}" stroke-width="16" stroke-linecap="round"></path>'
            f'<ellipse cx="{fx+10}" cy="{fy+6}" rx="24" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6" transform="rotate({lift} {fx} {fy})"></ellipse>')
def walk(frame, col=HARBOUR, e='happy'):
    bob = 0 if frame == 0 else -5
    if frame == 0: legs = leg(104, 238, 78, 272, 8) + leg(124, 238, 152, 270, -14); arm_b, arm_f = limb(112, 180, 82, 218, col, 4), limb(124, 178, 158, 212, col, -4)
    else: legs = leg(110, 238, 104, 276, 0) + leg(120, 238, 128, 262, -24); arm_b, arm_f = limb(114, 180, 104, 224, col, 2), limb(122, 178, 134, 224, col, -2)
    eye = f'<path d="M132 111q10 -12 20 0" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>' if e == 'happy' else f'<circle cx="142" cy="108" r="7.6" fill="{O}"></circle>'
    top = (f'<ellipse cx="54" cy="238" rx="40" ry="14" transform="rotate({22 if frame == 0 else 10} 54 238)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' + arm_b
           + f'<path d="M92 166Q118 158 144 166L160 244Q162 254 150 254L84 254Q72 254 74 244Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>' + arm_f
           + f'<ellipse cx="108" cy="108" rx="62" ry="58" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
           + f'<circle cx="112" cy="130" r="10" fill="{BL}"></circle><path d="M105 135l5-9M114 135l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>'
           + f'<ellipse cx="164" cy="150" rx="40" ry="18" transform="rotate(-4 164 150)" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="186" cy="141" r="1.8" fill="{O}"></circle>' + eye + ACC['clip'](132, 56, WARATAH))
    return legs + f'<g transform="translate(0 {bob})">{top}</g>'

def fig(inner, h, label, bg=None, vb='0 0 240 300'):
    st = f' style="background: {bg}; border-radius: 20px"' if bg else ''
    w_, h_ = [float(v) for v in vb.split()[2:]]
    return f'<svg role="img" aria-label="{label}" width="{h*w_/h_:.0f}" height="{h}" viewBox="{vb}"{st}>{inner}</svg>'
def cap(svg, name, note, w=170):
    return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: {w}px">{svg}<div style="font-size: 14px; font-weight: 800">{name}</div><div style="{T}; font-size: 12px; text-align: center">{note}</div></div>'
def section(title, intro, row):
    return f'<div style="display: flex; flex-direction: column; gap: 10px"><div><div style="font-size: 20px; font-weight: 800">{title}</div><div style="{T}">{intro}</div></div><div style="display: flex; gap: 14px; align-items: flex-start">{row}</div></div>'

s1 = section('1. A patterned outfit', 'Her dress takes a small print from our motif family. Sleeves stay plain so the arms still read. Each print is a real fabric repeat.',
             cap(fig(plain, 200, 'Puggle in the plain blue dress'), 'Now', 'Plain colour.')
             + cap(fig(outfit(HARBOUR, pat_quatre(PAPER), 'a'), 200, 'Puggle in a blue dress printed with cream quatrefoils'), 'Quatrefoil', 'Her own mark, cream on blue.')
             + cap(fig(outfit(MINT, pat_leaf(GUM), 'b'), 200, 'Puggle in a mint dress printed with green gum leaves'), 'Gum leaf', 'Green on mint.')
             + cap(fig(outfit(PAPER, pat_wattle(A, GUM), 'c'), 200, 'Puggle in a cream dress printed with wattle sprigs'), 'Wattle', 'Yellow blossom on cream.')
             + cap(fig(small(outfit(HARBOUR, pat_quatre(PAPER), 'd')), 84, 'Small Puggle in the quatrefoil dress'), 'At scene size', 'The print still reads as texture.', 130))
s2 = section('2. A flat version', 'No outline at all: shapes and tones only. Arms and legs are a shade deeper than the dress and fur so they separate. For prints, wallpapers and small sizes.',
             cap(fig(flat(HARBOUR, 'neutral'), 200, 'Flat Puggle on yellow', A), 'On colour', 'Sits on Wattle without a line.')
             + cap(fig(flat(WARATAH, 'happy', 'wave'), 200, 'Flat Puggle waving on sky blue', SKY), 'Waving', 'Poses carry over.')
             + cap(fig(flat(SKY, 'happy', 'up'), 200, 'Flat Puggle on night blue', NIGHT), 'At night', 'Reads on dark too.')
             + cap(f'<div style="display: flex; gap: 6px; align-items: flex-end; height: 200px">{fig(flat(HARBOUR, "happy"), 96, "Flat Puggle, small")}{fig(flat(HARBOUR, "happy"), 60, "Flat Puggle, smaller")}{fig(flat(HARBOUR, "happy"), 36, "Flat Puggle, tiny")}</div>', 'Small sizes', 'Holds down to icon size, where the outlined version clogs.', 210))
parade = ''.join(f'<g transform="translate({20 + i*118} {8 if i % 2 else 0}) scale(0.5)">{small(walk(i % 2, c))}</g>' for i, c in enumerate((HARBOUR, WARATAH, A, GUM)))
s3 = section('3. Walking', 'A side-on walk in two key poses: the stride, and the passing step with a small bounce. The tail and arms swing against the legs. Enough for books now, and the two keys Rive needs later.',
             cap(fig(walk(0), 200, 'Puggle walking, stride pose', None, '0 0 250 300'), 'Stride', 'Legs apart, arms opposite.')
             + cap(fig(walk(1), 200, 'Puggle walking, passing pose', None, '0 0 250 300'), 'Passing', 'Legs together, body lifts.')
             + cap(f'<svg role="img" aria-label="Four small Puggles walking in a line" width="430" height="170" viewBox="0 0 500 196" style="background: {MINT}; border-radius: 20px"><path d="M0 162H500V196H0Z" fill="#B2D3B9"></path>{parade}</svg>', 'In a row', 'Alternating the two poses makes a parade.', 430))
body = f'''<div style="width: 1080px; height: 1170px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Puggle: three additions</h1>
<div style="{T}; font-size: 15px">Proposals only. Her face and proportions are unchanged; these add range, they don't redesign her.</div></div>
{s1}{s2}{s3}
</div>'''
wrap('Puggle: three additions', body, 1080, 1170, 'PuggleAdds.dc.html', 0)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['PuggleAdds.dc.html'].update(page='characters', x=0, y=4180)
o = c['order']; o.remove('PuggleAdds.dc.html'); o.insert(o.index('ModelSheet.dc.html') + 1, 'PuggleAdds.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
