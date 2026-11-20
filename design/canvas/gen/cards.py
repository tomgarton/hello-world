import sys, json
ROOT = sys.argv[1]; P = ROOT + '/project/'
rs = open(ROOT + '/gen/refined.py').read(); rs = rs[:rs.index('# --- components sheet')]
x = {}; exec(rs, x)
ps = open(ROOT + '/gen/props.py').read(); ps = ps[ps.index("SW = f'"):ps.index('PROPS = [')]
exec(ps, x)
INK, PAPER, SAND, MUTED, LINE, FIELD, S, D, sv, head, clip, curl, page, FONT = [x[k] for k in ('INK', 'PAPER', 'SAND', 'MUTED', 'LINE', 'FIELD', 'S', 'D', 'sv', 'head', 'clip', 'curl', 'page', 'FONT')]
isrc = open(ROOT + '/gen/icons.py').read(); isrc = isrc[:isrc.index('def cell(')]
ic = {'__name__': 'x', 'sys': sys}; exec(isrc.replace("ROOT = sys.argv[1]", "ROOT = " + repr(ROOT)), ic)
MAP = {'bottleprop': 'Bottle', 'blanket': 'Blanket', 'nappy': 'Nappy', 'potty': 'Potty', 'bowl': 'Bowl and spoon'}
prop = lambda name, sz: sv(ic['ICONS'][MAP[name]], sz, sz, '0 0 100 100', MAP[name])
plus = f'<button aria-label="Add" style="width: 40px; height: 40px; border-radius: 20px; border: none; background: {PAPER}; box-shadow: 0 1px 3px rgba(58,42,32,0.15); {S}; font-size: 24px; color: {INK}; flex-shrink: 0">+</button>'
def who(name, col, txt): return f'<div style="display: flex; align-items: center; gap: 8px"><div style="height: 22px; padding: 0 8px; border-radius: 11px; background: {col}; display: flex; align-items: center; {S}; font-size: 12px; font-weight: 600">{name}</div><div style="{S}; font-size: 14px; color: {MUTED}; font-variant-numeric: tabular-nums">{txt}</div></div>'
def card(icon, title, lines, wide=False):
    return (f'<div style="{"grid-column: span 2;" if wide else ""} background: #ECE4D4; border-radius: 26px; padding: 14px 14px 16px 16px; display: flex; flex-direction: column; gap: 6px">'
            f'<div style="display: flex; justify-content: space-between; align-items: flex-start">{prop(icon, 52 if not wide else 60)}{plus}</div>'
            f'<div style="{S}; font-size: 19px; font-weight: 600">{title}</div>{"".join(lines)}</div>')
O = '#3A2A20'
tip = (f'<div style="background: #ECE4D4; border-radius: 26px; padding: 16px; display: flex; gap: 12px; align-items: center">'
       f'<div style="flex-grow: 1; display: flex; flex-direction: column; gap: 6px"><div style="{S}; font-size: 17px; font-weight: 600">Invite Nan</div><div style="{S}; font-size: 14px; color: {MUTED}; line-height: 1.35">Anyone who helps can log, on their own phone.</div><div style="{S}; font-size: 14px; font-weight: 600">Send an invite ›</div></div>'
       f'{sv(x["head"]("happy") + x["GL"](122, "blue", 14), 70, 62, "36 34 170 150", "Nan")}</div>') if 'GL' in x else ''
gs = open(ROOT + '/gen/glasses.py').read(); exec(gs[gs.index('def glasses('):gs.index('POS = [')], x)
tip = (f'<div style="background: #ECE4D4; border-radius: 26px; padding: 16px; display: flex; gap: 12px; align-items: center">'
       f'<div style="flex-grow: 1; display: flex; flex-direction: column; gap: 6px"><div style="{S}; font-size: 17px; font-weight: 600">Invite Nan</div><div style="{S}; font-size: 14px; color: {MUTED}; line-height: 1.35">Anyone who helps can log, on their own phone.</div><div style="{S}; font-size: 14px; font-weight: 600">Send an invite ›</div></div>'
       f'{sv(x["head"]("happy") + x["glasses"](122, "blue", 14), 70, 62, "36 34 170 150", "Nan")}</div>')
grid = ('<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px">' +
        card('bottleprop', 'Feed', [who('Bea', '#F3D9C9', 'Bottle 150 ml, 2h 35m ago'), who('Ollie', '#BFD9F5', 'Lunch at 12:30')], True) +
        card('blanket', 'Sleep', [who('Ollie', '#BFD9F5', 'Asleep 0:42')]) +
        card('nappy', 'Nappy', [who('Bea', '#F3D9C9', '11:50')]) +
        card('potty', 'Potty', [who('Ollie', '#BFD9F5', '3 today')]) +
        card('bowl', 'Solids', [who('Bea', '#F3D9C9', 'Tried egg')]) + '</div>')
tabs = ''.join(f'<button style="flex: 1; height: 50px; border: none; background: transparent; {S}; font-size: 11px; font-weight: {600 if i == 0 else 500}; color: {INK if i == 0 else MUTED}">{t}</button>' for i, t in enumerate(('Today', 'History', 'Insights', 'Family')))
inner = f'''<div style="width: 390px; height: 844px; box-sizing: border-box; background: {SAND}; color: {INK}; position: relative; overflow: hidden">
<div style="padding: 58px 16px 0 16px; display: flex; flex-direction: column; gap: 14px">
<div style="display: flex; justify-content: space-between; align-items: center"><div style="{S}; font-size: 15px; color: {MUTED}">Tuesday 10 November</div>
<div style="display: flex">{"".join(f'<div style="width: 40px; height: 40px; border-radius: 20px; background: {c}; border: 2px solid {SAND}; margin-left: -8px; display: flex; align-items: center; justify-content: center; overflow: hidden">{a}</div>' for c, a in (("#BFD9F5", sv(head("happy") + clip(160, 56, "#E5553B"), 34, 30, "36 20 170 160", "Ollie")), ("#F3D9C9", sv(head("happy") + curl(), 34, 32, "36 4 170 176", "Bea"))))}</div></div>
<div><h1 style="margin: 0; {D}; font-size: 32px; font-weight: 800; letter-spacing: -0.03em">Ollie and Bea</h1></div>
{tip}
{grid}
</div>
<div style="position: absolute; left: 0; right: 0; bottom: 0; height: 84px; background: rgba(251,246,233,0.94); border-top: 1px solid {LINE}; display: flex; padding: 4px 8px 30px 8px; box-sizing: border-box">{tabs}</div>
</div>'''
html = page('Today, card grid', inner)
assert html.count('<div') == html.count('</div>')
open(P + 'RefinedCards.dc.html', 'w').write(html)
open(ROOT + '/gen/RefinedCards.html', 'w').write('<head>' + FONT + '</head><body style="margin:0">' + inner.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>')
c = json.load(open(P + 'canvas.json'))
c['boards']['RefinedCards.dc.html'] = {'x': 1410, 'y': 28560, 'w': 390, 'h': 844, 'title': 'Refined: Today as cards', 'radius': 44}
if 'RefinedCards.dc.html' not in c['order']: c['order'].append('RefinedCards.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print('ok')
