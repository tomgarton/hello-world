"""A lap for the grown-ups, for sitting in a chair seen from the front (Tom, 19 November 2026).

Seen from the front, someone sitting has their thighs coming towards you: what shows is their knees,
round and a little wider than their legs, and they are lower than when standing, with their feet
poking out underneath. The cast is drawn standing, so each grown-up gets one more part, "lap": a knee on
each leg in whatever covers their thighs (trousers, shorts, a skirt, a dress, an apron), drawn over their
legs and under their arms. And while sitting their upper half comes down onto it (`sitting`, a pose the
app adds). Both happen only while the face says "seat=sitting", so standing is unchanged.

Used by make_cast_rigs.py. The knees are the garment's own colour, so the wardrobe's colour swaps
change them with the rest of the outfit. Puggle's own rig is drawn by hand, so her lap is added to it
in place: `python3 tools/sitting_lap.py puggle` from app/ (run again after her rig changes; it replaces
the lap it added before). Her dress ends at her hips, so her knees are her own colour.

Everything is in proportion to the leg, from the hip to the ankle, so it fits any size of character.
"""
import json, os, sys

# What covers their thighs, by outfit: the garment ('c'), the trim ('t'), or a colour of its own.
CHINO = '#D3BE97'
COVER = {
    ('mum', ''): 'c', ('mum', 'skirt'): 't', ('mum', 'trousers'): 't',
    ('dad', ''): 't', ('dad', 'jumper'): 't', ('dad', 'overalls'): 't',
    ('nan', ''): 'c', ('nan', 'apron'): 't', ('nan', 'skirt'): 't',
    ('pop', ''): CHINO, ('pop', 'waistcoat'): 't', ('pop', 'jumper'): 't',
}
INK = '#3A2A20'
# As parts of the leg's length, from the hip to the ankle: how far their upper half comes down when they
# sit, where the knee starts above the hip's new place, and how deep it is.
DROP, KNEE_TOP, KNEE_DEPTH = 0.48, 0.28, 0.76


def knee(cx, top, half, depth, r):
    """A knee from the front: flat across the top where it meets the lap, round below."""
    left, right, bottom = cx - half, cx + half, top + depth
    return (f'M{left:.1f} {top:.1f} L{right:.1f} {top:.1f} L{right:.1f} {bottom - r:.1f} '
            f'Q{right:.1f} {bottom:.1f} {right - r:.1f} {bottom:.1f} L{left + r:.1f} {bottom:.1f} '
            f'Q{left:.1f} {bottom:.1f} {left:.1f} {bottom - r:.1f} Z')


def add_lap(rig, kind, variant, garment, trim, shade):
    """Adds the "lap" part to a grown-up's rig, just above their legs and hips in the drawing order."""
    cover = COVER.get((kind, variant))
    if cover is None:
        return rig
    fill = {'c': garment, 't': trim}.get(cover, cover)
    return lap(rig, fill, shade(fill))


def friend_lap(rig, shade):
    """A friend's lap. With legs of their own, their knees are their fur, below clothes that end at the hips.
    In dungarees, drawn down to their feet with no legs, the knees are the dungarees' colour, over the bottom of
    them, and they stay at their height: brought down, the dungarees would cover their feet."""
    by_id = {p['id']: p for p in rig['parts']}
    if 'leg-left' in by_id:
        leg = by_id['leg-left']['shapes'][0]
        return lap(rig, leg['fill'], leg.get('tint') or shade(leg['fill']), half=16)
    if 'foot-left' not in by_id or 'upper' not in by_id:
        return rig
    # The lowest filled shape of the upper half is the dungarees' legs.
    def bottom(shape):
        import re
        if shape.get('kind') != 'path' or not shape.get('fill'):
            return -1
        return max(float(v) for v in re.findall(r'-?[\d.]+', shape['d'])[1::2])
    cloth = max(by_id['upper']['shapes'], key=bottom)
    ankle = by_id['foot-left']['pivot'][1]
    legs = (by_id['foot-left']['pivot'][0], by_id['foot-right']['pivot'][0], ankle - 32, ankle)
    return lap(rig, cloth['fill'], cloth.get('tint') or shade(cloth['fill']), half=16, legs=legs, drop=0)


def lap(rig, fill, tint, half=21, legs=None, drop=None):
    """The lap itself: a knee on each leg in `fill`, outlined in `tint`, and the upper half's drop.
    `legs` gives the left and right leg's x, the hip and the ankle where a rig has no leg parts."""
    parts = [p for p in rig['parts'] if p['id'] != 'lap']
    by_id = {p['id']: p for p in parts}
    if legs is None:
        if 'leg-left' not in by_id or 'leg-right' not in by_id:
            return rig
        legs = (by_id['leg-left']['pivot'][0], by_id['leg-right']['pivot'][0],
                by_id['leg-left']['pivot'][1], by_id['foot-left']['pivot'][1])
    left_x, right_x, hip, ankle = legs
    leg = ankle - hip
    drop = round(DROP * leg, 1) if drop is None else drop
    shapes = []
    for side in ('left', 'right'):
        cx = left_x if side == 'left' else right_x
        # Each knee a little wider than the leg, the two just apart, from the hips to where the shin begins.
        cx += -2 if side == 'left' else 2
        shapes.append({'kind': 'path', 'd': knee(cx, hip + drop - KNEE_TOP * leg, half, KNEE_DEPTH * leg, min(17, half - 3)),
                       'fill': fill, 'stroke': INK, 'tint': tint, 'width': 7 if half > 18 else 6})
    part = {'id': 'lap', 'parent': 'body', 'pivot': [rig['size'][0] / 2, hip], 'when': 'seat=sitting', 'shapes': shapes}
    # Over the hips and the trouser legs, under the arms and anything held.
    at = next(i for i, p in enumerate(parts) if p['id'] == 'upper') + 1
    while at < len(parts) and parts[at]['id'] in ('dress', 'coat', 'pyjamas') or (at < len(parts) and parts[at]['id'].startswith('trouser-')):
        at += 1
    parts.insert(at, part)
    rig['parts'] = parts
    if drop:
        rig['sitting'] = {'upper': {'y': drop}}
    return rig


if __name__ == '__main__' and sys.argv[1:] == ['puggle']:
    # Puggle's own rig: her knees are her legs' colour, below a dress that ends at her hips.
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, '..', 'Puggle', 'Resources', 'Rigs', 'puggle.rig.json')
    rig = json.load(open(path))
    leg = next(p for p in rig['parts'] if p['id'] == 'leg-left')['shapes'][0]
    rig = lap(rig, leg['fill'], leg['tint'], half=16)
    with open(path, 'w') as out:
        json.dump(rig, out, indent=1, ensure_ascii=False)
    print('puggle: lap added')
