import sys, re, math
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, BL, ST, p, head, limb, body, wrap, dot = [x[k] for k in ('O', 'PF', 'BILL', 'BL', 'ST', 'p', 'head', 'limb', 'body', 'wrap', 'dot')]
fsrc = open(ROOT + '/gen/family.py').read(); fsrc = fsrc[:fsrc.index('def card(')]
fsrc = fsrc[fsrc.index('def bottle('):]
exec(fsrc, x); baby = x['baby']
wsrc = open(ROOT + '/gen/world.py').read(); wsrc = wsrc[:wsrc.index('walls = f')]
w = {'__name__': 'x'}; exec(wsrc, w); inner = w['inner']
def quokka_kid(col='#F4BE2C'):
    fur = '#C2925F'
    s = p['legs'](fur).replace(PF, fur) + p['feet'](fur) + p['trap'](col) + p['pocket'](210, col) + limb(88, 178, 50, 214, col, 4, hand=fur) + limb(152, 178, 190, 214, col, -4, hand=fur)
    s += ''.join(f'<circle cx="{cx}" cy="58" r="19" fill="{fur}" stroke="{O}" stroke-width="6"></circle>' for cx in (72, 168))
    s += f'<ellipse cx="120" cy="110" rx="68" ry="62" fill="{fur}" stroke="{O}" stroke-width="7"></ellipse>'
    s += ''.join(f'<circle cx="{cx}" cy="124" r="10" fill="{BL}"></circle><path d="M{cx-7} 129l5-9M{cx+2} 129l5-9" stroke="{ST}" stroke-width="3.500" stroke-linecap="round"></path>' for cx in (70, 170))
    return s + f'<ellipse cx="120" cy="118" rx="10" ry="7" fill="{O}"></ellipse>' + dot(88, 100) + dot(152, 100)
gsrc = open(ROOT + '/gen/glasses.py').read(); gsrc = gsrc[gsrc.index('def glasses('):gsrc.index('POS = [')]
exec(gsrc, x); GL = x['glasses']
def adult(col, kind):
    s = p['tail'](PF).replace('cy="246"', 'cy="400"').replace('184 246', '184 400')
    s += ''.join(f'<rect x="{x0}" y="370" width="22" height="72" rx="10" fill="{PF}" stroke="{O}" stroke-width="6"></rect><ellipse cx="{x0+11}" cy="446" rx="24" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' for x0 in (90, 128))
    if kind == 'mum':
        s += f'<path d="M86 168Q120 158 154 168L192 380Q194 390 182 390L58 390Q46 390 48 380Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
    elif kind == 'dad':
        s += f'<path d="M84 168Q120 158 156 168L166 330L74 330Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path><path d="M74 326H166L170 384H126L120 366L114 384H70Z" fill="#F3E3C3" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
    else:
        s += f'<path d="M86 168Q120 158 154 168L180 380Q182 390 170 390L70 390Q58 390 60 380Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path><path d="M120 166V388" stroke="{O}" stroke-width="5"></path>' + ''.join(f'<circle cx="128" cy="{y}" r="4.500" fill="#FBF6E9" stroke="{O}" stroke-width="2.500"></circle>' for y in (200, 250, 300, 350))
    s += limb(88, 182, 46, 300, col, 8) + limb(152, 182, 194, 300, col, -8)
    s += head('neutral')
    if kind == 'nan': s += A['bun']() + GL(134, 'blue', 14)
    if kind == 'pop': s += GL(108, 'clear', 15)
    if kind == 'pop':
        s += f'<path d="M62 64Q120 22 178 64Z" fill="#3C9A5F" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path><path d="M48 66H192" stroke="{O}" stroke-width="7" stroke-linecap="round"></path>'
    if kind == 'mum':
        s += f'<path d="M156 52q14 -16 26 -2q-8 10 -26 2z" fill="#E5553B" stroke="{O}" stroke-width="4"></path>'
    return s
hsrc = open(ROOT + '/gen/heads.py').read(); hsrc = hsrc[hsrc.index('SW = '):hsrc.index('ACC = [')]
exec(hsrc, x)
A = {k: x[k] for k in ('quatre', 'bow', 'clip', 'headband', 'bun', 'flower', 'beanie', 'bucket', 'sunhat')}
GROUND = 470
def place(svg, vbw, vbh, h, x, label, sub):
    wdt = h * vbw / vbh
    return (f'<g transform="translate({x - wdt/2:.0f} {GROUND - h:.0f}) scale({h/vbh:.4f})">{svg}</g>'
            f'<text x="{x}" y="{GROUND+26}" text-anchor="middle" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="23" fill="#2A1F18">{label}</text>'
            f'<text x="{x}" y="{GROUND+50}" text-anchor="middle" font-family="Bricolage Grotesque, sans-serif" font-weight="500" font-size="18" fill="#4A3B30">{sub}</text>')
KID = 210
AH = 456 * 0.7
cast = [
 (adult('#E5553B', 'nan'), 240, 456, AH * 0.95, 'Nan', 'Platypus'),
 (adult('#3C9A5F', 'mum'), 240, 456, AH * 0.98, 'Mum', 'Platypus'),
 (adult('#2A62B8', 'dad'), 240, 456, AH, 'Dad', 'Platypus'),
 (adult('#BFD9F5', 'pop'), 240, 456, AH * 0.97, 'Pop', 'Platypus'),
 (body('down', 'happy', '#2A62B8') + A['clip'](160, 56, '#E5553B'), 240, 300, KID, 'Puggle', '2½, platypus'),
 (baby('happy', '#F4BE2C'), 240, 270, 140, 'Pebble', '6 months, platypus'),
 (inner('echidna', 'dungarees', '#E5553B'), 240, 300, KID, 'Quill', '2½, echidna'),
 (inner('koala', 'dress', '#F4BE2C') + A['bow'](150, 50, '#2A62B8'), 240, 300, KID * 1.06, 'Kip', '3, koala'),
 (inner('wombat', 'tee', '#2A62B8') + A['beanie']('#E5553B'), 240, 300, KID * 1.1, 'Digby', '3½, wombat'),
 (quokka_kid('#3C9A5F') + A['sunhat']('#F4E7B0'), 240, 300, KID * 1.14, 'Sunny', '4, quokka'),
]
xs = [90, 240, 390, 540, 700, 840, 980, 1120, 1260, 1400]
art = ''.join(place(s, vw, vh, h, xx, l, sub) for (s, vw, vh, h, l, sub), xx in zip(cast, xs))
lines = ''.join(f'<path d="M0 {GROUND - h}H1500" stroke="#C9B89F" stroke-width="1.500" stroke-dasharray="6 6"></path>' for h in (KID, round(AH)))
svg = f'<svg role="img" aria-label="The cast standing in a line from tallest grown-ups to the baby and friends" width="984" height="360" viewBox="0 110 1500 450"><path d="M0 {GROUND}H1500" stroke="#3A2A20" stroke-width="3"></path>{art}</svg>'
sm = x['small']
small_row = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 2px; width: 92px"><svg role="img" aria-label="{l}, small version" width="{76*h/KID*vw/vh:.0f}" height="{76*h/KID:.0f}" viewBox="0 0 {vw} {vh}">{sm(s_)}</svg><div style="font-size: 12px; font-weight: 700">{l}</div></div>' for (s_, vw, vh, h, l, sub) in cast[4:])
bodyh = f'''<div style="width: 1080px; height: 680px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 14px">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">The cast, to scale</h1><div style="font-size: 14px; font-weight: 600; color: #4A3B30">Children share one head size; grown-ups are taller, with longer bodies, not bigger heads</div></div>
{svg}
<div style="display: flex; align-items: flex-end; gap: 18px"><div style="width: 250px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Small versions</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4">For scenes, widgets and anywhere under about 100 pt tall: plain blush, no nostrils or pocket, line a quarter heavier.</div></div><div style="display: flex; align-items: flex-end; gap: 6px">{small_row}</div></div>
</div>'''
wrap('The cast, to scale', bodyh, 1080, 680, 'Lineup.dc.html', 19720)
