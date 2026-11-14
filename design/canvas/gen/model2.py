import sys
ROOT = sys.argv[1]
sys.path.insert(0, ROOT + '/gen')
import rig
wsrc = open(ROOT + '/gen/world.py').read(); wsrc = wsrc[:wsrc.index('walls = f')]
w = {'__name__': 'x'}; exec(wsrc, w)
wrap = w['wrap']
INK, FUR, FURL, BILL, BILLL, J, JL, POCKET, BLUSH, MARK, CLIP, CLIPL = '#3A2A20', '#8A5A3C', '#5E3A24', '#6E7F8D', '#465668', '#2A62B8', '#1B4387', '#8FB4E3', '#C27C66', '#F2A892', '#E5553B', '#B23A26'
def foot(cx, rot=0):
    d = (f'M{cx-9} 273 L{cx+9} 273 Q{cx+20} 277 {cx+19} 285 Q{cx+19} 292 {cx+12.5} 291 Q{cx+9.5} 287 {cx+6.3} 291 Q{cx} 294 {cx-6.3} 291 Q{cx-9.5} 287 {cx-12.5} 291 Q{cx-19} 292 {cx-19} 285 Q{cx-20} 277 {cx-9} 273 Z')
    return (f'<g data-p="foot" transform="rotate({rot} {cx} 274)"><path d="{d}" fill="{BILL}" stroke="{BILLL}" stroke-width="5.5" stroke-linejoin="round"></path>'
            f'<path d="M{cx-6.3} 290 L{cx-4.7} 283 M{cx+6.3} 290 L{cx+4.7} 283" stroke="{BILLL}" stroke-width="2.4" stroke-linecap="round" fill="none"></path></g>')
def leg(x): return f'<rect x="{x-14}" y="244" width="28" height="34" rx="11" fill="{FUR}" stroke="{FURL}" stroke-width="6"></rect>'
def tail(cx, cy, rot, rx=34):
    return (f'<g data-p="tail" transform="rotate({rot} {cx} {cy})"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="15" fill="{FUR}" stroke="{FURL}" stroke-width="6"></ellipse>'
            f'<path d="M{cx-8} {cy-8} Q{cx-4} {cy} {cx-8} {cy+8} M{cx+7} {cy-9} Q{cx+12} {cy} {cx+7} {cy+9} M{cx-14} {cy} L{cx+19} {cy}" stroke="{FURL}" stroke-width="2.5" stroke-linecap="round" fill="none"></path></g>')
def limb(x0, y0, x1, y1, bend=0):
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    dx, dy = y1 - y0, x0 - x1
    n = (dx * dx + dy * dy) ** 0.5 or 1
    cx, cy = mx + dx / n * bend, my + dy / n * bend
    tx, ty = x1 - cx, y1 - cy
    tn = (tx * tx + ty * ty) ** 0.5 or 1
    ux, uy = tx / tn, ty / tn
    ex, ey = x1 - ux * 8, y1 - uy * 8
    kx, ky = x1 - ux * 12, y1 - uy * 12
    return (f'<path d="M{x0} {y0}Q{cx:.1f} {cy:.1f} {ex:.1f} {ey:.1f}" fill="none" stroke="{JL}" stroke-width="34" stroke-linecap="round"></path>'
            f'<path d="M{x0} {y0}Q{cx:.1f} {cy:.1f} {x1} {y1}" fill="none" stroke="{J}" stroke-width="22" stroke-linecap="round"></path>'
            f'<path d="M{kx - uy*11:.1f} {ky + ux*11:.1f}L{kx + uy*11:.1f} {ky - ux*11:.1f}" stroke="{JL}" stroke-width="4" stroke-linecap="round"></path>'
            f'<circle cx="{x1}" cy="{y1}" r="12.5" fill="{FUR}" stroke="{FURL}" stroke-width="5"></circle>')
def eye(x, y, r=6.8): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}"></circle>'
def cheek(x, y, rx=12): return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="7.5" fill="{BLUSH}"></ellipse>'
def clip(cx, cy, s=1):
    pet = ''.join(f'<circle cx="{cx+dx*s}" cy="{cy+dy*s}" r="{12.6*s}" fill="{CLIP}" stroke="{CLIPL}" stroke-width="5"></circle>' for dx, dy in ((-8.8, 0), (8.8, 0), (0, -8.8), (0, 8.8)))
    return pet + ''.join(f'<circle cx="{cx+dx*s}" cy="{cy+dy*s}" r="{10.1*s}" fill="{CLIP}"></circle>' for dx, dy in ((-8.8, 0), (8.8, 0), (0, -8.8), (0, 8.8), (0, 0))) + f'<circle cx="{cx}" cy="{cy}" r="{4.6*s}" fill="#F4C95D"></circle>'
front = rig.render()
three = (tail(60, 246, 28) + leg(104) + leg(140) + foot(108, 4) + foot(146, -6) +
         f'<path d="M84 166Q116 156 150 166L176 244Q178 254 166 254L72 254Q60 254 62 244Z" fill="{J}" stroke="{JL}" stroke-width="7" stroke-linejoin="round"></path><path d="M106 210 L146 210 L146 219 C146 240.3 106 240.3 106 219 Z" fill="{POCKET}" stroke="{JL}" stroke-width="5" stroke-linejoin="round"></path>' +
         limb(86, 178, 54, 214, 4) + limb(148, 178, 180, 214, -4) +
         f'<ellipse cx="114" cy="108" rx="68" ry="60" fill="{FUR}" stroke="{FURL}" stroke-width="7"></ellipse>' + cheek(70, 132) + cheek(170, 130, 6) +
         f'<ellipse cx="146" cy="151" rx="44" ry="18" fill="{BILL}" stroke="{BILLL}" stroke-width="6"></ellipse><circle cx="148" cy="143" r="1.8" fill="{INK}"></circle><circle cx="160" cy="143" r="1.8" fill="{INK}"></circle>' +
         eye(96, 117) + eye(154, 115, 5.8) + clip(164, 58, 0.94))
side = (tail(54, 240, 22, 40) + leg(116) + foot(126, 0) +
        f'<path d="M92 166Q118 158 144 166L160 244Q162 254 150 254L84 254Q72 254 74 244Z" fill="{J}" stroke="{JL}" stroke-width="7" stroke-linejoin="round"></path>' +
        limb(122, 178, 136, 224, -4) +
        f'<ellipse cx="108" cy="108" rx="62" ry="58" fill="{FUR}" stroke="{FURL}" stroke-width="7"></ellipse>' +
        cheek(116, 133) + f'<ellipse cx="164" cy="150" rx="40" ry="18" transform="rotate(-4 164 150)" fill="{BILL}" stroke="{BILLL}" stroke-width="6"></ellipse><circle cx="186" cy="141" r="1.8" fill="{INK}"></circle>' +
        eye(146, 116) + clip(132, 52, 0.9))
back = (leg(100) + leg(140) + foot(100, 7) + foot(140, -7) +
        f'<path d="M88 166 Q120 156 152 166 L180 244 Q182 254 170 254 L70 254 Q58 254 60 244 Z" fill="{J}" stroke="{JL}" stroke-width="7" stroke-linejoin="round"></path>' + limb(88, 178, 50, 214, 4) + limb(152, 178, 190, 214, -4) +
        f'<g data-p="tail"><ellipse cx="120" cy="250" rx="24" ry="34" fill="{FUR}" stroke="{FURL}" stroke-width="6"></ellipse><path d="M110 240 Q120 244 130 240 M109 256 Q120 261 131 256 M120 226 L120 272" stroke="{FURL}" stroke-width="2.5" stroke-linecap="round" fill="none"></path></g>' +
        f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{FUR}" stroke="{FURL}" stroke-width="7"></ellipse>' + clip(80, 60))
views = [('Front (from the app)', front), ('Three-quarter', three), ('Side', side), ('Back', back)]
guides = ''.join(f'<path d="M0 {y}H1000" stroke="#C9B89F" stroke-width="1.5" stroke-dasharray="6 6"></path>' for y in (48, 168, 254, 292))
turn = f'<svg role="img" aria-label="Puggle turnaround: front, three-quarter, side and back" width="980" height="290" viewBox="0 20 1000 296">{guides}' + ''.join(f'<g data-v="{i}" transform="translate({i*250+5} 0)">{v}</g>' for i, (n, v) in enumerate(views)) + '</svg>'
labels = ''.join(f'<div style="width: 245px; font-size: 14px; font-weight: 700; text-align: center">{n}</div>' for n, v in views)
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
def tile(name, svg, note='', vb='28 4 190 184', wd=104, ht=100, bg='#FBF6E9'):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: {wd+8}px"><div style="width: {wd}px; height: {ht}px; background: {bg}; display: flex; align-items: center; justify-content: center">'
            f'<svg role="img" aria-label="Puggle: {name}" width="{wd-6}" height="{ht-6}" viewBox="{vb}">{svg}</svg></div><div style="font-size: 13px; font-weight: 700; text-align: center">{name}</div>'
            + (f'<div style="font-size: 11.5px; font-weight: 500; color: #4A3B30; text-align: center; line-height: 1.3">{note}</div>' if note else '') + '</div>')
soft = {'brow-left': {'y': 1, 'r': -14}, 'brow-right': {'y': 1, 'r': 14}}
up = {'brow-left': {'y': -4, 'r': -6}, 'brow-right': {'y': -4, 'r': 6}}
big = {'blush': {'sx': 1.14, 'sy': 1.14}}
FACES = [('At rest', rig.render(), 'Dot eyes, plain cheeks, no brows'),
         ('Delight', rig.render(face={'brows': 'on'}, pose=up), 'Brows raised'),
         ('Happy', rig.render(face={'eyes': 'happy', 'brows': 'on'}, pose={**up, **big}), 'Arc eyes, cheeks a little bigger'),
         ('Pleased', rig.render(face={'eyes': 'happy', 'brows': 'on', 'cheeks': 'shy'}, pose={**soft, **big}), 'Soft brows, marks on her cheeks'),
         ('Squeezed shut', rig.render(face={'eyes': 'squeeze', 'brows': 'on'}, pose={**up, **big}), 'Top of a hop, a stretch'),
         ('Wide awake', rig.render(face={'brows': 'on'}, pose={**up, 'eye-left': {'sx': 1.18, 'sy': 1.18}, 'eye-right': {'sx': 1.18, 'sy': 1.18}}), 'Eyes a touch bigger'),
         ('Asleep', rig.render(**rig.ASLEEP), 'Closed eyes, soft brows, Zs')]
faces = ''.join(tile(n, s, note) for n, s, note in FACES)
MOVES = [('nod', 0.0, 'Nod', 'An everyday save'), ('greet', 0.52, 'Hello', 'Opening the app'), ('proud', 0.44, 'Proud', 'A potty success'),
         ('celebrate', 0.12, 'Celebrate', 'A milestone. Rare'), ('wake', 0.2, 'Wake', 'A sleep ended'), (None, 0, 'Asleep', 'A sleep is running')]
moves = ''.join(tile(n, rig.render(**(rig.key(m, t) if m else rig.ASLEEP)), note, vb='-10 -24 260 330', wd=118, ht=146) for m, t, n, note in MOVES)
LINES = [('Coloured line', rig.render(), 'The look. Each line is a darker shade of its own colour', '#FBF6E9'),
         ('Dark line', rig.render(style='ink'), 'App icon and small marks only, if they need the contrast', '#FBF6E9'),
         ('By moonlight', rig.render(moonlit=True), 'Cooler, leaning violet. Still her own colours', '#2B2F5E')]
lines = ''.join(tile(n, s, note, vb='-10 -24 260 330', wd=118, ht=146, bg=bg) for n, s, note, bg in LINES)
OUT = [('Rain', 'rain', 'Coat and boots'), ('Cold', 'warm', 'Scarf and beanie'), ('Heat', 'sun', 'Straw hat and zinc')]
outfits = ''.join(tile(n, rig.render(face={'outfit': o}), note, vb='-10 -24 260 330', wd=118, ht=146) for n, o, note in OUT)
sw = [('Fur', FUR, FURL), ('Bill and feet', BILL, BILLL), ('Dress', J, JL), ('Pocket', POCKET, JL), ('Clip', CLIP, CLIPL), ('Cheeks', BLUSH, None), ('Cheek marks', MARK, None), ('Eyes, nostrils', INK, None)]
swatches = ''.join(f'<div style="display: flex; align-items: center; gap: 8px"><div style="width: 30px; height: 30px; border-radius: 15px; background: {c}; border: 4px solid {l or c}; box-sizing: border-box"></div><div style="display: flex; flex-direction: column"><div style="font-size: 13px; font-weight: 800">{n}</div><div style="font-size: 12px; font-weight: 500; color: #4A3B30; font-variant-numeric: tabular-nums">{c}' + (f', line {l}' if l else '') + '</div></div></div>' for n, c, l in sw)
X = '<path d="M172 14L212 54M212 14L172 54" stroke="#C24A36" stroke-width="8" stroke-linecap="round"></path>'
mouth = f'<path d="M106 157Q120 166 134 157" fill="none" stroke="#3A4651" stroke-width="4" stroke-linecap="round"></path>'
angry = f'<path d="M78 98L98 106M162 98L142 106" stroke="{FURL}" stroke-width="4" stroke-linecap="round"></path>'
recol = rig.render().replace(FUR, '#C9A06A').replace(BILL, '#F4BE2C')
donts = [('No mouth', rig.render() + mouth), ('No frowning brows', rig.render() + angry), ('No recolouring', recol), ('No black line', rig.render(style='ink').replace(INK, '#000000'))]
dont_html = ''.join(tile(n, s + X, vb='28 4 196 184', wd=100, ht=92) for n, s in donts)
small = rig.render(skip=('shy',)).replace('<ellipse cx="114" cy="143" rx="1.8" ry="1.8" fill="#3A2A20"></ellipse>', '').replace('<ellipse cx="126" cy="143" rx="1.8" ry="1.8" fill="#3A2A20"></ellipse>', '')
import re
small = re.sub(r'<path d="M100 210 L140 210[^>]*></path>', '', small)
small = re.sub(r'stroke-width="([\d.]+)"', lambda m: 'stroke-width="%.1f"' % (float(m.group(1)) * (1.25 if float(m.group(1)) < 12 else 1.06)), small)
bodyh = f'''<div style="width: 1080px; height: 1450px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle model sheet</h1><div style="font-size: 14px; font-weight: 600; color: #4A3B30">As built in the app, 12 November 2026. About 2½ heads tall</div></div>
<div style="{T}; max-width: 980px">The front view, faces, moves and outfits below are drawn from the app's own file of her parts, so this sheet and the app cannot drift apart. What changed from the sheet before: coloured lines, eyes lower, wider apart and a little smaller, soft oval cheeks, a light blue pocket, webbed feet, markings on her tail, a yellow centre in her clip, and eyebrows that appear only with a feeling.</div>
<div style="display: flex; flex-direction: column; gap: 4px">{turn}<div style="display: flex">{labels}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Faces: eyes, eyebrows and cheeks show the feeling. The bill never changes. No mouth</div><div style="display: flex; gap: 14px">{faces}</div></div>
<div style="display: flex; gap: 40px"><div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Moves: the pose each one holds</div><div style="display: flex; gap: 10px">{moves}</div></div></div>
<div style="display: flex; gap: 44px"><div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Line and light</div><div style="display: flex; gap: 10px">{lines}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Dressed for the weather</div><div style="display: flex; gap: 10px">{outfits}</div></div>
<div style="display: flex; flex-direction: column; gap: 6px; width: 150px"><div style="{H}">Small sizes</div>
<svg role="img" aria-label="Puggle, small version" width="72" height="90" viewBox="0 0 240 300">{small}</svg>
<div style="font-size: 12px; font-weight: 500; color: #4A3B30; line-height: 1.35">Under 100 pt tall: no nostrils or pocket, line a quarter heavier.</div></div></div>
<div style="display: flex; gap: 40px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Colours, each with its line</div><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 22px">{swatches}</div>
<div style="{T}; max-width: 400px">Line weight: head and dress 7, bill, legs and tail 6, details 4 to 5 (at 240 wide). Cheeks and inside shapes have no line. Dark brown is kept for eyes and nostrils.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Never</div><div style="display: flex; gap: 10px">{dont_html}</div>
<div style="{T}; max-width: 460px">Eyebrows are off at rest and come in only with a move: raised for delight, soft for content and sleepy. Never angry, sad or worried. Also never: an open or bent bill, hands hidden in silhouette, dark patches on the face.</div></div>
</div>
</div>'''
wrap('Puggle model sheet', bodyh, 1080, 1450, 'ModelSheet.dc.html', 18920)
