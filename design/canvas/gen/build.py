import json, sys
P = sys.argv[1] + '/project/'

def blob(cx, cy, fill, ink, asleep=False, hat=False, style=''):
    eyes = (f'<path d="M{cx-12} {cy-2}c2 3 6 3 8 0" fill="none" stroke="{ink}" stroke-width="2.500" stroke-linecap="round"></path>'
            f'<path d="M{cx+4} {cy-2}c2 3 6 3 8 0" fill="none" stroke="{ink}" stroke-width="2.500" stroke-linecap="round"></path>') if asleep else (
            f'<circle cx="{cx-8}" cy="{cy-3}" r="3" fill="{ink}"></circle><circle cx="{cx+8}" cy="{cy-3}" r="3" fill="{ink}"></circle>')
    mouth = f'<path d="M{cx-4} {cy+7}c2 3 6 3 8 0" fill="none" stroke="{ink}" stroke-width="2.500" stroke-linecap="round"></path>'
    h = (f'<path d="M{cx-9} {cy-20}L{cx} {cy-42}L{cx+9} {cy-20}z" fill="#FFC531" stroke="{ink}" stroke-width="2.500" stroke-linejoin="round"></path>'
         f'<circle cx="{cx}" cy="{cy-43}" r="3.500" fill="#FFFFFF" stroke="{ink}" stroke-width="2"></circle>') if hat else ''
    st = f' style="{style}"' if style else ''
    return f'<g{st}>{h}<ellipse cx="{cx}" cy="{cy}" rx="24" ry="21" fill="{fill}" stroke="{ink}" stroke-width="2.500"></ellipse>{eyes}{mouth}</g>'

def cloud(fill, ink, style=''):
    st = f' style="{style}"' if style else ''
    return (f'<g{st}>' + blob(262, 236, '#FFB170', ink, asleep=True) +
      f'<rect x="200" y="252" width="124" height="44" rx="22" fill="{fill}"></rect><circle cx="232" cy="254" r="20" fill="{fill}"></circle><circle cx="290" cy="256" r="18" fill="{fill}"></circle>'
      f'<path d="M318 206h12l-12 14h12" fill="none" stroke="{ink}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></path>'
      f'<path d="M338 184h9l-9 10h9" fill="none" stroke="{ink}" stroke-width="2.500" stroke-linecap="round" stroke-linejoin="round"></path></g>')

def scene(kind, anim=False):
    ink = '#0F2238'
    a = lambda s: s if anim else ''
    if kind == 'day':
        label = 'Afternoon sun over two hills. An orange character sleeps on a cloud and a blue character is awake on the hill'
        body = (f'<circle cx="320" cy="112" r="42" fill="#FFC531" stroke="{ink}" stroke-width="2.500"></circle>'
          f'<circle cx="320" cy="112" r="62" fill="none" stroke="{ink}" stroke-width="3" stroke-dasharray="2 14" stroke-linecap="round" style="{a("transform-box: fill-box; transform-origin: center; animation: spin 6s linear infinite")}"></circle>'
          f'<ellipse cx="300" cy="424" rx="230" ry="110" fill="#2E9E66"></ellipse><ellipse cx="70" cy="436" rx="220" ry="120" fill="#3FBF7F"></ellipse>'
          + blob(112, 302, '#8EC0FF', ink, style=a('animation: hop 0.9s ease-in-out infinite')) + cloud('#FFFFFF', ink, a('animation: bob 2.4s ease-in-out infinite')))
    elif kind == 'night':
        ink2 = '#0B0F20'
        label = 'Night sky with a crescent moon and stars. An orange character sleeps on a cloud and a blue character is awake on the hill'
        stars = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#F3E0B8"></circle>' for x, y, r in [(236,70,2),(270,150,1.5),(352,196,2),(196,120,1.5),(300,40,1.5),(160,200,2),(372,70,1.5)])
        body = (f'<path d="M324 66a46 46 0 1 0 32 80 38 38 0 0 1-32-80z" fill="#F3E0B8" stroke="{ink2}" stroke-width="2.500" stroke-linejoin="round"></path>' + stars +
          f'<path d="M196 120L236 70 300 40" fill="none" stroke="#F3E0B8" stroke-width="1" stroke-dasharray="2 5" stroke-linecap="round"></path>'
          f'<ellipse cx="300" cy="424" rx="230" ry="110" fill="#1B2550"></ellipse><ellipse cx="70" cy="436" rx="220" ry="120" fill="#27336A"></ellipse>'
          + blob(112, 302, '#8EC0FF', ink2) + cloud('#45528F', ink2).replace('stroke="#0B0F20" stroke-width="3"', 'stroke="#F3E0B8" stroke-width="3"').replace('h9l-9 10h9" fill="none" stroke="#0B0F20"', 'h9l-9 10h9" fill="none" stroke="#F3E0B8"'))
    else:
        label = 'Morning scene with bunting. A blue character in a party hat stands on the hill beside an orange character'
        flags = ''
        cols = ['#FFC531', '#FF8A5B', '#8EC0FF', '#FFFFFF', '#FFC531', '#FF8A5B', '#8EC0FF']
        for i, c in enumerate(cols):
            x = 150 + i * 34; y = 196 + (i - 3) ** 2 * 2.2 * -1 + 20
            flags += f'<path d="M{x} {y:.0f}h24l-12 22z" fill="{c}" stroke="{ink}" stroke-width="2.500" stroke-linejoin="round"></path>'
        body = (f'<circle cx="330" cy="330" r="46" fill="#FFC531" stroke="{ink}" stroke-width="2.500"></circle>'
          f'<path d="M140 204q125 34 250-8" fill="none" stroke="{ink}" stroke-width="2.500" stroke-linecap="round"></path>' + flags +
          f'<ellipse cx="300" cy="424" rx="230" ry="110" fill="#2E9E66"></ellipse><ellipse cx="70" cy="436" rx="220" ry="120" fill="#3FBF7F"></ellipse>'
          + blob(104, 300, '#8EC0FF', ink, hat=True) + blob(250, 302, '#FFB170', ink))
    return f'<svg role="img" aria-label="{label}" width="390" height="396" viewBox="0 0 390 396" style="position: absolute; left: 0; top: 0">{body}</svg>'

def page(fname, title, kind, time, head, sub, milo, ada, ada_btn, extra='', pull=False):
    night = kind == 'night'
    T = dict(
      root='#12162B' if night else '#FFFFFF', ink='#F4ECDD' if night else '#0F2238', sky={'day':'#BDE2FF','night':'#0F1326','party':'#FFE3C2'}[kind],
      sub='#D5CEC0' if night else '#33455C', mcard='#1C2550' if night else '#EEF5FF', acard='#33261F' if night else '#FFF1E2',
      asub='#D5CEC0' if night else '#5A4636', btn='#1C2550' if night else '#FFFFFF', line='#F4ECDD' if night else '#0F2238',
      shadow='#E6C98F' if night else '#0F2238', more='#F3E0B8' if night else '#FFC531', moreink='#0F1326' if night else '#0F2238')
    bstyle = f"height: 58px; border: 2.500px solid {T['line']}; border-radius: 18px; box-shadow: 3px 3px 0 {T['shadow']}; background: {T['btn']}; color: {T['ink']}; font: inherit; font-size: 14px; font-weight: 700"
    buttons = ''.join(f'<button style="{bstyle}">{n}</button>\n' for n in ['Bottle', 'Sleep', 'Nappy', 'Potty'])
    buttons += f'<button style="{bstyle.replace("background: " + T["btn"], "background: " + T["more"]).replace("color: " + T["ink"], "color: " + T["moreink"])}; font-weight: 800">More</button>'
    wake = (f'<button style="height: 44px; padding: 0 16px; border: 2.500px solid {T["line"]}; border-radius: 22px; box-shadow: 3px 3px 0 {T["shadow"]}; background: {T["btn"]}; color: {T["ink"]}; font: inherit; font-size: 14px; font-weight: 700; flex-shrink: 0">{ada_btn}</button>') if ada_btn else ''
    strip = (f'<div style="height: 96px; flex-shrink: 0; background: {T["sky"]}; box-sizing: border-box; padding: 54px 20px 0 20px; display: flex; align-items: center; justify-content: center; gap: 10px; font-size: 15px; font-weight: 700">'
      '<svg aria-hidden="true" width="28" height="28" viewBox="0 0 28 28" style="animation: spin 1.600s linear infinite"><circle cx="14" cy="14" r="6" fill="#FFC531" stroke="#0F2238" stroke-width="2"></circle><circle cx="14" cy="14" r="11" fill="none" stroke="#0F2238" stroke-width="2.500" stroke-dasharray="1 7.600" stroke-linecap="round"></circle></svg>'
      'Catching up with the other phones</div>') if pull else ''
    top = 14 if pull else 66
    css = ('@keyframes spin{to{transform:rotate(360deg)}}@keyframes bob{50%{transform:translateY(-6px)}}@keyframes hop{0%,100%{transform:translateY(0)}40%{transform:translateY(-16px)}}\n@media (prefers-reduced-motion: reduce){*{animation:none !important}}\n') if pull else ''
    html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&display=swap">
<style>
body{{margin:0}}
a{{color:{T['ink']}}}a:hover{{color:{T['sub']}}}
{css}</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; overflow: hidden; background: {T['root']}; color: {T['ink']}; font-family: 'Bricolage Grotesque', system-ui, sans-serif; display: flex; flex-direction: column">
{strip}
<div style="position: relative; height: 396px; background: {T['sky']}; overflow: hidden; flex-shrink: 0">
{scene(kind, pull)}
<div style="position: absolute; left: 20px; top: {top}px; width: 236px; display: flex; flex-direction: column; gap: 8px">
<div style="font-size: 14px; font-weight: 700; letter-spacing: 0.03em">{time}</div>
<h1 style="margin: 0; font-size: 40px; font-weight: 800; line-height: 1.02; letter-spacing: -0.02em">{head}</h1>
<div style="font-size: 16px; font-weight: 500; line-height: 1.35">{sub}</div>
</div>
</div>

<div style="flex-grow: 1; min-height: 0; padding: 16px 16px 0 16px; display: flex; flex-direction: column; gap: 10px">

<div style="background: {T['mcard']}; border-radius: 24px; padding: 14px 16px; display: flex; align-items: center; gap: 14px">
<div style="width: 52px; height: 52px; border-radius: 26px; background: #8EC0FF; color: #0F2238; display: flex; align-items: center; justify-content: center; font-size: 22px; font-weight: 800; flex-shrink: 0">M</div>
<div style="display: flex; flex-direction: column; gap: 2px; flex-grow: 1; min-width: 0">
<div style="font-size: 18px; font-weight: 800">{milo[0]}</div>
<div style="font-size: 14px; font-weight: 500; color: {T['sub']}">{milo[1]}</div>
</div>
</div>

<div style="background: {T['acard']}; border-radius: 24px; padding: 14px 16px; display: flex; align-items: center; gap: 14px">
<div style="width: 52px; height: 52px; border-radius: 26px; background: #FFB170; color: #0F2238; display: flex; align-items: center; justify-content: center; font-size: 22px; font-weight: 800; flex-shrink: 0">A</div>
<div style="display: flex; flex-direction: column; gap: 2px; flex-grow: 1; min-width: 0">
<div style="font-size: 18px; font-weight: 800; font-variant-numeric: tabular-nums">{ada[0]}</div>
<div style="font-size: 14px; font-weight: 500; color: {T['asub']}">{ada[1]}</div>
</div>
{wake}
</div>
{extra}
</div>

<div style="padding: 12px 16px 34px 16px; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 8px">
{buttons}
</div>

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
    open(P + fname, 'w').write(html)

page('MixDay.dc.html', 'Mix, afternoon', 'day', 'Tuesday, 2:50 pm', 'One down, one to go.', 'Ada has been asleep for 42 minutes. Milo has other plans.',
     ('Milo, awake 1h 05m', "Bottle o'clock is about 3:45"), ('Ada, napping 0:42', 'Dry since 11:30. Three stickers so far'), 'Wake')
page('MixNight.dc.html', 'Mix, night', 'night', 'Wednesday, 2:10 am', 'Just the two of you.', 'Milo is up for a bottle. Ada has slept through since 7:30.',
     ('Milo, awake 12 min', 'Last bottle 10:40 pm, 180 ml'), ('Ada, asleep 6h 40m', 'Dry at bedtime'), '')
page('MixPull.dc.html', 'Mix, pull to refresh', 'day', 'Tuesday, 2:50 pm', 'One down, one to go.', 'Ada has been asleep for 42 minutes. Milo has other plans.',
     ('Milo, awake 1h 05m', "Bottle o'clock is about 3:45"), ('Ada, napping 0:42', 'Dry since 11:30. Three stickers so far'), 'Wake', pull=True)
extra = '''
<button style="height: 52px; border: 2.500px solid #0F2238; border-radius: 18px; box-shadow: 3px 3px 0 #0F2238; background: #FFC531; color: #0F2238; font: inherit; font-size: 15px; font-weight: 800">Add today's photo</button>'''
page('MixMilestone.dc.html', 'Mix, milestone day', 'party', 'Saturday, 9:10 am', 'Half a year of Milo.', 'Six months old today. Ada is taking the credit.',
     ('Milo, awake 40 min', 'Bottle at 8:30, 180 ml'), ('Ada, awake since 6:50', 'One sticker already'), '', extra=extra)

c = json.load(open(P + 'canvas.json'))
names = [('MixDay.dc.html', 'Mix: afternoon'), ('MixNight.dc.html', 'Mix: night'), ('MixPull.dc.html', 'Mix: pull to refresh'), ('MixMilestone.dc.html', 'Mix: milestone day')]
for i, (f, t) in enumerate(names):
    c['boards'][f] = {'x': i * 470, 'y': 2600, 'w': 390, 'h': 844, 'title': t, 'radius': 44}
    if f not in c['order']: c['order'].append(f)
c['notes']['row3'] = {'x': 0, 'y': 2300, 'text': 'A + C mix, with B controls', 'kind': 'title1', 'maxW': 1800}
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
