import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, BL, ST, p, head, limb, body, bill_open, wrap, dot, blush = [x[k] for k in ('O', 'PF', 'BILL', 'BL', 'ST', 'p', 'head', 'limb', 'body', 'bill_open', 'wrap', 'dot', 'blush')]
small = x['small']
J = '#2A62B8'
def cheek(cx, cy, r=10):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{BL}"></circle><path d="M{cx-7} {cy+5}l5-9M{cx+2} {cy+5}l5-9" stroke="{ST}" stroke-width="3.500" stroke-linecap="round"></path>'
def legs_feet(xs, dx=0):
    return ''.join(f'<rect x="{x0-4}" y="244" width="28" height="34" rx="11" fill="{PF}" stroke="{O}" stroke-width="6"></rect><ellipse cx="{x0+10+dx}" cy="282" rx="24" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' for x0 in xs)
front = body('down', 'neutral', J)
three = (f'<ellipse cx="60" cy="246" rx="34" ry="15" transform="rotate(28 60 246)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' + legs_feet((88, 124), 6) +
         f'<path d="M84 166Q116 156 150 166L176 244Q178 254 166 254L72 254Q60 254 62 244Z" fill="{J}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path><path d="M106 210h40v9a20 16 0 0 1-40 0z" fill="none" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>' +
         limb(86, 178, 54, 214, J, 4) + limb(148, 178, 180, 214, J, -4) +
         f'<ellipse cx="114" cy="108" rx="68" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>' + cheek(66, 128) + cheek(164, 126, 8) +
         f'<ellipse cx="146" cy="151" rx="44" ry="18" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="148" cy="143" r="1.8" fill="{O}"></circle><circle cx="160" cy="143" r="1.8" fill="{O}"></circle>' +
         dot(99, 108) + dot(146, 106, 6.4))
side = (f'<ellipse cx="54" cy="240" rx="40" ry="14" transform="rotate(22 54 240)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' + legs_feet((102,), 12) +
        f'<path d="M92 166Q118 158 144 166L160 244Q162 254 150 254L84 254Q72 254 74 244Z" fill="{J}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>' +
        limb(122, 178, 136, 224, J, -4) +
        f'<ellipse cx="108" cy="108" rx="62" ry="58" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>' +
        cheek(112, 130) + f'<ellipse cx="164" cy="150" rx="40" ry="18" transform="rotate(-4 164 150)" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="186" cy="141" r="1.8" fill="{O}"></circle>' +
        dot(142, 108))
back = (legs_feet((90, 130)) + p['trap'](J) + limb(88, 178, 50, 214, J, 4) + limb(152, 178, 190, 214, J, -4) +
        f'<ellipse cx="120" cy="250" rx="24" ry="34" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' +
        f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>')
views = [('Front', front), ('Three-quarter', three), ('Side', side), ('Back', back)]
guides = ''.join(f'<path d="M0 {y}H1000" stroke="#C9B89F" stroke-width="1.500" stroke-dasharray="6 6"></path>' for y in (48, 168, 254, 292))
turn = f'<svg role="img" aria-label="Puggle turnaround: front, three-quarter, side and back" width="980" height="300" viewBox="0 30 1000 290">{guides}' + ''.join(f'<g transform="translate({i*250+5} 0)">{v}</g>' for i, (n, v) in enumerate(views)) + '</svg>'
labels = ''.join(f'<div style="width: 245px; font-size: 14px; font-weight: 700; text-align: center">{n}</div>' for n, v in views)
sw = [('Fur', PF), ('Bill and feet', BILL), ('Outline', O), ('Blush', BL), ('Stitches', ST), ('Jumper (varies)', J)]
swatches = ''.join(f'<div style="display: flex; align-items: center; gap: 8px"><div style="width: 30px; height: 30px; border-radius: 15px; background: {c}; border: 2px solid {O}; box-sizing: border-box"></div><div style="display: flex; flex-direction: column"><div style="font-size: 13px; font-weight: 800">{n}</div><div style="font-size: 12px; font-weight: 500; color: #4A3B30; font-variant-numeric: tabular-nums">{c}</div></div></div>' for n, c in sw)
H = f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
B0 = f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>'
donts = [('Mouth', H + blush(127, 53) + B0 + dot(93, 108) + dot(147, 108) + f'<path d="M106 156Q120 165 134 156" fill="none" stroke="#4E5D69" stroke-width="4" stroke-linecap="round"></path>'),
         ('Brows', H + blush(127, 53) + B0 + dot(93, 108) + dot(147, 108) + f'<path d="M80 90L104 86M136 86L160 90" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'),
         ('Open bill', H + blush(127, 53) + bill_open(14) + dot(93, 104, 9) + dot(147, 104, 9)),
         ('Recolouring', H.replace(PF, '#C9A06A') + blush(127, 53) + B0.replace(BILL, '#F4BE2C') + dot(93, 108) + dot(147, 108))]
X = '<path d="M172 14L212 54M212 14L172 54" stroke="#C24A36" stroke-width="8" stroke-linecap="round"></path>'
dont_html = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 96px; height: 90px; background: #FBF6E9; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="Do not draw: {n}" width="88" height="84" viewBox="34 8 190 180">{s}{X}</svg></div><div style="font-size: 12px; font-weight: 700">No {n.lower()}</div></div>' for n, s in donts)
bodyh = f'''<div style="width: 1080px; height: 720px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle model sheet</h1><div style="font-size: 14px; font-weight: 600; color: #4A3B30">About 2½ heads tall. Dashed lines: top of head, chin, hem, ground</div></div>
<div style="display: flex; flex-direction: column; gap: 4px">{turn}<div style="display: flex">{labels}</div></div>
<div style="display: flex; gap: 36px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 10px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Colours</div><div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 22px">{swatches}</div>
<div style="font-size: 13px; font-weight: 500; color: #4A3B30; max-width: 330px; line-height: 1.4">Line: head 7, body 6 to 7, details 4 to 5 (at 240 wide). Outline is warm brown, never black.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Never</div><div style="display: flex; gap: 12px">{dont_html}</div>
<div style="font-size: 13px; font-weight: 500; color: #4A3B30; max-width: 440px; line-height: 1.4">Also never: hands hidden in silhouette, arms straight up behind the head, dark patches on the face.</div></div>
<div style="display: flex; flex-direction: column; gap: 6px; width: 130px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Small sizes</div>
<svg role="img" aria-label="Puggle, small version" width="72" height="90" viewBox="0 0 240 300">{small(body('down', 'happy', J))}</svg>
<div style="font-size: 12px; font-weight: 500; color: #4A3B30; line-height: 1.35">Under 100 pt tall: plain blush, no nostrils or pocket, line a quarter heavier.</div></div>
</div>
</div>'''
wrap('Puggle model sheet', bodyh, 1080, 720, 'ModelSheet.dc.html', 18920)
