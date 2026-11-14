#!/usr/bin/env python3
"""Writes Puggle/Resources/Rigs/hatchling.rig.json: Puggle as a baby, in her egg.

Run from the app folder:  python3 tools/make_hatchling_rig.py
The drawing is the logo mark (docs/previews/logo, round ten, M3), moved onto a
200 x 134 board with the ground at y = 126 and the egg centred on x = 100.
"""
import json, math

DX, DY = 40, 20
INK = "#3A2A20"
SHELL = dict(fill="#FBF6E9", stroke=INK, tint="#D8CBB2", width=2.6)
RIM = [(22, 66), (28, 61), (34, 64), (40, 58), (46, 65.5), (52, 62), (58, 66.5), (64, 60),
       (69, 62.5), (75, 57.5), (81, 65.5), (87, 62), (92, 64.5), (98, 66)]
CAP = (4, 10, 0.55)   # the cap is the rim between these two dips, drawn this much shallower
SOFT = 2.4            # how far each corner of the break is rounded off

def n(v): return round(v, 2)
def sh(p): return (p[0] + DX, p[1] + DY)

def poly(pts, soft=0.0):
    d = "M%s %s" % (n(pts[0][0]), n(pts[0][1]))
    for i in range(1, len(pts) - 1):
        a, v, b = pts[i - 1], pts[i], pts[i + 1]
        if not soft:
            d += " L%s %s" % (n(v[0]), n(v[1])); continue
        la = math.hypot(a[0] - v[0], a[1] - v[1]); lb = math.hypot(b[0] - v[0], b[1] - v[1])
        ta = min(soft / la, 0.5); tb = min(soft / lb, 0.5)
        d += " L%s %s Q%s %s %s %s" % (n(v[0] + (a[0] - v[0]) * ta), n(v[1] + (a[1] - v[1]) * ta), n(v[0]), n(v[1]),
                                       n(v[0] + (b[0] - v[0]) * tb), n(v[1] + (b[1] - v[1]) * tb))
    return d + " L%s %s" % (n(pts[-1][0]), n(pts[-1][1]))

rim = [sh(p) for p in RIM]
rim_d = poly(rim, SOFT)
shell_d = rim_d + " C138 110 122 126 100 126 C78 126 62 110 62 86 Z"
i, j, k = CAP
seg = rim[i:j + 1]; dx = 100 - (seg[0][0] + seg[-1][0]) / 2
edge = [(x + dx, 46 + (y - seg[0][1]) * k) for x, y in seg]
cap_d = "M%s 46 Q100 22 %s %s" % (n(edge[0][0]), n(edge[-1][0]), n(edge[-1][1])) + " L" + poly(list(reversed(edge)), SOFT * 0.7)[1:] + " Z"
dome_d = ("M63.3 89.2" + "".join(" L%s %s" % (n(x), n(y + 3.2)) for x, y in rim[1:-1])
          + " L136.7 89.2 L138 86 C138 54 124 28 100 28 C76 28 62 54 62 86 Z")
arc_d = "M138 86 C138 54 124 28 100 28 C76 28 62 54 62 86"
left_d = poly(rim[0:i + 1], SOFT) + " L90 60 L81.2 34.5 Q62 50 62 86 Z"
right_d = poly(list(reversed(rim[j:])), SOFT) + " L111 62 L118.8 34.5 Q138 50 138 86 Z"
a, b = rim[i], rim[j]
crack_l = "M%s %s L%s %s L%s %s" % (a[0], a[1], a[0] - 2.5, a[1] + 6.5, a[0] + 1, a[1] + 10.5)
crack_r = "M%s %s L%s %s L%s %s L%s %s" % (b[0], b[1], b[0] + 2, b[1] + 5, b[0] - 0.5, b[1] + 8.5, b[0] + 1, b[1] + 11.5)

def path(d, **k): return dict(kind="path", d=d, **k)
def dot(x, y, r, fill, ry=None, **k): return dict(kind="ellipse", x=x, y=y, rx=r, ry=ry or r, fill=fill, **k)

parts = [
    dict(id="root", pivot=[100, 126], spring=230, shapes=[]),
    # The two pieces that break away. Hidden until the shell opens.
    dict(id="shard-left", parent="root", pivot=[76, 62], spring=60, when="bits=on", shapes=[path(left_d, **SHELL)]),
    dict(id="shard-right", parent="root", pivot=[124, 62], spring=52, when="bits=on", shapes=[path(right_d, **SHELL)]),
    # Her. "upper", "head", "eye-left", "eye-right" and "clip" are the names the player breathes, blinks and sways.
    dict(id="upper", parent="root", pivot=[100, 100], spring=150, shapes=[]),
    dict(id="head", parent="upper", pivot=[100, 84], shapes=[
        dict(kind="ellipse", x=100, y=62, rx=26, ry=23.5, fill="#8A5A3C", stroke=INK, tint="#5E3A24", width=2.6)]),
    dict(id="blush", parent="head", pivot=[100, 68.5], shapes=[dot(80, 68.5, 4.8, "#C27C66", ry=3.2), dot(120, 68.5, 4.8, "#C27C66", ry=3.2)]),
    dict(id="bill", parent="head", pivot=[100, 73], shapes=[
        dict(kind="ellipse", x=100, y=73, rx=15.5, ry=7.5, fill="#6E7F8D", stroke=INK, tint="#465668", width=2.6),
        dot(97.8, 70.2, 0.75, INK), dot(102.2, 70.2, 0.75, INK)]),
    dict(id="eye-left", parent="head", pivot=[89.5, 60], spring=0, when="eyes=open", shapes=[dot(89.5, 60, 3.2, INK)]),
    dict(id="eye-right", parent="head", pivot=[110.5, 60], spring=0, when="eyes=open", shapes=[dot(110.5, 60, 3.2, INK)]),
    dict(id="eyes-closed", parent="head", pivot=[100, 60], when="eyes=closed", shapes=[
        path("M85.5 60 Q89.5 64 93.5 60", stroke=INK, width=2.6, cap="round"),
        path("M106.5 60 Q110.5 64 114.5 60", stroke=INK, width=2.6, cap="round")]),
    # The piece of shell that stays on her head. Loose, so it arrives a beat after she does.
    dict(id="clip", parent="head", pivot=[100, 44], spring=70, shapes=[path(cap_d, **SHELL)]),
    dict(id="shell", parent="root", pivot=[100, 126], spring=300, shapes=[
        path(shell_d, **SHELL), dot(113, 105, 3.2, "#E0D2B8"), dot(123, 112.5, 2.2, "#E0D2B8"), dot(109.5, 116.5, 2.6, "#E0D2B8")]),
    dict(id="cracks", parent="shell", pivot=[100, 126], when="crack=on", shapes=[
        path(crack_l, stroke=INK, tint="#D8CBB2", width=1.8, cap="round"), path(crack_r, stroke=INK, tint="#D8CBB2", width=1.8, cap="round")]),
    # The unbroken top, over everything until the shell opens.
    dict(id="top", parent="root", pivot=[100, 126], when="shell=whole", shapes=[
        path(dome_d, fill="#FBF6E9"), path(arc_d, stroke=INK, tint="#D8CBB2", width=2.6, cap="round")]),
    dict(id="split", parent="root", pivot=[100, 126], when="split=on", shapes=[path(rim_d, stroke=INK, tint="#D8CBB2", width=2.6, cap="round")]),
]

REST = dict(eyes="open", shell="open", crack="on", split="off", bits="off")

def hatch():
    keys = []
    def key(t, face, **pose):
        keys.append(dict(t=t, pose=pose, face=face))
    inside = dict(upper=dict(y=30, sy=0.92))
    whole = dict(eyes="closed", shell="whole", crack="off", split="off", bits="off")
    # Still, one small rock, still again, then a harder rock.
    for t, r in [(0, 0), (0.35, -2.5), (0.47, 2), (0.6, 0), (1.0, -7), (1.16, 6), (1.32, -4), (1.46, 2), (1.58, 0)]:
        key(t, whole, root=dict(r=r), **inside)
    # The break runs across, then the two hairlines.
    key(1.72, dict(whole, split="on"), root=dict(r=-1.5), **inside)
    key(1.84, dict(whole, split="on"), **inside)
    key(1.95, dict(whole, split="on", crack="on"), **inside)
    opened = dict(eyes="closed", shell="open", crack="on", split="off", bits="on")
    up = {"shard-left": dict(x=-22, y=-14, r=-38), "shard-right": dict(x=26, y=-18, r=46)}
    down = {"shard-left": dict(x=-38, y=57, r=-94), "shard-right": dict(x=44, y=56, r=101)}
    # The top comes apart: two pieces are tossed out and she pushes up with the third on her head.
    key(2.3, opened, upper=dict(y=-3, sy=1.05), shell=dict(sx=1.04, sy=0.95), clip=dict(y=-2), **up)
    key(2.5, opened, upper=dict(y=0), **down)
    # Her eyes open over a moment.
    key(3.3, dict(opened, eyes="open"), **{"eye-left": dict(sy=0.2), "eye-right": dict(sy=0.2)}, **down)
    key(3.4, dict(opened, eyes="open"), **down)
    # The pieces on the ground shrink away, so she ends as the mark.
    gone = {k: dict(v, sx=0.02, sy=0.02) for k, v in down.items()}
    key(4.3, dict(opened, eyes="open"), **gone)
    return dict(about="She hatches: the egg rocks, cracks across and opens, and she comes up with a piece of shell on her head.",
                keys=keys, length=4.75)

rig = dict(name="Hatchling", size=[200, 134], parts=parts, face=REST, moves=dict(hatch=hatch()))
out = "Puggle/Resources/Rigs/hatchling.rig.json"
json.dump(rig, open(out, "w"), indent=1)
print("wrote", out, len(parts), "parts,", len(rig["moves"]["hatch"]["keys"]), "keys")
