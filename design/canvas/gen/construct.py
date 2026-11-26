import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, BL, ST, p, head, limb, body, wrap, dot, blush = [x[k] for k in ('O', 'PF', 'BILL', 'BL', 'ST', 'p', 'head', 'limb', 'body', 'wrap', 'dot', 'blush')]
G = '#5B8FD6'
def guide(d): return f'<path d="{d}" fill="none" stroke="{G}" stroke-width="2.500" stroke-dasharray="6 5"></path>'
def note(xx, yy, t, anchor='start'): return f'<text x="{xx}" y="{yy}" text-anchor="{anchor}" font-family="Bricolage Grotesque, sans-serif" font-weight="700" font-size="16" fill="{G}">{t}</text>'
headline = '<ellipse cx="120" cy="108" rx="70" ry="60" fill="none" stroke="#3A2A20" stroke-width="5"></ellipse>'
s1 = headline + guide('M120 40V176M44 108H196') + note(200, 112, 'eyes') + note(120, 194, '140 × 120', 'middle')
s2 = (headline + guide('M44 108H196') + dot(93, 108) + dot(147, 108) + f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="none" stroke="#3A2A20" stroke-width="5"></ellipse>' +
      guide('M73 151H167') + note(120, 192, 'bill 94 × 38, overlaps the chin', 'middle') + guide('M93 108V86M147 108V86') + note(120, 80, '54 apart', 'middle'))
s3 = (f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>' + blush(127, 53) +
      f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>' + dot(93, 108) + dot(147, 108) +
      guide('M88 166L60 254M152 166L180 254') + note(190, 214, 'body 64 wide') + note(190, 232, 'at the neck,') + note(190, 250, '120 at the hem'))
s4 = body('down', 'neutral', '#2A62B8') + guide('M0 48H240M0 168H240M0 254H240M0 292H240') + note(246, 114, 'head: 1') + note(246, 216, 'body: ¾') + note(246, 278, 'legs: ⅓')
steps = [('1. Head', s1, '0 30 240 180'), ('2. Eyes and bill', s2, '0 30 240 180'), ('3. Cheeks and body', s3, '0 30 310 250'), ('4. Arms, legs, tail', s4, '0 30 330 280')]
cells = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 230px"><div style="width: 230px; height: 250px; background: #FBF6E9; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="Construction step {t}" width="214" height="214" viewBox="{vb}" preserveAspectRatio="xMidYMid meet">{s}</svg></div><div style="font-size: 15px; font-weight: 800">{t}</div></div>' for t, s, vb in steps)
tips = ['Start from two ovals: the head, and the bill overlapping its lower edge.', 'Eyes sit on the head’s centre line, close above the bill, 54 apart.', 'Cheeks sit at the ends of the bill’s top edge, half on the head.', 'The jumper is the body. Arms join just under the head; legs are short and thick.', 'Outline last, in one weight per part; round every corner.']
tip_html = ''.join(f'<li style="margin: 0 0 4px 0">{t}</li>' for t in tips)
bodyh = f'''<div style="width: 1080px; height: 560px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Drawing Puggle by hand</h1>
<div style="display: flex; gap: 20px">{cells}</div>
<ul style="margin: 0; padding-left: 20px; font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.4; columns: 2; column-gap: 40px">{tip_html}</ul>
</div>'''
wrap('Drawing Puggle by hand', bodyh, 1080, 560, 'Construction.dc.html', 21120)
