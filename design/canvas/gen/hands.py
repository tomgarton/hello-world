import sys, math
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, p, head, limb, sparkle, wrap = x['O'], x['PF'], x['BILL'], x['p'], x['head'], x['limb'], x['sparkle'], x['wrap']
TAN = '#B9845A'
def fig(arms, e, col, hand, foot, front=False, extra_back='', extra_front=''):
    L = ''.join(limb(a[0], a[1], a[2], a[3], col, a[4], hand=hand) for a in arms)
    base = p['tail'](PF) + p['legs'](PF) + p['feet'](foot) + extra_back + p['trap'](col) + p['pocket'](210, col)
    if front:
        hands = ''.join(f'<circle cx="{a[2]}" cy="{a[3]}" r="12" fill="{hand}" stroke="{O}" stroke-width="5"></circle>' for a in arms)
        return base + L + head(e) + hands + extra_front
    return base + L + head(e) + extra_front
WAVE = [(88, 178, 50, 214, 4), (152, 178, 206, 126, -8)]
waves = '<path d="M216 100q10 10 4 24M228 94q14 14 6 34" fill="none" stroke="#3A2A20" stroke-width="4" stroke-linecap="round"></path>'
opts = [('A. Fur-brown hands, slate feet', 'Hands match the body, so they read as paws. Feet stay slate, like webbed platypus feet, tying them to the bill.', PF, BILL, '#F4BE2C'),
        ('B. All fur-brown', 'Hands and feet both match the body. The calmest; the bill becomes the only slate shape.', PF, PF, '#CFE5D2'),
        ('C. Light tan hands and feet', 'A lighter warm tan, like paw pads. Hands stand out against both the fur and the sleeves.', TAN, TAN, '#BFD9F5')]
row1 = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 300px"><div style="width: 300px; height: 250px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 8px; box-sizing: border-box">'
               f'<svg role="img" aria-label="{t}" width="196" height="233" viewBox="0 -10 252 300">{fig(WAVE, "happy", "#2A62B8", h, f, extra_front=waves)}</svg></div>'
               f'<div style="font-size: 16px; font-weight: 800">{t}</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4">{n}</div></div>' for t, n, h, f, bg in opts)
H, F = PF, BILL
wattle = ('<path d="M178 196Q182 150 168 110" fill="none" stroke="#6E9C7E" stroke-width="5"></path>' +
          ''.join(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#F4BE2C" stroke="#3A2A20" stroke-width="3.500"></circle>' for cx, cy in ((168, 104), (156, 116), (180, 118), (166, 128), (176, 136))))
balloon = ('<path d="M206 126Q214 90 210 64" fill="none" stroke="#3A2A20" stroke-width="3"></path><ellipse cx="210" cy="36" rx="22" ry="27" fill="#E5553B" stroke="#3A2A20" stroke-width="5"></ellipse>'
           '<path d="M205 64h10l-5 -6z" fill="#E5553B" stroke="#3A2A20" stroke-width="3" stroke-linejoin="round"></path><path d="M200 24q4 -8 10 -8" fill="none" stroke="#FBF6E9" stroke-width="4" stroke-linecap="round"></path>')
clapmarks = ''.join(f'<path d="M{120+math.cos(math.radians(a))*46:.0f} {196+math.sin(math.radians(a))*46:.0f}l{math.cos(math.radians(a))*13:.0f} {math.sin(math.radians(a))*13:.0f}" stroke="#3A2A20" stroke-width="5" stroke-linecap="round"></path>' for a in (-172, 166, -8, 14))
acts = [('Peekaboo', fig([(88, 178, 88, 116, 30), (152, 178, 152, 116, -30)], 'neutral', '#E5553B', H, F, front=True), '#F3D9C9', 'For the baby. The only time hands go over the face.'),
        ('Oh!', fig([(88, 178, 60, 138, 16), (152, 178, 180, 138, -16)], 'surprised', '#3C9A5F', H, F, front=True), '#BFD9F5', 'Hands to cheeks, for surprise or delight.'),
        ('Clap', fig([(90, 180, 112, 196, 10), (150, 180, 128, 196, -10)], 'happy', '#F4BE2C', H, F, extra_front=clapmarks), '#CFE5D2', 'Hands meet in front, with clap marks.'),
        ('Holding wattle', fig([(88, 178, 50, 214, 4), (152, 178, 178, 196, -6)], 'happy', '#2A62B8', H, F, extra_front=wattle), '#F4E7B0', 'One hand holds a prop: flowers, a bottle, a toy, Pebble’s hand.'),
        ('Balloon', fig([(88, 178, 50, 214, 4), (152, 178, 206, 126, -8)], 'proud', '#BFD9F5', H, F, extra_front=balloon), '#F4BE2C', 'Birthdays and milestones.')]
row2 = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 172px"><div style="width: 172px; height: 200px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 6px; box-sizing: border-box">'
               f'<svg role="img" aria-label="Puggle, {t}" width="156" height="186" viewBox="0 -14 256 304">{svg}</svg></div><div style="font-size: 15px; font-weight: 800">{t}</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.35">{n}</div></div>' for t, svg, bg, n in acts)
body = f'''<div style="width: 1080px; height: 800px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Hands</h1>
<div style="display: flex; gap: 42px">{row1}</div>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Doing things with them (shown with A)</div>
<div style="display: flex; gap: 22px">{row2}</div>
</div>'''
wrap('Hands', body, 1080, 800, 'Hands.dc.html', 18000)
