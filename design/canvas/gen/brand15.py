"""Two boards for the brand page (15 November 2026): the app icon and the activity icons, both drawn from the
app's own sources so the canvas matches what ships.

    python3 brand15.py .. /path/to/hello-world

The second argument is the repo, for docs/tools/make_icons.py, make_icons_large.py and app/tools/make_app_icon.py.
"""
import sys, os, json
ROOT, REPO = sys.argv[1], sys.argv[2]
sys.path[:0] = [ROOT + '/gen', REPO + '/docs/tools', REPO + '/app/tools']
import make_icons as mi, make_icons_large as ml, make_app_icon as ai
wsrc = open(ROOT + '/gen/world.py').read(); wsrc = wsrc[:wsrc.index('walls = f')]
w = {'__name__': 'x'}; exec(wsrc, w)
wrap = w['wrap']

H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
T = 'font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.4'
PAGE = "box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px"

def pic(svg, label):
    """An icon tool's SVG, made ready for the canvas: closed tags and a name for screen readers."""
    import re
    svg = re.sub(r'<(path|rect|circle|ellipse)([^>]*?)/>', r'<\1\2></\1>', svg)
    return svg.replace('<svg xmlns="http://www.w3.org/2000/svg"', f'<svg role="img" aria-label="{label}"', 1)

def name(n): return n.replace('-', ' ').capitalize()
def tile(inner, label='', size=76, bg='#FBF6E9', note=''):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: {size + 8}px"><div style="width: {size}px; height: {size}px; border-radius: 18px; background: {bg}; display: flex; align-items: center; justify-content: center">{inner}</div>'
            + (f'<div style="font-size: 12px; font-weight: 700; text-align: center">{label}</div>' if label else '')
            + (f'<div style="font-size: 11.5px; font-weight: 500; color: #4A3B30; text-align: center; line-height: 1.3">{note}</div>' if note else '') + '</div>')

# ---- Activity icons
reg = lambda n, size=44, **k: pic(mi.svg(n, spec=mi.regular(n), size=size, **k), name(n))
everything = ''.join(tile(reg(n), name(n)) for n in mi.ICONS)
def sizes(n):
    small = pic(mi.svg(n, size=24), name(n) + ', small')
    large = pic(ml.art(ml.LARGE[n][0], size=96) if n in ml.LARGE else '', name(n) + ', large') if n in ml.LARGE else ''
    return (f'<div style="display: flex; align-items: flex-end; gap: 10px">{tile(small, "Small", 44)}{tile(reg(n, 40), "Regular", 64)}'
            + (tile(large, "Large", 112) if large else '') + '</div>')
recolour = lambda s, c: s.replace(mi.WATTLE, c)
SIX = ['bottle', 'sleep', 'nappy', 'bath', 'breastfeed', 'pump']
def row(colour, keep=()):
    return ''.join(tile(reg(n) if n in keep else recolour(reg(n), colour), size=60) for n in SIX)
colours = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px"><div style="font-size: 13px; font-weight: 800">{t}</div><div style="display: flex; gap: 2px">{r}</div><div style="{T}; font-size: 12.5px; max-width: 420px">{note}</div></div>' for t, r, note in [
    ('Wattle, the default', row(mi.WATTLE), 'One accent fill in each drawing. Everything else is line.'),
    ('A colour of your own', row('#3C9A5F'), 'Chosen in Settings, Appearance. Gum is shown.'),
    ("The child's colour", row('#E5553B', keep=('pump',)), "On a tile or log for one child. Pumping is the parent's, so it stays Wattle."),
    ('Fixed colours never change', ''.join(tile(reg(n), size=60) for n in ['breastfeed', 'poo', 'wee', 'medicine', 'temperature', 'vaccine']), 'Skin, poo, wee and anything with a real colour keep it in every setting.')])
def dark(n):
    spec = mi.regular(n); spec = dict(spec, weight=spec['weight'] * mi.DARK_LINE, fineweight=spec['fineweight'] * mi.DARK_LINE)
    return pic(mi.svg(n, spec=spec, ink=mi.DARK, size=44), name(n) + ', in dark')
darks = ''.join(tile(dark(n), size=64, bg='#2A2420') for n in ['bottle', 'sleep', 'nappy', 'potty', 'bath', 'solids', 'weight', 'play', 'tummy-time', 'teeth'])
alt = lambda spec, size=64: pic(mi.svg('x', spec=spec, size=size), 'Breastfeeding')
alts = ''.join(tile(alt(spec), title, 96) for key, (spec, title, text) in mi.ALTERNATES.items())
tones = ''.join(tile(alt(mi.breast(a, b), 44), size=60) for a, b in mi.TONES)
icons = f'''<div style="width: 1080px; height: 1290px; {PAGE}">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Activity icons</h1><div style="font-size: 14px; font-weight: 600; color: #4A3B30">As built in the app, 15 November 2026</div></div>
<div style="{T}; max-width: 960px">Twenty-two drawings in one hand: a round-ended line in Ink, soft corners, and one flat fill. Objects have no faces. A baby in a drawing has one dot eye and hair, nothing more. These replace “Activity icons, rounded” on the App page.</div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">The set, at the regular size</div><div style="display: flex; flex-wrap: wrap; gap: 10px 5px">{everything}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Three sizes of drawing</div>
<div style="display: flex; gap: 36px">{sizes('bath')}{sizes('potty')}{sizes('solids')}</div>
<div style="{T}; max-width: 960px">Small, for lists and menus under 24 points: the fewest shapes and a 2 point line. Regular, for tiles from 32 points: the same shapes, a finer line and a little more detail. Large, for where a drawing stands alone: drawn on a 48 grid. The large drawings are not in the app yet.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Colour</div><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px 40px">{colours}</div></div>
<div style="display: flex; gap: 40px"><div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">In dark</div><div style="display: flex; gap: 2px">{darks}</div>
<div style="{T}; max-width: 700px">The line turns pale and is drawn a fifth thinner, because a pale line on a dark ground looks heavier. Fixed colours are dimmed a little so the line still shows against them.</div></div></div>
<div style="display: flex; gap: 40px"><div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Breastfeeding: five drawings to choose from</div><div style="display: flex; gap: 6px">{alts}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Skin tones</div><div style="display: flex; gap: 2px">{tones}</div>
<div style="{T}; font-size: 12.5px; max-width: 330px">For an app offered in many countries. The choices and tones are drawn, with no setting in the app yet.</div></div></div>
</div>'''
wrap('Activity icons', icons, 1080, 1290, 'ActivityIcons.dc.html', 4890, tinted=False)

# ---- App icon
rig = json.load(open(REPO + '/app/Puggle/Resources/Rigs/puggle.rig.json'))
parts = {p['id']: p for p in rig['parts']}
face = ''.join(''.join(ai.draw(s, 'tint') for s in parts[pid]['shapes']) for _, ids, _ in reversed(ai.GROUPS) for pid in ids)
face = __import__('re').sub(r'<(path|rect|circle|ellipse)([^>]*?)/>', r'<\1\2></\1>', face)
def app_icon(ground, size, label):
    return (f'<svg role="img" aria-label="{label}" width="{size}" height="{size}" viewBox="0 0 190 190"><rect width="190" height="190" rx="42" fill="{ground}"></rect>'
            f'<g transform="translate(-25 -7)">{face}</g></svg>')
light, darkg = ai.GROUNDS['wattle']
def shown(svg, label, note):
    return f'<div style="display: flex; flex-direction: column; gap: 8px; width: 230px">{svg}<div style="font-size: 15px; font-weight: 800">{label}</div><div style="{T}; font-size: 13px">{note}</div></div>'
small_row = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{app_icon(light, s, "App icon at %d points" % s)}<div style="font-size: 12px; font-weight: 600; color: #4A3B30">{s}</div></div>' for s in (60, 40, 29))
appicon = f'''<div style="width: 1080px; height: 570px; {PAGE}">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">App icon</h1><div style="font-size: 14px; font-weight: 600; color: #4A3B30">As built in the app, 15 November 2026</div></div>
<div style="{T}; max-width: 960px">Her face on Wattle, taken from the app's own file of her parts: the lick of hair, the eyebrows, the oval cheeks and the flower clip. The line is the coloured one, each shape edged in a darker shade of itself. It is flat, with no glass, which washed the line out.</div>
<div style="display: flex; gap: 40px; align-items: flex-start">
{shown(app_icon(light, 220, 'App icon, light'), 'Light', 'Wattle ground, #F4BE2C.')}
{shown(app_icon(darkg, 220, 'App icon, dark'), 'Dark', 'The ground goes deep brown, #3A2A20. Her colours stay as they are.')}
<div style="display: flex; flex-direction: column; gap: 14px; width: 420px">
<div style="{H}">Clear and tinted</div>
<div style="{T}">iOS makes these looks itself by taking the colour away, so the icon is built in four layers that still read in one colour: the clip, then eyes, eyebrows and cheeks, then the bill, then the head and hair.</div>
<div style="{H}">Small sizes</div>
<div style="display: flex; gap: 18px; align-items: flex-end">{small_row}</div>
<div style="{H}">The same face elsewhere</div>
<div style="{T}">The lock screen, the splash, Help and the stamps use the same drawing, so they change when she does. Her face here has eyebrows; at rest in the app she has none.</div>
</div></div>
</div>'''
wrap('App icon', appicon, 1080, 570, 'AppIcon.dc.html', 1660, tinted=False)
