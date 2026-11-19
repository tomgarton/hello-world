"""The little things in the air around a face: Zs, sparkles, hearts, notes, a "!" and a "?", the same for everyone (Tom, 20 November 2026).

Zs drift up beside anyone asleep, and sparkles twinkle round anyone celebrating. They used to be drawn on
Puggle alone, so a friend or a grown-up dozing had none. Now every rig gets the same parts, the same size,
colour and place beside the face: measured from the middle of the eyes and carried by the head, so they
tilt with it. The app moves them (`RigRuntime`), so they move the same way for everyone too.

Used by make_cast_rigs.py. Puggle's own rig is drawn by hand, so hers are put in place:
`python3 tools/air.py puggle` from app/ (it replaces the ones it put there before).
"""
import json, os, re, sys

ZED = '#8FA3D6'
GOLD = '#F4C95D'


def star(cx, cy, r):
    """A four-pointed sparkle, its sides drawn in."""
    k = r * 0.22
    return (f'M{cx:g} {cy - r:g} Q{cx + k:g} {cy - k:g} {cx + r:g} {cy:g} Q{cx + k:g} {cy + k:g} {cx:g} {cy + r:g} '
            f'Q{cx - k:g} {cy + k:g} {cx - r:g} {cy:g} Q{cx - k:g} {cy - k:g} {cx:g} {cy - r:g} Z')


def zed(cx, cy, half):
    return f'M{cx - half:g} {cy - half:g} L{cx + half:g} {cy - half:g} L{cx - half:g} {cy + half:g} L{cx + half:g} {cy + half:g}'


def heart(cx, cy, r):
    return (f'M{cx:g} {cy + r * 0.9:g} C{cx - r * 1.3:g} {cy + r * 0.1:g} {cx - r * 0.7:g} {cy - r * 0.9:g} {cx:g} {cy - r * 0.35:g} '
            f'C{cx + r * 0.7:g} {cy - r * 0.9:g} {cx + r * 1.3:g} {cy + r * 0.1:g} {cx:g} {cy + r * 0.9:g} Z')


def note(x, y, colour, size=1.0):
    """A quaver: a round head, a stem and its flag."""
    s = size
    return [{'kind': 'ellipse', 'x': x, 'y': y, 'rx': round(5.2 * s, 1), 'ry': round(4 * s, 1), 'fill': colour},
            {'kind': 'path', 'd': f'M{x + 4.6 * s:g} {y:g} L{x + 4.6 * s:g} {y - 17 * s:g} Q{x + 11 * s:g} {y - 13 * s:g} {x + 11 * s:g} {y - 6 * s:g}',
             'stroke': colour, 'width': round(2.4 * s, 1), 'cap': 'round'}]


def mark(x, y, colour, question):
    """A "!" or a "?", drawn as a line and a dot."""
    line = (f'M{x - 6:g} {y - 8:g} Q{x - 6:g} {y - 15:g} {x:g} {y - 15:g} Q{x + 7:g} {y - 15:g} {x + 7:g} {y - 8:g} '
            f'Q{x + 7:g} {y - 3:g} {x:g} {y:g} L{x:g} {y + 2:g}') if question else f'M{x:g} {y - 14:g} L{x:g} {y + 2:g}'
    return [{'kind': 'path', 'd': line, 'stroke': colour, 'width': 3.6, 'cap': 'round'},
            {'kind': 'ellipse', 'x': x, 'y': y + 9, 'rx': 2.3, 'ry': 2.3, 'fill': colour}]


PINK = '#E5727F'
LILAC = '#8C7BC4'
RED = '#E5553B'

# Where each sits from the middle of the eyes, in drawing units (everyone is drawn at Puggle's scale), as on her.
AIR = [
    ('zed-a', 'zzz', 76, -71, 40, lambda x, y: {'kind': 'path', 'd': zed(x, y, 5.5), 'stroke': ZED, 'width': 3.3, 'cap': 'round'}),
    ('zed-b', 'zzz', 94, -93, 30, lambda x, y: {'kind': 'path', 'd': zed(x, y, 4), 'stroke': ZED, 'width': 2.4, 'cap': 'round'}),
    ('sparkle-a', 'sparkle', -82, -55, 120, lambda x, y: {'kind': 'path', 'd': star(x, y, 11), 'fill': GOLD}),
    ('sparkle-b', 'sparkle', 92, -13, 90, lambda x, y: {'kind': 'path', 'd': star(x, y, 8), 'fill': GOLD}),
    ('sparkle-c', 'sparkle', -54, -95, 150, lambda x, y: {'kind': 'path', 'd': star(x, y, 6.5), 'fill': GOLD}),
    # Love: a hug, a friend answering her. Two hearts rising.
    ('heart-a', 'heart', 72, -80, 60, lambda x, y: {'kind': 'path', 'd': heart(x, y, 11), 'fill': PINK}),
    ('heart-b', 'heart', 94, -54, 60, lambda x, y: {'kind': 'path', 'd': heart(x, y, 7), 'fill': PINK}),
    # Humming as they play: two notes.
    ('note-a', 'notes', 74, -72, 50, lambda x, y: note(x, y, LILAC)),
    ('note-b', 'notes', 98, -50, 50, lambda x, y: note(x, y, LILAC, 0.75)),
    # Startled, waking with a jump: a "!".
    ('oh-a', 'oh', 66, -88, 200, lambda x, y: mark(x, y, RED, False)),
    # Wondering, watching something: a "?".
    ('wonder-a', 'wonder', 68, -88, 80, lambda x, y: mark(x, y, ZED, True)),
]
IDS = {a[0] for a in AIR}


def add_air(rig):
    """Puts the Zs and sparkles on a rig with two eyes and a head, in place of any it had."""
    parts = [p for p in rig['parts'] if p['id'] not in IDS]
    by_id = {p['id']: p for p in parts}
    if not {'eye-left', 'eye-right', 'head'} <= by_id.keys():
        return rig
    ex = (by_id['eye-left']['pivot'][0] + by_id['eye-right']['pivot'][0]) / 2
    ey = (by_id['eye-left']['pivot'][1] + by_id['eye-right']['pivot'][1]) / 2
    for part_id, when, dx, dy, spring, shape in AIR:
        x, y = round(ex + dx, 1), round(ey + dy, 1)
        shapes = shape(x, y)
        parts.append({'id': part_id, 'parent': 'head', 'pivot': [x, y], 'when': f'air={when}', 'spring': spring,
                      'shapes': shapes if isinstance(shapes, list) else [shapes]})
    rig['parts'] = parts
    return rig


if __name__ == '__main__' and sys.argv[1:] == ['puggle']:
    here = os.path.dirname(os.path.abspath(__file__))
    for path in (os.path.join(here, '..', 'Puggle', 'Resources', 'Rigs', 'puggle.rig.json'),
                 os.path.join(here, '..', '..', 'design', 'canvas', 'gen', 'puggle.rig.json')):
        if not os.path.exists(path):
            continue
        rig = add_air(json.load(open(path)))
        with open(path, 'w') as out:
            json.dump(rig, out, indent=1, ensure_ascii=False)
        print('puggle: air added', os.path.relpath(path))
