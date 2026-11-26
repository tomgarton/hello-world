import sys, json, math, random, shutil, os
ROOT = sys.argv[1]
_s = open(ROOT + '/gen/scenes3.py').read()
exec(_s[:_s.index('# ---- BOARD ----')])
P = ROOT + '/project/'
SC = {n: s for n, s, _, _ in SCENES}
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
PW, PH = 390, 844

# ================= Wallpapers =================
def phone(inner, label, cap, note):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px; width: 184px"><svg role="img" aria-label="{label}" width="184" height="398" viewBox="0 0 {PW} {PH}" style="border-radius: 30px; display: block">{inner}</svg>'
            f'<div style="font-size: 14px; font-weight: 800">{cap}</div><div style="{T}; font-size: 12px">{note}</div></div>')
def clock(col, sub='Tuesday 10 November'):
    return (f'<text x="195" y="150" text-anchor="middle" font-family="system-ui, sans-serif" font-size="26" font-weight="600" fill="{col}" opacity="0.85">{sub}</text>'
            f'<text x="195" y="262" text-anchor="middle" font-family="system-ui, sans-serif" font-size="112" font-weight="700" fill="{col}" opacity="0.9">9:41</text>')
def lock(scene, sky, ink, extra=''):
    return f'<rect width="{PW}" height="{PH}" fill="{sky}"></rect>{extra}<g transform="translate(0 {PH-Hh})">{scene}</g>' + clock(ink)
night_stars = ''.join(f(quatre(x, y, r), MOON, 0.9) for x, y, r in ((60, 330, 5), (330, 380, 4), (120, 440, 3), (300, 480, 3), (40, 500, 4), (220, 400, 3)))
# a head in a round sticker with a coloured ring, like a badge
def badge(i, char, ring, bg, x, y, r=74, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot})"><circle r="{r+9}" fill="{PAPER}"></circle><circle r="{r+3}" fill="{ring}"></circle><circle r="{r-5}" fill="{bg}"></circle>'
            f'<clipPath id="bd{i}"><circle r="{r-5}"></circle></clipPath><g clip-path="url(#bd{i})"><svg x="{-r*1.02:.0f}" y="{-r*0.86:.0f}" width="{r*2.04:.0f}" height="{r*2.04:.0f}" viewBox="18 4 204 204">{char}</svg></g></g>')
def leaf(x, y, s, rot, c, w=2.4):
    d = f'M0 {-16*s}C{12*s} {-8*s} {12*s} {8*s} 0 {16*s}C{-12*s} {8*s} {-12*s} {-8*s} 0 {-16*s}Z'
    return f'<g transform="translate({x} {y}) rotate({rot})">' + stroke(d, c, w) + stroke(f'M0 {-12*s}V{22*s}M0 {-4*s}l{6*s} {-5*s}M0 {4*s}l{-6*s} {-5*s}M0 {10*s}l{5*s} {-4*s}', c, w*0.8) + '</g>'
def motif(c, seed=5, w=2.4):
    rnd = random.Random(seed); out = ''
    for row in range(11):
        for col in range(5):
            x = col*88 + (44 if row % 2 else 0) + rnd.uniform(-8, 8) - 6; y = row*84 + rnd.uniform(-8, 8)
            if (row + col) % 3 == 0: out += f'<g transform="translate({x:.0f} {y:.0f}) rotate({rnd.uniform(-20, 20):.0f})">' + stroke(petals4, c, w) + '</g>'
            else: out += leaf(x, y, 1.5, rnd.uniform(-50, 50), c, w)
    return out
def _pet():
    R_, r = 9.0, 9.6; cs = [(R_*math.cos(math.radians(-90 + i*90)), R_*math.sin(math.radians(-90 + i*90))) for i in range(4)]
    pts = []
    for i in range(4):
        c1, c2 = cs[i-1], cs[i]; mx, my = (c1[0]+c2[0])/2, (c1[1]+c2[1])/2; d = math.hypot(c2[0]-c1[0], c2[1]-c1[1]); h = math.sqrt(r*r - d*d/4); l = math.hypot(mx, my)
        pts.append((mx + mx/l*h, my + my/l*h))
    d = f'M{pts[0][0]:.1f} {pts[0][1]:.1f}'
    for i in range(4): q = pts[(i+1) % 4]; d += f'A{r} {r} 0 0 1 {q[0]:.1f} {q[1]:.1f}'
    return d + 'Z'
petals4 = _pet()
full = lambda arms, e_, col: pbody(arms, e_, col) + ACC['clip'](160, 56, WARATAH)
w_sticker = (f'<rect width="{PW}" height="{PH}" fill="{PAPER}"></rect>' + motif('#9FD3C2')
             + badge(1, full('down', 'happy', HARBOUR), BLUSH, SUN, 128, 250, 96, -10) + badge(2, friend('koala', 'dress', A) + ACC['bow'](150, 50, HARBOUR), SKY, PAPER, 268, 470, 90, 8)
             + badge(3, friend('echidna', 'dungarees', WARATAH), MINT, SHELL, 124, 680, 92, -6))
mono = lambda bg, line: friend('platypus', 'jumper', bg, mono=(bg, line))
def w_line_fn():
    rnd = random.Random(2); out = f'<rect width="{PW}" height="{PH}" fill="{BLUSH}"></rect>'
    for row in range(7):
        for col in range(3):
            x = col*150 + (75 if row % 2 else 0) - 20; y = row*134 - 30
            if (row*3 + col) % 2 == 0:
                out += f'<svg x="{x}" y="{y}" width="124" height="112" viewBox="34 36 172 156">{mono(BLUSH, PAPER)}</svg>'
            else:
                out += leaf(x + 62, y + 56, 2.0, rnd.uniform(-40, 40), PAPER, 3) if (row + col) % 3 else f'<g transform="translate({x+62} {y+56}) scale(2.2)">' + stroke(petals4, PAPER, 1.5) + '</g>'
    return out
def w_tile_fn():
    out = f'<rect width="{PW}" height="{PH}" fill="{A}"></rect>'
    for row in range(6):
        for col in range(3):
            x = col*170 + (85 if row % 2 else 0) - 40; y = row*160 - 20
            out += e(x + 78, y + 132, 54, 9, '#D9A31F') + f'<svg x="{x}" y="{y}" width="156" height="146" viewBox="0 0 240 270">{baby("happy", SKY)}</svg>'
    return out

# ---- second row: ideas from the Nintendo wallpapers ----
def tone_icon(name, c, x, y, s_, rot=0):
    ic = ICONS[name]
    inner = ''.join(f'<path d="{d}" fill="{c}"></path>' for d, _ in ic['bodies']) + ''.join(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"></path>' for d in ic['lines'])
    return f'<g transform="translate({x} {y}) rotate({rot} {12*s_} {12*s_}) scale({s_})">{inner}</g>'
def line_icon_c(name, c, x, y, s_, rot=0):
    ic = ICONS[name]
    inner = ''.join(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"></path>' for d in ic['lines'])
    return f'<g transform="translate({x} {y}) rotate({rot} {12*s_} {12*s_}) scale({s_})">{inner}</g>'
NAMES = list(ICONS)
def w_tone_fn():
    out = f'<rect width="{PW}" height="{PH}" fill="{A}"></rect>'; k = 0
    for row in range(10):
        for col in range(5):
            out += tone_icon(NAMES[k % len(NAMES)], '#E9AE1B', col*84 - 14 + (42 if row % 2 else 0), row*88 - 10, 2.6); k += 1
    out += e(128, 800, 110, 14, '#D9A31F') + e(280, 800, 96, 12, '#D9A31F')
    out += put(full('wave', 'happy', HARBOUR), 128, 800, 380) + put(friend('koala', 'dress', PAPER) + ACC['bow'](150, 50, HARBOUR), 284, 800, 350)
    return out
def w_parade_fn():
    G0, G1 = '#CFE5D2', '#BFDCC4'; out = f'<rect width="{PW}" height="{PH}" fill="{G0}"></rect>'
    for row in range(12):
        for col in range(5):
            x, y = col*84 + (42 if row % 2 else 0) + 6, row*64 + 20
            out += f(quatre(x, y, 9), G1) if (row + col) % 2 else f'<g transform="translate({x} {y}) rotate(30)">' + f('M0 -11C8 -5 8 6 0 11C-8 6 -8 -5 0 -11Z', G1) + '</g>'
    line_up = [(A_(grown('pop', SKY), 50, 716, 150), 0), (K_(pug('wave', 'happy', HARBOUR), 122, 716, 100), 0), (B_(178, 716), 0), (K_(quill(WARATAH), 232, 716, 94), 0), (K_(kip(A), 296, 716, 98), 0), (K_(digby(HARBOUR), 356, 716, 104), 0)]
    out += ''.join(sh(x, 716, 34, '#A9CDB1') for x in (50, 122, 178, 232, 296, 356)) + ''.join(a for a, _ in line_up)
    out += ''.join(f(scallop(x, 800, 40, 34, 8), T1) for x in range(0, 420, 60)) + ''.join(f(scallop(x, 824, 36, 30, 7), T2) for x in range(30, 420, 60))
    out += ''.join(f(quatre(x, y, 7), c) + f'<circle cx="{x}" cy="{y}" r="2" fill="{A}"></circle>' for x, y, c in ((40, 770, PAPER), (150, 782, BLUSH), (250, 768, PAPER), (340, 780, BLUSH), (100, 806, PAPER), (300, 812, PAPER)))
    return out
def w_dark_fn():
    rnd = random.Random(8); out = f'<rect width="{PW}" height="{PH}" fill="{N1}"></rect>'; k = 0
    for row in range(10):
        for col in range(4):
            x = col*104 + (52 if row % 2 else 0) - 20 + rnd.uniform(-6, 6); y = row*90 - 16 + rnd.uniform(-6, 6)
            out += line_icon_c(NAMES[k % len(NAMES)], MOON, x, y, 2.5, rnd.choice([-14, -6, 0, 8, 14])); k += 1
            out += f(quatre(x + 84, y + 52, 4), MOON, 0.8)
    return out
morning_clouds = cloudf(96, 392, 150, '#FBE7B4') + cloudf(300, 330, 110, '#FBE7B4') + cloudf(250, 470, 90, '#FBE7B4')
phones2 = (phone(w_tone_fn(), 'Puggle and Kip in front of a tone-on-tone pattern of activity icons on yellow', 'Tone on tone', 'The activity icons as a quiet pattern in one colour, with the cast in front at full size.')
           + phone(w_parade_fn(), 'The cast walking in a line along the bottom over a pale green pattern, with bushes in front', 'The parade', 'Everyone in a row along the bottom, a faint motif grid above, bushes and flowers in front.')
           + phone(w_dark_fn(), 'Line icons of bottles, moons, nappies and prams scattered on dark blue', 'Night lines', 'The activity icons as line drawings on night blue, with quatrefoil stars.'))
phones = (phone(lock(SC['Backyard'], Y0, INK, morning_clouds), 'Lock screen with the morning backyard scene at the bottom', 'Morning', 'Quiet sky for the clock; the scene sits at the bottom.')
          + phone(lock(SC['Night street'], N1, MOON, night_stars), 'Lock screen with the bedtime street scene at the bottom', 'Bedtime', 'The night street, with extra stars up the screen.')
          + phone(w_sticker, 'Sticker badges of Puggle, Kip and Quill on a gum leaf and quatrefoil pattern', 'Sticker heads', 'Round badges with coloured rings over a line pattern of gum leaves and quatrefoils.')
          + phone(w_line_fn(), 'One-colour line repeat of Puggle faces, gum leaves and quatrefoils on pink', 'One-colour line', 'Line-only Puggle, leaves and quatrefoils. Prints as one screen on fabric.')
          + phone(w_tile_fn(), 'Repeat of baby Pebble on yellow, each with a soft shadow', 'Pebble repeat', 'One character, brick repeat, a soft shadow under each.'))
wbody = f'''<div style="width: 1080px; height: 1150px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Wallpapers and repeats</h1>
<div style="{T}; font-size: 15px; max-width: 940px">Two kinds: scenes that leave the sky clear for the clock, and repeats built from the cast, the gum leaf and the quatrefoil.</div></div>
<div style="display: flex; justify-content: space-between">{phones}</div>
<div style="display: flex; gap: 22px; align-items: flex-start">{phones2}<div style="width: 400px; display: flex; flex-direction: column; gap: 8px; {T}"><div style="{H}">What the references taught us</div><div><b>Leave room.</b> The best phone wallpapers are mostly empty: one colour, a small scene or a row of characters at the bottom.</div><div><b>Tone on tone.</b> A pattern in a slightly deeper shade of the background gives richness without noise, and lets the cast stand in front.</div><div><b>One motif family.</b> Ours are the gum leaf, the quatrefoil and the activity icons. They repeat everywhere, like a house pattern.</div><div><b>Line and flat both work.</b> The same drawings as outlines on dark, or as flat shapes on colour.</div></div></div>
</div>'''

# ================= Books =================
def cover(title, scene, band, ink, label):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px"><div style="display: flex; box-shadow: 4px 6px 0 #C9B89F"><div style="width: 10px; background: {INK}"></div>'
            f'<div style="width: 218px; background: {band}; display: flex; flex-direction: column"><div style="height: 92px; box-sizing: border-box; padding: 14px 14px 0; font-size: 25px; font-weight: 800; line-height: 1.05; letter-spacing: -0.02em; color: {ink}">{title}</div>'
            f'<svg role="img" aria-label="{label}" width="218" height="168" viewBox="0 0 {W} {Hh}" style="display: block">{scene}</svg>'
            f'<div style="height: 26px; display: flex; align-items: center; padding: 0 14px; font-size: 11px; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; color: {ink}; opacity: 0.8">Puggle and Friends</div></div></div></div>')
covers = (cover('Puggle at<br>the Beach', SC['Beach'], BL0, INK, 'Book cover: Puggle at the Beach')
          + cover('Night Night,<br>Puggle', SC['Night street'], N1, MOON, 'Book cover: Night Night, Puggle')
          + cover('Puggle and the<br>Big Puddle', SC['Rainy day'], RG0, INK, 'Book cover: Puggle and the Big Puddle')
          + cover('Puggle Goes<br>to Nan’s', SC["Grandma's house"], BL0, INK, 'Book cover: Puggle Goes to Nan’s'))
spread = (f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="display: flex; box-shadow: 4px 6px 0 #C9B89F">'
          f'<div style="width: 330px; height: 300px; background: {PAPER}; box-sizing: border-box; padding: 40px 34px; display: flex; flex-direction: column; justify-content: center; gap: 14px; border-right: 2px solid #E4DAC6">'
          f'<div style="font-size: 30px; font-weight: 800; line-height: 1.12; letter-spacing: -0.02em; color: {INK}">One sock,<br>two socks,<br>three socks.</div><div style="font-size: 19px; font-weight: 600; line-height: 1.3; color: {INK}">“Where is the fourth sock?” says Puggle.</div></div>'
          f'<svg role="img" aria-label="Spread picture: the backyard in the morning, with the washing on the Hills Hoist" width="390" height="300" viewBox="0 0 {W} {Hh}" style="display: block">{SC["Backyard"]}</svg></div>'
          f'<div style="font-size: 14px; font-weight: 700">Spread: words on the left, one picture on the right</div></div>')
rules = [('One scene, one book', 'Each title lives in one place from the set, so the books and the app share a world.'),
         ('The cover is the scene', 'Title in the sky colour of the scene, picture below, series name at the foot, Ink spine.'),
         ('Few words', 'One or two short sentences a spread, in Bricolage. The picture carries the story.')]
rule_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 2px"><div style="font-size: 15px; font-weight: 800">{n}</div><div style="{T}; font-size: 12px">{d}</div></div>' for n, d in rules)
bbody = f'''<div style="width: 1080px; height: 790px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 24px">
<h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Books</h1>
<div style="display: flex; justify-content: space-between">{covers}</div>
<div style="display: flex; gap: 36px; align-items: flex-start">{spread}<div style="display: flex; flex-direction: column; gap: 14px; width: 220px">{rule_html}</div></div>
</div>'''

if __name__ == '__main__':
    c = json.load(open(P + 'canvas.json'))
    for old, new, title, y in (('Wallpapers.dc.html', 'WallpapersV1.dc.html', 'Wallpapers and repeats (first version)', 12000), ('Books.dc.html', 'BooksV1.dc.html', 'Books (first version)', 12800)):
        if not os.path.exists(P + new):
            shutil.copy(P + old, P + new)
            c['boards'][new] = dict(c['boards'][old], page='archive', x=0, y=y, title=title); c['order'].append(new)
    keep = {k: dict(c['boards'][k]) for k in ('Wallpapers.dc.html', 'Books.dc.html')}
    json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
    wrap('Wallpapers and repeats', wbody, 1080, 1150, 'Wallpapers.dc.html', 0)
    wrap('Books', bbody, 1080, 790, 'Books.dc.html', 0)
    c = json.load(open(P + 'canvas.json'))
    c['boards']['Wallpapers.dc.html'] = dict(keep['Wallpapers.dc.html'], h=1150)
    c['boards']['Books.dc.html'] = dict(keep['Books.dc.html'], h=790)
    c['boards']['Merch.dc.html']['y'] = 4090
    json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
