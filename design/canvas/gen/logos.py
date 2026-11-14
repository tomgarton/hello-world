import sys, math, re
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, PF, head, wrap = x['O'], x['PF'], x['head'], x['wrap']
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); shape = w['shape']
INK, PAPER = '#3A2A20', '#FBF6E9'
B = "font-family: 'Bricolage Grotesque', system-ui, sans-serif; font-weight: 800; letter-spacing: -0.04em; line-height: 1"
def face(sz, mono=None, bg=None):
    s = head('neutral')
    if mono:
        s = re.sub(r'fill="#[0-9A-Fa-f]{6}"', f'fill="{bg}"', s)
        s = re.sub(r'stroke="#[0-9A-Fa-f]{6}"', f'stroke="{mono}"', s)
        s = s.replace(f'<circle cx="93" cy="108" r="7.6" fill="{bg}"', f'<circle cx="93" cy="108" r="7.6" fill="{mono}"').replace(f'<circle cx="147" cy="108" r="7.6" fill="{bg}"', f'<circle cx="147" cy="108" r="7.6" fill="{mono}"')
        s = s.replace(f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{bg}"', f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{mono}"')
        s = s.replace(f'r="1.8" fill="{bg}"', f'r="1.8" fill="{bg}"')
        s = re.sub(r'<circle cx="(67|173)" cy="127" r="10" fill="[^"]+"></circle>', '', s)
    return f'<svg role="img" aria-label="Puggle face" width="{sz}" height="{sz*150/170:.0f}" viewBox="35 40 170 150">{s}</svg>'
def shp(kind, c, sz): return f'<svg aria-hidden="true" width="{sz}" height="{sz}" viewBox="0 0 100 100">{shape(kind, c)}</svg>'
def wm(px, c=INK): return f'<div style="{B}; font-size: {px}px; color: {c}">puggle</div>'
def card(bg, inner, title):
    return f'<div style="display: flex; flex-direction: column; gap: 8px"><div style="width: 300px; height: 170px; background: {bg}; display: flex; align-items: center; justify-content: center; position: relative">{inner}</div><div style="font-size: 14px; font-weight: 800">{title}</div></div>'
v = []
v.append(card(PAPER, f'<div style="display: flex; align-items: flex-end; gap: 4px">{wm(70)}<div style="padding-bottom: 6px">{shp("quatre", "#C24A36", 30)}</div></div>', 'A. Wordmark, quatrefoil full stop'))
v.append(card('#F4BE2C', f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px">{face(82)}{wm(44)}</div>', 'B. Stacked: face over wordmark'))
v.append(card('#1B2440', f'<div style="position: relative; width: 140px; height: 140px; display: flex; align-items: center; justify-content: center"><div style="position: absolute; inset: 0">{shp("blossom", "#BFD9F5", 140)}</div><div style="position: relative">{face(86)}</div></div>', 'C. Badge: face in the blossom'))
v.append(card(PAPER, f'<div style="height: 76px; padding: 0 30px; border-radius: 38px; background: #F4BE2C; border: 4px solid {INK}; display: flex; align-items: center; gap: 10px">{face(52)}{wm(50)}</div>', 'D. Pill: face and wordmark'))
v.append(card('#CFE5D2', f'<div style="position: relative; width: 230px; height: 120px"><svg aria-hidden="true" width="230" height="120" viewBox="0 0 230 120" style="position: absolute; inset: 0"><path d="M6 118V52a18 18 0 0 1 36 0a18 18 0 0 1 36 0a18 18 0 0 1 37 0a18 18 0 0 1 37 0a18 18 0 0 1 36 0a18 18 0 0 1 36 0V118Z" fill="#E5553B" stroke="{INK}" stroke-width="4"></path></svg><div style="position: absolute; left: 0; right: 0; bottom: 14px; display: flex; justify-content: center">{wm(54, PAPER)}</div></div>', 'E. Scallop: awning or shop sign'))
v.append(card('#F3D9C9', f'<div style="width: 120px; height: 120px; border-radius: 30px; background: #2A62B8; display: flex; align-items: center; justify-content: center; position: relative"><div style="{B}; font-size: 104px; color: {PAPER}; padding-bottom: 14px">p</div><div style="position: absolute; right: 8px; bottom: 10px">{shp("quatre", "#F4BE2C", 26)}</div></div>', 'F. Monogram: p with quatrefoil'))
v.append(card(PAPER, f'<div style="width: 150px; height: 150px; box-sizing: border-box; border-radius: 75px; border: 5px solid {INK}; display: flex; align-items: center; justify-content: center">{face(100, INK, PAPER)}</div>', 'G. Line face in a roundel: stamps, embroidery'))
v.append(card('#BFD9F5', f'<div style="width: 220px; height: 84px; background: {PAPER}; border: 2px dashed #C9B89F; outline: 6px solid {INK}; display: flex; align-items: center; justify-content: center; gap: 10px">{face(56, INK, PAPER)}{wm(40)}</div>', 'H. Woven label: line face and wordmark'))
v.append(card('#F4E7B0', f'<div style="width: 96px; height: 96px; background: {PAPER}; border: 2px dashed #C9B89F; outline: 6px solid {INK}; display: flex; align-items: center; justify-content: center">{face(70, INK, PAPER)}</div>', 'I. Woven tab: face only, for sleeves and socks'))
body = f'''<div style="width: 1080px; height: 780px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 20px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Logo variants with the soft shapes</h1>
<div style="display: grid; grid-template-columns: repeat(3, 300px); gap: 22px 42px">{"".join(v)}</div>
</div>'''
wrap('Logo variants', body, 1080, 780, 'Logos.dc.html', 24700)
