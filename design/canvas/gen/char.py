import json, sys
P = sys.argv[1] + '/project/'
INK = '#141414'
def puggle(size, body='#F4BE2C', asleep=False, hat=False, label='Puggle character'):
    spikes = ''.join(f'<path d="M{x-11} {y+14}L{x} {y-12}L{x+11} {y+14}z" fill="#6B4A2B" stroke="{INK}" stroke-width="7" stroke-linejoin="round"></path>'
                     for x, y in [(58, 78), (79, 60), (100, 54), (121, 60), (142, 78)])
    feet = ''.join(f'<ellipse cx="{x}" cy="206" rx="19" ry="10" fill="{body}" stroke="{INK}" stroke-width="7"></ellipse>' for x in (72, 128))
    eyes = (f'<path d="M66 116h18" stroke="{INK}" stroke-width="7" stroke-linecap="round"></path><path d="M116 116h18" stroke="{INK}" stroke-width="7" stroke-linecap="round"></path>'
            if asleep else f'<circle cx="75" cy="114" r="6" fill="{INK}"></circle><circle cx="125" cy="114" r="6" fill="{INK}"></circle>')
    h = (f'<path d="M80 50L100 6L120 50z" fill="#E5553B" stroke="{INK}" stroke-width="7" stroke-linejoin="round"></path>' if hat else '')
    return (f'<svg role="img" aria-label="{label}" width="{size}" height="{size*1.1:.0f}" viewBox="0 0 200 220">{spikes}{feet}'
            f'<ellipse cx="100" cy="130" rx="72" ry="78" fill="{body}" stroke="{INK}" stroke-width="8"></ellipse>{h}{eyes}'
            f'<ellipse cx="100" cy="146" rx="9" ry="15" fill="{INK}"></ellipse></svg>')

def panel(bg, inner, name, fg='#141414'):
    return (f'<div style="display: flex; flex-direction: column; gap: 10px">'
            f'<div style="width: 220px; height: 220px; background: {bg}; display: flex; align-items: flex-end; justify-content: center; gap: 4px; padding-bottom: 18px; box-sizing: border-box; position: relative">{inner}</div>'
            f'<div style="font-size: 15px; font-weight: 700">{name}</div></div>')

moon = '<svg aria-hidden="true" width="44" height="44" viewBox="0 0 44 44" style="position: absolute; right: 18px; top: 18px"><path d="M26 6a17 17 0 1 0 12 28A14 14 0 0 1 26 6z" fill="#F4BE2C" stroke="#141414" stroke-width="4" stroke-linejoin="round"></path></svg>'
panels = (panel('#2A62B8', puggle(150), 'Awake') +
          panel('#1B2440', moon + puggle(150, asleep=True, label='Puggle character asleep'), 'Asleep') +
          panel('#E5553B', puggle(150, hat=True, label='Puggle character in a party hat'), 'Milestone') +
          panel('#3C9A5F', puggle(100, label='Puggle character') + puggle(100, body='#FBF6E9', label='Second puggle character in cream'), 'Two together'))
sw = ''.join(f'<div style="width: 44px; height: 44px; background: {c}; border: 3px solid #141414; box-sizing: border-box"></div>' for c in ['#F4BE2C', '#2A62B8', '#E5553B', '#3C9A5F', '#FBF6E9', '#141414'])
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
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Character study: a puggle</h1>
<div style="display: flex; gap: 34px">
{panels}
</div>
<div style="display: flex; align-items: center; gap: 48px">
<div style="display: flex; align-items: center; gap: 14px">
<div style="width: 96px; height: 96px; border-radius: 22px; background: #2A62B8; display: flex; align-items: flex-end; justify-content: center; overflow: hidden">{puggle(84, label='App icon with the puggle character')}</div>
<div style="font-size: 15px; font-weight: 700">App icon</div>
</div>
<div style="display: flex; align-items: center; gap: 14px">
<div style="width: 48px; height: 48px; border-radius: 24px; background: #F4BE2C; border: 3px solid #141414; box-sizing: border-box; display: flex; align-items: center; justify-content: center; overflow: hidden">{puggle(34, body='#FBF6E9', label='Puggle at avatar size')}</div>
<div style="font-size: 15px; font-weight: 700">At avatar size</div>
</div>
<div style="display: flex; align-items: center; gap: 14px">
<div style="display: flex; gap: 6px">{sw}</div>
<div style="font-size: 15px; font-weight: 700">Six flat colours</div>
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
c = json.load(open(P + 'canvas.json'))
c['boards']['CharacterStudy.dc.html'] = {'x': 0, 'y': 4900, 'w': 1080, 'h': 640, 'title': 'Character study: a puggle'}
if 'CharacterStudy.dc.html' not in c['order']: c['order'].append('CharacterStudy.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
s = html; print(s.count('<div') == s.count('</div>'), s.count('<svg') == s.count('</svg>'))
