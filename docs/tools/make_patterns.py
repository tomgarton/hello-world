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

FIELDS = {   # the field, then its tones
    'sun': {'f': '#F4E7B0', 'd': '#EDDB93', 'dd': '#E6CF78', 'l': '#FAF1CC'},
    'sky': {'f': '#BFD9F5', 'd': '#ABCBEE', 'dd': '#97BCE6', 'l': '#D5E6F9'},
    'shell': {'f': '#F3D9C9', 'd': '#ECC9B5', 'dd': '#E4B89F', 'l': '#F9E7DC'},
    'mint': {'f': '#CFE5D2', 'd': '#BBD9BF', 'dd': '#A6CCAB', 'l': '#E0EFE2'},
    'night': {'f': '#1B2440', 'd': '#27335B', 'dd': '#344377', 'l': '#4A5C95'},
    'sand': {'f': '#EFE7D4', 'd': '#E4D9C0', 'dd': '#D8CBAC', 'l': '#F8F2E4'},
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
    'comb': (156, 138, [('hexagon', c * 39, r * 46 + (23 if c % 2 else 0), 2.6, 0, tone)
                        for c, column in enumerate(['dld', 'ddl', 'ldd', 'dld']) for r, tone in enumerate(column)],
             'Soft hexagons packed like honeycomb, with a gap between, two tones.', 'mint'),
    'sparkle': named(lattice(84, ['quatrefoil'], ['quatrefoil'], 2.25, sizes=(2.25, 1.0)),
                     'Quatrefoils, large and small in turn. The brand\'s stars.', 'night'),
    # Each scallop is three bumps, 57.6 wide at this size. Rows 19 apart, every other row moved over by half a bump,
    # and each row drawn over the foot of the one above it.
    'scales': (57.6, 38, [('scallop', 0, 0, 3.2, 0, 'd'), ('scallop', 9.6, 19, 3.2, 0, 'l')],
               'Scallops in overlapping rows, like roof tiles or waves.', 'sky'),
    'check': (104, 104, [('square', 26, 26, 2.5, 0, 'd'), ('square', 78, 78, 2.5, 0, 'd'), ('square', 78, 26, 2.5, 0, 'l'), ('square', 26, 78, 2.5, 0, 'l')],
              'Soft squares in a check, two tones.', 'sand'),
}


LAYERED = {'scales'}   # rows that overlap: drawn from the top down


def tile(name, field):
    w, h, marks, _, _ = PATTERNS[name]
    tones = FIELDS[field]
    out = f'<rect width="{w}" height="{h}" fill="{tones["f"]}"/>'
    drawn = []
    for order, (shape, x, y, size, turn, tone) in enumerate(marks):
        # Again on every side, so a shape that crosses the edge comes back in on the other.
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                cx, cy = x + dx, y + dy
                reach = 14 * size
                if cx + reach < 0 or cx - reach > w or cy + reach < 0 or cy - reach > h: continue
                drawn.append((cy if name in LAYERED else order, f'<path transform="translate({cx:g} {cy:g}) rotate({turn}) scale({size}) '
                              f'translate(-12 -12)" d="{SHAPES[shape]}" fill="{tones["dd" if tone == "x" else tone]}"/>'))
    out += ''.join(path for _, path in sorted(drawn, key=lambda item: item[0]))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{out}</svg>'


def css(name, field, scale=1.0):
    """The pattern as a CSS background, for mock-ups."""
    w, h = PATTERNS[name][0], PATTERNS[name][1]
    return (f"background-color:{FIELDS[field]['f']};background-image:url('data:image/svg+xml,{urllib.parse.quote(tile(name, field))}');"
            f"background-size:{w * scale:g}px {h * scale:g}px")


def main():
    os.makedirs(os.path.join(OUT, 'tiles'), exist_ok=True)
    for name in PATTERNS:
        for field in FIELDS:
            with open(os.path.join(OUT, 'tiles', f'{name}-{field}.svg'), 'w') as out: out.write(tile(name, field))
    cells = ''
    for name, (w, h, marks, about, home) in PATTERNS.items():
        ways = ''.join(f'<div class="chip" style="{css(name, f, 0.5)}"></div>' for f in FIELDS)
        cells += (f'<div class="cell"><div class="swatch" style="{css(name, home)}"></div><div class="small" style="{css(name, home, 0.5)}"></div>'
                  f'<div class="ways">{ways}</div><h3>{name.capitalize()}</h3><p>{about}</p><p class="q">Tile {w} by {h}, {len(marks)} shapes.</p></div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle: repeat patterns</title><style>
body{{margin:0;background:#E4DCC8;color:#3A2A20;font:15px/1.4 -apple-system,BlinkMacSystemFont,system-ui,sans-serif;padding:34px;width:2060px}}
h1{{font-size:32px;margin:0 0 4px;letter-spacing:-.02em}}.lede{{color:#6B5E52;font-size:17px;margin:0 0 22px;max-width:120ch}}
.grid{{display:flex;flex-wrap:wrap;gap:22px}}.cell{{width:230px}}
.swatch{{height:230px;border-radius:22px}}.small{{height:84px;border-radius:16px;margin-top:10px}}
.ways{{display:flex;gap:6px;margin-top:10px}}.chip{{flex:1;height:38px;border-radius:10px}}
h3{{margin:12px 0 4px;font-size:17px}}p{{margin:0 0 4px}}.q{{color:#6B5E52;font-size:13.5px}}
</style></head><body><h1>Repeat patterns, second pass</h1>
<p class="lede">Eight repeats made from the brand's eight soft shapes, all on one rule: evenly spaced, the shapes large and all one size. Each is tone on tone: a soft field, with shapes a little darker or lighter. For each: at full size, at half size, and in all six colours.</p>
<div class="grid">{cells}</div></body></html>'''
    with open(os.path.join(OUT, 'repeats.html'), 'w') as out: out.write(html)
    print(len(PATTERNS), 'patterns,', len(PATTERNS) * len(FIELDS), 'tiles')


if __name__ == '__main__':
    main()
