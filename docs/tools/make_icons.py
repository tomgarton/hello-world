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
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'icons')
ASSETS = os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets')
INK, DARK, WATTLE, SKY = '#3A2A20', '#EBDDC4', '#F4BE2C', '#BFD9F5'
W = 2


def rr(x, y, w, h, r):
    return (f'M{x + r} {y}H{x + w - r}A{r} {r} 0 0 1 {x + w} {y + r}V{y + h - r}A{r} {r} 0 0 1 {x + w - r} {y + h}'
            f'H{x + r}A{r} {r} 0 0 1 {x} {y + h - r}V{y + r}A{r} {r} 0 0 1 {x + r} {y}Z')


def circle(cx, cy, r):
    return f'M{cx - r} {cy}A{r} {r} 0 1 0 {cx + r} {cy}A{r} {r} 0 1 0 {cx - r} {cy}Z'


def sparkle(cx, cy, r):
    """A four-point sparkle, the brand's star."""
    k = r * 0.12
    return (f'M{cx} {cy - r}C{cx + k} {cy - r * .45} {cx + r * .45} {cy - k} {cx + r} {cy}'
            f'C{cx + r * .45} {cy + k} {cx + k} {cy + r * .45} {cx} {cy + r}'
            f'C{cx - k} {cy + r * .45} {cx - r * .45} {cy + k} {cx - r} {cy}'
            f'C{cx - r * .45} {cy - k} {cx - k} {cy - r * .45} {cx} {cy - r}Z')


def icon(lines, wattle=(), sky=(), ink=(), tint=(), turn=0, note='', fine=(), box=24):
    return {'fine': list(fine), 'box': box, 'lines': list(lines), 'wattle': list(wattle), 'sky': list(sky), 'ink': list(ink), 'tint': list(tint), 'turn': turn, 'note': note}


TEAT = 'M9 8C9 6.5 10 6 10 4.5A2 2 0 0 1 14 4.5C14 6 15 6.5 15 8'
NAPPY = 'M6 4.5H18A4 4 0 0 1 22 8.5V12C22 17 18.5 20.5 14 20.5H10C5.5 20.5 2 17 2 12V8.5A4 4 0 0 1 6 4.5Z'
BREAST = 'M7.5 2.5C13 5 20.5 8.5 20.5 14A8 8 0 0 1 12.5 22C7.5 22 3.5 18.5 3.5 13.5C3.5 9.5 5.5 6 7.5 2.5Z'
POTTY = ('M12 4C9 4 7.5 6.5 7 10C5 10.8 3.6 12.5 3 14.5C2.3 17 2 18.5 2 19.5A2.5 2.5 0 0 0 4.5 22H19.5A2.5 2.5 0 0 0 22 19.5'
         'C22 18.5 21.7 17 21 14.5C20.4 12.5 19 10.8 17 10C16.5 6.5 15 4 12 4Z')
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
    'pump': icon(['M14 8.5L9.5 2.5C6 1.5 3 4.5 4.5 8L12 10.5', rr(12, 9.5, 6, 4, 1.5), rr(10, 13.5, 10, 8.5, 3)],
                 sky=['M14 8.5L9.5 2.5C6 1.5 3 4.5 4.5 8L12 10.5Z'], wattle=['M10 17.5H20V19A3 3 0 0 1 17 22H13A3 3 0 0 1 10 19Z'],
                 note='A cupped funnel, tilted up, sitting on its bottle.'),
    'solids': icon(['M7 11A5 5 0 0 1 17 11', 'M2.5 11H21.5A9.5 9.5 0 0 1 2.5 11Z', 'M15.5 7.5L20.5 2.5'],
                   wattle=['M7 11A5 5 0 0 1 17 11Z'], sky=['M2.5 11H21.5A9.5 9.5 0 0 1 2.5 11Z'], note='A filled bowl.'),
    'sleep': icon([MOON], wattle=[MOON], ink=[sparkle(18.5, 5, 3)], note='A filled moon, thick through the middle.'),
    # The tabs are flat and wide and sit right above the leg openings, so each side reads as one band of the
    # garment and the four patches are not two eyes and a mouth. The leg openings are big, which narrows the crotch.
    'nappy': icon([NAPPY, rr(2, 7.5, 5.5, 3.5, 1.75), rr(16.5, 7.5, 5.5, 3.5, 1.75), 'M14 20.5C14 16 18 12 22 12', 'M10 20.5C10 16 6 12 2 12'],
                  sky=[rr(2, 7.5, 5.5, 3.5, 1.75), rr(16.5, 7.5, 5.5, 3.5, 1.75), 'M22 12C22 17 18.5 20.5 14 20.5C14 16 18 12 22 12Z', 'M2 12C2 17 5.5 20.5 10 20.5C10 16 6 12 2 12Z'],
                  note='One closed, padded shape. The tabs and the leg openings sit inside it, which is what says nappy and not pants.'),
    'potty': icon([POTTY, 'M3 14.5C5 16.6 8.5 17.5 12 17.5C15.5 17.5 19 16.6 21 14.5'],
                  sky=['M3 14.5C5 16.6 8.5 17.5 12 17.5C15.5 17.5 19 16.6 21 14.5C21.7 17 22 18.5 22 19.5A2.5 2.5 0 0 1 19.5 22H4.5A2.5 2.5 0 0 1 2 19.5C2 18.5 2.3 17 3 14.5Z'],
                  ink=['M8.5 13A3.5 1.5 0 1 0 15.5 13A3.5 1.5 0 1 0 8.5 13Z'],
                  note='A small backrest, a wide seat with its opening, and a base.'),
    'bath': icon(['M2.5 11H21.5V13.5A6 6 0 0 1 15.5 19.5H8.5A6 6 0 0 1 2.5 13.5Z', 'M6.5 19.5L5.5 22M17.5 19.5L18.5 22', circle(8.5, 5.5, 2.5), circle(15, 6.5, 1.5)],
                 sky=['M2.5 11H21.5V13.5A6 6 0 0 1 15.5 19.5H8.5A6 6 0 0 1 2.5 13.5Z'], note='A filled tub and two bubbles.'),
    'growth': icon([rr(7.5, 2, 9, 20, 2.5), 'M7.5 6.5H10.5M7.5 10.5H12M7.5 14.5H10.5M7.5 18.5H12'], wattle=[rr(7.5, 2, 9, 20, 2.5)],
                   note='A height chart by itself. The arrow is gone.'),
    'weight': icon([rr(3, 3.5, 18, 18, 4.5), 'M7.5 11.5A4.5 4.5 0 0 1 16.5 11.5Z', 'M12 11.5L13.5 9'],
                   sky=[rr(3, 3.5, 18, 18, 4.5)], wattle=['M7.5 11.5A4.5 4.5 0 0 1 16.5 11.5Z'],
                   note='A scale seen from above, with its dial. The tray on a stand read as an hourglass.'),
    'temperature': icon(['M9 13V5A3 3 0 0 1 15 5V13A5 5 0 1 1 9 13Z'], wattle=[circle(12, 17, 2.5), rr(11, 7.5, 2, 9, 1)],
                        note='The reading is a filled column, not a second line.'),
    'medicine': icon([rr(2.5, 8, 19, 8, 4), 'M12 8V16'], wattle=['M6.5 8H12V16H6.5A4 4 0 0 1 6.5 8Z'], turn=-45, note='A capsule.'),
    'vaccine': icon([rr(9, 7.5, 6, 9.5, 1.5), 'M12 7.5V3.5M9.5 3.5H14.5', 'M12 17V21.5'], wattle=[rr(9, 11.5, 6, 5.5, 1.5)], turn=45, note='A syringe, with nothing on the barrel.'),
    'teeth': icon([TOOTH], wattle=[circle(16.5, 8, 1.5)], note='Wider roots, so they do not close up.'),
    'milestone': icon([BIG_SPARKLE], wattle=[BIG_SPARKLE], ink=[sparkle(19, 5.5, 3)],
                      note='Sparkles, not a five-point star: the brand\'s own star is the four-point one.'),
    'tummy-time': icon([rr(2.5, 13, 12.5, 6, 3), circle(17.5, 9, 3.5), 'M14 19H21.5'], wattle=[circle(17.5, 9, 3.5)], note='As before, heavier.'),
    'play': icon([rr(8, 2.5, 8, 8, 2.5), rr(2.5, 14, 7.5, 7.5, 2.5), rr(14, 14, 7.5, 7.5, 2.5)], wattle=[rr(8, 2.5, 8, 8, 2.5)], sky=[rr(14, 14, 7.5, 7.5, 2.5)], note='Three blocks, two of them coloured.'),
    'walk': icon(['M3.5 10.5A6.5 6.5 0 0 1 10 4V10.5Z', 'M3.5 10.5H16.5C16.5 13.5 13.6 15.5 10 15.5C6.4 15.5 3.5 13.5 3.5 10.5Z', 'M16.5 10.5L18.5 5H21.5', circle(6.5, 20, 1.5), circle(13.5, 20, 1.5)],
                 wattle=['M3.5 10.5A6.5 6.5 0 0 1 10 4V10.5Z'], sky=['M3.5 10.5H16.5C16.5 13.5 13.6 15.5 10 15.5C6.4 15.5 3.5 13.5 3.5 10.5Z'], note='A pram with a hood.'),
    'note': icon(['M7 3H14L18.5 7.5V19A2 2 0 0 1 16.5 21H7A2 2 0 0 1 5 19V5A2 2 0 0 1 7 3Z', 'M14 3V7.5H18.5', 'M8.5 12.5H15M8.5 16.5H12.5'], wattle=['M14 3L18.5 7.5H14Z'], note='As before, heavier.'),
    'photo': icon([rr(2, 6.5, 20, 14.5, 3.5), 'M8 6.5L9.5 3.5H14.5L16 6.5', circle(12, 13.5, 3.5)], wattle=[circle(12, 13.5, 3.5)], note='As before, heavier.'),
    # New, for the kinds of nappy. Not in the app.
    'poo': icon([POO, 'M8.5 10H12M6.2 15.5H11'], tint=[(POO, '#C99668')], note='New. The one icon with a colour of its own.'),
    'wee': icon([DROP], wattle=[DROP], note='New. A drop.'),
}
NEW = ['poo', 'wee']


def svg(name, ink=INK, plain=False, size=24, spec=None):
    spec = spec or ICONS[name]
    def fill(d, colour, solid=False):
        if plain: return f'<path d="{d}" fill="#000000"{"" if solid else " fill-opacity=" + chr(34) + "0.16" + chr(34)}/>'
        return f'<path d="{d}" fill="{colour}"/>'
    inner = ''.join(fill(d, SKY) for d in spec['sky']) + ''.join(fill(d, WATTLE) for d in spec['wattle'])
    # A tint marked strong lies on another (the areola on the breast): in one colour it is a stronger tint, so it still shows.
    inner += ''.join(fill(t[0], t[1]).replace('0.16', '0.4' if len(t) > 2 else '0.16') for t in spec['tint'])
    stroke = '#000000' if plain else ink
    inner += ''.join(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{W}" stroke-linecap="round" stroke-linejoin="round"/>' for d in spec['lines'])
    # Fine lines (1.5 points) are for a closed eye inside a small head, and nothing else.
    inner += ''.join(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' for d in spec.get('fine', []))
    inner += ''.join(fill(d, ink, solid=True) for d in spec['ink'])
    if spec['turn']: inner = f'<g transform="rotate({spec["turn"]} 12 12)">{inner}</g>'
    box = spec.get('box', 24)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {box} {box}" width="{size}" height="{size}">{inner}</svg>'


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
    return icon([BREAST], tint=[(BREAST, tone), (circle(16, 15, 2.5), areola, True)])


# The four with a baby in them are drawn on a 32 canvas, not 24, with the same 2 point line. That is the room a
# closed eye, hair and a blanket need: on 24 the line fills them in. Fluent does the same, with more detail in its
# larger sizes. On a tile they sit at the same size as the rest, with a line a quarter lighter.
EYE = lambda x, y: f'M{x - 1.6} {y}Q{x} {y + 1.8} {x + 1.6} {y}'
SIDE = 'M8 3.5C13 5.5 16.5 10 17.5 15.5C18 21.5 15 28.5 10 28.5C6 28.5 3 24.5 3 19.5C3 13.5 6.5 8.5 8 3.5Z'
WRAP = 'M28.2 18C28.5 24 24.5 28.5 19.5 28.5C17 28.5 14.8 28 13.3 27.3'


def nursing(tone, areola):
    head = circle(23, 16, 5.5)
    return icon([SIDE, head, WRAP], fine=[EYE(23.6, 16.6), 'M18.5 24.6C20.5 25 23 24.2 24.6 22.6'], box=32,
                sky=[WRAP + 'C15.5 25 17 21.5 17.7 17.5A5.5 5.5 0 0 0 28.2 18Z'],
                tint=[(SIDE, tone), (circle(15, 16, 2.6), areola, True), (head, tone)])


MUM, BUB = circle(13, 9.5, 6), circle(21.5, 21, 5)
TORSO = 'M8.5 13.5C5.5 15.5 3.5 19 3.5 23V25.5A3 3 0 0 0 6.5 28.5H21C24.5 28.5 27 26.5 26.3 22.4'
FRINGE = 'M7.2 11C11.5 11 15.5 9 17.5 5.5'
BUN = 'M9.4 4.7A3 3 0 1 0 7.1 8.4'
DROP32 = 'M16 2.5C21.5 9 26.5 14 26.5 19.5A10.5 10.5 0 0 1 5.5 19.5C5.5 14 10.5 9 16 2.5Z'
WAVE = 'M5.8 22C10 19.5 13 26 18.5 24.8C22 24 24 21 26.3 21.5'
HEART32 = 'M16 28C9.5 23.5 3 18.5 3 11.5A6.5 6.5 0 0 1 16 9A6.5 6.5 0 0 1 29 11.5C29 18.5 22.5 23.5 16 28Z'
LAP = 'M5.5 18.5C9.5 16.5 12.5 22.5 17.5 22C21.5 21.5 23.5 18 26.5 18'

ALTERNATES = {
    'breast': (ICONS['breastfeed'], 'Breast', 'As now. The plainest, and the one most likely to be unwelcome somewhere.'),
    'nursing': (nursing(*TONES[0]), 'Breast and baby', 'A sleepy baby at the breast, wrapped in a blanket. A little of the areola shows.'),
    'held': (icon([MUM, BUN, BUB, TORSO, FRINGE, 'M17.4 13.6C18 15 18 16.5 17.6 17.9', 'M17.2 23.6C14.5 24.3 13 26 12.5 28.5'],
                  fine=[EYE(14.6, 12), EYE(20.8, 21.6)], box=32,
                  sky=['M8.5 13.5C5.5 15.5 3.5 19 3.5 23V25.5A3 3 0 0 0 6.5 28.5H12.5C13 26 14.5 24.3 17.2 23.6A5 5 0 0 1 17.6 17.9C18 16.5 18 15 17.4 13.6A6 6 0 0 1 8.5 13.5Z'],
                  wattle=[FRINGE + 'A6 6 0 0 0 7.2 11Z', BUN + 'A6 6 0 0 1 9.4 4.7Z',
                          'M12.5 28.5C13 26 14.5 24.3 17.2 23.6A5 5 0 0 0 26.3 22.4C27 26.5 24.5 28.5 21 28.5Z']),
             'Parent and baby', 'A parent with hair in a bun and a closed eye, holding a wrapped baby. No breast and no skin colour.'),
    'drop': (icon([DROP32, circle(17.5, 16, 4.5), WAVE], fine=[EYE(16.2, 17)], box=32,
                  sky=[WAVE + 'A10.5 10.5 0 0 1 5.8 22Z'], wattle=[circle(17.5, 16, 4.5)]),
             'Milk drop', 'A sleeping baby tucked up inside a drop of milk. No breast and no skin colour.'),
    'heart': (icon([HEART32, circle(17, 14, 4.5), LAP], fine=[EYE(15.7, 15)], box=32,
                   sky=[LAP + 'C24 22 20 25.2 16 28C12 25.2 8 22 5.5 18.5Z'], wattle=[circle(17, 14, 4.5)]),
              'Heart', 'The same, in a heart. Reads as love more than feeding.'),
}


def alternates():
    folder = os.path.join(OUT, 'v2', 'breastfeeding')
    os.makedirs(folder, exist_ok=True)
    art = lambda spec, **k: svg('x', spec=spec, **k)
    cells = ''
    for key, (spec, title, text) in ALTERNATES.items():
        open(os.path.join(folder, f'icon-breastfeed-{key}.svg'), 'w').write(art(spec))
        row = ''.join(art(spec, size=s) for s in (32, 24, 17))
        plain = art(spec, plain=True, size=22).replace('#000000', '#3A2A20')
        cells += (f'<div class="c"><div class="big">{art(spec, size=190)}</div><div class="r">{row}'
                  f'<span class="dk">{art(spec, ink=DARK, size=30)}</span><span class="pl">{plain}</span></div>'
                  f'<div class="tile">{art(spec, size=34)}<b>Breastfeed</b><span>12:10</span></div>'
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
.tones{{display:flex;gap:14px;margin-top:12px}}.t{{background:#FBF6E9;border-radius:20px;padding:14px;display:flex;flex-direction:column;gap:8px}}
</style></head><body><h1>Breastfeeding icon, the choices</h1>
<p class="lede">Five ways to draw it, from the plainest to the quietest. Each is shown large, then at 32, 24 and 17 points, in dark, in one colour for lists, and on a Today tile.</p>
<div class="g">{cells}</div>
<h2>Skin tone</h2><p>The two with a breast, in five tones. The other three carry no skin colour.</p><div class="tones">{tones}</div></body></html>'''
    open(os.path.join(OUT, 'breastfeeding.html'), 'w').write(html)


def main():
    alternates()
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
    tile = lambda n, label, sub: (f'<div class="tile">{svg(n, size=34)}<b>{label}</b><span>{sub}</span></div>')
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
<div class="g">{cells}</div>
<h2>The ones that changed most</h2>{close}
<h2>The set together: on paper, in dark, in one colour for lists, and at 17 points</h2>
<div class="strip" style="background:#F2ECDD">{light}</div><div class="strip" style="background:#14110F">{dark}</div>
<div class="strip" style="background:#FBF6E9">{mono}</div><div class="strip">{tiny}</div>
<h2>In place: tiles on Today, and a list in History</h2>{context}</body></html>'''
    with open(os.path.join(OUT, 'refined.html'), 'w') as out: out.write(html)
    print(len(ICONS), 'icons')


if __name__ == '__main__':
    main()
