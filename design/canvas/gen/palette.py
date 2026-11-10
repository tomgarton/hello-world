import sys, json
ROOT = sys.argv[1]
w = {'__name__': 'x'}; src = open(ROOT + '/gen/world.py').read(); exec(src[:src.index('walls = f')], w); wrap = w['wrap']
def lum(h):
    c = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def cr(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)
INK, PAPER = '#3A2A20', '#FBF6E9'
groups = [
 ('Base', [('Ink', INK), ('Paper', PAPER), ('Sand', '#F2ECDD'), ('Night', '#1B2440'), ('Moon', '#F3E0B8')]),
 ('Brights', [('Wattle', '#F4BE2C'), ('Harbour', '#2A62B8'), ('Waratah', '#E5553B'), ('Gum', '#3C9A5F')]),
 ('Soft fields', [('Sky', '#BFD9F5'), ('Shell', '#F3D9C9'), ('Mint', '#CFE5D2'), ('Sun', '#F4E7B0')]),
 ('Puggle', [('Fur', '#8A5A3C'), ('Bill', '#6E7F8D'), ('Blush', '#EE9C88'), ('Stitch', '#C24A36')]),
]
def best(c):
    a, b = cr(c, INK), cr(c, PAPER)
    return (INK, a) if a >= b else (PAPER, b)
rows = ''
report = []
for g, cols in groups:
    chips = ''
    for n, c in cols:
        t, r = best(c)
        ok = 'passes AA' if r >= 4.5 else ('large text only' if r >= 3 else 'fills only')
        report.append((n, c, 'ink' if t == INK else 'paper', round(r, 1), ok))
        chips += (f'<div style="width: 150px; height: 92px; background: {c}; border: 2px solid {INK}; box-sizing: border-box; padding: 10px 12px; display: flex; flex-direction: column; justify-content: space-between; color: {t}">'
                  f'<div style="font-size: 17px; font-weight: 800">{n}</div><div style="display: flex; flex-direction: column; font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; line-height: 1.3"><span>{c}</span><span>{r:.1f}, {ok}</span></div></div>')
    rows += f'<div style="display: flex; align-items: center; gap: 14px"><div style="width: 90px; font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">{g}</div><div style="display: flex; gap: 12px">{chips}</div></div>'
json.dump(report, open(ROOT + '/gen/palette_report.json', 'w'))
F = "font-family: 'Bricolage Grotesque', system-ui, sans-serif"
S = "font-family: -apple-system, 'SF Pro Text', system-ui, sans-serif"
types = [('Display', f'{F}; font-size: 40px; font-weight: 800; letter-spacing: -0.03em', 'One down, one to go.'),
         ('Title', f'{F}; font-size: 26px; font-weight: 800; letter-spacing: -0.02em', 'Last night'),
         ('Headline (system)', f'{S}; font-size: 17px; font-weight: 600', 'Last bottle 150 ml at 12:15'),
         ('Body (system)', f'{S}; font-size: 17px; font-weight: 400', 'Puggle slept through. Pebble was up once.'),
         ('Caption (system)', f'{S}; font-size: 13px; font-weight: 500', 'Dry since 11:30')]
type_html = ''.join(f'<div style="display: flex; align-items: baseline; gap: 14px"><div style="width: 130px; font-size: 12px; font-weight: 700; color: #5A4636">{n}</div><div style="{st}; color: {INK}; line-height: 1.15">{t}</div></div>' for n, st, t in types)
comps = (f'<button style="height: 52px; padding: 0 22px; border: 2.500px solid {INK}; border-radius: 16px; box-shadow: 3px 3px 0 {INK}; background: #F4BE2C; color: {INK}; font: inherit; font-size: 16px; font-weight: 800">Save bottle</button>'
         f'<button style="height: 52px; padding: 0 22px; border: 2.500px solid {INK}; border-radius: 16px; box-shadow: 3px 3px 0 {INK}; background: {PAPER}; color: {INK}; font: inherit; font-size: 16px; font-weight: 700">Cancel</button>'
         f'<div style="height: 36px; padding: 0 14px; border-radius: 18px; background: #BFD9F5; color: {INK}; display: flex; align-items: center; font-size: 14px; font-weight: 700">Puggle</div>'
         f'<div style="height: 36px; padding: 0 14px; border-radius: 18px; background: #F3D9C9; color: {INK}; display: flex; align-items: center; font-size: 14px; font-weight: 700">Pebble</div>')
body = f'''<div style="width: 1080px; height: 780px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; {F}; padding: 40px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; align-items: baseline; justify-content: space-between"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Palette and type</h1><div style="font-size: 13px; font-weight: 600; color: #4A3B30">Numbers: contrast of the label text on each colour (WCAG)</div></div>
<div style="display: flex; flex-direction: column; gap: 12px">{rows}</div>
<div style="display: flex; gap: 50px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 10px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Type</div>{type_html}</div>
<div style="display: flex; flex-direction: column; gap: 12px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Components</div><div style="display: flex; flex-wrap: wrap; gap: 12px; width: 330px">{comps}</div>
<div style="font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4; max-width: 330px">Text is always Ink on light colours and Paper or Moon on Night. Brights are fills, not text colours. Each child gets one soft field as their colour.</div></div>
</div>
</div>'''
wrap('Palette and type', body, 1080, 780, 'Palette.dc.html', 21800)
