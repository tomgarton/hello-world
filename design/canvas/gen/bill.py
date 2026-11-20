import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, blush, dot, arc_up, sparkle, wrap = x['O'], x['PF'], x['BILL'], x['blush'], x['dot'], x['arc_up'], x['sparkle'], x['wrap']
GAP, TONGUE = '#6B2A2A', '#E88F8F'
HEAD = f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>'
nos = lambda y: f'<circle cx="110" cy="{y}" r="3" fill="{O}"></circle><circle cx="130" cy="{y}" r="3" fill="{O}"></circle>'
def A(e):
    if e == 'surprised':
        b = (f'<ellipse cx="120" cy="158" rx="38" ry="18" fill="{GAP}" stroke="{O}" stroke-width="5"></ellipse>'
             f'<ellipse cx="120" cy="180" rx="36" ry="10" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
             f'<ellipse cx="120" cy="136" rx="54" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' + nos(130))
        return HEAD + blush(112, 56) + b + dot(90, 92, 9) + dot(150, 92, 9)
    b = (f'<ellipse cx="120" cy="160" rx="44" ry="22" fill="{GAP}" stroke="{O}" stroke-width="5"></ellipse>'
         f'<ellipse cx="120" cy="168" rx="20" ry="9" fill="{TONGUE}"></ellipse>'
         f'<ellipse cx="120" cy="182" rx="46" ry="12" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
         f'<ellipse cx="120" cy="136" rx="54" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' + nos(130))
    return HEAD + blush(112, 56, 12) + b + arc_up(90, 94) + arc_up(150, 94)
def B(e):
    if e == 'surprised':
        b = (f'<ellipse cx="120" cy="150" rx="40" ry="30" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>'
             f'<ellipse cx="120" cy="156" rx="19" ry="16" fill="{GAP}" stroke="{O}" stroke-width="4"></ellipse>' + nos(132))
        return HEAD + blush(112, 58) + b + dot(90, 94, 9) + dot(150, 94, 9)
    b = (f'<path d="M60 128Q120 116 180 128Q182 186 120 188Q58 186 60 128Z" fill="{BILL}" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path>'
         f'<path d="M80 144Q120 136 160 144Q156 176 120 178Q84 176 80 144Z" fill="{GAP}" stroke="{O}" stroke-width="4" stroke-linejoin="round"></path>'
         f'<path d="M98 168Q120 158 142 168Q138 177 120 178Q102 177 98 168Z" fill="{TONGUE}"></path>' + nos(132))
    return HEAD + blush(112, 58, 12) + b + arc_up(90, 94) + arc_up(150, 94)
def C(e):
    base = f'<ellipse cx="120" cy="146" rx="54" ry="25" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse>' + nos(134)
    if e == 'surprised':
        return HEAD + blush(116, 56) + base + f'<ellipse cx="120" cy="156" rx="10" ry="9" fill="{GAP}"></ellipse>' + dot(90, 96, 9) + dot(150, 96, 9)
    return (HEAD + blush(116, 56, 12) + base + f'<path d="M84 146H156Q154 168 120 168Q86 168 84 146Z" fill="{GAP}"></path>'
            f'<path d="M104 162Q120 154 136 162Q130 168 120 168Q110 168 104 162Z" fill="{TONGUE}"></path>' + arc_up(90, 98) + arc_up(150, 98))
def D(e):
    # squash and stretch on top of A
    if e == 'surprised':
        return f'<g transform="translate(120 190) scale(0.92 1.1) translate(-120 -190)">{A(e)}</g>' + f'<path d="M196 30v18" stroke="{O}" stroke-width="7" stroke-linecap="round"></path><circle cx="196" cy="60" r="4" fill="{O}"></circle>'
    return f'<g transform="translate(120 190) scale(1.1 0.9) translate(-120 -190)">{A(e)}</g>' + sparkle(40, 44, 9) + sparkle(204, 52, 8)
AP = [('A. Hinged bill', 'Upper and lower bill part, with a dark gap and a tongue when laughing. Most like a real bill.', A),
      ('B. Shape-changing bill', 'The bill itself changes shape: a round "O" for surprise, a wide grin for laughing. Like Pingu’s stretchy beak.', B),
      ('C. Inside the outline', 'The bill keeps its shape; a dark opening appears inside it. Simplest, but close to the drawn mouth you disliked.', C),
      ('D. A plus squash and stretch', 'The hinged bill, with the whole head stretching tall for surprise and squashing wide for laughter.', D)]
cards = ''
for t, n, f in AP:
    pair = ''.join(f'<div style="width: 112px; height: 112px; background: #FBF6E9; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="Puggle {e}, {t}" width="106" height="106" viewBox="24 10 192 192">{f(e)}</svg></div>' for e in ('surprised', 'laughing'))
    cards += (f'<div style="display: flex; flex-direction: column; gap: 8px; width: 232px"><div style="display: flex; gap: 8px">{pair}</div>'
              f'<div style="font-size: 16px; font-weight: 800">{t}</div><div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4">{n}</div></div>')
big = ''.join(f'<div style="width: 220px; height: 220px; background: {bg}; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="Puggle {e}, large" width="200" height="200" viewBox="24 10 192 192">{B(e)}</svg></div>' for e, bg in (('surprised', '#BFD9F5'), ('laughing', '#F4BE2C')))
body = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 24px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Open bill: superseded</h1><div style="font-size: 16px; font-weight: 700; color: #C24A36">Decision: the bill never changes. Puggle emotes through her eyes, floating marks and body language.</div>
<div style="display: flex; gap: 30px">{cards}</div>
<div style="display: flex; gap: 20px; align-items: center">{big}<div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.45; max-width: 420px"><b style="font-weight: 800">B, larger (recommended).</b> Rules: the bill keeps its colour, outline and nostrils, so she always reads as Puggle; only its shape changes. The opening is a dark warm tone, not black. A pink tongue only when laughing. Eyes do the rest: big dots for surprise, happy arcs for laughing.</div></div>
</div>'''
wrap('Open bill options (superseded)', body, 1080, 640, 'OpenBill.dc.html', 16640)
