import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, head, wrap = x['O'], x['head'], x['wrap']
def glasses(y, lens, r=15, bridge_y=None):
    by = bridge_y if bridge_y is not None else y
    fill = {'clear': 'none', 'blue': '#DCEEFB', 'black': '#3A2A20'}[lens]
    op = ''
    s = ''.join(f'<circle cx="{cx}" cy="{y}" r="{r}" fill="{fill}"{op} stroke="{O}" stroke-width="5"></circle>' for cx in (93, 147))
    if lens == 'blue':
        s += ''.join(f'<path d="M{cx-8} {y-6}q4 -5 10 -6" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"></path>' for cx in (93, 147))
    if lens == 'blue' and y < 120:
        s += ''.join(f'<circle cx="{cx}" cy="108" r="7.600" fill="{O}"></circle>' for cx in (93, 147))
    s += f'<path d="M{93+r} {by}Q120 {by-6} {147-r} {by}" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'
    s += f'<path d="M{93-r} {y-2}L56 {y-8}M{147+r} {y-2}L184 {y-8}" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'
    return s
POS = [('At eye level', 108), ('Resting on the bill', 134)]
LENS = [('Rims only', 'clear'), ('Light blue lenses', 'blue'), ('Black lenses', 'black')]
grid = ''
for pn, y in POS:
    cells = ''
    for ln, l in LENS:
        cells += (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><div style="width: 150px; height: 136px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">'
                  f'<svg role="img" aria-label="Glasses {pn.lower()}, {ln.lower()}" width="140" height="128" viewBox="30 30 180 165">{head("neutral") + glasses(y, l, 14 if y > 120 else 15)}</svg></div><div style="font-size: 13px; font-weight: 700">{ln}</div></div>')
    grid += f'<div style="display: flex; align-items: center; gap: 14px"><div style="width: 100px; font-size: 14px; font-weight: 800">{pn}</div><div style="display: flex; gap: 12px">{cells}</div></div>'
pair = (f'<svg role="img" aria-label="Nan with low reading glasses and Pop with round glasses at eye level" width="300" height="140" viewBox="0 30 470 210">'
        f'<g transform="translate(0 0)">{head("happy") + glasses(134, "blue")}</g><g transform="translate(230 0)">{head("neutral") + glasses(108, "clear")}'
        f'<path d="M62 64Q120 22 178 64Z" fill="#3C9A5F" stroke="{O}" stroke-width="6" stroke-linejoin="round"></path><path d="M48 66H192" stroke="{O}" stroke-width="7" stroke-linecap="round"></path></g></svg>')
rules = ['Few and signature: one accessory per character, like Hello Kitty’s bow or Paddington’s hat.',
         'Same drawing rules: flat colour, the same outline, from the palette, no extra detail lines.',
         'Never hide the eyes: they carry every expression. Black lenses only for a sunny-day joke.',
         'Must read in silhouette and at icon size: glasses as two circles, a hat as one shape.',
         'Accessories can tell characters apart: Nan’s low reading glasses, Pop’s hat.']
rule_html = ''.join(f'<li style="margin-bottom: 6px">{r}</li>' for r in rules)
body = f'''<div style="width: 1080px; height: 560px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Glasses and accessories</h1>
<div style="display: flex; gap: 40px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 16px">{grid}</div>
<div style="display: flex; flex-direction: column; gap: 10px; width: 330px">{pair}
<div style="font-size: 13px; font-weight: 600; color: #4A3B30">Suggested: Nan in light blue reading glasses low on her bill; Pop in round rims at eye level, with his hat.</div>
<ul style="margin: 0; padding-left: 18px; font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4">{rule_html}</ul></div>
</div>
</div>'''
wrap('Glasses and accessories', body, 1080, 560, 'Glasses.dc.html', 22700)
