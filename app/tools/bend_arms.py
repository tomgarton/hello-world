"""Arms that bend at the elbow, for every rig.

An arm used to be one part: a curve from the shoulder to the hand. Here it is cut in two at the middle of
that curve, so the forearm can turn about the elbow. At rest it draws exactly as it did before.

One arm, one outline: the two halves' outlines are painted first and their sleeve colour after, so a bent
elbow has no line across it. That needs four parts in this order:

    arm-left            the upper arm's outline          turns about the shoulder
    forearm-left        the forearm's outline            turns about the elbow, carried by arm-left
    arm-left-top        the upper arm's colour
    forearm-left-top    the forearm's colour, cuff, hand

A second copy of the forearm is drawn after the head, shown only while a move sets "arms=front": that is how
her hands come in front of her face for "Oh!" (hands to her cheeks). Everywhere else arms stay behind the head.

Run from app/ as `python3 tools/bend_arms.py` to bend Puggle's own rig and give her the arm moves.
make_cast_rigs.py calls bend() and arm_moves() for everyone else.
"""
import json, math, re, os

RIGS = os.path.join(os.path.dirname(__file__), '..', 'Puggle', 'Resources', 'Rigs')
ARM = re.compile(r'^(coat-|pyjama-)?arm-(left|right)$')


def numbers(d):
    return [float(n) for n in re.findall(r'-?\d+\.?\d*', d)]


def fmt(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def at(curve, t):
    p0, c, p1 = curve
    return [(1 - t) ** 2 * p0[i] + 2 * t * (1 - t) * c[i] + t * t * p1[i] for i in (0, 1)]


def piece(curve, t0, t1):
    """The stretch of a quadratic curve between two points along it, as a path."""
    p0, c, p1 = curve
    control = [(1 - t0) * (1 - t1) * p0[i] + ((1 - t0) * t1 + t0 * (1 - t1)) * c[i] + t0 * t1 * p1[i] for i in (0, 1)]
    a, b = at(curve, t0), at(curve, t1)
    return f'M{fmt(a[0])} {fmt(a[1])} Q{fmt(control[0])} {fmt(control[1])} {fmt(b[0])} {fmt(b[1])}'


def both(when, more):
    return f'{when}&{more}' if when else more


def bend(parts):
    """Every arm cut at the elbow. Safe to run on parts that are already bent."""
    if any(p['id'].startswith('forearm-') for p in parts): return parts
    out, front = [], []
    for part in parts:
        match = ARM.match(part['id'])
        kinds = [s['kind'] for s in part['shapes']]
        if match and kinds == ['path', 'path', 'path', 'ellipse']:
            side = match.group(2)
            dark, sleeve, cuff, hand = part['shapes']
            n = numbers(sleeve['d'])
            curve = (n[0:2], n[2:4], n[4:6])
            # The outline stops a little short of the hand: find how far along the sleeve that is.
            stop = numbers(dark['d'])[4:6]
            reach = min(range(50, 101), key=lambda k: math.dist(at(curve, k / 100), stop)) / 100
            elbow = [round(v, 1) for v in at(curve, 0.5)]
            fore = part['id'].replace('arm-', 'forearm-')
            # A coat's or pyjamas' sleeve rides the plain arm underneath it.
            carried = part['id'] if not match.group(1) else f'forearm-{side}'
            when = part.get('when')

            def made(id, parent, pivot, shapes, spring=None, cond=when):
                new = {'id': id, 'parent': parent, 'pivot': pivot}
                if spring is not None: new['spring'] = spring
                if cond: new['when'] = cond
                new['shapes'] = shapes
                return new

            upper_line = dict(dark, d=piece(curve, 0, 0.5))
            fore_line = dict(dark, d=piece(curve, 0.5, reach))
            upper_fill = dict(sleeve, d=piece(curve, 0, 0.5))
            fore_fill = dict(sleeve, d=piece(curve, 0.5, 1))
            out.append(dict(part, shapes=[upper_line]))
            out.append(made(fore, carried, elbow, [fore_line], spring=170 if not match.group(1) else None))
            out.append(made(part['id'] + '-top', part['id'], part['pivot'], [upper_fill]))
            out.append(made(fore + '-top', fore, elbow, [fore_fill, cuff, hand]))
            ahead = both(when, 'arms=front')
            front.append(made(fore + '-front', fore, elbow, [dict(fore_line)], cond=ahead))
            front.append(made(part['id'] + '-front-top', part['id'], part['pivot'], [dict(sleeve, d=piece(curve, 0.3, 0.5))], cond=ahead))
            front.append(made(fore + '-front-top', fore, elbow, [dict(fore_fill), dict(cuff), dict(hand)], cond=ahead))
        elif part['id'].startswith('mitten-') and part.get('parent', '').startswith('arm-'):
            # A mitten is on the hand, so it goes with the forearm.
            side = part['id'].split('-')[1]
            mitten = dict(part, parent=f'forearm-{side}')
            out.append(mitten)
            front.append(dict(json.loads(json.dumps(mitten)), id=part['id'] + '-front', when=both(part.get('when'), 'arms=front')))
        else:
            out.append(part)
    # In front of the head and everything on it, but under an umbrella and the things in the air.
    last = next((i for i, p in enumerate(out) if p['id'] == 'umbrella' or p['id'].split('-')[0] in ('sparkle', 'zed', 'drop')), len(out))
    return out[:last] + front + out[last:]


# MARK: Poses

def joints(parts, side):
    """The shoulder, the elbow and the hand of one arm, as drawn."""
    by = {p['id']: p for p in parts}
    hand = next(s for s in by[f'forearm-{side}-top']['shapes'] if s['kind'] == 'ellipse')
    return by[f'arm-{side}']['pivot'], by[f'forearm-{side}']['pivot'], [hand['x'], hand['y']]


def reach(parts, side, target):
    """How far to turn the shoulder and the elbow, in degrees, to put this hand on a point. The elbow goes outward."""
    shoulder, elbow, hand = joints(parts, side)
    upper, fore = math.dist(shoulder, elbow), math.dist(elbow, hand)
    dx, dy = target[0] - shoulder[0], target[1] - shoulder[1]
    far = max(abs(upper - fore) + 0.5, min(upper + fore - 0.5, math.hypot(dx, dy)))
    toward = math.atan2(dy, dx)
    inside = math.acos(max(-1, min(1, (upper ** 2 + far ** 2 - fore ** 2) / (2 * upper * far))))
    best = None
    for sign in (1, -1):
        a1 = toward + sign * inside
        ex, ey = shoulder[0] + upper * math.cos(a1), shoulder[1] + upper * math.sin(a1)
        tx, ty = shoulder[0] + far * math.cos(toward), shoulder[1] + far * math.sin(toward)
        a2 = math.atan2(ty - ey, tx - ex)
        outward = -ex if side == 'left' else ex
        if best is None or outward > best[0]: best = (outward, a1, a2)
    _, a1, a2 = best
    rest1 = math.atan2(elbow[1] - shoulder[1], elbow[0] - shoulder[0])
    rest2 = math.atan2(hand[1] - elbow[1], hand[0] - elbow[0])

    def turn(angle):
        return round((math.degrees(angle) + 180) % 360 - 180, 1)
    return {f'arm-{side}': {'r': turn(a1 - rest1)}, f'forearm-{side}': {'r': turn((a2 - a1) - (rest2 - rest1))}}


def arms(parts, left, right):
    pose = {}
    pose.update(reach(parts, 'left', left))
    pose.update(reach(parts, 'right', right))
    return pose


def book_drop(parts):
    """How far below Puggle's the book is held. Hands rest at about four fifths of the arm's reach below the shoulder,
    so a grown-up's long arms hold it at the tummy with the elbows in, not at the chest with the elbows out wide."""
    shoulder, elbow, hand = joints(parts, 'left')
    length = math.dist(shoulder, elbow) + math.dist(elbow, hand)
    if length <= 70: return shoulder[1] - 178
    return round(shoulder[1] + 0.84 * length - 224, 1)


def book(parts):
    """A book held open in front of her, seen from its covers. It sits behind the arms, so her hands are on its edges."""
    drop = book_drop(parts)
    y = lambda v: fmt(v + drop)
    return {'id': 'book', 'parent': 'upper', 'pivot': [120, 222 + drop], 'when': 'holding=book', 'shapes': [
        {'kind': 'path', 'd': f'M78 {y(198)} L120 {y(205)} L162 {y(198)} L162 {y(240)} L120 {y(247)} L78 {y(240)} Z',
         'fill': '#E5553B', 'stroke': '#3A2A20', 'tint': '#B23A26', 'width': 5},
        {'kind': 'path', 'd': f'M120 {y(205)} L120 {y(247)}', 'stroke': '#B23A26', 'width': 3, 'cap': 'round'},
        {'kind': 'path', 'd': f'M82 {y(196)} L120 {y(202)} L158 {y(196)}', 'stroke': '#FBF6E9', 'width': 4, 'cap': 'round'},
        {'kind': 'ellipse', 'x': 141, 'y': 222 + drop, 'rx': 8, 'ry': 8, 'fill': '#F4BE2C'},
    ]}


def wand(parts):
    """A bubble wand in her right hand: a stick with a ring on the end. It goes with the forearm, under the hand."""
    _, elbow, hand = joints(parts, 'right')
    far = math.dist(elbow, hand)
    ux, uy = (hand[0] - elbow[0]) / far, (hand[1] - elbow[1]) / far
    tip = [hand[0] + ux * 24, hand[1] + uy * 24]
    ring = [round(hand[0] + ux * 34, 1), round(hand[1] + uy * 34, 1)]
    stick = f'M{fmt(hand[0])} {fmt(hand[1])} L{fmt(tip[0])} {fmt(tip[1])}'
    return {'id': 'wand', 'parent': 'forearm-right', 'pivot': hand, 'when': 'holding=wand', 'shapes': [
        {'kind': 'path', 'd': stick, 'stroke': '#3A2A20', 'tint': '#B8892A', 'width': 8, 'cap': 'round'},
        {'kind': 'ellipse', 'x': ring[0], 'y': ring[1], 'rx': 10, 'ry': 10, 'stroke': '#3A2A20', 'tint': '#B8892A', 'width': 8},
        {'kind': 'path', 'd': stick, 'stroke': '#F4BE2C', 'width': 4, 'cap': 'round'},
        {'kind': 'ellipse', 'x': ring[0], 'y': ring[1], 'rx': 10, 'ry': 10, 'stroke': '#F4BE2C', 'width': 4},
    ]}


def hold_in_hand(parts, prop):
    """Puts something in the right hand: drawn just under it, so the hand closes over it."""
    parts = [p for p in parts if p['id'] != prop['id']]
    first = next(i for i, p in enumerate(parts) if p['id'] == 'forearm-right-top')
    return parts[:first] + [prop] + parts[first:]


def raised(parts, lower=0):
    """The right arm held up and out, as for a wave: where the upper arm points, and the forearm at its highest and
    lowest, in degrees from straight out to the side (minus is up). A long arm is held lower, so the hand stays in the picture."""
    shoulder, elbow, hand = joints(parts, 'right')
    rest1 = math.degrees(math.atan2(elbow[1] - shoulder[1], elbow[0] - shoulder[0]))
    rest2 = math.degrees(math.atan2(hand[1] - elbow[1], hand[0] - elbow[0]))
    long = math.dist(shoulder, elbow) + math.dist(elbow, hand) > 70
    upper, high, low = (0, -60, -28) if long else (-15, -57, -23)
    # With something in the hand (a wand) the forearm stops lower, so it stays clear of the head.
    high, low = high + lower, low + lower
    def turns(fore):
        return {'arm-right': {'r': round(upper - rest1, 1)}, 'forearm-right': {'r': round((fore - upper) - (rest2 - rest1), 1)}}
    return turns(high), turns(low)


def rabbit():
    """Her toy rabbit, hugged to her chest. Puggle's only."""
    cloth, line, dark = '#FBF3E2', '#B9AE98', '#3A2A20'
    def oval(x, y, rx, ry, rotate=None):
        shape = {'kind': 'ellipse', 'x': x, 'y': y, 'rx': rx, 'ry': ry, 'fill': cloth, 'stroke': dark, 'tint': line, 'width': 4}
        if rotate is not None: shape['rotate'] = rotate
        return shape
    return {'id': 'rabbit', 'parent': 'upper', 'pivot': [120, 220], 'when': 'holding=rabbit', 'shapes': [
        oval(112, 186, 5, 13, -8), oval(128, 186, 5, 13, 10), oval(120, 232, 15, 15), oval(120, 207, 16, 14),
        {'kind': 'ellipse', 'x': 114, 'y': 205, 'rx': 1.9, 'ry': 1.9, 'fill': dark},
        {'kind': 'ellipse', 'x': 126, 'y': 205, 'rx': 1.9, 'ry': 1.9, 'fill': dark},
        {'kind': 'ellipse', 'x': 120, 'y': 210, 'rx': 2, 'ry': 1.5, 'fill': '#F2A48E'},
    ]}


def hold(parts, prop):
    """Puts something held just behind the arms."""
    parts = [p for p in parts if p['id'] != prop['id']]
    first = next(i for i, p in enumerate(parts) if p['id'] == 'arm-left')
    return parts[:first] + [prop] + parts[first:]


def arm_moves(parts, reads=True, hugs=False):
    """The moves that need an elbow, worked out for this character's own shoulders and arms."""
    ids = {p['id'] for p in parts}
    shoulder = joints(parts, 'left')[0]
    drop = shoulder[1] - 178
    # Every head is the same size and sits on the neck, so the cheeks are in the same place above the shoulders.
    neck = next(p for p in parts if p['id'] == 'head')['pivot'][1]
    cheeks = arms(parts, [59, neck - 21], [181, neck - 21])
    wide = {'sx': 1.18, 'sy': 1.18}
    up = {'brow-left': {'y': -4, 'r': -6}, 'brow-right': {'y': -4, 'r': 6}}

    def only(pose):
        return {k: v for k, v in pose.items() if k in ids}

    moves = {'oh': {
        'about': 'Oh! A small start, hands to her cheeks and clear of her bill, eyes wide. The one time her hands are in front of her head.',
        'exact': True, 'length': 1.4, 'keys': [
            {'t': 0, 'pose': only({'upper': {'sy': 0.95}})},
            {'t': 0.1, 'pose': only({**cheeks, 'body': {'y': -7}, 'upper': {'sy': 1.04}, 'eye-left': wide, 'eye-right': wide, **up}),
             'face': {'arms': 'front', 'brows': 'on'}},
            {'t': 0.26, 'pose': only({**cheeks, 'upper': {'sy': 1.02}, 'eye-left': wide, 'eye-right': wide, **up}),
             'face': {'arms': 'front', 'brows': 'on'}},
            {'t': 1.05, 'pose': {}, 'face': {'arms': 'front'}},
        ]}}
    if reads:
        held = 224 + book_drop(parts)
        on_book = arms(parts, [80, held], [160, held])
        down = {'head': {'y': 4}, 'eye-left': {'y': 3.5}, 'eye-right': {'y': 3.5}}
        # Turning a page: the right hand lifts off the edge and comes back.
        turning = json.loads(json.dumps(on_book))
        turning['forearm-right']['r'] += 22
        moves['read'] = {
            'about': 'Reading: a book held open at her chest, eyes down on it, a page turned now and then. Goes round until stopped.',
            'exact': True, 'loops': True, 'length': 7, 'keys': [
                {'t': 0, 'pose': only({**on_book, **down}), 'face': {'holding': 'book'}},
                {'t': 4.6, 'pose': only({**turning, **down, 'head': {'y': 4, 'r': 3}}), 'face': {'holding': 'book'}},
                {'t': 4.9, 'pose': only({**on_book, **down}), 'face': {'holding': 'book'}},
            ]}
    if 'wand' in ids:
        high, low = raised(parts, lower=16)
        watching = {'head': {'r': 4}, 'eye-left': {'x': 3, 'y': -2.5}, 'eye-right': {'x': 3, 'y': -2.5}, **up}
        face = {'holding': 'wand', 'brows': 'on'}
        moves['bubbles'] = {
            'about': 'Making bubbles: a wand held up in her right hand and swept slowly through the air, her eyes on it. No blowing: '
                     'the bubbles come off the wand as it moves. Goes round until stopped.',
            'exact': True, 'loops': True, 'length': 3.4, 'keys': [
                {'t': 0, 'pose': only({**low, **watching}), 'face': face},
                {'t': 0.9, 'pose': only({**high, **watching, 'head': {'r': 6}}), 'face': face},
                {'t': 2.3, 'pose': only({**low, **watching}), 'face': face},
            ]}
    if hugs:
        round_it = arms(parts, [100, 226], [140, 226])
        glad = {'blush': {'sx': 1.14, 'sy': 1.14}}
        face = {'holding': 'rabbit', 'eyes': 'happy', 'cheeks': 'shy'}
        moves['hug'] = {
            'about': 'A hug for her rabbit: both arms round it, a squeeze, and a sway from side to side.',
            'exact': True, 'length': 2.8, 'keys': [
                {'t': 0, 'pose': only({**round_it, **glad, 'head': {'r': -5}}), 'face': face},
                {'t': 0.5, 'pose': only({**round_it, **glad, 'head': {'r': -7}, 'upper': {'sx': 0.97, 'sy': 1.02}}), 'face': face},
                {'t': 1.2, 'pose': only({**round_it, **glad, 'head': {'r': 5}, 'upper': {'r': 2}}), 'face': face},
                {'t': 1.9, 'pose': only({**round_it, **glad, 'head': {'r': -5}, 'upper': {'r': -2}}), 'face': face},
                {'t': 2.5, 'pose': only({**round_it, **glad}), 'face': face},
            ]}
    return moves


def bend_wave(move, parts=None):
    """A wave from the elbow: the upper arm goes up and stays, and the forearm does the waving.

    Puggle's is written as plain turns (-58 at the shoulder; -42 and -8 at the elbow). With `parts`, the same
    wave is worked out for another character's arm, so a grown-up's long arm ends up beside the head too,
    and not out past the edge of the drawing.
    """
    up, back = {'arm-right': {'r': -58}, 'forearm-right': {'r': -42}}, {'arm-right': {'r': -58}, 'forearm-right': {'r': -8}}
    if parts is not None: new_up, new_back = raised(parts)
    for key in move['keys']:
        pose = key['pose']
        turn, fore = pose.get('arm-right', {}).get('r'), pose.get('forearm-right', {}).get('r')
        if turn == -80 or fore == -42: pose.update(new_up if parts is not None else up)
        elif turn == -60 or fore == -8: pose.update(new_back if parts is not None else back)
    return move


def main():
    path = os.path.join(RIGS, 'puggle.rig.json')
    rig = json.load(open(path))
    parts = bend(rig['parts'])
    parts = hold(hold(parts, rabbit()), book(parts))
    parts = hold_in_hand(parts, wand(parts))
    rig['parts'] = parts
    # Room at her sides for the wand, which reaches past the edge of her drawing.
    rig['sideroom'] = 30
    rig['moves']['greet'] = bend_wave(rig['moves']['greet'])
    rig['moves'].update(arm_moves(parts, hugs=True))
    with open(path, 'w') as out:
        json.dump(rig, out, indent=1, ensure_ascii=False)
    print('puggle', len(parts), 'parts;', ', '.join(rig['moves']))


if __name__ == '__main__':
    main()
