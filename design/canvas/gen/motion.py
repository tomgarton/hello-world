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
def headparts(kind, blink=True):
    return (G(f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>', '', 'head-shape')
            + G(''.join(f'<circle cx="{x0}" cy="127" r="10" fill="{BL}"></circle><path d="M{x0-7} 132l5-9M{x0+2} 132l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>' for x0 in (67, 173)), '', 'blush')
            + G(f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>', '', 'bill')
            + G(eyes(kind, blink), '', 'eyes') + G(ACC['clip'](160, 56, WARATAH), '', 'clip'))
def rig(col, arms, eye, a_tail='', a_armL='', a_armR='', a_head='', a_body='', a_all='', blink=True):
    (lx0, ly0, lx1, ly1, lb), (rx0, ry0, rx1, ry1, rb) = X['ARMS'][arms]
    return G(G(p['tail'](PF), a_tail, 'tail') + G(p['legs'](PF) + p['feet'](BILL), '', 'legs')
             + G(G(p['trap'](col) + p['pocket'](210), '', 'dress') + G(limb(lx0, ly0, lx1, ly1, col, lb), a_armL, 'arm-left') + G(limb(rx0, ry0, rx1, ry1, col, rb), a_armR, 'arm-right')
                 + G(headparts(eye, blink), a_head, 'head'), a_body, 'upper'), a_all, 'puggle')
def shadow(anim=''): return f'<ellipse cx="124" cy="290" rx="62" ry="8" fill="#3A2A20" opacity="0.14">{anim}</ellipse>'

idle = shadow() + rig(HARBOUR, 'down', 'open', a_tail=at('rotate', '-4 160 240;5 160 240;-4 160 240', 2.4), a_armL=at('rotate', '0 88 178;3 88 178;0 88 178', 3.2), a_armR=at('rotate', '0 152 178;-3 152 178;0 152 178', 3.2),
                      a_head=at('translate', '0 0;0 2;0 0', 3.2), a_body=at('translate', '0 0;0 1.2;0 0', 3.2))
wave = shadow() + rig(HARBOUR, 'wave', 'happy', a_tail=at('rotate', '-6 160 240;8 160 240;-6 160 240', 0.8), a_armR=at('rotate', '0 152 178;-18 152 178;0 152 178;-18 152 178;0 152 178;0 152 178', 1.8, 0, '0;0.18;0.36;0.54;0.72;1'),
                      a_head=at('rotate', '0 120 170;3.5 120 170;0 120 170', 1.8))
sparks = ''.join(f'<g fill="{A}" opacity="0">{quatre(x, y, r)}{an("opacity", "0;0;1;0;0", 1.3, 0, "0;0.25;0.42;0.7;1")}</g>' for x, y, r in ((36, 60, 16), (206, 44, 20), (210, 130, 12), (28, 140, 12)))
hooray = (shadow(an('rx', '62;40;62;62', 1.3, 0, '0;0.36;0.72;1')) + sparks
          + rig(WARATAH, 'up', 'happy', a_tail=at('rotate', '0 160 240;14 160 240;0 160 240;0 160 240', 1.3, 0, '0;0.36;0.72;1'),
                a_all=at('translate', '0 6;0 -30;0 6;0 0;0 6', 1.3, 0, '0;0.36;0.72;0.86;1'), a_armL=at('rotate', '0 88 178;8 88 178;0 88 178;0 88 178', 1.3, 0, '0;0.36;0.72;1'), a_armR=at('rotate', '0 152 178;-8 152 178;0 152 178;0 152 178', 1.3, 0, '0;0.36;0.72;1')))
zz = ''.join(f'<text x="{186 + i*12}" y="{60 - i*8}" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="{26 - i*5}" fill="{O}" opacity="0">z{an("opacity", "0;1;1;0", 3.6, i*0.9, "0;0.2;0.7;1")}{at("translate", "0 10;0 -14", 3.6, i*0.9)}</text>' for i in range(3))
sleepy = shadow() + zz + rig(SKY, 'down', 'sleepy', a_tail=at('rotate', '0 160 240;3 160 240;0 160 240', 5), a_head=at('rotate', '0 120 170;5 120 170;5 120 170;0 120 170', 5, 0, '0;0.4;0.6;1'),
                             a_body=at('translate', '0 0;0 3;0 0', 5), blink=False)
ground = f'<g stroke="#C9B89F" stroke-width="5" stroke-linecap="round">{at("translate", "0 0;-60 0", 0.56)}' + ''.join(f'<path d="M{x0} 296h26"></path>' for x0 in range(-40, 360, 60)) + '</g>'
walkc = (shadow() + ground + f'<g>{an("display", "inline;none", 0.56, 0, None, True)}{walk(0)}</g><g display="none">{an("display", "none;inline", 0.56, 0, None, True)}{walk(1)}</g>')

def tile(inner, name, note, bg=PAPER, vb='0 0 248 304'):
    return (f'<div style="display: flex; flex-direction: column; gap: 4px; width: 184px"><svg role="img" aria-label="Puggle animation: {name}" width="184" height="220" viewBox="{vb}" style="background: {bg}; border-radius: 22px">{inner}</svg>'
            f'<div style="font-size: 15px; font-weight: 800">{name}</div><div style="{T}; font-size: 12px">{note}</div></div>')
p_row = (tile(idle, 'Idle', 'Breathes, blinks every four seconds, tail drifts. The default on Today.')
         + tile(wave, 'Wave', 'Hello on launch and on the splash. Arm from the shoulder, head tilts with it.', SUN)
         + tile(hooray, 'Hooray', 'After a log or a milestone. Squash, jump, land; quatrefoils pop.', MINT)
         + tile(sleepy, 'Sleepy', 'When a child is asleep or it is night. Slow breath, nodding head.', '#D9DEEF')
         + tile(walkc, 'Walk', 'Pull to refresh and the books. Two key poses for now; Rive adds the in-betweens.', SHELL))

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
body = f'''<div style="width: 1080px; height: 1090px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Motion studies for Rive</h1>
<div style="{T}; font-size: 15px; max-width: 960px">Moving sketches of how Puggle and the scenes should feel. They loop here on the canvas; the real animations get rebuilt in the Rive editor from these.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Puggle</div><div style="display: flex; justify-content: space-between">{p_row}</div></div>
<div style="display: flex; gap: 16px; align-items: stretch">{machine}{how}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Scenes with ambient motion</div><div style="display: flex; justify-content: space-between">{s_row}</div></div>
</div>'''
for nm, sv, need in (('morning', m, 7), ('bedtime', n, 10), ('rainy', r, 6), ('celebrate', c, 7)):
    k = sv.count('<animate'); assert k >= need, (nm, k)
if __name__ == '__main__':
    body = body.replace('<g>', '<g data-m="1">')
    wrap('Motion studies for Rive', body, 1080, 1090, 'Motion.dc.html', 0)
    P = ROOT + '/project/'
    cj = json.load(open(P + 'canvas.json'))
    cj['boards']['Motion.dc.html'].update(page='characters', x=1200, y=4180, is_interactive=True)
    o = cj['order']; o.remove('Motion.dc.html'); o.insert(o.index('ModelSheet.dc.html') + 1, 'Motion.dc.html')
    json.dump(cj, open(P + 'canvas.json', 'w'), separators=(',', ':'))
    # the parts file for Rive: one SVG, named groups, neutral pose
    parts = rig(HARBOUR, 'down', 'open', blink=False).replace('data-part=', 'id=')
    os.makedirs(ROOT + '/rive', exist_ok=True)
    open(ROOT + '/rive/puggle-parts.svg', 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 300" width="480" height="600">{parts}</svg>\n')
