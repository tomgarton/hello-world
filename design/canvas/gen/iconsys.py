import sys
ROOT = sys.argv[1]
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); wrap = w['wrap']
INK, A = '#3A2A20', '#F4BE2C'
L = f'fill="none" stroke="{INK}" stroke-width="1.750" stroke-linecap="round" stroke-linejoin="round"'
F = f'fill="{A}" stroke="none"'
def both(d): return f'<path d="{d}" {F}></path><path d="{d}" {L}></path>'
def ln(d): return f'<path d="{d}" {L}></path>'
I = {
 'Bottle': f'<path d="M9.500 14h5v4.500a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2z" {F}></path>' + ln('M9.500 9h5v9.500a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2zM9 7h6v2H9zM10.500 7l.5-3h2l.5 3'),
 'Breastfeed': f'<path d="M12 11c-1.200 1.800-2 3-2 4a2 2 0 0 0 4 0c0-1-.8-2.200-2-4z" {F}></path>' + ln('M12 20s-7.500-4.500-7.500-10A4 4 0 0 1 12 7.500 4 4 0 0 1 19.500 10c0 5.500-7.500 10-7.500 10z'),
 'Pump': both('M8 13h6v6a2 2 0 0 1-2 2h-2a2 2 0 0 1-2-2z') + ln('M7 8a4 4 0 0 1 8 0v5H7zM15 8h4l1-3'),
 'Solids': f'<path d="M7 11c1-2.500 3-3.500 5-3.500s4 1 5 3.500z" {F}></path>' + ln('M3.500 11h17a8.500 8.500 0 0 1-17 0zM14 11l5-7'),
 'Sleep': ln('M18.500 14.500A7.500 7.500 0 0 1 9 5a7.500 7.500 0 1 0 9.500 9.500z') + f'<path d="M17 4l.8 1.700 1.700.8-1.700.8L17 9l-.8-1.700-1.700-.8 1.700-.8z" {F}></path>',
 'Nappy': ln('M3.500 7h17v2c0 5.500-3.800 9-8.500 9S3.500 14.500 3.500 9z') + f'<rect x="5" y="8" width="3" height="2" rx=".5" {F}></rect><rect x="16" y="8" width="3" height="2" rx=".5" {F}></rect>' + ln('M3.500 10h17'),
 'Potty': ln('M3 9.500h18M4 8h16a1 1 0 0 1 1 1v1a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1zM5.500 11l1.300 7a2 2 0 0 0 2 1.500h6.400a2 2 0 0 0 2-1.500l1.300-7') + f'<circle cx="12" cy="15" r="1.600" {F}></circle>',
 'Bath': f'<circle cx="17.500" cy="8.500" r="2" {F}></circle>' + ln('M10 8a5 5 0 1 1 0 10 5 5 0 0 1 0-10zM17.500 8.500a2 2 0 1 1 0 .01M18 15.500a1.500 1.500 0 1 1 0 .01M7 4a1.500 1.500 0 1 1 0 .01'),
 'Growth': ln('M5 20h14M8 20V9M8 9l-3 3M8 9l3 3') + both('M14 20V6h5v14z') + ln('M14 9h2.500M14 12h2.500M14 15h2.500'),
 'Weight': ln('M4 9h16l-1.500 10.500a1 1 0 0 1-1 .5h-11a1 1 0 0 1-1-.5zM8.500 9a3.500 3.500 0 0 1 7 0M12 9l1.500-2') + f'<rect x="9" y="13" width="6" height="3" rx="1" {F}></rect>',
 'Temperature': ln('M10 14.500V5a2 2 0 0 1 4 0v9.500a4 4 0 1 1-4 0z') + f'<circle cx="12" cy="17.500" r="2" {F}></circle>' + ln('M12 15.500V9'),
 'Medicine': ln('M4 19L14.500 8.500') + both('M14 9l3.500-3.500a2.500 2.500 0 0 1 3.500 3.500L17.500 12.500z'),
 'Vaccine': f'<path d="M9 9l3-3 6 6-3 3z" {F}></path>' + ln('M5 13l8-8 6 6-8 8z') + ln('M5 13l-1 1a1.400 1.400 0 0 0 0 2l4 4a1.400 1.400 0 0 0 2 0l1-1M9 9l6 6M11.500 10l.01.01M14 12.500l.01.01'),
 'Teeth': f'<path d="M15.500 7.500q2 .5 2 3" fill="none" stroke="#F4BE2C" stroke-width="2" stroke-linecap="round"></path>' + ln('M7 4c-2 0-3 2-3 4 0 3 1.500 4 2 7 .5 3 1 5 2.500 5S10 17 12 17s2 3 3.500 3 2-2 2.500-5c.5-3 2-4 2-7 0-2-1-4-3-4-2.500 0-3 1.500-5 1.500S9.500 4 7 4z'),
 'Milestone': f'<circle cx="12" cy="12" r="2.600" {F}></circle>' + ln('M12 3.500l2.500 5.200 5.700.8-4.100 4 1 5.700L12 16.500l-5.100 2.700 1-5.700-4.100-4 5.700-.8z'),
 'Tummy time': ln('M3 19h18') + both('M5 19c0-3 2-5 6-5h4') + f'<circle cx="17.500" cy="13" r="3" fill="none" stroke="{INK}" stroke-width="1.750"></circle>',
 'Play': both('M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z').replace(F, 'fill="none" stroke="none"', 1) + f'<path d="M12 4a8 8 0 0 1 8 8h-8z" {F}></path>' + ln('M12 4a8 8 0 1 1 0 16 8 8 0 0 1 0-16zM12 4v16M4 12h16'),
 'Walk': f'<path d="M5 11V7a5 5 0 0 1 5-5v9z" {F}></path>' + ln('M5 11h12a6 6 0 0 1-12 0zM5 11V7a5 5 0 0 1 5-5v9M17 11l2-5h2M8 20.500a1.500 1.500 0 1 0 0 .01M15 20.500a1.500 1.500 0 1 0 0 .01'),
 'Note': both('M6 3.500h9l3 3v14H6z').replace(F, 'fill="none" stroke="none"', 1) + f'<path d="M15 3.500l3 3h-3z" {F}></path>' + ln('M6 3.500h9l3 3v14H6zM15 3.500v3h3M9 11h6M9 14h6M9 17h4'),
 'Photo': both('M8.500 6.500l1-2h5l1 2') + ln('M4 7h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z') + f'<circle cx="12" cy="13" r="3.500" {F}></circle>' + ln('M12 9.500a3.500 3.500 0 1 1 0 7 3.500 3.500 0 0 1 0-7z'),
}
def tile(n, svg):
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 5px; width: 78px"><div style="width: 64px; height: 64px; border-radius: 16px; background: #ECE4D4; display: flex; align-items: center; justify-content: center">'
            f'<svg role="img" aria-label="{n}" width="40" height="40" viewBox="0 0 24 24">{svg}</svg></div><div style="font-size: 12px; font-weight: 700; text-align: center">{n}</div></div>')
grid_ = ''.join(f'<path d="M{i} 0V24M0 {i}H24" stroke="#D9CFBE" stroke-width="0.080"></path>' for i in range(25))
key = (f'<svg role="img" aria-label="Keyline grid: 24 point canvas with 2 point padding, circle, square, portrait and landscape keyshapes" width="200" height="200" viewBox="-1 -1 26 26"><rect x="0" y="0" width="24" height="24" fill="#FBF6E9"></rect>{grid_}'
       '<rect x="2" y="2" width="20" height="20" fill="none" stroke="#E5553B" stroke-width="0.250"></rect><circle cx="12" cy="12" r="10" fill="none" stroke="#2A62B8" stroke-width="0.250"></circle>'
       '<rect x="3" y="3" width="18" height="18" rx="2" fill="none" stroke="#3C9A5F" stroke-width="0.250"></rect><rect x="4" y="2" width="16" height="20" rx="2" fill="none" stroke="#C24A36" stroke-width="0.200" stroke-dasharray="0.600 0.400"></rect>'
       '<rect x="2" y="4" width="20" height="16" rx="2" fill="none" stroke="#6B5E52" stroke-width="0.200" stroke-dasharray="0.600 0.400"></rect></svg>')
mono = ''.join(f'<svg aria-hidden="true" width="32" height="32" viewBox="0 0 24 24">{I[n].replace(F, "fill=\"none\" stroke=\"none\"")}</svg>' for n in ('Bottle', 'Sleep', 'Nappy', 'Potty', 'Teeth', 'Milestone'))
sizes = ''.join(f'<svg aria-hidden="true" width="{s}" height="{s}" viewBox="0 0 24 24">{I["Bottle"]}</svg>' for s in (17, 22, 28, 44))
sf = ['Today: house', 'History: calendar', 'Insights: chart.bar', 'Family: person.2', 'Settings: gearshape', 'Add: plus', 'Edit: pencil', 'Timer: timer', 'Share: square.and.arrow.up', 'Filter: line.3.horizontal.decrease']
refs = [('SF Symbols', 'Apple. Use for all system UI; only on Apple platforms; not in logos or app icons'), ('Phosphor', 'MIT. Six weights incl. a duotone style: the model for line plus accent'),
        ('Lucide', 'ISC. Clean 24 grid, 2 stroke, round joins: a model for construction'), ('Tabler', 'MIT. Very large set; useful for coverage checks'), ('Material Symbols', 'Apache 2.0. Keyline shapes and optical sizes, well documented')]
H = lambda t: f'<div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">{t}</div>'
body = f'''<div style="width: 1080px; height: 760px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 36px 48px; display: flex; flex-direction: column; gap: 18px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">App icon foundation</h1>
<div style="display: flex; gap: 40px">
<div style="display: flex; flex-direction: column; gap: 10px; width: 210px">{H("Grid")}{key}<div style="font-size: 12px; font-weight: 500; color: #4A3B30; line-height: 1.4">24 pt canvas, 2 pt padding. Keyshapes: circle 20, square 18, portrait 16 × 20, landscape 20 × 16.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px; flex-grow: 1">{H("Puggle activity icons (custom)")}<div style="display: flex; flex-wrap: wrap; gap: 10px 2px">{"".join(tile(n, s) for n, s in I.items())}</div></div>
</div>
<div style="display: flex; gap: 40px; align-items: flex-start">
<div style="display: flex; flex-direction: column; gap: 8px; width: 330px">{H("Rules")}<ul style="margin: 0; padding-left: 18px; font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.45">
<li>1.75 pt stroke at 24 pt, round caps and joins, to sit beside SF Symbols Regular</li><li>One accent fill, under the line, up to about a third of the shape. Wattle by default</li><li>Must read with the accent removed (mono test below)</li><li>No faces on icons; faces belong to the characters</li><li>Shipped as custom SF Symbols so they scale with Dynamic Type and take weights</li></ul>
<div style="display: flex; gap: 12px; align-items: center">{mono}</div><div style="display: flex; gap: 14px; align-items: flex-end">{sizes}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px; width: 270px">{H("System UI: SF Symbols")}<div style="display: flex; flex-direction: column; gap: 3px; font-size: 13px; font-weight: 500; color: #4A3B30">{"".join(f"<div>{t}</div>" for t in sf)}</div></div>
<div style="display: flex; flex-direction: column; gap: 8px; width: 330px">{H("References")}<div style="display: flex; flex-direction: column; gap: 6px">{"".join(f'<div style="font-size: 13px; line-height: 1.35"><b style="font-weight: 800">{n}</b> <span style="color: #4A3B30; font-weight: 500">{d}</span></div>' for n, d in refs)}</div></div>
</div>
</div>'''
wrap('App icon foundation', body, 1080, 760, 'IconSystem.dc.html', 31760)
