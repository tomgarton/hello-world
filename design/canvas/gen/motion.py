import sys, json, math, random, os
ROOT = sys.argv[1]
_p = open(ROOT + '/gen/puggle3.py').read()
exec(_p[:_p.index('def fig(')])                    # character parts, colours, walk()
sc = {'__name__': 'x', 'sys': sys}
_t = open(ROOT + '/gen/three.py').read()
exec(_t[:_t.index('# ---------------- board ----------------')], sc)   # the three app scenes and their helpers
W, Hh = 390, 300

# ---------- animation helpers (SMIL; these loops stand in for Rive timelines) ----------
def spl(n): return ';'.join(['0.4 0 0.6 1'] * (n - 1))
def at(kind, values, dur, begin=0, kt=None):
    n = len(values.split(';'))
    k = f' keyTimes="{kt}"' if kt else ''
    return f'<animateTransform attributeName="transform" type="{kind}" values="{values}" dur="{dur}s" begin="{begin}s" repeatCount="indefinite" calcMode="spline" keySplines="{spl(n)}"{k}></animateTransform>'
def an(attr, values, dur, begin=0, kt=None, discrete=False):
    n = len(values.split(';'))
    k = f' keyTimes="{kt}"' if kt else ''
    mode = ' calcMode="discrete"' if discrete else f' calcMode="spline" keySplines="{spl(n)}"'
    return f'<animate attributeName="{attr}" values="{values}" dur="{dur}s" begin="{begin}s" repeatCount="indefinite"{mode}{k}></animate>'
def G(inner, anim='', gid=None): return f'<g{" data-part=" + chr(34) + gid + chr(34) if gid else ""}>{anim}{inner}</g>'

# ---------- Puggle, rigged into named parts ----------
def eyes(kind, blink=True):
    if kind == 'open':
        b = an('ry', '7.6;7.6;0.9;7.6;7.6', 4.2, 0, '0;0.9;0.94;0.98;1') if blink else ''
        return ''.join(f'<ellipse cx="{x0}" cy="108" rx="7.6" ry="7.6" fill="{O}">{b}</ellipse>' for x0 in (93, 147))
    if kind == 'happy': return ''.join(f'<path d="M{x0-10} 111q10 -12 20 0" fill="none" stroke="{O}" stroke-width="6.5" stroke-linecap="round"></path>' for x0 in (93, 147))
    return ''.join(f'<path d="M{x0-9} 108q9 9 18 0" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>' for x0 in (93, 147))
def headparts(kind, blink=True, a_clip='', a_eyes='', eyes_svg=None):
    return (G(f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>', '', 'head-shape')
            + G(''.join(f'<circle cx="{x0}" cy="127" r="10" fill="{BL}"></circle><path d="M{x0-7} 132l5-9M{x0+2} 132l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>' for x0 in (67, 173)), '', 'blush')
            + G(f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>', '', 'bill')
            + G(eyes_svg if eyes_svg is not None else eyes(kind, blink), a_eyes, 'eyes') + G(ACC['clip'](160, 56, WARATAH), a_clip, 'clip'))
def rig(col, arms, eye, a_tail='', a_armL='', a_armR='', a_head='', a_body='', a_all='', blink=True, a_clip='', a_eyes='', a_squash='', eyes_svg=None):
    (lx0, ly0, lx1, ly1, lb), (rx0, ry0, rx1, ry1, rb) = X['ARMS'][arms]
    inner = (G(p['tail'](PF), a_tail, 'tail') + G(p['legs'](PF) + p['feet'](BILL), '', 'legs')
             + G(G(p['trap'](col) + p['pocket'](210), '', 'dress') + G(limb(lx0, ly0, lx1, ly1, col, lb), a_armL, 'arm-left') + G(limb(rx0, ry0, rx1, ry1, col, rb), a_armR, 'arm-right')
                 + G(headparts(eye, blink, a_clip, a_eyes, eyes_svg), a_head, 'head'), a_body, 'upper'))
    if a_squash:   # squash and stretch about the feet
        inner = f'<g transform="translate(120 290)"><g data-m="1">{a_squash}<g transform="translate(-120 -290)">{inner}</g></g></g>'
    return G(inner, a_all, 'puggle')
def shadow(anim=''): return f'<ellipse cx="124" cy="290" rx="62" ry="8" fill="#3A2A20" opacity="0.14">{anim}</ellipse>'

KT_J = '0;0.16;0.42;0.62;0.74;0.86;1'          # hooray: rest, crouch, peak, land, squash, recover, rest
idle = shadow() + rig(HARBOUR, 'down', 'open',
                      a_tail=at('rotate', '-4 160 240;5 160 240;-4 160 240;-4 160 240;12 160 240;-6 160 240;-4 160 240', 7.2, 0, '0;0.17;0.34;0.6;0.66;0.74;1'),      # drift, then a flick
                      a_armL=at('rotate', '0 88 178;3 88 178;0 88 178', 3.6, 0.2), a_armR=at('rotate', '0 152 178;-3 152 178;0 152 178', 3.6, 0.2),
                      a_head=at('translate', '0 0;0 2;0 0', 3.6, 0.15), a_body=at('translate', '0 0;0 1.4;0 0', 3.6),
                      a_eyes=at('translate', '0 0;0 0;5 0;5 0;0 0;0 0', 7.2, 0, '0;0.3;0.36;0.5;0.56;1'), a_clip=at('translate', '0 0;0 1.2;0 0', 3.6, 0.3))
# wave: the arm starts down, dips first (anticipation), swings up, waves twice, comes back; head and tail follow late
KT_W = '0;0.08;0.24;0.36;0.48;0.6;0.72;0.9;1'
wave = shadow() + rig(HARBOUR, 'down', 'happy',
                      a_armR=at('rotate', '0 152 178;9 152 178;-82 152 178;-64 152 178;-82 152 178;-64 152 178;-80 152 178;4 152 178;0 152 178', 2.6, 0, KT_W),
                      a_head=at('rotate', '0 120 170;-1.5 120 170;4 120 170;3 120 170;4.5 120 170;3 120 170;4 120 170;-1 120 170;0 120 170', 2.6, 0.08, KT_W),
                      a_body=at('rotate', '0 120 250;-1 120 250;2 120 250;2 120 250;2 120 250;2 120 250;2 120 250;0 120 250;0 120 250', 2.6, 0, KT_W),
                      a_tail=at('rotate', '0 160 240;-6 160 240;10 160 240;-4 160 240;10 160 240;-4 160 240;8 160 240;-3 160 240;0 160 240', 2.6, 0.12, KT_W),
                      a_clip=at('rotate', '0 160 70;0 160 70;-10 160 70;6 160 70;-8 160 70;5 160 70;-5 160 70;3 160 70;0 160 70', 2.6, 0.14, KT_W))
sparks = ''.join(f'<g fill="{A}" opacity="0">{quatre(x, y, r)}{an("opacity", "0;0;1;0;0", 1.8, 0, "0;0.36;0.46;0.7;1")}</g>' for x, y, r in ((36, 60, 16), (206, 44, 20), (210, 130, 12), (28, 140, 12)))
hooray = (shadow(an('rx', '62;70;38;66;72;62;62', 1.8, 0, KT_J)) + sparks
          + rig(WARATAH, 'up', 'happy',
                a_squash=at('scale', '1 1;1.1 0.86;0.93 1.1;1 1;1.12 0.84;0.97 1.04;1 1', 1.8, 0, KT_J),
                a_all=at('translate', '0 0;0 0;0 -38;0 0;0 0;0 0;0 0', 1.8, 0, KT_J),
                a_tail=at('rotate', '0 160 240;-10 160 240;18 160 240;-6 160 240;-14 160 240;6 160 240;0 160 240', 1.8, 0.07, KT_J),             # lags the body
                a_armL=at('rotate', '0 88 178;-34 88 178;6 88 178;0 88 178;-16 88 178;4 88 178;0 88 178', 1.8, 0.04, KT_J),
                a_armR=at('rotate', '0 152 178;34 152 178;-6 152 178;0 152 178;16 152 178;-4 152 178;0 152 178', 1.8, 0.04, KT_J),
                a_head=at('translate', '0 0;0 4;0 -3;0 0;0 6;0 -1;0 0', 1.8, 0.05, KT_J),
                a_clip=at('translate', '0 0;0 3;0 -7;0 2;0 7;0 -3;0 0', 1.8, 0.1, KT_J)))
# falling asleep: eyes droop in two tries, the head nods further each time, then she is out
KT_S = '0;0.14;0.24;0.4;0.52;0.66;0.9;1'
drowsy = ''.join(f'<ellipse cx="{x0}" cy="108" rx="7.6" ry="7.6" fill="{O}">{an("ry", "7.6;3;6.5;2.2;5;1;1;7.6", 7, 0, KT_S)}</ellipse>' for x0 in (93, 147))
zz = ''.join(f'<text x="{186 + i*12}" y="{60 - i*8}" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="{26 - i*5}" fill="{O}" opacity="0">z{an("opacity", "0;0;1;1;0", 7, 0, "0;%.2f;%.2f;0.9;1" % (0.66 + i*0.05, 0.72 + i*0.05))}{at("translate", "0 10;0 10;0 -12;0 -12", 7, 0, "0;%.2f;0.9;1" % (0.66 + i*0.05))}</text>' for i in range(3))
sleepy = shadow() + zz + rig(SKY, 'down', 'sleepy', eyes_svg=drowsy, blink=False,
                             a_head=at('rotate', '0 120 170;4 120 170;1 120 170;7 120 170;2 120 170;9 120 170;9 120 170;0 120 170', 7, 0, KT_S),
                             a_body=at('translate', '0 0;0 2;0 0;0 3;0 1;0 4;0 4;0 0', 7, 0, KT_S),
                             a_tail=at('rotate', '0 160 240;2 160 240;0 160 240;4 160 240;2 160 240;8 160 240;8 160 240;0 160 240', 7, 0.2, KT_S),
                             a_armL=at('rotate', '0 88 178;0 88 178;0 88 178;-3 88 178;-3 88 178;-6 88 178;-6 88 178;0 88 178', 7, 0, KT_S),
                             a_armR=at('rotate', '0 152 178;0 152 178;0 152 178;3 152 178;3 152 178;6 152 178;6 152 178;0 152 178', 7, 0, KT_S))
# walk: four keys per step (contact, down, passing, up); arms and legs mirror, so one step loops
WK = [dict(name='Contact', back=(78, 272, 10), front=(152, 270, -16), bob=0, ab=(82, 218), af=(158, 212), tail=22, note='Legs widest. Heel strikes. Arms widest, opposite the legs.'),
      dict(name='Down', back=(88, 276, 24), front=(142, 276, 0), bob=5, ab=(92, 222), af=(148, 218), tail=26, note='Weight lands. Lowest point. Tail drops late.'),
      dict(name='Passing', back=(126, 260, -22), front=(112, 276, 0), bob=-2, ab=(108, 224), af=(130, 224), tail=14, note='Free leg passes the standing leg. Arms cross.'),
      dict(name='Up', back=(150, 258, -26), front=(100, 274, 8), bob=-7, ab=(124, 220), af=(112, 222), tail=8, note='Push off. Highest point. Tail lifts.')]
def walk4(k, col=HARBOUR, head_bob=None):
    w_ = WK[k]; hb = WK[k-1]['bob'] if head_bob is None else head_bob          # the head arrives a beat late
    (bx, by, bl), (fx, fy, fl) = w_['back'], w_['front']
    legs = leg(104, 238, bx, by, bl) + leg(124, 238, fx, fy, fl)
    body_ = (f'<ellipse cx="54" cy="238" rx="40" ry="14" transform="rotate({w_["tail"]} 54 238)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' + limb(112, 180, *w_['ab'], col, 4)
             + f'<path d="M92 166Q118 158 144 166L160 244Q162 254 150 254L84 254Q72 254 74 244Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>' + limb(124, 178, *w_['af'], col, -4))
    head_ = (f'<ellipse cx="108" cy="108" rx="62" ry="58" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
             + f'<circle cx="112" cy="130" r="10" fill="{BL}"></circle><path d="M105 135l5-9M114 135l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>'
             + f'<ellipse cx="164" cy="150" rx="40" ry="18" transform="rotate(-4 164 150)" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="186" cy="141" r="1.8" fill="{O}"></circle>'
             + f'<path d="M132 111q10 -12 20 0" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>' + ACC['clip'](132, 56, WARATAH))
    return legs + f'<g transform="translate(0 {w_["bob"]})">{body_}</g><g transform="translate(0 {hb})">{head_}</g>'
ground = f'<g stroke="#C9B89F" stroke-width="5" stroke-linecap="round"><animateTransform attributeName="transform" type="translate" values="0 0;-60 0" dur="0.6s" repeatCount="indefinite"></animateTransform>' + ''.join(f'<path d="M{x0} 296h26"></path>' for x0 in range(-40, 360, 60)) + '</g>'
def frame_vis(k, n=4): return ';'.join('inline' if i == k else 'none' for i in range(n))
walkc = shadow() + ground + ''.join(f'<g display="{"inline" if k == 0 else "none"}">{an("display", frame_vis(k), 0.6, 0, None, True)}{walk4(k)}</g>' for k in range(4))
pose_sheet = ''.join(f'<div style="display: flex; flex-direction: column; gap: 2px; width: 150px"><svg role="img" aria-label="Walk key pose: {w_["name"]}" width="150" height="176" viewBox="0 0 250 304" style="background: {PAPER}; border-radius: 18px"><path d="M0 290H250" stroke="#C9B89F" stroke-width="3"></path><path d="M0 50H250" stroke="#C9B89F" stroke-width="1.5" stroke-dasharray="6 6"></path>{walk4(k)}</svg>'
                     f'<div style="font-size: 14px; font-weight: 800">{k+1}. {w_["name"]}</div><div style="{T}; font-size: 12px">{w_["note"]}</div></div>' for k, w_ in enumerate(WK))

def tile(inner, name, note, bg=PAPER, vb='0 0 248 304'):
    return (f'<div style="display: flex; flex-direction: column; gap: 4px; width: 184px"><svg role="img" aria-label="Puggle animation: {name}" width="184" height="220" viewBox="{vb}" style="background: {bg}; border-radius: 22px">{inner}</svg>'
            f'<div style="font-size: 15px; font-weight: 800">{name}</div><div style="{T}; font-size: 12px">{note}</div></div>')
p_row = (tile(idle, 'Idle', 'Breathes and blinks; now and then she glances aside and her tail flicks, so it never reads as a loop.')
         + tile(wave, 'Wave', 'The arm dips, then swings up and waves twice. Head, tail and clip follow a beat late.', SUN)
         + tile(hooray, 'Hooray', 'Crouch and squash, stretch into the jump, squash on landing, settle. Tail and clip lag.', MINT)
         + tile(sleepy, 'Falling asleep', 'Eyes droop twice and fight back, the head nods further each time, then she is out.', '#D9DEEF')
         + tile(walkc, 'Walk', 'Four key poses a step, with the head arriving late. Rive smooths between them.', SHELL))

# ---------- animated scenes ----------
def bob(svg, dy, dur, begin=0): return G(svg, at('translate', f'0 0;0 {dy};0 0', dur, begin))
m = sc['morning']; Y2 = sc['Y2']; PAPER_ = sc['PAPER']
m = m.replace(f'<circle cx="236" cy="166" r="76" fill="{Y2}"></circle>', f'<circle cx="236" cy="166" r="76" fill="{Y2}">{an("cy", "196;166;166;196", 14, 0, "0;0.35;0.8;1")}</circle>')
m = m.replace(f'<circle cx="236" cy="166" r="104" fill="{PAPER_}" opacity="0.5"></circle>', f'<circle cx="236" cy="166" r="104" fill="{PAPER_}" opacity="0.5">{an("r", "96;112;96", 5)}{an("cy", "196;166;166;196", 14, 0, "0;0.35;0.8;1")}</circle>')
mg = sc['magpie'](150, sc['HZ'] - 64); m = m.replace(mg, bob(mg, -4, 0.9))
dw = sc['dew'](); m = m.replace(dw, G(dw, an('opacity', '1;0.3;1', 2.6)))
for b_, d_ in ((sc['stroke']('M56 54q8 -8 16 0q8 -8 16 0', sc['F2'], 2.6), '0 0;40 -10;0 0'), (sc['stroke']('M104 36q6 -6 12 0q6 -6 12 0', sc['F2'], 2.2), '0 0;-30 6;0 0')):
    m = m.replace(b_, G(b_, at('translate', d_, 16)))
hm = sc['hoist_m'](66, 262); m = m.replace(hm, G(hm, at('rotate', '-1.2 66 262;1.2 66 262;-1.2 66 262', 4)))
pm = sc['put'](sc['pug']('up', 'happy', sc['SKY']), 196, 290, 86); m = m.replace(pm, bob(pm, -5, 2.4))

n = sc['bedtime']; MOON_ = sc['MOON']
st = sc['stars'](); n = n.replace(st, ''.join(f'<g>{an("opacity", "1;0.25;1", 2 + i*0.5, i*0.4)}{sc["f"](sc["quatre"](x, y, s), MOON_, 0.9)}</g>' for i, (x, y, s) in enumerate(((40, 36, 5), (96, 70, 3), (150, 30, 4), (206, 58, 3), (236, 22, 5), (372, 150, 3), (20, 120, 3), (176, 96, 2.5)))))
n = n.replace(f'<circle cx="300" cy="96" r="92" fill="{MOON_}" opacity="0.07"></circle>', f'<circle cx="300" cy="96" r="92" fill="{MOON_}" opacity="0.07">{an("r", "86;102;86", 6)}</circle>')
n = n.replace(f'<circle cx="302" cy="168" r="22" fill="{MOON_}" opacity="0.22"></circle>', f'<circle cx="302" cy="168" r="22" fill="{MOON_}" opacity="0.22">{an("opacity", "0.22;0.34;0.2;0.3;0.22", 3.4)}</circle>')
n += f'<path d="M0 0l26 9" stroke="{MOON_}" stroke-width="2.4" stroke-linecap="round" opacity="0">{an("opacity", "0;0;1;0;0", 9, 0, "0;0.82;0.86;0.93;1")}{at("translate", "60 30;60 30;170 70;170 70", 9, 0, "0;0.82;0.93;1")}</path>'

_s3 = open(ROOT + '/gen/scenes3.py').read()
s3 = {'__name__': 'x', 'sys': sys}; exec(_s3[:_s3.index('# ---- BOARD ----')], s3)
r = dict((a, b) for a, b, _, _ in s3['SCENES'])['Rainy day']
rf = s3['rainf'](); r = r.replace(rf, G(rf, at('translate', '10 -24;0 0', 0.5)) )
r += ''.join(f'<ellipse cx="{x}" cy="{y}" rx="4" ry="1" fill="none" stroke="{s3["PAPER"]}" stroke-width="1.6" opacity="0">{an("rx", "4;26", 1.6, b)}{an("ry", "1;6", 1.6, b)}{an("opacity", "0.9;0", 1.6, b)}</ellipse>' for x, y, b in ((110, 284, 0), (268, 286, 0.6), (190, 292, 1.1), (330, 240, 0.3)))
pr = s3['K_'](s3['pug']('up', 'laughing', s3['A']), 192, 284); r = r.replace(pr, G(pr, at('translate', '0 0;0 -16;0 0;0 0', 0.9, 0, '0;0.4;0.8;1')))

c = sc['celebrate']
cf = sc['confetti'](); c = c.replace(cf, f'<g>{at("translate", "0 0;0 300", 7)}{cf}</g><g transform="translate(0 -300)"><g>{at("translate", "0 0;0 300", 7)}{cf}</g></g>'.replace('calcMode="spline" keySplines="0.4 0 0.6 1"', 'calcMode="linear"'))
for (bx, by, br, bc, bs), dur in (((40, 96, 30, sc['SKY'], -8), 3.2), ((84, 132, 24, sc['PAPER'], 6), 2.6), ((372, 110, 34, sc['SKY'], -10), 3.8)):
    bl = sc['balloon'](bx, by, br, bc, bs); c = c.replace(bl, bob(bl, -8, dur))
q1 = sc['f'](sc['quatre'](195, 150, 96), sc['G1']); c = c.replace(q1, f'<g transform="translate(195 150)"><g>{at("scale", "1;1.08;1", 2.4)}<g transform="translate(-195 -150)">{q1}</g></g></g>')
pc = sc['put'](sc['pug']('tada', 'proud', sc['WARATAH']), 196, 289, 92); c = c.replace(pc, G(pc, at('translate', '0 0;0 -14;0 0;0 0', 1.1, 0, '0;0.4;0.8;1')))

def stile(inner, name, note):
    return (f'<div style="display: flex; flex-direction: column; gap: 4px; width: 234px"><svg role="img" aria-label="Animated scene: {name}" width="234" height="180" viewBox="0 0 {W} {Hh}" style="border-radius: 20px; display: block">{inner}</svg>'
            f'<div style="font-size: 15px; font-weight: 800">{name}</div><div style="{T}; font-size: 12px">{note}</div></div>')
s_row = (stile(m, 'Morning', 'The sun rises and settles, its glow breathes, the washing sways, the magpie bobs, dew twinkles.')
         + stile(n, 'Bedtime', 'Stars twinkle out of step, the moon’s halo breathes, the lamp flickers, a shooting star every nine seconds.')
         + stile(r, 'Rainy day', 'Rain falls on a loop, rings spread on the puddle, Puggle jumps.')
         + stile(c, 'Celebration', 'Confetti falls without a seam, balloons bob, the quatrefoil pulses, Puggle hops.'))

def box(t, sub, c_): return f'<div style="padding: 8px 12px; border-radius: 14px; background: {c_}; min-width: 96px"><div style="font-size: 14px; font-weight: 800">{t}</div><div style="font-size: 11px; color: #4A3B30">{sub}</div></div>'
arrow = '<div style="font-size: 18px; font-weight: 800; color: #5A4636">→</div>'
machine = (f'<div style="display: flex; flex-direction: column; gap: 10px; padding: 16px 18px; background: {PAPER}; border-radius: 22px; flex: 1">'
           f'<div style="{H}">State machine: “Mood”</div>'
           f'<div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap">{box("Idle", "default, loops", SAND)}{arrow}{box("Wave", "trigger: greet", SUN)}{arrow}{box("Idle", "returns by itself", SAND)}</div>'
           f'<div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap">{box("Idle", "", SAND)}{arrow}{box("Hooray", "trigger: celebrate", MINT)}{arrow}{box("Idle", "", SAND)}</div>'
           f'<div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap">{box("Idle", "", SAND)}<div style="font-size: 18px; font-weight: 800; color: #5A4636">⇄</div>{box("Sleepy", "boolean: asleep", "#D9DEEF")}<div style="width: 14px"></div>{box("Walk", "boolean: walking", SHELL)}</div>'
           f'<div style="{T}; font-size: 12px">Blink runs on its own layer so it plays over every state. The app sets the inputs: <b>greet</b> on launch, <b>celebrate</b> after a log or milestone, <b>asleep</b> while a sleep timer runs or at night.</div></div>')
how = (f'<div style="display: flex; flex-direction: column; gap: 8px; padding: 16px 18px; background: {PAPER}; border-radius: 22px; width: 420px">'
       f'<div style="{H}">From these studies to Rive</div>'
       f'<div style="{T}; font-size: 12px"><b>1. Import the parts.</b> Puggle is exported as an SVG with named parts (tail, legs, dress, arm-left, arm-right, head, eyes, bill, clip), saved in the repo. Rive imports it and keeps the names.</div>'
       f'<div style="{T}; font-size: 12px"><b>2. Rig.</b> Pivots at the shoulders, the neck and the tail root; a bone or two for the tail. No mouth to animate: emotion is eyes, marks and body.</div>'
       f'<div style="{T}; font-size: 12px"><b>3. Animate and wire.</b> Rebuild these five loops as timelines, then the state machine on the left. One .riv file for the character.</div>'
       f'<div style="{T}; font-size: 12px"><b>4. Scenes.</b> Each scene is its own artboard with slow ambient loops, with Puggle nested in it. Reduce Motion shows the still scene.</div></div>')
principles = [('Anticipation', 'A small move the other way first: the crouch before the jump, the dip before the wave.'), ('Squash and stretch', 'She squashes wider when she lands and stretches taller in the air, always about her feet.'),
              ('Follow-through', 'Tail, clip and head start and stop a beat after the body, so nothing moves as one block.'), ('Not a loop', 'Idle has rare one-off moments on a longer cycle than the breath.')]
prin_html = ''.join(f'<div style="{T}; font-size: 12px"><b>{n}.</b> {d}</div>' for n, d in principles)
body = f'''<div style="width: 1080px; height: 1400px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Motion studies for Rive</h1>
<div style="{T}; font-size: 15px; max-width: 960px">Moving sketches of how Puggle and the scenes should feel. They loop here on the canvas; the real animations get rebuilt in the Rive editor from these.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Puggle</div><div style="display: flex; justify-content: space-between">{p_row}</div></div>
<div style="display: flex; gap: 22px; align-items: flex-start"><div style="display: flex; flex-direction: column; gap: 8px"><div style="{H}">Walk: the four key poses</div><div style="display: flex; gap: 10px">{pose_sheet}</div></div><div style="display: flex; flex-direction: column; gap: 8px; flex: 1"><div style="{H}">What the second pass added</div>{prin_html}</div></div>
<div style="display: flex; gap: 16px; align-items: stretch">{machine}{how}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Scenes with ambient motion</div><div style="display: flex; justify-content: space-between">{s_row}</div></div>
</div>'''
for nm, sv, need in (('morning', m, 7), ('bedtime', n, 10), ('rainy', r, 6), ('celebrate', c, 7)):
    k = sv.count('<animate'); assert k >= need, (nm, k)
if __name__ == '__main__':
    body = body.replace('<g>', '<g data-m="1">')
    wrap('Motion studies for Rive', body, 1080, 1400, 'Motion.dc.html', 0)
    P = ROOT + '/project/'
    cj = json.load(open(P + 'canvas.json'))
    cj['boards']['Motion.dc.html'].update(page='characters', x=1200, y=4180, is_interactive=True)
    o = cj['order']; o.remove('Motion.dc.html'); o.insert(o.index('ModelSheet.dc.html') + 1, 'Motion.dc.html')
    json.dump(cj, open(P + 'canvas.json', 'w'), separators=(',', ':'))
    # the parts file for Rive: one SVG, named groups, neutral pose
    parts = rig(HARBOUR, 'down', 'open', blink=False).replace('data-part=', 'id=')
    os.makedirs(ROOT + '/rive', exist_ok=True)
    open(ROOT + '/rive/puggle-parts.svg', 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 300" width="480" height="600">{parts}</svg>\n')
