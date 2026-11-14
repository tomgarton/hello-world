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
from make_icons import ICONS, OUT, DARK, POO, circle, rr, sparkle, icon, svg, regular

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
# Weight: a baby scale, with a curved tray on a base and a dial.
TRAY = 'M5 13C5 10 8 9 12 9.5C17 10.2 20 10.5 24 10.5C28 10.5 31 10.2 36 9.5C40 9 43 10 43 13C43 16.5 39 19 35 19H13C9 19 5 16.5 5 13Z'
BASE = 'M12 23H36C38 23 39.3 24.2 39.8 26L42.5 37C43.2 40 41.5 42.5 38.5 42.5H9.5C6.5 42.5 4.8 40 5.5 37L8.2 26C8.7 24.2 10 23 12 23Z'
DIAL = 'M15 38.5A9 9 0 0 1 33 38.5Z'
# Solids: a bowl on a foot, a mound of food, a spoon standing in it, and steam.
BOWL = 'M5 22H43C43 31 36.5 38 27 38H21C11.5 38 5 31 5 22Z'
MOUND = 'M10 22C10 18.5 12.5 16.5 15.5 17C16.5 14 20 13 22.5 15C24.5 12.5 28.5 13 29.5 16C33 15.5 35.5 18 35.5 22'
# Bath: a tub with a rim and feet, foam, a duck and two bubbles.
TUB = 'M7 24C7 32 11 38 18 38H30C37 38 41 32 41 24'
FOAM = 'M10 19C10 16 12.5 14.5 15 15.5C16 13 19.5 12.5 21 15C22.8 14 24.5 15.5 24.5 17.5V19'
DUCK = 'M27.5 19C26.5 16.5 27.5 14.5 29.5 14M36.5 13.5C38.8 14.8 39.8 17 39 19'
# Pump: a funnel, a body with a lever, and a bottle with milk in it.
FUNNEL = 'M15 5L25 16.5C27 16.5 29 18 29 20.5V24.5M20 24.5V21.5L7 19'
MOUTH = 'M14.5 4.5C17 6 15 12 12 15.5C9.5 18.5 7 19.5 6 18.5C4 17 6 11 9 7.5C11 5 13.3 3.8 14.5 4.5Z'
JAR = 'M17 30C14.5 31.5 13 34 13 37V39.5C13 42 15 44 17.5 44H30.5C33 44 35 42 35 39.5V37C35 34 33.5 31.5 31 30'
# Tummy time: a baby on its front, head up, an arm out in front and a foot kicked up behind.
BODY = ('M22.5 22C18 22.5 15 24.5 13 27.5C11.5 26 9.5 23 7.5 21.5C6 20.5 4.5 22 5.5 23.5C7 26 8 29 8 31.5C8 34.5 10 36.5 13 36.5H38.5C41 36.5 42.5 35 42.5 33.2'
        'C42.5 31.2 41 30 39 30C36.5 30 34.5 28.5 33 25.5')
POO2 = scale(POO)

LARGE = {
    'bottle': (doubled('bottle'), False),
    'breastfeed': (doubled('breastfeed'), False),
    'pump': (drawn([MOUTH, FUNNEL, 'M27 17.5C28 13 31.5 10.5 35 11.5C39 12.5 40 16.5 40.5 20.5C41 24 42 26.5 43 28', rr(15, 24.5, 18, 5.5, 2.5), JAR],
                   fine=['M13.2 36H34.8', 'M21 33H27M21 40H27'],
                   sky=['M15 5L25 16.5C27 16.5 29 18 29 20.5V24.5H20V21.5L7 19C4.5 17 6 11 9 7.5C11 5 13.3 3.8 15 5Z'],
                   wattle=['M13.2 36H34.8C35 36.3 35 36.7 35 37V39.5C35 42 33 44 30.5 44H17.5C15 44 13 42 13 39.5V37C13 36.7 13 36.3 13.2 36Z']), True),
    'solids': (drawn([BOWL, 'M17 38V40.5C17 41.6 17.9 42.5 19 42.5H29C30.1 42.5 31 41.6 31 40.5V38', MOUND, 'M30.5 16.5L39 7'],
                     fine=['M9 27C14 29.5 34 29.5 39 27', 'M9 12L7 9.5M13 10L12 6.5M17.5 10.5V7'],
                     sky=[BOWL], wattle=[MOUND + 'Z']), True),
    'sleep': (doubled('sleep'), False),
    'nappy': (doubled('nappy', only_fine=[scale('M8.5 7.3H15.5'), 'M21 23.5H27M21.5 27H26.5M22 30.5H26']), False),
    # The splash guard is the raised lip at the front. It is the blue body itself rising into the seat: the line between
    # blue and yellow swells up in the middle, with no edges of its own.
    'potty': (drawn([POTTY, 'M33.5 27.73A12 5 0 1 0 17.5 27.73', GUARD], fine=['M12 36.5H18'], sky=[POTTY], wattle=[SEAT], tint=[(GUARD + 'V29.5H17.5Z', '#BFD9F5')],
                    ink=['M18 24A7.5 2.8 0 0 1 33 24C33 24.9 31.9 25.7 30.3 26.2C29.8 23.8 28 22.4 25.5 22.4C23 22.4 21.2 23.8 20.7 26.2C19.1 25.7 18 24.9 18 24Z']), True),
    'bath': (drawn([rr(4, 19, 40, 5, 2.5), TUB, 'M14 38.5V41M34 38.5V41', FOAM, circle(32.5, 11, 4.2), DUCK, circle(13, 8.5, 2.5)],
                   fine=[circle(20, 5.5, 1.6), 'M36.5 10L39.8 11.3L36.3 12.8', 'M13 29Q16 27 19 29Q22 31 25 29'],
                   sky=[rr(4, 19, 40, 5, 2.5), TUB + 'Z'], wattle=[circle(32.5, 11, 4.2), 'M27.5 19C26.5 16.5 27.5 14.5 29.5 14L36.5 13.5C38.8 14.8 39.8 17 39 19Z'],
                   ink=[circle(33.3, 10.2, .9)]), True),
    'growth': (doubled('growth'), False),
    'weight': (drawn([TRAY, 'M20 19V23M28 19V23', BASE, DIAL, 'M24 38.5L27.5 32.5'],
                     fine=['M9.5 14.5C14 16 34 16 38.5 14.5', 'M24 29.5V31.8M17.6 32.1L19.2 33.7M30.4 32.1L28.8 33.7'],
                     sky=[TRAY, BASE], wattle=[DIAL]), True),
    'temperature': (doubled('temperature'), False),
    'medicine': (doubled('medicine'), False),
    'vaccine': (doubled('vaccine'), False),
    'teeth': (doubled('teeth', only_fine=[eye(18, 24, up=True), eye(29, 24, up=True)]), False),
    'milestone': (doubled('milestone'), False),
    'tummy-time': (drawn([circle(30, 17, 9), 'M21.6 13.8C27 15 33 13.5 36 10.3', BODY],
                         fine=[eye(31.5, 19.5), 'M24 18.5q-1.8 1.7 0 3.4', 'M27 36.5C27 33.2 29 31 31.5 30.4'],
                         sky=[BODY + 'A9 9 0 0 1 22.5 22Z'], wattle=[circle(30, 17, 9)]), True),
    # Three blocks with depth, as in ChatGPT's sheet: each shows its front, its top and its right side. The top
    # block sits across the two below. Lines hidden behind a nearer block are left out by hand.
    'play': (drawn([rr(4, 26, 16, 16, 3), rr(20, 26, 16, 16, 3), rr(12, 8, 16, 16, 3),
                    'M5 26.8L8.6 23.2C9.2 22.4 10 22 11 22H12', 'M20 26L22.5 24',
                    'M29 22H38.5C40 22 41 23 41 24.5V35.5C41 36.5 40.6 37.3 40 37.9L35.2 41.2', 'M35.2 26.8L40.2 22.7',
                    'M13 8.8L16.6 5.2C17.2 4.4 18 4 19 4H30.5C32 4 33 5 33 6.5V17.5C33 18.5 32.6 19.3 32 19.9L27.2 23.2', 'M27.2 8.8L32.2 4.7',
                    sparkle(20, 16, 4.6), 'M12 30.8L16 37.5H8Z', circle(28, 34, 3.6)],
                   wattle=[rr(12, 8, 16, 16, 3)], sky=[rr(20, 26, 16, 16, 3)]), True),
    'walk': (doubled('walk', fine=['M20 21L9 16.5']), False),
    'note': (doubled('note'), False),
    'photo': (doubled('photo'), False),
    'poo': (drawn([POO2, 'M17 20H24'], fine=[eye(18, 34.5), eye(30, 34.5), 'M22 38.8A2 2 0 0 0 26 38.8', 'M33.5 9L35.5 5.5M36.5 12.5L40 10.5'],
                  tint=[(POO2, '#C99668')]), True),
    'wee': (doubled('wee'), False),
}


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
