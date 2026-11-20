"""Today's tiles with more than one child (15 November 2026): where everything else is logged once each child's
card has its three facts. Drawn, not built. Writes docs/previews/today/tiles.html.

    python3 docs/tools/make_today_tiles_mockup.py
"""
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'today', 'tiles.html')
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

G.update({'bath': '<path d="M4 12h16v2a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM7 12V6a2 2 0 0 1 4 0"/>', 'more': '<path d="M12 6v12M6 12h12"/>',
          'weight': '<rect x="4" y="8" width="16" height="12" rx="3"/><path d="M9 8a3 3 0 0 1 6 0"/>', 'play': '<rect x="4" y="12" width="7" height="7" rx="1.5"/><rect x="13" y="12" width="7" height="7" rx="1.5"/><rect x="8.500" y="4" width="7" height="7" rx="1.5"/>'})
ollie = fact('bottle', 'Fed', '1h 29m') + fact('sun', 'Awake', '1h 11m') + fact('nappy', 'Nappy', '45m')
bea = fact('sun', 'Awake', '3h 10m') + fact('solids', 'Ate', '2h 30m') + fact('potty', 'Potty', '1h 05m')
kit = fact('bottle', 'Fed', '2h 05m') + fact('sun', 'Awake', '40m') + fact('nappy', 'Nappy', '1h 10m')
def more(open_=False): return f'<span style="width:34px;height:34px;border-radius:17px;background:var(--fi);display:inline-grid;place-items:center;transform:rotate({45 if open_ else 0}deg)">{glyph("more", 18)}</span>'
def chip(g, t, c=None): return f'<div style="background:{c or "#EFE8D8"};border-radius:14px;padding:8px 4px 6px;text-align:center"><div>{glyph(g, 20)}</div><div style="font-weight:600;font-size:11.500px">{t}</div></div>'
def drawer(items, c): return f'<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px;margin-top:9px">{"".join(chip(g, t, c) for g, t in items)}</div>'
BABY = [('solids', 'Solids'), ('health', 'Health'), ('bath', 'Bath'), ('weight', 'Weight'), ('play', 'Play'), ('more', 'All')]
KID = [('health', 'Health'), ('bath', 'Bath'), ('play', 'Play'), ('more', 'All')]
def ccard(l, c, name, age, facts, nxt, button, extra='', tight=False):
    base = card(l, c, name, age, facts, nxt, button, tight=tight)
    return base[:base.rindex('</div>')] + extra + '</div>'
def both(): return f'<div style="display:flex;align-items:center;gap:8px;background:#EAE2D2;border-radius:16px;padding:9px 12px;margin-top:2px;font-size:13px;font-weight:600"><span style="display:flex">{badge("B", MINT, 22)}<span style="margin-left:-6px">{badge("O", SKY, 22)}</span></span>Log for everyone<span style="margin-left:auto;color:#6B5E52;font-weight:500">Bath, a meal, a walk</span></div>'
def split(g, t, people): return f'<div style="flex:1;background:#EAE2D2;border-radius:18px;padding:10px 0 9px;text-align:center"><div>{glyph(g, 22)}</div><div style="font-weight:650;font-size:13px">{t}</div><div style="display:flex;justify-content:center;gap:5px;margin-top:5px">{"".join(badge(l, c, 24) for l, c in people)}</div></div>'
B, O, K = ('B', MINT), ('O', SKY), ('K', SHELL)
one = phone(ccard('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep')) +
            '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">' + ''.join(tile(g, t).replace('flex:1;', '') for g, t in BABY[:6]) + '</div>')
closed = phone(ccard('B', MINT, 'Bea', '2½', bea, '', more()) + ccard('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep') + '<span style="width:6px"></span>' + more()) + both())
opened = phone(ccard('B', MINT, 'Bea', '2½', bea, '', more()) + ccard('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep') + '<span style="width:6px"></span>' + more(True), drawer(BABY, None)) + both())
three = phone(ccard('B', MINT, 'Bea', '2½', bea, '', more(), tight=True) + ccard('K', SHELL, 'Kit', '5mo', kit, 'Next sleep around 1:50', btn('Start sleep') + '<span style="width:6px"></span>' + more(), tight=True)
              + ccard('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep') + '<span style="width:6px"></span>' + more(), tight=True) + both())
alt = phone(ccard('B', MINT, 'Bea', '2½', bea, '', '') + ccard('O', SKY, 'Ollie', '5mo', ollie, 'Next feed around 2:30', btn('Start sleep')) +
            f'<div style="display:flex;gap:8px">{split("solids", "Solids", [B, O])}{split("health", "Health", [B, O])}{split("bath", "Bath", [B, O])}</div>')
def col(t, d, p, tag=''): return f'<div style="width:330px"><div style="font-weight:700;font-size:15.500px">{t} <span style="font-weight:600;font-size:12px;color:#3C9A5F">{tag}</span></div><p style="margin:2px 0 10px;color:#6B5E52;font-size:13px;min-height:72px">{d}</p>{p}</div>'
html = f"""<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#E4DCC8;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1800px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Today: where everything else is logged</h1>
<p style="margin:0 0 20px;color:#6B5E52;font-size:17px;max-width:120ch">Drawn, not built. The shared tiles (Nappy, Solids, Health) say what, then ask who. With two children that is backwards: a parent starts from the child. So the rest of the actions move onto the child they belong to.</p>
<div style="display:flex;gap:26px;align-items:flex-start">
{col('One child', 'Nothing to choose between, so their tiles sit open under the card, as you said: for one child this style works for all of their actions.', one, 'Recommended')}
{col('Two children, closed', 'Each card has its three facts and a plus. The page is two cards and one line, so both children are in view without scrolling.', closed, 'Recommended')}
{col('Two children, one opened', 'The plus opens that child’s other actions in place. Opening one closes the other. The tiles sit inside that child’s card, so it is clear whose they are.', opened, 'Recommended')}
{col('Three children', 'The same, tighter. Three cards still fit above the fold.', three, 'Recommended')}
{col('The other way: a badge on every tile', 'Keep shared tiles, with a badge to tap for each child. It works for two, gets tight at three and fails at four, and every tile repeats every child.', alt)}
</div>
<div style="display:flex;gap:44px;margin-top:22px;font-size:14px;max-width:1500px">
<div style="flex:1"><b>The rule</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Who first, then what. Every action starts from a child.</li><li>The three things asked most often are always showing, as facts.</li><li>Everything else is one tap away, under that child.</li><li>“Log for everyone” is for the things siblings do together. The sheet already lets one entry go to several children.</li></ul></div>
<div style="flex:1"><b>What goes</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>The shared tiles under the cards, and the “Tiles on Today” setting that arranges them, once there are two or more children.</li><li>“More in each child’s panel: tap their name.” The plus says it.</li></ul></div>
<div style="flex:1"><b>For you to decide</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Whether a parent can still choose which actions show first under each child.</li><li>Whether “Log for everyone” earns its place, or belongs inside the sheet only.</li></ul></div></div>
</body>"""
open(OUT, 'w').write(html)
print('wrote', OUT)
