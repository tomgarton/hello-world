"""Draws Puggle from the app's own rig file (app/Puggle/Resources/Rigs/puggle.rig.json),
so the canvas matches the app. Copy the rig file to gen/puggle.rig.json before running.
render(face=..., pose=..., style='tinted'|'ink', moonlit=False) returns SVG markup for a 240 x 300 box."""
import json, math, os, colorsys
RIG = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals() else '.', 'puggle.rig.json')))
def _mul(a, b):
    # apply a first, then b; matrices as (a, b, c, d, e, f) in SVG order
    a1, b1, c1, d1, e1, f1 = a; a2, b2, c2, d2, e2, f2 = b
    return (a2*a1 + c2*b1, b2*a1 + d2*b1, a2*c1 + c2*d1, b2*c1 + d2*d1, a2*e1 + c2*f1 + e2, b2*e1 + d2*f1 + f2)
def _local(pivot, st):
    px, py = pivot; r = math.radians(st.get('r', 0)); sx, sy = st.get('sx', 1), st.get('sy', 1)
    m = (1, 0, 0, 1, -px, -py)
    m = _mul(m, (sx, 0, 0, sy, 0, 0))
    m = _mul(m, (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0))
    return _mul(m, (1, 0, 0, 1, px + st.get('x', 0), py + st.get('y', 0)))
def moon(hexc, amount=0.6):
    r, g, b = (int(hexc[i:i+2], 16) / 255 for i in (1, 3, 5))
    r *= 1 - amount * 0.34; g *= 1 - amount * 0.36; b *= 1 - amount * 0.06; b += amount * 0.18 * (1 - b)
    return '#%02X%02X%02X' % tuple(round(v * 255) for v in (r, g, b))
def _shape(s, style, moonlit):
    col = lambda c: moon(c) if moonlit else c
    fill = col(s['fill']) if s.get('fill') else 'none'
    a = f' fill="{fill}"'
    if s.get('stroke'):
        c = s.get('tint', s['stroke']) if style == 'tinted' else s['stroke']
        a += f' stroke="{col(c)}" stroke-width="{s.get("width", 1)}" stroke-linejoin="round"' + (' stroke-linecap="round"' if s.get('cap') == 'round' else '')
    if s.get('rotate') is not None and 'x' in s: a += f' transform="rotate({s["rotate"]} {s["x"]} {s["y"]})"'
    if s['kind'] == 'ellipse': return f'<ellipse cx="{s["x"]}" cy="{s["y"]}" rx="{s["rx"]}" ry="{s.get("ry", s["rx"])}"{a}></ellipse>'
    if s['kind'] == 'rect': return f'<rect x="{s["x"]}" y="{s["y"]}" width="{s["w"]}" height="{s["h"]}" rx="{s.get("r", 0)}"{a}></rect>'
    return f'<path d="{s["d"]}"{a}></path>'
def render(face=None, pose=None, style='tinted', moonlit=False, skip=()):
    f = dict(RIG['face']); f.update(face or {}); pose = pose or {}
    world, out = {}, ''
    for p in RIG['parts']:
        m = _local(p['pivot'], pose.get(p['id'], {}))
        if p.get('parent') in world: m = _mul(m, world[p['parent']])
        world[p['id']] = m
        if not p['shapes'] or p['id'] in skip: continue
        if p.get('when'):
            k, v = p['when'].split('=')
            if f.get(k) != v: continue
        out += f'<g data-part="{p["id"]}" transform="matrix({" ".join("%.4f" % v for v in m)})">' + ''.join(_shape(s, style, moonlit) for s in p['shapes']) + '</g>'
    return out
def key(move, t):
    """The pose and face held at time t of a move."""
    ks = [k for k in RIG['moves'][move]['keys'] if k['t'] <= t + 1e-6]
    k = ks[-1]
    return dict(face=k.get('face') or {}, pose=k.get('pose') or {})
ASLEEP = dict(face={'eyes': 'closed', 'brows': 'on', 'air': 'zzz'}, pose={'head': {'r': 6, 'y': 4}, 'tail': {'r': 10}, 'brow-left': {'y': 1, 'r': -14}, 'brow-right': {'y': 1, 'r': 14}})
