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
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
CANVAS = os.path.normpath(os.path.join(HERE, '..', '..', 'design', 'canvas'))
RIGS = os.path.normpath(os.path.join(HERE, '..', 'Puggle', 'Resources', 'Rigs'))
INK = '#3A2A20'


# ---------- The drawings ----------

def drawings():
    src = open(CANVAS + '/gen/lineup.py').read()
    src = src[:src.index('GROUND = 470')].replace('ROOT = sys.argv[1]', '')
    g = {'ROOT': CANVAS, 'sys': sys, '__name__': 'cast'}
    sys.argv = [sys.argv[0], CANVAS]   # the canvas scripts read their folder from here
    exec(src, g)
    adult, baby, inner, quokka, A = g['adult'], g['baby'], g['inner'], g['quokka_kid'], g['A']
    return {
        'nan': (adult('#E5553B', 'nan'), 456, "Nan: Puggle's grandmother. A fur bun, pale blue reading glasses on her bill, a red cardigan."),
        'mum': (adult('#3C9A5F', 'mum'), 456, "Mum: a flower behind her ear, a green dress."),
        'dad': (adult('#2A62B8', 'dad'), 456, "Dad: a blue shirt and shorts."),
        'pop': (adult('#BFD9F5', 'pop'), 456, "Pop: Puggle's grandfather. Round glasses, a green bucket hat, a pale blue cardigan."),
        'pebble': (baby('happy', '#F4BE2C'), 270, "Pebble: Puggle's baby sibling, about six months, sitting with a bottle. A Kewpie curl."),
        'quill': (inner('echidna', 'dungarees', '#E5553B'), 300, "Quill: an echidna, Puggle's friend. Red dungarees; the spines are the signature."),
        'kip': (inner('koala', 'dress', '#F4BE2C') + A['bow'](150, 50, '#2A62B8'), 300, "Kip: a koala, Puggle's best friend, who can fall asleep anywhere. A blue bow."),
        'digby': (inner('wombat', 'tee', '#2A62B8') + A['beanie']('#E5553B'), 300, "Digby: a wombat who loves digging. A red beanie."),
        'sunny': (quokka('#3C9A5F') + A['sunhat']('#F4E7B0'), 300, "Sunny: a quokka, always smiling. A sun hat."),
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


# ---------- Cutting it into parts ----------

def build(name, svg, height, about, shade, moves):
    shapes = flatten(svg)
    grown = height > 400
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
            if s['opacity'] < 1 and grown: continue      # the tail's marks were left at a child's height on the canvas
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
            shape = {k: s[k] for k in ('kind', 'x', 'y', 'rx', 'ry', 'd', 'rotate', 'fill', 'stroke', 'width', 'cap') if k in s}
            if s.get('stroke') == INK:
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
    return {'name': name.capitalize(), 'size': [240, height], 'about': about + ' Cut from the canvas drawing by tools/make_cast_rigs.py; do not edit by hand.',
            'parts': parts, 'moves': borrowed, 'face': {'eyes': 'open'}}


def main():
    shade = shade_rule()
    moves = json.load(open(RIGS + '/puggle.rig.json'))['moves']
    for name, (svg, height, about) in drawings().items():
        rig = build(name, svg, height, about, shade, moves)
        with open(f'{RIGS}/{name}.rig.json', 'w') as out:
            json.dump(rig, out, indent=1, ensure_ascii=False)
        print(name, [f"{p['id']}:{len(p['shapes'])}" for p in rig['parts']])

if __name__ == '__main__':
    main()
