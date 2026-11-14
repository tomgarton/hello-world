import sys, math
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, head, wrap = x['O'], x['PF'], x['head'], x['wrap']
SW = f'stroke="{O}" stroke-width="5" stroke-linejoin="round"'
def quatre(cx, cy, r, c):
    return ''.join(f'<circle cx="{cx+dx*r}" cy="{cy+dy*r}" r="{r*1.15:.1f}" fill="{c}" {SW}></circle>' for dx, dy in ((-0.8, 0), (0.8, 0), (0, -0.8), (0, 0.8))) + ''.join(f'<circle cx="{cx+dx*r}" cy="{cy+dy*r}" r="{r*1.15-2.5:.1f}" fill="{c}"></circle>' for dx, dy in ((-0.8, 0), (0.8, 0), (0, -0.8), (0, 0.8))) + f'<circle cx="{cx}" cy="{cy}" r="{r*0.9:.1f}" fill="{c}"></circle>'
def bow(cx, cy, c):
    return f'<path d="M{cx} {cy}L{cx-24} {cy-14}Q{cx-30} {cy} {cx-24} {cy+14}Z" fill="{c}" {SW}></path><path d="M{cx} {cy}L{cx+24} {cy-14}Q{cx+30} {cy} {cx+24} {cy+14}Z" fill="{c}" {SW}></path><circle cx="{cx}" cy="{cy}" r="7" fill="{c}" {SW}></circle>'
def clip(cx, cy, c): return quatre(cx, cy, 11, c)
def headband(c): return f'<path d="M56 86Q120 22 184 86" fill="none" stroke="{O}" stroke-width="16" stroke-linecap="round"></path><path d="M56 86Q120 22 184 86" fill="none" stroke="{c}" stroke-width="8" stroke-linecap="round"></path>'
def bun(): return f'<circle cx="120" cy="44" r="20" fill="{PF}" {SW}></circle><path d="M104 54Q120 62 136 54" fill="none" stroke="#E5553B" stroke-width="6" stroke-linecap="round"></path>'
def flower(cx, cy, c): return ''.join(f'<circle cx="{cx+10*math.cos(math.radians(72*i-90)):.1f}" cy="{cy+10*math.sin(math.radians(72*i-90)):.1f}" r="8" fill="{c}" {SW}></circle>' for i in range(5)) + f'<circle cx="{cx}" cy="{cy}" r="6" fill="#F4BE2C" {SW}></circle>'
def beanie(c): return f'<path d="M52 92Q52 34 120 32Q188 34 188 92Z" fill="{c}" {SW}></path><rect x="46" y="80" width="148" height="22" rx="11" fill="{c}" {SW}></rect><circle cx="120" cy="26" r="12" fill="#FBF6E9" {SW}></circle>'
def bucket(c): return f'<path d="M66 70Q70 30 120 30Q170 30 174 70Z" fill="{c}" {SW}></path><path d="M40 74Q120 50 200 74Q204 84 192 84Q120 70 48 84Q36 84 40 74Z" fill="{c}" {SW}></path>'
def sunhat(c): return f'<ellipse cx="120" cy="66" rx="98" ry="18" fill="{c}" {SW}></ellipse><path d="M78 64Q80 26 120 26Q160 26 162 64Z" fill="{c}" {SW}></path><path d="M80 56H160" stroke="#E5553B" stroke-width="8"></path>'
ACC = [('Quatrefoil clip', clip(160, 56, '#E5553B'), 'Puggle’s signature: the brand shape as a hair clip'),
       ('Bow', bow(158, 52, '#E5553B'), 'Classic, but close to Hello Kitty'),
       ('Headband', headband('#3C9A5F'), 'Reads well front and side'),
       ('Bun (fur)', bun(), 'A fur topknot with a band; nearest to hair'),
       ('Flower', flower(160, 54, '#F3D9C9'), 'Mum’s accessory'),
       ('Beanie', beanie('#2A62B8'), 'Winter; links to the label'),
       ('Bucket hat', bucket('#3C9A5F'), 'Pop, and beach days'),
       ('Sun hat', sunhat('#F4E7B0'), 'Summer, sun safety')]
def cell(title, svg, note, w=116, hgt=112, vb='16 0 208 188'):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 3px; width: {w}px"><div style="width: {w}px; height: {hgt}px; background: #FBF6E9; display: flex; align-items: center; justify-content: center">'
            f'<svg role="img" aria-label="{title}" width="{w-10}" height="{hgt-8}" viewBox="{vb}">{svg}</svg></div><div style="font-size: 13px; font-weight: 800; text-align: center">{title}</div><div style="font-size: 11px; font-weight: 500; color: #4A3B30; text-align: center; line-height: 1.3">{note}</div></div>')
acc_html = ''.join(cell(t, (head('neutral') + a) if t not in ('Beanie', 'Bucket hat', 'Sun hat') else (head('neutral') + a), n) for t, a, n in ACC)
# curls for Pebble
def curl_a(): return f'<path d="M116 52q-4 -14 8 -16q10 0 6 9q-3 5 -8 2" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'
def curl_kewpie(): return f'<path d="M120 52Q104 30 120 14Q140 2 146 18Q148 30 134 30Q124 28 128 20" fill="none" stroke="{O}" stroke-width="13" stroke-linecap="round"></path><path d="M120 52Q104 30 120 14Q140 2 146 18Q148 30 134 30Q124 28 128 20" fill="none" stroke="{PF}" stroke-width="5" stroke-linecap="round"></path>'
def curl_tuft(): return ''.join(f'<path d="M{120+dx} 52Q{120+dx*2.2} 30 {120+dx*1.4-6} 22" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>' for dx in (-8, 0, 8))
def curl_spiral():
    pts = []
    for i in range(60):
        t = i / 59 * 2.3 * math.pi
        r = 3 + t * 3.2
        pts.append((120 + r * math.cos(t - math.pi / 2), 30 + r * math.sin(t - math.pi / 2)))
    d = 'M120 52 L' + ' L'.join(f'{a:.1f} {b:.1f}' for a, b in reversed(pts))
    return f'<path d="{d}" fill="none" stroke="{O}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"></path>'
def curl_bow(): return f'<path d="M120 52Q112 34 122 24Q134 18 136 30" fill="none" stroke="{O}" stroke-width="12" stroke-linecap="round"></path><path d="M120 52Q112 34 122 24Q134 18 136 30" fill="none" stroke="{PF}" stroke-width="4" stroke-linecap="round"></path>' + bow(118, 44, '#F3D9C9').replace('L{cx-24}', '')
def curl_fore(): return f'<path d="M96 66q6 -10 12 0t12 0t12 0t12 0" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path>'
CURLS = [('Current', curl_a(), 'Thin and lost at small sizes'),
         ('Kewpie curl', curl_kewpie(), 'A thick fur curl with an outline, after the Kewpie doll topknot. Recommended'),
         ('Three tufts', curl_tuft(), 'Newborn fuzz'),
         ('Spiral', curl_spiral(), 'Line-only swirl'),
         ('Curl with a bow', curl_bow(), 'Topknot tied with a tiny bow'),
         ('Forehead squiggle', curl_fore(), 'A zigzag across the brow, cartoon-strip style')]
curl_html = ''.join(cell(t, head('happy') + c, n, 140, 128, '30 -10 180 196') for t, c, n in CURLS)
body = f'''<div style="width: 1080px; height: 600px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 14px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">No hair: head accessories, and Pebble’s curl</h1>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Head accessories</div>
<div style="display: flex; gap: 6px">{acc_html}</div>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Pebble’s curl</div>
<div style="display: flex; gap: 12px">{curl_html}</div>
</div>'''
wrap('Head accessories and curls', body, 1080, 600, 'Heads.dc.html', 23980)
