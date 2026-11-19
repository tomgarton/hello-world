"""A lap for the grown-ups, for sitting in a chair seen from the front (Tom, 19 November 2026).

Seen from the front, someone sitting has their thighs coming towards you: what shows is their knees,
round and a little wider than their legs, and they are lower than when standing, with their feet
poking out underneath. The cast is drawn standing, so each grown-up gets one more part, "lap": a knee on
each leg in whatever covers their thighs (trousers, shorts, a skirt, a dress, an apron), drawn over their
legs and under their arms. And while sitting their upper half comes down onto it (`sitting`, a pose the
app adds). Both happen only while the face says "seat=sitting", so standing is unchanged.

Used by make_cast_rigs.py. The knees are the garment's own colour, so the wardrobe's colour swaps
change them with the rest of the outfit.
"""

# What covers their thighs, by outfit: the garment ('c'), the trim ('t'), or a colour of its own.
CHINO = '#D3BE97'
COVER = {
    ('mum', ''): 'c', ('mum', 'skirt'): 't', ('mum', 'trousers'): 't',
    ('dad', ''): 't', ('dad', 'jumper'): 't', ('dad', 'overalls'): 't',
    ('nan', ''): 'c', ('nan', 'apron'): 't', ('nan', 'skirt'): 't',
    ('pop', ''): CHINO, ('pop', 'waistcoat'): 't', ('pop', 'jumper'): 't',
}
INK = '#3A2A20'
# How far their upper half comes down when they sit, in the drawing's units.
DROP = 24


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
    parts = rig['parts']
    legs = {p['id']: p for p in parts if p['id'] in ('leg-left', 'leg-right')}
    if len(legs) < 2:
        return rig
    hip = legs['leg-left']['pivot'][1]
    shapes = []
    for side in ('left', 'right'):
        cx = legs[f'leg-{side}']['pivot'][0]
        # Each knee a little wider than the leg, the two just apart, from the hips to where the shin begins.
        cx += -2 if side == 'left' else 2
        shapes.append({'kind': 'path', 'd': knee(cx, hip + DROP - 14, 21, 38, 17), 'fill': fill, 'stroke': INK,
                       'tint': shade(fill), 'width': 7})
    lap = {'id': 'lap', 'parent': 'body', 'pivot': [rig['size'][0] / 2, hip], 'when': 'seat=sitting', 'shapes': shapes}
    # Over the hips and the trouser legs, under the arms and anything held.
    at = next(i for i, p in enumerate(parts) if p['id'] == 'upper') + 1
    while at < len(parts) and parts[at]['id'].startswith('trouser-'):
        at += 1
    parts.insert(at, lap)
    rig['sitting'] = {'upper': {'y': DROP}}
    return rig
