import math, sys
P = sys.argv[1] + '/project/'
INK = '#141414'; FUR = '#9B6B43'; SNOUT = '#CFA277'; SPINE = '#F3E3C3'
def puggle(size, jumper='#2A62B8', asleep=False, hat=False, label='Puggle character', head_only=False):
    cx, cy = 120, 110
    sp = ''
    for i in range(8):
        a = math.radians(198 + i * 20.6)
        def pt(r, da=0):
            return f'{cx + r * math.cos(a + da):.1f} {cy + r * 0.92 * math.sin(a + da):.1f}'
        sp += f'<path d="M{pt(58, -0.26)}L{pt(104)}L{pt(58, 0.26)}z" fill="{SPINE}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"></path>'
    feet = ''.join(f'<ellipse cx="{x}" cy="263" rx="21" ry="10" fill="{FUR}" stroke="{INK}" stroke-width="6"></ellipse>' for x in (97, 143))
    arms = ''.join(f'<ellipse cx="{x}" cy="212" rx="14" ry="23" fill="{jumper}" stroke="{INK}" stroke-width="6"></ellipse>' for x in (70, 170))
    body = f'<ellipse cx="120" cy="216" rx="47" ry="45" fill="{jumper}" stroke="{INK}" stroke-width="7"></ellipse>'
    head = f'<ellipse cx="{cx}" cy="{cy}" rx="72" ry="62" fill="{FUR}" stroke="{INK}" stroke-width="7"></ellipse>'
    blush = '<circle cx="70" cy="128" r="10" fill="#E88F7A"></circle><circle cx="170" cy="128" r="10" fill="#E88F7A"></circle>'
    snout = (f'<path d="M106 110Q120 98 134 110L128 170Q120 180 112 170z" fill="{SNOUT}" stroke="{INK}" stroke-width="6" stroke-linejoin="round"></path>'
             f'<ellipse cx="120" cy="171" rx="7" ry="5" fill="{INK}"></ellipse>')
    eyes = (f'<path d="M78 106h18" stroke="{INK}" stroke-width="7" stroke-linecap="round"></path><path d="M144 106h18" stroke="{INK}" stroke-width="7" stroke-linecap="round"></path>'
            if asleep else f'<circle cx="87" cy="104" r="6.500" fill="{INK}"></circle><circle cx="153" cy="104" r="6.500" fill="{INK}"></circle>')
    h = f'<path d="M100 54L120 2L140 54z" fill="#E5553B" stroke="{INK}" stroke-width="6" stroke-linejoin="round"></path>' if hat else ''
    vb, hh = ('18 0 204 190', size * 190 / 204) if head_only else ('0 0 240 280', size * 280 / 240)
    return (f'<svg role="img" aria-label="{label}" width="{size}" height="{hh:.0f}" viewBox="{vb}">{sp}{feet}{arms}{body}{head}{h}{blush}{snout}{eyes}</svg>')

def panel(bg, inner, name):
    return (f'<div style="display: flex; flex-direction: column; gap: 10px">'
            f'<div style="width: 220px; height: 220px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; gap: 2px; padding-bottom: 14px; box-sizing: border-box; position: relative">{inner}</div>'
            f'<div style="font-size: 15px; font-weight: 700">{name}</div></div>')

moon = '<svg aria-hidden="true" width="40" height="40" viewBox="0 0 44 44" style="position: absolute; right: 14px; top: 14px"><path d="M26 6a17 17 0 1 0 12 28A14 14 0 0 1 26 6z" fill="#F4BE2C" stroke="#141414" stroke-width="4" stroke-linejoin="round"></path></svg>'
panels = (panel('#F4BE2C', puggle(160), 'Awake') +
          panel('#1B2440', moon + puggle(160, jumper='#FBF6E9', asleep=True, label='Puggle character asleep in cream pyjamas'), 'Asleep') +
          panel('#3C9A5F', puggle(160, jumper='#F4BE2C', hat=True, label='Puggle character in a party hat'), 'Milestone') +
          panel('#BFD9F5', puggle(104, jumper='#3C9A5F', label='Parent puggle in a green jumper') + puggle(74, jumper='#E5553B', label='Child puggle in a red jumper') + puggle(56, jumper='#2A62B8', label='Baby puggle in a blue jumper'), 'A family: jumper colour per child'))
sw = ''.join(f'<div style="width: 40px; height: 40px; background: {c}; border: 3px solid #141414; box-sizing: border-box"></div>' for c in [FUR, SPINE, '#F4BE2C', '#2A62B8', '#E5553B', '#3C9A5F', '#141414'])
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Character study, a puggle</title>
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
<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #FBF6E9; color: #141414; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 48px; display: flex; flex-direction: column; gap: 36px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Character study: a puggle, second pass</h1>
<div style="display: flex; gap: 34px">
{panels}
</div>
<div style="display: flex; align-items: center; gap: 44px">
<div style="display: flex; align-items: center; gap: 14px">
<div style="width: 96px; height: 96px; border-radius: 22px; background: #F4BE2C; display: flex; align-items: center; justify-content: center; overflow: hidden">{puggle(86, head_only=True, label='App icon with the puggle face')}</div>
<div style="font-size: 15px; font-weight: 700">App icon</div>
</div>
<div style="display: flex; align-items: center; gap: 14px">
<div style="width: 48px; height: 48px; border-radius: 24px; background: #BFD9F5; border: 3px solid #141414; box-sizing: border-box; display: flex; align-items: center; justify-content: center; overflow: hidden">{puggle(40, head_only=True, label='Puggle face at avatar size')}</div>
<div style="font-size: 15px; font-weight: 700">At avatar size</div>
</div>
<div style="display: flex; align-items: center; gap: 14px">
<div style="display: flex; gap: 6px">{sw}</div>
<div style="font-size: 15px; font-weight: 700">Palette</div>
</div>
</div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":640}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'CharacterStudy.dc.html', 'w').write(html)
open(sys.argv[1] + '/gen/puggle.svg', 'w').write(puggle(480).replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" '))
print(html.count('<div') == html.count('</div>'), html.count('<svg') == html.count('</svg>'))
