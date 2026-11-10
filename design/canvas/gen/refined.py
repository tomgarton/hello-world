import sys, json
ROOT = sys.argv[1]; P = ROOT + '/project/'
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, head, body = [x[k] for k in ('O', 'PF', 'BILL', 'head', 'body')]
fs = open(ROOT + '/gen/family.py').read(); exec(fs[fs.index('def bottle('):fs.index('def card(')], x); baby, curl, bottle = x['baby'], x['curl'], x['bottle']
hs = open(ROOT + '/gen/heads.py').read(); exec(hs[hs.index('SW = '):hs.index('ACC = [')], x); clip = x['clip']
INK, PAPER, SAND, MUTED, LINE, FIELD = '#3A2A20', '#FBF6E9', '#F2ECDD', '#6B5E52', '#E4DAC6', '#EAE2D2'
FONT = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">'
S = "font-family: -apple-system, 'SF Pro Text', system-ui, sans-serif"
D = "font-family: 'Bricolage Grotesque', system-ui, sans-serif"
def sv(b, w, h, vb, label): return f'<svg role="img" aria-label="{label}" width="{w}" height="{h}" viewBox="{vb}">{b}</svg>'
def toggle(on, tint='#3C9A5F'):
    return (f'<button role="switch" aria-checked="{"true" if on else "false"}" style="width: 51px; height: 31px; border-radius: 16px; border: none; padding: 2px; background: {tint if on else "#D8CFBF"}; display: flex; justify-content: {"flex-end" if on else "flex-start"}">'
            f'<div style="width: 27px; height: 27px; border-radius: 14px; background: #FFFFFF; box-shadow: 0 2px 4px rgba(58,42,32,0.25)"></div></button>')
def pill(label, bg=INK, fg=PAPER, h=54): return f'<button style="height: {h}px; padding: 0 22px; border: none; border-radius: {h//2}px; background: {bg}; color: {fg}; {S}; font-size: 17px; font-weight: 600">{label}</button>'
def seg(opts, i):
    return (f'<div style="display: flex; gap: 2px; background: {FIELD}; border-radius: 12px; padding: 3px">' +
            ''.join(f'<button style="flex: 1; height: 36px; padding: 0 14px; border: none; border-radius: 9px; background: {"#FFFFFF" if k == i else "transparent"}; box-shadow: {"0 1px 3px rgba(58,42,32,0.15)" if k == i else "none"}; color: {INK}; {S}; font-size: 15px; font-weight: {600 if k == i else 500}">{o}</button>' for k, o in enumerate(opts)) + '</div>')
def iconchip(svgbody, bg, size=44): return f'<div style="width: {size}px; height: {size}px; border-radius: {size//2}px; background: {bg}; display: flex; align-items: center; justify-content: center; flex-shrink: 0">{svgbody}</div>'
I = lambda d: f'<svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="{INK}" stroke-width="1.800" stroke-linecap="round" stroke-linejoin="round">{d}</svg>'
ICONS = {'bottle': I('<path d="M10 2h4v3h-4z"></path><path d="M8 8a3 3 0 0 1 3-3h2a3 3 0 0 1 3 3v11a3 3 0 0 1-3 3h-2a3 3 0 0 1-3-3z"></path><path d="M8 13h8"></path>'),
         'moon': I('<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"></path>'),
         'drop': I('<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"></path>'),
         'potty': I('<path d="M5 10h14l-2 9a2 2 0 0 1-2 1H9a2 2 0 0 1-2-1z"></path><path d="M4 7h16v3H4z"></path>'),
         'bowl': I('<path d="M3 11h18a9 9 0 0 1-18 0z"></path><path d="M9 7c0-1 1-1 1-2M13 7c0-1 1-1 1-2"></path>'),
         'chev': I('<path d="M9 6l6 6-6 6"></path>')}
def listrow(icon, chipbg, title, sub='', right='', last=False):
    return (f'<div style="display: flex; align-items: center; gap: 14px; min-height: 64px; border-bottom: {"none" if last else f"1px solid {LINE}"}">{iconchip(ICONS[icon], chipbg)}'
            f'<div style="flex-grow: 1; display: flex; flex-direction: column; gap: 2px"><div style="{S}; font-size: 17px; font-weight: 500">{title}</div>{f"<div style={chr(34)}{S}; font-size: 14px; color: {MUTED}{chr(34)}>{sub}</div>" if sub else ""}</div>{right}</div>')
def field(label, value):
    return f'<div style="display: flex; justify-content: space-between; align-items: center; height: 52px; padding: 0 16px; border-radius: 14px; background: {FIELD}"><div style="{S}; font-size: 16px; font-weight: 500">{label}</div><div style="{S}; font-size: 16px; color: {MUTED}">{value}</div></div>'
def page(title, inner, w=390, h=844, bg=SAND):
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONT}
<style>
body{{margin:0}}
a{{color:{INK}}}a:hover{{color:{MUTED}}}
</style>
</helmet>
{inner}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
# --- components sheet
comp = f'''<div style="width: 1080px; height: 620px; box-sizing: border-box; background: {SAND}; color: {INK}; {D}; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Refined Puggle: controls</h1>
<div style="display: flex; gap: 46px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 14px; width: 300px">
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Buttons</div>
<div style="display: flex; flex-direction: column; gap: 10px">{pill("Save")}{pill("Cancel", FIELD, INK)}<div style="display: flex; gap: 10px">{pill("Skip", "transparent", INK, 44)}{pill("Add a child", "#BFD9F5", INK, 44)}</div></div>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Segmented</div>{seg(["Formula", "Breast", "Mixed"], 0)}
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Toggles</div>
<div style="display: flex; gap: 12px">{toggle(True)}{toggle(False)}{toggle(True, "#2A62B8")}</div>
</div>
<div style="display: flex; flex-direction: column; gap: 14px; width: 300px">
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Fields</div>
{field("Time", "Now, 2:50 pm")}{field("Note", "Add")}
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Rows</div>
<div style="background: {PAPER}; border-radius: 20px; padding: 0 16px">{listrow("bottle", "#F3D9C9", "Bottle")}{listrow("moon", "#BFD9F5", "Sleep")}{listrow("potty", "#CFE5D2", "Potty", last=True)}</div>
</div>
<div style="display: flex; flex-direction: column; gap: 14px; width: 260px">
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Numbers</div>
<div style="display: flex; align-items: baseline; gap: 4px"><div style="{D}; font-size: 76px; font-weight: 500; letter-spacing: -0.04em; line-height: 1; font-variant-numeric: tabular-nums">150</div><div style="{S}; font-size: 18px; color: {MUTED}">ml</div></div>
<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: {MUTED}">Character, sparingly</div>
<div style="display: flex; gap: 12px; align-items: center">{iconchip(sv(head("happy") + clip(160, 56, "#E5553B"), 40, 36, "36 20 170 160", "Puggle avatar"), "#BFD9F5", 52)}<div style="{S}; font-size: 14px; color: {MUTED}; line-height: 1.4">Avatars, empty states, celebrations. Never on every row.</div></div>
</div>
</div>
<div style="{S}; font-size: 13px; color: {MUTED}">Native-feeling: filled pills with no outline or hard shadow, soft filled fields, system toggles and segmented controls, tinted icon circles, thin dividers. Bricolage for titles and big numbers only.</div>
</div>'''
# --- today refined
kid = lambda name, age, status, col, art: (f'<div style="display: flex; align-items: center; gap: 14px; background: {PAPER}; border-radius: 22px; padding: 14px 16px">'
         f'{iconchip(art, col, 52)}<div style="flex-grow: 1; display: flex; flex-direction: column; gap: 2px"><div style="{S}; font-size: 17px; font-weight: 600">{name} <span style="font-weight: 400; color: {MUTED}">{age}</span></div><div style="{S}; font-size: 15px; color: {MUTED}; font-variant-numeric: tabular-nums">{status}</div></div></div>')
today = f'''<div style="width: 390px; height: 844px; box-sizing: border-box; background: {SAND}; color: {INK}; display: flex; flex-direction: column; padding: 58px 18px 0 18px; gap: 16px; position: relative; overflow: hidden">
<div style="display: flex; justify-content: space-between; align-items: flex-end"><div style="display: flex; flex-direction: column; gap: 2px"><div style="{S}; font-size: 14px; color: {MUTED}">Tuesday 10 November</div><h1 style="margin: 0; {D}; font-size: 34px; font-weight: 800; letter-spacing: -0.03em">Today</h1></div>
{seg(["Both", "Ollie", "Bea"], 0).replace('flex: 1;', '')}</div>
<div style="display: flex; flex-direction: column; gap: 10px">
{kid("Ollie", "2½", "Napping 0:42", "#BFD9F5", sv(head("sleepy") + clip(160, 56, "#E5553B"), 40, 36, "36 20 170 160", "Ollie"))}
{kid("Bea", "6 mo", "Awake 1h 05m · bottle due 3:45", "#F3D9C9", sv(head("happy") + curl(), 40, 38, "36 4 170 176", "Bea"))}
</div>
<div style="background: {PAPER}; border-radius: 22px; padding: 0 16px">
{listrow("bottle", "#F3D9C9", "Bottle, 150 ml", "Bea · 12:15")}{listrow("moon", "#BFD9F5", "Nap started", "Ollie · 2:08")}{listrow("potty", "#CFE5D2", "Potty, wee", "Ollie · 1:20")}{listrow("drop", "#F3D9C9", "Nappy, wet", "Bea · 11:50", last=True)}
</div>
<div style="position: absolute; left: 18px; right: 18px; bottom: 34px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px">
{"".join(f'<button style="height: 64px; border: none; border-radius: 20px; background: {PAPER}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; {S}; font-size: 13px; font-weight: 600; color: {INK}; box-shadow: 0 1px 2px rgba(58,42,32,0.08)">{ICONS[i]}{t}</button>' for i, t in (("bottle", "Feed"), ("moon", "Sleep"), ("drop", "Nappy"), ("potty", "Potty")))}
</div>
</div>'''
# --- bottle sheet refined
sheet = f'''<div style="width: 390px; height: 844px; box-sizing: border-box; background: #8F857A; color: {INK}; display: flex; flex-direction: column; padding-top: 300px; position: relative; overflow: hidden">
<div style="flex-grow: 1; background: {SAND}; border-radius: 30px 30px 0 0; padding: 10px 18px 34px 18px; display: flex; flex-direction: column; gap: 16px">
<div style="display: flex; justify-content: center"><div style="width: 36px; height: 5px; border-radius: 3px; background: #C9BFAF"></div></div>
<div style="display: flex; justify-content: space-between; align-items: center"><div style="{S}; font-size: 17px; font-weight: 600">Bottle</div><button aria-label="Close" style="width: 32px; height: 32px; border-radius: 16px; border: none; background: {FIELD}; {S}; font-size: 15px; color: {MUTED}">✕</button></div>
{seg(["Bea", "Ollie", "Both"], 0)}
<div style="display: flex; align-items: baseline; justify-content: center; gap: 4px; padding: 6px 0"><div style="{D}; font-size: 76px; font-weight: 500; letter-spacing: -0.04em; line-height: 1; font-variant-numeric: tabular-nums">150</div><div style="{S}; font-size: 18px; color: {MUTED}">ml</div></div>
{seg(["Formula", "Breast milk", "Mixed"], 0)}
{field("Time", "Now, 2:50 pm")}
<div style="display: flex; justify-content: space-between; align-items: center; height: 52px; padding: 0 16px; border-radius: 14px; background: {FIELD}"><div style="{S}; font-size: 16px; font-weight: 500">Remind me in 3 hours</div>{toggle(True)}</div>
<div style="flex-grow: 1"></div>
{pill("Save bottle")}
</div></div>'''
# --- import
imp = f'''<div style="width: 390px; height: 844px; box-sizing: border-box; background: {SAND}; color: {INK}; display: flex; flex-direction: column; padding: 58px 18px 34px 18px; gap: 16px">
<button style="align-self: flex-start; height: 44px; border: none; background: transparent; {S}; font-size: 17px; color: {INK}; padding: 0">‹ Settings</button>
<div style="display: flex; flex-direction: column; gap: 8px"><h1 style="margin: 0; {D}; font-size: 32px; font-weight: 800; letter-spacing: -0.03em; line-height: 1.05">Bring your history with you.</h1><div style="{S}; font-size: 16px; line-height: 1.4; color: {MUTED}">Export from your old app, then open the file here. Feeds, sleep, nappies, growth and milestones come across with their dates.</div></div>
<div style="background: {PAPER}; border-radius: 22px; padding: 0 16px">
{"".join(listrow(i, c, n, s, ICONS["chev"], last=(k == 3)) for k, (i, c, n, s) in enumerate((("bottle", "#F3D9C9", "Nara Baby", "Export file"), ("moon", "#BFD9F5", "Huckleberry", "Export file"), ("drop", "#CFE5D2", "Baby Tracker", "CSV export"), ("bowl", "#F4E7B0", "Another app", "Any CSV"))))}
</div>
<div style="display: flex; gap: 12px; align-items: center; background: {PAPER}; border-radius: 22px; padding: 14px 16px">{iconchip(sv(head("happy") + clip(160, 56, "#E5553B"), 40, 36, "36 20 170 160", "Puggle"), "#BFD9F5", 52)}<div style="{S}; font-size: 14px; line-height: 1.4; color: {MUTED}">If you and your partner both import the same file, Puggle only adds it once.</div></div>
<div style="flex-grow: 1"></div>{pill("Choose file")}</div>'''
boards = [('RefinedControls.dc.html', 'Refined: controls', comp, 1080, 620, 0), ('RefinedToday.dc.html', 'Refined: Today', today, 390, 844, 1), ('RefinedBottle.dc.html', 'Refined: bottle sheet', sheet, 390, 844, 2), ('RefinedImport.dc.html', 'Refined: import', imp, 390, 844, 3)]
c = json.load(open(P + 'canvas.json'))
pos = {0: (0, 27800), 1: (0, 28560), 2: (470, 28560), 3: (940, 28560)}
for fn, t, inner, w_, h_, k in boards:
    html = page(t, inner, w_, h_)
    assert html.count('<div') == html.count('</div>'), fn
    open(P + fn, 'w').write(html)
    c['boards'][fn] = {'x': pos[k][0], 'y': pos[k][1], 'w': w_, 'h': h_, 'title': t, **({'radius': 44} if w_ == 390 else {})}
    if fn not in c['order']: c['order'].append(fn)
    open(ROOT + '/gen/' + fn.replace('.dc.html', '.html'), 'w').write('<head>' + FONT + '</head><body style="margin:0">' + inner.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>')
c['notes']['row_refined'] = {'x': 0, 'y': 27500, 'text': 'Refined Puggle', 'kind': 'title1', 'maxW': 1330}
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print('ok')
