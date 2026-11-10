import sys, json
ROOT = sys.argv[1]; P = ROOT + '/project/'
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
O = '#3A2A20'; PAPER = '#FBF6E9'
L = f'stroke="{O}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"'
HI = 'stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.85"'
YEL, RED, BLUE, GREEN, SKY, SHELL, SAND, BROWN, SLATE, CREAM = '#F4BE2C', '#E5553B', '#2A62B8', '#3C9A5F', '#BFD9F5', '#F3D9C9', '#E8D3A8', '#B9845A', '#6E7F8D', '#FBF6E9'
def g(*parts): return ''.join(parts)
# everyday
bottle = g(f'<path d="M42 10h16v8H42z" fill="{YEL}" {L}></path>', f'<path d="M40 18h20v8H40z" fill="{BLUE}" {L}></path>',
           f'<rect x="32" y="26" width="36" height="64" rx="12" fill="{CREAM}" {L}></rect>', f'<path d="M34 56h32v20a12 12 0 0 1-12 12H46a12 12 0 0 1-12-12z" fill="#FFF0C8"></path>',
           f'<rect x="32" y="26" width="36" height="64" rx="12" fill="none" {L}></rect>', ''.join(f'<path d="M58 {y}h8" {L}></path>' for y in (40, 52, 64)), f'<path d="M40 34v14" {HI}></path>')
nappy = g(f'<path d="M12 28H88V38Q84 72 62 82Q50 88 38 82Q16 72 12 38Z" fill="{CREAM}" {L}></path>', f'<path d="M12 28H88V40H12z" fill="{SKY}" {L}></path>',
          f'<rect x="16" y="32" width="14" height="10" rx="3" fill="{YEL}" {L}></rect><rect x="70" y="32" width="14" height="10" rx="3" fill="{YEL}" {L}></rect>', f'<path d="M40 56q10 6 20 0" fill="none" {L}></path>')
potty = g(f'<path d="M20 44H80L72 84Q70 90 62 90H38Q30 90 28 84Z" fill="{CREAM}" {L}></path>', f'<rect x="12" y="34" width="76" height="14" rx="7" fill="{SKY}" {L}></rect>',
          f'<path d="M82 50q14 4 8 20" fill="none" {L}></path>', f'<path d="M32 56l4 22" {HI}></path>')
bowl = g(f'<path d="M60 40L86 12" stroke="{O}" stroke-width="10" stroke-linecap="round"></path><path d="M60 40L86 12" stroke="{SKY}" stroke-width="4" stroke-linecap="round"></path>',
         f'<path d="M10 46H90Q88 84 50 84Q12 84 10 46Z" fill="{YEL}" {L}></path>', f'<ellipse cx="50" cy="46" rx="40" ry="8" fill="#F3B48A" {L}></ellipse>', f'<path d="M22 58q4 12 14 16" {HI}></path>')
cup = g(f'<rect x="26" y="30" width="44" height="56" rx="12" fill="{SKY}" {L}></rect>', f'<path d="M26 32H70V24Q70 18 64 18H32Q26 18 26 24Z" fill="{RED}" {L}></path>',
        f'<path d="M70 44q16 2 14 14q-2 12 -14 12" fill="none" {L}></path><path d="M44 18V6" {L}></path>', f'<path d="M34 40v26" {HI}></path>')
brush = g(f'<rect x="10" y="44" width="62" height="14" rx="7" fill="{GREEN}" {L}></rect>', f'<rect x="66" y="34" width="24" height="16" rx="5" fill="{CREAM}" {L}></rect>',
          ''.join(f'<path d="M{x} 34v-10" {L}></path>' for x in (71, 78, 85)), f'<path d="M18 49h40" {HI}></path>')
book = g(f'<path d="M50 28Q34 18 10 20V80Q34 78 50 88Q66 78 90 80V20Q66 18 50 28Z" fill="{RED}" {L}></path>', f'<path d="M50 28V88" {L}></path>',
         f'<path d="M18 34Q32 32 42 36M18 46Q32 44 42 48M58 36Q68 32 82 34" fill="none" stroke="{CREAM}" stroke-width="4" stroke-linecap="round"></path>')
blanket = g(f'<path d="M12 26Q50 14 88 26L84 80Q50 92 16 80Z" fill="{SHELL}" {L}></path>', f'<path d="M14 66Q50 78 86 66L84 80Q50 92 16 80Z" fill="{SKY}" {L}></path>',
            ''.join(f'<circle cx="{cx}" cy="{cy}" r="4" fill="{RED}"></circle>' for cx, cy in ((30, 40), (52, 34), (72, 42), (40, 56), (64, 56))))
duck = g(f'<path d="M14 62Q14 82 46 84Q82 84 86 62Q74 66 64 60Q52 70 30 64Z" fill="{YEL}" {L}></path>', f'<circle cx="62" cy="40" r="16" fill="{YEL}" {L}></circle>',
         f'<path d="M76 40L92 44L76 50Z" fill="{RED}" {L}></path><circle cx="66" cy="36" r="3" fill="{O}"></circle>', f'<path d="M24 70q10 6 22 6" {HI}></path>')
balloon = g(f'<path d="M50 72Q58 86 50 98" fill="none" {L}></path>', f'<ellipse cx="50" cy="38" rx="28" ry="33" fill="{RED}" {L}></ellipse>', f'<path d="M44 72h12l-6 -6z" fill="{RED}" {L}></path>', f'<path d="M36 22q4 -8 12 -10" {HI}></path>')
# Australian
thongs = g(''.join(f'<g transform="translate({dx} {dy}) rotate({r} 25 50)"><path d="M14 14Q25 4 36 14Q40 50 34 86Q25 94 16 86Q10 50 14 14Z" fill="{c}" {L}></path><path d="M25 24L14 44M25 24L36 44" fill="none" stroke="{O}" stroke-width="5" stroke-linecap="round"></path></g>' for dx, dy, r, c in ((6, 2, -8, BLUE), (46, 4, 8, YEL))))
esky = g(f'<rect x="12" y="38" width="76" height="48" rx="8" fill="{BLUE}" {L}></rect>', f'<rect x="8" y="28" width="84" height="16" rx="6" fill="{CREAM}" {L}></rect>',
         f'<path d="M36 28V20Q36 16 40 16H60Q64 16 64 20V28" fill="none" {L}></path>', f'<rect x="20" y="50" width="60" height="6" rx="3" fill="{CREAM}"></rect>')
hoist = g(f'<path d="M50 96V30" {L}></path>', f'<path d="M8 34L50 24L92 34M22 42L50 24L78 42" fill="none" {L}></path>',
          ''.join(f'<path d="M{x-6} 38v16q0 6 6 6h6v-6h-4v-16z" fill="{c}" {L}></path>' for x, c in ((20, RED), (36, BLUE), (64, YEL), (80, GREEN))))
pie = g(f'<path d="M12 50H88L80 78Q78 84 70 84H30Q22 84 20 78Z" fill="{BROWN}" {L}></path>', f'<ellipse cx="50" cy="50" rx="38" ry="12" fill="#D9A066" {L}></ellipse>',
        f'<path d="M40 50l6 -4M54 46l6 4" fill="none" {L}></path>', ''.join(f'<path d="M{x} 60v18" stroke="#8C5C35" stroke-width="3"></path>' for x in (30, 40, 50, 60, 70)))
snag = g(f'<path d="M10 54Q50 40 90 54Q86 72 50 74Q14 72 10 54Z" fill="{CREAM}" {L}></path>', f'<path d="M14 50Q50 34 86 50Q82 60 50 62Q18 60 14 50Z" fill="#B0533A" {L}></path>',
         f'<path d="M24 46q8 6 16 0t16 0t16 0" fill="none" stroke="{RED}" stroke-width="4" stroke-linecap="round"></path><path d="M30 64h40" stroke="#E8D3A8" stroke-width="3"></path>')
fairy = g(f'<path d="M14 24H86L50 86Z" fill="{CREAM}" {L}></path>', ''.join(f'<circle cx="{x}" cy="{y}" r="2.600" fill="{c}"></circle>' for x, y, c in ((30, 32, RED), (42, 30, BLUE), (56, 34, YEL), (68, 30, GREEN), (36, 42, BLUE), (50, 44, RED), (62, 42, YEL), (44, 56, GREEN), (54, 58, RED), (50, 70, BLUE), (74, 32, RED))))
lam = g(f'<rect x="18" y="30" width="64" height="50" rx="8" fill="#6B3E24" {L}></rect>', f'<path d="M18 52H82" stroke="{CREAM}" stroke-width="6"></path><path d="M18 52H82" stroke="{RED}" stroke-width="2"></path>',
        ''.join(f'<circle cx="{x}" cy="{y}" r="2" fill="{CREAM}"></circle>' for x, y in ((28, 38), (40, 42), (54, 36), (68, 40), (74, 64), (30, 66), (46, 70), (60, 68))))
pav = g(f'<path d="M14 64Q14 44 30 42Q36 30 50 32Q64 30 70 42Q86 44 86 64Z" fill="{CREAM}" {L}></path>', f'<rect x="10" y="62" width="80" height="16" rx="6" fill="{SHELL}" {L}></rect>',
        f'<circle cx="40" cy="38" r="7" fill="{RED}" {L}></circle><circle cx="58" cy="36" r="6" fill="#7DBB5B" {L}></circle><circle cx="50" cy="28" r="5" fill="{YEL}" {L}></circle>')
cricket = g(f'<path d="M30 92L44 50" stroke="{O}" stroke-width="10" stroke-linecap="round"></path><path d="M30 92L44 50" stroke="{BROWN}" stroke-width="4" stroke-linecap="round"></path>',
            f'<path d="M40 52L60 10Q66 6 70 12L54 56Z" fill="#E8D3A8" {L}></path>', f'<circle cx="78" cy="78" r="12" fill="{RED}" {L}></circle><path d="M70 72q8 6 16 12" fill="none" stroke="{CREAM}" stroke-width="3"></path>')
zinc = g(f'<rect x="34" y="22" width="32" height="64" rx="10" fill="{CREAM}" {L}></rect>', f'<rect x="34" y="22" width="32" height="18" rx="8" fill="{BLUE}" {L}></rect>',
         f'<path d="M40 50h20M40 58h20" stroke="{YEL}" stroke-width="5" stroke-linecap="round"></path><path d="M40 70h20" stroke="{RED}" stroke-width="5" stroke-linecap="round"></path>')
letterbox = g(f'<path d="M50 96V62" stroke="{O}" stroke-width="10"></path><path d="M50 96V62" stroke="{BROWN}" stroke-width="4"></path>', f'<path d="M24 62V36Q24 18 50 18Q76 18 76 36V62Z" fill="{RED}" {L}></path>',
              f'<rect x="38" y="34" width="24" height="5" rx="2.500" fill="{O}"></rect>', f'<path d="M20 96H80" {L}></path>')
crate = g(f'<rect x="14" y="26" width="72" height="60" rx="5" fill="{BLUE}" {L}></rect>', ''.join(f'<rect x="{x}" y="38" width="9" height="12" rx="3" fill="{PAPER}"></rect><rect x="{x}" y="60" width="9" height="12" rx="3" fill="{PAPER}"></rect>' for x in (24, 38, 52, 66)), f'<rect x="38" y="28" width="24" height="7" rx="3" fill="{PAPER}"></rect>')
board = g(f'<path d="M24 92Q12 50 40 12Q50 4 58 12Q84 50 74 92Z" fill="{YEL}" {L}></path>', f'<path d="M49 16V88" stroke="{RED}" stroke-width="6"></path>', f'<path d="M36 34q-6 18 -2 36" {HI}></path>')
EVERY = [('Bottle', bottle), ('Nappy', nappy), ('Potty', potty), ('Bowl and spoon', bowl), ('Sippy cup', cup), ('Toothbrush', brush), ('Book', book), ('Blanket', blanket), ('Rubber duck', duck), ('Balloon', balloon)]
AUS = [('Thongs', thongs), ('Esky', esky), ('Hills Hoist', hoist), ('Meat pie', pie), ('Sausage in bread', snag), ('Fairy bread', fairy), ('Lamington', lam), ('Pavlova', pav), ('Cricket bat and ball', cricket), ('Zinc stick', zinc), ('Letterbox', letterbox), ('Milk crate', crate), ('Surfboard', board)]
def cell(n, s): return f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 92px"><div style="width: 88px; height: 84px; background: {PAPER}; border-radius: 18px; display: flex; align-items: center; justify-content: center"><svg role="img" aria-label="{n}" width="66" height="66" viewBox="0 0 100 100">{s}</svg></div><div style="font-size: 12px; font-weight: 700; text-align: center; line-height: 1.2">{n}</div></div>'
def grid(lst): return f'<div style="display: flex; flex-wrap: wrap; gap: 12px 6px">{"".join(cell(n, s) for n, s in lst)}</div>'
H = lambda t: f'<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">{t}</div>'
body = f'''<div style="width: 1080px; height: 600px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 14px">
<div style="display: flex; flex-direction: column; gap: 4px"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Props, refined, and Australiana</h1><div style="font-size: 13px; font-weight: 600; color: #4A3B30">One outline weight, flat palette colours, one white highlight, no brands or labels</div></div>
{H("Everyday")}{grid(EVERY)}
{H("Australian")}{grid(AUS)}
</div>'''
wrap('Props, refined, and Australiana', body, 1080, 600, 'Props2.dc.html', 29600)
