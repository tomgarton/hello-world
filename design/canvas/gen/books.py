import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/world.py').read(); src = src[:src.index('walls = f')]
ns = {'__name__': 'x'}; sys.argv = sys.argv[:2]; exec(src, ns)
inner, shape, place, wrap = ns['inner'], ns['shape'], ns['place'], ns['wrap']
O = '#3A2A20'; SW = 'stroke="#3A2A20" stroke-width="4" stroke-linejoin="round"'
# flora and places, each in a 100x100 box
def gum():
    return ''.join(f'<path transform="rotate({r} 50 50)" d="M50 10C66 30 66 62 50 90C34 62 34 30 50 10Z" fill="{c}" {SW}></path>' for r, c in ((-28, '#8FB59A'), (24, '#6E9C7E'))) + f'<path d="M50 92V40" stroke="{O}" stroke-width="4"></path>'
def wattle():
    pts = [(30, 30), (46, 22), (62, 28), (72, 44), (38, 48), (56, 46), (28, 64), (46, 66), (64, 62)]
    return f'<path d="M50 94Q48 70 30 64M48 70Q60 60 64 62M50 80Q56 50 46 22" fill="none" stroke="#6E9C7E" stroke-width="4"></path>' + ''.join(f'<circle cx="{x}" cy="{y}" r="9" fill="#F4BE2C" {SW}></circle>' for x, y in pts)
def banksia():
    s = f'<path d="M50 94V76" stroke="{O}" stroke-width="4"></path><rect x="32" y="14" width="36" height="66" rx="18" fill="#D98A3D" {SW}></rect>'
    s += ''.join(f'<circle cx="{x}" cy="{y}" r="2.500" fill="{O}"></circle>' for y in range(24, 74, 10) for x in (42, 50, 58))
    return s + f'<path d="M50 78L28 92M50 78L72 92" stroke="#6E9C7E" stroke-width="6" stroke-linecap="round"></path>'
def bottlebrush():
    s = f'<path d="M50 96V8" stroke="{O}" stroke-width="4"></path>'
    s += ''.join(f'<path d="M50 {y}l{dx} -6" stroke="#E5553B" stroke-width="4" stroke-linecap="round"></path>' for y in range(20, 70, 6) for dx in (-20, 20))
    return s + ''.join(f'<circle cx="{50+dx}" cy="{y-6}" r="3" fill="#F4BE2C"></circle>' for y in range(20, 70, 12) for dx in (-20, 20))
def waratah():
    s = f'<path d="M50 96V70" stroke="#6E9C7E" stroke-width="5"></path>'
    s += ''.join(f'<path transform="rotate({r} 50 66)" d="M50 66C40 66 30 60 26 52C38 52 46 58 50 66Z" fill="#C24A36" {SW}></path>' for r in (-40, -10, 20, 50, 200, 170))
    return s + f'<ellipse cx="50" cy="44" rx="20" ry="24" fill="#E5553B" {SW}></ellipse>' + ''.join(f'<circle cx="{x}" cy="{y}" r="2.500" fill="{O}"></circle>' for x, y in ((44, 34), (56, 34), (50, 44), (44, 54), (56, 54)))
def jacaranda():
    return (f'<path d="M50 96V58M50 70L36 56M50 66L64 54" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>' +
            ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#9B86D8" {SW}></circle>' for x, y, r in ((30, 46, 18), (70, 44, 18), (50, 32, 22), (40, 56, 12), (62, 58, 12))))
def hoist():
    s = f'<path d="M50 96V36" stroke="{O}" stroke-width="5"></path><path d="M10 40L50 30L90 40M24 46L50 30L76 46" fill="none" stroke="{O}" stroke-width="4"></path>'
    socks = [(22, '#E5553B'), (38, '#2A62B8'), (62, '#F4BE2C'), (78, '#3C9A5F')]
    return s + ''.join(f'<path d="M{x-5} 42v14q0 6 6 6h6v-6h-4v-14z" fill="{c}" {SW}></path>' for x, c in socks)
def terrace():
    s = f'<rect x="14" y="20" width="72" height="76" fill="#F3D9C9" {SW}></rect><path d="M10 22L50 8L90 22Z" fill="#C24A36" {SW}></path>'
    s += f'<rect x="14" y="50" width="72" height="6" fill="{O}"></rect>' + ''.join(f'<path d="M{x} 56a5 6 0 0 0 10 0" fill="none" stroke="{O}" stroke-width="3"></path>' for x in range(16, 84, 10))
    return s + f'<rect x="24" y="26" width="16" height="20" rx="3" fill="#BFD9F5" {SW}></rect><rect x="60" y="26" width="16" height="20" rx="3" fill="#BFD9F5" {SW}></rect><rect x="24" y="66" width="18" height="30" rx="9" fill="#2A62B8" {SW}></rect><rect x="58" y="68" width="18" height="16" rx="3" fill="#BFD9F5" {SW}></rect>'
def tram():
    return (f'<path d="M40 22L50 10L60 22" fill="none" stroke="{O}" stroke-width="4"></path><rect x="10" y="22" width="80" height="58" rx="18" fill="#E5553B" {SW}></rect>'
            + ''.join(f'<rect x="{x}" y="32" width="16" height="18" rx="5" fill="#BFD9F5" {SW}></rect>' for x in (20, 42, 64)) +
            f'<rect x="10" y="58" width="80" height="6" fill="#FBF6E9"></rect><circle cx="30" cy="84" r="7" fill="{O}"></circle><circle cx="70" cy="84" r="7" fill="{O}"></circle><path d="M4 94H96" stroke="{O}" stroke-width="4"></path>')
def lighthouse():
    return (f'<path d="M36 94L42 30H58L64 94Z" fill="#FBF6E9" {SW}></path><path d="M39 64H61L62 76H38Z" fill="#E5553B"></path><path d="M36 94L42 30H58L64 94Z" fill="none" {SW}></path>'
            f'<rect x="40" y="16" width="20" height="14" rx="4" fill="#F4BE2C" {SW}></rect><path d="M36 16H64L50 6Z" fill="#C24A36" {SW}></path>')
def oceanpool():
    return (f'<path d="M6 60Q20 52 34 60T62 60T94 60V96H6Z" fill="#2A62B8"></path><rect x="14" y="44" width="72" height="34" rx="6" fill="#BFD9F5" {SW}></rect>'
            f'<path d="M22 60q7 -5 14 0t14 0t14 0t14 0" fill="none" stroke="#FBF6E9" stroke-width="4" stroke-linecap="round"></path><path d="M6 96H94" stroke="{O}" stroke-width="4"></path>')
def flags():
    return ''.join(f'<path d="M{x} 96V16" stroke="{O}" stroke-width="4"></path><path d="M{x} 18H{x+30}L{x} 44Z" fill="#E5553B" {SW}></path><path d="M{x+30} 18V44H{x}Z" fill="#F4BE2C" {SW}></path>' for x in (14, 56))
FLORA = [('Wattle', wattle), ('Gum leaves', gum), ('Banksia', banksia), ('Bottlebrush', bottlebrush), ('Waratah', waratah), ('Jacaranda', jacaranda)]
PLACES = [('Hills Hoist', hoist), ('Terrace house', terrace), ('Light rail', tram), ('Lighthouse', lighthouse), ('Ocean pool', oceanpool), ('Surf flags', flags)]

def cover(title, bg, scene, label):
    return (f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: 222px; height: 222px; display: flex; box-shadow: 4px 6px 0 #C9B89F">'
            f'<div style="width: 10px; background: {O}"></div><div style="flex-grow: 1; background: {bg}; position: relative; overflow: hidden">'
            f'<svg role="img" aria-label="{label}" width="212" height="222" viewBox="0 0 212 222" style="position: absolute; left: 0; top: 0">{scene}</svg>'
            f'<div style="position: absolute; left: 14px; top: 12px; right: 12px; font-size: 25px; font-weight: 800; line-height: 1; letter-spacing: -0.03em; color: {"#F3E0B8" if bg == "#1B2440" else O}">{title}</div></div></div>'
            f'<div style="font-size: 14px; font-weight: 700">{title.replace("<br>", " ")}</div></div>')
P_ = lambda a, o, g, x, y, s, mono=None: place(x, y, s, inner(a, o, g, mono=mono), 0, 240)
c1 = (f'<rect y="150" width="212" height="72" fill="#F3E3C3"></rect><rect y="120" width="212" height="34" fill="#2A62B8"></rect>' + place(176, 128, 56, flags()) + place(44, 136, 44, shape('pill', '#FBF6E9')) +
      P_('platypus', 'tee', '#E5553B', 100, 156, 92))
c2 = (f'<rect y="176" width="212" height="46" fill="#CFE5D2"></rect>' + place(56, 118, 110, terrace()) + place(168, 104, 120, jacaranda()) +
      ''.join(place(x, y, 10, shape('blossom', '#9B86D8')) for x, y in ((30, 196), (120, 206), (190, 192))) + P_('koala', 'dress', '#F4BE2C', 118, 160, 84))
c3 = (place(168, 64, 56, '<path d="M60 16a34 34 0 1 0 24 56A28 28 0 0 1 60 16z" fill="#F3E0B8"></path>') +
      ''.join(place(x, y, 10, shape('quatre', '#3A4690')) for x, y in ((30, 82), (120, 70), (196, 120), (24, 200))) + place(60, 150, 96, hoist().replace('stroke="#3A2A20"', 'stroke="#F3E0B8"')) +
      P_('platypus', 'jumper', '#BFD9F5', 140, 160, 92, mono=('#1B2440', '#F3E0B8')))
c4 = (f'<rect y="170" width="212" height="52" fill="#8FB59A"></rect>' + place(40, 110, 76, wattle()) + place(176, 120, 70, gum()) + place(184, 60, 36, wattle()) +
      P_('echidna', 'dungarees', '#2A62B8', 106, 158, 90))
covers = (cover('Puggle at<br>the Beach', '#BFD9F5', c1, 'Puggle in a red T-shirt on the sand, with surf flags') +
          cover('Koala and the<br>Jacaranda', '#FBF6E9', c2, 'Koala under a purple jacaranda beside a terrace house') +
          cover('Night Night,<br>Puggle', '#1B2440', c3, 'Mono Puggle at night beside a Hills Hoist under the moon') +
          cover('The Wattle<br>Walk', '#F4E7B0', c4, 'Echidna in dungarees among wattle and gum leaves'))
spread_r = (f'<rect width="360" height="300" fill="#BFD9F5"></rect><rect y="230" width="360" height="70" fill="#8FB59A"></rect>' + place(150, 150, 190, hoist()) +
            place(310, 210, 90, bottlebrush()) + place(44, 214, 70, banksia()) + P_('platypus', 'jumper', '#2A62B8', 220, 226, 108) + P_('echidna', 'dungarees', '#E5553B', 96, 238, 82))
spread = (f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="display: flex; box-shadow: 4px 6px 0 #C9B89F">'
          f'<div style="width: 300px; height: 300px; background: #FBF6E9; box-sizing: border-box; padding: 44px 36px; display: flex; flex-direction: column; justify-content: center; gap: 14px; border-right: 2px solid #E4DAC6">'
          f'<div style="font-size: 30px; font-weight: 800; line-height: 1.12; letter-spacing: -0.02em; color: {O}">One sock,<br>two socks,<br>three socks.</div><div style="font-size: 20px; font-weight: 600; line-height: 1.3; color: {O}">"Where is the fourth sock?" says Puggle.</div></div>'
          f'<svg role="img" aria-label="Puggle and the echidna in the backyard by the washing line, with bottlebrush and banksia" width="300" height="300" viewBox="0 0 360 300" preserveAspectRatio="xMidYMid slice">{spread_r}</svg></div>'
          f'<div style="font-size: 14px; font-weight: 700">Spread: words on the left, one picture on the right</div></div>')
def icons(lst):
    return ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 78px"><svg role="img" aria-label="{n}" width="56" height="56" viewBox="0 0 100 100">{f()}</svg><div style="font-size: 12px; font-weight: 700; text-align: center">{n}</div></div>' for n, f in lst)
body = f'''<div style="width: 1080px; height: 800px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Books</h1>
<div style="display: flex; gap: 32px">{covers}</div>
<div style="display: flex; gap: 40px; align-items: flex-start">
{spread}
<div style="display: flex; flex-direction: column; gap: 14px">
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Flora</div>
<div style="display: flex; flex-wrap: wrap; gap: 10px; width: 280px">{icons(FLORA)}</div>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Everyday places</div>
<div style="display: flex; flex-wrap: wrap; gap: 10px; width: 280px">{icons(PLACES)}</div>
</div>
</div>
</div>'''
wrap('Books', body, 1080, 800, 'Books.dc.html', 12590)
