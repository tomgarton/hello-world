import math, sys, json
P = sys.argv[1] + '/project/'
INK = '#141414'
def base(jumper, fur):
    feet = ''.join(f'<ellipse cx="{x}" cy="263" rx="21" ry="10" fill="{fur}" stroke="{INK}" stroke-width="6"></ellipse>' for x in (97, 143))
    arms = ''.join(f'<ellipse cx="{x}" cy="212" rx="14" ry="23" fill="{jumper}" stroke="{INK}" stroke-width="6"></ellipse>' for x in (70, 170))
    return feet + arms + f'<ellipse cx="120" cy="216" rx="47" ry="45" fill="{jumper}" stroke="{INK}" stroke-width="7"></ellipse>'
def eyes(y, dx=33):
    return f'<circle cx="{120-dx}" cy="{y}" r="6.500" fill="{INK}"></circle><circle cx="{120+dx}" cy="{y}" r="6.500" fill="{INK}"></circle>'
def blush(y=128, dx=50):
    return f'<circle cx="{120-dx}" cy="{y}" r="10" fill="#E88F7A"></circle><circle cx="{120+dx}" cy="{y}" r="10" fill="#E88F7A"></circle>'
def wrap(inner, size, label):
    return f'<svg role="img" aria-label="{label}" width="{size}" height="{size*280/240:.0f}" viewBox="0 0 240 280">{inner}</svg>'

def echidna(size, jumper='#2A62B8'):
    fur = '#9B6B43'; sp = ''
    for i in range(8):
        a = math.radians(198 + i * 20.6)
        pt = lambda r, da=0: f'{120 + r * math.cos(a + da):.1f} {110 + r * 0.92 * math.sin(a + da):.1f}'
        sp += f'<path d="M{pt(58, -0.26)}L{pt(104)}L{pt(58, 0.26)}z" fill="#F3E3C3" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path>'
    return wrap(sp + base(jumper, fur) + f'<ellipse cx="120" cy="110" rx="72" ry="62" fill="{fur}" stroke="{INK}" stroke-width="7"></ellipse>' + blush() +
        f'<path d="M106 110Q120 98 134 110L128 170Q120 180 112 170z" fill="#CFA277" stroke="{INK}" stroke-width="6" stroke-linejoin="round"></path><ellipse cx="120" cy="171" rx="7" ry="5" fill="{INK}"></ellipse>' + eyes(104), size, 'Echidna puggle in a blue jumper')
def platypus(size, jumper='#E5553B'):
    fur = '#7A5638'
    return wrap(base(jumper, fur) + f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{fur}" stroke="{INK}" stroke-width="7"></ellipse>' + blush(116, 54) +
        f'<rect x="66" y="118" width="108" height="42" rx="21" fill="#55616C" stroke="{INK}" stroke-width="6"></rect><circle cx="108" cy="132" r="3" fill="{INK}"></circle><circle cx="132" cy="132" r="3" fill="{INK}"></circle>' + eyes(94, 30), size, 'Platypus puggle in a red jumper')
def wombat(size, jumper='#3C9A5F'):
    fur = '#8C7B6E'
    ears = ''.join(f'<ellipse cx="{x}" cy="56" rx="15" ry="13" fill="{fur}" stroke="{INK}" stroke-width="6"></ellipse>' for x in (70, 170))
    return wrap(ears + base(jumper, fur) + f'<rect x="44" y="50" width="152" height="124" rx="52" fill="{fur}" stroke="{INK}" stroke-width="7"></rect>' + blush(134, 52) +
        f'<ellipse cx="120" cy="130" rx="23" ry="15" fill="#2E2622" stroke="{INK}" stroke-width="4"></ellipse>' + eyes(104, 36), size, 'Wombat joey in a green jumper')
def koala(size, jumper='#F4BE2C'):
    fur = '#A9B0B8'
    ears = ''.join(f'<circle cx="{x}" cy="72" r="34" fill="{fur}" stroke="{INK}" stroke-width="7"></circle><circle cx="{x}" cy="72" r="17" fill="#F0DAD6"></circle>' for x in (54, 186))
    return wrap(ears + base(jumper, fur) + f'<ellipse cx="120" cy="112" rx="68" ry="62" fill="{fur}" stroke="{INK}" stroke-width="7"></ellipse>' + blush(134, 46) +
        f'<ellipse cx="120" cy="122" rx="14" ry="21" fill="{INK}"></ellipse>' + eyes(102, 34), size, 'Koala joey in a yellow jumper')
def quokka(size, jumper='#F3E3C3'):
    fur = '#C2925F'
    ears = ''.join(f'<circle cx="{x}" cy="58" r="19" fill="{fur}" stroke="{INK}" stroke-width="6"></circle>' for x in (72, 168))
    return wrap(ears + base(jumper, fur) + f'<ellipse cx="120" cy="110" rx="68" ry="62" fill="{fur}" stroke="{INK}" stroke-width="7"></ellipse>' + blush(124, 50) +
        f'<ellipse cx="120" cy="116" rx="9" ry="6.500" fill="{INK}"></ellipse><path d="M98 132Q120 154 142 132" fill="none" stroke="{INK}" stroke-width="6" stroke-linecap="round"></path>' + eyes(98, 32), size, 'Quokka joey in a cream jumper')

cast = [('#F4BE2C', echidna, 'Puggle', 'Echidna. The lead'), ('#BFD9F5', platypus, 'The other puggle', 'Platypus. Bath time'), ('#F3D9C9', wombat, 'Wombat', 'Sleep, and potty'),
        ('#CFE5D2', koala, 'Koala', 'Naps and cuddles'), ('#2A62B8', quokka, 'Quokka', 'Milestones')]
if len(sys.argv) > 2:
    NS = '<svg xmlns="http://www.w3.org/2000/svg" '
    cells = ''.join('<div style="background:' + bg + ';padding:10px">' + fn(190).replace('<svg ', NS) + '</div>' for bg, fn, n, r in cast)
    open(sys.argv[1] + '/gen/friends.html', 'w').write('<body style="margin:0;display:flex">' + cells + '</body>')
    sys.exit()
panels = ''.join(f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: 180px; height: 200px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 10px; box-sizing: border-box">{fn(150)}</div>'
                 f'<div style="font-size: 17px; font-weight: 800">{n}</div><div style="font-size: 14px; font-weight: 500; color: #3D3D3D">{r}</div></div>' for bg, fn, n, r in cast)
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Puggle and friends</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&display=swap">
<style>
body{{margin:0}}
a{{color:#141414}}a:hover{{color:#444444}}
</style>
</helmet>
<div style="width: 1080px; height: 440px; box-sizing: border-box; background: #FBF6E9; color: #141414; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 48px; display: flex; flex-direction: column; gap: 30px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Puggle and friends</h1>
<div style="display: flex; gap: 21px">
{panels}
</div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":440}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'Friends.dc.html', 'w').write(html)
c = json.load(open(P + 'canvas.json'))
c['boards']['Friends.dc.html'] = {'x': 0, 'y': 5660, 'w': 1080, 'h': 440, 'title': 'Puggle and friends'}
if 'Friends.dc.html' not in c['order']: c['order'].append('Friends.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'))
