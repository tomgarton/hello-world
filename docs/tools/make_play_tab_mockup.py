"""A Play tab (15 November 2026): where stamping, the stamp book and, later, Puggle and friends' books would
live if play had a tab of its own. Drawn, not built. Writes docs/previews/play/play-tab.html.

    python3 docs/tools/make_play_tab_mockup.py
"""
import os
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'play', 'play-tab.html')
os.makedirs(os.path.dirname(OUT), exist_ok=True)
PUGGLE = open(os.path.join(HERE, '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets', 'PuggleStill.imageset', 'PuggleStill.svg')).read()
PUGGLE = PUGGLE[PUGGLE.index('<svg'):]
SKY, MINT, SHELL, WATTLE, INK, MUTED, PAPER, SAND, FIELD = '#BFD9F5', '#CFE5D2', '#F3D9C9', '#F4BE2C', '#3A2A20', '#6B5E52', '#FBF6E9', '#F2ECDD', '#EAE2D2'

def puggle(h): return f'<span style="display:inline-block;height:{h}px">{PUGGLE.replace("<svg", f"<svg style=&quot;height:{h}px;width:auto&quot;", 1).replace("&quot;", chr(34))}</span>'
def svg(d, s=22, fill='none'): return f'<svg viewBox="0 0 24 24" width="{s}" height="{s}" fill="{fill}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{d}</svg>'
ICON = {'today': '<path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1z"/>', 'history': '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 3v4M15 3v4"/>',
        'insights': '<path d="M6 20v-6M12 20V6M18 20v-9"/>', 'family': '<circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.500"/><path d="M3 20a6 6 0 0 1 12 0M15 20a4 4 0 0 1 6-3.500"/>',
        'play': '<path d="M12 3l2.600 5.600 6 .700-4.500 4.100 1.300 6-5.400-3.100-5.400 3.100 1.300-6L3.400 9.300l6-.700z"/>', 'book': '<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11"/>'}
def tabs(names, on):
    cells = ''.join(f'<div style="flex:1;text-align:center;padding:7px 0 5px;border-radius:22px;{"background:" + FIELD if n == on else ""};font-size:10.500px;font-weight:650">{svg(ICON[n.lower()], 21)}<div>{n}</div></div>' for n in names)
    return f'<div style="position:absolute;left:14px;right:14px;bottom:14px;background:{PAPER};border-radius:28px;padding:5px;display:flex;box-shadow:0 6px 18px rgba(0,0,0,.14)">{cells}</div>'
def phone(body, bar, title='Play'):
    return (f'<div style="width:330px;height:700px;background:{SAND};border-radius:40px;overflow:hidden;border:1px solid #DDD2BC;position:relative">'
            f'<div style="padding:54px 16px 0"><div style="font-weight:800;font-size:30px;letter-spacing:-.02em;margin-bottom:10px">{title}</div>{body}</div>{bar}</div>')
def badge(l, c, s=30): return f'<span style="width:{s}px;height:{s}px;border-radius:50%;background:{c};font-weight:800;font-size:{s*.45:.0f}px;display:inline-grid;place-items:center;flex:none">{l}</span>'
def star(c, s=26): return f'<span style="color:{c}">{svg(ICON["play"], s, fill=c)}</span>'
def hero(tall=True):
    h = 166 if tall else 108
    return (f'<div style="background:{WATTLE};border-radius:26px;height:{h}px;position:relative;overflow:hidden;margin-bottom:12px">'
            f'<div style="position:absolute;left:16px;top:{18 if tall else 14}px"><div style="font-weight:800;font-size:{22 if tall else 19}px;letter-spacing:-.01em">Stamp and draw</div>'
            + (f'<div style="font-size:13px;margin-top:2px;max-width:150px">Hand over the phone. Hold the cross to come back.</div>' if tall else '') +
            f'<span style="display:inline-block;margin-top:{12 if tall else 10}px;background:{INK};color:{PAPER};font-weight:700;font-size:14px;padding:8px 16px;border-radius:18px">Play</span></div>'
            f'<div style="position:absolute;right:14px;bottom:-8px">{puggle(h - 22)}</div></div>')
def head(t, tag=''): return f'<div style="font-weight:700;font-size:14px;margin:4px 2px 7px;display:flex;justify-content:space-between"><span>{t}</span><span style="color:{MUTED};font-weight:600;font-size:12px">{tag}</span></div>'
def stampbook(l, c, name, done, total=5):
    stars = ''.join(star('#D8432F' if i < done else '#D9CFBB') for i in range(total))
    return (f'<div style="background:{PAPER};border-radius:20px;padding:11px 13px;margin-bottom:8px"><div style="display:flex;align-items:center;gap:9px">{badge(l, c)}'
            f'<b style="font-weight:650;font-size:15px;flex:1">{name}\'s stamp book</b><span style="color:{MUTED};font-size:12.500px">{done} of {total}</span></div>'
            f'<div style="display:flex;gap:9px;margin-top:9px;justify-content:space-between;padding:0 4px">{stars}</div></div>')
def stickers():
    foil = ['linear-gradient(135deg,#F7D96B,#E9A93A)', 'linear-gradient(135deg,#9FD8E8,#4E9BC4)', 'linear-gradient(135deg,#F2B8C6,#D9658A)', 'linear-gradient(135deg,#BFE3C3,#5FA873)']
    dots = ''.join(f'<span style="width:52px;height:52px;border-radius:50%;background:{f};display:inline-grid;place-items:center;color:rgba(58,42,32,.75);box-shadow:inset 0 0 0 3px rgba(255,255,255,.5)">{svg(ICON["play"], 22)}</span>' for f in foil)
    return f'<div style="background:{PAPER};border-radius:20px;padding:11px 13px;display:flex;gap:10px;align-items:center">{dots}<span style="margin-left:auto;color:{MUTED};font-size:12.500px">All</span></div>'
def cover(t, c, kind, w=96):
    return (f'<div style="width:{w}px;flex:none"><div style="height:{int(w*1.28)}px;border-radius:14px;background:{c};position:relative;overflow:hidden;box-shadow:0 3px 8px rgba(0,0,0,.1)">'
            f'<div style="position:absolute;left:9px;top:9px;right:9px;font-weight:800;font-size:13px;line-height:1.15;letter-spacing:-.01em">{t}</div>'
            f'<div style="position:absolute;right:4px;bottom:-6px;opacity:.95">{puggle(int(w*.62))}</div></div>'
            f'<div style="font-size:11px;color:{MUTED};margin-top:4px">{kind}</div></div>')
def shelf(items): return f'<div style="display:flex;gap:10px;overflow:hidden;margin-bottom:10px">{"".join(cover(*i) for i in items)}</div>'
def play_row(): return (f'<div style="background:{PAPER};border-radius:20px;padding:12px 14px;display:flex;align-items:center;gap:10px"><span>{svg(ICON["play"], 20)}</span>'
                        f'<div style="flex:1"><b style="font-weight:650">Play</b><div style="font-size:12px;color:{MUTED}">Stamps and drawing</div></div><span style="color:{MUTED}">›</span></div>')
def childcard(l, c, name, age, line): return (f'<div style="background:{PAPER};border-radius:22px;padding:13px;margin-bottom:9px;display:flex;align-items:center;gap:10px">{badge(l, c, 40)}'
                                              f'<div style="flex:1"><b style="font-weight:650;font-size:16px">{name}</b> <span style="color:{MUTED};font-size:13px">· {age}</span><div style="font-size:12.500px;color:{MUTED}">{line}</div></div></div>')

FIVE, FOUR = ['Today', 'History', 'Insights', 'Play', 'Family'], ['Today', 'History', 'Insights', 'Family']
now = phone(hero() + head('Stamp books') + stampbook('B', MINT, 'Bea', 3) + head('Stickers', '4 earned') + stickers(), tabs(FIVE, 'Play'))
later = phone(hero(False) + head('Stories', 'Read aloud') + shelf([('Puggle and the puddle', SKY, 'Story'), ('The windy washing day', MINT, 'Story'), ('Goodnight, billabong', '#D6CFEA', 'Story')])
              + head('Lift the flap') + shelf([('Where is Spike?', SHELL, 'Lift the flap'), ('Who lives in the burrow?', '#F1E1A6', 'Lift the flap'), ('What is in the bag?', SKY, 'Lift the flap')])
              + head('Stamp books') + stampbook('B', MINT, 'Bea', 3), tabs(FIVE, 'Play'))
asnow = phone('<div style="color:#6B5E52;font-size:13.500px;margin:-6px 0 11px">Afternoon. 3 things logged today.</div>' + childcard('O', SKY, 'Ollie', '5mo', 'Bottle · 150 ml · 1h 29m ago')
              + childcard('B', MINT, 'Bea', '2½', 'Potty · Wee · 1h 05m ago') + play_row(), tabs(FOUR, 'Today'), 'Sunday 15 November'.replace('Sunday ', ''))
def col(t, d, p, tag='', colour='#3C9A5F'): return f'<div style="width:330px"><div style="font-weight:700;font-size:15.500px">{t} <span style="font-weight:600;font-size:12px;color:{colour}">{tag}</span></div><p style="margin:2px 0 10px;color:{MUTED};font-size:13px;min-height:92px">{d}</p>{p}</div>'
html = f"""<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#E4DCC8;font:15px/1.4 -apple-system,system-ui,sans-serif;color:{INK};width:1120px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">A tab for play</h1>
<p style="margin:0 0 20px;color:{MUTED};font-size:17px;max-width:100ch">Drawn, not built. Stamping is the thing a child asks for, and it is three taps deep in a parent's app. A tab would give it, the stamp book and the stickers one home, with room for Puggle and friends' books later.</p>
<div style="display:flex;gap:30px;align-items:flex-start">
{col('As built today', 'Four tabs. Play is a row on Today that opens the pad. The stamp book is on each child’s page under Family, and stickers are beside it.', asnow, 'Built')}
{col('A Play tab, with what exists now', 'One big button into the pad, with Puggle on it. Under it, each child’s stamp book and the stickers they have earned. A family with only a baby sees the button and nothing else.', now, 'Idea', '#C2412A')}
{col('The same tab, once there are books', 'The button gets smaller and shelves take the room: stories to read aloud and lift-the-flap books, then the stamp books. Each cover opens full screen, protected as the pad is.', later, 'Idea', '#C2412A')}
</div>
<div style="display:flex;gap:40px;margin-top:22px;font-size:14px;max-width:1080px">
<div style="flex:1"><b>For it</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>One tap from anywhere to the thing a child asks for.</li><li>The stamp book and stickers stop being hidden under Family.</li><li>Books have somewhere to go without another rearrangement later.</li></ul></div>
<div style="flex:1"><b>Against it</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Five tabs in an app for parents, one of them for a child.</li><li>With only the pad and one stamp book it is a thin page.</li><li>A family with a young baby has no use for it yet.</li></ul></div>
<div style="flex:1"><b>For you to decide</b><ul style="margin:6px 0 0;padding-left:18px;color:#4A3B30"><li>Add the tab now, or when the first book is ready.</li><li>Whether it shows for every family, or only once a child is old enough to play (about 18 months) or is potty training.</li><li>Its name: Play, or Puggle.</li></ul></div></div>
</body>"""
open(OUT, 'w').write(html)
print('wrote', OUT)
