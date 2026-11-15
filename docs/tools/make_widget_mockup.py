"""The widget family, drawn (15 November 2026): what is built, and what the references suggest adding.
Writes docs/previews/widgets/family.html.

    python3 docs/tools/make_widget_mockup.py
"""
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'widgets', 'family.html')
os.makedirs(os.path.dirname(OUT), exist_ok=True)
SKY, MINT, SHELL = '#BFD9F5', '#CFE5D2', '#F3D9C9'
G = {'sleep': '<path d="M19 14.5A8 8 0 0 1 9.500 5a8 8 0 1 0 9.500 9.500Z"/>',
     'bottle': '<path d="M9 3h6v3H9zM8 9c0-1.500 1-3 4-3s4 1.500 4 3v10a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2z"/>',
     'nappy': '<path d="M4 7h16v4a8 8 0 0 1-16 0zM4 9.500c3 0 5 2 5.500 5.500M20 9.500c-3 0-5 2-5.500 5.500"/>',
     'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.600 5.600l1.400 1.400M17 17l1.400 1.400M5.600 18.400L7 17M17 7l1.400-1.400"/>',
     'solids': '<path d="M4 11h16a8 8 0 0 1-16 0zM9 20h6M14 8l4-4"/>'}
def glyph(n, s=13): return f'<svg viewBox="0 0 24 24" width="{s}" height="{s}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-2px">{G[n]}</svg>'
def badge(l, c, s=28): return f'<span style="width:{s}px;height:{s}px;border-radius:50%;background:{c};color:#3A2A20;font-weight:800;font-size:{s*.5:.0f}px;display:inline-grid;place-items:center;flex:none">{l}</span>'
def fact(g, t, v, big=False): return f'<div style="flex:1;min-width:0"><div style="font-size:{12 if big else 10.500}px;color:var(--mu);font-weight:550;white-space:nowrap">{glyph(g, 13 if big else 11)} {t}</div><div style="font-size:{20 if big else 15}px;font-weight:650;white-space:nowrap">{v}</div></div>'
def line(g, t, v): return f'<div style="display:flex;justify-content:space-between;font-size:12.500px"><span style="color:var(--mu);font-weight:550">{glyph(g, 12)} {t}</span><b style="font-weight:650">{v}</b></div>'
def w(inner, wd=338, ht=158, dark=False, night=False, pad=16):
    v = ('--bg:#1B2440;--ink:#F3E0B8;--mu:rgba(243,224,184,.7);--fi:rgba(243,224,184,.16)' if night else
         '--bg:#2A2420;--ink:#EBDDC4;--mu:#B3A590;--fi:#3B332D' if dark else '--bg:#FBF6E9;--ink:#3A2A20;--mu:#6B5E52;--fi:#EAE2D2')
    return f'<div style="{v};width:{wd}px;height:{ht}px;background:var(--bg);color:var(--ink);border-radius:24px;padding:{pad}px;box-sizing:border-box;display:flex;flex-direction:column;box-shadow:0 6px 18px rgba(58,42,32,.14)">{inner}</div>'
def row(l, c, name, facts): return f'<div style="display:flex;align-items:center;gap:10px;flex:1">{badge(l, c)}<b style="width:58px;font-size:14.500px;font-weight:650">{name}</b><div style="display:flex;gap:6px;flex:1">{facts}</div></div>'
HR = '<div style="height:1px;background:var(--fi)"></div>'
ollie = fact('bottle', 'Fed', '1h 29m') + fact('sun', 'Awake', '1h 11m') + fact('nappy', 'Nappy', '45m')
bea = fact('sleep', 'Asleep', '50m') + fact('bottle', 'Fed', '2h 30m')
kit = fact('bottle', 'Fed', '2h 05m') + fact('sun', 'Awake', '40m') + fact('nappy', 'Nappy', '1h 10m')
def head(l, c, name, s=28, fs=16): return f'<div style="display:flex;align-items:center;gap:8px">{badge(l, c, s)}<b style="font-size:{fs}px;font-weight:650">{name}</b></div>'
small = head('O', SKY, 'Ollie') + '<div style="flex:1"></div><div style="display:flex;flex-direction:column;gap:4px">' + line('bottle', 'Fed', '1h 29m') + line('sun', 'Awake', '1h 11m') + line('nappy', 'Nappy', '45m') + '</div>'
small_n = head('B', MINT, 'Bea') + '<div style="flex:1"></div><div style="display:flex;flex-direction:column;gap:4px">' + line('sleep', 'Asleep', '50m') + line('bottle', 'Fed', '2h 30m') + '</div>'
alone = head('O', SKY, 'Ollie', 34, 19) + '<div style="flex:1"></div><div style="display:flex;gap:10px">' + fact('bottle', 'Fed', '1h 29m', True) + fact('sun', 'Awake', '1h 11m', True) + fact('nappy', 'Nappy', '45m', True) + '</div><div style="font-size:11.500px;color:var(--mu);margin-top:2px">Bottle · 150 ml</div>'
def pill(g, t, filled): return f'<span style="padding:6px 10px;border-radius:16px;font-size:12px;font-weight:650;white-space:nowrap;background:{"var(--ink)" if filled else "var(--fi)"};color:{"var(--bg)" if filled else "var(--ink)"}">{glyph(g, 13)} {t}</span>'
def qrow(l, c, name, st, a, b): return f'<div style="display:flex;align-items:center;gap:10px;flex:1">{badge(l, c, 30)}<div style="flex:1"><div style="font-weight:650;font-size:14.500px">{name}</div><div style="font-size:12px;color:var(--mu)">{st}</div></div>{a}{b}</div>'
quick = qrow('O', SKY, 'Ollie', 'Fed 1h 29m', pill('nappy', 'Nappy', False), pill('sleep', 'Sleep', True)) + qrow('B', MINT, 'Bea', 'Asleep 50m', '', pill('sun', 'Woke', True))
def tile(g, t, v): return f'<div style="background:var(--fi);border-radius:16px;padding:8px 12px;display:flex;align-items:center;gap:10px;min-height:0"><span>{glyph(g, 22)}</span><div style="flex:1"><div style="font-size:11px;color:var(--mu);font-weight:550">{t}</div><div style="font-size:15px;font-weight:650;line-height:1.15">{v}</div></div><span style="font-size:17px;color:var(--mu)">+</span></div>'
tiles = f'<div style="display:grid;grid-template-columns:1fr 1fr;grid-template-rows:1fr 1fr;gap:8px;flex:1">{tile("sleep", "Awake", "1h 11m")}{tile("bottle", "Fed", "1h 29m")}{tile("nappy", "Nappy", "45m")}{tile("solids", "Solids", "3h 20m")}</div>'
def block(l, c, name, facts, totals): return f'<div style="flex:1;display:flex;flex-direction:column;justify-content:center;gap:6px">{head(l, c, name)}<div style="display:flex;gap:6px;padding-left:36px">{facts}</div><div style="font-size:11.500px;color:var(--mu);padding-left:36px">Today: {totals}</div></div>'
large = block('O', SKY, 'Ollie', ollie, '4 feeds, 560 ml · 3h 10m asleep · 5 nappies') + HR + block('B', MINT, 'Bea', bea, '3 meals · 50m asleep so far') + HR + block('K', SHELL, 'Kit', kit, '5 feeds · 2h 40m asleep · 4 nappies')
lock = '<div style="width:170px;color:#fff;font:600 14px -apple-system"><div style="font-size:15px">Ollie</div><div style="font-weight:500">Fed 1h 29m</div><div style="font-weight:500">Awake 1h 11m</div></div>'
def cell(title, tag, body, note): return f'<div><div style="font-weight:700;font-size:15px">{title} <span style="font-weight:600;font-size:12px;color:{"#3C9A5F" if tag == "Built" else "#B23A26"};margin-left:4px">{tag}</span></div><div style="margin:8px 0 6px">{body}</div><p style="margin:0;color:#6B5E52;font-size:13px;max-width:{note[1]}px">{note[0]}</p></div>'
html = f'''<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#E9E1CF;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1300px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Widgets: one snapshot, in every size</h1>
<p style="margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:105ch">A drawing of the widget family. "Built" is in the code now and not yet seen on a phone; "Idea" is drawn only. Every widget uses the same three facts as the Lock Screen card, in one ink, with the child's badge.</p>
<div style="display:flex;gap:30px;flex-wrap:wrap;align-items:flex-start">
{cell('One child, small', 'Built', '<div style="display:flex;gap:14px">' + w(small, 158, 158) + w(small_n, 158, 158, night=True) + '</div>', ('Night colours while they are asleep.', 330))}
{cell('Family snapshot, one child', 'Built', w(alone), ('One child has the room. The amount under the feed is an idea, taken from Gaia.', 338))}
{cell('Family snapshot, two and three', 'Built', '<div style="display:flex;gap:14px">' + w(row('O', SKY, 'Ollie', ollie) + HR + row('B', MINT, 'Bea', bea)) + w(row('O', SKY, 'Ollie', ollie) + HR + row('B', MINT, 'Bea', bea) + HR + row('K', SHELL, 'Kit', kit), dark=True, pad=12) + '</div>', ('A row each, sharing the height. Dark follows the Home Screen.', 690))}
{cell('Quick log', 'Built', w(quick), ('The buttons. One short fact, so nothing is cut off.', 338))}
{cell('Log for one child, tiles', 'Idea', w(tiles, pad=10), ('Each tile is the fact and the way in: it opens that sheet. The shape is from Huckleberry; one ink and our icons, not four loud colours.', 338))}
{cell('Lock Screen', 'Built', '<div style="background:#3d4a63;border-radius:18px;padding:14px 18px;width:200px">' + lock + '</div>', ('Under the clock. Also one line beside the date.', 230))}
{cell('Family today, large', 'Idea', w(large, 338, 354), ('The snapshot plus the day so far for each child. The totals for the day are the one good thing in the Baby Tracker widget.', 338))}
</div>
<div style="display:flex;gap:40px;margin-top:26px;font-size:14px;max-width:1240px">
<div style="flex:1"><b>Taken from the references</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Gaia: an icon, a word, a time, and the amount beneath.</li><li>Huckleberry: a tile that is both the fact and the button.</li><li>Baby Tracker: the day's totals under the latest entry.</li><li>All of them: a short name and one plain line in the picker.</li></ul></div>
<div style="flex:1"><b>Left behind</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Seconds ("57 min, 32 secs ago"). Nobody needs them and they never sit still.</li><li>A colour for every activity. One ink, and the child's colour for the child.</li><li>Stale facts ("12270h ago"). Ours drop out after twelve hours.</li><li>A logo on every widget. The badge and the icons are enough.</li><li>A prediction mixed in with the facts. If it comes, it is its own widget.</li></ul></div></div>
</body>'''
open(OUT, 'w').write(html)
print('wrote', OUT)
