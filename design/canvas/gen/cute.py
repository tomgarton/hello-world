import sys, re
ROOT = sys.argv[1]
src = open(ROOT + '/gen/world.py').read(); src = src[:src.index('walls = f')]
ns = {'__name__': 'x'}; exec(src, ns)
place, wrap, outfits, tail = ns['place'], ns['wrap'], ns['ns']['outfits'], ns['ns']['tail']
FUR, BILL, BILLD, BLUSH, ST, TEE = '#8A5A3C', '#6E7F8D', '#4E5D69', '#EE9C88', '#C24A36', '#2A62B8'
def fill(s, line):
    vals = dict(fur=FUR, ext=BILL, garment=TEE, paper='#FBF6E9', spine='#F3E3C3', inner='#F0DAD6', blush=BLUSH, blushShow='inline', stitch=ST, line=line)
    return re.sub(r'\{\{c\.(\w+)\}\}', lambda m: vals[m.group(1)], s)
def cheeks(y, dx, cx=120):
    return ''.join(f'<circle cx="{x}" cy="{y}" r="11" fill="{BLUSH}"></circle><path d="M{x-7} {y+5}l5-9M{x+2} {y+5}l5-9" stroke="{ST}" stroke-width="3.500" stroke-linecap="round"></path>' for x in (cx-dx, cx+dx))
def eyes(expr, L, xs, y, r):
    s = ''
    for i, x in enumerate(xs):
        shut = expr in ('happy', 'laugh') or expr == 'sleepy' or (expr == 'wink' and i == 1)
        if expr in ('happy', 'laugh') or (expr == 'wink' and i == 1):
            s += f'<path d="M{x-r-1} {y+2}q{r+1} -{r*1.6:.0f} {2*r+2} 0" fill="none" stroke="{L}" stroke-width="5" stroke-linecap="round"></path>'
        elif expr == 'sleepy':
            s += f'<path d="M{x-r-1} {y}q{r+1} {r} {2*r+2} 0" fill="none" stroke="{L}" stroke-width="5" stroke-linecap="round"></path>'
        else:
            k = 1.3 if expr == 'surprised' else 1
            s += f'<ellipse cx="{x}" cy="{y}" rx="{r*k:.1f}" ry="{(r+2)*k:.1f}" fill="{L}"></ellipse><circle cx="{x+r*0.35:.1f}" cy="{y-r*0.45:.1f}" r="{r*0.38:.1f}" fill="#FFFFFF"></circle>'
    return s
def bill(expr, L, cx, cy, rx, ry, sw):
    s = f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{BILL}" stroke="{L}" stroke-width="{sw}"></ellipse>'
    s += f'<circle cx="{cx-9}" cy="{cy-ry*0.45:.1f}" r="2.600" fill="{BILLD}"></circle><circle cx="{cx+9}" cy="{cy-ry*0.45:.1f}" r="2.600" fill="{BILLD}"></circle>'
    if expr == 'laugh':
        s += f'<path d="M{cx-14} {cy+2}Q{cx} {cy+20} {cx+14} {cy+2}Z" fill="#9A3B3B" stroke="{L}" stroke-width="3.500" stroke-linejoin="round"></path>'
    elif expr == 'surprised':
        s += f'<ellipse cx="{cx}" cy="{cy+5}" rx="5" ry="6" fill="#9A3B3B" stroke="{L}" stroke-width="3"></ellipse>'
    elif expr == 'sleepy':
        s += f'<path d="M{cx-7} {cy+6}H{cx+7}" stroke="{BILLD}" stroke-width="4" stroke-linecap="round"></path>'
    elif expr == 'sad':
        s += f'<path d="M{cx-10} {cy+10}Q{cx} {cy+2} {cx+10} {cy+10}" fill="none" stroke="{BILLD}" stroke-width="4" stroke-linecap="round"></path>'
    else:
        s += f'<path d="M{cx-12} {cy+4}Q{cx} {cy+13} {cx+12} {cy+4}" fill="none" stroke="{BILLD}" stroke-width="4" stroke-linecap="round"></path>'
    return s
def head1(expr='neutral', L='#3A2A20'):
    return (f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{FUR}" stroke="{L}" stroke-width="7"></ellipse>' + cheeks(118, 56) +
            bill(expr, L, 120, 146, 54, 23, 6) + eyes(expr, L, (90, 150), 98, 6))
def head2(expr='neutral', L='#4A2E1E'):
    return (f'<ellipse cx="120" cy="106" rx="72" ry="62" fill="{FUR}" stroke="{L}" stroke-width="6"></ellipse>' + cheeks(124, 54) +
            bill(expr, L, 120, 142, 40, 19, 5) + eyes(expr, L, (98, 142), 108, 8))
def body3(L):
    s = f'<ellipse cx="180" cy="236" rx="30" ry="14" transform="rotate(-24 180 236)" fill="{FUR}" stroke="{L}" stroke-width="5"></ellipse>'
    s += ''.join(f'<ellipse cx="{x}" cy="268" rx="20" ry="11" fill="{BILL}" stroke="{L}" stroke-width="5"></ellipse>' for x in (98, 142))
    s += f'<ellipse cx="120" cy="220" rx="52" ry="46" fill="{TEE}" stroke="{L}" stroke-width="6"></ellipse>'
    s += f'<path d="M102 224h36v8a18 14 0 0 1-36 0z" fill="none" stroke="{L}" stroke-width="4.500" stroke-linejoin="round"></path>'
    s += ''.join(f'<ellipse cx="{x}" cy="214" rx="13" ry="18" transform="rotate({r} {x} 214)" fill="{TEE}" stroke="{L}" stroke-width="5"></ellipse><circle cx="{x+dx}" cy="230" r="9" fill="{BILL}" stroke="{L}" stroke-width="4.500"></circle>' for x, r, dx in ((70, 24, -4), (170, -24, 4)))
    return s
def head3(expr='neutral', L='#4A2E1E'):
    return (f'<ellipse cx="120" cy="104" rx="80" ry="70" fill="{FUR}" stroke="{L}" stroke-width="6"></ellipse>' + cheeks(126, 58) +
            bill(expr, L, 120, 146, 38, 18, 5) + eyes(expr, L, (96, 144), 108, 9))
std = lambda L: fill(tail, L) + fill(outfits['jumper'], L)
V = [('A. Miffy, plus a smile', 'The current Puggle with only two changes: a smile on the bill and a glint in the eye.', '#F4BE2C', std('#3A2A20') + head1()),
     ('B. Bigger eyes, smaller bill', 'Eyes larger and lower, bill smaller, softer brown outline. No brows.', '#CFE5D2', std('#4A2E1E') + head2()),
     ('C. Chubby', 'Bigger head, round tummy, stubby arms and legs. The most baby-like.', '#BFD9F5', body3('#4A2E1E') + head3())]
cards = ''.join(f'<div style="display: flex; flex-direction: column; gap: 8px; width: 300px"><div style="width: 300px; height: 330px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 14px; box-sizing: border-box">'
                f'<svg role="img" aria-label="{t}" width="250" height="312" viewBox="0 0 240 300">{svg}</svg></div><div style="font-size: 17px; font-weight: 800">{t}</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.4">{n}</div></div>' for t, n, bg, svg in V)
EX = ['neutral', 'happy', 'laugh', 'surprised', 'sleepy', 'sad', 'wink']
exprs = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 118px; height: 108px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">'
                f'<svg role="img" aria-label="Puggle looking {e}" width="108" height="100" viewBox="40 30 160 148">{head2(e)}</svg></div><div style="font-size: 13px; font-weight: 700">{e.capitalize()}</div></div>' for e in EX)
body = f'''<div style="width: 1080px; height: 720px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 24px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle, cuter: three candidates</h1>
<div style="display: flex; gap: 42px">{cards}</div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Expressions with eyes and bill only, no brows (shown on B)</div>
<div style="display: flex; gap: 16px">{exprs}</div></div>
</div>'''
wrap('Puggle, cuter: three candidates', body, 1080, 720, 'Cute.dc.html', 14450)
