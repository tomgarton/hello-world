import sys, json, math, random
ROOT = sys.argv[1]
_n = open(ROOT + '/gen/night2.py').read()
exec(_n[:_n.index('def big(')])          # brings scene helpers, the cast (cx) and `after` (the bedtime scene)
bedtime = after
small, baby, friend = cx['x']['small'], cx['baby'], cx['inner']
def pug(arms, e, col): return small(pbody(arms, e, col)) + ACC['clip'](160, 56, WARATAH)
def put(svg, x, base, h, vb_h=300, vb_w=240):
    s = h / vb_h
    return f'<g transform="translate({x - vb_w*s/2:.1f} {base - h:.1f}) scale({s:.4f})">{svg}</g>'
def e(cx_, cy, rx, ry, c, o=1, rot=0):
    t = f' transform="rotate({rot} {cx_} {cy})"' if rot else ''
    return f'<ellipse cx="{cx_}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{c}"' + (f' opacity="{o}"' if o != 1 else '') + t + '></ellipse>'
def stroke(d, c, w, o=1): return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"' + (f' opacity="{o}"' if o != 1 else '') + '></path>'

# ---------------- Morning: backyard at sunrise ----------------
Y0, Y1, Y2 = '#FCEFC9', '#F9E09E', '#F4BE2C'          # sky, low sky, sun (Wattle)
F1, F2 = '#E9C877', '#D6AE55'                          # backlit fence, its gaps
L1, L2, L3 = '#CFE5D2', '#B2D3B9', '#8FBE9B'           # lawn, shadow, deep shadow
T1, T2 = '#3C9A5F', '#2E7549'                          # Gum, deep Gum
HZ = 196
def fence_m():
    out = ''; x = -6
    while x < W + 6:
        out += f(f'M{x} {HZ+2}V{HZ-58}Q{x+8} {HZ-68} {x+16} {HZ-58}V{HZ+2}Z', F1); x += 18
    return out + f(f'M-6 {HZ-44}H{W+6}v7H-6Z', F2, 0.55) + f(f'M-6 {HZ-18}H{W+6}v7H-6Z', F2, 0.55)
def hoist_m(x, y, h=150):
    top = y - h
    out = stroke(f'M{x} {y}V{top}', T2, 5) + stroke(f'M{x-62} {top+8}L{x} {top-10}L{x+62} {top+8}L{x} {top+26}Z', T2, 3) + stroke(f'M{x-62} {top+8}H{x+62}', T2, 2)
    out += f(f'M{x-52} {top+12}h22v8l-4 3v14h-14v-14l-4-3z', BLUSH) + f(f'M{x-22} {top+19}h18v24q-9 6-18 0z', SKY) + f(R(x+8, top+15, 24, 28, 4), PAPER) + f(R(x+38, top+10, 16, 20, 4), SKY)
    return out
def lemon_m(x, y):
    out = f(f'M{x-5} {y}V{y-70}h10V{y}Z', T2) + f(scallop(x, y-104, 62, 50, 9), T1) + f(scallop(x+14, y-92, 40, 32, 7), T2)
    for dx, dy in ((-30, -112), (-8, -84), (-40, -86), (6, -128), (-22, -134)): out += e(x+dx, y+dy, 6, 4.6, Y2)
    return out
def leaves(x, y, c):
    return ''.join(e(x + dx, y + dy, 34*s, 11*s, c, 1, r) for dx, dy, r, s in ((0, 0, -50, 1), (26, 6, -28, 1.1), (-14, 12, -72, 0.9), (48, 20, -12, 1), (10, 30, -40, 1.15)))
O = INK
FAR = '#F5D98C'                                         # rooftops between sky and fence
LIT = '#E3F1E0'                                         # sunlit lawn
def fence_m2():
    out = ''; x = -6
    while x < W + 6:
        out += f(f'M{x} {HZ+2}V{HZ-58}Q{x+8} {HZ-68} {x+16} {HZ-58}V{HZ+2}Z', F1) + f(f'M{x+11} {HZ+2}V{HZ-62}Q{x+14} {HZ-60} {x+16} {HZ-58}V{HZ+2}Z', F2, 0.45)
        out += stroke(f'M{x+2} {HZ-59}Q{x+8} {HZ-67} {x+13} {HZ-61}', PAPER, 1.6, 0.8); x += 18                      # sun catching the tops
    return out + f(f'M-6 {HZ-44}H{W+6}v7H-6Z', F2, 0.5) + f(f'M-6 {HZ-18}H{W+6}v7H-6Z', F2, 0.5)
def fence_shadow():
    d = f'M-6 {HZ}H{W+6}V{HZ+26}'; x = W + 6
    while x > -6: d += f'q-4.5 9 -9 0q-4.5 -5 -9 0'; x -= 18
    return f(d + 'Z', L2)
def rooftops():
    return (f(f'M96 {HZ-40}V{HZ-84}L134 {HZ-112}L172 {HZ-84}V{HZ-40}Z', FAR) + f(R(150, HZ-116, 10, 22, 2), FAR)
            + f(f'M324 {HZ-40}V{HZ-76}Q356 {HZ-100} 388 {HZ-76}V{HZ-40}Z', FAR) + f(R(338, HZ-104, 9, 20, 2), FAR)
            + f(scallop(40, HZ-78, 44, 30, 8), FAR))
def magpie(x, y):
    return (e(x, y-9, 13, 8.5, O) + f'<circle cx="{x+11}" cy="{y-17}" r="6.5" fill="{O}"></circle>' + f(f'M{x+16} {y-18}l9 2.5-8.5 2z', '#C9D0D6')
            + f(f'M{x-12} {y-10}l-13 7 2 -9z', O) + e(x-2, y-12, 7, 3.4, PAPER, 1, -12) + e(x+7, y-21, 3.4, 2.2, PAPER, 1, -30)
            + stroke(f'M{x-2} {y-1}v5M{x+4} {y-1}v5', O, 1.6) + f'<circle cx="{x+13}" cy="{y-18}" r="1.1" fill="{Y2}"></circle>')
def dew():
    return ''.join(f(quatre(x, y, r), PAPER, 0.9) for x, y, r in ((118, 250, 3.2), (150, 278, 2.4), (236, 262, 2.8), (300, 252, 2.2), (332, 280, 3), (180, 236, 2), (270, 238, 2.2)))
def ball(x, y, r=11):
    return e(x + 3, y + 1, r*1.1, 3.4, L3) + f'<circle cx="{x}" cy="{y-r}" r="{r}" fill="{WARATAH}"></circle>' + f(f'M{x-r} {y-r}a{r} {r} 0 0 1 {2*r} 0q-{r} -5 -{2*r} 0z', PAPER, 0.9) + e(x - r*0.35, y - r*1.45, r*0.22, r*0.14, PAPER, 0.8, -25)
morning = (f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{Y0}"></rect>' + f(f'M0 112H{W}V{HZ}H0Z', Y1)
           + f'<circle cx="236" cy="166" r="132" fill="{PAPER}" opacity="0.35"></circle><circle cx="236" cy="166" r="104" fill="{PAPER}" opacity="0.5"></circle><circle cx="236" cy="166" r="76" fill="{Y2}"></circle>'   # one big shape, with a glow
           + rooftops() + stroke('M56 54q8 -8 16 0q8 -8 16 0', F2, 2.6) + stroke('M104 36q6 -6 12 0q6 -6 12 0', F2, 2.2)
           + fence_m2() + magpie(150, HZ-64)
           + f(f'M0 {HZ}H{W}V{Hh}H0Z', L1) + f(f'M96 {Hh}L150 {HZ+20}H322L372 {Hh}Z', LIT)                                                               # sunlight pooling on the lawn
           + fence_shadow()
           + f(f'M60 {HZ+24}L10 {Hh}H70L72 {HZ+24}Z', L2) + f(f'M36 {HZ+60}L-6 {HZ+96}V{HZ+70}Z', L2, 0.0) + f(f'M330 {HZ+24}L318 {Hh}H{W}V{HZ+24}Z', L2)
           + dew() + hoist_m(66, 262) + lemon_m(366, 250)
           + f(f'M168 291Q150 {Hh} 96 {Hh+8}H190Q214 {Hh} 222 291Z', L3) + f(f'M250 291Q244 {Hh} 220 {Hh+8}H262Q274 {Hh} 274 291Z', L3)                    # their shadows fall towards us
           + ball(322, 286)
           + put(pug('up', 'happy', SKY), 196, 290, 86) + put(small(baby('happy', A)), 262, 291, 52, 270)
           + leaves(-8, 262, T2))

# ---------------- Celebration ----------------
C0, C1, C2 = '#F6DCCB', '#EFC4AE', '#DDA78E'          # wall, floor, shadow (Shell family)
G0, G1 = '#F4BE2C', '#F9D465'                          # Wattle, light Wattle
def balloon(x, y, r, c, sway=0):
    return (stroke(f'M{x} {y+r}q{sway} 40 {sway*0.4:.0f} 86', C2, 1.6) + e(x, y, r*0.86, r, c) + f(f'M{x-4} {y+r-1}h8l-4 7z', c) + e(x - r*0.3, y - r*0.4, r*0.16, r*0.28, PAPER, 0.7, -20))
def bunting_c(y):
    out = stroke(f'M-6 {y}Q{W/2} {y+34} {W+6} {y}', C2, 1.8); n = 11
    for i in range(n):
        t = (i + 0.5)/n; x = -6 + (W + 12)*t; yy = y + 34*2*t*(1-t)
        out += f(rpoly([(x-10, yy), (x+10, yy), (x, yy+20)], 2.5), (PAPER, SKY, G0)[i % 3])
    return out
def confetti():
    rnd = random.Random(11); out = ''
    for _ in range(46):
        x, y = rnd.uniform(6, W - 6), rnd.uniform(44, 276)
        if 128 < x < 262 and 110 < y < 290: continue
        c = rnd.choice([PAPER, SKY, WARATAH, G1]); k = rnd.random()
        if k < 0.4: out += f(quatre(x, y, rnd.uniform(3.5, 6)), c)
        elif k < 0.7: out += f'<rect x="{x:.1f}" y="{y:.1f}" width="11" height="4.6" rx="2.3" fill="{c}" transform="rotate({rnd.uniform(-60, 60):.0f} {x:.1f} {y:.1f})"></rect>'
        else: out += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rnd.uniform(2, 3.4):.1f}" fill="{c}"></circle>'
    return out
celebrate = (f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{C0}"></rect>' + f(f'M0 236H{W}V{Hh}H0Z', C1)
             + f(quatre(195, 150, 132), G0) + f(quatre(195, 150, 96), G1)                                                                             # one big shape
             + bunting_c(8) + balloon(40, 96, 30, SKY, -8) + balloon(84, 132, 24, PAPER, 6) + balloon(372, 110, 34, SKY, -10) + confetti()
             + e(196, 288, 48, 7, C2) + e(96, 286, 34, 5.5, C2) + e(304, 286, 36, 5.5, C2)
             + put(small(friend('echidna', 'dungarees', SKY)), 96, 287, 80) + put(small(friend('koala', 'dress', PAPER)) + ACC['bow'](150, 50, HARBOUR), 304, 287, 84)
             + put(pug('tada', 'proud', WARATAH), 196, 289, 92))

# ---------------- board ----------------
def phone(scene, label, date, greet, row_icon, row_text, row_sub, bg):
    return (f'<div style="width: 320px; border-radius: 34px; overflow: hidden; background: {bg}; display: flex; flex-direction: column">'
            f'<svg role="img" aria-label="{label}" width="320" height="246" viewBox="0 0 {W} {Hh}" style="display: block">{scene}</svg>'
            f'<div style="background: {PAPER}; border-radius: 26px 26px 0 0; padding: 16px 18px 18px; display: flex; flex-direction: column; gap: 10px; position: relative">'
            f'<div><div style="font-family: system-ui; font-size: 12px; color: #6B5E52">{date}</div><div style="font-size: 26px; font-weight: 800; letter-spacing: -0.02em">{greet}</div></div>'
            f'<div style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: {SAND}; border-radius: 16px"><div style="width: 34px; height: 34px; border-radius: 10px; background: {PAPER}; display: flex; align-items: center; justify-content: center">'
            f'<svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">{line_icon(row_icon)}</svg></div><div style="font-family: system-ui"><div style="font-size: 14px; font-weight: 700">{row_text}</div><div style="font-size: 12px; color: #6B5E52">{row_sub}</div></div></div></div></div>')
def chips(cols): return ''.join(f'<div style="width: 22px; height: 22px; border-radius: 99px; background: {c}; border: 1.4px solid rgba(58,42,32,0.25)"></div>' for c in cols)
def col(ph, title, key, notes):
    return (f'<div style="display: flex; flex-direction: column; gap: 10px; width: 320px">{ph}<div style="display: flex; align-items: center; gap: 10px"><div style="font-size: 18px; font-weight: 800">{title}</div><div style="display: flex; gap: 4px">{chips(key)}</div></div>'
            f'<div style="{T}">{notes}</div></div>')
cols = (col(phone(morning, 'Morning scene: Puggle and Pebble in the backyard at sunrise', 'Tuesday 10 November', 'Good morning', 'Bottle', 'Bottle, 150 ml', '6:40 am, Bea', L1),
            'Morning', [Y0, Y2, L1, T1], '<b>Big shape:</b> the sun and its glow, rising over the neighbours\u2019 roofs. <b>Light:</b> paling tops catch the sun, the fence throws a scalloped shadow, sunlight pools on the lawn. <b>Moment:</b> Puggle stretches, Pebble is already up, a magpie sings on the fence.')
        + col(phone(bedtime, 'Bedtime scene: Puggle under the street lamp saying goodnight to the moon', 'Tuesday 10 November', 'Goodnight', 'Sleep', 'Asleep 12 min', 'since 7:05 pm, Ollie', N2),
              'Bedtime', [N1, N3, MOON, A], '<b>Big shape:</b> the moon behind the roofs. <b>Light:</b> moonlit roof edges, lit windows, lamplight and her shadow. <b>Moment:</b> goodnight to the moon; the cat watches. The lit doorway has moved off her head.')
        + col(phone(celebrate, 'Celebration scene: Puggle with Quill and Kip, balloons and confetti', 'Tuesday 10 November', 'First steps!', 'Milestone', 'Ollie walked today', 'Tap to add a photo', C1),
              'Celebration', [C0, G0, SKY, PAPER], '<b>Big shape:</b> a giant quatrefoil, Puggle’s own mark. <b>Light:</b> soft floor shadows only; the colour does the shouting. <b>Moment:</b> ta-da, with Quill and Kip cheering, in their small versions.'))
body = f'''<div style="width: 1080px; height: 830px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Three scenes for the app</h1>
<div style="{T}; font-size: 15px; max-width: 940px">The new approach, on the scenes the app needs first: the Today header in the morning and at night, and a milestone. The world is flat shapes in a three-colour key; only the cast has a line.</div></div>
<div style="display: flex; gap: 12px; justify-content: space-between">{cols}</div>
</div>'''
wrap('Three scenes for the app', body, 1080, 830, 'AppScenes.dc.html', 0)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['AppScenes.dc.html'].update(page='app', x=1200, y=4990)
o = c['order']; o.remove('AppScenes.dc.html'); o.insert(o.index('PuggleStyle.dc.html'), 'AppScenes.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
