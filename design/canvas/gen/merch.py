import sys, math, re
ROOT = sys.argv[1]
ls = open(ROOT + '/gen/logos.py').read(); ls = ls[:ls.index('v = []')]
x = {}; sys_argv = sys.argv; exec(ls, x)
O, PF, head, wrap, face, shape, INK, PAPER, B = [x[k] for k in ('O', 'PF', 'head', 'wrap', 'face', 'shape', 'INK', 'PAPER', 'B')]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); inner, place = w['inner'], w['place']
def inner_face(mono=None, bg=None):
    f = face(10, mono, bg); return f[f.index('>') + 1:f.rindex('</svg>')]
def repeat(kind, w_, h_):
    out = ''
    if kind == 'friends':
        cast = [('platypus', 'jumper', '#2A62B8'), ('koala', 'dress', '#E5553B'), ('echidna', 'dungarees', '#3C9A5F'), ('wombat', 'tee', '#2A62B8')]
        i = 0
        for r in range(-1, h_ // 46 + 2):
            for c in range(-1, w_ // 46 + 2):
                xx = c * 46 + (23 if r % 2 else 0); yy = r * 48
                if (r + c) % 2 == 0: out += place(xx, yy, 40, inner(*cast[i % 4]), 0, 240); i += 1
                else: out += place(xx, yy, 16, shape(['quatre', 'blossom', 'pill', 'pebble'][(r * 3 + c) % 4], ['#E5553B', '#3C9A5F', '#2A62B8', '#F4BE2C'][(r + c) % 4]))
    elif kind == 'faces':
        for r in range(-1, h_ // 44 + 2):
            for c in range(-1, w_ // 44 + 2):
                xx = c * 44 + (22 if r % 2 else 0); yy = r * 40
                out += f'<g transform="translate({xx-17} {yy-15}) scale(0.2)"><g transform="translate(-35 -40)">{inner_face("#C24A36", "#F3D9C9")}</g></g>'
    elif kind == 'shapes':
        for r in range(-1, h_ // 34 + 2):
            for c in range(-1, w_ // 34 + 2):
                out += place(c * 34 + (17 if r % 2 else 0), r * 34, 16, shape(['quatre', 'blossom'][(r + c) % 2], ['#F4BE2C', '#FBF6E9'][r % 2]))
    return out
def tee(fill, print_svg='', pid='t'):
    path = 'M60 20L100 8Q120 22 140 8L180 20L210 62L184 78L172 66V196H68V66L56 78L30 62Z'
    return (f'<defs><clipPath id="{pid}"><path d="{path}"></path></clipPath></defs><path d="{path}" fill="{fill}"></path>'
            f'<g clip-path="url(#{pid})">{print_svg}</g><path d="{path}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path><path d="M100 8Q120 30 140 8" fill="none" stroke="{INK}" stroke-width="5"></path>')
def onesie(fill, print_svg, pid):
    path = 'M74 18L100 10Q120 26 140 10L166 18L196 50L176 66L164 58V132Q164 150 150 160L140 188Q120 198 100 188L90 160Q76 150 76 132V58L64 66L44 50Z'
    return (f'<defs><clipPath id="{pid}"><path d="{path}"></path></clipPath></defs><path d="{path}" fill="{fill}"></path><g clip-path="url(#{pid})">{print_svg}</g>'
            f'<path d="{path}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path><path d="M100 10Q120 32 140 10" fill="none" stroke="{INK}" stroke-width="5"></path>'
            + ''.join(f'<circle cx="{cx}" cy="184" r="3.500" fill="{PAPER}" stroke="{INK}" stroke-width="2"></circle>' for cx in (110, 120, 130)))
def bucket_hat(fill, print_svg, pid):
    crown = 'M62 92Q66 34 120 32Q174 34 178 92Z'
    return (f'<defs><clipPath id="{pid}"><path d="{crown}"></path></clipPath></defs><path d="M20 100Q120 70 220 100Q226 118 206 120Q120 98 34 120Q14 118 20 100Z" fill="{fill}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path>'
            f'<path d="{crown}" fill="{fill}"></path><g clip-path="url(#{pid})">{print_svg}</g><path d="{crown}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path>')
def sock(xo, fill, cuff, flip=False):
    d = 'M40 10H86V120Q86 140 106 146Q132 152 132 172Q132 190 110 190H56Q40 190 40 170Z'
    t = f'translate({xo} 0)' + (' translate(172 0) scale(-1 1)' if flip else '')
    return (f'<g transform="{t}"><path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path><rect x="40" y="10" width="46" height="26" fill="{cuff}" stroke="{INK}" stroke-width="5"></rect>'
            f'<path d="M104 190Q132 190 132 172Q132 158 116 150" fill="#F4BE2C" stroke="{INK}" stroke-width="5"></path>'
            f'<g transform="translate(46 54) scale(0.2)"><g transform="translate(-35 -40)">{inner_face()}</g></g></g>')
beanie = (f'<path d="M50 120Q50 40 120 36Q190 40 190 120Z" fill="#2A62B8" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path><rect x="42" y="108" width="156" height="34" rx="10" fill="#2A62B8" stroke="{INK}" stroke-width="5"></rect>'
          + ''.join(f'<path d="M{xx} 112V138" stroke="#1F4E96" stroke-width="4"></path>' for xx in range(54, 190, 12)) +
          f'<rect x="100" y="114" width="40" height="22" fill="{PAPER}" stroke="{INK}" stroke-width="3"></rect><g transform="translate(106 115) scale(0.17)"><g transform="translate(-35 -40)">{inner_face(INK, PAPER)}</g></g><circle cx="120" cy="30" r="14" fill="#F4BE2C" stroke="{INK}" stroke-width="5"></circle>')
chest = f'<g transform="translate(98 58) scale(0.28)"><g transform="translate(-35 -40)">{inner_face()}</g></g><text x="120" y="128" text-anchor="middle" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="26" letter-spacing="-1" fill="{INK}">puggle</text>'
items = [
 ('Tee: face and wordmark', '#BFD9F5', tee('#BFD9F5', chest, 'ta'), '0 0 240 210'),
 ('Tee: friends repeat', '#FBF6E9', tee('#FBF6E9', repeat('friends', 240, 210), 'tb'), '0 0 240 210'),
 ('Tee: stripes and tab', '#F4BE2C', tee(PAPER, ''.join(f'<rect x="0" y="{y}" width="240" height="12" fill="#2A62B8"></rect>' for y in range(30, 200, 26)) + f'<rect x="64" y="150" width="20" height="20" fill="{PAPER}" stroke="{INK}" stroke-width="3"></rect><g transform="translate(66 152) scale(0.1)"><g transform="translate(-35 -40)">{inner_face(INK, PAPER)}</g></g>', 'tc'), '0 0 240 210'),
 ('Onesie: line-face repeat', '#CFE5D2', onesie('#F3D9C9', repeat('faces', 240, 200), 'oa'), '0 0 240 200'),
 ('Onesie: shapes repeat', '#F3D9C9', onesie('#3C9A5F', repeat('shapes', 240, 200), 'ob'), '0 0 240 200'),
 ('Bucket hat: shapes', '#BFD9F5', bucket_hat('#E5553B', repeat('shapes', 240, 100), 'ha'), '0 20 240 110'),
 ('Beanie: woven tab', '#F4E7B0', beanie, '20 10 200 140'),
 ('Socks: face at the ankle', '#CFE5D2', sock(0, PAPER, '#E5553B') + sock(120, PAPER, '#E5553B', True), '20 0 270 200'),
]
cells = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px"><div style="width: 225px; height: 200px; background: {bg}; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="{t}" width="196" height="172" viewBox="{vb}">{svg}</svg></div><div style="font-size: 14px; font-weight: 800">{t}</div></div>' for t, bg, svg, vb in items)
body = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 20px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Clothing mock-ups</h1>
<div style="display: grid; grid-template-columns: repeat(4, 225px); gap: 22px 28px">{cells}</div>
</div>'''
wrap('Clothing mock-ups', body, 1080, 640, 'Merch.dc.html', 25600)
