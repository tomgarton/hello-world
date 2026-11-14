import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, p, head, limb, wrap = [x[k] for k in ('O', 'PF', 'BILL', 'p', 'head', 'limb', 'wrap')]
fsrc = open(ROOT + '/gen/family.py').read(); fsrc = fsrc[fsrc.index('def bottle('):fsrc.index('def curl(')]
exec(fsrc, x); bottle = x['bottle']
SW = f'stroke="{O}" stroke-width="5" stroke-linejoin="round"'
def nappy(): return f'<path d="M18 30H82Q86 30 84 40L74 70Q68 84 50 84Q32 84 26 70L16 40Q14 30 18 30Z" fill="#FBF6E9" {SW}></path><rect x="14" y="28" width="72" height="12" rx="5" fill="#BFD9F5" {SW}></rect><circle cx="30" cy="34" r="3" fill="{O}"></circle><circle cx="70" cy="34" r="3" fill="{O}"></circle>'
def potty(): return f'<path d="M18 46H82L74 82Q72 88 64 88H36Q28 88 26 82Z" fill="#FBF6E9" {SW}></path><rect x="10" y="36" width="80" height="14" rx="7" fill="#BFD9F5" {SW}></rect><path d="M84 52q14 4 6 18" fill="none" {SW}></path>'
def toothbrush(): return f'<rect x="12" y="44" width="62" height="12" rx="6" fill="#3C9A5F" {SW}></rect><rect x="66" y="34" width="22" height="14" rx="4" fill="#FBF6E9" {SW}></rect>' + ''.join(f'<path d="M{x0} 34v-8" stroke="{O}" stroke-width="3" stroke-linecap="round"></path>' for x0 in (70, 76, 82))
def book(): return f'<path d="M50 30Q34 22 14 24V78Q34 76 50 84Q66 76 86 78V24Q66 22 50 30Z" fill="#E5553B" {SW}></path><path d="M50 30V84" stroke="{O}" stroke-width="4"></path><path d="M22 36Q34 34 44 38M56 38Q66 34 78 36" stroke="#FBF6E9" stroke-width="4" stroke-linecap="round" fill="none"></path>'
def bowl(): return f'<path d="M14 46H86Q84 80 50 80Q16 80 14 46Z" fill="#F4BE2C" {SW}></path><path d="M60 46L84 14" stroke="{O}" stroke-width="9" stroke-linecap="round"></path><path d="M60 46L84 14" stroke="#BFD9F5" stroke-width="4" stroke-linecap="round"></path><ellipse cx="50" cy="46" rx="36" ry="6" fill="#F3D9C9" {SW}></ellipse>'
def cup(): return f'<rect x="28" y="30" width="40" height="52" rx="10" fill="#BFD9F5" {SW}></rect><path d="M28 30H68V24Q68 18 62 18H34Q28 18 28 24Z" fill="#E5553B" {SW}></path><path d="M68 44q16 2 14 14q-2 10 -14 10" fill="none" {SW}></path><path d="M44 18V8" stroke="{O}" stroke-width="6" stroke-linecap="round"></path>'
def duck(): return f'<ellipse cx="48" cy="62" rx="34" ry="20" fill="#F4BE2C" {SW}></ellipse><circle cx="62" cy="38" r="16" fill="#F4BE2C" {SW}></circle><path d="M76 38L92 42L76 46Z" fill="#E5553B" {SW}></path><circle cx="66" cy="34" r="3" fill="{O}"></circle>'
def blanket(): return f'<path d="M14 28Q50 18 86 28L82 78Q50 88 18 78Z" fill="#F3D9C9" {SW}></path>' + ''.join(f'<circle cx="{cx}" cy="{cy}" r="4" fill="#E5553B"></circle>' for cx, cy in ((32, 40), (54, 36), (72, 44), (40, 60), (64, 64)))
def plush(): return (f'<ellipse cx="50" cy="44" rx="30" ry="26" fill="{PF}" {SW}></ellipse><ellipse cx="50" cy="58" rx="22" ry="11" fill="{BILL}" {SW}></ellipse>'
                     f'<circle cx="38" cy="40" r="3.500" fill="{O}"></circle><circle cx="62" cy="40" r="3.500" fill="{O}"></circle><path d="M30 70Q50 92 70 70" fill="#F4BE2C" {SW}></path>')
def wattle(): return f'<path d="M50 94Q52 60 46 30" fill="none" stroke="#6E9C7E" stroke-width="5"></path>' + ''.join(f'<circle cx="{cx}" cy="{cy}" r="9" fill="#F4BE2C" stroke="{O}" stroke-width="3.500"></circle>' for cx, cy in ((46, 24), (34, 36), (58, 34), (44, 46), (56, 52)))
def balloon(): return f'<path d="M50 70Q56 84 50 96" fill="none" stroke="{O}" stroke-width="3"></path><ellipse cx="50" cy="38" rx="26" ry="31" fill="#E5553B" {SW}></ellipse><path d="M45 70h10l-5 -6z" fill="#E5553B" stroke="{O}" stroke-width="3"></path><path d="M38 24q4 -8 12 -9" fill="none" stroke="#FBF6E9" stroke-width="4" stroke-linecap="round"></path>'
def bottleprop(): return bottle(50, 56, 0)
PROPS = [('Bottle', bottleprop, 'Feeds'), ('Nappy', nappy, 'Changes'), ('Potty', potty, 'Potty training'), ('Bowl and spoon', bowl, 'First foods'),
         ('Sippy cup', cup, 'Drinks'), ('Toothbrush', toothbrush, 'Teeth'), ('Book', book, 'Bedtime'), ('Blanket', blanket, 'Sleep'),
         ('Rubber duck', duck, 'Bath time'), ('Puggle plush', plush, 'Comfort toy'), ('Wattle', wattle, 'Walks, gifts'), ('Balloon', balloon, 'Birthdays')]
cells = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 2px; width: 120px"><div style="width: 104px; height: 96px; background: #FBF6E9; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="{n}" width="76" height="76" viewBox="0 0 100 100">{f()}</svg></div><div style="font-size: 14px; font-weight: 800">{n}</div><div style="font-size: 12px; font-weight: 500; color: #4A3B30">{u}</div></div>' for n, f, u in PROPS)
def g(svg, sx, sy, s): return f'<g transform="translate({sx} {sy}) scale({s})">{svg}</g>'
def hands(pts):
    return ''.join(f'<circle cx="{a}" cy="{b}" r="12.500" fill="{PF}" stroke="{O}" stroke-width="5"></circle>' for a, b in pts)
def holding(arms, prop, col):
    L = ''.join(limb(*a[:4], col, a[4]) for a in arms)
    return p['tail'](PF) + p['legs'](PF) + p['feet'](BILL) + p['trap'](col) + p['pocket'](210) + L + head('happy') + prop
uses = [('Book, two hands', holding([(90, 180, 96, 206, 6), (150, 180, 144, 206, -6)], '', '#2A62B8').replace(head('happy'), head('happy') + g(book(), 78, 166, 0.84) + hands(((96, 206), (144, 206)))), '#BFD9F5'),
        ('Toothbrush', holding([(88, 178, 50, 214, 4), (152, 178, 176, 150, -10)], g(toothbrush(), 150, 112, 0.6), '#3C9A5F'), '#CFE5D2'),
        ('Plush, a cuddle', holding([(90, 180, 104, 210, 8), (150, 180, 136, 210, -8)], '', '#F4BE2C').replace(head('happy'), head('happy') + g(plush(), 88, 170, 0.64) + hands(((104, 210), (136, 210)))), '#F3D9C9')]
use_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 4px; width: 170px"><div style="width: 170px; height: 196px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 6px; box-sizing: border-box"><svg role="img" aria-label="Puggle holding: {n}" width="154" height="184" viewBox="0 -10 252 300">{s}</svg></div><div style="font-size: 14px; font-weight: 800">{n}</div></div>' for n, s, bg in uses)
bodyh = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Props</h1>
<div style="display: flex; gap: 40px; align-items: flex-start">
<div style="display: grid; grid-template-columns: repeat(4, 120px); gap: 14px 12px; align-content: start">{cells}</div>
<div style="display: flex; flex-direction: column; gap: 12px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Held by a ball hand</div>
<div style="display: flex; gap: 14px; flex-wrap: wrap; width: 370px">{use_html}</div>
<div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4; max-width: 370px">Props are drawn in the same outline and palette, sized to Puggle's hands, with a grip point (a handle, a spine, a stem) so a ball hand can plausibly hold them.</div></div>
</div>
</div>'''
wrap('Props', bodyh, 1080, 640, 'Props.dc.html', 20360)
