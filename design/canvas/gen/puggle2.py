import sys, json, re
ROOT = sys.argv[1]
_l = open(ROOT + '/gen/lineup.py').read()
cx = {'__name__': 'x', 'sys': sys}
exec(_l[:_l.index('GROUND = 470')], cx)
X = cx['x']; ACC = cx['A']; wrap = cx['w']['wrap']
pbody, limb, ARMS, blush_old = X['body'], X['limb'], X['ARMS'], X['blush']
O, PF, BILL, BL, ST = '#3A2A20', '#8A5A3C', '#6E7F8D', '#EE9C88', '#C24A36'
BILL2 = '#757D88'   # the same slate, a little warmer, so it sits with the fur
PAPER, SAND, NIGHT, HARBOUR, WARATAH, SKY = '#FBF6E9', '#F2ECDD', '#27315A', '#2A62B8', '#E5553B', '#BFD9F5'

def dot(x, y, r): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{O}"></circle>'
def arc_up(x, y): return f'<path d="M{x-10} {y+3}q10 -12 20 0" fill="none" stroke="{O}" stroke-width="6.5" stroke-linecap="round"></path>'
def blush2(y, dx, r, stitches=True):
    s = ''
    for x in (120 - dx, 120 + dx):
        s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="{BL}"></circle>'
        if stitches: s += ''.join(f'<path d="M{x-7+i*9:.1f} {y+5}l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>' for i in range(2))
    return s
def bill2(dy=0, nostrils=True):
    out = f'<ellipse cx="120" cy="{151+dy}" rx="47" ry="19" fill="{BILL2}" stroke="{O}" stroke-width="6"></ellipse>'
    if nostrils: out += f'<circle cx="114" cy="{143+dy}" r="1.8" fill="{O}"></circle><circle cx="126" cy="{143+dy}" r="1.8" fill="{O}"></circle>'
    return out
def head2(e, small=False):
    s = f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
    s += blush2(127, 53, 11 if e == 'happy' else 10, not small)
    if e == 'happy': s += bill2(-2, not small) + arc_up(93, 108) + arc_up(147, 108)
    else: s += bill2(0, not small) + dot(93, 108, 7.6) + dot(147, 108, 7.6)
    return s
def body2(e, col=HARBOUR, small=False):
    tail = f'<ellipse cx="184" cy="248" rx="36" ry="12" transform="rotate(-20 184 248)" fill="{PF}" stroke="{O}" stroke-width="6"></ellipse>'
    legs = ''.join(f'<rect x="{x}" y="246" width="28" height="32" rx="12" fill="{PF}" stroke="{O}" stroke-width="6"></rect>' for x in (84, 128))
    feet = ''.join(f'<ellipse cx="{x}" cy="282" rx="25" ry="10" fill="{BILL2}" stroke="{O}" stroke-width="6"></ellipse>' for x in (96, 144))
    pear = f'<path d="M92 164Q120 155 148 164Q175 200 174 238Q174 256 156 256H84Q66 256 66 238Q65 200 92 164Z" fill="{col}" stroke="{O}" stroke-width="7" stroke-linejoin="round"></path>'
    pocket = f'<path d="M100 214h40v9a20 16 0 0 1-40 0z" fill="none" stroke="{O}" stroke-width="5" stroke-linejoin="round"></path>'
    arms = limb(90, 180, 52, 216, col, 4) + limb(150, 180, 188, 216, col, -4)
    out = tail + legs + feet + pear + ('' if small else pocket) + arms + head2(e, small) + ACC['clip'](160, 56, WARATAH)
    if small: out = re.sub(r'stroke-width="([\d.]+)"', lambda m: f'stroke-width="{float(m.group(1))*1.25:.1f}"', out)
    return out
def old(e, col=HARBOUR): return pbody('down', e, col) + ACC['clip'](160, 56, WARATAH)

def fig(inner, h, label, bg=None, pad=0):
    st = f' style="background: {bg}; border-radius: 16px; padding: {pad}px"' if bg else ''
    return f'<svg role="img" aria-label="{label}" width="{h*0.8:.0f}" height="{h}" viewBox="0 0 240 300"{st}>{inner}</svg>'
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
def col(title, a, b, note):
    return (f'<div style="display: flex; flex-direction: column; gap: 8px; padding: 18px 22px; background: {PAPER}; border-radius: 26px"><div style="font-size: 20px; font-weight: 800">{title}</div>'
            f'<div style="display: flex; gap: 8px">{a}{b}</div><div style="{T}; max-width: 420px">{note}</div></div>')
big = (col('Now', fig(old('neutral'), 270, 'Current Puggle, neutral'), fig(old('happy'), 270, 'Current Puggle, happy'), 'The model sheet as it stands.')
       + col('Tweaked', fig(body2('neutral'), 270, 'Tweaked Puggle, neutral'), fig(body2('happy'), 270, 'Tweaked Puggle, happy'), 'Same head, colours, clip, stitched blush and no-mouth rule.'))
def small_cell(inner, label, bg):
    return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 96px; height: 100px; border-radius: 16px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 8px; box-sizing: border-box">{fig(inner, 80, label)}</div></div>'
def small_row(title, inner_fn, note):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px"><div style="font-size: 15px; font-weight: 800">{title}</div><div style="display: flex; gap: 8px">'
            + small_cell(inner_fn(HARBOUR), title + ' on paper', PAPER) + small_cell(inner_fn(SKY), title + ' at night', NIGHT) + f'</div><div style="{T}; font-size: 12px; width: 200px">{note}</div></div>')
smalls = (small_row('Now', lambda c: old('happy', c), 'Stitches and nostrils turn to speckle.')
          + small_row('Tweaked', lambda c: body2('happy', c), 'Better, but the fine details still buzz.')
          + small_row('Tweaked, small version', lambda c: body2('happy', c, True), 'Plain blush, no nostrils or pocket, line a quarter heavier.'))
changes = [('Bill', 'Smaller, flatter and a touch lower, in a slightly less blue slate. Nostrils shrink to pin dots so they stop reading as eyes.'),
           ('Eyes', 'Lower and a little larger, closer to the bill. Blush drops with them.'),
           ('Body', 'A pear, not a trapezoid; legs shorter and thicker. Tail flatter, like a paddle.')]
ch = ''.join(f'<div style="display: flex; flex-direction: column; gap: 2px; width: 230px"><div style="font-size: 15px; font-weight: 800">{n}</div><div style="{T}; font-size: 12px">{d}</div></div>' for n, d in changes)
body = f'''<div style="width: 1080px; height: 790px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Puggle, small tweaks</h1>
<div style="{T}; font-size: 15px">A proposal only. The model sheet is unchanged until you say so.</div></div>
<div style="display: flex; gap: 24px">{big}</div>
<div style="display: flex; gap: 40px; align-items: flex-start"><div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">What changed</div><div style="display: flex; flex-direction: column; gap: 10px">{ch}</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">At scene size</div><div style="display: flex; gap: 22px">{smalls}</div></div></div>
</div>'''
wrap('Puggle, small tweaks', body, 1080, 790, 'PuggleTweaks.dc.html', 0)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['PuggleTweaks.dc.html'].update(page='characters', x=1200, y=4260)
o = c['order']; o.remove('PuggleTweaks.dc.html'); o.insert(o.index('ModelSheet.dc.html') + 1, 'PuggleTweaks.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
