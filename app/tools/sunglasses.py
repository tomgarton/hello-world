"""Sunglasses for every rig, as parts that can be switched.

Each style is one part, shown while the face has `shades=<style>` ("none" is no sunglasses). They are drawn just
after the eyes, so eyebrows and hats stay on top of them. Each part has a `lift`: how far it slides up onto the
forehead while she is reacting, so that her eyes, which carry her feelings, are never hidden when it matters.

Eight at an ordinary size and five big ones:

    round-dark (the default)   aviator-mirror   aviator-dark   round-mirror   square-dark   hearts-dark   flowers-dark
    round-tinted (amber, with her eyes showing through: this one is drawn under the eyes)
    big-sunset   big-night   big-mirror   big-aviator   big-sea

Frames are in the character's own accent colour unless the style has its own (metal, gold, wattle). Every colour
is one step off the brand's, so that swapping a garment's colour never repaints a pair of sunglasses.

Run from app/ as `python3 tools/sunglasses.py` for Puggle. make_cast_rigs.py calls wear() for everyone else.
"""
import json, os

RIGS = os.path.join(os.path.dirname(__file__), '..', 'Puggle', 'Resources', 'Rigs')
INK = '#3A2A20'
STYLES = ['round-dark', 'aviator-mirror', 'aviator-dark', 'round-mirror', 'square-dark', 'hearts-dark', 'flowers-dark', 'round-tinted',
          'big-sunset', 'big-night', 'big-mirror', 'big-aviator', 'big-sea']
K = 1.28           # the ordinary ones: a little bigger than a pair of spectacles
LIFT, BIG_LIFT = 38, 43


def off(colour):
    """The same colour to the eye, one step away, so a colour swap never finds it."""
    value = int(colour[1:], 16)
    return '#%06X' % (value + 1 if value & 0xFF < 0xFF else value - 1)


NIGHT, MIRROR, GLINT, METAL, GOLD, AMBER = (off(c) for c in ('#1B2440', '#C5D2DE', '#F3F7FA', '#8491A0', '#D9A441', '#E3B062'))


def n(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def lens(shape, x, y, out):
    k = K
    if shape == 'square':
        return {'kind': 'rect', 'x': round(x - 15 * k, 1), 'y': round(y - 12.5 * k, 1), 'w': round(30 * k, 1), 'h': round(25 * k, 1), 'r': round(8 * k, 1)}
    if shape == 'aviator':
        o = out
        return {'kind': 'path', 'd': f'M{n(x - o * 14 * k)} {n(y - 9 * k)} Q{n(x)} {n(y - 12 * k)} {n(x + o * 16 * k)} {n(y - 9 * k)} '
                                     f'Q{n(x + o * 19 * k)} {n(y + 6 * k)} {n(x + o * 5 * k)} {n(y + 14 * k)} '
                                     f'Q{n(x - o * 11 * k)} {n(y + 15 * k)} {n(x - o * 14 * k)} {n(y - 9 * k)} Z'}
    if shape == 'heart':
        return {'kind': 'path', 'd': f'M{n(x)} {n(y + 13 * k)} C{n(x - 22 * k)} {n(y - k)} {n(x - 11 * k)} {n(y - 17 * k)} {n(x)} {n(y - 6 * k)} '
                                     f'C{n(x + 11 * k)} {n(y - 17 * k)} {n(x + 22 * k)} {n(y - k)} {n(x)} {n(y + 13 * k)} Z'}
    return {'kind': 'ellipse', 'x': x, 'y': y, 'rx': round(14.5 * k, 1), 'ry': round(14.5 * k, 1)}


def pair(shape, x, y, colour, glass, wide, twin=False, shine=False):
    """Two lenses, a bridge and two arms, about the middle of the face (x is the left eye)."""
    k, other = K, 240 - x
    half = {'round': 14.5, 'square': 15, 'aviator': 14, 'heart': 15}[shape] * k
    shapes = []
    for cx, out in ((x, -1), (other, 1)):
        shapes.append(dict(lens(shape, cx, y, out), fill=glass, stroke=INK, tint=colour, width=wide))
    def line(d, w=wide): return {'kind': 'path', 'd': d, 'stroke': INK, 'tint': colour, 'width': w, 'cap': 'round'}
    shapes.append(line(f'M{n(x + half)} {n(y)} Q120 {n(y - 7 * k)} {n(other - half)} {n(y)}'))
    shapes.append(line(f'M{n(x - half)} {n(y - 2)} L{n(x - half - 17)} {n(y - 8)} M{n(other + half)} {n(y - 2)} L{n(other + half + 17)} {n(y - 8)}'))
    if twin:   # the second bar across the top of an aviator's bridge
        shapes.append(line(f'M{n(x + 13 * k)} {n(y - 8 * k)} L{n(other - 13 * k)} {n(y - 8 * k)}'))
    if shine:  # a flat mirror: two glints on each lens
        for cx in (x, other):
            shapes.append({'kind': 'path', 'd': f'M{n(cx - 8 * k)} {n(y + 2 * k)} L{n(cx)} {n(y - 7 * k)}', 'stroke': GLINT, 'width': 3.6, 'cap': 'round'})
            shapes.append({'kind': 'path', 'd': f'M{n(cx - k)} {n(y + 5 * k)} L{n(cx + 5 * k)} {n(y - 2 * k)}', 'stroke': GLINT, 'width': 2.6, 'cap': 'round'})
    return shapes


def darker(colour, by=0.68):
    value = int(colour[1:], 16)
    return '#%02X%02X%02X' % tuple(int(((value >> shift) & 0xFF) * by) for shift in (16, 8, 0))


def flowers(x, y, colour, glass):
    """A flower for each eye: five round petals in the frame's colour, joined as one shape, with a round dark lens
    in the middle."""
    import math
    other, reach, petal, line = 240 - x, 10.5, 9.0, darker(colour)
    shapes = []
    for cx in (x, other):
        spots = [(cx + reach * math.sin(math.radians(turn)), y - reach * math.cos(math.radians(turn))) for turn in range(0, 360, 72)]
        # One flower, one outline: every petal's line first, then every petal's colour over the joins.
        shapes += [{'kind': 'ellipse', 'x': round(px, 1), 'y': round(py, 1), 'rx': petal, 'ry': petal, 'fill': colour, 'stroke': INK, 'tint': line, 'width': 4} for px, py in spots]
        shapes += [{'kind': 'ellipse', 'x': round(px, 1), 'y': round(py, 1), 'rx': petal - 1.5, 'ry': petal - 1.5, 'fill': colour} for px, py in spots]
        shapes.append({'kind': 'ellipse', 'x': cx, 'y': y, 'rx': 11, 'ry': 11, 'fill': glass, 'stroke': INK, 'tint': line, 'width': 3})
    half = reach + petal - 2
    def bar(d): return {'kind': 'path', 'd': d, 'stroke': INK, 'tint': line, 'width': 5, 'cap': 'round'}
    shapes.insert(0, bar(f'M{n(x + half)} {n(y)} Q120 {n(y - 7)} {n(other - half)} {n(y)}'))
    shapes.insert(0, bar(f'M{n(x - half)} {n(y - 2)} L{n(x - half - 17)} {n(y - 8)} M{n(other + half)} {n(y - 2)} L{n(other + half + 17)} {n(y - 8)}'))
    return shapes


def big(shape, x, y, colour, top, bottom):
    """Far too big for the face: a heavy bar across the brow, no rim below, and lenses in two flat bands."""
    other, r = 240 - x, 25.0
    shapes = []
    for cx, o in ((x, -1), (other, 1)):
        if shape == 'aviator':
            whole = (f'M{n(cx - o * 22)} {n(y - 16)} Q{n(cx)} {n(y - 21)} {n(cx + o * 26)} {n(y - 16)} Q{n(cx + o * 31)} {n(y + 10)} {n(cx + o * 9)} {n(y + 25)} '
                     f'Q{n(cx - o * 18)} {n(y + 27)} {n(cx - o * 22)} {n(y - 16)} Z')
            lower = (f'M{n(cx - o * 20)} {n(y + 3)} L{n(cx + o * 27)} {n(y + 3)} Q{n(cx + o * 25)} {n(y + 15)} {n(cx + o * 9)} {n(y + 25)} '
                     f'Q{n(cx - o * 15)} {n(y + 27)} {n(cx - o * 20)} {n(y + 3)} Z')
            shapes += [{'kind': 'path', 'd': whole, 'fill': top}, {'kind': 'path', 'd': lower, 'fill': bottom},
                       {'kind': 'path', 'd': whole, 'stroke': INK, 'tint': colour, 'width': 4}]
        else:
            shapes += [{'kind': 'ellipse', 'x': cx, 'y': y, 'rx': r, 'ry': r, 'fill': top},
                       {'kind': 'path', 'd': f'M{n(cx - r)} {n(y + 2)} C{n(cx - r)} {n(y + 2 + r * 1.3)} {n(cx + r)} {n(y + 2 + r * 1.3)} {n(cx + r)} {n(y + 2)} Z', 'fill': bottom},
                       {'kind': 'path', 'd': f'M{n(cx - r)} {n(y - 1)} C{n(cx - r)} {n(y - 1 - r * 1.34)} {n(cx + r)} {n(y - 1 - r * 1.34)} {n(cx + r)} {n(y - 1)}',
                        'stroke': INK, 'tint': colour, 'width': 8, 'cap': 'round'}]
    reach = 22.0 if shape == 'aviator' else r
    shapes.append({'kind': 'path', 'd': f'M{n(x + reach - 4)} {n(y - 15)} L{n(other - reach + 4)} {n(y - 15)}', 'stroke': INK, 'tint': colour,
                   'width': 4 if shape == 'aviator' else 8, 'cap': 'round'})
    return shapes


def wear(parts, accent):
    """Every style of sunglasses added to this character, each as its own part. Safe to run again."""
    parts = [p for p in parts if not p['id'].startswith('sunnies-')]
    eye = next(p for p in parts if p['id'] == 'eye-left')
    x, y = eye['pivot'][0], eye['pivot'][1]
    accent = off(accent)
    drawn = {
        'round-dark': pair('round', x, y + 2, accent, NIGHT, 5.5),
        'aviator-mirror': pair('aviator', x, y + 4, METAL, MIRROR, 4, twin=True, shine=True),
        'aviator-dark': pair('aviator', x, y + 4, GOLD, NIGHT, 4, twin=True),
        'round-mirror': pair('round', x, y + 2, accent, MIRROR, 5.5, shine=True),
        'square-dark': pair('square', x, y + 2, accent, NIGHT, 5.5),
        'hearts-dark': pair('heart', x, y + 2, accent, NIGHT, 5),
        'flowers-dark': flowers(x, y + 2, accent, NIGHT),
        'round-tinted': pair('round', x, y + 2, accent, AMBER, 5.5),
        'big-sunset': big('round', x, y + 5, accent, off('#E5553B'), off('#F4BE2C')),
        'big-night': big('round', x, y + 5, accent, NIGHT, off('#3D4F86')),
        'big-mirror': big('round', x, y + 5, METAL, off('#9DB2C6'), off('#DDE7EF')),
        'big-aviator': big('aviator', x, y + 5, METAL, off('#9DB2C6'), off('#DDE7EF')),
        'big-sea': big('round', x, y + 5, off('#F4BE2C'), off('#2A62B8'), off('#BFD9F5')),
    }
    def part(style):
        return {'id': f'sunnies-{style}', 'parent': 'head', 'pivot': [120, y], 'spring': 150, 'when': f'shades={style}',
                'lift': BIG_LIFT if style.startswith('big-') else LIFT, 'shapes': drawn[style]}
    # Tinted lenses go under the eyes, so the eyes show through; every other pair goes straight over them.
    under = next(i for i, p in enumerate(parts) if p['id'] == 'eye-left')
    parts = parts[:under] + [part('round-tinted')] + parts[under:]
    over = next(i for i, p in enumerate(parts) if p['id'] == 'eye-right') + 1
    return parts[:over] + [part(s) for s in STYLES if s != 'round-tinted'] + parts[over:]


def main():
    path = os.path.join(RIGS, 'puggle.rig.json')
    rig = json.load(open(path))
    rig['parts'] = wear(rig['parts'], '#E5553B')
    rig['face']['shades'] = 'none'
    with open(path, 'w') as out:
        json.dump(rig, out, indent=1, ensure_ascii=False)
    print('puggle', len(rig['parts']), 'parts')


if __name__ == '__main__':
    main()
