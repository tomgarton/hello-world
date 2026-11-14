"""Puggle's repeat patterns, made from the brand's eight soft shapes.

Each pattern is one tile that repeats without a seam: a list of shapes, each with a place, a size, a turn
and a tone. Shapes that cross a tile's edge are drawn again on the far side, so the repeat joins up.
Patterns are tone on tone: a soft field, with shapes a little darker (d), darker again (dd) or lighter (l).

Run `python3 docs/tools/make_patterns.py` from the repo. It writes one SVG tile per pattern and colourway to
docs/previews/patterns/tiles/, and the sheet docs/previews/patterns/repeats.html.
"""
import os, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'patterns')

SHAPES = {   # each drawn in a 24 by 24 box, centred on 12, 12 (app/Puggle/Resources/Assets.xcassets/shape-*)
    'quatrefoil': 'M7.31 7.31A4.7 4.7 0 0 1 16.69 7.31A4.7 4.7 0 0 1 16.69 16.69A4.7 4.7 0 0 1 7.31 16.69A4.7 4.7 0 0 1 7.31 7.31Z',
    'pill': 'M6.5 8H17.5Q21.5 8 21.5 12V12Q21.5 16 17.5 16H6.5Q2.5 16 2.5 12V12Q2.5 8 6.5 8Z',
    'scallop': 'M4.5 18.5a1.5 1.5 0 0 1-1.5-1.5V12.5a3 3 0 0 1 6 0a3 3 0 0 1 6 0a3 3 0 0 1 6 0V17a1.5 1.5 0 0 1-1.5 1.5Z',
    'square': 'M8.5 3.5H15.5Q20.5 3.5 20.5 8.5V15.5Q20.5 20.5 15.5 20.5H8.5Q3.5 20.5 3.5 15.5V8.5Q3.5 3.5 8.5 3.5Z',
    'hexagon': 'M17.99 6.92L19.81 9.80Q21.20 12.00 19.81 14.20L17.99 17.08Q16.60 19.27 14.00 19.27L10.00 19.27Q7.40 19.27 6.01 17.08L4.19 14.20Q2.80 12.00 4.19 9.80L6.01 6.92Q7.40 4.73 10.00 4.73L14.00 4.73Q16.60 4.73 17.99 6.92Z',
    'pebble': 'M12 3.5C18.5 3.5 21.3 7.5 20.8 12.6S16.6 20.8 11 20.4S2.8 16.8 3.3 11.4S6 3.5 12 3.5Z',
    'halfpill': 'M5 6H14a6 6 0 0 1 0 12H5a1.5 1.5 0 0 1-1.5-1.5V7.5A1.5 1.5 0 0 1 5 6Z',
    'blossom': 'M7.85 6.28A4.3 4.3 0 0 1 16.15 6.28A4.3 4.3 0 0 1 18.72 14.18A4.3 4.3 0 0 1 12.00 19.07A4.3 4.3 0 0 1 5.28 14.18A4.3 4.3 0 0 1 7.85 6.28Z',
}

FIELDS = {   # the field, then its tones: a little darker (d), darker again (dd), lighter (l)
    'sun': {'f': '#F4E7B0', 'd': '#EDDB93', 'dd': '#E6CF78', 'l': '#FAF1CC'},
    'sky': {'f': '#BFD9F5', 'd': '#ABCBEE', 'dd': '#97BCE6', 'l': '#D5E6F9'},
    'shell': {'f': '#F3D9C9', 'd': '#ECC9B5', 'dd': '#E4B89F', 'l': '#F9E7DC'},
    'mint': {'f': '#CFE5D2', 'd': '#BBD9BF', 'dd': '#A6CCAB', 'l': '#E0EFE2'},
    'lilac': {'f': '#E0D3EE', 'd': '#D2C2E6', 'dd': '#C3B0DC', 'l': '#ECE3F5'},
    'sand': {'f': '#EFE7D4', 'd': '#E4D9C0', 'dd': '#D8CBAC', 'l': '#F8F2E4'},
}

# The same colours for dark mode: each field deep and muted, with shapes a little lighter (d), lighter again (dd)
# or deeper (l). No pattern is dark in light mode; the dark versions are for dark mode and the night look.
DARK = {
    'sun': {'f': '#3A3116', 'd': '#483D1D', 'dd': '#584B25', 'l': '#2F2811'},
    'sky': {'f': '#1C2B42', 'd': '#253752', 'dd': '#304564', 'l': '#162338'},
    'shell': {'f': '#3F2A20', 'd': '#4D3428', 'dd': '#5C4032', 'l': '#34221A'},
    'mint': {'f': '#1E3226', 'd': '#283F30', 'dd': '#334E3C', 'l': '#182A1F'},
    'lilac': {'f': '#2B2440', 'd': '#372E50', 'dd': '#453A62', 'l': '#231D35'},
    'sand': {'f': '#2A2420', 'd': '#352E29', 'dd': '#413932', 'l': '#221D19'},
}


def lattice(cell, first, second, size, tones=('d', 'l'), turns=(0, 0), sizes=None, cols=1, rows=1):
    """An evenly spaced repeat: one shape at every corner of a square grid, and another in the middle of every
    square, so each shape is the same distance from its four neighbours. Every shape is the same size unless
    `sizes` gives the middles their own. `first` and `second` are lists, used in turn across and down the tile."""
    marks = []
    for r in range(rows):
        for c in range(cols):
            step = c * 2 + r * (len(first) // 2 if len(first) > 1 else 0)
            marks.append((first[step // 2 % len(first)] if len(first) < cols else first[(c + r * 2) % len(first)],
                          c * cell, r * cell, size, turns[0], tones[0]))
            marks.append((second[(c + r * 2) % len(second)], c * cell + cell / 2, r * cell + cell / 2,
                          (sizes or (size, size))[1], turns[1], tones[1]))
    return cell * cols, cell * rows, marks


def named(grid, about, home):
    return grid + (about, home)


# name: (tile width, tile height, [(shape, x, y, size, turn, tone)], what it is, its home colour)
# All on one rule (Tom, 14 November 2026): evenly spaced, the shapes large and all one size, nothing scattered.
PATTERNS = {
    'mix': named(lattice(84, ['quatrefoil', 'pebble', 'square', 'blossom'], ['pill', 'hexagon', 'halfpill', 'scallop'], 2.15, cols=4, rows=2),
                 'All eight shapes in turn, one size, evenly spaced. The brand\'s own strip as a field.', 'sky'),
    'pair': named(lattice(84, ['quatrefoil'], ['blossom'], 2.25),
                  'Quatrefoils and blossoms in turn. The repeat already on the brand\'s clothing boards.', 'sky'),
    'pills': named(lattice(84, ['pill'], ['pill'], 2.25, turns=(0, 90)),
                   'Pills lying down and standing up in turn, like a basket weave.', 'sun'),
    'bloom': named(lattice(84, ['blossom'], ['pebble'], 2.25),
                   'Blossoms and pebbles in turn.', 'shell'),
    # Honeycomb: columns 39 apart, every other column dropped by half a row. Four columns by three rows.
    'comb': (156, 138, [('hexagon', c * 39, r * 46 + (23 if c % 2 else 0), 2.2, 0, tone)
                        for c, column in enumerate(['dld', 'ddl', 'ldd', 'dld']) for r, tone in enumerate(column)],
             'Soft hexagons set out like honeycomb, with clear gaps between, two tones.', 'mint'),
    'sparkle': named(lattice(84, ['quatrefoil'], ['quatrefoil'], 2.25, sizes=(2.25, 1.0)),
                     'Quatrefoils, large and small in turn. The brand\'s stars.', 'lilac'),
    # Each scallop is three bumps, 57.6 wide at this size. Rows 19 apart, every other row moved over by half a bump,
    # and each row drawn over the foot of the one above it.
    'scales': (57.6, 38, [('scallop', 0, 0, 3.2, 0, 'd'), ('scallop', 9.6, 19, 3.2, 0, 'l')],
               'Scallops in overlapping rows, like roof tiles or waves.', 'sky'),
    'check': (104, 104, [('square', 26, 26, 2.5, 0, 'd'), ('square', 78, 78, 2.5, 0, 'd'), ('square', 78, 26, 2.5, 0, 'l'), ('square', 26, 78, 2.5, 0, 'l')],
              'Soft squares in a check, two tones.', 'sand'),
}


# ---------- Outline patterns: the cast's heads and the app's line icons, drawn in one line ----------
RIGS = os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Rigs')
ICONS = os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets')
CAST = ['puggle', 'kip', 'quill', 'digby', 'sunny', 'mum', 'dad', 'nan', 'pop']    # everyone but Pebble, who is too like Mum in line
THINGS = ['bottle', 'sleep', 'nappy', 'bath', 'solids', 'potty', 'play', 'milestone']
INK = '#3A2A20'


def head(name, line, field):
    """A character's head as a line drawing, taken from the app's own rig (never redrawn): every outline in one
    colour, every fill in the field's colour so shapes still sit in front of one another, eyes and nostrils solid."""
    import json
    rig = json.load(open(os.path.join(RIGS, f'{name}.rig.json')))
    parts = {p['id']: p for p in rig['parts']}
    face = dict(rig.get('face') or {}, outfit='none', shades='none')
    def on_head(part):
        if part['id'] == 'head': return True    # Puggle's head shape is on the head part itself
        while part.get('parent'):
            if part['parent'] == 'head': return True
            part = parts[part['parent']]
        return False
    def shown(part):
        for condition in (part.get('when') or '').split('&'):
            if '=' in condition:
                key, values = condition.split('=')
                if face.get(key) not in values.split('|'): return False
        return True
    out = ''
    for part in rig['parts']:
        if not on_head(part) or not shown(part) or part['id'].startswith('sunnies'): continue
        for shape in part['shapes']:
            fill, stroke = shape.get('fill', '').upper(), shape.get('stroke', '').upper()
            if fill in ('#C27C66', '#EE9C88') and not stroke: continue           # cheeks: left out of a line drawing
            if stroke in ('#B79F8A', '#D6CDBE', '#FFFFFF'): continue             # grey in the hair, a shine: left out
            # Every other line is kept, whatever its colour: the short line under a nose is a friend's mouth.
            def dark(colour):
                value = int(colour[1:], 16)
                return (0.299 * (value >> 16) + 0.587 * (value >> 8 & 255) + 0.114 * (value & 255)) / 255 < 0.25
            # Eyes, nostrils and noses are solid; everything else is the field's colour, so it still sits in front.
            paint = f'fill="{line if fill and dark(fill) else field if fill else "none"}"'
            if stroke: paint += f' stroke="{line}" stroke-width="{round(shape.get("width", 1) * 1.3, 1)}" stroke-linejoin="round" stroke-linecap="{shape.get("cap", "round")}"'
            turn = f' transform="rotate({shape["rotate"]} {shape["x"]} {shape["y"]})"' if shape.get('rotate') else ''
            if shape['kind'] == 'ellipse':
                out += f'<ellipse cx="{shape["x"]}" cy="{shape["y"]}" rx="{shape["rx"]}" ry="{shape.get("ry", shape["rx"])}" {paint}{turn}/>'
            elif shape['kind'] == 'rect':
                out += f'<rect x="{shape["x"]}" y="{shape["y"]}" width="{shape["w"]}" height="{shape["h"]}" rx="{shape.get("r", 0)}" {paint}/>'
            else:
                out += f'<path d="{shape["d"]}" {paint}/>'
    return out, parts['head']['pivot'][1] - 62      # and how far down the middle of the head is


def icon(name, line):
    """One of the app's own line icons, in the pattern's line colour."""
    import re
    svg = open(os.path.join(ICONS, f'icon-{name}-plain.imageset', f'icon-{name}-plain.svg')).read()
    inner = svg[svg.index('>') + 1:svg.rindex('</svg>')]
    inner = inner.replace('stroke-width="1.4"', 'stroke-width="1.7"')
    return re.sub(r'#000000|#000\b', line, inner)


def grid(cell, corners, middles, cols=4, rows=2):
    """Evenly spaced: one thing at every corner of a square grid and one in the middle of every square."""
    marks = []
    for r in range(rows):
        for c in range(cols):
            marks.append(corners[(c + r * (cols // 2 + 1)) % len(corners)] + (c * cell, r * cell))
            marks.append(middles[(c + r * (cols // 2 + 1)) % len(middles)] + (c * cell + cell / 2, r * cell + cell / 2))
    return cell * cols, cell * rows, [(kind, x, y, size, 0, tone) for (kind, size, tone, x, y) in marks]


HEADS = [(f'face:{n}', 0.32, 'dd') for n in CAST]
ITEMS = [(f'icon:{n}', 1.9, 'dd') for n in THINGS]
PATTERNS.update({
    'faces': named(grid(104, HEADS[:5], HEADS[5:]), 'Nine of the cast\'s heads in one line, taken from the app\'s own drawings.', 'shell'),
    'things': named(grid(84, ITEMS[:4], ITEMS[4:]), 'The app\'s line icons: bottle, sleep, nappy, bath, solids, potty, play, a first.', 'sun'),
    'friends': named(grid(104, HEADS[:8], ITEMS), 'Heads and things in turn.', 'mint'),
    'lines': named(grid(84, [(f'line:{n}', 2.1, 'dd') for n in ('quatrefoil', 'pebble', 'square', 'blossom')],
                        [(f'line:{n}', 2.1, 'dd') for n in ('pill', 'hexagon', 'halfpill', 'scallop')]),
                   'The eight soft shapes as outlines.', 'sky'),
})


LAYERED = {'scales'}   # rows that overlap: drawn from the top down


def tile(name, field, dark=False):
    w, h, marks, _, _ = PATTERNS[name]
    tones = (DARK if dark else FIELDS)[field]
    out = f'<rect width="{w}" height="{h}" fill="{tones["f"]}"/>'
    drawn, made = [], {}
    for order, (shape, x, y, size, turn, tone) in enumerate(marks):
        colour = tones["dd" if tone == "x" else tone]
        kind, _, what = shape.rpartition(':')
        if kind == 'face':
            art, middle = made.setdefault(shape, head(what, colour, tones['f']))
            reach, at = 110 * size, f'scale({size}) translate(-120 {-middle})'
        elif kind == 'icon':
            art = made.setdefault(shape, icon(what, colour))
            reach, at = 14 * size, f'scale({size}) translate(-12 -12)'
        elif kind == 'line':
            art = f'<path d="{SHAPES[what]}" fill="none" stroke="{colour}" stroke-width="1.6" stroke-linejoin="round"/>'
            reach, at = 14 * size, f'scale({size}) translate(-12 -12)'
        else:
            art = f'<path d="{SHAPES[shape]}" fill="{colour}"/>'
            reach, at = 14 * size, f'rotate({turn}) scale({size}) translate(-12 -12)'
        # Again on every side, so a shape that crosses the edge comes back in on the other.
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                cx, cy = x + dx, y + dy
                if cx + reach < 0 or cx - reach > w or cy + reach < 0 or cy - reach > h: continue
                drawn.append((cy if name in LAYERED else order, f'<g transform="translate({cx:g} {cy:g}) {at}">{art}</g>'))
    out += ''.join(path for _, path in sorted(drawn, key=lambda item: item[0]))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{out}</svg>'


def css(name, field, scale=1.0, dark=False, drift=True):
    """The pattern as a CSS background, for mock-ups."""
    w, h = PATTERNS[name][0] * scale, PATTERNS[name][1] * scale
    # The repeat drifts slowly down and to the right, one whole tile at a time so it never jumps: about 6 points
    # a second. The page needs the DRIFT keyframes below.
    move = f"--tx:{w:g}px;--ty:{h:g}px;animation:drift {(w * w + h * h) ** 0.5 / 6:.1f}s linear infinite;" if drift else ''
    return (f"background-color:{(DARK if dark else FIELDS)[field]['f']};background-image:url('data:image/svg+xml,{urllib.parse.quote(tile(name, field, dark))}');"
            f"background-size:{w:g}px {h:g}px;{move}")


DRIFT = '@keyframes drift{to{background-position:var(--tx) var(--ty)}}@media (prefers-reduced-motion: reduce){*{animation:none!important}}'


def main():
    os.makedirs(os.path.join(OUT, 'tiles'), exist_ok=True)
    for name in PATTERNS:
        for field in FIELDS:
            with open(os.path.join(OUT, 'tiles', f'{name}-{field}.svg'), 'w') as out: out.write(tile(name, field))
            with open(os.path.join(OUT, 'tiles', f'{name}-{field}-dark.svg'), 'w') as out: out.write(tile(name, field, True))
    cells = ''
    for name, (w, h, marks, about, home) in PATTERNS.items():
        ways = ''.join(f'<div class="chip" style="{css(name, f, 0.5)}"></div>' for f in FIELDS)
        nights = ''.join(f'<div class="chip" style="{css(name, f, 0.5, True)}"></div>' for f in FIELDS)
        cells += (f'<div class="cell"><div class="swatch" style="{css(name, home)}"></div><div class="swatch" style="{css(name, home, 1, True)};height:150px;margin-top:10px"></div>'
                  f'<div class="ways">{ways}</div><div class="ways">{nights}</div><h3>{name.capitalize()}</h3><p>{about}</p><p class="q">Tile {w:g} by {h:g}.</p></div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle: repeat patterns</title><style>
body{{margin:0;background:#E4DCC8;color:#3A2A20;font:15px/1.4 -apple-system,BlinkMacSystemFont,system-ui,sans-serif;padding:34px;width:2060px}}
h1{{font-size:32px;margin:0 0 4px;letter-spacing:-.02em}}.lede{{color:#6B5E52;font-size:17px;margin:0 0 22px;max-width:120ch}}
.grid{{display:flex;flex-wrap:wrap;gap:22px 20px}}.cell{{width:326px}}
.swatch{{height:250px;border-radius:22px}}.small{{height:84px;border-radius:16px;margin-top:10px}}
.ways{{display:flex;gap:6px;margin-top:10px}}.chip{{flex:1;height:38px;border-radius:10px}}
h3{{margin:12px 0 4px;font-size:17px}}p{{margin:0 0 4px}}.q{{color:#6B5E52;font-size:13.5px}}
{DRIFT}</style></head><body><h1>Repeat patterns, light and dark</h1>
<p class="lede">Twelve repeats on one rule: evenly spaced, everything large and all one size, tone on tone. Eight are made from the brand's soft shapes. Four are outlines: the cast's heads, the app's line icons, both together, and the shapes in line. For each: light, then dark, then all six colours in both. Nothing is dark in light mode.</p>
<div class="grid">{cells}</div></body></html>'''
    with open(os.path.join(OUT, 'repeats.html'), 'w') as out: out.write(html)
    print(len(PATTERNS), 'patterns,', len(PATTERNS) * len(FIELDS), 'tiles')


if __name__ == '__main__':
    main()
