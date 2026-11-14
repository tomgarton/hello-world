#!/usr/bin/env python3
"""Turns the cast drawn on the design canvas into rigs the app can move.

The drawings come from design/canvas/gen/lineup.py ("The cast, to scale"): Nan, Mum, Dad, Pop,
Pebble, Quill, Kip, Digby and Sunny. Each is cut into the same parts as Puggle (body, legs, upper,
arms, head, eyes, tail), so the app's rig gives them her breathing, blinking and head tilts, and
they can borrow her moves (a nod, a wave, a hop).

    python3 tools/make_cast_rigs.py            # from app/, writes Puggle/Resources/Rigs/<name>.rig.json

Run it again whenever the canvas drawings change.
"""
import json, math, os, re, sys
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bend_arms
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
CANVAS = os.path.normpath(os.path.join(HERE, '..', '..', 'design', 'canvas'))
RIGS = os.path.normpath(os.path.join(HERE, '..', 'Puggle', 'Resources', 'Rigs'))
INK = '#3A2A20'



# ---------- Clothes for the grown-ups ----------
# Each grown-up has three outfits, and each outfit has two colours: the garment's own, and a trim
# that contrasts with it (a collar, a hem, a skirt, trousers, an apron), as their weather things
# contrast with their clothes. Each outfit comes in four pairs of colours.
TRIM = {'mum': '#F2BA30', 'dad': '#F1E1C2', 'nan': '#BBD6F4', 'pop': '#40A064'}      # as drawn; one off a brand colour, so a swap finds only the trim
PAIRS = {   # the other three pairs: garment, trim
    'mum': [('#E5553B', '#BFD9F5'), ('#F4BE2C', '#2A62B8'), ('#2A62B8', '#F3D9C9')],
    'dad': [('#3C9A5F', '#F4E7B0'), ('#E5553B', '#2A62B8'), ('#F4BE2C', '#3C9A5F')],
    'nan': [('#2A62B8', '#F4BE2C'), ('#3C9A5F', '#F3D9C9'), ('#B9A0EA', '#F4E7B0')],
    'pop': [('#F3D9C9', '#2A62B8'), ('#F4E7B0', '#E5553B'), ('#CFE5D2', '#F4BE2C')],
}

def dressed(svg, kind, outfit, c):
    """A grown-up's drawing with the garment swapped for another. The first shape is the one the body hangs from."""
    t = TRIM[kind]
    def P(d, fill, w=7): return f'<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="{w}" stroke-linejoin="round"></path>'
    def flat(d, fill): return f'<path d="{d}" fill="{fill}"></path>'
    def cord(d, col, w=6): return f'<path d="{d}" stroke="{INK}" stroke-width="{w + 6}" stroke-linecap="round"></path><path d="{d}" stroke="{col}" stroke-width="{w}" stroke-linecap="round"></path>'
    collar = P('M97 169 Q99 187 117 181 L119 171 Z', t, 5) + P('M143 169 Q141 187 123 181 L121 171 Z', t, 5)
    top = 'M86 168 Q120 158 154 168 L166 300 L74 300 Z'
    trousers = 'M72 296 H168 L167 352 H73 Z'               # the hips only: each trouser leg is added to its own leg (see trouser_legs)
    hem = 'M72 298 L168 298 L169 320 Q120 329 71 320 Z'
    coat = 'M86 168 Q120 158 154 168 L180 380 Q182 390 170 390 L70 390 Q58 390 60 380 Z'
    buttons = ''.join(f'<circle cx="128" cy="{y}" r="4.500" fill="#FBF6E9" stroke="{INK}" stroke-width="2.500"></circle>' for y in (200, 250, 300, 350))
    looks = {
        # Mum: a dress with a collar and a band at the hem; a top and a skirt; a top tucked into trousers.
        ('mum', ''): P('M86 168 Q120 158 154 168 L192 380 Q194 390 182 390 L58 390 Q46 390 48 380 Z', c)
                     + P('M53 352 L187 352 L192 380 Q194 390 182 390 L58 390 Q46 390 48 380 Z', t) + collar,
        ('mum', 'skirt'): P('M70 258 L170 258 L192 380 Q194 390 182 390 L58 390 Q46 390 48 380 Z', t)
                          + P('M86 168 Q120 158 154 168 L172 270 Q120 279 68 270 Z', c) + collar,
        ('mum', 'trousers'): P(top, c) + P(trousers, t) + P('M72 292 H168 V308 H72 Z', t, 5) + collar,
        # Dad: a shirt and shorts; a jumper with a stripe, over trousers; a tee under overalls.
        ('dad', ''): P('M84 168 Q120 158 156 168 L166 330 L74 330 Z', c) + P('M74 326 H166 L170 384 H126 L120 366 L114 384 H70 Z', t) + collar,
        ('dad', 'jumper'): P('M84 168 Q120 158 156 168 L168 318 Q120 326 72 318 Z', c) + P(trousers, t) + P(hem, c)
                           + flat('M84 222 L156 222 L158 246 L82 246 Z', t),
        ('dad', 'overalls'): P(top, c) + P('M96 216 H144 V290 H170 L169 352 H71 L70 290 H96 Z', t)
                             + cord('M100 218 L93 176', t) + cord('M140 218 L147 176', t)
                             + f'<circle cx="101" cy="222" r="4.500" fill="#FBF6E9" stroke="{INK}" stroke-width="2.500"></circle><circle cx="139" cy="222" r="4.500" fill="#FBF6E9" stroke="{INK}" stroke-width="2.500"></circle>',
        # Nan: her cardigan, with a collar and pockets; a dress under an apron; a jumper and a skirt.
        ('nan', ''): P(coat, c) + f'<path d="M120 166V388" stroke="{INK}" stroke-width="5"></path>' + buttons + collar
                     + P('M76 304 H102 V324 Q102 332 94 332 H82 Q74 332 74 324 Z', t, 5) + P('M138 304 H164 L166 324 Q166 332 158 332 H146 Q138 332 138 324 Z', t, 5),
        ('nan', 'apron'): P(coat, c) + P('M102 206 H138 V264 H160 L166 368 Q120 377 74 368 L80 264 H102 Z', t)
                          + cord('M104 208 L98 176', t, 5) + cord('M136 208 L142 176', t, 5),
        ('nan', 'skirt'): P('M72 262 L168 262 L180 380 Q182 390 170 390 L70 390 Q58 390 60 380 Z', t)
                          + P('M86 168 Q120 158 154 168 L170 274 Q120 283 70 274 Z', c) + collar,
        # Pop: his cardigan, with a collar and a breast pocket; a shirt under a waistcoat; a jumper with diamonds.
        ('pop', ''): P(coat, c) + f'<path d="M120 166V388" stroke="{INK}" stroke-width="5"></path>' + buttons + collar + P('M84 222 H106 V242 Q106 248 100 248 H90 Q84 248 84 242 Z', t, 5),
        ('pop', 'waistcoat'): P(top, c) + P(trousers, t) + P('M89 171 L113 176 L118 262 L110 300 L78 300 L81 214 Z', t) + P('M151 171 L127 176 L122 262 L130 300 L162 300 L159 214 Z', t)
                              + collar,
        ('pop', 'jumper'): P('M84 168 Q120 158 156 168 L168 318 Q120 326 72 318 Z', c) + P(trousers, t) + P(hem, c)
                           + flat('M102 212 L114 236 L102 260 L90 236 Z', t) + flat('M138 212 L150 236 L138 260 L126 236 Z', t) + flat('M120 236 L130 256 L120 276 L110 256 Z', t),
    }
    start = min(i for i in (svg.find('<path d="M86 168Q'), svg.find('<path d="M84 168Q')) if i >= 0)
    return svg[:start] + looks[(kind, outfit)] + svg[svg.index('<path d="M88 182Q'):]

# ---------- The drawings ----------

def drawings():
    src = open(CANVAS + '/gen/lineup.py').read()
    src = src[:src.index('GROUND = 470')].replace('ROOT = sys.argv[1]', '')
    g = {'ROOT': CANVAS, 'sys': sys, '__name__': 'cast'}
    sys.argv = [sys.argv[0], CANVAS]   # the canvas scripts read their folder from here
    exec(src, g)
    adult, baby, inner, quokka, A = g['adult'], g['baby'], g['inner'], g['quokka_kid'], g['A']
    kip = lambda garment: inner('koala', garment, '#F4BE2C') + A['bow'](150, 50, '#2A62B8')
    digby = lambda garment: inner('wombat', garment, '#2A62B8') + A['beanie']('#E5553B')
    quill = lambda garment: inner('echidna', garment, '#E5553B')
    grown = lambda kind, colour, outfits: {o: dressed(adult(colour, kind), kind, o, colour) for o in outfits}
    # name: (what they wear, by variant, the first being the canvas's own; the drawing's height; the
    # garment's colour; the other colours it comes in; a line about them)
    return {
        'nan': (grown('nan', '#E5553B', ['', 'apron', 'skirt']), 456, '#E5553B', PAIRS['nan'],
                "Nan: Puggle's grandmother. A fur bun, pale blue reading glasses on her bill, a cardigan."),
        'mum': (grown('mum', '#3C9A5F', ['', 'skirt', 'trousers']), 456, '#3C9A5F', PAIRS['mum'], "Mum: a daisy on her head, a dress."),
        'dad': (grown('dad', '#2A62B8', ['', 'jumper', 'overalls']), 456, '#2A62B8', PAIRS['dad'], "Dad: a shirt and shorts."),
        'pop': (grown('pop', '#BFD9F5', ['', 'waistcoat', 'jumper']), 456, '#BFD9F5', PAIRS['pop'],
                "Pop: Puggle's grandfather. Round glasses, a green bucket hat, a cardigan."),
        'pebble': ({'': baby('neutral', '#CFE5D2')}, 270, '#CFE5D2', ['#BFD9F5', '#F3D9C9', '#3C9A5F', '#E5553B'],
                   "Pebble: Puggle's baby brother, about six months, sitting in a mint babygro with a bottle, or a dummy when he sleeps. A round curl."),
        'quill': ({'': quill('dungarees'), 'jumper': quill('jumper'), 'tee': quill('tee')}, 300, '#E5553B', ['#2A62B8', '#3C9A5F', '#F4BE2C'],
                  "Quill: an echidna, Puggle's friend. The spines are the signature."),
        'kip': ({'': kip('dress'), 'dungarees': kip('dungarees'), 'jumper': kip('jumper')}, 300, '#F4BE2C', ['#E5553B', '#3C9A5F', '#F3D9C9'],
                "Kip: a koala, Puggle's best friend, who can fall asleep anywhere. A blue bow."),
        'digby': ({'': digby('tee'), 'dungarees': digby('dungarees')}, 300, '#2A62B8', ['#3C9A5F', '#F4BE2C'],
                  "Digby: a wombat who loves digging. A red beanie."),
        'sunny': ({'': quokka('#3C9A5F') + A['sunhat']('#F4E7B0')}, 300, '#3C9A5F', ['#2A62B8', '#E5553B', '#F4BE2C'],
                  "Sunny: a quokka, always smiling. A sun hat."),
    }


def shade_rule():
    """The canvas's own rule for a coloured outline: a darker shade of the colour it goes round."""
    src = open(CANVAS + '/gen/world.py').read()
    start = src.index('def shade(c):')
    end = src.index('def tint(', start)
    g = {'re': re}
    # shade() may lean on tables defined just above it.
    exec(src[src.rindex('\n# ---- Coloured outlines', 0, start):end], g)
    return g['shade']


# ---------- Geometry ----------

def mul(a, b):
    """a then b, as (a, b, c, d, e, f) affine matrices."""
    return (a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3],
            a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3],
            a[4] * b[0] + a[5] * b[2] + b[4], a[4] * b[1] + a[5] * b[3] + b[5])

IDENT = (1, 0, 0, 1, 0, 0)

def apply(m, x, y):
    return (m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5])

def parse_transform(text):
    m = IDENT
    for name, args in re.findall(r'(\w+)\(([^)]*)\)', text or ''):
        v = [float(n) for n in re.findall(r'-?\d*\.?\d+(?:e-?\d+)?', args)]
        if name == 'translate':
            t = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            t = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == 'rotate':
            a = math.radians(v[0]); c, s = math.cos(a), math.sin(a)
            cx, cy = (v[1], v[2]) if len(v) > 2 else (0, 0)
            t = (c, s, -s, c, cx - c * cx + s * cy, cy - s * cx - c * cy)
        else:
            continue
        m = mul(t, m)   # the first listed is applied last to the point
    return m

def rotation_of(m):
    return math.degrees(math.atan2(m[1], m[0]))

def arc_to_cubics(x1, y1, rx, ry, phi, large, sweep, x2, y2):
    """An SVG arc as cubic curves: [(c1x, c1y, c2x, c2y, x, y), ...]."""
    if rx == 0 or ry == 0: return [(x1, y1, x2, y2, x2, y2)]
    phi = math.radians(phi); cp, sp = math.cos(phi), math.sin(phi)
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    x1p, y1p = cp * dx + sp * dy, -sp * dx + cp * dy
    rx, ry = abs(rx), abs(ry)
    lam = x1p ** 2 / rx ** 2 + y1p ** 2 / ry ** 2
    if lam > 1: rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx ** 2 * ry ** 2 - rx ** 2 * y1p ** 2 - ry ** 2 * x1p ** 2
    den = rx ** 2 * y1p ** 2 + ry ** 2 * x1p ** 2
    co = math.sqrt(max(0, num / den)) * (-1 if large == sweep else 1)
    cxp, cyp = co * rx * y1p / ry, -co * ry * x1p / rx
    cx, cy = cp * cxp - sp * cyp + (x1 + x2) / 2, sp * cxp + cp * cyp + (y1 + y2) / 2
    def ang(ux, uy, vx, vy):
        return math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    t1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dt = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if not sweep and dt > 0: dt -= 2 * math.pi
    if sweep and dt < 0: dt += 2 * math.pi
    n = max(1, math.ceil(abs(dt) / (math.pi / 2)))
    out, step = [], dt / n
    k = 4 / 3 * math.tan(step / 4)
    for i in range(n):
        a, b = t1 + i * step, t1 + (i + 1) * step
        def pt(t): return (cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp, cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp)
        def dv(t): return (-rx * math.sin(t) * cp - ry * math.cos(t) * sp, -rx * math.sin(t) * sp + ry * math.cos(t) * cp)
        p0, p1 = pt(a), pt(b); d0, d1 = dv(a), dv(b)
        out.append((p0[0] + k * d0[0], p0[1] + k * d0[1], p1[0] - k * d1[0], p1[1] - k * d1[1], p1[0], p1[1]))
    return out

def absolute(d):
    """Any SVG path as absolute M, L, Q, C, Z segments: [(cmd, [numbers])]."""
    tokens = re.findall(r'[MmLlHhVvQqCcZzAa]|-?\d*\.?\d+(?:e-?\d+)?', d)
    out, i, x, y, sx, sy, cmd = [], 0, 0.0, 0.0, 0.0, 0.0, None
    def take(n):
        nonlocal i
        vals = [float(t) for t in tokens[i:i + n]]; i += n
        return vals
    while i < len(tokens):
        if re.match(r'[A-Za-z]', tokens[i]):
            cmd = tokens[i]; i += 1
            if cmd in 'Zz':
                out.append(('Z', [])); x, y = sx, sy
                continue
        rel = cmd.islower(); c = cmd.upper()
        if c == 'M':
            vx, vy = take(2); x, y = (x + vx, y + vy) if rel else (vx, vy)
            sx, sy = x, y; out.append(('M', [x, y])); cmd = 'l' if rel else 'L'
        elif c == 'L':
            vx, vy = take(2); x, y = (x + vx, y + vy) if rel else (vx, vy); out.append(('L', [x, y]))
        elif c == 'H':
            vx, = take(1); x = x + vx if rel else vx; out.append(('L', [x, y]))
        elif c == 'V':
            vy, = take(1); y = y + vy if rel else vy; out.append(('L', [x, y]))
        elif c == 'Q':
            v = take(4)
            if rel: v = [v[0] + x, v[1] + y, v[2] + x, v[3] + y]
            x, y = v[2], v[3]; out.append(('Q', v))
        elif c == 'C':
            v = take(6)
            if rel: v = [v[0] + x, v[1] + y, v[2] + x, v[3] + y, v[4] + x, v[5] + y]
            x, y = v[4], v[5]; out.append(('C', v))
        elif c == 'A':
            rx, ry, phi, large, sweep, ex, ey = take(7)
            if rel: ex, ey = ex + x, ey + y
            for seg in arc_to_cubics(x, y, rx, ry, phi, int(large), int(sweep), ex, ey): out.append(('C', list(seg)))
            x, y = ex, ey
    return out

def path_text(segments, m):
    parts = []
    for cmd, v in segments:
        pts = [apply(m, v[j], v[j + 1]) for j in range(0, len(v), 2)]
        parts.append(cmd + ' '.join(f'{round(px, 1):g} {round(py, 1):g}' for px, py in pts))
    return ' '.join(parts)

def rounded_rect(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    return [('M', [x + r, y]), ('L', [x + w - r, y]), ('Q', [x + w, y, x + w, y + r]), ('L', [x + w, y + h - r]),
            ('Q', [x + w, y + h, x + w - r, y + h]), ('L', [x + r, y + h]), ('Q', [x, y + h, x, y + h - r]),
            ('L', [x, y + r]), ('Q', [x, y, x + r, y]), ('Z', [])]

def bounds(segments, m):
    xs, ys = [], []
    for _, v in segments:
        for j in range(0, len(v), 2):
            px, py = apply(m, v[j], v[j + 1]); xs.append(px); ys.append(py)
    return min(xs), min(ys), max(xs), max(ys)


# ---------- Reading a drawing ----------

def flatten(svg):
    """Every visible shape, in paint order, with its transform applied and where it came from."""
    root = ET.fromstring('<svg>' + svg + '</svg>')
    shapes = []
    def walk(node, m, tags):
        if node.get('display') == 'none': return
        m = mul(parse_transform(node.get('transform')), m)
        tags = dict(tags)
        if node.tag == 'g':
            if node.get('data-p'): tags['part'] = node.get('data-p')
            rot = re.match(r'rotate\((-?[\d.]+) ([\d.]+) ([\d.]+)\)', node.get('transform') or '')
            if rot and abs(abs(float(rot.group(1))) - 42) < 1:
                tags['arm'] = 'left' if float(rot.group(2)) < 120 else 'right'
                tags['shoulder'] = [float(rot.group(2)), float(rot.group(3))]
            for child in node: walk(child, m, tags)
            return
        if node.tag == 'svg':
            for child in node: walk(child, m, tags)
            return
        f = lambda k, default=0.0: float(node.get(k, default))
        shape = {'tags': tags, 'opacity': f('opacity', 1), 'src': node.tag, 'd0': node.get('d', '')}
        fill, stroke = node.get('fill'), node.get('stroke')
        if fill and fill != 'none': shape['fill'] = fill
        elif node.tag != 'path' and fill is None: shape['fill'] = '#000000'
        if stroke and stroke != 'none':
            shape['stroke'] = stroke; shape['width'] = f('stroke-width', 1)
            if node.get('stroke-linecap') == 'round': shape['cap'] = 'round'
        plain = abs(m[1]) < 1e-9 and abs(m[2]) < 1e-9 and abs(m[0] - m[3]) < 1e-9
        turn_only = abs(m[0] * m[3] - m[1] * m[2] - 1) < 1e-6 and abs(m[0] - m[3]) < 1e-6 and abs(m[1] + m[2]) < 1e-6
        if node.tag in ('ellipse', 'circle'):
            rx = f('rx') if node.tag == 'ellipse' else f('r'); ry = f('ry') if node.tag == 'ellipse' else f('r')
            cx, cy = apply(m, f('cx'), f('cy'))
            if plain or turn_only:
                shape.update(kind='ellipse', x=round(cx, 1), y=round(cy, 1), rx=round(rx * abs(m[0]) if plain else rx, 2), ry=round(ry * abs(m[3]) if plain else ry, 2))
                if not plain and abs(rotation_of(m)) > 0.01 and abs(rx - ry) > 0.01: shape['rotate'] = round(rotation_of(m), 2)
                shape['box'] = (cx - rx, cy - ry, cx + rx, cy + ry)
                shapes.append(shape); return
            k = 0.5523
            segs = [('M', [f('cx') + rx, f('cy')]), ('C', [f('cx') + rx, f('cy') + k * ry, f('cx') + k * rx, f('cy') + ry, f('cx'), f('cy') + ry]),
                    ('C', [f('cx') - k * rx, f('cy') + ry, f('cx') - rx, f('cy') + k * ry, f('cx') - rx, f('cy')]),
                    ('C', [f('cx') - rx, f('cy') - k * ry, f('cx') - k * rx, f('cy') - ry, f('cx'), f('cy') - ry]),
                    ('C', [f('cx') + k * rx, f('cy') - ry, f('cx') + rx, f('cy') - k * ry, f('cx') + rx, f('cy')]), ('Z', [])]
        elif node.tag == 'rect':
            segs = rounded_rect(f('x'), f('y'), f('width'), f('height'), f('rx'))
        elif node.tag == 'path':
            segs = absolute(node.get('d'))
        else:
            return
        shape.update(kind='path', d=path_text(segs, m)); shape['box'] = bounds(segs, m)
        shapes.append(shape)
    walk(root, IDENT, {})
    return shapes


# ---------- Puggle's refinements, for everyone ----------
# The app's drawing of Puggle is the reference (spec: "As built in the app, 12 November"). The canvas
# cast predates it, so the same changes are made here: soft oval cheeks with no marks, her eye size,
# a filled pocket, her arms (sleeve, cuff, ball hand), tail markings, and each leg on its own ankle
# with a real foot. Feet are bare, as hers are: webbed for the platypus family, and each friend's own.

FEET = {'nan': 'webbed', 'mum': 'webbed', 'dad': 'webbed', 'pop': 'webbed', 'pebble': 'webbed',
        'kip': 'koala', 'digby': 'wombat', 'quill': 'echidna', 'sunny': 'quokka'}
CLAW = '#F3E3C3'

def lighten(c, amount=0.5):
    r, g, b = (int(c[i:i + 2], 16) for i in (1, 3, 5))
    return '#%02X%02X%02X' % tuple(round(v + (255 - v) * amount) for v in (r, g, b))

def moved(d, dx, dy):
    nums = iter(re.findall(r'[A-Z]|-?\d*\.?\d+', d))
    out, pair = [], []
    for token in nums:
        if token.isalpha(): out.append(token); continue
        pair.append(float(token))
        if len(pair) == 2:
            out.append(f'{round(pair[0] + dx, 1):g} {round(pair[1] + dy, 1):g}'); pair = []
    return re.sub(r'([A-Z]) ', r'\1', ' '.join(out))

def shift(shape, dx, dy):
    if shape['kind'] == 'ellipse': shape['x'] += dx; shape['y'] += dy
    else: shape['d'] = moved(shape['d'], dx, dy)
    b = shape['box']; shape['box'] = (b[0] + dx, b[1] + dy, b[2] + dx, b[3] + dy)

def webbed_foot(puggle, side, cx, ankle, turn=None):
    """Puggle's own foot, moved to this ankle."""
    src = next(p for p in puggle['parts'] if p['id'] == f'foot-{side}')
    home_x, home_bottom = (100 if side == 'left' else 140), 278
    dx, dy = cx - home_x, ankle - home_bottom
    out = []
    for shp in src['shapes']:
        new = dict(shp); new['d'] = moved(shp['d'], dx, dy); new['x'] = shp['x'] + dx; new['y'] = shp['y'] + dy
        if turn is not None: new['rotate'] = turn
        out.append(new)
    return out

def toed_foot(cx, top, half, lobes, drop=18.0):
    """A foot drawn the way Puggle's is: a flat top at the ankle, rounded sides, and a row of toes along
    the bottom with a nick between each. Returns the outline, where each nick is, and where each toe ends."""
    notch = 6.2
    width = (2 * half - notch * (lobes - 1)) / lobes          # each toe's width
    base = top + drop
    d = f'M{cx - 9:g} {top:g} L{cx + 9:g} {top:g} Q{cx + half + 1:g} {top + 4:g} {cx + half:g} {top + 12:g}'
    x = cx + half
    nicks, tips = [], []
    for i in range(lobes):
        left = x - width
        first, last = i == 0, i == lobes - 1
        if first:   # the outer toe runs on from the side of the foot
            d += f' Q{x:g} {base + 1:g} {left:g} {base:g}' if not last else f' Q{x:g} {base + 3:g} {cx:g} {base + 3:g} Q{left:g} {base + 3:g} {left:g} {top + 12:g}'
        elif last:
            d += f' Q{left:g} {base + 1:g} {left:g} {top + 12:g}'
        else:
            d += f' Q{(x + left) / 2:g} {base + 3:g} {left:g} {base:g}'
        tips.append(((x + left) / 2 + (2 if first and not last else (-2 if last and not first else 0)), base + (0.5 if first or last else 2)))
        if not last:
            d += f' Q{left - notch / 2:g} {base - 4:g} {left - notch:g} {base:g}'
            nicks.append(left - notch / 2)
            x = left - notch
    d += f' Q{cx - half - 1:g} {top + 4:g} {cx - 9:g} {top:g} Z'
    return d, nicks, tips, base

def paw(kind, side, cx, ankle, fur, shade):
    """A friend's foot, in the same hand as Puggle's: one soft shape with toes, turned out a little.
    No claws: each toe has a small rounded nail, a shade lighter than the foot. (Pointed claws were
    tried and read as fierce beside her.) The animals still differ: by how many toes, how broad the
    foot is, and how long the nails are."""
    sign = -1 if side == 'left' else 1
    top = ankle - 5
    spec = {
        # half-width, toes, pad colour, nail length
        'koala': (19, 3, '#939CA6', 2.0),      # round, soft pads
        'wombat': (22, 4, '#7F7168', 2.4),      # broad and flat
        'echidna': (17, 3, None, 3.6),          # longer nails, for digging
        'quokka': (24, 3, '#B58A5C', 2.0),      # long hind feet
    }[kind]
    half, lobes, pad, nail = spec
    pad = pad or fur
    d, nicks, tips, base = toed_foot(cx, top, half, lobes, drop=19 if kind == 'quokka' else 18)
    turn = {'x': cx, 'y': ankle - 4, 'rotate': -7 * sign}
    out = [dict(turn, kind='path', d=d, fill=pad, stroke=INK, tint=shade(pad), width=5.5)]
    for nx in nicks:   # the line up from each nick, as on hers
        out.append(dict(turn, kind='path', d=f'M{nx:g} {base - 1:g} L{nx + (cx - nx) * 0.12:g} {base - 8:g}', stroke=shade(pad), width=2.4, cap='round'))
    for tx, ty in tips:
        out.append(dict(turn, kind='ellipse', x=round(tx, 1), y=round(ty - 3.2 - nail * 0.3, 1), rx=2.6, ry=nail, fill=lighten(pad, 0.55)))
    return out

def puggle_arm(side, sleeve, hand, shade, shoulder_y=178):
    """Her arm: a sleeve with a dark edge, a cuff line, and a ball hand."""
    def x(v): return v if side == 'left' else 240 - v
    dy = shoulder_y - 178
    return [
        {'kind': 'path', 'd': f'M{x(88):g} {178 + dy:g} Q{x(71.8):g} {198.9 + dy:g} {x(56.5):g} {209.5 + dy:g}', 'stroke': INK, 'tint': shade(sleeve), 'width': 34, 'cap': 'round'},
        {'kind': 'path', 'd': f'M{x(88):g} {178 + dy:g} Q{x(71.8):g} {198.9 + dy:g} {x(50):g} {214 + dy:g}', 'stroke': sleeve, 'width': 22, 'cap': 'round'},
        {'kind': 'path', 'd': f'M{x(53.6):g} {198.1 + dy:g} L{x(66.1):g} {216.2 + dy:g}', 'stroke': INK, 'tint': shade(sleeve), 'width': 4, 'cap': 'round'},
        {'kind': 'ellipse', 'x': x(50), 'y': 214 + dy, 'rx': 12.5, 'ry': 12.5, 'fill': hand, 'stroke': INK, 'tint': shade(hand), 'width': 5},
    ]

def refine(name, shapes, shade):
    """Changes made to the flattened drawing before it is cut up."""
    out, garment = [], None
    for s in shapes:
        if s.get('stroke') == '#C24A36': continue                       # the stitch marks: cheeks are plain at rest
        if s['kind'] == 'ellipse' and s.get('fill') == '#EE9C88' and 'stroke' not in s:
            s['rx'], s['ry'] = 12, 7.5                                   # soft ovals, her size
        if s['kind'] == 'ellipse' and s.get('fill') == INK and 'stroke' not in s and 6 <= s['rx'] <= 8 and abs(s['rx'] - s['ry']) < 0.1:
            s['rx'] = s['ry'] = 6.8                                      # her eyes
        if s.get('fill') and s.get('width') in (6, 7) and s['kind'] == 'path': garment = s['fill']
        if s['kind'] == 'path' and not s.get('fill') and s.get('stroke') == INK and re.match(r'M100 (19|2\d)\dh40v', s['d0']) and garment:
            s['fill'] = lighten(garment)                                 # a pocket, filled a lighter shade of what it is on
        out.append(s)
    def swap(match, make):
        for i, shp in enumerate(out):
            if match(shp):
                new = make(shp)
                for n in new:
                    n.setdefault('tags', shp['tags']); n.setdefault('opacity', 1); n.setdefault('src', n['kind']); n.setdefault('d0', '')
                    if 'box' not in n:
                        n['box'] = (n['x'] - n['rx'], n['y'] - n['ry'], n['x'] + n['rx'], n['y'] + n['ry']) if n['kind'] == 'ellipse' else bounds(absolute(n['d']), IDENT)
                out[i:i + 1] = new
                return True
        return False
    def dark_oval(x, y): return lambda shp: shp['kind'] == 'ellipse' and shp.get('fill') == INK and abs(shp['x'] - x) < 1 and abs(shp['y'] - y) < 1 and shp['rx'] > 6.9
    # Noses nearer the real animals. The nose is the face: it is how each is told apart.
    if name == 'kip':
        # A koala's nose is big, tall and leathery: a rounded spoon, wider at the top.
        swap(dark_oval(120, 122), lambda shp: [{'kind': 'path', 'd': 'M104 110 Q104 98 120 98 Q136 98 136 110 L134 128 Q132 146 120 146 Q108 146 106 128 Z', 'fill': '#33302F', 'stroke': INK, 'width': 4}])
        # Her bow sat between her ear and her head. On top, in the middle, it is plainly in her fur.
        for shp in out:
            if shp.get('fill') == '#2A62B8' and shp['box'][3] < 70: shift(shp, -30, -4)
    if name == 'digby':
        # A wombat's nose is a broad, flat pad, squarer than it is round, with a nostril each side.
        swap(dark_oval(120, 130), lambda shp: [
            {'kind': 'path', 'd': 'M100 118 Q120 112 140 118 Q147 121 145 131 Q142 145 120 145 Q98 145 95 131 Q93 121 100 118 Z', 'fill': '#33302F', 'stroke': INK, 'width': 4},
            {'kind': 'ellipse', 'x': 110, 'y': 132, 'rx': 4, 'ry': 3, 'fill': '#5B5350'}, {'kind': 'ellipse', 'x': 130, 'y': 132, 'rx': 4, 'ry': 3, 'fill': '#5B5350'},
            # A short line down from it, as Sunny has, so the pad reads as a nose and not an open mouth.
            {'kind': 'path', 'd': 'M120 146 L120 154', 'stroke': shade('#8C7B6E'), 'width': 3, 'cap': 'round'}])
    if name == 'sunny':
        # A quokka has a small dark nose on a short, pale, rounded muzzle.
        fur = '#C2925F'
        swap(dark_oval(120, 118), lambda shp: [
            {'kind': 'ellipse', 'x': 120, 'y': 126, 'rx': 27, 'ry': 19, 'fill': lighten(fur, 0.38)},
            {'kind': 'path', 'd': 'M109 114 Q120 108 131 114 Q132 122 120 128 Q108 122 109 114 Z', 'fill': '#33302F', 'stroke': INK, 'width': 3.5},
            {'kind': 'path', 'd': 'M120 128 L120 135', 'stroke': shade(fur), 'width': 3, 'cap': 'round'}])
        # Her hat sat on her eyebrows: up a little, with a slightly smaller brim, so her ears show.
        for shp in out:
            if (shp.get('fill') == '#F4E7B0' or shp.get('stroke') == '#E5553B') and shp['box'][1] < 70:
                shift(shp, 0, -9)
                if shp['kind'] == 'ellipse': shp['rx'] = 88
    if name == 'quill':
        # An echidna's snout is a long, slim tube with a small dark tip.
        for shp in out:
            if shp['d0'].startswith('M106 110Q120 98 134 110'):
                shp['d'] = 'M109 112 Q120 102 131 112 L126 170 Q120 178 114 170 Z'
            if shp['kind'] == 'ellipse' and shp.get('fill') == INK and abs(shp['y'] - 169) < 1: shp.update(y=171, rx=5.5, ry=4.5)
    if name == 'nan':
        # Her reading glasses rest on her bill, so her eyes look over them.
        for shp in out:
            if abs((shp['box'][1] + shp['box'][3]) / 2 - 134) < 9 and shp.get('width') in (5, 5.0) and shp['box'][3] - shp['box'][1] < 40 and shp is not None and (shp.get('fill') in ('#BFD9F5', None)):
                shift(shp, 0, 8)
                if shp['kind'] == 'ellipse': shp['rx'] = shp['ry'] = 12
    if name == 'pop':
        # His round glasses go where his eyes are.
        for shp in out:
            if 'fill' not in shp and shp.get('width') in (5, 5.0) and 95 < (shp['box'][1] + shp['box'][3]) / 2 < 112 and shp['d0'] != 'M48 66H192':
                shift(shp, 0, 9)
                # And each lens goes round an eye. They were set for the old, closer eyes, which made him look two ways at once.
                if shp['kind'] == 'ellipse': shp['x'] = 88 if shp['x'] < 120 else 152
                elif 'Q' in shp['d']: shp['d'] = 'M103 117 Q120 110 137 117'
                else: shp['d'] = 'M73 115 L52 109 M167 115 L188 109'
    if name == 'digby':
        # His beanie sat over his eyes: up it goes, to where a beanie sits.
        for s in out:
            if (s.get('fill') == '#E5553B' or s.get('fill') == '#FBF6E9') and s['box'][3] < 110 and s['box'][1] < 85 and s.get('width') == 5: shift(s, 0, -17)
    if name == 'pop':
        # The brim of his bucket hat was a single line: now it is a brim.
        for i, s in enumerate(out):
            if s['d0'] == 'M48 66H192':
                segs = rounded_rect(40, 60, 160, 15, 7.5)
                out[i] = {'kind': 'path', 'd': path_text(segs, IDENT), 'box': bounds(segs, IDENT), 'fill': '#3C9A5F', 'stroke': INK, 'width': 6, 'tags': s['tags'], 'opacity': 1, 'src': 'path', 'd0': ''}
    if name == 'pop':
        # A bucket hat has a deep crown, not a cap's.
        for shp in out:
            if shp['d0'] == 'M62 64Q120 22 178 64Z': shp['d'] = 'M66 66 Q64 24 120 24 Q176 24 174 66 Z'; shp['box'] = (64, 24, 176, 66)
    if name == 'mum':
        # Her flower read as a leaf. A small daisy, so it is plainly a flower and not Puggle's clip.
        for i, s in enumerate(out):
            if s['d0'].startswith('M156 52q14'):
                cx, cy, daisy = 160, 60, []
                petals = [(cx + 9 * math.cos(math.radians(a)), cy + 9 * math.sin(math.radians(a))) for a in range(-90, 270, 72)]
                for px, py in petals: daisy.append({'kind': 'ellipse', 'x': round(px, 1), 'y': round(py, 1), 'rx': 7.5, 'ry': 7.5, 'fill': '#FBF6E9', 'stroke': INK, 'width': 4})
                for px, py in petals: daisy.append({'kind': 'ellipse', 'x': round(px, 1), 'y': round(py, 1), 'rx': 6, 'ry': 6, 'fill': '#FBF6E9'})
                daisy.append({'kind': 'ellipse', 'x': cx, 'y': cy, 'rx': 5.5, 'ry': 5.5, 'fill': '#F4BE2C'})
                for d in daisy: d.update(tags=s['tags'], opacity=1, src='ellipse', d0='', box=(d['x'] - d['rx'], d['y'] - d['ry'], d['x'] + d['rx'], d['y'] + d['ry']))
                out[i:i + 1] = daisy
                break
    return out


# ---------- Dressed for the weather ----------
# Everyone is dressed for the weather as Puggle is, each in their own way. What makes each of them
# who they are carries through: the accessories are in their own colour, their own hat stays where it
# suits the weather, and whoever cannot wear a hat (Kip's ears, Quill's spines, Nan's bun, Sunny's own
# hat) carries an umbrella where the others wear a raincoat and rain hat.
#   cold: a scarf and mittens for all; a beanie for bare heads; ear warmers for Kip
#   wet:  a yellow raincoat and rain hat, or their own clothes under an umbrella
#   hot:  a sun hat for bare heads; a parasol for Nan; zinc on the nose for Quill and Pebble

ACCENT = {'nan': '#E5553B', 'mum': '#F4BE2C', 'dad': '#3C9A5F', 'pop': '#3C9A5F', 'pebble': '#E5553B',
          'quill': '#2A62B8', 'kip': '#2A62B8', 'digby': '#E5553B', 'sunny': '#E5553B'}
UMBRELLA = {'nan', 'quill', 'kip', 'sunny'}     # the rest wear a raincoat
SIDEROOM = 60                                   # how far the canopy reaches past their side, held beside the face
HEADROOM = 62                                   # space above the head for an open umbrella, in the drawing's units

def lowered(rig, by):
    """The whole drawing moved down, to leave room above it."""
    for part in rig['parts']:
        part['pivot'] = [part['pivot'][0], part['pivot'][1] + by]
        for shp in part['shapes']:
            if 'd' in shp: shp['d'] = moved(shp['d'], 0, by)
            if 'y' in shp: shp['y'] = shp['y'] + by
    rig['size'] = [rig['size'][0], rig['size'][1] + by]
    rig['headroom'] = by
    return rig

def dress_for_weather(name, parts, puggle, shade):
    accent = ACCENT[name]
    hers = {p['id']: p for p in puggle['parts']}
    def at(part_id): return next(i for i, p in enumerate(parts) if p['id'] == part_id)
    def copy(part_id, swaps=None, when=None, parent=None):
        part = json.loads(json.dumps(hers[part_id]))
        for shp in part['shapes']:
            for key in ('fill', 'stroke', 'tint'):
                if swaps and shp.get(key) in swaps: shp[key] = swaps[shp[key]]
        if when: part['when'] = when
        if parent: part['parent'] = parent
        return part
    hand = {side: next(shp for shp in reversed(parts[at(f'arm-{side}')]['shapes']) if shp['kind'] == 'ellipse') for side in ('left', 'right')}
    own_hat = {'digby': 'outfit=none|warm', 'sunny': 'outfit=none|sun|rain'}     # off in pyjamas, and when asked ("bare")
    if name in own_hat:
        # Their own hat comes off when the weather calls for another.
        parts[at('head-2')]['when'] = own_hat[name]
    last_face = max(i for i, p in enumerate(parts) if p['id'] in ('face', 'eye-left', 'eye-right', 'eyes-closed', 'head-2'))
    top = at('head-2') if name in ('mum', 'kip') and any(p['id'] == 'head-2' for p in parts) else last_face + 1     # under a daisy or a bow

    # Cold: a scarf in their colour, under the chin, and mittens over their hands.
    scarf = copy('scarf', {'#E5553B': accent, '#B23A26': shade(accent), '#F7B9A8': lighten(accent, 0.6)})
    parts.insert(at('head'), scarf)
    for side in ('left', 'right'):
        parts.insert(at(f'arm-{side}') + 1, {'id': f'mitten-{side}', 'parent': f'arm-{side}', 'pivot': [hand[side]['x'], hand[side]['y']], 'when': 'outfit=warm',
                     'shapes': [{'kind': 'ellipse', 'x': hand[side]['x'], 'y': hand[side]['y'], 'rx': 13.5, 'ry': 13.5, 'fill': accent, 'stroke': INK, 'tint': shade(accent), 'width': 5}]})
    top = max(i for i, p in enumerate(parts) if p['id'] in ('face', 'eye-left', 'eye-right', 'eyes-closed')) + 1 if top == last_face + 1 else at('head-2')
    beanie = lambda colour: copy('beanie', {'#7FB48F': colour, '#4E8060': shade(colour)}, parent='head')
    if name in ('mum', 'dad'):
        parts.insert(top, beanie(accent))
    if name == 'sunny':
        # Her sun hat's colours, as a beanie.
        parts.insert(top, copy('beanie', {'#7FB48F': '#F4E7B0', '#4E8060': accent, '#FBF3E2': accent}, parent='head'))
    if name == 'kip':
        # Ear warmers over those ears, with the band behind her bow.
        parts.insert(top, {'id': 'earmuffs', 'parent': 'head', 'pivot': [120, 60], 'when': 'outfit=warm', 'shapes': [
            {'kind': 'path', 'd': 'M50 62 Q120 14 190 62', 'stroke': INK, 'tint': shade(accent), 'width': 11, 'cap': 'round'},
            {'kind': 'path', 'd': 'M50 62 Q120 14 190 62', 'stroke': accent, 'width': 5.5, 'cap': 'round'},
            {'kind': 'ellipse', 'x': 50, 'y': 76, 'rx': 19, 'ry': 22, 'fill': accent, 'stroke': INK, 'tint': shade(accent), 'width': 5},
            {'kind': 'ellipse', 'x': 190, 'y': 76, 'rx': 19, 'ry': 22, 'fill': accent, 'stroke': INK, 'tint': shade(accent), 'width': 5}]})

    # Hot: a straw hat with their colour for a band, on a bare head; zinc on the nose where a hat will not go.
    if name in ('mum', 'dad', 'digby', 'kip'):
        parts.insert(top, copy('sunhat', {'#E5553B': accent}, parent='head'))
    if name == 'pebble':
        parts.append(copy('zinc', parent='head'))
    if name == 'quill':
        parts.append({'id': 'zinc', 'parent': 'head', 'pivot': [120, 132], 'when': 'outfit=sun',
                      'shapes': [{'kind': 'path', 'd': 'M113 132 L127 132', 'stroke': '#FBF6E9', 'width': 7, 'cap': 'round'}]})

    # Wet: her rain hat with a raincoat, or an umbrella in their colour. Nan's is a parasol too when it is hot.
    if name == 'pop':
        # His bucket hat comes out of the part that also holds his glasses, so it can come off for the rain hat.
        specs = parts[at('head-2')]
        hat = [shp for shp in specs['shapes'] if shp.get('fill') == '#3C9A5F']
        specs['shapes'] = [shp for shp in specs['shapes'] if shp not in hat]
        parts.insert(at('head-2') + 1, {'id': 'hat', 'parent': 'head', 'pivot': [120, 66], 'when': 'outfit=none|warm|sun', 'shapes': hat})
        top = at('hat') + 1
    if name in ('mum', 'dad', 'digby', 'pop'):
        # Everyone in a raincoat wears the same yellow rain hat: yellow is what says "rain" at a glance.
        parts.insert(top, copy('rainhat', parent='head'))
    if name in UMBRELLA:
        when = 'outfit=rain|sun' if name == 'nan' else 'outfit=rain'
        # The umbrella stands straight up, at one height and one size for everyone, and all of it is in front
        # of them. So that the shaft does not cross their face, it stands beside it, and the arm changes: a
        # second right arm, shown only with the umbrella, bent up with the fist beside the chin. Their usual
        # arm is hidden while it is up.
        arm = parts[at('arm-right')]
        sx, sy = arm['pivot']
        # The fist is up beside the cheek, so little of the shaft shows between it and the canopy. Heads are
        # at one height in every drawing, grown-up or child, so one height suits them all.
        hx, hy = 190.0, 142.0
        cx, cy = sx + 50, sy + 30                                # the elbow's side of the bend
        bend = f'M{sx:g} {sy:g} Q{cx:g} {cy:g} {hx:g} {hy:g}'
        dx, dy = hx - cx, hy - cy
        far = math.hypot(dx, dy); dx, dy = dx / far, dy / far
        cuff = f'M{hx - dx * 9 - dy * 11:.1f} {hy - dy * 9 + dx * 11:.1f} L{hx - dx * 9 + dy * 11:.1f} {hy - dy * 9 - dx * 11:.1f}'
        dark, sleeve, edge, fist = (json.loads(json.dumps(shp)) for shp in arm['shapes'][:4])
        dark['d'] = sleeve['d'] = bend
        edge['d'] = cuff
        fist['x'], fist['y'] = hx, hy
        arm['when'] = 'outfit=none|warm|night|bare' if name == 'nan' else 'outfit=none|warm|sun|night|bare'
        parts.insert(at('head'), {'id': 'arm-right-hold', 'parent': 'upper', 'pivot': arm['pivot'], 'spring': 150, 'when': when, 'shapes': [dark, sleeve, edge]})
        # The umbrella is the last thing drawn, in front of the head and of hair, ears, spines, bows and hats:
        # a slim shaft straight up, a short wooden handle that hooks round below the fist, the fist over the
        # shaft so it is held, and then the canopy at its full size, centred on the shaft. The canopy stands
        # above and beside the drawing, so these four have room added (see HEADROOM and SIDEROOM).
        r = 8
        hook = f'M{hx:g} {hy + 2:g} L{hx:g} {hy + 17:g} Q{hx:g} {hy + 17 + r:g} {hx + r:g} {hy + 17 + r:g} Q{hx + 2 * r:g} {hy + 17 + r:g} {hx + 2 * r:g} {hy + 17:g} L{hx + 2 * r:g} {hy + 13:g}'
        shaft = f'M{hx:g} {hy:g} L{hx:g} -30'
        parts.append({'id': 'umbrella', 'parent': 'upper', 'pivot': [hx, hy], 'spring': 120, 'when': when, 'shapes': [
            {'kind': 'path', 'd': shaft, 'stroke': INK, 'width': 7, 'cap': 'round'},
            {'kind': 'path', 'd': shaft, 'stroke': '#C9CED3', 'width': 2.5, 'cap': 'round'},
            {'kind': 'path', 'd': hook, 'stroke': INK, 'width': 11, 'cap': 'round'},
            {'kind': 'path', 'd': hook, 'stroke': '#C58F5A', 'width': 5.5, 'cap': 'round'},
            fist,
            {'kind': 'path', 'd': moved('M26 30 Q32 -44 132 -48 Q232 -44 238 30 Q212 14 185 30 Q158 14 132 28 Q106 14 79 30 Q52 14 26 30 Z', hx - 132, 0),
             'fill': accent, 'stroke': INK, 'tint': shade(accent), 'width': 6},
            # Its ribs: a line from the tip down to each point where two scallops meet, as her rain hat has seams.
            {'kind': 'path', 'd': moved('M132 -45 Q98 -32 79 27 M132 -45 L132 25 M132 -45 Q166 -32 185 27', hx - 132, 0),
             'stroke': shade(accent), 'width': 3, 'cap': 'round'},
            {'kind': 'path', 'd': f'M{hx:g} -48 L{hx:g} -56', 'stroke': INK, 'tint': shade(accent), 'width': 5, 'cap': 'round'}]})
    return parts


# ---------- Cutting it into parts ----------

# What grows from a head (ears, spines, a bun, a curl) is part of the head: the head's own fur and
# line, joined to it with no line between, so it changes the head's outline instead of sitting on it.
def inset_fill(shape, by):
    """The same shape, smaller by `by` and with no line: laid over a seam, it leaves one outline."""
    if shape['kind'] == 'ellipse':
        return {'kind': 'ellipse', 'x': shape['x'], 'y': shape['y'], 'rx': shape['rx'] - by, 'ry': shape['ry'] - by, 'fill': shape['fill']}
    pts = [(float(a), float(b)) for a, b in re.findall(r'[ML]\s*(-?[\d.]+)[ ,]+(-?[\d.]+)', shape['d'])]
    cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
    lines = []
    for i, (x1, y1) in enumerate(pts):
        x2, y2 = pts[(i + 1) % len(pts)]
        nx, ny = y2 - y1, x1 - x2
        n = math.hypot(nx, ny); nx, ny = nx / n, ny / n
        if (cx - x1) * nx + (cy - y1) * ny < 0: nx, ny = -nx, -ny
        lines.append((nx, ny, nx * (x1 + nx * by) + ny * (y1 + ny * by)))
    out = []
    for i in range(len(lines)):
        a1, b1, c1 = lines[i - 1]; a2, b2, c2 = lines[i]
        det = a1 * b2 - a2 * b1
        out.append(((c1 * b2 - c2 * b1) / det, (a1 * c2 - a2 * c1) / det))
    return {'kind': 'path', 'd': 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in out) + ' Z', 'fill': shape['fill']}

def join_to_head(name, parts):
    """Each ear, spine, bun and curl becomes a part of its own, so it can be posed and sprung by itself.
    It sits on the head as Puggle's lick does: its line shows round the outside, and its fur runs into
    the head where they meet. Each is a pair: `ear-left` holds the outlined shape, and `ear-left-top`,
    its child, lays the fur over the seam, so moving `ear-left` moves both."""
    by_id = {p['id']: p for p in parts}
    face = by_id['face']
    skull = face['shapes'][0]
    fur, line = skull['fill'], skull.get('tint')
    if skull['kind'] == 'ellipse': centre = (skull['x'], skull['y'])
    else:
        pts = [(float(a), float(b)) for a, b in re.findall(r'(-?[\d.]+) (-?[\d.]+)', skull['d'])]
        centre = ((min(p[0] for p in pts) + max(p[0] for p in pts)) / 2, (min(p[1] for p in pts) + max(p[1] for p in pts)) / 2)
    if name == 'pebble':
        # His canvas curl was a wire. He has a wave of hair now (see HAIR), so the old curl goes.
        parts.remove(by_id['head-2'])
        return parts
    back = by_id.get('head-back')
    shapes, extras = (back['shapes'] if back else []), {}
    if name == 'nan':
        # Her bun and its tie are gone: she has a set of curls now (see HAIR).
        top = by_id['head-2']
        del top['shapes'][:2]
    if not shapes: return parts
    outlined = [i for i, s in enumerate(shapes) if s.get('stroke')]
    for i, s in enumerate(shapes):
        if not s.get('stroke'): extras.setdefault(max(j for j in outlined if j < i), []).append(s)   # an inner ear goes with its ear
    behind, over = [], []
    for n, i in enumerate(outlined):
        s = shapes[i]
        if s['kind'] == 'ellipse':
            dx, dy = centre[0] - s['x'], centre[1] - s['y']; d = math.hypot(dx, dy)
            pivot = [round(s['x'] + dx / d * s['rx'] * 0.7, 1), round(s['y'] + dy / d * s['ry'] * 0.7, 1)]
        else:
            pts = [(float(a), float(b)) for a, b in re.findall(r'[ML]\s*(-?[\d.]+)[ ,]+(-?[\d.]+)', s['d'])]
            base = sorted(pts, key=lambda p: math.hypot(p[0] - centre[0], p[1] - centre[1]))[:2]
            pivot = [round((base[0][0] + base[1][0]) / 2, 1), round((base[0][1] + base[1][1]) / 2, 1)]
        if name == 'quill':
            s.update(fill=fur, tint=line, width=6.0)      # spines in the head's own fur and line
            pid, spring = f'spine-{n + 1}', 200
        elif name == 'nan': pid, spring = 'bun', 190
        else: pid, spring = ('ear-left' if s['x'] < centre[0] else 'ear-right'), 170
        behind.append({'id': pid, 'parent': 'head', 'pivot': pivot, 'spring': spring, 'shapes': [s]})
        over.append({'id': pid + '-top', 'parent': pid, 'pivot': pivot, 'shapes': [inset_fill(s, s['width'] / 2)] + extras.get(i, [])})
    if back: parts.remove(back)
    at = parts.index(face)
    parts[at + 1:at + 1] = over
    parts[at:at] = behind
    return parts


# Hair for the grown-ups, so each has an outline of their own (Tom, 14 November 2026). Mum: a side
# sweep and a bob that flicks out. Dad: a scruffy crest and small cheek tufts. Nan and Pop follow:
# Nan a set of curls on top (chosen over her bun) and soft curls at the sides, Pop bushy cheek tufts under his hat. Each lock is a
# part of its own, drawn as the ears are: outlined behind the head, its fur over the seam in front.
def mirrored(d):
    return re.sub(r'(-?[\d.]+) (-?[\d.]+)', lambda m: f'{240 - float(m.group(1)):g} {m.group(2)}', d)

FLICK = 'M58 124 Q36 132 30 114 Q42 122 56 108 Z'
TUFT = 'M58 120 L44 124 L54 130 L45 139 L60 140 Z'
CURL = 'M58 116 Q39 115 38 130 Q39 142 51 142 Q46 134 59 134 Z'
BUSHY = 'M58 116 L42 119 L52 125 L40 130 L52 135 L43 143 L60 142 Z'
BARE = 'outfit=none|night|bare'      # no hat on: "bare" is hats off, for indoors or a close-up
HATLESS = 'outfit=night|bare'         # for those whose own hat is on by day
HAIR = {   # part, pivot, when it shows (None: always), shapes
    'mum': [('sweep', [100, 62], BARE, ['M88 64 Q80 44 96 35 Q114 28 130 38 Q139 45 137 55 Q128 46 117 48 Q107 52 110 64 Z']),
            ('flick-left', [57, 118], None, [FLICK]), ('flick-right', [183, 118], None, [mirrored(FLICK)])],
    'dad': [('crest', [120, 60], BARE, ['M109 60 Q111 40 120 30 Q129 40 129 60 Z', 'M98 62 Q93 46 101 37 Q109 44 112 60 Z', 'M126 60 Q130 45 139 39 Q144 48 139 62 Z']),
            ('tuft-left', [59, 130], None, [TUFT]), ('tuft-right', [181, 130], None, [mirrored(TUFT)])],
    'nan': [('curls', [120, 66], None, ['M70 70 Q58 52 74 44 Q76 30 94 34 Q102 22 120 28 Q138 22 146 34 Q164 30 166 44 Q182 52 170 70 Z']),
            ('curl-left', [58, 126], None, [CURL]), ('curl-right', [182, 126], None, [mirrored(CURL)])],
    'pop': [('tuft-left', [59, 130], None, [BUSHY]), ('tuft-right', [181, 130], None, [mirrored(BUSHY)])],
    # Pebble: one wave swept to the side with three little flicks along its top (Tom chose it over a round curl).
    'pebble': [('curl', [118, 56], None, ['M99 58 Q94 42 107 35 Q111 27 120 29 Q117 35 122 37 Q128 28 138 31 Q133 37 138 40 Q146 33 153 38 Q147 43 148 49 Q141 55 135 58 Z'])],
    # Under their hats, for when the hats come off: Digby a coarse, stubby tuft between his ears, Sunny two small
    # pointed wisps: small and pointed, so they are not read as a third ear beside her round ones.
    'digby': [('tuft', [122, 54], HATLESS, ['M103 55 Q100 41 109 35 Q116 41 118 53 Z', 'M115 53 Q117 37 126 31 Q134 39 133 53 Z', 'M130 55 Q134 43 141 39 Q146 47 142 57 Z'])],
    'sunny': [('tuft', [120, 54], HATLESS, ['M109 55 Q107 44 114 39 Q118 44 119 50 Q122 41 129 38 Q133 46 130 56 Z'])],
}

def grow_hair(name, parts):
    if name not in HAIR: return parts
    face = next(p for p in parts if p['id'] == 'face')
    skull = face['shapes'][0]
    fur, line = skull['fill'], skull.get('tint')
    behind, over = [], []
    for pid, pivot, bare, locks in HAIR[name]:
        # The line is drawn at twice its width behind the fur, so the half that shows matches the head's.
        back = {'id': pid, 'parent': 'head', 'pivot': pivot, 'spring': 130,
                'shapes': [{'kind': 'path', 'd': d, 'fill': fur, 'stroke': INK, 'tint': line, 'width': skull['width'] * 2} for d in locks]}
        top = {'id': pid + '-top', 'parent': pid, 'pivot': pivot, 'shapes': [{'kind': 'path', 'd': d, 'fill': fur} for d in locks]}
        if bare: back['when'] = top['when'] = bare
        behind.append(back); over.append(top)
    at = parts.index(face)
    parts[at + 1:at + 1] = over
    parts[at:at] = behind
    return parts


# Hats (Tom, 14 November 2026): a pompom is wool, so its edge is tufted, not a smooth ball; and
# Sunny's ears come up through the brim of her sun hat.
def fuzzy(x, y, r, tufts=14):
    """A pompom: many short soft points of uneven length all the way round (the line's round joins blunt them)."""
    pts = []
    for k in range(tufts * 2):
        a = math.pi * k / tufts - math.pi / 2
        rad = (r + (3.6, 2.2, 3.0)[(k // 2) % 3]) if k % 2 == 0 else r - 0.4
        pts.append(f'{x + rad * math.cos(a):.1f} {y + rad * math.sin(a):.1f}')
    return 'M' + ' L'.join(pts) + ' Z'

def lower_half(x, y, rx, ry):
    """The front half of a brim, as curves."""
    d, steps = f'M{x - rx:g} {y:g}', 4
    for k in range(steps):
        a0, a1 = math.pi - math.pi * k / steps, math.pi - math.pi * (k + 1) / steps
        m, h = (a0 + a1) / 2, (a0 - a1) / 2
        d += f' Q{x + rx * math.cos(m) / math.cos(h):.1f} {y + ry * math.sin(m) / math.cos(h):.1f} {x + rx * math.cos(a1):.1f} {y + ry * math.sin(a1):.1f}'
    return d

def finish_hats(name, parts):
    by_id = {p['id']: p for p in parts}
    if name == 'digby':
        hat = by_id['head-2']
        ball = next(s for s in hat['shapes'] if s['kind'] == 'ellipse')
        hat['shapes'][hat['shapes'].index(ball)] = {'kind': 'path', 'd': fuzzy(ball['x'], ball['y'] + 4, ball['rx'] + 4, tufts=16), 'fill': ball['fill'],   # bigger, its top where it was
                                                    'stroke': ball['stroke'], 'tint': ball.get('tint'), 'width': 4}
    if name == 'sunny':
        hat = by_id['head-2']
        brim = hat['shapes'][0]
        through = []
        for side in ('left', 'right'):
            ear = by_id[f'ear-{side}']
            through.append({'id': f'ear-{side}-through', 'parent': ear['id'], 'pivot': ear['pivot'], 'when': hat['when'], 'shapes': json.loads(json.dumps(ear['shapes']))})
        # The front of the brim goes back over the ears, so they come up through it and not over it.
        front = lower_half(brim['x'], brim['y'], brim['rx'], brim['ry'])
        through.append({'id': 'brim-front', 'parent': 'head', 'pivot': hat['pivot'], 'when': hat['when'], 'shapes': [
            {'kind': 'path', 'd': front + ' Z', 'fill': brim['fill']},
            {'kind': 'path', 'd': front, 'stroke': brim['stroke'], 'tint': brim.get('tint'), 'width': brim['width'], 'cap': 'round'}]})
        at = parts.index(hat) + 1
        parts[at:at] = through
    return parts


# The platypus tail (Tom, 14 November 2026). It was an oval lying beside the legs with a line down its
# middle, which read as a leaf, and on the grown-ups it floated clear of the body. A platypus has a broad
# flat paddle: narrow where it leaves the body, wide and round at the end. Its base is tucked well in
# behind the body, so it always grows out of them, and it has two short ridges across it and no midline.
def paddle(bx, by, angle=-28.0, long=66.0):
    a = math.radians(angle)
    ax, ay, nx, ny = math.cos(a), math.sin(a), -math.sin(a), math.cos(a)
    def at(t, w): return f'{bx + t * ax + w * nx:.1f} {by + t * ay + w * ny:.1f}'
    k = long / 66.0
    outline = (f'M{at(0, -8)} Q{at(20 * k, -18)} {at(40 * k, -17)} Q{at(66 * k, -15)} {at(66 * k, 0)} '
               f'Q{at(66 * k, 15)} {at(40 * k, 17)} Q{at(20 * k, 18)} {at(0, 8)} Z')
    ridges = f'M{at(38 * k, -8)} Q{at(42 * k, 0)} {at(38 * k, 8)} M{at(51 * k, -7)} Q{at(55 * k, 0)} {at(51 * k, 7)}'
    return outline, ridges

def regrow_tail(parts, grown, sitting=False):
    tail = next((p for p in parts if p['id'] == 'tail'), None)
    if not tail: return parts
    oval = tail['shapes'][0]
    # Where the oval's near end was, and further in behind the body; a grown-up's sits higher, at the hip.
    # Up at the hip, where a tail leaves the body: not down by the knees or, for a sitting baby, along the ground.
    lift = 50 if grown else 30 if sitting else 18
    bx, by = oval['x'] - 28, oval['y'] + 14 - lift
    outline, ridges = paddle(bx, by, long=72.0)
    tail['shapes'] = [{'kind': 'path', 'd': outline, 'fill': oval['fill'], 'stroke': oval['stroke'], 'tint': oval.get('tint'), 'width': oval['width']},
                      {'kind': 'path', 'd': ridges, 'stroke': oval.get('tint') or INK, 'width': 2.5, 'cap': 'round'}]
    tail['pivot'] = [round(bx + 6, 1), round(by - 3, 1)]
    return parts


# Pebble's babygro (Tom, 14 November 2026). The canvas drew a flared triangle, which read as a dress. A
# babygro is close to the body: a rounded suit with a leg each side, poppers round the inside of the legs,
# a seam down the front, a neckband, and feet: sitting, he shows us their soles.
def babygro(parts):
    upper = next(p for p in parts if p['id'] == 'upper')
    suit = upper['shapes'][0]
    def piece(d, w=None): return {'kind': 'path', 'd': d, 'fill': suit['fill'], 'stroke': suit['stroke'], 'tint': suit.get('tint'), 'width': w or suit['width']}
    def seam(d, w=3): return {'kind': 'path', 'd': d, 'stroke': suit.get('tint') or INK, 'width': w, 'cap': 'round'}
    # A thigh each side, coming forward and out from the hip, with a fold where it meets the body.
    leg = 'M98 221 Q111 236 104 250 Q98 262 80 261 Q65 258 65 244 Q66 228 80 223 Q90 219 98 221 Z'   # its outer edge is inside the sole: one line there, not two
    fold = 'M99 222 Q108 237 102 251'
    cuff = 'M63 240 Q59 250 66 259'
    body = 'M92 166 Q120 158 148 166 Q168 194 168 222 Q168 247 146 248 L94 248 Q72 247 72 222 Q72 194 92 166 Z'
    poppers = [{'kind': 'ellipse', 'x': x, 'y': y, 'rx': 2.8, 'ry': 2.8, 'fill': '#FBF6E9', 'stroke': INK, 'tint': suit.get('tint'), 'width': 1.8}
               for x, y in ((110, 240), (120, 243), (130, 240))]
    # He is sitting with his legs out towards us, so what we see of each foot is its sole, and the babygro
    # has feet: a rounded sole in the suit's colour with a paler pad on it, turned out a little.
    def sole(x, turn):
        return [{'kind': 'ellipse', 'x': x, 'y': 243, 'rx': 20, 'ry': 23, 'rotate': turn, 'fill': suit['fill'], 'stroke': suit['stroke'], 'tint': suit.get('tint'), 'width': suit['width']},
                {'kind': 'ellipse', 'x': x, 'y': 246, 'rx': 11, 'ry': 13, 'rotate': turn, 'fill': lighten(suit['fill'])}]
    upper['shapes'] = ([piece(body), piece(leg), piece(mirrored(leg)), seam(fold, 3.5), seam(mirrored(fold), 3.5),
                        seam('M120 172 L120 240'), seam('M102 169 Q120 181 138 169', 3.5)]
                       + poppers + sole(72, -12) + sole(168, 12) + upper['shapes'][1:])
    # A bottle or a dummy, never both: the bottle while he is awake, a wattle-yellow dummy while he sleeps,
    # when his hands rest together. The dummy is a shield and a ring resting on the front of his closed
    # bill; the bill itself does not change.
    next(p for p in parts if p['id'] == 'held')['when'] = 'eyes=open'
    gold, line = '#F4BE2C', '#B8892A'
    parts.append({'id': 'dummy', 'parent': 'head', 'pivot': [120, 152], 'when': 'eyes=closed', 'shapes': [
        {'kind': 'path', 'd': 'M90 151 Q90 136 106 139 Q120 144 134 139 Q150 136 150 151 Q150 167 134 164 Q120 160 106 164 Q90 167 90 151 Z',
         'fill': gold, 'stroke': INK, 'tint': line, 'width': 5},
        {'kind': 'ellipse', 'x': 120, 'y': 160, 'rx': 12, 'ry': 12, 'stroke': INK, 'tint': line, 'width': 9},
        {'kind': 'ellipse', 'x': 120, 'y': 160, 'rx': 12, 'ry': 12, 'stroke': '#FBF6E9', 'width': 4},
        {'kind': 'ellipse', 'x': 120, 'y': 150, 'rx': 5.5, 'ry': 5.5, 'fill': '#FBF6E9', 'stroke': INK, 'tint': line, 'width': 3}]})
    for side in ('left', 'right'):
        next(p for p in parts if p['id'] == f'foot-{side}')['shapes'] = []
    return parts


# Outfits with trousers. The hips are drawn with the body; each trouser leg is part of its own leg, over
# the fur, so it swings with the leg in a walk.
TROUSERED = {('mum', 'trousers'), ('dad', 'jumper'), ('dad', 'overalls'), ('pop', 'waistcoat'), ('pop', 'jumper')}

def trouser_legs(name, parts, shade):
    colour = TRIM[name]
    upper = next(i for i, p in enumerate(parts) if p['id'] == 'upper')
    over = []
    for side in ('left', 'right'):
        leg = next(p for p in parts if p['id'] == f'leg-{side}')
        cx = leg['pivot'][0]
        left, right = (cx - 20, cx + 18) if side == 'left' else (cx - 18, cx + 20)
        leg['shapes'].append({'kind': 'path', 'd': f'M{left:g} 288 L{right:g} 288 L{right:g} 354 L{left:g} 354 Z',
                              'fill': colour, 'stroke': INK, 'tint': shade(colour), 'width': 7})
        # The same leg again, without its line and over the hips, so hips and leg read as one garment.
        over.append({'id': f'trouser-{side}', 'parent': leg['id'], 'pivot': leg['pivot'], 'shapes': [
            {'kind': 'path', 'd': f'M{left + 3.5:g} 291.5 L{right - 3.5:g} 291.5 L{right - 3.5:g} 350.5 L{left + 3.5:g} 350.5 Z', 'fill': colour}]})
    parts[upper + 1:upper + 1] = over
    return parts

def build(name, svg, height, about, shade, moves, puggle, variant=''):
    grown = height > 400
    if grown:
        # The tail's marks were left at a child's height on the canvas: put them on the tail.
        svg = svg.replace('M176 238 Q180 246 176 254 M191 237 Q196 246 191 255 M170 246 L203 246', 'M176 392 Q180 400 176 408 M191 391 Q196 400 191 409 M170 400 L203 400')
    svg = svg.replace('stroke-width="2.5" stroke-linecap="round" opacity="0.5"', f'stroke-width="2.5" stroke-linecap="round" data-mark="1"')
    shapes = refine(name, flatten(svg), shade)
    if grown:
        # On the canvas a grown-up is Puggle's head on a body two and a half times as long, which reads
        # as stretched beside her. Everything below the neck is drawn closer: about one and a quarter
        # times her height, the same head.
        K, NECK = 0.72, 166
        def lower(y): return y if y <= NECK else NECK + (y - NECK) * K
        tail_dy = None
        for shp in shapes:
            cy = (shp['box'][1] + shp['box'][3]) / 2
            if shp['tags'].get('part') == 'tail':
                if tail_dy is None: tail_dy = lower(400) - 400      # the tail moves as one piece
                shift(shp, 0, tail_dy)
            elif shp['kind'] == 'ellipse':
                if cy > NECK: shift(shp, 0, lower(cy) - cy)         # hands and buttons keep their shape
            elif shp['box'][3] > NECK:
                nums = re.findall(r'[A-Z]|-?\d*\.?\d+', shp['d']); text, pair = [], []
                for token in nums:
                    if token.isalpha(): text.append(token); continue
                    pair.append(float(token))
                    if len(pair) == 2: text.append(f'{pair[0]:g} {round(lower(pair[1]), 1):g}'); pair = []
                shp['d'] = re.sub(r'([A-Z]) ', r'\1', ' '.join(text))
                shp['box'] = (shp['box'][0], lower(shp['box'][1]), shp['box'][2], lower(shp['box'][3]))
        height = round(lower(442) + 20)
    # The head: the first big outlined shape up where a head is.
    head_at = next(i for i, s in enumerate(shapes)
                   if s.get('fill') and s.get('stroke') and s['box'][3] - s['box'][1] >= 105 and 80 < (s['box'][1] + s['box'][3]) / 2 < 135)
    torso_at = next(i for i, s in enumerate(shapes) if s['kind'] == 'path' and s.get('fill') and s.get('width') == 7)
    torso_bottom = shapes[torso_at]['box'][3]
    groups = []   # (part id, [shapes])
    def put(part, shape):
        if groups and groups[-1][0] == part: groups[-1][1].append(shape)
        else: groups.append((part, [shape]))
    arm, arm_left, shoulders = None, 0, {}
    for i, s in enumerate(shapes):
        cx, cy = (s['box'][0] + s['box'][2]) / 2, (s['box'][1] + s['box'][3]) / 2
        if s['tags'].get('part') == 'tail':
            if not s.get('fill') and s.get('width') == 2.5: s['stroke'] = shade('#8A5A3C')   # her tail's markings, in the fur's own dark
            put('tail', s); continue
        if i >= head_at:
            dark_dot = s['kind'] == 'ellipse' and s.get('fill') == INK and 'stroke' not in s and 6 <= s['rx'] <= 8 and abs(s['rx'] - s['ry']) < 0.1
            if dark_dot and i > head_at: put('eye-left' if cx < 120 else 'eye-right', s)
            else: put('head', s)
            continue
        if i < torso_at:
            put('legs', s); continue
        if s['tags'].get('arm'):
            side = s['tags']['arm']; shoulders[side] = s['tags']['shoulder']
            put('arm-' + side, s); continue
        start = re.match(r'M(88|152) (17\d|18\d)Q', s['d0'])
        if start and s.get('width') == 34:
            arm, arm_left = ('left' if start.group(1) == '88' else 'right'), 4
            shoulders[arm] = [float(start.group(1)), float(start.group(2))]
        if arm_left > 0:
            put('arm-' + arm, s); arm_left -= 1; continue
        if cy < 100 and i > torso_at: put('head-back', s); continue
        put('upper' if not any(g[0].startswith('arm') for g in groups) else 'held', s)

    # Outlines: dark by default, and a darker shade of what they go round in the coloured line style.
    last = None
    def finish(part_shapes):
        nonlocal last
        out = []
        for j, s in enumerate(part_shapes):
            shape = {k: s[k] for k in ('kind', 'x', 'y', 'rx', 'ry', 'd', 'rotate', 'fill', 'stroke', 'tint', 'width', 'cap') if k in s}
            if s.get('stroke') == INK and 'tint' not in s:
                if s.get('fill') and s['fill'] != INK: last = shade(s['fill'])
                elif not s.get('fill') and j + 1 < len(part_shapes) and part_shapes[j + 1].get('d') == s.get('d') and part_shapes[j + 1].get('stroke') != INK:
                    last = shade(part_shapes[j + 1]['stroke'])
                if last and s.get('fill') != INK: shape['tint'] = last
            out.append(shape)
        return out

    pivots = {'tail': [158, torso_bottom + 2], 'legs': [120, height - 14], 'upper': [120, torso_bottom], 'held': [120, torso_bottom],
              'arm-left': shoulders.get('left', [88, 178]), 'arm-right': shoulders.get('right', [152, 178]),
              'head-back': [120, 166], 'head': [120, 166]}
    parents = {'tail': 'body', 'legs': 'body', 'upper': 'body', 'held': 'upper', 'arm-left': 'upper', 'arm-right': 'upper',
               'head-back': 'head', 'head': 'upper', 'eye-left': 'head', 'eye-right': 'head'}
    parts = [{'id': 'body', 'pivot': [120, height - 10], 'shapes': []}]
    seen, eyes = {}, {}
    for part, part_shapes in groups:
        if part == 'legs':
            # Each leg on its own ankle, with a real foot: hers for the platypus family, their own for her friends.
            for side in ('left', 'right'):
                mine = [s for s in part_shapes if ((s['box'][0] + s['box'][2]) / 2 < 120) == (side == 'left')]
                leg = next((s for s in mine if s['src'] == 'rect'), None)
                pad = next((s for s in mine if s['src'] in ('ellipse', 'circle')), None)
                if leg:
                    cx, ankle, fur = (leg['box'][0] + leg['box'][2]) / 2, leg['box'][3], leg['fill']
                    parts.append({'id': f'leg-{side}', 'parent': 'body', 'pivot': [cx, leg['box'][1] + 2], 'shapes': finish([leg])})
                else:
                    cx, ankle, fur = pad['x'], pad['y'] - 6, pad['fill']
                sitting = name == 'pebble'
                if FEET[name] == 'webbed':
                    if sitting: foot = webbed_foot(puggle, side, cx + (6 if side == 'left' else -6), pad['y'] + 4, turn=-20 if side == 'left' else 20)
                    else: foot = webbed_foot(puggle, side, cx, ankle)
                else:
                    foot = paw(FEET[name], side, cx, ankle, fur, shade)
                parts.append({'id': f'foot-{side}', 'parent': f'leg-{side}' if leg else 'body', 'pivot': [cx, ankle], 'spring': 200, 'shapes': foot})
            continue
        if part.startswith('arm-') and part_shapes[0]['src'] == 'rect':
            # The friends' arms were plain blocks: give them hers.
            side = part[4:]
            hand = next(s['fill'] for s in part_shapes if s['kind'] == 'ellipse')
            parts.append({'id': part, 'parent': 'upper', 'pivot': [88 if side == 'left' else 152, 178], 'spring': 150,
                          'shapes': puggle_arm(side, part_shapes[0]['fill'], hand, shade)})
            seen[part] = 1
            continue
        seen[part] = seen.get(part, 0) + 1
        pid = part if seen[part] == 1 else f'{part}-{seen[part]}'
        entry = {'id': pid, 'parent': parents[part] if seen[part] == 1 or not part.startswith('head') else 'head', 'pivot': pivots.get(part), 'shapes': finish(part_shapes)}
        if seen[part] > 1: entry['parent'] = part if part in ('head', 'upper') else parents[part]
        if part.startswith('eye'):
            eye = part_shapes[0]; entry['pivot'] = [eye['x'], eye['y']]; entry['spring'] = 0; entry['when'] = 'eyes=open'
            eyes[part] = eye
        if part == 'tail': entry['spring'] = 70
        if part.startswith('arm'): entry['spring'] = 150
        parts.append(entry)
    # The head is an empty pivot that carries the face, and the ears or spines behind it, so they all turn together.
    first = next(i for i, p in enumerate(parts) if p['id'] in ('head-back', 'head'))
    for p in parts:
        if p['id'] == 'head': p['id'] = 'face'
        if p['id'] == 'face' or p['id'].startswith('head-'): p['parent'] = 'head'
    parts.insert(first, {'id': 'head', 'parent': 'upper', 'pivot': [120, 166], 'shapes': []})
    if eyes:
        closed = []
        for eye in eyes.values():
            x, y, r = eye['x'], eye['y'], eye['rx'] + 1.2
            closed.append({'kind': 'path', 'd': f'M{x - r:g} {y - 1:g} Q{x:g} {y + r - 1:g} {x + r:g} {y - 1:g}', 'stroke': INK, 'width': 4.5, 'cap': 'round'})
        parts.append({'id': 'eyes-closed', 'parent': 'head', 'pivot': [120, 110], 'when': 'eyes=closed', 'shapes': closed})
    parts = regrow_tail(parts, grown, sitting=name == 'pebble')
    if (name, variant) in TROUSERED: parts = trouser_legs(name, parts, shade)
    if name == 'pebble': parts = babygro(parts)
    parts = join_to_head(name, parts)
    parts = grow_hair(name, parts)
    parts = dress_for_weather(name, parts, puggle, shade)
    parts = finish_hats(name, parts)
    # Arms that bend at the elbow, and a book to hold. Pebble is too small to read, and has his bottle.
    parts = bend_arms.bend(parts)
    if name != 'pebble': parts = bend_arms.hold(parts, bend_arms.book(parts))
    ids = {p['id'] for p in parts}
    # Her moves, kept to the parts this character has. Faces are left alone: they have one pair of eyes.
    borrowed = {}
    for move_name in ('nod', 'greet', 'celebrate', 'wake', 'walk'):
        move = json.loads(json.dumps(moves[move_name]))
        for key in move.get('keys', []):
            key.pop('face', None)
            pose = key.get('pose', {})
            key['pose'] = {k: v for k, v in pose.items() if k in ids}
        borrowed[move_name] = move
    borrowed['greet'] = bend_arms.bend_wave(borrowed['greet'], parts)
    # The shoulders move with the body.
    # A wave with the other arm, for answering someone who stands on their left.
    mirror = json.loads(json.dumps(borrowed['greet']))
    for key in mirror['keys']:
        flipped = {}
        for part, pose in key['pose'].items():
            other = part.replace('right', 'LEFT').replace('left', 'right').replace('LEFT', 'left')
            flipped[other] = {k: (-v if k in ('r', 'x') else v) for k, v in pose.items()}
        key['pose'] = flipped
    borrowed['greet-left'] = mirror
    borrowed.update(bend_arms.arm_moves(parts, reads=name != 'pebble'))
    return {'name': name.capitalize(), 'size': [240, height], 'about': about + ' Cut from the canvas drawing by tools/make_cast_rigs.py; do not edit by hand.',
            'parts': parts, 'moves': borrowed, 'face': {'eyes': 'open'}}


def main():
    shade = shade_rule()
    puggle = json.load(open(RIGS + '/puggle.rig.json'))
    moves = puggle['moves']
    for name, (variants, height, colour, others, about) in drawings().items():
        # The same garment in other colours: a swap of its colour, its outline and its pocket. A grown-up's
        # outfit is a pair, so the trim is swapped with it.
        def swap(to, pocket=None, trim=None):
            if isinstance(to, tuple): to, trim = to
            swaps = {colour: to, shade(colour): shade(to), lighten(colour): pocket or lighten(to)}
            if name in TRIM and trim: swaps.update({TRIM[name]: trim, shade(TRIM[name]): shade(trim)})
            return swaps
        # In the rain the garment is a raincoat's yellow, unless they are under an umbrella.
        wardrobe = {'looks': [{}] + [swap(c) for c in others], 'rain': {} if name in UMBRELLA else swap('#F4C95D', '#FBE7A6', '#F4C95D')}
        for variant, svg in variants.items():
            rig = build(name, svg, height, about, shade, moves, puggle, variant)
            rig['wardrobe'] = wardrobe
            if name in UMBRELLA: rig = lowered(rig, HEADROOM)
            if name in UMBRELLA: rig['sideroom'] = SIDEROOM
            with open(f'{RIGS}/{name}{"-" + variant if variant else ""}.rig.json', 'w') as out:
                json.dump(rig, out, indent=1, ensure_ascii=False)
            print(name, variant or '(as drawn)', len(rig['parts']), 'parts')

if __name__ == '__main__':
    main()
