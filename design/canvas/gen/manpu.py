import sys, math
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; sys_argv = sys.argv; exec(src, x)
O, PF, BL = x['O'], x['PF'], x['BL']
blush, dot, arc_up, arc_down, bill_closed, bill_open, sparkle, wrap = x['blush'], x['dot'], x['arc_up'], x['arc_down'], x['bill_closed'], x['bill_open'], x['sparkle'], x['wrap']
H = f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
def star(cx, cy, r):
    pts = ' '.join(f'{cx + (r if i % 2 == 0 else r*0.45) * math.cos(math.radians(-90 + i*36)):.1f},{cy + (r if i % 2 == 0 else r*0.45) * math.sin(math.radians(-90 + i*36)):.1f}' for i in range(10))
    return f'<polygon points="{pts}" fill="#F4BE2C" stroke="{O}" stroke-width="3" stroke-linejoin="round"></polygon>'
def squeeze(cx, cy, flip):
    d = -1 if flip else 1
    return f'<path d="M{cx-8*d} {cy-8}L{cx+7*d} {cy}L{cx-8*d} {cy+8}" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"></path>'
def swirl(cx, cy):
    return f'<path d="M{cx} {cy}m-2 0a2 2 0 1 1 4 0a5 5 0 1 1 -9 0a8 8 0 1 1 15 0" fill="none" stroke="{O}" stroke-width="3.500" stroke-linecap="round"></path>'
def heart(cx, cy, s=1):
    return f'<path transform="translate({cx} {cy}) scale({s})" d="M0 8C-14 -2 -10 -14 0 -7C10 -14 14 -2 0 8Z" fill="#E5553B" stroke="{O}" stroke-width="3" stroke-linejoin="round"></path>'
def blossom(cx, cy, r, c):
    return ''.join(f'<circle cx="{cx + r*0.9*math.cos(math.radians(72*i-90)):.1f}" cy="{cy + r*0.9*math.sin(math.radians(72*i-90)):.1f}" r="{r*0.8:.1f}" fill="{c}"></circle>' for i in range(5)) + f'<circle cx="{cx}" cy="{cy}" r="{r*0.6:.1f}" fill="#F4BE2C"></circle>'
F = {
 'Sparkly eyes': ('Excited: a new toy, a first', H + blush(127, 53) + bill_closed(0, -2) + star(93, 108, 13) + star(147, 108, 13)),
 'Squeezed eyes': ('Big effort, or a big cry', H + blush(127, 53, 12) + bill_closed(0, -2) + squeeze(93, 108, False) + squeeze(147, 108, True)),
 'Sweat drop': ('Oops: the nappy explosion', H + blush(127, 53) + bill_closed(0, 2) + dot(93, 108) + dot(147, 108) + '<path d="M184 54q-12 18 0 24q12 -6 0 -24z" fill="#8FC1EC" stroke="#3A2A20" stroke-width="3.500" stroke-linejoin="round"></path>'),
 'Dizzy': ('Tired parents, 3 am', H + blush(127, 53) + bill_closed(6, 2) + swirl(93, 108) + swirl(147, 108)),
 'Bubble': ('Fast asleep', H + blush(127, 53) + bill_closed(0, 2) + arc_down(93, 110) + arc_down(147, 110) + '<circle cx="150" cy="134" r="15" fill="#DCEEFB" stroke="#3A2A20" stroke-width="3.500" opacity="0.95"></circle><circle cx="145" cy="129" r="4" fill="#FFFFFF"></circle>'),
 'Tear streams': ('Big feelings', H + blush(127, 53) + bill_closed(0, 4) + arc_down(93, 108) + arc_down(147, 108) + ''.join(f'<path d="M{x-5} 114v30q5 8 10 0v-30" fill="#8FC1EC" stroke="#3A2A20" stroke-width="3"></path>' for x in (93, 147))),
 'Gloom lines': ('A bit sad', H + blush(129, 53) + bill_closed(0, 6) + dot(93, 114) + dot(147, 114) + ''.join(f'<path d="M{x} 8v{l}" stroke="#7F8FB0" stroke-width="4" stroke-linecap="round"></path>' for x, l in ((84, 24), (100, 30), (116, 22), (132, 30), (148, 24)))),
 'Flower burst': ('Pure joy', ''.join(blossom(cx, cy, 13, c) for cx, cy, c in ((40, 48, '#F3D9C9'), (196, 40, '#BFD9F5'), (204, 120, '#F3D9C9'), (34, 132, '#CFE5D2'))) + H + blush(127, 53, 12) + bill_closed(0, -4) + arc_up(93, 108) + arc_up(147, 108)),
 'Hearts': ('Love', H + blush(127, 53, 12) + bill_closed(0, -3) + arc_up(93, 108) + arc_up(147, 108) + heart(186, 46, 1.3) + heart(206, 74, 0.9)),
 'Puffed cheeks': ('Cross, but cute', H + blush(129, 55, 16) + bill_closed(0, 4) + dot(93, 110) + dot(147, 110) + '<path d="M182 36q10 -8 16 0q8 -2 8 8q-2 8 -12 6q-6 6 -12 0q-8 -4 0 -14z" fill="#FBF6E9" stroke="#3A2A20" stroke-width="3"></path>'),
}
cards = ''.join(f'<div style="display: flex; flex-direction: column; gap: 4px; width: 176px"><div style="width: 176px; height: 150px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">'
                f'<svg role="img" aria-label="Puggle, {n}" width="156" height="142" viewBox="14 0 212 194">{svg}</svg></div><div style="font-size: 14px; font-weight: 800">{n}</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30">{use}</div></div>' for n, (use, svg) in F.items())
body = f'''<div style="width: 1080px; height: 540px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Anime-style marks on the original Puggle</h1>
<div style="display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 22px 20px">{cards}</div>
</div>'''
wrap('Anime-style marks', body, 1080, 540, 'Manpu.dc.html', 15980)
