import sys, json
ROOT = sys.argv[1]; P = ROOT + '/project/'
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, BILL, head, body, limb, p = [x[k] for k in ('O', 'PF', 'BILL', 'head', 'body', 'limb', 'p')]
fs = open(ROOT + '/gen/family.py').read(); exec(fs[fs.index('def bottle('):fs.index('def card(')], x); baby = x['baby']
hs = open(ROOT + '/gen/heads.py').read(); exec(hs[hs.index('SW = '):hs.index('ACC = [')], x); clip = x['clip']
ls = open(ROOT + '/gen/lineup.py').read(); exec(ls[ls.index('gsrc = open'):ls.index('hsrc = open')], {**x, 'ROOT': ROOT, 'x': x}); adult = x.get('adult')
INK, PAPER, SAND = '#3A2A20', '#FBF6E9', '#F2ECDD'
FONT = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">'
BTN = f"height: 56px; border: 2.500px solid {INK}; border-radius: 18px; box-shadow: 3px 3px 0 {INK}; font: inherit; font-size: 17px; font-weight: 800"
puggle = body('wave', 'happy', '#2A62B8') + clip(160, 56, '#E5553B')
pebble = baby('happy', '#F4BE2C')
def sv(svgbody, w, h, vb, label): return f'<svg role="img" aria-label="{label}" width="{w}" height="{h}" viewBox="{vb}">{svgbody}</svg>'
def screen(i, bg, head_txt, sub, art, title):
    dots = ''.join(f'<div style="width: {28 if j == i else 9}px; height: 9px; border-radius: 5px; background: {INK if j == i else "#C9B89F"}"></div>' for j in range(4))
    nxt = 'Get started' if i == 3 else 'Next'
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
a{{color:{INK}}}a:hover{{color:#5A4636}}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {bg}; color: {INK}; font-family: 'Bricolage Grotesque', system-ui, sans-serif; display: flex; flex-direction: column; padding: 58px 22px 34px 22px; gap: 14px">
<div style="display: flex; align-items: center; justify-content: flex-end; height: 44px"><button style="height: 44px; padding: 0 6px; border: none; background: transparent; color: {INK}; font: inherit; font-size: 16px; font-weight: 700">Skip</button></div>
<div style="display: flex; flex-direction: column; gap: 8px; padding-top: 8px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; line-height: 1.05; letter-spacing: -0.03em">{head_txt}</h1>
<div style="font-family: -apple-system, 'SF Pro Text', system-ui, sans-serif; font-size: 17px; line-height: 1.4; color: #4A3B30">{sub}</div>
</div>
<div style="flex-grow: 1; display: flex; align-items: center; justify-content: center">{art}</div>
<div style="display: flex; justify-content: center; gap: 8px; padding-bottom: 6px">{dots}</div>
<button style="{BTN}; background: #F4BE2C; color: {INK}">{nxt}</button>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":390,"height":844}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
S = "font-family: -apple-system, 'SF Pro Text', system-ui, sans-serif"
# 1 hello
art1 = (f'<div style="position: relative; width: 320px; height: 380px; display: flex; align-items: flex-end; justify-content: center">'
        f'<div style="position: absolute; left: 10px; top: 20px; width: 300px; height: 300px; border-radius: 150px; background: #BFD9F5"></div>'
        f'<div style="position: relative; display: flex; align-items: flex-end; gap: 0">{sv(puggle, 220, 262, "0 -14 252 304", "Puggle waving")}{sv(pebble, 120, 135, "0 -10 240 290", "Pebble sitting")}</div></div>')
# 2 shared log
def row(t, label, who, col):
    return (f'<div style="display: flex; align-items: center; gap: 12px; min-height: 52px; border-bottom: 1px solid #E4DAC6"><div style="width: 50px; {S}; font-size: 14px; font-weight: 600; color: #4A3B30; font-variant-numeric: tabular-nums">{t}</div>'
            f'<div style="flex-grow: 1; {S}; font-size: 16px; font-weight: 600">{label}</div><div style="height: 28px; padding: 0 10px; border-radius: 14px; background: {col}; display: flex; align-items: center; font-size: 13px; font-weight: 800">{who}</div></div>')
art2 = (f'<div style="width: 330px; display: flex; flex-direction: column; gap: 12px">'
        f'<div style="display: flex; align-items: center; gap: 10px; background: {PAPER}; border: 2.500px solid {INK}; border-radius: 22px; padding: 12px 14px; box-shadow: 3px 3px 0 {INK}">'
        f'<div style="width: 44px; height: 44px; border-radius: 22px; background: #F3D9C9; display: flex; align-items: center; justify-content: center; flex-shrink: 0">{sv(head("happy"), 38, 34, "40 34 160 146", "Mum")}</div>'
        f'<div style="{S}; font-size: 15px; line-height: 1.35"><b>Mum</b> logged a bottle for Bea, 150 ml. <span style="color: #4A3B30">Just now</span></div></div>'
        f'<div style="background: {PAPER}; border-radius: 22px; padding: 4px 16px">{row("2:50", "Bottle, 150 ml", "Bea", "#F3D9C9")}{row("2:08", "Nap started", "Ollie", "#BFD9F5")}{row("1:20", "Potty: wee", "Ollie", "#BFD9F5")}{row("12:15", "Nappy, wet", "Bea", "#F3D9C9")}</div>'
        f'<div style="font-size: 13px; font-weight: 600; color: #4A3B30; text-align: center">Example family</div></div>')
# 3 all children together
def kid(name, age, status, col, art):
    return (f'<div style="display: flex; align-items: center; gap: 12px; background: {col}; border-radius: 24px; padding: 12px 14px">'
            f'<div style="width: 64px; height: 64px; border-radius: 32px; background: {PAPER}; border: 3px solid {INK}; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0">{art}</div>'
            f'<div style="display: flex; flex-direction: column; gap: 2px"><div style="font-size: 19px; font-weight: 800">{name} <span style="font-size: 14px; font-weight: 600; color: #4A3B30">{age}</span></div><div style="{S}; font-size: 15px; font-variant-numeric: tabular-nums">{status}</div></div></div>')
art3 = (f'<div style="width: 330px; display: flex; flex-direction: column; gap: 12px">'
        + kid('Ollie', '2½', 'Napping 0:42', '#BFD9F5', sv(head('sleepy') + clip(160, 56, '#E5553B'), 56, 52, '36 20 170 160', 'Ollie’s character, asleep'))
        + kid('Bea', '6 months', 'Awake 1h 05m. Bottle due 3:45', '#F3D9C9', sv(head('happy') + x['curl'](), 56, 52, '36 4 170 176', 'Bea’s character, with a curl'))
        + f'<button style="{BTN}; background: {PAPER}; color: {INK}">+ Add a child</button>'
        f'<div style="font-size: 13px; font-weight: 600; color: #4A3B30; text-align: center">Twins, siblings, as many as you have</div></div>')
# 4 make their character
opts = ''.join(f'<div style="width: 46px; height: 46px; border-radius: 23px; background: {c}; border: {"4px" if k == 0 else "2px"} solid {INK if k == 0 else "#C9B89F"}; box-sizing: border-box"></div>' for k, c in enumerate(['#F4BE2C', '#BFD9F5', '#F3D9C9', '#CFE5D2', '#E5553B']))
art4 = (f'<div style="width: 330px; display: flex; flex-direction: column; align-items: center; gap: 14px">'
        f'<div style="width: 220px; height: 240px; border-radius: 30px; background: #CFE5D2; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 10px; box-sizing: border-box">{sv(pebble, 150, 170, "0 -10 240 290", "Bea as a baby platypus")}</div>'
        f'<div style="display: flex; gap: 10px">{opts}</div>'
        f'<div style="display: flex; gap: 10px"><button style="{BTN}; height: 48px; padding: 0 16px; background: {PAPER}; color: {INK}; font-size: 15px">Add a photo</button><button style="{BTN}; height: 48px; padding: 0 16px; background: {PAPER}; color: {INK}; font-size: 15px">Change friend</button></div></div>')
screens = [('OnboardHello.dc.html', 'Onboarding 1: hello', screen(0, SAND, 'Hello, little family.', 'The family tracker for every little one, from first bottle to first day of school.', art1, 'Onboarding, hello')),
           ('OnboardShared.dc.html', 'Onboarding 2: shared log', screen(1, SAND, 'Everyone sees the same day.', 'Log a bottle on one phone and it is on your partner’s phone straight away. Nan and the nanny too.', art2, 'Onboarding, shared log')),
           ('OnboardKids.dc.html', 'Onboarding 3: all your children', screen(2, SAND, 'All your little ones, in one place.', 'No switching between children. Timers for each, side by side.', art3, 'Onboarding, all children')),
           ('OnboardCharacter.dc.html', 'Onboarding 4: their character', screen(3, SAND, 'Make their character.', 'Pick a friend and an outfit, or use a photo. You can change it any time.', art4, 'Onboarding, character'))]
c = json.load(open(P + 'canvas.json'))
for i, (fn, title, html) in enumerate(screens):
    open(P + fn, 'w').write(html)
    assert html.count('<div') == html.count('</div>'), fn
    c['boards'][fn] = {'x': i * 470, 'y': 26600, 'w': 390, 'h': 844, 'title': title, 'radius': 44}
    if fn not in c['order']: c['order'].append(fn)
    open(ROOT + '/gen/' + fn.replace('.dc.html', '.html'), 'w').write('<head>' + FONT + '</head><body style="margin:0">' + html[html.index('<div style="width: 390px'):html.index('</x-dc>')].replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ') + '</body>')
c['notes']['row_onboard'] = {'x': 0, 'y': 26300, 'text': 'Onboarding', 'kind': 'title1', 'maxW': 1800}
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print('ok')
