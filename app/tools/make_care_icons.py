"""Draws the toothbrush and scissors icons for Looking after, in the house style (Tom, 20 November 2026).

Each icon is drawn once here, on the 24-point grid the other activity icons use: ink lines 2 wide with round
ends, and one touch of the wattle yellow. It is written out in the six versions the app reads, like the hand-made
ones beside it:
  icon-NAME           ink and yellow, with a dark-mode copy in the light line colour
  icon-NAME-plain     one colour, the yellow as a faint fill (menus, templated)
  icon-NAME-fill      the yellow parts alone, and icon-NAME-line the lines alone, for tinting separately
  icon-NAME-reg-*     the same at large sizes, with slightly finer lines
Run from app/:  python3 tools/make_care_icons.py
"""
import json, math, os

INK, INK_DARK, WATTLE = '#3A2A20', '#EBDDC4', '#F4BE2C'
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, '..', 'Puggle', 'Resources', 'Assets.xcassets')


def turned(points, degrees, about=(12, 12)):
    a = math.radians(degrees)
    cx, cy = about
    return [(cx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a), cy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a))
            for x, y in points]


def path(commands, degrees=0):
    """Commands as (letter, points…), turned about the middle of the grid."""
    out = []
    for letter, *points in commands:
        if letter == 'Z':
            out.append('Z')
            continue
        moved = turned(points, degrees)
        out.append(letter + ' '.join(f'{x:.2f} {y:.2f}' for x, y in moved))
    return ''.join(out)


def circle(cx, cy, r):
    return f'M{cx - r:.2f} {cy:.2f}A{r} {r} 0 1 0 {cx + r:.2f} {cy:.2f}A{r} {r} 0 1 0 {cx - r:.2f} {cy:.2f}Z'


def fitted(commands, degrees, box=(2.2, 21.8)):
    """Turns a drawing and scales it to fill the grid, so a long thing laid on the diagonal uses all of it."""
    pts = [p for c in commands for p in c[1:]]
    moved = turned(pts, degrees)
    xs, ys = [x for x, _ in moved], [y for _, y in moved]
    k = (box[1] - box[0]) / max(max(xs) - min(xs), max(ys) - min(ys))
    ox = box[0] + ((box[1] - box[0]) - (max(xs) - min(xs)) * k) / 2 - min(xs) * k
    oy = box[0] + ((box[1] - box[0]) - (max(ys) - min(ys)) * k) / 2 - min(ys) * k
    return lambda shape: [(c[0], *[(ox + x * k, oy + y * k) for x, y in turned(c[1:], degrees)]) if len(c) > 1 else c for c in shape]


# The toothbrush, drawn lying flat with its head on the right, then laid on the diagonal: a long handle, a
# slimmer neck, a head with three tufts of bristles, and a curl of toothpaste above them in yellow.
BRUSH = [
    [('M', (5.2, 12.6)), ('L', (12.5, 13.1)), ('Q', (14.2, 13.2), (15.6, 11.8)), ('L', (24.4, 11.8)), ('Q', (26.6, 11.8), (26.6, 14)),
     ('L', (26.6, 16)), ('Q', (26.6, 18.2), (24.4, 18.2)), ('L', (15.6, 18.2)), ('Q', (14.2, 16.8), (12.5, 16.9)), ('L', (5.2, 17.4)),
     ('Q', (2.8, 17.4), (2.8, 15)), ('Q', (2.8, 12.6), (5.2, 12.6)), ('Z',)],
    [('M', (18.2, 11.8)), ('L', (18.2, 8.6)), ('M', (21.2, 11.8)), ('L', (21.2, 8.6)), ('M', (24.2, 11.8)), ('L', (24.2, 8.6))],
]
PASTE = [[('M', (17.6, 5)), ('Q', (19.2, 2.8), (21.2, 4.2)), ('Q', (23.2, 2.6), (25, 4.6)), ('Q', (26, 6), (24.6, 6.4)),
          ('L', (18.2, 6.4)), ('Q', (16.8, 6.2), (17.6, 5)), ('Z',)]]
place = fitted(BRUSH[0] + BRUSH[1] + PASTE[0], -35)
brush_lines = [path(place(shape)) for shape in BRUSH]
brush_yellow = [path(place(shape)) for shape in PASTE]

# Scissors of our own: two round finger loops on the left and gently curved blades crossing at a yellow pin,
# opening to the right. The pin is drawn over the blades, so it shows.
scissor_lines = [
    circle(5.4, 6.4, 2.8),
    circle(5.4, 17.6, 2.8),
    'M7.5 8.3Q10 10.6 12 12Q16.4 15 21.4 19.2',
    'M7.5 15.7Q10 13.4 12 12Q16.4 9 21.4 4.8',
]
scissor_yellow = [circle(12, 12, 1.7)]

# name: (lines, yellow, whether the yellow sits over the lines)
ICONS = {'toothbrush': (brush_lines, brush_yellow, False), 'scissors': (scissor_lines, scissor_yellow, True)}


def svg(lines, yellow, ink, width, accent, accent_opacity=None, show_lines=True, show_yellow=True, on_top=False):
    """The yellow is a flat touch with no outline, as on the tooth's sparkle."""
    opacity = f' fill-opacity="{accent_opacity}"' if accent_opacity else ''
    filled = [f'<path d="{d}" fill="{accent}"{opacity}/>' for d in yellow] if show_yellow else []
    stroked = [f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
               for d in lines] if show_lines else []
    parts = stroked + filled if on_top else filled + stroked
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">' + ''.join(parts) + '</svg>'


def imageset(name, light, dark=None):
    folder = os.path.join(ASSETS, f'{name}.imageset')
    os.makedirs(folder, exist_ok=True)
    images = [{'idiom': 'universal', 'filename': f'{name}.svg'}]
    open(os.path.join(folder, f'{name}.svg'), 'w').write(light)
    if dark:
        open(os.path.join(folder, f'{name}-dark.svg'), 'w').write(dark)
        images.append({'idiom': 'universal', 'filename': f'{name}-dark.svg',
                       'appearances': [{'appearance': 'luminosity', 'value': 'dark'}]})
    contents = {'images': images, 'info': {'author': 'xcode', 'version': 1},
                'properties': {'preserves-vector-representation': True}}
    json.dump(contents, open(os.path.join(folder, 'Contents.json'), 'w'), indent=2)


for name, (lines, yellow, on_top) in ICONS.items():
    base = f'icon-{name}'
    imageset(base, svg(lines, yellow, INK, 2, WATTLE, on_top=on_top), svg(lines, yellow, INK_DARK, 2, WATTLE, on_top=on_top))
    imageset(base + '-plain', svg(lines, yellow, '#000000', 2, '#000000', accent_opacity=0.16, on_top=on_top))
    imageset(base + '-fill', svg(lines, yellow, '#000000', 2, '#000000', show_lines=False))
    imageset(base + '-line', svg(lines, yellow, '#000000', 2, '#000000', show_yellow=False))
    imageset(base + '-reg-fill', svg(lines, yellow, '#000000', 1.65, '#000000', show_lines=False))
    imageset(base + '-reg-line', svg(lines, yellow, '#000000', 1.65, '#000000', show_yellow=False))
    print(base, 'written')
