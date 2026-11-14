"""Puggle's activity icons, redrawn to one set of rules.

The rules (drawn from how SF Symbols, Fluent System Icons and Lucide are made; see docs/baby-tracker-spec.md):

  1. A 24 by 24 canvas. Nothing nearer the edge than 1 point, line included.
  2. One line: 1.5 points, centred on its path, round caps and round joins. Never two weights in one icon.
  3. Every point on the half-point grid. Corners 2 points round on big shapes, 1 to 1.5 on small ones.
  4. Keylines, so icons carry the same weight: a 20 circle, an 18 square, a 16 by 20 upright, a 20 by 16 landscape.
  5. Room to breathe: at least 1.5 points clear between two lines. If a detail does not fit, it goes.
  6. One accent: a single filled shape in Wattle (a matched pair counts as one). It marks what the icon is about.
     No second colour.
  7. Few parts: five strokes at most. Named for the object (bottle, not feeding).
  8. No faces. Faces belong to characters.

Run `python3 docs/tools/make_icons.py` from the repo. It writes docs/previews/icons/after/*.svg and the sheet
docs/previews/icons/refined.html. With `--install` it also writes the three files each icon has in the app's
asset catalogue (light, dark and plain).
"""
import math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'icons')
ASSETS = os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets')
INK, DARK, ACCENT = '#3A2A20', '#EBDDC4', '#F4BE2C'
W = 1.5


def rr(x, y, w, h, r):
    return (f'M{x + r} {y}H{x + w - r}A{r} {r} 0 0 1 {x + w} {y + r}V{y + h - r}A{r} {r} 0 0 1 {x + w - r} {y + h}'
            f'H{x + r}A{r} {r} 0 0 1 {x} {y + h - r}V{y + r}A{r} {r} 0 0 1 {x + r} {y}Z')


def circle(cx, cy, r):
    return f'M{cx - r} {cy}A{r} {r} 0 1 0 {cx + r} {cy}A{r} {r} 0 1 0 {cx - r} {cy}Z'


def star(cx, cy, outer, inner):
    pts = [(cx + (outer if i % 2 == 0 else inner) * math.cos(math.radians(-90 + i * 36)),
            cy + (outer if i % 2 == 0 else inner) * math.sin(math.radians(-90 + i * 36))) for i in range(10)]
    return 'M' + 'L'.join(f'{x:.2f} {y:.2f}' for x, y in pts) + 'Z'


# name: (accent fills, lines, a turn about the centre in degrees, a note on what changed)
ICONS = {
    'bottle': ([f'M7.5 15h9v4a3 3 0 0 1-3 3h-3a3 3 0 0 1-3-3z'],
               ['M10 6V4.5a2 2 0 0 1 4 0V6', rr(8.5, 6, 7, 2.5, 1), rr(7.5, 8.5, 9, 13.5, 3)], 0,
               'Straight body, no waist and no tick marks: they closed up when small.'),
    'breastfeed': ([circle(16, 12.5, 2.5)],
                   [circle(9, 6.5, 3), circle(16, 12.5, 2.5), 'M3 21c0-5 2.5-8.5 6-8.5', 'M7.5 17c3 3 8.5 3 11.5 0'], 0,
                   'Same idea, on the grid.'),
    'pump': (['M13 15h6v3.5a2.5 2.5 0 0 1-2.5 2.5h-1a2.5 2.5 0 0 1-2.5-2.5z'],
             ['M3 5.5l7 2.5v4l-7 2.5z', 'M10 10h3', rr(13, 6, 6, 15, 2.5)], 0,
             'The funnel is one plain shape; the bottle is bigger.'),
    'solids': (['M7.5 11a4.5 4.5 0 0 1 9 0z'],
               ['M7.5 11a4.5 4.5 0 0 1 9 0', 'M3 11h18a9 9 0 0 1-18 0z', 'M16.5 7.5l4-4'], 0,
               'A full half-circle bowl, to the keyline.'),
    'sleep': (['M17.5 3q.5 2.500 3 3q-2.500.5-3 3q-.5-2.500-3-3q2.500-.5 3-3z'],
              ['M20.5 14.5A8.5 8.5 0 1 1 9.5 3.5a7.5 7.5 0 0 0 11 11z'], 0,
              'A bigger moon. The sparkle is a filled shape, with no line of its own.'),
    'nappy': ([rr(5, 8.5, 3, 1.5, .75), rr(16, 8.5, 3, 1.5, .75)],
              ['M4.5 6.5h15a1.5 1.5 0 0 1 1.5 1.5v2.500c-3.500.5-5.500 2.500-6 5.500a3 3 0 0 1-6 0c-.5-3-2.500-5-6-5.500V8a1.500 1.500 0 0 1 1.500-1.500z'], 0,
              'The waistband line is gone; the tabs carry it.'),
    'potty': ([f'M10 13.5a3.5 1.5 0 1 0 7 0a3.5 1.5 0 1 0-7 0z'],
              [rr(3.5, 18, 17, 3, 1.5), 'M5.5 18c-.5-5 0-8 1-10a3 3 0 0 1 5.500-.5c.5 1.500 1.500 2.500 3 2.500h1.500a2.500 2.500 0 0 1 2.500 2.500V18',
               'M10 13.5a3.5 1.5 0 1 0 7 0a3.5 1.5 0 1 0-7 0z'], 0,
              'Fewer curves, on the grid.'),
    'bath': ([circle(9, 6, 2.5)],
             ['M3 11.5h18v2a5.500 5.500 0 0 1-5.500 5.500h-7A5.500 5.500 0 0 1 3 13.500z', 'M7 19.500l-1 2M17 19.500l1 2',
              circle(9, 6, 2.5), circle(15.5, 7, 1.5)], 0,
             'Two bubbles, not three, with room between.'),
    'growth': ([rr(4, 18.5, 7, 2.5, 1.25)],
               [rr(14.5, 3, 5, 18, 1.5), 'M14.5 7.500h2M14.5 12h2.500M14.5 16.500h2', rr(4, 18.5, 7, 2.5, 1.25), 'M7.5 18.500V5.500M4 9l3.500-3.500L11 9'], 0,
               'Three marks on the ruler, not four.'),
    'weight': ([rr(9.5, 17.75, 5, 1.5, .75)],
               ['M3.5 6.500h17c0 4.500-3.500 7-8.500 7s-8.500-2.500-8.500-7z', 'M12 13.500V16', rr(5, 16, 14, 5.5, 2)], 0,
               'Taller, to fill its space: it was the smallest of the set.'),
    'temperature': ([circle(12, 17.5, 2)],
                    ['M9.5 13.500V5a2.500 2.500 0 0 1 5 0v8.500a4.500 4.500 0 1 1-5 0z', 'M12 15.500V8'], 0,
                    'A wider tube, so the line inside has room.'),
    'medicine': (['M7 8h5v8H7a4 4 0 0 1 0-8z'],
                 [rr(3, 8, 18, 8, 4), 'M12 8v8'], -45,
                 'A capsule in place of the dropper bottle, which looked like the feeding bottle.'),
    'vaccine': ([rr(9, 12, 6, 5, 1.5)],
                [rr(9, 7, 6, 10, 1.5), 'M12 7V3M9.5 3h5', 'M12 17v4.500'], 45,
                'No marks on the barrel.'),
    'teeth': ([circle(16, 8, 1.25)],
              ['M7.5 3.500c1.500 0 2.500 1 4.500 1s3-1 4.500-1c2.500 0 4 2 4 4.500 0 3-1.500 4.500-2 7.500-.4 2.500-.8 5-2.300 5s-1.700-2.200-2.200-4c-.3-1.200-1-2-2-2s-1.700.8-2 2c-.5 1.800-.7 4-2.200 4s-1.900-2.500-2.300-5c-.5-3-2-4.500-2-7.500 0-2.500 1.500-4.500 4-4.500z'], 0,
              'The shine is a dot.'),
    'milestone': ([star(12, 12.8, 9.6, 4.7)], [star(12, 12.8, 9.6, 4.7)], 0,
                  'One star, filled; the star inside a star is gone.'),
    'tummy-time': ([circle(17.5, 9.5, 3)],
                   [rr(2.5, 13.5, 12, 5.5, 2.75), circle(17.5, 9.5, 3), 'M14 19h7.500'], 0,
                   'One colour. The blue ground line is gone.'),
    'play': ([rr(8.5, 3, 7, 7, 2)],
             [rr(8.5, 3, 7, 7, 2), rr(3, 13.5, 7.5, 7.5, 2), rr(13.5, 13.5, 7.5, 7.5, 2)], 0,
             'Clear gaps between the blocks.'),
    'walk': (['M4.5 10.500A6.500 6.500 0 0 1 11 4v6.500z'],
             ['M4.5 10.500A6.500 6.500 0 0 1 11 4v6.500z', 'M4.5 10.500h12.500c0 3.500-2.800 6-6.300 6s-6.200-2.500-6.200-6z', 'M17 10.500l2-5h2.500',
              circle(7.5, 20, 1.5), circle(14.5, 20, 1.5)], 0,
             'A plain hood, with no spokes.'),
    'note': (['M14 3l4.500 4.500H14z'],
             ['M7 3h7l4.500 4.500V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z', 'M14 3v4.500h4.500', 'M8.5 12.500h6.500M8.5 16.500h4'], 0,
             'Two lines of writing, not three.'),
    'photo': ([circle(12, 13.5, 3.5)],
              [rr(2.5, 7, 19, 13.5, 3), 'M8.5 7l1.500-2.500h4L15.500 7', circle(12, 13.5, 3.5)], 0,
              'No flash dot.'),
}


def svg(name, ink=INK, accent=ACCENT, plain=False, size=24):
    fills, lines, turn, _ = ICONS[name]
    inner = ''.join(f'<path d="{d}" fill="{"#000000" if plain else accent}"{" fill-opacity=" + chr(34) + "0.16" + chr(34) if plain else ""}/>' for d in fills)
    stroke = '#000000' if plain else ink
    inner += ''.join(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{W}" stroke-linecap="round" stroke-linejoin="round"/>' for d in lines)
    if turn: inner = f'<g transform="rotate({turn} 12 12)">{inner}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="{size}" height="{size}">{inner}</svg>'


def before(name):
    path = os.path.join(ASSETS, f'icon-{name}.imageset', f'icon-{name}.svg')
    text = open(path).read()
    return text[text.index('>') + 1:text.rindex('</svg>')]


def main():
    os.makedirs(os.path.join(OUT, 'after'), exist_ok=True)
    for name in ICONS:
        with open(os.path.join(OUT, 'after', f'icon-{name}.svg'), 'w') as out: out.write(svg(name))
    if '--install' in sys.argv:
        for name in ICONS:
            folder = os.path.join(ASSETS, f'icon-{name}.imageset')
            open(os.path.join(folder, f'icon-{name}.svg'), 'w').write(svg(name))
            open(os.path.join(folder, f'icon-{name}-dark.svg'), 'w').write(svg(name, ink=DARK))
            open(os.path.join(ASSETS, f'icon-{name}-plain.imageset', f'icon-{name}-plain.svg'), 'w').write(svg(name, plain=True))
        print('installed', len(ICONS), 'icons')
    grid = ''.join(f'<path d="M{i} 0V24M0 {i}H24" stroke="#C9583F" stroke-width="0.03" opacity=".45"/>' for i in range(25))
    keys = ('<rect x="1" y="1" width="22" height="22" fill="none" stroke="#2A62B8" stroke-width="0.06" stroke-dasharray=".3 .3"/>'
            '<circle cx="12" cy="12" r="10" fill="none" stroke="#2A62B8" stroke-width="0.06"/><rect x="3" y="3" width="18" height="18" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/>'
            '<rect x="4" y="2" width="16" height="20" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/><rect x="2" y="4" width="20" height="16" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/>')
    def inner(name): text = svg(name); return text[text.index('>') + 1:text.rindex('</svg>')]
    cells = ''
    for name, (_, _, _, note) in ICONS.items():
        was, now = before(name), inner(name)
        small = lambda art: ''.join(f'<svg viewBox="0 0 24 24" width="{s}" height="{s}">{art}</svg>' for s in (32, 24, 17))
        cells += (f'<div class="c"><div class="pair"><svg viewBox="0 0 24 24" width="92" height="92" class="old">{was}</svg>'
                  f'<svg viewBox="0 0 24 24" width="132" height="132" class="new">{grid}{keys}{now}</svg></div>'
                  f'<div class="r"><span class="lab">was</span>{small(was)}</div><div class="r"><span class="lab">now</span>{small(now)}</div>'
                  f'<b>{name.replace("-", " ").capitalize()}</b><p>{note}</p></div>')
    row = lambda art, bg, fg: ''.join(f'<span class="chip" style="background:{bg}">{art(n, fg)}</span>' for n in ICONS)
    strip = (f'<div class="strip">{row(lambda n, fg: svg(n, size=28), "#EAE2D2", INK)}</div>'
             f'<div class="strip" style="background:#14110F">{row(lambda n, fg: svg(n, ink=DARK, size=28), "#3B332D", DARK)}</div>'
             f'<div class="strip">{"".join(svg(n, size=17) for n in ICONS)}</div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle icons, refined</title><style>
body{{margin:0;padding:30px;background:#EFE7D4;font:13px/1.35 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1980px}}
h1{{margin:0 0 4px;font-size:28px;letter-spacing:-.02em}}.lede{{margin:0 0 18px;color:#6B5E52;font-size:16px;max-width:130ch}}
.g{{display:flex;flex-wrap:wrap;gap:20px 14px}}.c{{width:238px}}.pair{{display:flex;align-items:flex-end;gap:8px}}
.old{{background:#F8F2E4;border-radius:10px;opacity:.75}}.new{{background:#FBF6E9;border-radius:12px}}
.r{{display:flex;align-items:center;gap:10px;margin-top:6px}}.lab{{width:26px;color:#6B5E52;font-size:11px}}
b{{display:block;margin-top:6px;font-size:14px}}p{{margin:2px 0 0;color:#6B5E52}}
.strip{{display:flex;gap:8px;align-items:center;padding:12px;border-radius:14px;margin-top:12px;flex-wrap:wrap}}
.chip{{width:48px;height:48px;border-radius:14px;display:grid;place-items:center}}h2{{font-size:18px;margin:26px 0 4px}}
</style></head><body><h1>Puggle icons, refined</h1>
<p class="lede">All twenty redrawn to one set of rules. For each: the icon as it was, the new one on the grid with its keylines, then both at 32, 24 and 17 points.</p>
<div class="g">{cells}</div><h2>The set together: in light, in dark, and at 17 points</h2>{strip}</body></html>'''
    with open(os.path.join(OUT, 'refined.html'), 'w') as out: out.write(html)
    print(len(ICONS), 'icons')


if __name__ == '__main__':
    main()
