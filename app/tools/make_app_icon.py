"""The app icon, from Puggle's rig (14 November 2026).

Puggle's face on Wattle, as an Icon Composer document: Puggle/Resources/AppIcon.icon. The layers are taken
from her rig (Puggle/Resources/Rigs/puggle.rig.json), so the icon has the face the app has: the lick of hair,
the eyebrows, the oval cheeks, the smaller bill and the flower clip.

Four groups, front to back, so each part still reads when iOS takes the colour away (the clear and tinted looks):

    clip      the flower
    features  eyes, eyebrows and cheeks. No glass: they stay crisp.
    bill
    head      the head and the lick of hair

Her outline is the coloured one the app uses: each shape edged in a darker shade of itself, not in ink.
In dark, the ground goes deep brown.

It also writes the still pictures of her in the asset catalogue (PuggleMark, PuggleFace, PuggleStill), so the
lock screen, the splash, Help and the stamps show the same face.

Run `python3 tools/make_app_icon.py` from app/. With `--render` it also asks Apple's ictool (inside Xcode's
Icon Composer) to draw every look into docs/previews/app-icon/.
"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
RIG = os.path.join(HERE, '..', 'Puggle', 'Resources', 'Rigs', 'puggle.rig.json')
ICON = os.path.join(HERE, '..', 'Puggle', 'Resources', 'AppIcon.icon')
OUT = os.path.join(HERE, '..', '..', 'docs', 'previews', 'app-icon')
ICTOOL = '/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool'
BOX = '25 7 190 190'   # the head, with room for the flower
# The ground: its colour, and what it becomes in dark. `--ground sky` or `--ground blue` tries another.
GROUNDS = {'wattle': ('#F4BE2C', '#3A2A20'), 'sky': ('#BFD9F5', '#1F3246'), 'blue': ('#2A62B8', '#16284A')}
# Icon Composer cuts an outline off at the edge of the shape it belongs to. Two specks in the corners, too faint
# to see, make each layer as big as the whole picture, so nothing is cut.
SPECKS = ('<rect x="25" y="7" width="1" height="1" fill="#000000" fill-opacity="0.02"/>'
          '<rect x="214" y="196" width="1" height="1" fill="#000000" fill-opacity="0.02"/>')

GROUPS = [   # front to back: name, the rig's parts, glass
    ('clip', ['clip'], True),
    ('features', ['blush', 'eye-left', 'eye-right', 'brow-left', 'brow-right'], False),
    ('bill', ['bill'], True),
    ('head', ['head', 'lick'], True),
]


def draw(shape, line):
    """One of the rig's shapes as SVG. An outline is drawn as the app draws it: in the shape's own darker colour
    (its `tint`), not in ink, and about three-quarters as heavy. `line` 'ink' gives the old dark outline."""
    stroke, width = shape.get('stroke'), shape.get('width', 1)
    if stroke and shape.get('tint') and line != 'ink':
        stroke, width = shape['tint'], round(width * 0.74, 2)
    paint = f'fill="{shape.get("fill", "none")}"'
    if stroke:
        paint += f' stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"'
        if shape.get('cap'): paint += f' stroke-linecap="{shape["cap"]}"'
    if shape.get('rotate'):
        paint += f' transform="rotate({shape["rotate"]} {shape["x"]} {shape["y"]})"'
    if shape['kind'] == 'ellipse':
        return f'<ellipse cx="{shape["x"]}" cy="{shape["y"]}" rx="{shape["rx"]}" ry="{shape["ry"]}" {paint}/>'
    if shape['kind'] == 'rect':
        return f'<rect x="{shape["x"]}" y="{shape["y"]}" width="{shape["w"]}" height="{shape["h"]}" rx="{shape.get("r", 0)}" {paint}/>'
    if shape['kind'] == 'path':
        return f'<path d="{shape["d"]}" {paint}/>'
    raise ValueError(shape['kind'])


def layer(parts, ids, line='tint'):
    inner = ''.join(f'<g id="{pid}">' + ''.join(draw(s, line) for s in parts[pid]['shapes']) + '</g>' for pid in ids)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{BOX}" width="1024" height="1024">{SPECKS}{inner}</svg>'


def colour(hex_):
    return 'srgb:' + ','.join(f'{int(hex_[i:i + 2], 16) / 255:.5f}' for i in (1, 3, 5)) + ',1.00000'


def showing(part, face):
    """Whether a part is drawn with this face, by the rig's own rule: every condition in `when` must hold."""
    for condition in (part.get('when') or '').split('&'):
        if '=' in condition:
            key, values = condition.split('=')
            if face.get(key) not in values.split('|'): return False
    return True


def stills(rig):
    """The still pictures of Puggle in the asset catalogue, from the same rig: her mark (the face on a Wattle
    tile, on the lock screen, the splash and in Help), her face alone (on stamps) and her standing."""
    catalogue = os.path.join(HERE, '..', 'Puggle', 'Resources', 'Assets.xcassets')
    def save(name, text):
        open(os.path.join(catalogue, f'{name}.imageset', f'{name}.svg'), 'w').write(text)
    def drawn(face, only=None):
        return ''.join(''.join(draw(s, 'tint') for s in p['shapes']) for p in rig['parts']
                       if showing(p, face) and (only is None or p['id'] in only))
    # The mark and the face match the app icon: her resting face, with her eyebrows.
    head = {pid for _, ids, _ in GROUPS for pid in ids}
    face = drawn(dict(rig['face'], brows='on'), head)
    save('PuggleFace', f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{BOX}" width="190" height="190">{face}</svg>')
    save('PuggleMark', '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 132 132" width="132" height="132"><rect width="132" height="132" rx="30" fill="#F4BE2C"/>'
                       f'<g transform="translate(-9.6 1.7) scale(0.63)">{face}</g></svg>')
    width, height = rig['size']
    save('PuggleStill', f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width * 2}" height="{height * 2}">{drawn(rig["face"])}</svg>')
    print('wrote PuggleMark, PuggleFace and PuggleStill')


def option(name, default):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def main():
    global ICON, OUT
    ICON, OUT = option('--icon', ICON), option('--out', OUT)
    light, dark = GROUNDS[option('--ground', 'wattle')]
    # Flat is Tom's choice: glass washed her outline out. `--glass` puts it back on the head, bill and clip.
    flat = '--glass' not in sys.argv
    rig = json.load(open(RIG))
    parts = {p['id']: p for p in rig['parts']}
    if '--icon' not in sys.argv: stills(rig)
    assets = os.path.join(ICON, 'Assets')
    os.makedirs(assets, exist_ok=True)
    for old in os.listdir(assets): os.remove(os.path.join(assets, old))
    groups = []
    for name, ids, glass in GROUPS:
        open(os.path.join(assets, f'{name}.svg'), 'w').write(layer(parts, ids, option('--line', 'tint')))
        glass = glass and not flat
        # A property that changes with the look is a list: the plain value first, then one for each look.
        groups.append({
            'layers': [{'image-name': f'{name}.svg', 'name': name, 'glass': glass}],
            'shadow': {'kind': 'neutral', 'opacity': 0.5 if glass else 0.0},
            'translucency': {'enabled': False, 'value': 0.5},
        })
    doc = {'fill-specializations': [{'value': {'solid': colour(light)}}, {'appearance': 'dark', 'value': {'solid': colour(dark)}}],
           'groups': groups, 'supported-platforms': {'squares': 'shared'}}
    json.dump(doc, open(os.path.join(ICON, 'icon.json'), 'w'), indent=2)
    print('wrote', ICON)
    if '--render' in sys.argv:
        os.makedirs(OUT, exist_ok=True)
        for look in ('Default', 'Dark', 'ClearLight', 'ClearDark', 'TintedLight', 'TintedDark'):
            target = os.path.join(OUT, f'{look}.png')
            done = subprocess.run([ICTOOL, ICON, '--export-image', '--output-file', target, '--platform', 'iOS',
                                   '--rendition', look, '--width', '512', '--height', '512', '--scale', '2'],
                                  capture_output=True, text=True)
            print(look, 'ok' if done.returncode == 0 else done.stderr.strip() or done.stdout.strip())


if __name__ == '__main__':
    main()
