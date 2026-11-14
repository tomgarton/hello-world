import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, p, head, limb, body, sparkle, wrap = x['O'], x['PF'], x['BILL'], x['p'], x['head'], x['limb'], x['body'], x['sparkle'], x['wrap']
def bottle(cx, cy, rot=0):
    return (f'<g transform="rotate({rot} {cx} {cy})"><rect x="{cx-11}" y="{cy-20}" width="22" height="36" rx="7" fill="#FBF6E9" stroke="{O}" stroke-width="4.500"></rect>'
            f'<rect x="{cx-11}" y="{cy-2}" width="22" height="18" rx="6" fill="#FFF3D6" stroke="{O}" stroke-width="4.500"></rect>'
            f'<rect x="{cx-13}" y="{cy-26}" width="26" height="8" rx="3" fill="#2A62B8" stroke="{O}" stroke-width="4"></rect><path d="M{cx-6} {cy-26}q6 -14 12 0" fill="#F4BE2C" stroke="{O}" stroke-width="4"></path></g>')
def curl():
    d = 'M120 52Q104 30 120 14Q140 2 146 18Q148 30 134 30Q124 28 128 20'
    return f'<path d="{d}" fill="none" stroke="{O}" stroke-width="13" stroke-linecap="round"></path><path d="{d}" fill="none" stroke="{PF}" stroke-width="5" stroke-linecap="round"></path>'
def baby(e='happy', col='#F4BE2C', hold=True):
    s = p['tail'](PF)
    s += ''.join(f'<ellipse cx="{x0}" cy="250" rx="20" ry="15" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' for x0 in (82, 158))
    s += p['trap'](col, 248, 30)
    if hold:
        s += limb(88, 182, 106, 214, col, 6) + limb(152, 182, 134, 214, col, -6) + bottle(120, 206, -18)
    else:
        s += limb(88, 182, 58, 222, col, 4) + limb(152, 182, 182, 222, col, -4)
    return s + head(e) + curl()
def potty(e='proud', col='#E5553B'):
    s = (f'<path d="M64 214H176L166 266Q164 276 154 276H86Q76 276 74 266Z" fill="#FBF6E9" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path>'
         f'<rect x="56" y="204" width="128" height="18" rx="9" fill="#BFD9F5" stroke="{O}" stroke-width="6"></rect>')
    s += ('<g data-t="1" transform="translate(4 -30)">' + p['tail'](PF) + '</g>')
    s += p['trap'](col, 212, 18)
    s += ''.join(f'<ellipse cx="{x0}" cy="232" rx="19" ry="11" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' for x0 in (92, 148))
    s += limb(88, 180, 50, 136, col, 8) + limb(152, 180, 190, 136, col, -8)
    return s + head(e) + sparkle(36, 60, 9) + sparkle(206, 70, 8) + sparkle(190, 30, 6)
def night(svg):
    for w in ('4', '3.4', '2.8'):
        svg = svg.replace(f'stroke="#3A2A20" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"', f'stroke="#F3E0B8" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"')
    return svg
def card(svg, title, sub, bg, vb='0 -10 252 300', w=196):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px; width: 220px"><div style="width: 220px; height: 250px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 10px; box-sizing: border-box">'
            f'<svg role="img" aria-label="{title}" width="{w}" height="{w*233/196:.0f}" viewBox="{vb}">{svg}</svg></div><div style="font-size: 16px; font-weight: 800">{title}</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4">{sub}</div></div>')
cards = (card(body('wave', 'happy', '#2A62B8'), 'Puggle, 2½', 'Big sister. Potty training, moving to a big bed, big feelings.', '#F4BE2C') +
         card(baby('happy'), 'Baby sibling, 6 months', 'Bottles, first foods, rolling, teeth. Smaller, with a curl on top and a romper.', '#CFE5D2', '0 -10 240 290', 140) +
         card(potty(), 'Puggle on the potty', 'Ta-da: the proud pose for a success, with sparkles.', '#F3D9C9', '0 -10 252 300') +
         card(night(body('down', 'sleepy', '#BFD9F5')), 'Puggle at bedtime', 'Sleepy pose in pyjama colours, for the big-bed story.', '#1B2440'))
body_html = f'''<div style="width: 1080px; height: 520px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle and her baby sibling</h1>
<div style="display: flex; gap: 32px">{cards}</div>
</div>'''
wrap('Puggle and her baby sibling', body_html, 1080, 520, 'Family.dc.html', 17400)
