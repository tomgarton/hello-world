"""Today with the snapshot rows (15 November 2026). Drawn, not built. Writes docs/previews/today/snapshot.html.

    python3 docs/tools/make_today_mockup.py
"""
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'today', 'snapshot.html')
os.makedirs(os.path.dirname(OUT), exist_ok=True)
SKY, MINT, SHELL = '#BFD9F5', '#CFE5D2', '#F3D9C9'
G = {'sleep': '<path d="M19 14.500A8 8 0 0 1 9.500 5a8 8 0 1 0 9.500 9.500Z"/>',
     'bottle': '<path d="M9 3h6v3H9zM8 9c0-1.500 1-3 4-3s4 1.500 4 3v10a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2z"/>',
     'nappy': '<path d="M4 7h16v4a8 8 0 0 1-16 0zM4 9.500c3 0 5 2 5.500 5.500M20 9.500c-3 0-5 2-5.500 5.500"/>',
     'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.600 5.600l1.400 1.400M17 17l1.400 1.400M5.600 18.400L7 17M17 7l1.400-1.400"/>',
     'solids': '<path d="M4 11h16a8 8 0 0 1-16 0zM9 20h6M14 8l4-4"/>',
     'health': '<rect x="3" y="8.500" width="18" height="7" rx="3.500" transform="rotate(-45 12 12)"/><path d="M9 9l6 6"/>',
     'potty': '<path d="M6 11a6 5 0 0 1 12 0v3a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4zM9 11h6"/>'}
def glyph(n, s=13): return f'<svg viewBox="0 0 24 24" width="{s}" height="{s}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-2px">{G[n]}</svg>'
def badge(l, c, s=40): return f'<span style="width:{s}px;height:{s}px;border-radius:50%;background:{c};color:#3A2A20;font-weight:800;font-size:{s*.45:.0f}px;display:inline-grid;place-items:center;flex:none">{l}</span>'
def fact(g, t, v): return f'<div style="flex:1;background:var(--fi);border-radius:12px;padding:6px 9px"><div style="font-size:10.500px;color:var(--mu);font-weight:550;white-space:nowrap">{glyph(g, 11)} {t}</div><div style="font-size:15px;font-weight:650;white-space:nowrap">{v}</div></div>'
def btn(t, filled=True): return f'<span style="padding:8px 13px;border-radius:18px;font-weight:650;font-size:13px;white-space:nowrap;background:{"var(--ink)" if filled else "var(--fi)"};color:{"var(--bg)" if filled else "var(--ink)"}">{t}</span>'
def card(l, c, name, age, facts, nxt, button, night=False, tight=False):
    v = '--bg:#1B2440;--ink:#F3E0B8;--mu:rgba(243,224,184,.7);--fi:rgba(243,224,184,.14)' if night else '--bg:#FBF6E9;--ink:#3A2A20;--mu:#6B5E52;--fi:#EFE8D8'
    nx = f'<div style="font-size:12px;color:var(--mu);margin-top:{6 if tight else 8}px">{nxt}</div>' if nxt else ''
    return (f'<div style="{v};background:var(--bg);color:var(--ink);border-radius:22px;padding:{10 if tight else 13}px 13px;margin-bottom:9px">'
            f'<div style="display:flex;align-items:center;gap:10px">{badge(l, c, 30 if tight else 38)}<div style="flex:1"><b style="font-size:{15 if tight else 16.500}px;font-weight:650">{name}</b> <span style="color:var(--mu);font-size:13px">· {age}</span></div>{button}</div>'
            f'<div style="display:flex;gap:6px;margin-top:{7 if tight else 10}px">{facts}</div>{nx}</div>')
def tile(g, t, sub=''): return f'<div style="flex:1;background:#EAE2D2;border-radius:18px;padding:11px 0 9px;text-align:center"><div>{glyph(g, 24)}</div><div style="font-weight:650;font-size:13.500px">{t}</div><div style="font-size:11px;color:#6B5E52;height:14px">{sub}</div></div>'
def phone(body, sky='#BFDDF0'):
    return (f'<div style="width:330px;height:690px;background:#F2ECDD;border-radius:40px;overflow:hidden;border:1px solid #DDD2BC;position:relative">'
            f'<div style="height:118px;background:linear-gradient({sky},#F2ECDD)"></div>'
            f'<div style="padding:0 14px"><div style="font-weight:800;font-size:23px;letter-spacing:-.02em">Sunday 15 November</div>'
            f'<div style="color:#6B5E52;font-size:13.500px;margin:1px 0 11px">Afternoon. 3 things logged today.</div>{body}</div></div>')
ollie = fact('bottle', 'Fed', '1h 29m') + fact('sun', 'Awake', '1h 11m') + fact('nappy', 'Nappy', '45m')
bea_asleep = fact('sleep', 'Asleep', '50m') + fact('solids', 'Ate', '2h 30m') + fact('potty', 'Potty', '1h 05m')
bea_awake = fact('sun', 'Awake', '3h 10m') + fact('solids', 'Ate', '2h 30m') + fact('potty', 'Potty', '1h 05m')
kit = fact('bottle', 'Fed', '2h 05m') + fact('sun', 'Awake', '40m') + fact('nappy', 'Nappy', '1h 10m')
tiles = lambda: f'<div style="display:flex;gap:8px;margin-top:3px">{tile("solids", "Solids")}{tile("health", "Health")}{tile("potty", "Potty", "Bea 12:05")}</div>'
one = phone(card('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep')) + tiles() +
            '<div style="font-size:12px;color:#6B5E52;margin:10px 2px">Tap a fact to log the next one. The tiles below keep what has no fact: solids, health and the rest.</div>')
two = phone(card('B', MINT, 'Bea', '2½', bea_asleep, '', btn('Woke up'), night=True) + card('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep')) + tiles())
three = phone(card('B', MINT, 'Bea', '2½', bea_awake, '', btn('Start sleep'), tight=True) + card('K', SHELL, 'Kit', '5mo', kit, 'Next sleep around 1:50', btn('Start sleep'), tight=True)
              + card('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep'), tight=True) + tiles())
now = phone(''.join(f'<div style="background:#FBF6E9;border-radius:22px;padding:13px;margin-bottom:9px;display:flex;align-items:center;gap:10px">{badge(l, c)}<div style="flex:1"><b style="font-size:16.500px;font-weight:650">{n}</b> <span style="color:#6B5E52;font-size:13px">· {a}</span><div style="color:#6B5E52;font-size:13.500px">{x}</div><div style="color:#6B5E52;font-size:13.500px">{y}</div></div>{btn("Start sleep", False)}</div>'
                    for l, c, n, a, x, y in [('B', MINT, 'Bea', '2½', 'Slept · 1h 43m', '20h 44m ago'), ('O', SKY, 'Ollie', '5mo', 'Bottle · 200 ml', '2h 44m ago')])
            + f'<div style="display:flex;gap:8px;margin-top:3px">{tile("nappy", "Nappy", "Ollie 9:03")}{tile("solids", "Solids")}{tile("health", "Health")}</div>')
def col(t, d, p): return f'<div style="width:330px"><div style="font-weight:700;font-size:15.500px">{t}</div><p style="margin:2px 0 10px;color:#6B5E52;font-size:13px;min-height:54px">{d}</p>{p}</div>'
html = f'''<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#E4DCC8;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1440px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Today, with the snapshot</h1>
<p style="margin:0 0 20px;color:#6B5E52;font-size:17px;max-width:110ch">Drawn, not built. Each child's card on Today takes the same three facts as the Lock Screen card and the widgets, with the line for what comes next. The scene and Puggle at the top are left out of the drawing.</p>
<div style="display:flex;gap:28px;align-items:flex-start">
{col('Now', 'One fact and one button for each child. The last nappy lives on a tile further down.', now)}
{col('One child', 'Three facts, each one a button that opens its sheet. One line for what comes next, which goes once its time has passed.', one)}
{col('Two, one asleep', 'A sleeping child goes first, in night colours, with Woke up. An older child gets the facts that fit them: ate, potty.', two)}
{col('Three', 'The cards tighten so three fit above the tiles. A child with nothing coming up has no extra line.', three)}
</div>
<div style="display:flex;gap:44px;margin-top:22px;font-size:14px;max-width:1300px">
<div style="flex:1"><b>What changes</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>The nappy moves from a tile up to the child it belongs to.</li><li>Facts are the way in: tapping Fed opens the feed sheet for that child.</li><li>The tiles keep what has no fact of its own.</li></ul></div>
<div style="flex:1"><b>For you to decide</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Whether the facts should look this much like buttons, or sit plainer with the card as the button.</li><li>Whether an older child's facts (ate, potty) are the right three.</li><li>Whether 'Start sleep' stays on every card or only on the youngest.</li></ul></div></div>
</body>'''
open(OUT, 'w').write(html)
print('wrote', OUT)
