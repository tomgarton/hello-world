import sys, json
ROOT = sys.argv[1]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
O = '#3A2A20'; L = f'stroke="{O}" stroke-width="4" stroke-linejoin="round"'
def goo(fid, blur): return f'<filter id="{fid}" x="-10%" y="-40%" width="120%" height="180%"><feGaussianBlur stdDeviation="{blur}"></feGaussianBlur><feColorMatrix values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 22 -10"></feColorMatrix></filter>'
def sign_text(x, y, word, size, col, fid, anchor='middle'):
    return f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="{size}" letter-spacing="-2" fill="{col}" stroke="{col}" stroke-width="2.200" stroke-linejoin="round" filter="url(#{fid})">{word}</text>'
def shop(x, w_, h_, wall, sign_bg, word, word_col, awning, fid):
    s = f'<rect x="{x}" y="{300-h_}" width="{w_}" height="{h_}" fill="{wall}" {L}></rect>'
    s += f'<rect x="{x+10}" y="{300-h_+12}" width="{w_-20}" height="34" rx="6" fill="{sign_bg}" {L}></rect>'
    s += sign_text(x + w_/2, 300-h_+38, word, 24, word_col, fid)
    s += ''.join(f'<path d="M{x+i*w_/6:.1f} {300-h_+56}h{w_/6:.1f}v12a{w_/12:.1f} {w_/12:.1f} 0 0 1 -{w_/6:.1f} 0z" fill="{awning if i % 2 == 0 else "#FBF6E9"}" {L}></path>' for i in range(6))
    s += f'<rect x="{x+14}" y="{300-h_+82}" width="{w_*0.5:.0f}" height="{h_-96}" rx="4" fill="#BFD9F5" {L}></rect><rect x="{x+w_*0.62:.0f}" y="{300-h_+82}" width="{w_*0.3:.0f}" height="{h_-82}" rx="4" fill="#8A5A3C" {L}></rect>'
    return s
street = ('<rect x="0" y="0" width="980" height="300" fill="#BFD9F5"></rect><rect x="0" y="300" width="980" height="40" fill="#C9B89F"></rect>' +
          shop(10, 200, 200, '#F3D9C9', '#E5553B', 'Milk Bar', '#F08A6E', '#E5553B', 'g1') + shop(220, 180, 170, '#F4E7B0', '#3C9A5F', 'Bakery', '#5FB27F', '#3C9A5F', 'g1') +
          shop(410, 190, 210, '#CFE5D2', '#FBF6E9', 'Chemist', '#D9D0BE', '#2A62B8', 'g1') + shop(610, 170, 180, '#FBF6E9', '#F4BE2C', 'Surf Shop', '#F8D777', '#2A62B8', 'g1') + shop(790, 180, 200, '#F3D9C9', '#2A62B8', 'Café', '#5A86CC', '#F4BE2C', 'g1'))
street_svg = f'<svg role="img" aria-label="A street of shops with blended, blob-like signs" width="984" height="340" viewBox="0 0 980 340"><defs>{goo("g1", 1.8)}</defs>{street}</svg>'
ladder = []
for i, (lab, blur, col) in enumerate([('Crisp: reads as text', 0, '#FBF6E9'), ('Soft: still readable', 0.9, '#FBF6E9'), ('Blob, close colour: the world, not a message', 1.9, '#F08A6E'), ('Pills only: pure shape', None, '#F08A6E')]):
    fid = f'l{i}'
    t = (f'<rect x="10" y="10" width="200" height="56" rx="10" fill="#E5553B" {L}></rect>' +
         (sign_text(110, 50, 'Milk Bar', 30, col, fid) if blur not in (None, 0) else (f'<text x="110" y="50" text-anchor="middle" font-family="Bricolage Grotesque, sans-serif" font-weight="800" font-size="30" letter-spacing="-1" fill="{col}">Milk Bar</text>' if blur == 0 else
          ''.join(f'<rect x="{x}" y="28" width="{wd}" height="20" rx="10" fill="{col}"></rect>' for x, wd in ((34, 56), (98, 22), (126, 60))))))
    ladder.append(f'<div style="display: flex; flex-direction: column; gap: 6px"><svg role="img" aria-label="{lab}" width="220" height="76" viewBox="0 0 220 76"><defs>{goo(fid, blur) if blur else ""}</defs>{t}</svg><div style="font-size: 13px; font-weight: 700">{lab}</div></div>')
body = f'''<div style="width: 1080px; height: 640px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; flex-direction: column; gap: 4px"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Text in the world</h1><div style="font-size: 14px; font-weight: 500; color: #4A3B30">Signs are real words, blurred and merged into blobs in a colour close to the sign, so they read as part of the scene. Only words the story needs are crisp.</div></div>
{street_svg}
<div style="display: flex; gap: 26px">{"".join(ladder)}</div>
</div>'''
wrap('Text in the world', body, 1080, 640, 'Signs.dc.html', 30300)
