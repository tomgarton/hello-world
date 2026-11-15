"""Puggle's activity icons, second pass (the first is kept in make_icons_v1.py and docs/previews/icons/v1).

What changed from the first pass, after Tom's notes and the ideas ChatGPT drew for him (14 November 2026):

  - A heavier line: 2 points, as Lucide draws and as those sheets specify. It holds at 17 points.
  - Fuller, rounder shapes that fill their keyline, drawn as the whole object and not a diagram of it.
  - Two fills, not one: Wattle for what the icon is about, and Sky for the part that holds or supports it.
    Still flat, still one line colour (Ink). Poo is the one icon with a colour of its own.
  - The nappy is a closed, padded shape with fastening tabs and leg openings inside it, so it is not a pair of pants.
  - Breastfeeding is a breast.
  - Two new ones, for the kinds of nappy: poo and wee.

The rules:

  1. A 24 by 24 canvas. Nothing nearer the edge than 1 point, line included.
  2. One line: 2 points, centred, round caps and joins.
  3. Points on the half-point grid where the shape allows.
  4. Keylines for even weight: a 20 circle, an 18 square, a 16 by 20 upright, a 20 by 16 landscape.
  5. At least 1 point clear between two lines, and 1.5 where it can be had. If a detail does not fit, it goes.
  6. Wattle and Sky fills only (poo aside). A small solid mark may be Ink.
  7. Few parts. Named for the object. No faces.

Run `python3 docs/tools/make_icons.py` from the repo: it writes docs/previews/icons/v2/*.svg and the sheet
docs/previews/icons/refined.html. With `--install` it also writes each icon's three files in the app's asset
catalogue (light, dark and plain); poo and wee are new and are not installed.
"""
import math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'icons')
ASSETS = os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets')
# The widget target has a small catalogue of its own: the one-colour drawings it shows, as `glyph-…`.
WIDGET_ASSETS = os.path.join(HERE, '..', '..', 'app', 'PuggleWidgets', 'Glyphs.xcassets')
WIDGET_GLYPHS = ['sleep', 'bottle', 'nappy']
INK, DARK, WATTLE, SKY = '#3A2A20', '#EBDDC4', '#F4BE2C', '#BFD9F5'
W = 2


def rr(x, y, w, h, r):
    return (f'M{x + r} {y}H{x + w - r}A{r} {r} 0 0 1 {x + w} {y + r}V{y + h - r}A{r} {r} 0 0 1 {x + w - r} {y + h}'
            f'H{x + r}A{r} {r} 0 0 1 {x} {y + h - r}V{y + r}A{r} {r} 0 0 1 {x + r} {y}Z')


def circle(cx, cy, r):
    return f'M{cx - r} {cy}A{r} {r} 0 1 0 {cx + r} {cy}A{r} {r} 0 1 0 {cx - r} {cy}Z'


def scale(d, k=2):
    """A path at k times the size. Arc flags and rotation are left alone."""
    counts = {'M': 2, 'L': 2, 'H': 1, 'V': 1, 'C': 6, 'S': 4, 'Q': 4, 'T': 2, 'A': 7, 'Z': 0}
    out, tokens, i = '', re.findall(r'[A-Za-z]|-?\d*\.?\d+', d), 0
    while i < len(tokens):
        cmd = tokens[i]; i += 1
        n = counts[cmd.upper()]
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


def sparkle(cx, cy, r):
    """A four-point sparkle, the brand's star."""
    k = r * 0.12
    return (f'M{cx} {cy - r}C{cx + k} {cy - r * .45} {cx + r * .45} {cy - k} {cx + r} {cy}'
            f'C{cx + r * .45} {cy + k} {cx + k} {cy + r * .45} {cx} {cy + r}'
            f'C{cx - k} {cy + r * .45} {cx - r * .45} {cy + k} {cx - r} {cy}'
            f'C{cx - r * .45} {cy - k} {cx - k} {cy - r * .45} {cx} {cy - r}Z')


def icon(lines, wattle=(), sky=(), ink=(), tint=(), turn=0, note='', fine=(), box=24, weight=W):
    return {'fine': list(fine), 'box': box, 'weight': weight, 'lines': list(lines), 'wattle': list(wattle), 'sky': list(sky), 'ink': list(ink), 'tint': list(tint), 'turn': turn, 'note': note}


TEAT = 'M9 8C9 6.5 10 6 10 4.5A2 2 0 0 1 14 4.5C14 6 15 6.5 15 8'
NAPPY = 'M6 4.5H18A4 4 0 0 1 22 8.5V12C22 17 18.5 20.5 14 20.5H10C5.5 20.5 2 17 2 12V8.5A4 4 0 0 1 6 4.5Z'
# The narrower body the tabs stick out from: its top, down to where the tabs begin, and the rest below them.
NAPPY_TOP = 'M2.87 7.3A3.5 3.5 0 0 1 6.3 4.5H17.7A3.5 3.5 0 0 1 21.13 7.3'
NAPPY_BOTTOM = 'M2.8 10.7V12C2.8 17 6 20.5 10.2 20.5H13.8C18 20.5 21.2 17 21.2 12V10.7'
# The teardrop of the second pass, with its left side flat where it meets the chest.
BREAST = 'M5.5 2.5C11 5 20.5 8.5 20.5 14A8 8 0 0 1 12.5 22C8.5 22 5.5 19.5 5.5 15.5Z'
POTTY = ('M12 4C9 4 7.5 6.5 7 10C5 10.8 3.6 12.5 3 14.5C2.3 17 2 18.5 2 19.5A2.5 2.5 0 0 0 4.5 22H19.5A2.5 2.5 0 0 0 22 19.5'
         'C22 18.5 21.7 17 21 14.5C20.4 12.5 19 10.8 17 10C16.5 6.5 15 4 12 4Z')
FRONT = 'M3 14.5C5 16.5 7 17.1 8.3 17.2C8.6 15.2 10 14 12 14C14 14 15.4 15.2 15.7 17.2C17 17.1 19 16.5 21 14.5'
# The large tummy-time body at half size: see make_icons_large.py.
TUMMY = ('M11.25 11C9 10.8 7.25 11.6 6.4 13.1C4.5 12.7 2.5 13.9 2.5 15.65C2.5 17.2 3.75 18.25 5.25 18.25H19.25'
         'C20.5 18.25 21.25 17.5 21.25 16.6C21.25 15.6 20.5 15 19.5 15C18.25 15 17.25 14.25 16.5 12.75')
FRINGE24 = 'M10.8 6.9C13.5 7.5 16.5 6.75 18 5.15'
# Three blocks with depth, on a 48 canvas: each shows its front, its top and its right side, and the top block
# sits across the two below. Lines hidden behind a nearer block are left out by hand.
BLOCKS48 = [rr(4, 26, 16, 16, 3), rr(20, 26, 16, 16, 3), rr(12, 8, 16, 16, 3),
            'M5 26.8L8.6 23.2C9.2 22.4 10 22 11 22H12', 'M20 26L22.5 24',
            'M29 22H38.5C40 22 41 23 41 24.5V35.5C41 36.5 40.6 37.3 40 37.9L35.2 41.2', 'M35.2 26.8L40.2 22.7',
            'M13 8.8L16.6 5.2C17.2 4.4 18 4 19 4H30.5C32 4 33 5 33 6.5V17.5C33 18.5 32.6 19.3 32 19.9L27.2 23.2', 'M27.2 8.8L32.2 4.7']
MOUND24 = 'M5 11C5 9 6.5 8 8 8.3C8.7 6.5 11 6 12.3 7.3C13.5 6.3 15.5 6.8 16 8.5C17.8 8.3 19 9.5 19 11'
SCALE24 = 'M7 11H17C18 11 18.7 11.6 19 12.5L20.8 18.5C21.2 20 20.2 21.5 18.5 21.5H5.5C3.8 21.5 2.8 20 3.2 18.5L5 12.5C5.3 11.6 6 11 7 11Z'
# A shallow inner curve (radius 9.5), so the crescent is thick through the middle.
MOON = 'M20.5 14.5A8.5 8.5 0 1 1 9.5 3.5A9.5 9.5 0 0 0 20.5 14.5Z'
TOOTH = ('M7 3C8.5 3 10 4 12 4C14 4 15.5 3 17 3C19.5 3 21 5 21 7.5C21 10 20 11.5 19.5 14L18.5 19C18.2 20.5 17.5 21.5 16.3 21.5'
         'C15 21.5 14.5 20.5 14.3 19L14 16.5C13.8 15.3 13.1 14.5 12 14.5C10.9 14.5 10.2 15.3 10 16.5L9.7 19C9.5 20.5 9 21.5 7.7 21.5'
         'C6.5 21.5 5.8 20.5 5.5 19L4.5 14C4 11.5 3 10 3 7.5C3 5 4.5 3 7 3Z')
POO = ('M12.5 2.5C13 4.5 11.5 5.5 10 6.5C8.5 7.5 8 8.5 8.5 10C6.5 10.5 5.5 11.8 5.5 13.5C5.5 14.3 5.8 15 6.2 15.5'
       'C4.5 16.3 3 17.5 3 19.3C3 21 4.5 22 6.5 22H17.5C19.5 22 21 21 21 19.3C21 17.5 19.5 16.3 17.8 15.5'
       'C18.3 15 18.5 14.3 18.5 13.5C18.5 11.8 17.3 10.5 15.5 10C16 8.5 15.2 7.5 14.5 6.8C13.5 5.8 12.8 4.5 12.5 2.5Z')
DROP = 'M12 2.5C15 6.5 18.5 10 18.5 14.5A6.5 6.5 0 0 1 5.5 14.5C5.5 10 9 6.5 12 2.5Z'
BIG_SPARKLE = sparkle(10.5, 13, 8.5)

ICONS = {
    'bottle': icon([TEAT, rr(7, 8, 10, 3.5, 1.75), 'M8 11.5C6.5 13 5.5 14.5 5.5 17V19A3 3 0 0 0 8.5 22H15.5A3 3 0 0 0 18.5 19V17C18.5 14.5 17.5 13 16 11.5', 'M9.5 15.5H12.5M9.5 18.5H12.5'],
                   wattle=[TEAT + 'Z'], sky=[rr(7, 8, 10, 3.5, 1.75)],
                   note='A teat, a collar and a body with shoulders. Two measure marks; three will not fit.'),
    'breastfeed': icon([BREAST], tint=[(BREAST, '#F3D9C9'), (circle(16, 15, 2.5), '#C27C66', True)],
                       note='A breast, in place of the two heads. In Shell, a brand colour: see the two versions below.'),
    'pump': icon(['M14 8.5L9.5 2.5C6 1.5 3 4.5 4.5 8L12 10.5', rr(12, 9.5, 6, 4, 1.5), rr(10, 13.5, 10, 8.5, 3), 'M16 9.5C16 6.5 18 5 19.7 5.8C21.5 6.7 21 9.5 22 12.5'],
                 sky=['M14 8.5L9.5 2.5C6 1.5 3 4.5 4.5 8L12 10.5Z'], wattle=['M10 17.5H20V19A3 3 0 0 1 17 22H13A3 3 0 0 1 10 19Z'],
                 note='A cupped funnel, a lever and a bottle.'),
    'solids': icon(['M2.5 11H21.5C21.5 15.5 18 19 13.5 19H10.5C6 19 2.5 15.5 2.5 11Z', MOUND24, 'M15.5 8L20 3', 'M9 21.5H15'],
                   wattle=[MOUND24 + 'Z'], note='A bowl on a foot, a mound of food and a spoon.'),
    'sleep': icon([MOON], wattle=[MOON], ink=[sparkle(18.5, 5, 3)], note='A filled moon, thick through the middle.'),
    # The tabs are flat and wide and sit right above the leg openings, so each side reads as one band of the
    # garment and the four patches are not two eyes and a mouth. The leg openings are big, which narrows the crotch.
    # The body is drawn in two pieces, top and bottom, leaving a gap at each side where a tab crosses it, so a
    # tab reads as lying over the front. The tabs stick out past the sides (Tom, 15 November 2026, after
    # looking at how others draw a nappy: the tab past the edge is what says "fastened"). They overhang by a
    # little over one unit; two and a half was too much (Tom, the same day).
    'nappy': icon([NAPPY_TOP, NAPPY_BOTTOM, rr(1.6, 7.3, 5, 3.4, 1.7), rr(17.4, 7.3, 5, 3.4, 1.7), 'M13.8 20.5C13.8 16 17.6 12 21.2 12', 'M10.2 20.5C10.2 16 6.4 12 2.8 12'],
                  sky=[rr(1.6, 7.3, 5, 3.4, 1.7), rr(17.4, 7.3, 5, 3.4, 1.7)],
                  note='One closed, padded shape. The tabs and the leg openings sit inside it, which is what says nappy and not pants.'),
    # The front of the seat swells up in the middle: the splash guard. It stands in front of the opening.
    'potty': icon([POTTY, FRONT],
                  # The colour is the opening alone (Tom, 15 November 2026: the whole base in yellow was too much).
                  wattle=['M8.2 11.8A3.8 1.6 0 1 0 15.8 11.8A3.8 1.6 0 1 0 8.2 11.8Z'],
                  note='A small backrest, a wide seat with its opening in colour, a raised front and a base.'),
    'bath': icon(['M2.5 11H21.5V13.5A6 6 0 0 1 15.5 19.5H8.5A6 6 0 0 1 2.5 13.5Z', 'M6.5 19.5L5.5 22M17.5 19.5L18.5 22', circle(16, 7, 3), circle(7.5, 5.5, 2.3)],
                 wattle=[circle(16, 7, 3)], note='A tub, a bubble and a duck looking over the rim.'),
    'growth': icon([rr(7.5, 2, 9, 20, 2.5), 'M7.5 6.5H10.5M7.5 10.5H12M7.5 14.5H10.5M7.5 18.5H12'], wattle=[rr(7.5, 2, 9, 20, 2.5)],
                   note='A height chart by itself. The arrow is gone.'),
    'weight': icon([rr(3, 3.5, 18, 4.5, 2.25), 'M12 8V11', SCALE24, 'M8 19A4 4 0 0 1 16 19Z'],
                   wattle=['M8 19A4 4 0 0 1 16 19Z'], note='A baby scale: a tray, a base and a dial.'),
    'temperature': icon(['M9 13V5A3 3 0 0 1 15 5V13A5 5 0 1 1 9 13Z'], wattle=[circle(12, 17, 2.5), rr(11, 7.5, 2, 9, 1)],
                        note='The reading is a filled column, not a second line.'),
    'medicine': icon([rr(2.5, 8, 19, 8, 4), 'M12 8V16'], wattle=['M6.5 8H12V16H6.5A4 4 0 0 1 6.5 8Z'], turn=-45, note='A capsule.'),
    'vaccine': icon([rr(9, 7.5, 6, 9.5, 1.5), 'M12 7.5V3.5M9.5 3.5H14.5', 'M12 17V21.5'], wattle=[rr(9, 11.5, 6, 5.5, 1.5)], turn=45, note='A syringe, with nothing on the barrel.'),
    # A sparkle, not a dot: a yellow dot on a tooth reads as a cavity.
    'teeth': icon([TOOTH], wattle=[sparkle(16, 8.5, 2.6)], note='Wider roots, so they do not close up. A sparkle for a new tooth.'),
    'milestone': icon([BIG_SPARKLE], wattle=[BIG_SPARKLE], ink=[sparkle(19, 5.5, 3)],
                      note='Sparkles, not a five-point star: the brand\'s own star is the four-point one.'),
    # Only the hair is filled: a whole yellow head read as a ball.
    'tummy-time': icon([circle(15, 8.5, 4.5), FRINGE24, TUMMY], wattle=[FRINGE24 + 'A4.5 4.5 0 0 0 10.8 6.9Z'], ink=[circle(16.8, 8.6, .9)], note='A baby on its front, head up, with its back and bottom behind.'),
    'play': icon([rr(7.5, 3, 9, 9, 2.5), rr(3, 12, 9, 9, 2.5), rr(12, 12, 9, 9, 2.5)], wattle=[rr(7.5, 3, 9, 9, 2.5)], note='Three blocks, stacked.'),
    'walk': icon(['M3.5 10.5A6.5 6.5 0 0 1 10 4V10.5Z', 'M3.5 10.5H16.5C16.5 13.5 13.6 15.5 10 15.5C6.4 15.5 3.5 13.5 3.5 10.5Z', 'M16.5 10.5L18.5 5H21.5', circle(6.5, 20, 1.5), circle(13.5, 20, 1.5)],
                 wattle=['M3.5 10.5A6.5 6.5 0 0 1 10 4V10.5Z'], sky=['M3.5 10.5H16.5C16.5 13.5 13.6 15.5 10 15.5C6.4 15.5 3.5 13.5 3.5 10.5Z'], note='A pram with a hood.'),
    'note': icon(['M7 3H14L18.5 7.5V19A2 2 0 0 1 16.5 21H7A2 2 0 0 1 5 19V5A2 2 0 0 1 7 3Z', 'M14 3V7.5H18.5', 'M8.5 12.5H15M8.5 16.5H12.5'], wattle=['M14 3L18.5 7.5H14Z'], note='As before, heavier.'),
    'photo': icon([rr(2, 6.5, 20, 14.5, 3.5), 'M8 6.5L9.5 3.5H14.5L16 6.5', circle(12, 13.5, 3.5)], wattle=[circle(12, 13.5, 3.5)], note='As before, heavier.'),
    # New, for the kinds of nappy. Not in the app.
    'poo': icon([POO, 'M8.5 10H12M6.2 15.5H11'], tint=[(POO, '#C99668')], note='New. The one icon with a colour of its own.'),
    'wee': icon([DROP], tint=[(DROP, WATTLE)], note='New. A drop, always yellow.'),
}
NEW = ['poo', 'wee']

# One fill each (14 November 2026). Tom: yellow by default, a colour of your choosing or each child's colour in
# Settings, and the fixed colours stay (the breast, poo, wee). So an icon has one accent, which the app tints,
# and the Sky fills go. Three icons had no Wattle at all: their Sky part becomes the accent.
for _name, _spec in ICONS.items():
    if _name == 'nappy': _spec['wattle'] += _spec['sky'][:2]      # the fastening tabs
    _spec['sky'] = []


def svg(name, ink=INK, plain=False, size=24, spec=None, layer=None):
    """`layer` draws one part alone, in black, for the app to tint: 'line', 'fill' (the accent) or 'fixed' (in its own colours)."""
    spec = spec or ICONS[name]
    if layer: return layered(spec, layer, size, dark=ink == DARK)
    def fill(d, colour, solid=False):
        if plain: return f'<path d="{d}" fill="#000000"{"" if solid else " fill-opacity=" + chr(34) + "0.16" + chr(34)}/>'
        return f'<path d="{d}" fill="{colour}"/>'
    inner = ''.join(fill(d, SKY) for d in spec['sky']) + ''.join(fill(d, WATTLE) for d in spec['wattle'])
    # A tint marked strong lies on another (the areola on the breast): in one colour it is a stronger tint, so it still shows.
    inner += ''.join(fill(t[0], t[1]).replace('0.16', '0.4' if len(t) > 2 else '0.16') for t in spec['tint'])
    stroke = '#000000' if plain else ink
    inner += ''.join(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{spec.get("weight", W)}" stroke-linecap="round" stroke-linejoin="round"/>' for d in spec['lines'])
    # Fine lines (1.5 points) are for a closed eye inside a small head, and nothing else.
    inner += ''.join(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{spec.get("fineweight", 1.2)}" stroke-linecap="round" stroke-linejoin="round"/>' for d in spec.get('fine', []))
    inner += ''.join(fill(d, ink, solid=True) for d in spec['ink'])
    if spec['turn']: inner = f'<g transform="rotate({spec["turn"]} 12 12)">{inner}</g>'
    box = spec.get('box', 24)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {box} {box}" width="{size}" height="{size}">{inner}</svg>'


# In dark the line is pale on a dark ground, and a pale line looks heavier than a dark one of the same width.
# So the dark drawing has a thinner line. A fixed colour is dimmed a little too, so the pale line still shows
# against it (the breast's skin was nearly the line's own colour).
# 0.62 since 15 November 2026 (it was 0.8): Tom found the icons hard to read in dark, and chose the thinner line
# with a deep mustard in place of Wattle (`Palette.iconYellow` in the app). See docs/previews/icons/dark-options.png.
DARK_LINE, DARK_FIXED = 0.62, 0.8


def dimmed(colour, k):
    return '#' + ''.join(f'{round(int(colour[i:i + 2], 16) * k):02X}' for i in (1, 3, 5))


def layered(spec, layer, size, dark=False):
    path = lambda d, more: f'<path d="{d}" {more}/>'
    thin = DARK_LINE if dark else 1
    if layer == 'fill': inner = ''.join(path(d, 'fill="#000000"') for d in spec['wattle'])
    elif layer == 'fixed': inner = ''.join(path(t[0], f'fill="{dimmed(t[1], DARK_FIXED) if dark else t[1]}"') for t in spec['tint'])
    else:
        stroke = 'fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width='
        inner = ''.join(path(d, f'{stroke}"{round(spec.get("weight", W) * thin, 2)}"') for d in spec['lines'])
        inner += ''.join(path(d, f'{stroke}"{round(spec.get("fineweight", 1.2) * thin, 2)}"') for d in spec.get('fine', []))
        inner += ''.join(path(d, 'fill="#000000"') for d in spec['ink'])
    if not inner: return ''
    box = spec.get('box', 24)
    if spec['turn']: inner = f'<g transform="rotate({spec["turn"]} {box / 2} {box / 2})">{inner}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {box} {box}" width="{size}" height="{size}">{inner}</svg>'


def imageset(name, text, template, dark=None, catalogue=None):
    """One vector image in the app's catalogue, with a second drawing for dark if one is given."""
    import json
    folder = os.path.join(catalogue or ASSETS, f'{name}.imageset')
    os.makedirs(folder, exist_ok=True)
    open(os.path.join(folder, f'{name}.svg'), 'w').write(text)
    props = {'preserves-vector-representation': True}
    if template: props['template-rendering-intent'] = 'template'
    images = [{'idiom': 'universal', 'filename': f'{name}.svg'}]
    if dark:
        open(os.path.join(folder, f'{name}-dark.svg'), 'w').write(dark)
        images.append({'idiom': 'universal', 'filename': f'{name}-dark.svg', 'appearances': [{'appearance': 'luminosity', 'value': 'dark'}]})
    json.dump({'images': images, 'info': {'author': 'xcode', 'version': 1}, 'properties': props},
              open(os.path.join(folder, 'Contents.json'), 'w'), indent=2)


def inner_of(text):
    return text[text.index('>') + 1:text.rindex('</svg>')]


def from_file(path):
    return inner_of(open(path).read()) if os.path.exists(path) else ''


# The breast again with no skin colour, to compare. Shell is a brand colour, and one skin tone.
PLAIN_BREAST = icon([BREAST], wattle=[circle(16, 15, 2.5)], ink=[circle(16, 15, 1)])


# Other ways to draw breastfeeding (14 November 2026). The app is meant for families anywhere, and a bare breast
# is not welcome on every phone, nor is one skin tone everyone's. So the icon becomes a choice. Nothing here is
# in the app yet.
TONES = [('#F3D9C9', '#C27C66'), ('#E9C4A2', '#B0704F'), ('#CF9B6E', '#8E5637'), ('#A06D49', '#6B3F28'), ('#74492F', '#4A2A1B')]


def breast(tone, areola):
    return icon([BREAST32], box=32, weight=2.2, tint=[(BREAST32, tone), (circle(21.5, 20, 3.3), areola, True)])


# The four with a baby in them are drawn on a 32 canvas, not 24. That is the room a closed eye, an ear, hair and
# a blanket need: on 24 the line fills them in. Fluent does the same, with more detail in its larger sizes.
# The line is 2.2 there, a little heavier than the first try, so a row of tiles looks more even. Each also has a small
# drawing for lists: the same shapes with no eye, ear or fold, and a line as heavy as the rest of the set.
BIG, SMALL = 2.2, 2.67


def head(cx, cy, r, toward):
    """A head. `toward` is where it faces, and only the eye shows it: a nose on the outline was tried, and at this
    weight it read as a beak on the baby and a jaw on the parent."""
    return circle(cx, cy, r)


def eye(x, y, w=1.3):
    # A half circle, a little wider than asked: any shorter and the round ends make it a bean.
    w *= 1.25
    return f'M{x - w} {y}A{w} {w} 0 0 0 {x + w} {y}'


def ear(x, y, side=1):
    return f'M{x} {y - .8}q{1.3 * side} .8 0 1.6'


SIDE = 'M5 3.5C10 5.5 16.5 10 17.5 15.5C18.3 21.5 15.5 28.5 10.5 28.5H7A2 2 0 0 1 5 26.5Z'
WRAP = 'M27 17.5C27.5 24 24 28.5 19.5 28.5C17 28.5 14.8 28 13.3 27.3'


def nursing(tone, areola):
    # The baby faces the breast, and its nose and mouth press into it: that is the latch.
    bub = head(22, 15.8, 5, 180)
    return icon([SIDE, bub, WRAP], fine=[eye(20.6, 15.2), 'M18.5 24.6C20.5 25 22.5 24.2 24 22.6'], box=32, weight=BIG,
                sky=[WRAP + 'C15.5 25 17 21.5 17.5 18.5L18 18.3A5 5 0 0 0 27 17.5Z'],
                tint=[(SIDE, tone), (circle(15.3, 15.8, 2.8), areola, True), (bub, tone)])


MUM, BUB = head(12.5, 9.5, 6, 40), head(21.5, 21, 5, 205)
TORSO = 'M8 13.5C5.2 15.5 3.5 19 3.5 23V25.5A3 3 0 0 0 6.5 28.5H21C24.5 28.5 27 26.5 26.3 22.4'
FRINGE = 'M6.7 11C11 11 15 9 17 5.5'
BUN = 'M9.1 4.6A2.4 2.4 0 1 0 6.8 7.7'
ARM = 'M8.5 20.5C10 24 14.5 26.5 20 26.2C22.5 26 24.8 25.2 26.2 23.8'
BREAST32 = 'M7.5 3.5C15 7 27.5 11.5 27.5 18.5A10.5 10.5 0 0 1 17 29.5C11.5 29.5 7.5 26 7.5 20.5Z'
LAP = 'M4.58 17.3C8.5 16 12.5 22 18.5 22C22 22 24.5 18 27.42 17.3'
DROP32 = 'M16 2.5C21.5 9 26.5 14 26.5 19.5A10.5 10.5 0 0 1 5.5 19.5C5.5 14 10.5 9 16 2.5Z'
HEART32 = 'M16 28C9.5 23.5 3 18.5 3 11.5A6.5 6.5 0 0 1 16 9A6.5 6.5 0 0 1 29 11.5C29 18.5 22.5 23.5 16 28Z'
# A swaddled body: it leaves the head and tapers away to a rounded end.
POD_DROP = 'M21.6 19.6C21.8 23.5 17.5 26.5 13.2 25.8C10.5 25.3 9.6 22.8 11 21C12 19.7 13.5 18.3 14.6 16.3'
POD_HEART = 'M22.6 17.6C22.7 20.8 19 23.2 15.4 22.6C13.1 22.2 12.3 20.1 13.5 18.5C14.3 17.4 14.9 16 15.6 14.3'

# One colour rule for all five: skin where there is a breast, and otherwise the baby's head is Wattle.
ALTERNATES = {
    'breast': (breast(*TONES[0]), 'Breast', 'The plainest, and the one most likely to be unwelcome somewhere. Now on the same canvas as the others.'),
    'nursing': (nursing(*TONES[0]), 'Breast and baby', 'The baby is tucked against the breast, eye closed, wrapped in a blanket. A little of the areola shows.'),
    'held': (icon([MUM, BUN, BUB, TORSO, FRINGE, 'M14 15.3C15.5 16.5 17.5 16.8 19 16.7', 'M17.2 23.6C16 23.9 15 24.4 14.1 25.1', ARM],
                  fine=[eye(14.4, 10.8), eye(20.6, 20.2, 1.2)], box=32, weight=BIG,
                  sky=['M8 13.5C5.2 15.5 3.5 19 3.5 23V25.5A3 3 0 0 0 6.5 28.5H21C24.5 28.5 27 26.5 26.3 22.4L26.2 23.8C24.8 25.2 22.5 26 20 26.2'
                       'C18 26.4 16 26.2 14.1 25.1C15 24.4 16 23.9 17.2 23.6A5 5 0 0 1 19 16.7C17.5 16.8 15.5 16.5 14 15.3A6 6 0 0 1 8 13.5Z'],
                  wattle=[FRINGE + 'A6 6 0 0 0 6.7 11Z', BUN + 'A6 6 0 0 1 9.1 4.6Z', BUB]),
             'Parent and baby', 'The parent has an arm around the baby. No breast and no skin colour.'),
    'drop': (icon([DROP32, head(18.5, 17, 4, 195), POD_DROP], fine=[eye(17.6, 16.6, 1.1), 'M13.5 23C15.3 23.3 17.3 22.5 18.4 21.2'], box=32, weight=BIG,
                  sky=[POD_DROP + 'A4 4 0 0 0 21.6 19.6Z'], wattle=[head(18.5, 17, 4, 195)]),
             'Milk drop', 'A swaddled, sleeping baby inside a drop of milk. No breast and no skin colour.'),
    'heart': (icon([HEART32, circle(19, 14.5, 3.8), LAP], fine=[eye(18.2, 14.3, 1.1)], box=32, weight=BIG,
                   sky=[LAP + 'C25.1 21.46 20.55 24.85 16 28C11.45 24.85 6.9 21.46 4.58 17.3Z'], wattle=[circle(19, 14.5, 3.8)]),
              'Heart', 'Reworked: a sleeping baby resting in a cupped hand, inside a heart.'),
}


# After the International Breastfeeding Symbol (Matt Daigle, 2006, given to the public domain by its maker): a
# round head above a body whose arms wrap a baby, the baby's head a circle at the chest. Tom asked for it as
# another choice, drawn to sit with the rest of the set (15 November 2026). The symbol is one solid shape with
# the baby cut out of it; here it is the set's line with one colour. Three drawings, on the same canvas and
# at the same weight as the other choices:
#   line    a closed body, and one line for the forearm: from the crook of the arm, under the baby's head, down
#           to the bottom edge where the hand ends. The baby's head is in colour, as in the other choices.
#   colour  the same drawing with the parent in colour and the baby's head left clear, which is nearest the
#           symbol itself: one figure, the baby cut out of it.
#   stroke  the body as one stroke that goes up one arm, across the shoulders and down the other, open where
#           the hands pass each other.
# The baby's head sits at the chest and to one side, clear of the shoulders, and rests on the forearm. A circle
# in the middle of a closed body would read as a baby inside it.
SYMBOL_HEAD = circle(15.6, 7.3, 4.3)
SYMBOL_BODY = ('M13 14.9H18.6C22.2 14.9 25 18.4 25 21.6C25 25.4 21.8 28.2 17.6 28.2H14.2C10 28.2 7.2 26 7.2 22.4'
               'C7.2 19.2 9.6 14.9 13 14.9Z')
SYMBOL_BUB = circle(18.4, 20.8, 2.8)
SYMBOL_ARM = 'M10.4 23.2C12.4 24.9 15 25.5 17.6 25.5C18.7 25.5 19 26.4 18.7 27.3'
SYMBOL_HUG = ('M16.6 28.2C13.2 28.6 7.2 27.6 7.2 22.4C7.2 19.2 9.6 14.9 13 14.9H18.6C22.4 14.9 25 18.4 25 21.4'
              'C25 24.4 23.4 26.8 20.8 26.6')
SYMBOL_HUG_BUB = circle(18.7, 20.6, 2.8)
# Each: the drawing for tiles, the simpler one for lists (no forearm line, which closes up at that weight), a
# name and a note.
SYMBOL_DISC = circle(18.5, 20.5, 3.1)   # the baby's head with no outline: an outlined one with colour inside reads as an eye
SYMBOL = {
    'symbol': (icon([SYMBOL_HEAD, SYMBOL_BODY, SYMBOL_ARM], box=32, weight=BIG, wattle=[SYMBOL_DISC]),
               icon([SYMBOL_HEAD, SYMBOL_BODY], box=32, weight=SMALL, wattle=[SYMBOL_DISC]),
               'Symbol, in line', 'A closed body with the forearm under the baby. The baby\u2019s head is the one spot of colour, with no outline. No breast and no skin colour.'),
    'symbol-colour': (icon([SYMBOL_HEAD, SYMBOL_BODY, SYMBOL_ARM], box=32, weight=BIG, wattle=[SYMBOL_HEAD, SYMBOL_BODY + SYMBOL_DISC]),
                      icon([SYMBOL_HEAD, SYMBOL_BODY], box=32, weight=SMALL, wattle=[SYMBOL_HEAD, SYMBOL_BODY + SYMBOL_DISC]),
                      'Symbol, in colour', 'The same drawing with the parent in colour and the baby\u2019s head cut out. Nearest the symbol itself, which is one figure with the baby cut out.'),
    'symbol-ring': (icon([SYMBOL_HEAD, SYMBOL_BODY, SYMBOL_BUB, SYMBOL_ARM], box=32, weight=BIG, wattle=[SYMBOL_BUB]),
                    icon([SYMBOL_HEAD, SYMBOL_BODY, SYMBOL_BUB], box=32, weight=SMALL, wattle=[SYMBOL_BUB]),
                    'Symbol, baby outlined', 'The baby\u2019s head drawn as the parent\u2019s is, with colour inside. Small, it can read as an eye.'),
    'symbol-stroke': (icon([SYMBOL_HEAD, SYMBOL_HUG, SYMBOL_HUG_BUB], fine=['M14.4 23.9C13.2 24.4 12 24.5 10.9 24.1'], box=32, weight=BIG, wattle=[SYMBOL_HUG_BUB]),
                      icon([SYMBOL_HEAD, SYMBOL_HUG, SYMBOL_HUG_BUB], box=32, weight=SMALL, wattle=[SYMBOL_HUG_BUB]),
                      'Symbol, one stroke', 'The body is one stroke: up one arm, across the shoulders and down the other, open where the hands pass.'),
}


# Parent and baby without the blue (15 November 2026, Tom's ask): colour is for hair alone, as on tummy time.
HELD_LINES = [MUM, BUN, BUB, TORSO, FRINGE, 'M14 15.3C15.5 16.5 17.5 16.8 19 16.7', 'M17.2 23.6C16 23.9 15 24.4 14.1 25.1', ARM]
HELD_EYES = [eye(14.4, 10.8), eye(20.6, 20.2, 1.2)]
MUM_HAIR = [FRINGE + 'A6 6 0 0 0 6.7 11Z', BUN + 'A6 6 0 0 1 9.1 4.6Z']
BUB_HAIR = 'M17 18.8C19.4 18.6 22.6 18 24.6 17.1A5 5 0 0 0 17 18.8Z'
ALTERNATES['held-hair'] = (icon(HELD_LINES, fine=HELD_EYES, box=32, weight=BIG, wattle=MUM_HAIR),
                           'Parent and baby, hair in colour', 'No blue. The only colour is the parent\u2019s hair.')
ALTERNATES['held-hair-both'] = (icon(HELD_LINES, fine=HELD_EYES, box=32, weight=BIG, wattle=MUM_HAIR + [BUB_HAIR]),
                                'Parent and baby, both with hair', 'No blue. The parent\u2019s hair and a little on the baby, as tummy time has.')

# The one Tom chose, with its lines cleaned up (15 November 2026). Before: the parent's eye ran into the fringe
# and the head's edge; a neck line, a wrap line, the arm, the baby's head and the body's base all met in one
# knot under the baby. Now the fringe sits higher and the eye lower and smaller, so the eye touches nothing;
# the baby is tucked under the chin; the body is one line that comes round and up the baby's far side; and the
# near forearm stops short of everything.
NURSE_MUM = circle(12.5, 9.5, 6)
NURSE_FRINGE = 'M6.5 9.6C10.4 9.6 14.5 8 16.2 4.8'
NURSE_BUB = circle(19.4, 18.2, 4.8)
NURSE_BODY = 'M7.6 14.4C5 16.4 3.6 19.4 3.6 23C3.6 26.8 6.6 29.4 10.6 29.4H19C23.6 29.4 26.4 26.4 26.7 20.4'
NURSE_ARM = 'M9 20.6C10.4 23.2 13 24.8 16.2 25'
ALTERNATES['held-refined'] = (icon([NURSE_MUM, BUN, NURSE_BUB, NURSE_BODY, NURSE_FRINGE, NURSE_ARM],
                                   fine=[eye(14.2, 11.5, 1.0), eye(19.2, 18.4, 1.2)], box=32, weight=BIG,
                                   wattle=[NURSE_FRINGE + 'A6 6 0 0 0 6.5 9.6Z', BUN + 'A6 6 0 0 1 9.1 4.6Z']),
                              'Parent and baby, refined', 'The chosen drawing with its lines cleaned up: no eye touches an edge, and no lines pile up under the baby.')

# The symbol with the baby's head drawn as tummy time draws it (15 November 2026, Tom's ask): an outlined head,
# hair in colour and a dot for an eye. Tummy time's head is 4.5 on a 24 canvas; to keep that share of the line
# here it would be 6 across a 32 canvas, larger than the body can hold. So the head is 4.2, the body is wider
# to hold it, the fringe has no line of its own, and the forearm stops at the baby.
BABE_HEAD = circle(15.6, 6.4, 4.1)
BABE_BODY = ('M13 14H18.4C23.2 14 27.6 18 27.6 22C27.6 26.2 24.4 29.2 20 29.2H13.4C9 29.2 6 26.4 6 22.6'
             'C6 18.6 9 14 13 14Z')
BABE_BUB = circle(20, 22, 4.2)
BABE_HAIR = 'M23.92 20.51C21.4 21.07 18.6 20.37 17.2 18.87A4.2 4.2 0 0 1 23.92 20.51Z'
BABE_EYE = circle(18.32, 22.09, 0.75)
BABE_ARM = 'M9.4 22.4C10.4 24.8 12.2 25.9 14.2 25.7'
SYMBOL['symbol-hair'] = (icon([BABE_HEAD, BABE_BODY, BABE_BUB, BABE_ARM], box=32, weight=BIG, wattle=[BABE_HAIR]),
                         icon([BABE_HEAD, BABE_BODY, BABE_BUB], box=32, weight=SMALL, wattle=[BABE_HAIR]),
                         'Symbol, baby with hair', 'The baby\u2019s head as tummy time draws it, without the eye: an outlined head with hair in colour.')
SYMBOL['symbol-face'] = (icon([BABE_HEAD, BABE_BODY, BABE_BUB, BABE_ARM], box=32, weight=BIG, wattle=[BABE_HAIR], ink=[BABE_EYE]),
                         icon([BABE_HEAD, BABE_BODY, BABE_BUB], box=32, weight=SMALL, wattle=[BABE_HAIR]),
                         'Symbol, baby with hair and eye', 'The same with tummy time\u2019s dot for an eye. Inside the body, a ring with a dot can read as an eye or a lens.')

# A parent holding a wrapped baby (15 November 2026), after a stock line drawing Tom liked: its idea, with the
# neckline, the sling's folds, the ear and the baby's face left out. Hair is a fine line, gone when small.
HELD_HEAD = circle(16, 7.2, 4.3)
HELD_HAIR = 'M11.9 6.3C13.9 6.6 15.6 5.5 16.3 3.4C17 5.3 18.4 6.3 20.1 6.3'
HELD_LEFT = 'M12.2 14.6C8 14.6 5.2 17.4 5.2 21.6V25'
HELD_RIGHT = 'M19.8 14.6C24 14.6 26.8 17.4 26.8 21.6C26.8 25.6 23.4 28 18.6 28H12.4C10.4 28 9 27.2 8.2 26'   # the shoulder runs on into the forearm
HELD_BUB = circle(20.2, 20.5, 3.0)
HELD_WRAP = 'M17.3 19.5C13.6 18.7 10 20.3 8.6 23.5C11.6 24.9 15.4 24.7 18.2 22.9'
HELD = {
    'held': (icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], fine=[HELD_HAIR], box=32, weight=BIG, wattle=[HELD_WRAP + 'Z']),
             icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], box=32, weight=SMALL, wattle=[HELD_WRAP + 'Z']),
             'Held, wrap in colour', 'Head with a parting, shoulders, and one arm that runs on under a wrapped baby. The wrap carries the colour.'),
    'held-baby': (icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], fine=[HELD_HAIR], box=32, weight=BIG, wattle=[HELD_BUB, HELD_WRAP + 'Z']),
                  icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], box=32, weight=SMALL, wattle=[HELD_BUB, HELD_WRAP + 'Z']),
                  'Held, baby in colour', 'The same, with the whole baby in colour.'),
    'held-line': (icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], fine=[HELD_HAIR, 'M12.6 20.5C13 21.7 13 22.9 12.6 23.9'], box=32, weight=BIG, wattle=[HELD_BUB]),
                  icon([HELD_HEAD, HELD_LEFT, HELD_RIGHT, HELD_BUB, HELD_WRAP], box=32, weight=SMALL, wattle=[HELD_BUB]),
                  'Held, in line', 'Nearest the drawing it came from: the wrap in line with one fold, and only the baby\u2019s head in colour.'),
}

def small(spec):
    """The drawing for lists and anything under 24 points: no eye, ear or fold, and a heavier line."""
    return spec if spec['box'] == 24 else dict(spec, fine=[], weight=SMALL)


def alternates():
    folder = os.path.join(OUT, 'v2', 'breastfeeding')
    os.makedirs(folder, exist_ok=True)
    art = lambda spec, **k: svg('x', spec=spec, **k)
    cells = ''
    for key, (spec, title, text) in ALTERNATES.items():
        open(os.path.join(folder, f'icon-breastfeed-{key}.svg'), 'w').write(art(spec))
        open(os.path.join(folder, f'icon-breastfeed-{key}-small.svg'), 'w').write(art(small(spec)))
        row = art(spec, size=32) + ''.join(art(small(spec), size=s) for s in (24, 17))
        plain = art(small(spec), plain=True, size=22).replace('#000000', '#3A2A20')
        cells += (f'<div class="c"><div class="big">{art(spec, size=190)}</div><div class="r">{row}'
                  f'<span class="dk">{art(spec, ink=DARK, size=30)}</span><span class="pl">{plain}</span></div>'
                  f'<div class="tiles"><div class="tile">{art(spec, size=40)}<b>Breastfeed</b><span>12:10</span></div></div>'
                  f'<h3>{title}</h3><p>{text}</p></div>')
    after = ''
    for key, (spec, simple, title, text) in list(SYMBOL.items()) + list(HELD.items()):
        open(os.path.join(folder, f'icon-breastfeed-{key}.svg'), 'w').write(art(spec))
        open(os.path.join(folder, f'icon-breastfeed-{key}-small.svg'), 'w').write(art(simple))
        row = art(spec, size=32) + ''.join(art(simple, size=s) for s in (24, 17))
        plain = art(simple, plain=True, size=22).replace('#000000', '#3A2A20')
        after += (f'<div class="c"><div class="big">{art(spec, size=190)}</div><div class="r">{row}'
                  f'<span class="dk">{art(spec, ink=DARK, size=30)}</span><span class="pl">{plain}</span></div>'
                  f'<div class="tiles"><div class="tile">{art(spec, size=40)}<b>Breastfeed</b><span>12:10</span></div></div>'
                  f'<h3>{title}</h3><p>{text}</p></div>')
    tones = ''.join(f'<div class="t">{art(breast(a, b), size=84)}{art(nursing(a, b), size=84)}</div>' for a, b in TONES)
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Breastfeeding icon, the choices</title><style>
body{{margin:0;padding:34px;background:#EFE7D4;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1180px}}
h1{{margin:0 0 4px;font-size:30px;letter-spacing:-.02em}}.lede{{margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:80ch}}
h2{{font-size:20px;margin:34px 0 4px}}h3{{margin:12px 0 2px;font-size:17px}}p{{margin:0;color:#6B5E52}}
.g{{display:flex;gap:20px}}.c{{width:220px}}.big{{background:#FBF6E9;border-radius:22px;height:220px;display:grid;place-items:center}}
.r{{display:flex;align-items:center;gap:10px;margin:10px 0}}.dk{{background:#2A2420;border-radius:12px;width:44px;height:44px;display:grid;place-items:center}}
.pl{{background:#EAE2D2;border-radius:50%;width:38px;height:38px;display:grid;place-items:center}}
.tile{{width:104px;height:104px;border-radius:20px;background:#FBF6E9;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px}}
.tile b{{font-size:14px;margin-top:4px}}.tile span{{color:#6B5E52;font-size:12px}}
.tiles{{display:flex;gap:8px}}
.tones{{display:flex;gap:14px;margin-top:12px}}.t{{background:#FBF6E9;border-radius:20px;padding:14px;display:flex;flex-direction:column;gap:8px}}
</style></head><body><h1>Breastfeeding icon, the choices</h1>
<p class="lede">Eight ways to draw it. The last three are Parent and baby without the blue; the very last is the one chosen, refined. Each is shown large, then at 32 points, then its simpler drawing at 24 and 17, in dark, in one colour for lists, and on a Today tile at 40 points, the size the app uses.</p>
<div class="g" style="flex-wrap:wrap">{cells}</div>
<h2>After the International Breastfeeding Symbol</h2><p>Six after the symbol (Matt Daigle, 2006, given to the public domain by its maker) and three of a parent holding a wrapped baby, added 15 November 2026. All are drawn for this set: its line, its weight and one colour.</p>
<div class="g" style="margin-top:14px;flex-wrap:wrap">{after}</div>
<h2>Skin tone</h2><p>The two with a breast, in five tones. The other three carry no skin colour.</p><div class="tones">{tones}</div></body></html>'''
    open(os.path.join(OUT, 'breastfeeding.html'), 'w').write(html)


# Three drawings of every icon (14 November 2026), as SF Symbols and Fluent have:
#   small    the drawings above: a 24 canvas and a 2 point line. For lists and anything under 24 points.
#   regular  the same shapes at the proportions of a 32 canvas (a 2.2 line there, which is 1.65 here), plus
#            details in a fine line (1.5 there, 1.125 here). For tiles.
#   large    a 48 canvas, for where an icon stands alone. Not drawn yet.
# DETAIL holds what the regular drawing adds to the small one. `drop` removes small-drawing lines it replaces.
MILK = 'M5.9 14.5H18.1C18.4 15.3 18.5 16.1 18.5 17V19A3 3 0 0 1 15.5 22H8.5A3 3 0 0 1 5.5 19V17C5.5 16.1 5.6 15.3 5.9 14.5Z'
DETAIL = {
    'bottle': dict(drop=[3], fine=['M5.9 14.5H18.1', 'M8.5 16.5H10.5M8.5 18.5H11.5M8.5 20.3H10.5'], note='Milk in the bottle, and three measure marks.'),
    'pump': dict(fine=['M10 17.5H20', 'M12.5 15.5H15'], note='The milk has a surface, and the bottle a mark.'),
    'solids': dict(fine=['M4.5 13.5H19.5', 'M4.5 6.5L3.5 5M7 5.3L6.4 3.5M9.5 5V3'], note='A rim on the bowl, and steam.'),
    'sleep': dict(ink=[sparkle(15, 10, 1.5), sparkle(21, 10.5, 1.2)], note='Two more stars.'),
    # A waistband joining the tops of the two tabs, and nothing in the middle: the leg openings do the work.
    # Before this it had an upright centre fold, which looked odd, and then two curved creases, which with
    # the tabs above them read as a face (Tom, 15 November 2026, after looking at how nappy makers draw one).
    # The waistband is drawn at the icon's own line weight, not the fine one (Tom, 15 November 2026).
    'nappy': dict(lines=['M6.6 7.6H17.4'], note='A waistband between the tabs.'),
    'potty': dict(note='As the small one.'),
    'bath': dict(fine=[circle(11.5, 3.3, 1.2), 'M13.2 6.2L11.2 7L13.2 8'], ink=[circle(15.2, 6.4, .7)], note='A second bubble, and the duck has a beak and an eye.'),
    'growth': dict(fine=['M7.5 4.5H9.5M7.5 8.5H9.5M7.5 12.5H9.5M7.5 16.5H9.5'], note='Half marks between the marks.'),
    'weight': dict(fine=['M12 19L13.6 16.4', 'M6.5 5.8H17.5'], note='A needle on the dial and a line in the tray.'),
    'temperature': dict(fine=['M17.5 5.5H19.5M17.5 8.5H19.5M17.5 11.5H19.5'], note='A scale beside the tube.'),
    'medicine': dict(fine=['M14.5 10.5H17'], note='A highlight on the capsule.'),
    'vaccine': dict(fine=['M13 9.5H15M13 12H15M13 14.5H15'], note='Marks on the barrel.'),
    'teeth': dict(fine=['M6.5 8C6.5 6.8 7.2 6 8.3 6'], note='A highlight and a sparkle.'),
    'milestone': dict(ink=[sparkle(20, 17.5, 1.7)], note='A third sparkle.'),
    'tummy-time': dict(fine=['M13.5 18.25C13.5 16.6 14.5 15.5 15.75 15.2', 'M6.4 13.1C7 13.7 7.4 14.5 7.4 15.4'], note='An elbow and a crease.'),
    'play': dict(fine=[scale(sparkle(20, 16, 4.6), .5), 'M6 15.6L7.8 18.6H4.2Z', circle(14, 17, 1.7)],
                 spec=dict(lines=[scale(d, .5) for d in BLOCKS48],
                           wattle=[rr(6, 4, 8, 8, 1.5)], sky=[], ink=[], tint=[], turn=0), note='The blocks have depth, and a shape on each.'),
    'walk': dict(fine=['M10 10.5L5.4 5.9', 'M6.5 15.5V18.5M13.5 15.5V18.5'], note='A rib in the hood, and legs to the wheels.'),
    'note': dict(fine=['M8.5 8.5H11'], note='A third line of writing.'),
    'photo': dict(fine=['M10.6 13.2A1.6 1.6 0 0 1 12 11.9'], ink=[circle(18, 10, .9)], note='A flash, and a glint on the lens.'),
    'wee': dict(fine=['M9 14.5C9 16.5 10 17.8 11.5 18.3'], note='A highlight.'),
    'poo': dict(fine=['M14 17.5H17', 'M16.8 4.5L17.8 2.8M18.3 6.3L20 5.3'], note='One more fold, and shine.'),
}


def regular(name):
    more = DETAIL.get(name, {})
    spec = dict(ICONS[name], **more['spec']) if 'spec' in more else ICONS[name]
    out = dict(spec, weight=1.65, fineweight=1.125, fine=list(more.get('fine', [])))
    out['lines'] = [d for i, d in enumerate(spec['lines']) if i not in more.get('drop', [])] + list(more.get('lines', []))
    for key in ('sky', 'wattle', 'ink'):
        out[key] = list(spec[key]) + list(more.get(key, []))
    return out


def size_sheet():
    """The sheet for the three sizes: every icon small in a list, and regular on a tile and close up."""
    folder = os.path.join(OUT, 'v2', 'regular')
    os.makedirs(folder, exist_ok=True)
    cells = ''
    for name in ICONS:
        reg = regular(name)
        open(os.path.join(folder, f'icon-{name}.svg'), 'w').write(svg(name, spec=reg))
        plain = lambda s: svg(name, plain=True, size=s).replace('#000000', '#3A2A20')
        label = name.replace('-', ' ').capitalize()
        cells += (f'<div class="c"><div class="pair"><div class="big">{svg(name, size=96)}<i>small</i></div><div class="big">{svg(name, spec=reg, size=96)}<i>regular</i></div></div>'
                  f'<div class="use"><span class="pl">{plain(20)}</span><span class="pl sm">{plain(17)}</span>'
                  f'<div class="tile">{svg(name, spec=reg, size=40)}<b>{label}</b></div>'
                  f'<span class="dk">{svg(name, spec=reg, ink=DARK, size=40)}</span></div>'
                  f'<h3>{label}</h3><p>{DETAIL.get(name, {}).get("note", "No change yet.")}</p></div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle icons, three sizes</title><style>
body{{margin:0;padding:34px;background:#EFE7D4;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1180px}}
h1{{margin:0 0 4px;font-size:30px;letter-spacing:-.02em}}.lede{{margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:84ch}}
h3{{margin:10px 0 2px;font-size:17px}}p{{margin:0;color:#6B5E52}}i{{display:block;font-style:normal;font-size:12px;color:#6B5E52;text-align:center}}
.g{{display:flex;flex-wrap:wrap;gap:30px 20px}}.c{{width:220px}}.pair{{display:flex;gap:8px}}
.big{{background:#FBF6E9;border-radius:18px;width:106px;padding:6px 0 4px;display:grid;place-items:center}}
.use{{display:flex;align-items:center;gap:8px;margin-top:8px}}.pl{{background:#EAE2D2;border-radius:50%;width:36px;height:36px;display:grid;place-items:center}}.pl.sm{{width:30px;height:30px}}
.tile{{width:76px;height:76px;border-radius:18px;background:#FBF6E9;display:flex;flex-direction:column;align-items:center;justify-content:center}}
.tile b{{font-size:11px;margin-top:2px}}.dk{{background:#2A2420;border-radius:16px;width:60px;height:60px;display:grid;place-items:center}}
</style></head><body><h1>Puggle icons, three sizes</h1>
<p class="lede">Small is for lists: the drawing as it was. Regular is for tiles: the same shapes with a finer line and a little more detail, shown at 40 points. Large, for where an icon stands alone, is not drawn yet. Under each pair: the small drawing in a list at 20 and 17 points, then the regular one on a tile and in dark.</p>
<div class="g" style="flex-wrap:wrap">{cells}</div></body></html>'''
    open(os.path.join(OUT, 'sizes.html'), 'w').write(html)


# How each icon draws itself on (15 November 2026, second pass, against Apple's guidance for the Draw animation
# in SF Symbols 7). Apple annotates a symbol with guide points: where each path starts, where it ends, and so
# which way it runs; and with layers, which draw with a staggered start. This is the same for Puggle's icons.
#
#   groups   One list for each motion group, in the order they start. Each group is a list of tracks, which
#            draw at the same time; a track is the strokes one pen makes, one after another.
#   stroke   Its number (the larger drawing's lines, split into single strokes, then its fine lines), then a
#            colon and how it is drawn:
#              (nothing)  an open stroke as it was written; a closed one from where it was written, clockwise
#              r          an open stroke the other way
#              m          from its middle out to both ends: Apple's bidirectional drawing, for something symmetrical
#              e          from both ends in to the middle
#              T B L R TL TR BL BR @x,y   a closed stroke, starting at its top, bottom, left, right, a corner,
#                         or the point nearest x,y. Clockwise, as Apple draws a circle, unless followed by "-".
#   fills    When a colour or a filled detail appears: after which group, and "up" if it rises from its foot.
#            Apple: parts that are not drawn "appear in". Colours come after group 0 and filled details after
#            the last group unless said here. a0 is the first colour, x0 the first fixed colour, k0 the first
#            filled detail.
#
# The rules followed: the main shape first, then what sits on it; top to bottom and left to right, as a hand
# would; something symmetrical from its middle; a closed shape clockwise; and a direction that says what the
# thing does where it has one (steam rises, a level fills, ticks are counted down a ruler). Because a group
# starts before the last has finished, a stroke that joins another starts from the end where the other
# already is, so it grows out of a line and does not begin in mid-air: the nappy's leg openings from the
# hips, the ruler's left side before its ticks, the band in the bowl from the wall already drawn.
DRAW = {
    'bottle':      dict(groups=[['0:m'], ['1:TL'], ['2:e'], ['3'], ['4 5 6']]),
    'breastfeed':  dict(groups=[['0']]),
    'pump':        dict(groups=[['0'], ['1:TL'], ['2:TL'], ['3'], ['4 5']], fills={'a0': (4, 'up')}),
    'solids':      dict(groups=[['0'], ['4:r', '3:m'], ['1'], ['2'], ['5', '6', '7']], fills={'a0': 2}),
    'sleep':       dict(groups=[['0:@9.5,3.5-']]),
    'nappy':       dict(groups=[['0:m 1:e'], ['5:r', '4:r'], ['6:m'], ['2:TL', '3:TR-']], fills={'a0': 3, 'a1': 3}),
    'potty':       dict(groups=[['0:T 1:e']]),
    'bath':        dict(groups=[['0'], ['1', '2'], ['3:T 6'], ['4:T 5:T']], fills={'a0': 2, 'k0': 2}),
    'growth':      dict(groups=[['0:BL'], ['5 1 6 2 7 3 8 4']]),
    'weight':      dict(groups=[['0'], ['1', '5:m'], ['2'], ['3'], ['4']], fills={'a0': 3}),
    'temperature': dict(groups=[['0:T'], ['1 2 3']], fills={'a0': 0, 'a1': (0, 'up')}),
    'medicine':    dict(groups=[['0'], ['1'], ['2']], fills={'a0': 1}),
    'vaccine':     dict(groups=[['0'], ['1 2:m', '3'], ['4:r 5:r 6:r']]),
    'teeth':       dict(groups=[['0 1']]),
    'milestone':   dict(groups=[['0']]),
    'tummy-time':  dict(groups=[['0:T'], ['1'], ['2'], ['4', '3']], fills={'a0': 1, 'k0': 1}),
    'play':        dict(groups=[['0:TL', '1:TL'], ['3', '4', '5', '6'], ['2:TL'], ['7', '8'], ['10', '11', '9']], fills={'a0': 2}),
    'walk':        dict(groups=[['1'], ['0 5'], ['2'], ['6 3:T', '7 4:T']], fills={'a0': 1}),
    'note':        dict(groups=[['0'], ['1'], ['4 2 3']], fills={'a0': 1}),
    'photo':       dict(groups=[['0'], ['1'], ['2:T'], ['3']], fills={'a0': 2, 'k0': 0}),
}
OPEN_WAYS, CORNERS = ('', 'r', 'm', 'e'), ('T', 'B', 'L', 'R', 'TL', 'TR', 'BL', 'BR')


def draw_data(name):
    """An icon's strokes in the order they are drawn, and its colours, for the app (IconStrokes.json)."""
    spec = regular(name)
    single = []   # every stroke on its own: (path, fine)
    for key, fine in (('lines', False), ('fine', True)):
        for d in spec.get(key, []):
            single += [('M' + part.strip(), fine) for part in d.split('M') if part.strip()]
    plan = DRAW.get(name) or dict(groups=[[str(i)] for i in range(len(single))])
    strokes, used = [], set()
    for group, tracks in enumerate(plan['groups']):
        for track, refs in enumerate(tracks):
            for ref in refs.split():
                number, _, way = ref.partition(':')
                number = int(number)
                assert number < len(single) and number not in used, (name, ref)
                used.add(number)
                d, fine = single[number]
                closed = d.rstrip().endswith('Z')
                start = way.rstrip('-')
                assert (way in OPEN_WAYS) if not closed else (start == '' or start in CORNERS or start.startswith('@')), (name, ref, 'closed' if closed else 'open')
                strokes.append({'d': d, 'fine': fine, 'mode': way, 'group': group, 'track': track})
    assert len(used) == len(single), (name, 'strokes with no place in the drawing', sorted(set(range(len(single))) - used))
    asked, last, fills = plan.get('fills', {}), len(plan['groups']) - 1, []
    def fill(key, d, kind, colour=None, usual=0):
        after, grow = asked.get(key, usual), 'centre'
        if isinstance(after, tuple): after, grow = after
        assert after <= last, (name, key)
        fills.append({'d': d, 'kind': kind, 'colour': colour, 'after': after, 'grow': grow})
    for i, d in enumerate(spec['wattle']): fill(f'a{i}', d, 'accent')
    for i, t in enumerate(spec['tint']): fill(f'x{i}', t[0], 'fixed', t[1])
    for i, d in enumerate(spec['ink']): fill(f'k{i}', d, 'ink', usual=last)
    assert not set(asked) - {f'{k}{i}' for k, n in (('a', len(spec['wattle'])), ('x', len(spec['tint'])), ('k', len(spec['ink']))) for i in range(n)}, (name, 'no such fill')
    return {'box': spec.get('box', 24), 'turn': spec['turn'], 'weight': spec.get('weight', W), 'fine': spec.get('fineweight', 1.2),
            'strokes': strokes, 'fills': fills}


def main():
    alternates()
    size_sheet()
    os.makedirs(os.path.join(OUT, 'v2'), exist_ok=True)
    for name in ICONS:
        with open(os.path.join(OUT, 'v2', f'icon-{name}.svg'), 'w') as out: out.write(svg(name))
    if '--install' in sys.argv:
        for name in ICONS:
            if name in NEW: continue
            folder = os.path.join(ASSETS, f'icon-{name}.imageset')
            open(os.path.join(folder, f'icon-{name}.svg'), 'w').write(svg(name))
            open(os.path.join(folder, f'icon-{name}-dark.svg'), 'w').write(svg(name, ink=DARK))
            open(os.path.join(ASSETS, f'icon-{name}-plain.imageset', f'icon-{name}-plain.svg'), 'w').write(svg(name, plain=True))
            # The parts the app tints: the small drawing, and the regular one (`-reg`) for 32 points and up.
            for tag, spec in (('', ICONS[name]), ('-reg', regular(name))):
                for layer in ('line', 'fill', 'fixed'):
                    text = svg(name, spec=spec, layer=layer)
                    other = svg(name, spec=spec, layer=layer, ink=DARK) if layer != 'fill' else None
                    if text: imageset(f'icon-{name}{tag}-{layer}', text, template=layer != 'fixed', dark=other)
        import json
        # The strokes themselves, in the order and direction they are drawn, for the app to draw an icon on
        # (see DRAW). The larger drawing only, which is the one shown at 32 points and up.
        strokes = {f'icon-{name}': draw_data(name) for name in ICONS if name not in NEW}
        json.dump(strokes, open(os.path.join(ASSETS, '..', 'IconStrokes.json'), 'w'), indent=1)
        os.makedirs(WIDGET_ASSETS, exist_ok=True)
        json.dump({'info': {'author': 'xcode', 'version': 1}}, open(os.path.join(WIDGET_ASSETS, 'Contents.json'), 'w'), indent=2)
        for name in WIDGET_GLYPHS:
            imageset(f'glyph-{name}', svg(name, plain=True), template=True, catalogue=WIDGET_ASSETS)
        print('installed', len(ICONS) - len(NEW), 'icons')
    grid = ''.join(f'<path d="M{i} 0V24M0 {i}H24" stroke="#C9583F" stroke-width="0.03" opacity=".45"/>' for i in range(25))
    keys = ('<rect x="1" y="1" width="22" height="22" fill="none" stroke="#2A62B8" stroke-width="0.06" stroke-dasharray=".3 .3"/>'
            '<circle cx="12" cy="12" r="10" fill="none" stroke="#2A62B8" stroke-width="0.06"/><rect x="3" y="3" width="18" height="18" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/>'
            '<rect x="4" y="2" width="16" height="20" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/><rect x="2" y="4" width="20" height="16" rx="2" fill="none" stroke="#2A62B8" stroke-width="0.06"/>')
    sizes = lambda art: ''.join(f'<svg viewBox="0 0 24 24" width="{s}" height="{s}">{art}</svg>' for s in (32, 24, 17))
    cells = ''
    for name, spec in ICONS.items():
        now = inner_of(svg(name))
        app = from_file(os.path.join(ASSETS, f'icon-{name}.imageset', f'icon-{name}.svg'))
        first = from_file(os.path.join(OUT, 'v1', f'icon-{name}.svg'))
        rows = ''.join(f'<div class="r"><span class="lab">{label}</span>{sizes(art)}</div>' for label, art in (('in the app', app), ('first pass', first), ('now', now)) if art)
        cells += (f'<div class="c"><svg viewBox="0 0 24 24" width="150" height="150" class="new">{grid}{keys}{now}</svg>{rows}'
                  f'<b>{name.replace("-", " ").capitalize()}</b><p>{spec["note"]}</p></div>')
    chip = lambda art, bg: f'<span class="chip" style="background:{bg}">{art}</span>'
    light = ''.join(chip(svg(n, size=30), '#FBF6E9') for n in ICONS)
    dark = ''.join(chip(svg(n, ink=DARK, size=30), '#2A2420') for n in ICONS)
    mono = ''.join(chip(f'<span style="color:#3A2A20">{svg(n, plain=True, size=22).replace("#000000", "#3A2A20")}</span>', '#EAE2D2') for n in ICONS)
    tiny = ''.join(svg(n, size=17) for n in ICONS)
    tile = lambda n, label, sub: (f'<div class="tile">{svg(n, spec=regular(n), size=40)}<b>{label}</b><span>{sub}</span></div>')
    listrow = lambda n, what, when: (f'<div class="lr"><span class="ic">{svg(n, plain=True, size=20).replace("#000000", "#3A2A20")}</span><b>{what}</b><span>{when}</span></div>')
    context = (f'<div class="ctx"><div class="tiles">{tile("bottle", "Feeding", "14:52")}{tile("nappy", "Nappy", "Ollie 16:00")}{tile("potty", "Potty", "14:40")}'
               f'{tile("breastfeed", "Breastfeed", "12:10")}{tile("sleep", "Sleep", "1h 59m")}</div>'
               f'<div class="list">{listrow("nappy", "Nappy · wet", "16:00")}{listrow("breastfeed", "Breastfeed · 12m", "12:10")}{listrow("bottle", "Bottle · 180 ml", "14:52")}{listrow("potty", "Potty · wee", "14:40")}</div></div>')
    big = lambda art, label: f'<div class="bigc"><svg viewBox="0 0 24 24" width="170" height="170" class="new">{art}</svg><span>{label}</span></div>'
    close = (f'<div class="closeups">{big(from_file(os.path.join(OUT, "v1", "icon-nappy.svg")), "Nappy, first pass: the leg cut-outs shape the outline, like pants")}'
             f'{big(inner_of(svg("nappy")), "Nappy now: a closed padded shape, tabs and leg openings inside")}'
             f'{big(inner_of(svg("breastfeed")), "Breast, in Shell (suggested): a brand colour, though one skin tone")}{big(inner_of(svg("x", spec=PLAIN_BREAST)), "Breast, with no skin colour: harder to read")}'
             f'{big(inner_of(svg("poo")), "Poo (new)")}{big(inner_of(svg("wee")), "Wee (new)")}</div>')
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle icons, second pass</title><style>
body{{margin:0;padding:30px;background:#EFE7D4;font:13px/1.35 -apple-system,system-ui,sans-serif;color:#3A2A20;width:2010px}}
h1{{margin:0 0 4px;font-size:28px;letter-spacing:-.02em}}.lede{{margin:0 0 18px;color:#6B5E52;font-size:16px;max-width:150ch}}
h2{{font-size:18px;margin:28px 0 8px}}
.g{{display:flex;flex-wrap:wrap;gap:22px 14px}}.c{{width:168px}}.new{{background:#FBF6E9;border-radius:14px}}
.r{{display:flex;align-items:center;gap:8px;margin-top:5px;height:34px}}.lab{{width:54px;color:#6B5E52;font-size:11px}}
b{{display:block;margin-top:6px;font-size:14px}}p{{margin:2px 0 0;color:#6B5E52}}
.strip{{display:flex;gap:8px;align-items:center;padding:12px;border-radius:16px;margin-top:10px;flex-wrap:wrap}}
.chip{{width:50px;height:50px;border-radius:14px;display:grid;place-items:center}}
.closeups{{display:flex;gap:18px}}.bigc{{width:170px}}.bigc span{{display:block;margin-top:6px;color:#6B5E52}}
.ctx{{display:flex;gap:26px;align-items:flex-start}}.tiles{{display:flex;gap:10px;background:#F2ECDD;padding:14px;border-radius:22px}}
.tile{{width:104px;height:104px;border-radius:20px;background:#FBF6E9;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px}}
.tile b{{margin:4px 0 0;font-size:14px}}.tile span{{color:#6B5E52;font-size:12px}}
.list{{background:#FBF6E9;border-radius:20px;padding:4px 16px;width:330px}}.lr{{display:flex;align-items:center;gap:12px;padding:9px 0}}.lr+.lr{{border-top:1px solid #DDD2BC}}
.lr .ic{{width:36px;height:36px;border-radius:50%;background:#EAE2D2;display:grid;place-items:center}}.lr b{{margin:0;flex:1;font-size:14px}}.lr span{{color:#6B5E52}}
</style></head><body><h1>Puggle icons, second pass</h1>
<p class="lede">A heavier line, fuller shapes, and two fills: Wattle for what the icon is about, Sky for what holds it. Each is shown on the grid, then at 32, 24 and 17 points beside the icon in the app today and the first pass.</p>
<div class="g" style="flex-wrap:wrap">{cells}</div>
<h2>The ones that changed most</h2>{close}
<h2>The set together: on paper, in dark, in one colour for lists, and at 17 points</h2>
<div class="strip" style="background:#F2ECDD">{light}</div><div class="strip" style="background:#14110F">{dark}</div>
<div class="strip" style="background:#FBF6E9">{mono}</div><div class="strip">{tiny}</div>
<h2>In place: tiles on Today, and a list in History</h2>{context}</body></html>'''
    with open(os.path.join(OUT, 'refined.html'), 'w') as out: out.write(html)
    print(len(ICONS), 'icons')


if __name__ == '__main__':
    main()
