import sys, json, math
ROOT = sys.argv[1]
_s = open(ROOT + '/gen/scenes2.py').read()
exec(_s[:_s.index('# ---------------- rules diagram ----------------')])
BEFORE = dict((n, s) for n, s, _ in SCENES)['Night street']
_l = open(ROOT + '/gen/lineup.py').read()
cx = {'__name__': 'x', 'sys': sys}
exec(_l[:_l.index('GROUND = 470')], cx)
pbody, ACC = cx['x']['body'], cx['A']

# One colour in four tones, plus Moon and Wattle. No outlines on the world.
N0, N1, N2, N3, N4 = '#121831', '#1B2440', '#27315A', '#323E6E', '#42508A'
def f(d, c, o=1): return f'<path d="{d}" fill="{c}"' + (f' opacity="{o}"' if o != 1 else '') + '></path>'
def win(x, y, w, h, lit=True):
    out = f(R(x, y, w, h, 3), A if lit else N1)
    if lit: out = out + f(f'M{x+w/2-0.8} {y}h1.6v{h}h-1.6z', N3, 0.8)
    return out
def mix(c1, c2, t):
    a_, b_ = [int(c1[i:i+2], 16) for i in (1, 3, 5)], [int(c2[i:i+2], 16) for i in (1, 3, 5)]
    return '#' + ''.join(f'{round(x_ + (y_ - x_)*t):02X}' for x_, y_ in zip(a_, b_))
def house(x, base, w, h, roof, wins, door=None, tint=None):
    top = base - h
    c_body, c_lit = (mix(N3, tint, 0.26), mix(N4, tint, 0.34)) if tint else (N3, N4)   # each house keeps a whisper of its daytime colour
    out = f(f'M{x} {base}V{top}H{x+w}V{base}Z', c_body) + f(f'M{x+w*0.72} {base}V{top}H{x+w}V{base}Z', c_lit)   # moonlit right side
    if roof == 'pitch':
        out += f(f'M{x-3} {top}L{x+w/2} {top-26}L{x+w+3} {top}Z', N0) + f'<path d="M{x+w/2} {top-26}L{x+w+3} {top}" stroke="{MOON}" stroke-width="1.6" stroke-linecap="round" opacity="0.55" fill="none"></path>'
    elif roof == 'round':
        out += f(f'M{x} {top}V{top-10}Q{x+w/2} {top-30} {x+w} {top-10}V{top}Z', N0) + f'<path d="M{x+w/2} {top-20}Q{x+w*0.8} {top-18} {x+w} {top-10}" stroke="{MOON}" stroke-width="1.6" stroke-linecap="round" opacity="0.55" fill="none"></path>'
    else:
        out += f(R(x-2, top-8, w+4, 10, 2), N0)
    out += f(R(x+w*0.62, top-(26 if roof == 'pitch' else 20), 8, 16, 1.5), N0)                                # chimney
    for wx, wy, lit in wins: out += win(x + w*wx, top + h*wy, w*0.2, h*0.2, lit)
    if door is not None:
        dx = x + w*0.4
        out += f(R(dx, base - h*0.34, w*0.2, h*0.34, 3), A if door else N1)
        if door: out += f(f'M{dx} {base}h{w*0.2}l22 44h-64z', '#5B6AA6', 0.8)
    return out
def stars():
    pts = ((40, 36, 5), (96, 70, 3), (150, 30, 4), (206, 58, 3), (236, 22, 5), (372, 150, 3), (20, 120, 3), (176, 96, 2.5))
    return ''.join(f(quatre(x, y, s), MOON, 0.9) for x, y, s in pts)
def branch():
    out = f'<path d="M-6 30Q60 40 124 18" stroke="{N0}" stroke-width="7" stroke-linecap="round" fill="none"></path>'
    for x, y, r, s in ((20, 44, 40, 14), (66, 52, 20, 12), (100, 36, -10, 13), (40, 14, -30, 12), (128, 20, 30, 11), (84, 18, -20, 12), (4, 70, 60, 15)):
        out += f'<ellipse cx="{x}" cy="{y}" rx="{s*1.6:.1f}" ry="{s*0.62:.1f}" fill="{N0}" transform="rotate({r} {x} {y})"></ellipse>'
    return out
def catsil(x, y):
    return (f(f'M{x-11} {y}Q{x-13} {y-17} {x-3} {y-21}Q{x+6} {y-23} {x+10} {y-13}Q{x+12} {y-5} {x+12} {y}Z', N0) + f'<circle cx="{x+2}" cy="{y-24}" r="8" fill="{N0}"></circle>'
            + f(f'M{x-5} {y-29}l1-9 6 5zM{x+9} {y-29}l-1-9-6 5z', N0) + f'<path d="M{x+12} {y-2}q12 0 10-14" stroke="{N0}" stroke-width="3" stroke-linecap="round" fill="none"></path>'
            + f'<circle cx="{x-1}" cy="{y-25}" r="1.4" fill="{A}"></circle><circle cx="{x+6}" cy="{y-25}" r="1.4" fill="{A}"></circle>')
def lampsil(x, y, h=118):
    return (f'<circle cx="{x}" cy="{y-h}" r="22" fill="{MOON}" opacity="0.22"></circle>'
            + f(f'M{x-2.2} {y}V{y-h+8}h4.4V{y}Z', N0) + f(R(x-9, y-h-8, 18, 16, 6), A) + f(R(x-11, y-h-11, 22, 5, 2), N0))
base = 226
after = (f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{N1}"></rect>'
         + f'<circle cx="300" cy="96" r="92" fill="{MOON}" opacity="0.07"></circle><circle cx="300" cy="96" r="66" fill="{MOON}"></circle>'   # one big shape
         + f'<circle cx="276" cy="78" r="9" fill="#E9D2A4"></circle><circle cx="322" cy="112" r="14" fill="#E9D2A4"></circle><circle cx="306" cy="62" r="5" fill="#E9D2A4"></circle>'
         + stars()
         + house(-8, base, 76, 82, 'pitch', ((0.2, 0.22, True), (0.6, 0.22, False)), True, SHELL)
         + house(70, base, 64, 112, 'flat', ((0.16, 0.14, False), (0.6, 0.14, True), (0.16, 0.46, True)), None, SKY)
         + house(136, base, 84, 74, 'round', ((0.14, 0.24, True), (0.66, 0.24, True)), False, MINT)
         + house(222, base, 70, 104, 'pitch', ((0.18, 0.18, False), (0.6, 0.18, False), (0.6, 0.5, True)), None, BLUSH)
         + house(294, base, 104, 88, 'round', ((0.14, 0.22, True), (0.44, 0.22, False), (0.74, 0.22, True)), False, SUN)
         + f(f'M-4 {base}H{W+4}V{Hh+4}H-4Z', N2) + f(f'M-4 {base}H{W+4}v5H-4Z', N1, 0.6)
         + f(f'M-4 {base-14}H128V{base}H-4Z', N1) + f(f'M224 {base-14}H{W+4}V{base}H224Z', N1) + catsil(254, base - 14)
         + f'<ellipse cx="236" cy="284" rx="124" ry="18" fill="{N3}"></ellipse><ellipse cx="262" cy="284" rx="66" ry="9.5" fill="{N4}"></ellipse>'
         + lampsil(302, 286)
         + f'<ellipse cx="164" cy="287" rx="38" ry="6" fill="{N0}" opacity="0.55"></ellipse>'                                              # Puggle's cast shadow, away from the lamp
         + f'<g transform="translate(160 205) scale(0.275)">{cx["x"]["small"](pbody("down", "happy", SKY)) + ACC["clip"](160, 56, WARATAH)}</g>'
         + branch())

def big(svg_inner, label):
    return f'<svg role="img" aria-label="{label}" width="476" height="366" viewBox="0 0 {W} {Hh}" style="border-radius: 26px; display: block">{svg_inner}</svg>'
notes = [('World without outlines', 'Houses, wall, lamp and branch are flat shapes. Only Puggle keeps the Ink line, so she is the first thing you see.'),
         ('Three colours', 'Night in four tones, Moon, and Wattle for every light. Her blue pyjamas and red clip are the only other colour.'),
         ('One big shape', 'The moon is huge and sits behind the roofline. Roofs overlap it; a gum branch crops the top corner.'),
         ('Light', 'Moonlit right sides and roof edges, glowing windows, a lit doorway, a pool of lamplight and her cast shadow.'),
         ('A moment', 'Puggle, in pyjamas, out to say goodnight to the moon; the cat watches from the wall.')]
note_html = ''.join(f'<div style="flex: 1; display: flex; flex-direction: column; gap: 3px"><div style="font-size: 15px; font-weight: 800">{i+1}. {n}</div><div style="{T}; font-size: 12px">{d}</div></div>' for i, (n, d) in enumerate(notes))
body = f'''<div style="width: 1080px; height: 660px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Night street, a different approach</h1>
<div style="{T}; font-size: 15px">A test on one scene before touching the other eleven. Same place, same kit, drawn as a picture, not a set of icons.</div></div>
<div style="display: flex; gap: 32px"><div style="display: flex; flex-direction: column; gap: 6px">{big(BEFORE, "Night street, current version")}<div style="font-size: 15px; font-weight: 800">Now</div></div>
<div style="display: flex; flex-direction: column; gap: 6px">{big(after, "Night street, new approach with Puggle under the lamp")}<div style="font-size: 15px; font-weight: 800">Proposed</div></div></div>
<div style="display: flex; gap: 18px">{note_html}</div>
</div>'''
wrap('Night street, a different approach', body, 1080, 660, 'NightTest.dc.html', 0)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['NightTest.dc.html'].update(page='brand', x=2400, y=3640)
o = c['order']; o.remove('NightTest.dc.html'); o.insert(o.index('Scenes.dc.html') + 1, 'NightTest.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
