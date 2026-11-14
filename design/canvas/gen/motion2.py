import sys, json, math
ROOT = sys.argv[1]
_m = open(ROOT + '/gen/motion.py').read()
exec(_m[:_m.index('def tile(')])                    # rig, loops, helpers, colours
dot, blush = X['dot'], X['blush']

def mtile(inner, name, note, bg=PAPER):
    return (f'<div style="display: flex; flex-direction: column; gap: 4px; width: 186px"><svg role="img" aria-label="Puggle animation: {name}" width="186" height="226" viewBox="-21 -50 290 354" style="background: {bg}; border-radius: 20px">{inner}</svg>'
            f'<div style="font-size: 14px; font-weight: 800">{name}</div><div style="{T}; font-size: 12px">{note}</div></div>')
timing_row = (mtile(hooray_smooth, 'Hooray, smooth (before)', 'Eased the whole way. Soft, a little floaty.', MINT) + mtile(hooray, 'Hooray, snappy (chosen)', 'Holds each pose and pops to the next. Arms start down, so the fling reads.', MINT)
              + mtile(wave_smooth, 'Wave, smooth (before)', 'Arm swings continuously, and only to cheek height.', SUN) + mtile(wave, 'Wave, snappy (chosen)', 'Arm up beside the head, clear of it; three beats.', SUN)
              + mtile(nod, 'Nod (new)', 'The everyday “saved” reaction: dip, pop, settle in 0.4 s.', PAPER))

# ---------- tail mood sheet ----------
def tail(rot, dx=0, dy=0, rx=34, extra=''):
    return f'<ellipse cx="{184+dx}" cy="{246+dy}" rx="{rx}" ry="15" transform="rotate({rot} {160+dx} {246+dy})" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' + extra
def marks(pts): return ''.join(f'<path d="M{x0} {y0}l{dx} {dy}" stroke="{O}" stroke-width="4.5" stroke-linecap="round"></path>' for x0, y0, dx, dy in pts)
def mood_fig(tail_svg, e, col, arms='down'):
    L = ''.join(limb(*a[:4], col, a[4]) for a in X['ARMS'][arms])
    return tail_svg + p['legs'](PF) + p['feet'](BILL) + p['trap'](col) + p['pocket'](210) + L + head(e) + ACC['clip'](160, 56, WARATAH)
curl = f'<path d="M168 262Q214 268 206 284Q150 300 96 288" fill="none" stroke="{O}" stroke-width="36" stroke-linecap="round"></path><path d="M168 262Q214 268 206 284Q150 300 96 288" fill="none" stroke="{PF}" stroke-width="24" stroke-linecap="round"></path>'
MOODS = [('Calm', mood_fig(tail(-28), 'neutral', HARBOUR), 'Resting, slightly raised. The default.'),
         ('Happy', mood_fig(tail(-52, 0, -4, 34, marks(((222, 196, 10, -6), (230, 214, 12, 0), (196, 180, 6, -10)))), 'happy', HARBOUR), 'Up and wagging. Small marks show the wag in stills.'),
         ('Proud', mood_fig(tail(-74, -2, -6), 'proud', WARATAH, 'tada'), 'Straight up, like a flag.'),
         ('Surprised', mood_fig(tail(-6, 4, -4, 38, marks(((232, 232, 10, -4), (234, 246, 12, 0), (232, 260, 10, 4)))), 'surprised', A), 'Stiff and straight out.'),
         ('Sad', mood_fig(tail(22, -4, 14), 'sad', GUM, 'sad'), 'Droops to the ground. Only for her own feelings, never about the parent.'),
         ('Shy', mood_fig(tail(-8, -22, 6, 26), 'shy', BLUSH, 'shy'), 'Tucked in close, half hidden.'),
         ('Sleepy', mood_fig('', 'sleepy', SKY) + curl, 'Curled around her feet.')]
tail_row = ''.join(f'<div style="display: flex; flex-direction: column; gap: 2px; width: 132px"><svg role="img" aria-label="Puggle, tail when {n.lower()}" width="132" height="158" viewBox="0 0 250 300" style="background: {PAPER}; border-radius: 16px">{s_}</svg>'
                   f'<div style="font-size: 14px; font-weight: 800">{n}</div><div style="{T}; font-size: 11.5px">{d}</div></div>' for n, s_, d in MOODS)

# ---------- three-quarter view and toddler-true key poses ----------
def tq(armL=(54, 214, 4), armR=(180, 214, -4), eye='dots', tail_rot=28, legs='stand', dy=0, tilt=0, extra_back='', extra_front='', col=HARBOUR, look=0):
    t = f'<ellipse cx="60" cy="246" rx="34" ry="15" transform="rotate({tail_rot} 82 246)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>'
    def leg_(x0): return f'<rect x="{x0-4}" y="244" width="28" height="34" rx="11" fill="{PF}" stroke="{O}" stroke-width="6"></rect><ellipse cx="{x0+16}" cy="282" rx="24" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
    if legs == 'stand': lg = leg_(88) + leg_(124)
    elif legs == 'cross':   # knees together, feet turned in
        lg = (f'<path d="M100 244L122 276" stroke="{O}" stroke-width="28" stroke-linecap="round"></path><path d="M100 244L122 276" stroke="{PF}" stroke-width="16" stroke-linecap="round"></path>'
              f'<path d="M134 244L112 276" stroke="{O}" stroke-width="28" stroke-linecap="round"></path><path d="M134 244L112 276" stroke="{PF}" stroke-width="16" stroke-linecap="round"></path>'
              f'<ellipse cx="134" cy="283" rx="22" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6" transform="rotate(-12 134 283)"></ellipse><ellipse cx="102" cy="283" rx="22" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6" transform="rotate(12 102 283)"></ellipse>')
    elif legs == 'toes':
        lg = ''.join(f'<rect x="{x0-4}" y="232" width="28" height="40" rx="11" fill="{PF}" stroke="{O}" stroke-width="6"></rect><ellipse cx="{x0+14}" cy="278" rx="13" ry="16" fill="{BILL}" stroke="{O}" stroke-width="6" transform="rotate(-24 {x0+14} 278)"></ellipse>' for x0 in (88, 124))
    else:                   # sitting: soles towards us
        lg = ''.join(f'<ellipse cx="{x0}" cy="274" rx="20" ry="17" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><path d="M{x0-8} 270q8 8 16 0" fill="none" stroke="{O}" stroke-width="3.5" stroke-linecap="round" opacity="0.5"></path>' for x0 in (86, 150))
    body_ = f'<path d="M84 166Q116 156 150 166L176 244Q178 254 166 254L72 254Q60 254 62 244Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
    arms_ = limb(86, 178, armL[0], armL[1], col, armL[2]) + limb(148, 178, armR[0], armR[1], col, armR[2])
    if eye == 'dots': ey = f'<circle cx="99" cy="{108+look}" r="7.6" fill="{O}"></circle><circle cx="146" cy="{106+look}" r="6.4" fill="{O}"></circle>'
    elif eye == 'happy': ey = f'<path d="M89 111q10 -12 20 0" fill="none" stroke="{O}" stroke-width="6.5" stroke-linecap="round"></path><path d="M138 109q8 -10 16 0" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>'
    else: ey = f'<path d="M90 102l14 7l-14 7M154 100l-12 6l12 6" fill="none" stroke="{O}" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round"></path>'      # squeezed
    hd = (f'<ellipse cx="114" cy="108" rx="68" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
          + f'<circle cx="66" cy="128" r="10" fill="{BL}"></circle><path d="M59 133l5-9M68 133l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path><circle cx="164" cy="126" r="8" fill="{BL}"></circle>'
          + f'<ellipse cx="146" cy="151" rx="44" ry="18" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="148" cy="143" r="1.8" fill="{O}"></circle><circle cx="160" cy="143" r="1.8" fill="{O}"></circle>' + ey + ACC['clip'](150, 54, WARATAH))
    upper = f'<g transform="translate(0 {dy}) rotate({tilt} 116 250)">{t if legs != "sit" else ""}{body_}{pocket_tq}{arms_}{hd}</g>'
    sit_tail = f'<ellipse cx="44" cy="{262+dy*0.2:.0f}" rx="38" ry="13" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>' if legs == 'sit' else ''
    order = (extra_back + sit_tail + upper + lg) if legs == 'sit' else (extra_back + lg + upper)
    return f'<ellipse cx="118" cy="291" rx="70" ry="8" fill="#3A2A20" opacity="0.12"></ellipse>' + order + extra_front
pocket_tq = f'<path d="M106 210h40v9a20 16 0 0 1-40 0z" fill="none" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>'
wig = marks(((30, 176, -12, -4), (26, 200, -14, 0), (30, 224, -12, 4), (206, 176, 12, -4), (210, 200, 14, 0), (206, 224, 12, 4)))
puff = ''.join(f'<path d="M{x0} 288q{dx} -14 {dx*2} -4" fill="none" stroke="{O}" stroke-width="4.5" stroke-linecap="round"></path>' for x0, dx in ((8, -6), (214, 8))) + marks(((22, 262, -10, -8), (218, 260, 10, -8)))
shelf = (f'<path d="M150 46H250" stroke="{O}" stroke-width="7" stroke-linecap="round"></path><rect x="196" y="6" width="38" height="38" rx="10" fill="{A}" stroke="{O}" stroke-width="6"></rect><rect x="192" y="0" width="46" height="12" rx="6" fill="{WARATAH}" stroke="{O}" stroke-width="5"></rect>')
MOVES = [('Three-quarter, at rest', tq(), 'Her acting view. The bill and one cheek turn towards us; movement reads more naturally than front-on.'),
         ('Potty dance', tq(armL=(104, 232, -10), armR=(134, 234, 10), eye='squeeze', tail_rot=-18, legs='cross', dy=2, extra_front=wig), 'Knees together, hands at the front of her dress, tail stiff. A quick side-to-side jiggle. The app can use it as the gentle "time to try?" reminder.'),
         ('Flop-sit', tq(armL=(40, 196, 8), armR=(196, 196, -8), eye='happy', legs='sit', dy=26, extra_front=puff), 'Legs shoot out, bottom lands, arms fly up for balance, soles to camera. For finishing something, or giving up happily.'),
         ('Tippy-toe reach', tq(armL=(44, 200, 6), armR=(196, 86, -10), eye='dots', tail_rot=44, legs='toes', dy=-12, tilt=-3, extra_back=shelf, look=-5), 'Up on her toes, one arm stretched, the other out for balance, tail as counterweight, eyes on the prize. For "add" and "not yet" moments.')]
move_row = ''.join(f'<div style="display: flex; flex-direction: column; gap: 4px; width: 228px"><svg role="img" aria-label="Puggle key pose: {n}" width="228" height="258" viewBox="-14 -14 280 318" style="background: {PAPER}; border-radius: 20px">{s_}</svg>'
                   f'<div style="font-size: 15px; font-weight: 800">{n}</div><div style="{T}; font-size: 12px">{d}</div></div>' for n, s_, d in MOVES)

# ---------- reaction map ----------
ROWS = [('Opens the app, first time that day', 'Wave', '2 s', 'Once a day, not on every open.'),
        ('Saves an everyday log (bottle, nappy, solids)', 'Nod: one small happy bounce', '0.4 s', 'The save is instant; the bounce plays beside it.'),
        ('Starts a sleep', 'Yawn, then falls asleep', '3 s, then loops', 'She stays asleep until the sleep ends.'),
        ('Ends a sleep', 'Stretch and wake', '1.2 s', ''),
        ('Potty success', 'Proud ta-da, tail up', '1.5 s', 'With the sticker.'),
        ('Milestone', 'Full hooray, quatrefoils', '1.5 to 1.8 s', 'The only big one. Rare on purpose.'),
        ('Pulls to refresh', 'Walks while you pull', 'while held', ''),
        ('Taps or drags near her', 'Eyes follow the finger; a tap gets a giggle bounce', '0.5 s', 'She notices you.'),
        ('Hasn’t logged for a while; missed a day', 'Nothing. She idles as usual', '', 'No sad face, no reminders from her. Ever.'),
        ('Night (about 10 pm to 6 am), or a child asleep', 'Everything half the size and slower; no jumps', '', 'Idle becomes the sleepy loop.'),
        ('Reduce Motion is on', 'Still poses that swap', '', 'No movement at all.')]
th = 'font-size: 12px; font-weight: 800; letter-spacing: 0.04em; text-transform: uppercase; color: #5A4636; padding: 6px 10px; text-align: left'
td = 'font-size: 13px; padding: 7px 10px; border-top: 1px solid #E4DAC6; vertical-align: top; line-height: 1.35'
table = (f'<table style="border-collapse: collapse; background: {PAPER}; border-radius: 18px; overflow: hidden; width: 660px"><tr><th scope="col" style="{th}">When the parent…</th><th scope="col" style="{th}">Puggle…</th><th scope="col" style="{th}">For</th><th scope="col" style="{th}">Note</th></tr>'
         + ''.join(f'<tr><td style="{td}; font-weight: 700; width: 210px">{a}</td><td style="{td}; width: 190px">{b}</td><td style="{td}; white-space: nowrap; font-variant-numeric: tabular-nums">{c_}</td><td style="{td}; color: #4A3B30">{d}</td></tr>' for a, b, c_, d in ROWS) + '</table>')
RULES = [('Never in the way', 'Nothing waits for an animation. Saving, navigating and typing are instant; she reacts alongside.'),
         ('No guilt', 'She is never sad, worried or disappointed about what a parent did or didn’t log. Sad is only for her own stories.'),
         ('Quiet at night', 'After dark she is smaller, slower and stays on the ground.'),
         ('Silent by default', 'No sound unless switched on. A soft haptic tap when she lands.'),
         ('One thing at a time', 'When she moves, the scene behind her goes still.'),
         ('She notices you', 'Her eyes follow your finger, and she glances at what you just pressed.')]
rules_html = ''.join(f'<div style="{T}; font-size: 12.5px"><b>{n}.</b> {d}</div>' for n, d in RULES)

def sec(title, intro, inner):
    return f'<div style="display: flex; flex-direction: column; gap: 10px"><div><div style="font-size: 20px; font-weight: 800">{title}</div><div style="{T}">{intro}</div></div>{inner}</div>'
body = f'''<div style="width: 1080px; height: 2000px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Motion direction</h1>
<div style="{T}; font-size: 15px; max-width: 960px">What to settle before opening Rive: when she reacts, how her tail shows feeling, how snappy she is, and a few moves taken from a real toddler.</div></div>
{sec('1. Reaction map', 'Every moment she responds to, and the rules that keep her kind to tired parents.', f'<div style="display: flex; gap: 22px; align-items: flex-start">{table}<div style="display: flex; flex-direction: column; gap: 9px; flex: 1"><div style="{H}">Rules</div>{rules_html}</div></div>')}
{sec('2. The tail shows the feeling', 'She has no mouth or brows, so the tail is her mood signal, with her eyes. One position per feeling.', f'<div style="display: flex; justify-content: space-between">{tail_row}</div>')}
{sec('3. Reactions are snappy', 'Decided: reactions hold each pose and pop to the next; breathing, sleeping and scenes stay smooth. The earlier smooth versions are shown for comparison.', f'<div style="display: flex; gap: 12px; align-items: flex-start">{timing_row}</div>')}
{sec('4. Moves from a real toddler', 'Key poses in a three-quarter view. Each is one clear silhouette to animate into and hold.', f'<div style="display: flex; justify-content: space-between">{move_row}</div>')}
</div>'''
if __name__ == '__main__':
    body = body.replace('<g>', '<g data-m="1">')
    wrap('Motion direction', body, 1080, 2000, 'Motion2.dc.html', 0)
    P = ROOT + '/project/'
    cj = json.load(open(P + 'canvas.json'))
    cj['boards']['Motion2.dc.html'].update(page='characters', x=2400, y=4180, is_interactive=True)
    o = cj['order']; o.remove('Motion2.dc.html'); o.insert(o.index('Motion.dc.html') + 1, 'Motion2.dc.html')
    json.dump(cj, open(P + 'canvas.json', 'w'), separators=(',', ':'))
