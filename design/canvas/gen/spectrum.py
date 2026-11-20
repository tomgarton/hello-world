import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/world.py').read(); src = src[:src.index('walls = f')]
ns = {'__name__': 'x'}; exec(src, ns)
inner, shape, place, wrap = ns['inner'], ns['shape'], ns['place'], ns['wrap']
FUR, DARK, BELLY, BILL, BILLD, LINE = '#8A5A3C', '#6A4128', '#C89A72', '#6E7F8D', '#4E5D69', '#4A2E1E'
TEE = '#2A62B8'
def feet_web(cx, cy, col, line, sw):
    st = f'stroke="{line}" stroke-width="{sw}"' if line else ''
    return f'<path d="M{cx-22} {cy}q0 -14 22 -14q22 0 22 14q-7 6 -11 0q-4 6 -11 0q-7 6 -11 0q-4 6 -11 0z" fill="{col}" {st} stroke-linejoin="round"></path>'
def mid(expr='happy'):
    sw = 5; L = LINE
    s = f'<ellipse cx="186" cy="232" rx="38" ry="16" transform="rotate(-24 186 232)" fill="{DARK}" stroke="{L}" stroke-width="{sw}"></ellipse>'
    s += f'<rect x="92" y="236" width="22" height="34" rx="10" fill="{FUR}" stroke="{L}" stroke-width="{sw}"></rect><rect x="126" y="236" width="22" height="34" rx="10" fill="{FUR}" stroke="{L}" stroke-width="{sw}"></rect>'
    s += feet_web(103, 284, BILL, L, sw) + feet_web(137, 284, BILL, L, sw)
    s += f'<path d="M120 150C80 150 66 196 70 230Q72 250 120 250Q168 250 170 230C174 196 160 150 120 150Z" fill="{FUR}" stroke="{L}" stroke-width="{sw}"></path>'
    s += f'<path d="M84 196Q120 182 156 196L160 228Q160 246 120 246Q80 246 80 228Z" fill="{TEE}" stroke="{L}" stroke-width="{sw}" stroke-linejoin="round"></path>'
    s += f'<ellipse cx="120" cy="222" rx="22" ry="16" fill="{BELLY}" opacity="0"></ellipse>'
    for side in (-1, 1):
        x = 120 + side * 52
        s += f'<g transform="rotate({side*-30} {x} 176)"><rect x="{x-11}" y="172" width="22" height="46" rx="11" fill="{FUR}" stroke="{L}" stroke-width="{sw}"></rect><path d="M{x-12} 214q12 16 24 0z" fill="{BILL}" stroke="{L}" stroke-width="4" stroke-linejoin="round"></path></g>'
    s += f'<ellipse cx="120" cy="104" rx="68" ry="58" fill="{FUR}" stroke="{L}" stroke-width="{sw}"></ellipse>'
    s += f'<path d="M66 82Q120 40 174 82Q150 64 120 64Q90 64 66 82Z" fill="{DARK}"></path>'
    s += '<circle cx="66" cy="118" r="11" fill="#EE9C88"></circle><circle cx="174" cy="118" r="11" fill="#EE9C88"></circle>'
    s += ''.join(f'<path d="M{x-7} 123l5-9M{x+2} 123l5-9" stroke="#C24A36" stroke-width="3.500" stroke-linecap="round"></path>' for x in (66, 174))
    ey = 94
    brows = {'happy': (2, -2), 'laugh': (4, -4), 'surprised': (-10, -14), 'sleepy': (0, 0), 'cross': (-6, 10), 'cheeky': (6, -8)}[expr]
    for i, x in enumerate((92, 148)):
        if expr == 'sleepy' or (expr == 'cheeky' and i == 1) or expr == 'laugh':
            s += f'<path d="M{x-9} {ey}q9 {7 if expr != "laugh" else -9} 18 0" fill="none" stroke="{L}" stroke-width="5" stroke-linecap="round"></path>'
        else:
            r = 9 if expr == 'surprised' else 7
            s += f'<ellipse cx="{x}" cy="{ey}" rx="{r-1}" ry="{r+1}" fill="{L}"></ellipse><circle cx="{x+2}" cy="{ey-3}" r="2.200" fill="#FBF6E9"></circle>'
        o, n = brows
        b0, b1 = (o, n) if i == 0 else (n, o)
        s += f'<path d="M{x-10} {ey-18+b0*0.6:.1f}L{x+10} {ey-18+b1*0.6:.1f}" stroke="{L}" stroke-width="4.500" stroke-linecap="round"></path>' if expr != 'sleepy' else ''
    if expr in ('laugh', 'surprised'):
        s += f'<path d="M64 128Q120 112 176 128Q184 140 172 150Q120 160 68 150Q56 140 64 128Z" fill="{BILL}" stroke="{L}" stroke-width="{sw}"></path>'
        gap = 'M86 150Q120 182 154 150Z' if expr == 'laugh' else 'M106 150Q120 176 134 150Z'
        s += f'<path d="{gap}" fill="#7A2E2A" stroke="{L}" stroke-width="4" stroke-linejoin="round"></path>'
    else:
        s += f'<path d="M62 128Q120 110 178 128Q190 146 176 158Q120 172 64 158Q50 146 62 128Z" fill="{BILL}" stroke="{L}" stroke-width="{sw}"></path>'
        curve = {'happy': 'M96 150Q120 162 144 150', 'sleepy': 'M104 152H136', 'cross': 'M100 156Q120 146 140 156', 'cheeky': 'M100 150Q124 162 144 146'}[expr]
        s += f'<path d="{curve}" fill="none" stroke="{BILLD}" stroke-width="4" stroke-linecap="round"></path>'
    s += f'<circle cx="110" cy="128" r="2.800" fill="{BILLD}"></circle><circle cx="130" cy="128" r="2.800" fill="{BILLD}"></circle>'
    return s
def bluey():
    s = f'<path d="M64 222Q34 236 26 262Q50 266 76 240Z" fill="{DARK}"></path>'
    s += f'<path d="M104 238L92 280" stroke="{FUR}" stroke-width="22" stroke-linecap="round"></path><path d="M134 238L156 274" stroke="{FUR}" stroke-width="22" stroke-linecap="round"></path>'
    s += f'<path d="M70 290q0-14 22-14q22 0 22 14q-11 5 -22 0q-11 5 -22 0z" fill="{BILL}"></path><path d="M146 286q2-14 22-12q20 2 18 16q-10 4 -20-2q-10 4 -20-2z" fill="{BILL}"></path>'
    s += f'<path d="M84 170Q58 150 44 122" stroke="{FUR}" stroke-width="20" stroke-linecap="round" fill="none"></path><path d="M30 118q8 -16 24 -6z" fill="{BILL}"></path>'
    s += f'<path d="M118 146C80 146 70 196 74 228Q78 250 120 250Q160 250 164 226C168 194 156 146 118 146Z" fill="{FUR}"></path>'
    s += f'<path d="M80 192Q118 176 158 190L162 226Q160 246 120 246Q80 246 78 228Z" fill="{TEE}"></path><path d="M80 204H160M79 216H161" stroke="#FBF6E9" stroke-width="6"></path>'
    s += f'<path d="M154 176Q170 200 168 222" stroke="{FUR}" stroke-width="20" stroke-linecap="round" fill="none"></path><path d="M160 226q8 16 18 0z" fill="{BILL}"></path>'
    s += f'<ellipse cx="110" cy="100" rx="64" ry="56" fill="{FUR}"></ellipse><path d="M50 84Q100 36 162 68Q124 52 96 58Q68 64 50 84Z" fill="{DARK}"></path>'
    s += f'<path d="M128 106Q176 96 198 110Q208 124 198 136Q178 148 130 142Z" fill="{BILL}"></path><path d="M150 136Q172 142 194 132" stroke="{BILLD}" stroke-width="4" fill="none" stroke-linecap="round"></path>'
    s += f'<circle cx="184" cy="114" r="3" fill="{BILLD}"></circle>'
    s += '<circle cx="72" cy="124" r="11" fill="#EE9C88"></circle><path d="M65 129l5-9M74 129l5-9" stroke="#C24A36" stroke-width="3.500" stroke-linecap="round"></path>'
    s += f'<ellipse cx="88" cy="92" rx="6.500" ry="8.500" fill="{LINE}"></ellipse><circle cx="90" cy="89" r="2.200" fill="#FBF6E9"></circle><ellipse cx="132" cy="90" rx="7.500" ry="9.500" fill="{LINE}"></ellipse><circle cx="134" cy="87" r="2.500" fill="#FBF6E9"></circle>'
    s += f'<path d="M78 74L96 70M122 68L142 72" stroke="{LINE}" stroke-width="4.500" stroke-linecap="round"></path>'
    return s
def card(svgbody, title, note, bg, vb='0 0 240 300'):
    return (f'<div style="display: flex; flex-direction: column; gap: 8px; width: 300px"><div style="width: 300px; height: 330px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 14px; box-sizing: border-box">'
            f'<svg role="img" aria-label="{title}" width="250" height="312" viewBox="{vb}">{svgbody}</svg></div>'
            f'<div style="font-size: 17px; font-weight: 800">{title}</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.4">{note}</div></div>')
row = (card(inner('platypus', 'jumper', TEE), 'Miffy end (current)', 'Heavy ink outline, dot eyes, no mouth, front-on, garment as body.', '#F4BE2C') +
       card(mid('happy'), 'Middle', 'Thinner outline in a dark fur tone. Brows and an eye glint. The bill can smile. A pear-shaped body, darker crown, webbed hands and feet, bigger tail.', '#CFE5D2') +
       card(bluey(), 'Bluey end', 'No outlines, tonal patches, three-quarter view with the bill in profile, and a pose with energy: waving, mid-stride.', '#BFD9F5', '0 -10 250 310'))
exprs = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 132px; height: 120px; background: #FBF6E9; display: flex; align-items: center; justify-content: center; overflow: hidden">'
                f'<svg role="img" aria-label="Puggle looking {e}" width="124" height="112" viewBox="38 34 164 148">{mid(e)}</svg></div><div style="font-size: 13px; font-weight: 700">{e.capitalize()}</div></div>'
                for e in ('happy', 'laugh', 'surprised', 'sleepy', 'cross', 'cheeky'))
body = f'''<div style="width: 1080px; height: 820px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 24px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle, between Miffy and Bluey</h1>
<div style="display: flex; gap: 42px">{row}</div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Middle version: expressions</div>
<div style="display: flex; gap: 22px">{exprs}</div></div>
</div>'''
wrap('Puggle, between Miffy and Bluey', body, 1080, 820, 'Spectrum.dc.html', 13510)
