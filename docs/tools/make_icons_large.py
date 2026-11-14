"""Puggle's activity icons, the large drawing (14 November 2026).

The third of the three sizes (see make_icons.py for small and regular). A 48 canvas, a 2.4 point line, details
in a 1.6 line. For where an icon stands alone: the log sheet, a picker, first run.

Seven are drawn afresh, after two sheets of ideas ChatGPT drew for Tom: potty, poo, weight, solids, bath, pump
and tummy time. The rest are the regular drawing at twice the size with the finer line, some with a little more.
Still Wattle and Sky, still one line colour.

Run `python3 docs/tools/make_icons_large.py` from the repo: it writes docs/previews/icons/v2/large/*.svg and the
sheet docs/previews/icons/large.html. Nothing here is in the app.
"""
import os, re
from make_icons import ICONS, OUT, DARK, POO, BLOCKS48, circle, rr, sparkle, icon, svg, regular

LINE, FINE = 2.4, 1.6
ARGS = {'M': 2, 'L': 2, 'H': 1, 'V': 1, 'C': 6, 'S': 4, 'Q': 4, 'T': 2, 'A': 7, 'Z': 0}


def scale(d, k=2):
    """A path at k times the size. Arc flags and rotation are left alone."""
    out, tokens, i = '', re.findall(r'[A-Za-z]|-?\d*\.?\d+', d), 0
    while i < len(tokens):
        cmd = tokens[i]; i += 1
        n = ARGS[cmd.upper()]
        out += cmd
        first = True
        while first or (n and i < len(tokens) and not tokens[i].isalpha()):
            first = False
            nums = [float(t) for t in tokens[i:i + n]]; i += n
            if cmd.upper() == 'A': nums = [nums[0] * k, nums[1] * k, nums[2], nums[3], nums[4], nums[5] * k, nums[6] * k]
            else: nums = [v * k for v in nums]
            out += ' '.join(f'{v:g}' for v in nums) + ' '
            if not n: break
    return out.strip()


def doubled(name, fine=(), ink=(), lines=(), only_fine=None):
    """The regular drawing at twice the size, with anything the large one adds."""
    spec = regular(name)
    out = dict(spec, box=48, weight=LINE, fineweight=FINE, turn=spec['turn'], centre=24)
    for key in ('lines', 'fine', 'sky', 'wattle', 'ink'):
        out[key] = [scale(d) for d in spec[key]]
    out['tint'] = [(scale(t[0]),) + tuple(t[1:]) for t in spec['tint']]
    if only_fine is not None: out['fine'] = list(only_fine)
    out['fine'] += list(fine); out['ink'] += list(ink); out['lines'] += list(lines)
    return out


def drawn(lines, fine=(), **fills):
    return dict(icon(lines, fine=fine, box=48, weight=LINE, **fills), fineweight=FINE, centre=24)


def eye(x, y, w=2.3, up=False):
    return f'M{x - w} {y}A{w} {w} 0 0 {1 if up else 0} {x + w} {y}'


# Potty: a backrest, a seat ring with its opening and a splash guard, and a base with two feet.
POTTY = ('M8 40C7 34 9 24 11 21C12 19 14 18 17 17.5C17 10 20 5.5 25.5 5.5C31 5.5 34 10 34.5 18C37.5 18.5 39.5 20 40.5 22'
         'C42.5 26 43.5 34 43 40C43 42 42 43 40 43H34C33 43 32.5 42 32 41H19C18.5 42 18 43 17 43H11C9 43 8 42 8 40Z')
SEAT = 'M13.5 24A12 5 0 1 0 37.5 24A12 5 0 1 0 13.5 24Z'
GUARD = 'M17.5 27.73C19.5 28 20.3 27 20.6 25.8C21.2 23.6 23 22.4 25.5 22.4C28 22.4 29.8 23.6 30.4 25.8C30.7 27 31.5 28 33.5 27.73'
# Weight: a baby scale. A shallow tray with its dish underneath, a short neck, and a base with a dial.
TRAY = 'M5 12.5C5 9.8 7.8 8.8 11.5 9.3C16.5 10 20 10.3 24 10.3C28 10.3 31.5 10 36.5 9.3C40.2 8.8 43 9.8 43 12.5C43 15 40.5 16.5 37 16.5H11C7.5 16.5 5 15 5 12.5Z'
DISH = 'M11 16.5C12 19.5 14.5 21.5 18 21.5H30C33.5 21.5 36 19.5 37 16.5'
BASE = 'M13 24H35C37 24 38.3 25.2 38.8 27L41.5 37.5C42.2 40.5 40.5 43 37.5 43H10.5C7.5 43 5.8 40.5 6.5 37.5L9.2 27C9.7 25.2 11 24 13 24Z'
DIAL = 'M14.5 39.5A9.5 9.5 0 0 1 33.5 39.5Z'
# Solids: a deep bowl with a rim and a foot, a mound of food, a spoon standing in it, and steam.
BOWL = 'M5 21H43C43 31.5 35.5 39 24 39C12.5 39 5 31.5 5 21Z'
MOUND_A = 'M10 21C10 17.5 12.5 15.5 15.5 16C16.5 13 20 12 22.5 14C24 12.2 27.5 12 29.6 14'
MOUND_B = 'M33 16.8C35.5 17.3 37 19 37 21'
SPOON = 'M31.2 18.9L40.7 7.9A2.2 2.2 0 0 0 37.3 5.1L27.8 16.1A2.2 2.2 0 0 0 31.2 18.9Z'
# Bath: a tub with a rim and round feet, foam, a duck facing the foam, and two bubbles.
TUB = 'M7.5 24C7.5 32.5 12 38 19 38H29C36 38 40.5 32.5 40.5 24'
FOAM = 'M9.5 19C9.5 16 12 14.5 14.5 15.5C15.5 13 19 12.5 20.5 15C22 14.2 23.5 15.5 23.5 17.5V19'
DUCK = 'M26.5 19C26 16 27.3 13.8 29.3 12.8M36 12.3C37.5 14 39.5 14 41 12.5C42 15 41.5 17.5 40.5 19'
BEAK = 'M28.3 8L24.8 9.5L28.3 11'
# Pump: a funnel, a body with a lever, and a bottle with milk in it.
FUNNEL = 'M15 5L25 16.5C27 16.5 29 18 29 20.5V24.5M20 24.5V21.5L7 19'
MOUTH = 'M14.5 4.5C17 6 15 12 12 15.5C9.5 18.5 7 19.5 6 18.5C4 17 6 11 9 7.5C11 5 13.3 3.8 14.5 4.5Z'
JAR = 'M17 30C14.5 31.5 13 34 13 37V39.5C13 42 15 44 17.5 44H30.5C33 44 35 42 35 39.5V37C35 34 33.5 31.5 31 30'
# Tummy time: a baby on its front, head up, an arm out in front, its back and bottom behind. Only the hair is filled.
BODY = ('M22.5 22C18 21.6 14.5 23.2 12.8 26.2C9 25.4 5 27.8 5 31.3C5 34.4 7.5 36.5 10.5 36.5H38.5C41 36.5 42.5 35 42.5 33.2'
        'C42.5 31.2 41 30 39 30C36.5 30 34.5 28.5 33 25.5')
HAIR = 'M21.6 13.8C27 15 33 13.5 36 10.3'
# The pump's lever: a handle with its own thickness, arcing over and hanging down.
LEVER = ('M27 16C28 11.5 31.5 9 35.2 10C39.5 11.2 40.8 15.5 41.3 20C41.7 23.5 42.6 26 43.5 27.8A1.8 1.8 0 0 1 40.3 29.3'
         'C39.3 27 38.7 24.3 38.2 20.6C37.8 17.5 37.3 14.1 34.8 13.3C32.6 12.6 30.6 14.5 30 17.5')
POO2 = scale(POO)

LARGE = {
    'bottle': (doubled('bottle'), False),
    'breastfeed': (doubled('breastfeed'), False),
    'pump': (drawn([MOUTH, FUNNEL, LEVER, rr(15, 24.5, 18, 5.5, 2.5), JAR],
                   fine=['M13.2 36H34.8', 'M21 32.5H27M21 39H27M21 41.8H25'],
                   sky=['M15 5L25 16.5C27 16.5 29 18 29 20.5V24.5H20V21.5L7 19C4.5 17 6 11 9 7.5C11 5 13.3 3.8 15 5Z'],
                   wattle=['M13.2 36H34.8C35 36.3 35 36.7 35 37V39.5C35 42 33 44 30.5 44H17.5C15 44 13 42 13 39.5V37C13 36.7 13 36.3 13.2 36Z']), True),
    'solids': (drawn([BOWL, 'M17.5 39.5V41A2 2 0 0 0 19.5 43H28.5A2 2 0 0 0 30.5 41V39.5', MOUND_A, MOUND_B, SPOON,
                      'M8.5 13.5L6 10.5M13 11L11.8 7M18 10.5V6.5'],
                     fine=['M6 25.5H42'],
                     wattle=[MOUND_A + 'L27.8 16.1A2.2 2.2 0 0 0 31.2 18.9L33 16.8C35.5 17.3 37 19 37 21Z']), True),
    'sleep': (doubled('sleep'), False),
    'nappy': (doubled('nappy', only_fine=[scale('M8.5 7.3H15.5'), 'M21 23.5H27M21.5 27H26.5M22 30.5H26']), False),
    # The splash guard is the raised lip at the front. It is the blue body itself rising into the seat: the line between
    # blue and yellow swells up in the middle, with no edges of its own.
    'potty': (drawn([POTTY, 'M33.5 27.73A12 5 0 1 0 17.5 27.73', GUARD], fine=['M12 36.5H18'], sky=[POTTY], wattle=['M33.5 27.73A12 5 0 1 0 17.5 27.73' + GUARD[GUARD.index('C'):] + 'Z'],
                    ink=['M18 24A7.5 2.8 0 0 1 33 24C33 24.9 31.9 25.7 30.3 26.2C29.8 23.8 28 22.4 25.5 22.4C23 22.4 21.2 23.8 20.7 26.2C19.1 25.7 18 24.9 18 24Z']), True),
    'bath': (drawn([rr(4, 19, 40, 5, 2.5), TUB, circle(14, 40.3, 1.9), circle(34, 40.3, 1.9), FOAM, circle(32.5, 9.5, 4.5), DUCK, circle(12.5, 8.5, 2.6)],
                   fine=[circle(19, 5.5, 1.6), BEAK + 'Z', 'M32 16.2Q34.5 18 37 16'],
                   wattle=[circle(32.5, 9.5, 4.5), 'M26.5 19C26 16 27.3 13.8 29.3 12.8L36 12.3C37.5 14 39.5 14 41 12.5C42 15 41.5 17.5 40.5 19Z', BEAK + 'Z'],
                   ink=[circle(31, 8.8, .9)]), True),
    'growth': (doubled('growth'), False),
    'weight': (drawn([TRAY, DISH, 'M19 21.5V24M29 21.5V24', BASE, DIAL, 'M24 39.5L27.6 33.3'],
                     fine=['M10 13.2C14.5 14.3 33.5 14.3 38 13.2', 'M24 30V32.5M15.8 34.8L17.9 36M32.2 34.8L30.1 36'],
                     wattle=[DIAL]), True),
    'temperature': (doubled('temperature'), False),
    'medicine': (doubled('medicine'), False),
    'vaccine': (doubled('vaccine'), False),
    'teeth': (doubled('teeth'), False),
    'milestone': (doubled('milestone'), False),
    # The eye is a dot, high under the fringe: a closed-eye arc lower on the face read as a mouth.
    'tummy-time': (drawn([circle(30, 17, 9), HAIR, BODY],
                         fine=['M27 36.5C27 33.2 29 31 31.5 30.4', 'M12.8 26.2C14 27.4 14.8 29 14.8 30.8'],
                         wattle=[HAIR + 'A9 9 0 0 0 21.6 13.8Z'], ink=[circle(33.6, 17, 1.4)]), True),
    'play': (drawn(BLOCKS48 + [sparkle(20, 16, 4.6), 'M12 30.8L16 37.5H8Z', circle(28, 34, 3.6)], wattle=[rr(12, 8, 16, 16, 3)]), True),
    'walk': (doubled('walk', fine=['M20 21L9 16.5']), False),
    'note': (doubled('note'), False),
    'photo': (doubled('photo'), False),
    # No face: Tom took the eyes and smile off the poo and the tooth.
    'poo': (drawn([POO2, 'M17 20H24M12.4 31H22'], fine=['M33.5 9L35.5 5.5M36.5 12.5L40 10.5'],
                  tint=[(POO2, '#C99668')]), True),
    'wee': (doubled('wee'), False),
}


# One fill each, as in make_icons.py: the Sky fills go, and so does a tint in Sky (the potty's guard).
for _spec, _ in LARGE.values():
    _spec['sky'] = []
    _spec['tint'] = [t for t in _spec['tint'] if t[1] != '#BFD9F5']


def art(spec, **k):
    text = svg('x', spec=spec, **k)
    return text.replace('rotate(%s 12 12)' % spec['turn'], 'rotate(%s 24 24)' % spec['turn']) if spec['turn'] else text


def main():
    folder = os.path.join(OUT, 'v2', 'large')
    os.makedirs(folder, exist_ok=True)
    cells = ''
    for name, (spec, fresh) in LARGE.items():
        open(os.path.join(folder, f'icon-{name}.svg'), 'w').write(art(spec))
        label = name.replace('-', ' ').capitalize()
        cells += (f'<div class="c"><div class="big">{art(spec, size=170)}</div>'
                  f'<div class="r"><span class="chip">{art(spec, size=64)}</span><span class="chip dk">{art(spec, ink=DARK, size=64)}</span>'
                  f'<span class="tile">{svg(name, spec=regular(name), size=40)}</span></div>'
                  f'<h3>{label}</h3><p>{"Drawn afresh." if fresh else "The regular drawing, larger."}</p></div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle icons, the large drawing</title><style>
body{{margin:0;padding:34px;background:#EFE7D4;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1180px}}
h1{{margin:0 0 4px;font-size:30px;letter-spacing:-.02em}}.lede{{margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:84ch}}
h3{{margin:10px 0 2px;font-size:17px}}p{{margin:0;color:#6B5E52}}
.g{{display:flex;flex-wrap:wrap;gap:30px 20px}}.c{{width:220px}}
.big{{background:#FBF6E9;border-radius:22px;height:206px;display:grid;place-items:center}}
.r{{display:flex;align-items:center;gap:8px;margin-top:8px}}.chip{{background:#FBF6E9;border-radius:18px;width:80px;height:80px;display:grid;place-items:center}}
.dk{{background:#2A2420}}.tile{{background:#FBF6E9;border-radius:14px;width:52px;height:52px;display:grid;place-items:center}}
</style></head><body><h1>Puggle icons, the large drawing</h1>
<p class="lede">For where an icon stands alone. Each is shown close up, then at 64 points on paper and in dark, then the regular drawing at 40 points to compare.</p>
<div class="g">{cells}</div></body></html>'''
    open(os.path.join(OUT, 'large.html'), 'w').write(html)
    print(len(LARGE), 'large icons')


if __name__ == '__main__':
    main()
