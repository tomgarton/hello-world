import sys
ROOT = sys.argv[1]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
INK, A, SKY = '#3A2A20', '#F4BE2C', '#BFD9F5'
L = f'fill="none" stroke="{INK}" stroke-width="SW" stroke-linecap="round" stroke-linejoin="round"'
def ln(d): return f'<path d="{d}" {L}></path>'
def fill(d, c=A): return f'<path d="{d}" fill="{c}"></path>'
def circ(cx, cy, r, f=None): return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{f}"></circle>' if f else '') + f'<circle cx="{cx}" cy="{cy}" r="{r}" {L}></circle>'
ICONS = [
 ('Bottle', 'Teat, collar, body, milk level. Ticks say "measured feed".',
  fill('M8 14h8v4.500a2.500 2.500 0 0 1-2.500 2.500h-3A2.500 2.500 0 0 1 8 18.500z') + ln('M10 4.500a2 2 0 0 1 4 0V7h-4z') + ln('M8.500 7h7a1 1 0 0 1 1 1v1h-9V8a1 1 0 0 1 1-1z') + ln('M8 9h8v9.500a2.500 2.500 0 0 1-2.500 2.500h-3A2.500 2.500 0 0 1 8 18.500z') + ln('M8 12.500h2.500M8 15.500h2.500')),
 ('Breastfeed', 'A parent cradling a baby to the chest: two heads, one arm.',
  circ(8.500, 5.500, 2.500) + ln('M3.500 20.500c0-6 1.500-9.500 5-9.500 2.500 0 4 1 5 2.500') + '<ellipse cx="12.500" cy="16" rx="4.200" ry="2.600" transform="rotate(-18 12.500 16)" fill="#F4BE2C"></ellipse><ellipse cx="12.500" cy="16" rx="4.200" ry="2.600" transform="rotate(-18 12.500 16)" ' + L + '></ellipse>' + circ(17.500, 13.500, 2) + ln('M6.500 18.500c3 1.500 7 1.500 11-.5')),
 ('Pump', 'A round funnel narrowing into a small bottle.',
  '<ellipse cx="5.500" cy="8" rx="1.600" ry="3.600" ' + L + '></ellipse>' + ln('M5.500 4.400L12 7M5.500 11.600L12 10') + ln('M12 6.500h4v4h-4z') + fill('M12 15h5v3.500a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2z') + ln('M12 10.500h5v8a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2z')),
 ('Solids', 'A bowl with food heaped above the rim and a spoon.',
  fill('M7 11c.8-2.200 2.800-3.500 5-3.500s4.200 1.300 5 3.500z') + ln('M7 11c.8-2.200 2.800-3.500 5-3.500s4.200 1.300 5 3.500') + ln('M3.500 11h17c0 4.700-3.800 8.500-8.500 8.500S3.500 15.700 3.500 11z') + ln('M15.500 7.500l4-4')),
 ('Sleep', 'Crescent moon with one twinkle.',
  ln('M18.500 15A8 8 0 0 1 9 4.500a8 8 0 1 0 9.500 10.500z') + fill('M17 3.500l.9 1.900 1.900.9-1.900.9L17 9.100l-.9-1.900-1.900-.9 1.900-.9z')),
 ('Nappy', 'Front view: waistband, tapered body, leg openings, tabs.',
  ln('M3.500 6.500h17v3c0 4.500-3.200 8-6 9.500h-5c-2.800-1.500-6-5-6-9.500z') + ln('M3.500 9.500h17') + fill('M4.500 7.200h3.500v1.600H4.500zM16 7.200h3.500v1.600H16z') + ln('M8.500 19c0-3 1.500-5 3.500-5s3.500 2 3.500 5')),
 ('Potty', 'Side view: seat, bowl and the raised front guard, so it is not a cup.',
  fill('M4 10h16v2H4z') + ln('M4 10h16v2H4z') + ln('M5.500 12l1.500 6.500a1.500 1.500 0 0 0 1.500 1h7a1.500 1.500 0 0 0 1.500-1L18.500 12') + ln('M17 10V6.500a1.500 1.500 0 0 1 3 0V10')),
 ('Bath', 'A tub on feet, with bubbles rising.',
  ln('M3 11.500h18v2a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5z') + ln('M6 18l-1 2M18 18l1 2') + circ(9, 7.500, 2, A) + circ(13.500, 6, 1.300, A) + circ(15.500, 9, 1, A)),
 ('Growth', 'A height chart with a child-sized arrow mark.',
  ln('M15 3.500h4.500v17H15z') + ln('M15 7h2M15 10.500h2.500M15 14h2M15 17.500h2.500') + fill('M5 12.500h7.500v2H5z') + ln('M5 12.500h7.500v2H5zM8.750 12.500V5M6 7.500l2.750-2.750L11.500 7.500')),
 ('Weight', 'A baby scale: curved tray on a base with a readout.',
  ln('M3.500 8.500h17c-.5 3-3 5-8.500 5s-8-2-8.500-5z') + ln('M8 13.500l-1 3h10l-1-3') + ln('M5 16.500h14v3H5z') + fill('M10 17.500h4v1h-4z')),
 ('Temperature', 'A thermometer with a filled bulb.',
  ln('M10 14V5.500a2 2 0 0 1 4 0V14a3.500 3.500 0 1 1-4 0z') + circ(12, 17, 1.800, A) + ln('M12 15.200V9')),
 ('Medicine', 'A dropper bottle: the shape of baby medicine.',
  fill('M8 14h8v4.500a1.500 1.500 0 0 1-1.500 1.500h-5A1.500 1.500 0 0 1 8 18.500z') + ln('M8 11h8v7.500a1.500 1.500 0 0 1-1.500 1.500h-5A1.500 1.500 0 0 1 8 18.500z') + ln('M9.500 8.500h5V11h-5z') + ln('M10.500 8.500V6a1.500 1.500 0 0 1 3 0v2.500')),
 ('Vaccine', 'A syringe with a needle, filled partway.',
  fill('M8.200 13.800l4-4 2.400 2.400-4 4z') + ln('M6 13.500L13.500 6l4.500 4.500L10.500 18z') + ln('M6 13.500l-2.500 2.500 4.500 4.500 2.500-2.500M15.750 8.250l2.500-2.500M17 4.500l2.500 2.500M4.750 19.250L3 21')),
 ('Teeth', 'One tooth with a shine.',
  ln('M7 4c-2 0-3 2-3 4 0 3 1.500 4 2 7 .5 3 1 5 2.500 5S10 17 12 17s2 3 3.500 3 2-2 2.500-5c.5-3 2-4 2-7 0-2-1-4-3-4-2.500 0-3 1.500-5 1.500S9.500 4 7 4z') + '<path d="M15.500 7.500q2 .5 2 3" fill="none" stroke="#F4BE2C" stroke-width="2" stroke-linecap="round"></path>'),
 ('Milestone', 'A star with a filled centre.',
  fill('M12 8.400l1.100 2.300 2.500.4-1.800 1.700.4 2.500L12 14.100l-2.200 1.200.4-2.500-1.800-1.700 2.500-.4z') + ln('M12 3.500l2.500 5.200 5.700.8-4.100 4 1 5.700L12 16.500l-5.100 2.700 1-5.700-4.100-4 5.700-.8z')),
 ('Tummy time', 'A baby on a mat, lying flat with head lifted.',
  fill('M2.500 19h19v1.800h-19z', SKY) + ln('M2.500 19h19') + ln('M5 19a2.500 2.500 0 0 1 0-5h8.500a2.500 2.500 0 0 1 0 5') + circ(17.500, 12.500, 3, A) + ln('M14.500 17l2 2')),
 ('Play', 'A baby rattle: round head, band, handle.',
  circ(14, 9, 5, None) + fill('M10.400 12.500l1.100 1.100 3.500-3.500-1.100-1.100z') + ln('M10.500 12.500L4.500 18.500M3.500 17.500l3 3') + ln('M11 6.500c1-1 2.500-1.500 3.500-1')),
 ('Walk', 'A pram: hood, basket, handle, two wheels.',
  fill('M4 11.500V8a6 6 0 0 1 6-6v9.500z') + ln('M4 11.500V8a6 6 0 0 1 6-6v9.500') + ln('M4 11.500h13.500a6.750 6.750 0 0 1-13.500 0z') + ln('M17.500 11.500l1.500-5h2') + circ(7.500, 20, 1.500) + circ(15, 20, 1.500)),
 ('Note', 'A page with a folded corner.',
  fill('M14.500 3.500v4h4z') + ln('M5.500 3.500h9l4 4v13h-13z') + ln('M14.500 3.500v4h4M8.500 11h7M8.500 14h7M8.500 17h4.500')),
 ('Photo', 'A camera body, lens and top bump.',
  ln('M8.500 6.500l1.200-2h4.600l1.200 2') + ln('M3.500 6.500h17v12.500h-17z') + circ(12, 12.700, 3.800, A) + '<circle cx="17.500" cy="9" r=".8" fill="#3A2A20"></circle>'),
]
grid = ''.join(f'<path d="M{i} 0V24M0 {i}H24" stroke="#E2D8C6" stroke-width="0.060"></path>' for i in range(25))
key = '<rect x="2" y="2" width="20" height="20" fill="none" stroke="#E5553B" stroke-width="0.100" opacity="0.6"></rect><circle cx="12" cy="12" r="10" fill="none" stroke="#2A62B8" stroke-width="0.100" opacity="0.5"></circle>'
def tile(n, note, svg, k):
    return (f'<div style="display: flex; flex-direction: column; gap: 6px; width: 182px">'
            f'<div style="display: flex; gap: 8px; align-items: flex-end"><svg role="img" aria-label="{n} icon on the grid" width="132" height="132" viewBox="0 0 24 24" style="background: #FBF6E9; border-radius: 10px">{grid}{key}{svg}</svg>'
            f'<div style="display: flex; flex-direction: column; gap: 8px; align-items: center"><svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">{svg}</svg><svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24">{svg}</svg></div></div>'
            f'<div style="font-size: 15px; font-weight: 800">{k:02d}. {n}</div><div style="font-size: 12px; font-weight: 500; color: #4A3B30; line-height: 1.35">{note}</div></div>')
tiles = ''.join(tile(n, note, s, i + 1) for i, (n, note, s) in enumerate(ICONS))
D = {n: sv_ for n, _, sv_ in ICONS}
def wt(svg, sw): return svg.replace('stroke-width="1.400"', f'stroke-width="{sw}"')
cmp_rows = ''
for sw in (1.75, 1.4, 1.2):
    cmp_rows += f'<div style="display: flex; align-items: center; gap: 14px"><div style="width: 60px; font-size: 13px; font-weight: 800">{sw} pt</div>' + ''.join(f'<svg aria-hidden="true" width="{sz}" height="{sz}" viewBox="0 0 24 24">{wt(D[n], sw)}</svg>' for n in ('Bottle', 'Pump', 'Nappy', 'Tummy time', 'Walk', 'Teeth') for sz in (24,)) + '<div style="width: 18px"></div>' + ''.join(f'<svg aria-hidden="true" width="17" height="17" viewBox="0 0 24 24">{wt(D[n], sw)}</svg>' for n in ('Bottle', 'Pump', 'Nappy', 'Tummy time', 'Walk', 'Teeth')) + '</div>'
body = f'''<div style="width: 1080px; height: 1150px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; flex-direction: column; gap: 4px"><h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">Activity icons, one by one</h1><div style="font-size: 14px; font-weight: 500; color: #4A3B30">1.4 pt stroke. Each on the 24 pt grid (red: 2 pt padding, blue: circle keyshape), with the idea it relies on, and at real sizes 24 and 17 pt.</div></div>
<div style="display: flex; flex-direction: column; gap: 8px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">Stroke weight at real size (24 and 17 pt)</div>{cmp_rows}</div>
<div style="display: flex; flex-wrap: wrap; gap: 22px 12px">{tiles}</div>
</div>'''
wrap('Activity icons, one by one', body, 1080, 1150, 'IconSystem2.dc.html', 32600)
