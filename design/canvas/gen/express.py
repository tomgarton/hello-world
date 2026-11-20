import sys
ROOT = sys.argv[1]
psrc = open(ROOT + '/gen/platy.py').read(); psrc = psrc[:psrc.index('def panel')].replace("P = sys.argv[1] + '/project/'", '')
p = {}; exec(psrc, p)
wsrc = open(ROOT + '/gen/world.py').read(); wsrc = wsrc[:wsrc.index('walls = f')]
w = {'__name__': 'x'}; exec(wsrc, w)
wrap = w['wrap']
O, PF, BILL, BL, ST = '#3A2A20', '#8A5A3C', '#6E7F8D', '#C27C66', '#C24A36'
BL, MK, BROW = '#C27C66', '#F2A892', '#5E3A24'
def blush(y, dx, r=10, n=0):
    # soft ovals; three short marks only when she is pleased (n > 0); a little bigger when happy (r > 10)
    k = r / 10; s = ''
    for x in (120 - dx, 120 + dx):
        s += f'<ellipse cx="{x}" cy="{y}" rx="{12*k:.1f}" ry="{7.5*k:.1f}" fill="{BL}"></ellipse>'
        if n: s += ''.join(f'<path d="M{x-7+i*5} {y+4}l4-8" fill="none" stroke="{MK}" stroke-width="2.6" stroke-linecap="round" data-mark="1"></path>' for i in range(3))
    return s
def dot(x, y, r=6.8): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{O}"></circle>'
def arc_up(x, y): return f'<path d="M{x-8} {y+3}q8 -9 16 0" fill="none" stroke="{O}" stroke-width="4.5" stroke-linecap="round"></path>'
def arc_down(x, y): return f'<path d="M{x-8} {y-1}q8 7 16 0" fill="none" stroke="{O}" stroke-width="4.5" stroke-linecap="round"></path>'
def brows(kind='up'):
    # off at rest; raised for delight, soft for content and sleepy. Never angry, sad or worried.
    dy, rot = (-4, 6) if kind == 'up' else (1, 14)
    return ''.join(f'<path d="M{x-8} {102+dy} Q{x} {97+dy} {x+8} {102+dy}" transform="rotate({-rot*sg} {x} {101+dy})" fill="none" stroke="{BROW}" stroke-width="4" stroke-linecap="round" data-brow="1"></path>' for x, sg in ((88, 1), (152, -1)))
def bill_closed(rot=0, dy=0):
    return (f'<g transform="rotate({rot} 120 151) translate(0 {dy})"><ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
            f'<circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle></g>')
def bill_open(gap=14):
    return (f'<ellipse cx="120" cy="{156+gap*0.4:.0f}" rx="{30+gap}" ry="{8+gap*0.6:.0f}" fill="#7A2E2A" stroke="{O}" stroke-width="5"></ellipse>'
            f'<ellipse cx="120" cy="{164+gap*0.9:.0f}" rx="{26+gap}" ry="9" fill="{BILL}" stroke="{O}" stroke-width="5"></ellipse>'
            f'<ellipse cx="120" cy="140" rx="54" ry="21" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
            f'<circle cx="110" cy="133" r="3" fill="{O}"></circle><circle cx="130" cy="133" r="3" fill="{O}"></circle>')
def zzz(x, y):
    return ''.join(f'<path d="M{x+i*14} {y-i*14}h{9-i*1.5}l-{9-i*1.5} {9-i*1.5}h{9-i*1.5}" fill="none" stroke="{O}" stroke-width="{4-i*0.6}" stroke-linecap="round" stroke-linejoin="round"></path>' for i in range(3))
def sparkle(x, y, s=10):
    return f'<path d="M{x} {y-s}Q{x} {y} {x+s} {y}Q{x} {y} {x} {y+s}Q{x} {y} {x-s} {y}Q{x} {y} {x} {y-s}Z" fill="#F4BE2C" stroke="{O}" stroke-width="3" stroke-linejoin="round"></path>'
def head(e):
    s = f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
    if e == 'neutral': s += blush(132, 50) + bill_closed() + dot(88, 117) + dot(152, 117)
    elif e == 'happy': s += blush(132, 50, 11.4) + bill_closed() + arc_up(88, 117) + arc_up(152, 117) + brows('up')
    elif e == 'laughing': s += blush(132, 50, 11.4) + bill_closed() + f'<path d="M82 111 L93 117 L82 123 M158 111 L147 117 L158 123" fill="none" stroke="{O}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"></path>' + brows('up') + ''.join(f'<path d="M{x0} {y0}l{dx} {dy}" stroke="{O}" stroke-width="4.500" stroke-linecap="round"></path>' for x0, y0, dx, dy in ((40, 70, -12, -8), (36, 92, -14, 0), (40, 114, -12, 8), (200, 70, 12, -8), (204, 92, 14, 0), (200, 114, 12, 8)))
    elif e == 'surprised': s += blush(132, 50) + bill_closed() + dot(88, 116, 8.2) + dot(152, 116, 8.2) + brows('up') + f'<path d="M190 34v18" stroke="{O}" stroke-width="7" stroke-linecap="round"></path><circle cx="190" cy="64" r="4" fill="{O}"></circle>'
    elif e == 'sleepy': s += blush(132, 50) + bill_closed() + arc_down(88, 118) + arc_down(152, 118) + brows('soft') + zzz(176, 46)
    elif e == 'sad': s += blush(133, 50) + bill_closed() + dot(88, 121) + dot(152, 121) + f'<path d="M152 132q-6 9 0 13q6 -4 0 -13z" fill="#8FC1EC" stroke="{O}" stroke-width="3" stroke-linejoin="round"></path>'
    elif e == 'shy': s += blush(132, 49, 12.5, 3) + bill_closed() + dot(82, 121, 5.6) + dot(144, 121, 5.6)
    elif e == 'cheeky': s += blush(132, 50) + bill_closed() + dot(88, 117) + arc_up(152, 117) + brows('up')
    elif e == 'proud': s += blush(132, 50, 11.4, 3) + bill_closed() + arc_up(88, 117) + arc_up(152, 117) + brows('soft') + sparkle(46, 46) + sparkle(196, 58, 8) + sparkle(178, 26, 6)
    return s
def small(svg):
    """Small-size cast (under about 100 pt tall): plain blush, no nostrils or pocket, line a quarter heavier. Works for Puggle and the friends."""
    import re as _re
    svg = _re.sub(r'<path [^>]*data-mark="1"></path>', '', svg)
    svg = _re.sub(r'<circle cx="\d+" cy="\d+" r="1.8" fill="%s"></circle>' % O, '', svg)
    svg = _re.sub(r'<path d="M100 \d+h40v9a20 16 0 0 1-40 0z"[^>]*></path>', '', svg)
    return _re.sub(r'stroke-width="([\d.]+)"', lambda m: 'stroke-width="%.1f"' % (float(m.group(1))*1.25), svg)
def limb(x0, y0, x1, y1, col, bend=0, line=O, hand=PF):
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    dx, dy = y1 - y0, x0 - x1
    n = (dx * dx + dy * dy) ** 0.5 or 1
    cx, cy = mx + dx / n * bend, my + dy / n * bend
    d = f'M{x0} {y0}Q{cx:.1f} {cy:.1f} {x1} {y1}'
    tx, ty = x1 - cx, y1 - cy
    tn = (tx * tx + ty * ty) ** 0.5 or 1
    ux, uy = tx / tn, ty / tn
    kx, ky = x1 - ux * 12, y1 - uy * 12
    cuff = f'<path d="M{kx - uy*11:.1f} {ky + ux*11:.1f}L{kx + uy*11:.1f} {ky - ux*11:.1f}" stroke="{line}" stroke-width="4" stroke-linecap="round"></path>'
    return (f'<path d="{d}" fill="none" stroke="{line}" stroke-width="34" stroke-linecap="round"></path>'
            f'<path d="{d}" fill="none" stroke="{col}" stroke-width="22" stroke-linecap="round"></path>' + cuff +
            f'<circle cx="{x1}" cy="{y1}" r="12.500" fill="{hand}" stroke="{line}" stroke-width="5"></circle>')
ARMS = {
 'down':  ((88, 178, 50, 214, 4), (152, 178, 190, 214, -4)),
 'wave':  ((88, 178, 50, 214, 4), (152, 178, 206, 126, -8)),
 'up':    ((88, 178, 34, 126, 8), (152, 178, 206, 126, -8)),
 'shy':   ((90, 180, 112, 212, 6), (150, 180, 128, 212, -6)),
 'tada':  ((88, 182, 34, 196, -6), (152, 178, 206, 126, -8)),
 'sad':   ((90, 180, 56, 232, 2), (150, 180, 184, 232, -2)),
}
def body(arms, e, col='#2A62B8', sil=None, gap='#F2ECDD'):
    if not sil:
        L = ''.join(limb(*a[:4], col, a[4]) for a in ARMS[arms])
        return p['tail'](PF) + p['legs'](PF) + p['feet'](BILL) + p['trap'](col) + p['pocket'](210, col) + L + head(e)
    import re
    rest = p['tail'](PF) + p['legs'](PF) + p['feet'](BILL) + p['trap'](col)
    rest = re.sub(r'(fill|stroke)="#[0-9A-Fa-f]{6}"', lambda m: m.group(1) + '="' + sil + '"', rest)
    hd = re.sub(r'(fill|stroke)="#[0-9A-Fa-f]{6}"', lambda m: m.group(1) + '="' + sil + '"', head(e))
    L = ''
    for a in ARMS[arms]:
        x0, y0, x1, y1, bend = a
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        dx, dy = y1 - y0, x0 - x1
        n = (dx * dx + dy * dy) ** 0.5 or 1
        d = f'M{x0} {y0}Q{mx + dx / n * bend:.1f} {my + dy / n * bend:.1f} {x1} {y1}'
        L += (f'<path d="{d}" fill="none" stroke="{gap}" stroke-width="32" stroke-linecap="round"></path>'
              f'<path d="{d}" fill="none" stroke="{sil}" stroke-width="22" stroke-linecap="round"></path>'
              f'<circle cx="{x1}" cy="{y1}" r="16" fill="{gap}"></circle><circle cx="{x1}" cy="{y1}" r="12" fill="{sil}"></circle>')
    return rest + L + hd
EX = ['neutral', 'happy', 'laughing', 'surprised', 'sleepy', 'sad', 'shy', 'cheeky', 'proud']
faces = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 104px; height: 100px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">'
                f'<svg role="img" aria-label="Puggle looking {e}" width="98" height="94" viewBox="30 14 180 170">{head(e)}</svg></div><div style="font-size: 13px; font-weight: 700">{e.capitalize()}</div></div>' for e in EX)
POSES = [('Hello', 'wave', 'happy', '#2A62B8', '#F4BE2C'), ('Hooray', 'up', 'laughing', '#E5553B', '#CFE5D2'),
         ('Shy', 'shy', 'shy', '#F4BE2C', '#F3D9C9'), ('Oh no', 'sad', 'sad', '#3C9A5F', '#BFD9F5'), ('Ta-da', 'tada', 'proud', '#BFD9F5', '#F4BE2C')]
poses = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px"><div style="width: 180px; height: 220px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 8px; box-sizing: border-box">'
                f'<svg role="img" aria-label="Puggle, {t}" width="172" height="205" viewBox="0 -10 252 300">{body(a, e, col)}</svg></div><div style="font-size: 14px; font-weight: 700">{t}</div></div>' for t, a, e, col, bg in POSES)
sils = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><svg role="img" aria-label="Silhouette of {t}" width="86" height="102" viewBox="0 -10 252 300">{body(a, e, col, sil="#3A2A20")}</svg><div style="font-size: 12px; font-weight: 700">{t}</div></div>' for t, a, e, col, bg in POSES)
bodyhtml = f'''<div style="width: 1080px; height: 700px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 24px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle, expressions and poses</h1>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Faces: eyes, cheeks and floating marks. The bill never changes. No mouth; eyebrows only with a feeling</div>
<div style="display: flex; gap: 10px">{faces}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Poses</div>
<div style="display: flex; gap: 18px">{poses}</div></div>
<div style="display: flex; align-items: center; gap: 26px"><div style="display: flex; gap: 22px">{sils}</div>
<div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.45; max-width: 400px"><b style="font-weight: 800">Silhouette test.</b> Arms keep a thin light outline in silhouette so they never merge with the body. Both hands are always visible. Raised or lowered hands sit clear of the head and body; raised arms go up and out at about 45 degrees, never straight up behind the head. Hands held in front sit on the garment, never over the face or bill.</div></div>
</div>'''
wrap('Puggle, expressions and poses', bodyhtml, 1080, 700, 'Expressions.dc.html', 15290)
