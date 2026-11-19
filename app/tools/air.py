"""The little things in the air around a face, the same for everyone (Tom, 20 November 2026).

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


# Where each sits from the middle of the eyes, in drawing units (everyone is drawn at Puggle's scale), as on her.
AIR = [
    ('zed-a', 'zzz', 76, -71, 40, lambda x, y: {'kind': 'path', 'd': zed(x, y, 5.5), 'stroke': ZED, 'width': 3.3, 'cap': 'round'}),
    ('zed-b', 'zzz', 94, -93, 30, lambda x, y: {'kind': 'path', 'd': zed(x, y, 4), 'stroke': ZED, 'width': 2.4, 'cap': 'round'}),
    ('sparkle-a', 'sparkle', -82, -55, 120, lambda x, y: {'kind': 'path', 'd': star(x, y, 11), 'fill': GOLD}),
    ('sparkle-b', 'sparkle', 92, -13, 90, lambda x, y: {'kind': 'path', 'd': star(x, y, 8), 'fill': GOLD}),
    ('sparkle-c', 'sparkle', -54, -95, 150, lambda x, y: {'kind': 'path', 'd': star(x, y, 6.5), 'fill': GOLD}),
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
        parts.append({'id': part_id, 'parent': 'head', 'pivot': [x, y], 'when': f'air={when}', 'spring': spring,
                      'shapes': [shape(x, y)]})
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
