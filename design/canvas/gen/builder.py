import math, sys, json, re
P = sys.argv[1] + '/project/'
L = '{{c.line}}'
def T(n): return '{{c.' + n + '}}'
def eyes(y, dx, shut=False):
    return ''.join(f'<circle cx="{x}" cy="{y}" r="6.500" fill="{L}"></circle>' for x in (120-dx, 120+dx))
def cheeks(y, dx):
    s = ''
    for x in (120 - dx, 120 + dx):
        s += (f'<circle cx="{x}" cy="{y}" r="10" fill="{T("blush")}" display="{{{{c.blushShow}}}}"></circle>'
              f'<path d="M{x-7} {y+5}l5-9M{x+2} {y+5}l5-9" fill="none" stroke="{T("stitch")}" stroke-width="3.500" stroke-linecap="round"></path>')
    return s
def platypus():
    return (f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{T("fur")}" stroke="{L}" stroke-width="7"></ellipse>' + cheeks(127, 53) +
        f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{T("ext")}" stroke="{L}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{L}"></circle><circle cx="126" cy="143" r="1.8" fill="{L}"></circle>' + eyes(108, 27).replace('r="6.500"', 'r="7.600"'))
def echidna():
    sp = ''
    for i in range(8):
        a = math.radians(198 + i * 20.6)
        pt = lambda r, da=0: f'{120 + r * math.cos(a + da):.1f} {110 + r * 0.92 * math.sin(a + da):.1f}'
        sp += f'<path d="M{pt(58, -0.26)}L{pt(104)}L{pt(58, 0.26)}z" fill="{T("spine")}" stroke="{L}" stroke-width="5" stroke-linejoin="round"></path>'
    return (sp + f'<ellipse cx="120" cy="110" rx="72" ry="62" fill="{T("fur")}" stroke="{L}" stroke-width="7"></ellipse>' + cheeks(128, 54) +
        f'<path d="M106 110Q120 98 134 110L128 168Q120 178 112 168z" fill="{T("ext")}" stroke="{L}" stroke-width="6" stroke-linejoin="round"></path><ellipse cx="120" cy="169" rx="7" ry="5" fill="{L}"></ellipse>' + eyes(104, 33))
def koala():
    ears = ''.join(f'<circle cx="{x}" cy="72" r="34" fill="{T("fur")}" stroke="{L}" stroke-width="7"></circle><circle cx="{x}" cy="72" r="17" fill="{T("inner")}"></circle>' for x in (54, 186))
    return ears + f'<ellipse cx="120" cy="112" rx="68" ry="62" fill="{T("fur")}" stroke="{L}" stroke-width="7"></ellipse>' + cheeks(134, 46) + f'<ellipse cx="120" cy="122" rx="14" ry="20" fill="{L}"></ellipse>' + eyes(102, 34)
def wombat():
    ears = ''.join(f'<ellipse cx="{x}" cy="56" rx="15" ry="13" fill="{T("fur")}" stroke="{L}" stroke-width="6"></ellipse>' for x in (70, 170))
    return ears + f'<rect x="44" y="50" width="152" height="124" rx="52" fill="{T("fur")}" stroke="{L}" stroke-width="7"></rect>' + cheeks(134, 52) + f'<ellipse cx="120" cy="130" rx="23" ry="15" fill="{L}"></ellipse>' + eyes(104, 36)
def trap(col, hem=254, flare=28):
    return f'<path d="M88 166Q120 156 152 166L{152+flare} {hem-10}Q{154+flare} {hem} {142+flare} {hem}L{98-flare} {hem}Q{86-flare} {hem} {88-flare} {hem-10}Z" fill="{col}" stroke="{L}" stroke-width="7" stroke-linejoin="round"></path>'
def pocket(y):
    return f'<path d="M100 {y}h40v9a20 16 0 0 1-40 0z" fill="none" stroke="{L}" stroke-width="5" stroke-linejoin="round"></path>'
def arms(col, a=42):
    s = ''
    for side, ang in ((-1, a), (1, -a)):
        sx = 92 if side < 0 else 148
        s += (f'<g transform="rotate({ang} {sx} 176)"><rect x="{sx-12}" y="170" width="24" height="50" rx="12" fill="{col}" stroke="{L}" stroke-width="6"></rect>'
              f'<circle cx="{sx}" cy="224" r="11.500" fill="{T("fur")}" stroke="{L}" stroke-width="5"></circle></g>')
    return s
legs = ''.join(f'<rect x="{x}" y="244" width="28" height="34" rx="11" fill="{T("fur")}" stroke="{L}" stroke-width="6"></rect>' for x in (86, 126))
feet = ''.join(f'<ellipse cx="{x}" cy="282" rx="24" ry="10" fill="{T("ext")}" stroke="{L}" stroke-width="6"></ellipse>' for x in (100, 140))
G, G2 = T('garment'), T('paper')
outfits = {
 'jumper': legs + feet + trap(G) + pocket(210) + arms(G),
 'dungarees': feet + trap(G2, 232, 16) + f'<path d="M72 208H168L174 270H127L120 250L113 270H66Z" fill="{G}" stroke="{L}" stroke-width="7" stroke-linejoin="round"></path><rect x="97" y="180" width="46" height="34" rx="6" fill="{G}" stroke="{L}" stroke-width="6"></rect><path d="M100 182L93 164M140 182L147 164" stroke="{L}" stroke-width="6" stroke-linecap="round"></path><path d="M100 190h40v5a20 12 0 0 1-40 0z" fill="none" stroke="{L}" stroke-width="5" stroke-linejoin="round"></path>' + arms(G2),
 'dress': legs + feet + trap(G, 254, 42) + f'<path d="M100 164a12 10 0 0 0 20 4a12 10 0 0 0 20-4" fill="{G2}" stroke="{L}" stroke-width="5" stroke-linejoin="round"></path>' + pocket(214) + arms(G),
 'tee': f'<rect x="86" y="250" width="28" height="28" rx="11" fill="{T("fur")}" stroke="{L}" stroke-width="6"></rect><rect x="126" y="250" width="28" height="28" rx="11" fill="{T("fur")}" stroke="{L}" stroke-width="6"></rect>' + feet + f'<path d="M74 220H166L170 258H127L120 244L113 258H70Z" fill="{G}" stroke="{L}" stroke-width="7" stroke-linejoin="round"></path>' + trap(G2, 228, 16) + ''.join(f'<path d="M{80-i*3} {186+i*14}H{160+i*3}" stroke="{G}" stroke-width="6"></path>' for i in range(3)) + arms(G2),
}
tail = f'<ellipse cx="184" cy="246" rx="34" ry="15" transform="rotate(-28 184 246)" fill="{T("fur")}" stroke="{L}" stroke-width="6"></ellipse>'
heads = {'platypus': platypus(), 'echidna': echidna(), 'koala': koala(), 'wombat': wombat()}
svg = ('<svg role="img" aria-label="{{label}}" width="300" height="375" viewBox="0 0 240 300">'
  f'<g display="{{{{d.platypus}}}}">{tail}</g>' + ''.join(f'<g display="{{{{o.{k}}}}}">{v}</g>' for k, v in outfits.items()) +
  ''.join(f'<g display="{{{{d.{k}}}}}">{v}</g>' for k, v in heads.items()) + '</svg>')

def btn_row(lst, h=44):
    return (f'<div style="display: flex; flex-wrap: wrap; gap: 8px"><sc-for list="{{{{{lst}}}}}" as="b" hint-placeholder-count="4">'
            f'<button onClick="{{{{b.pick}}}}" aria-pressed="{{{{b.on}}}}" style="height: {h}px; padding: 0 16px; border: 2.500px solid #3A2A20; border-radius: 14px; background: {{{{b.bg}}}}; color: {{{{b.fg}}}}; font: inherit; font-size: 15px; font-weight: 700">{{{{b.label}}}}</button></sc-for></div>')
def swatch_row(lst):
    return (f'<div style="display: flex; gap: 10px"><sc-for list="{{{{{lst}}}}}" as="s" hint-placeholder-count="5">'
            f'<button onClick="{{{{s.pick}}}}" aria-label="{{{{s.label}}}}" aria-pressed="{{{{s.on}}}}" style="width: 44px; height: 44px; border-radius: 22px; border: {{{{s.border}}}}; background: {{{{s.color}}}}; box-sizing: border-box"></button></sc-for></div>')
def group(title, inner):
    return f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">{title}</div>{inner}</div>'
html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Character builder</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wdth,wght@12..96,75..100,200..800&display=swap">
<style>
body{{margin:0}}
a{{color:#2A1F18}}a:hover{{color:#5A4636}}
</style>
</helmet>
<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; gap: 48px">
<div style="width: 400px; height: 560px; flex-shrink: 0; background: {{{{stage}}}}; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px 0; box-sizing: border-box">
{svg}
</div>
<div style="display: flex; flex-direction: column; gap: 22px; flex-grow: 1">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Make your puggle</h1>
{group("Friend", btn_row("animals"))}
{group("Outfit", btn_row("outfits"))}
{group("Colour", swatch_row("garments"))}
{group("Background", swatch_row("stages"))}
{group("Style", btn_row("styles"))}
<div style="font-size: 14px; font-weight: 500; color: #4A3B30; line-height: 1.4; max-width: 460px">Mono uses one ink on paper: for embroidery, single-colour print, stamps, widgets and the Lock Screen.</div>
</div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":1080,"height":640}}}}'>
class Component extends DCLogic {{
constructor(props) {{
super(props);
this.state = {{ animal: 'platypus', outfit: 'jumper', garment: '#2A62B8', stage: '#F4BE2C', style: 'colour' }};
}}
renderVals() {{
const s = this.state;
const INK = '#3A2A20';
const mono = s.style !== 'colour';
const dark = s.style === 'dark';
const furs = {{ platypus: ['#8A5A3C', '#6E7F8D'], echidna: ['#9B6B43', '#CFA277'], koala: ['#A9B0B8', '#A9B0B8'], wombat: ['#8C7B6E', '#8C7B6E'] }};
const paper = dark ? '#1B2440' : '#FBF6E9';
const line = dark ? '#F3E0B8' : INK;
const c = mono ? {{ fur: paper, ext: paper, garment: paper, paper: paper, spine: paper, inner: paper, blush: paper, blushShow: 'none', stitch: line, line: line }}
  : {{ fur: furs[s.animal][0], ext: furs[s.animal][1], garment: s.garment, paper: '#FBF6E9', spine: '#F3E3C3', inner: '#F0DAD6', blush: '#EE9C88', blushShow: 'inline', stitch: '#C24A36', line: INK }};
const show = (k, v) => (k === v ? 'inline' : 'none');
const d = {{ platypus: show('platypus', s.animal), echidna: show('echidna', s.animal), koala: show('koala', s.animal), wombat: show('wombat', s.animal) }};
const o = {{ jumper: show('jumper', s.outfit), dungarees: show('dungarees', s.outfit), dress: show('dress', s.outfit), tee: show('tee', s.outfit) }};
const pill = (key, val, label) => ({{ label: label, on: s[key] === val, bg: s[key] === val ? INK : '#FBF6E9', fg: s[key] === val ? '#FBF6E9' : INK, pick: () => this.setState({{ [key]: val }}) }});
const sw = (key, val, label) => ({{ label: label, color: val, on: s[key] === val, border: s[key] === val ? '4px solid ' + INK : '2px solid #C9B89F', pick: () => this.setState({{ [key]: val }}) }});
return {{
c: c, d: d, o: o,
stage: mono ? paper : s.stage,
label: 'Puggle character: ' + s.animal + ' in ' + s.outfit + (mono ? ', mono' : ''),
animals: [pill('animal', 'platypus', 'Platypus'), pill('animal', 'echidna', 'Echidna'), pill('animal', 'koala', 'Koala'), pill('animal', 'wombat', 'Wombat')],
outfits: [pill('outfit', 'jumper', 'Jumper'), pill('outfit', 'dungarees', 'Dungarees'), pill('outfit', 'dress', 'Dress'), pill('outfit', 'tee', 'Tee and shorts')],
garments: [sw('garment', '#2A62B8', 'Blue'), sw('garment', '#E5553B', 'Red'), sw('garment', '#3C9A5F', 'Green'), sw('garment', '#F4BE2C', 'Yellow'), sw('garment', '#BFD9F5', 'Sky')],
stages: [sw('stage', '#F4BE2C', 'Yellow'), sw('stage', '#F3D9C9', 'Pink'), sw('stage', '#CFE5D2', 'Mint'), sw('stage', '#BFD9F5', 'Sky'), sw('stage', '#1B2440', 'Night')],
styles: [pill('style', 'colour', 'Colour'), pill('style', 'mono', 'Mono'), pill('style', 'dark', 'Mono on night')]
}};
}}
}}
</script>
</body>
</html>
'''
open(P + 'Builder.dc.html', 'w').write(html)
# static preview of the svg in colour and mono
def fill(svgs, vals, disp):
    out = re.sub(r'\{\{c\.(\w+)\}\}', lambda m: vals[m.group(1)], svgs)
    out = re.sub(r'\{\{[do]\.(\w+)\}\}', lambda m: 'inline' if m.group(1) in disp else 'none', out)
    return out.replace('{{label}}', 'x').replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ')
col = dict(fur='#8A5A3C', ext='#6E7F8D', garment='#2A62B8', paper='#FBF6E9', spine='#F3E3C3', inner='#F0DAD6', blush='#EE9C88', blushShow='inline', stitch='#C24A36', line='#3A2A20')
mono = dict(fur='#FBF6E9', ext='#FBF6E9', garment='#FBF6E9', paper='#FBF6E9', spine='#FBF6E9', inner='#FBF6E9', blush='#FBF6E9', blushShow='none', stitch='#3A2A20', line='#3A2A20')
night = {k: ('#1B2440' if v == '#FBF6E9' else '#F3E0B8') for k, v in mono.items()}; night['blushShow'] = 'none'
open(sys.argv[1] + '/gen/builder.html', 'w').write('<body style="margin:0;display:flex">' +
  ''.join(f'<div style="background:{bg}">{fill(svg, v, ds)}</div>' for bg, v, ds in [('#F4BE2C', col, {'platypus', 'jumper'}), ('#FBF6E9', mono, {'platypus', 'dungarees'}), ('#1B2440', night, {'koala', 'dress'}), ('#CFE5D2', dict(col, fur='#8C7B6E', ext='#8C7B6E', garment='#E5553B'), {'wombat', 'tee'})]) + '</body>')
c = json.load(open(P + 'canvas.json'))
c['boards']['Builder.dc.html'] = {'x': 0, 'y': 10310, 'w': 1080, 'h': 640, 'title': 'Character builder', 'is_interactive': True}
if 'Builder.dc.html' not in c['order']: c['order'].append('Builder.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
print(html.count('<div') == html.count('</div>'), html.count('<g ') == html.count('</g>'))
