"""Live Activity with more than one child: one family card in place of a card each (15 November 2026).
Drawn, not built. Writes docs/previews/live-activity/family.html.

    python3 docs/tools/make_live_activity_mockup.py
"""
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'live-activity', 'family.html')
SKY, MINT, SHELL = '#BFD9F5', '#CFE5D2', '#F3D9C9'
MOON = '<svg viewBox="0 0 24 24" width="14" height="14" style="vertical-align:-2px"><path d="M19 14.5A8 8 0 0 1 9.5 5a8 8 0 1 0 9.5 9.5Z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/></svg>'
BOTTLE = '<svg viewBox="0 0 24 24" width="14" height="14" style="vertical-align:-2px"><path d="M9 3h6v3H9zM8 9c0-1.5 1-3 4-3s4 1.500 4 3v10a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>'

def badge(letter, colour, size=30, overlap=0):
    return f'<span style="width:{size}px;height:{size}px;border-radius:50%;background:{colour};color:#3A2A20;font-weight:800;font-size:{size * .5:.0f}px;display:inline-grid;place-items:center;flex:none;margin-left:{-overlap}px;box-shadow:0 0 0 2px var(--bg);position:relative;z-index:{0 if overlap else 1}">{letter}</span>'

def row(letter, colour, name, what, figure, button='', dim=False):
    return (f'<div style="display:flex;align-items:center;gap:10px;opacity:{.75 if dim else 1}">{badge(letter, colour)}'
            f'<div style="min-width:0"><div style="font-weight:650;font-size:15.5px;line-height:1.15">{name}</div><div style="color:#F3E0B8;font-size:13.5px;white-space:nowrap">{what}</div></div>'
            f'<div style="margin-left:auto;display:flex;align-items:center;gap:10px"><b style="color:#F3E0B8;font-size:17px;white-space:nowrap">{figure}</b>{button}</div></div>')

def btn(text, filled=True):
    return f'<span style="padding:7px 13px;border-radius:18px;font-weight:650;font-size:13.5px;white-space:nowrap;background:{"#F3E0B8" if filled else "rgba(243,224,184,.16)"};color:{"#3A2A20" if filled else "#F3E0B8"}">{text}</span>'

def lock(rows, extra=''):
    return f'<div style="--bg:#1B2440;width:372px;background:#1B2440;border-radius:26px;padding:14px;box-sizing:border-box;color:#FBF6E9;display:flex;flex-direction:column;gap:11px">{"".join(rows)}{extra}</div>'

def island(left, right):
    return (f'<div style="--bg:#000;width:250px;height:37px;background:#000;border-radius:19px;display:flex;align-items:center;justify-content:space-between;padding:0 9px 0 8px;box-sizing:border-box;color:#F3E0B8;font-weight:650;font-size:12px">'
            f'<span style="display:flex">{left}</span><span>{right}</span></div>')

def watch(lines):
    return f'<div style="--bg:#1C1C1E;width:184px;height:80px;background:#1C1C1E;border-radius:18px;padding:8px 12px;box-sizing:border-box;color:#FBF6E9;display:flex;flex-direction:column;justify-content:center;gap:5px">{"".join(lines)}</div>'

def wline(letter, colour, text):
    return f'<div style="display:flex;align-items:center;gap:6px;font-weight:650;font-size:14px;color:#F3E0B8;white-space:nowrap">{badge(letter, colour, 20)}{text}</div>'

feed_buttons = f'<div style="display:flex;gap:8px">{btn("✓ Left")}{btn("Right", False)}<span style="margin-left:auto">{btn("Finish")}</span></div>'
O, B, K = ('O', SKY), ('B', MINT), ('K', SHELL)
CASES = [
    ('1. One baby', 'As now. The card is theirs alone.',
     lock([row(*O, 'Ollie', 'Awake 1 hr, 11 min', 'Fed 1h 29m')]), island(badge(*O, 22), '1h 29m'), watch([wline(*O, 'Fed 1h 29m ago'), wline(*O, 'Awake 1h 11m')])),
    ('2. A baby, and a toddler napping', 'One row each. The one with something running goes first and keeps its button.',
     lock([row(*B, 'Bea', f'{MOON} Asleep since 12:40', '1h 12m', btn('Woke up')), row(*O, 'Ollie', 'Awake 1 hr, 11 min', 'Fed 1h 29m')]),
     island(badge(*B, 22) + badge(*O, 22, 7), f'{MOON} 1h 12m'), watch([wline(*B, f'{MOON} Asleep 1h 12m'), wline(*O, 'Fed 1h 29m ago')])),
    ('3. The same, with the toddler awake', 'A child over two with nothing running has nothing to show, so the card is the baby\'s again.',
     lock([row(*O, 'Ollie', 'Awake 1 hr, 11 min', 'Fed 1h 29m')]), island(badge(*O, 22), '1h 29m'), watch([wline(*O, 'Fed 1h 29m ago'), wline(*O, 'Awake 1h 11m')])),
    ('4. A feed running, another child asleep', 'The feed takes the card, with its buttons. Everyone else is one quiet line.',
     lock([row(*O, 'Ollie', f'{BOTTLE} Feeding, left', '12:30'), feed_buttons, row(*B, 'Bea', f'{MOON} Asleep', '1h 12m', dim=True)]),
     island(badge(*O, 22) + badge(*B, 22, 7), f'{BOTTLE} 12m'), watch([wline(*O, f'{BOTTLE} Left 12:30'), wline(*B, f'{MOON} Asleep 1h 12m')])),
    ('5. Twins', 'Two rows that read the same way, so they are easy to compare.',
     lock([row(*K, 'Kit', 'Awake 40 min', 'Fed 2h 05m'), row(*O, 'Ollie', 'Awake 1 hr, 11 min', 'Fed 1h 29m')]),
     island(badge(*K, 22) + badge(*O, 22, 7), '2h 05m'), watch([wline(*K, 'Fed 2h 05m ago'), wline(*O, 'Fed 1h 29m ago')])),
    ('6. Three or more', 'Three rows is all the Lock Screen has height for. The rest are counted, and the app has them all.',
     lock([row(*B, 'Bea', f'{MOON} Asleep since 12:40', '1h 12m', btn('Woke up')), row(*K, 'Kit', 'Awake 40 min', 'Fed 2h 05m'), row(*O, 'Ollie', 'Awake 1 hr, 11 min', 'Fed 1h 29m')],
          '<div style="font-size:12.5px;color:rgba(251,246,233,.7);text-align:center">and 1 more in Puggle</div>'),
     island(badge(*B, 22) + badge(*K, 22, 7) + badge(*O, 22, 7), f'{MOON} 1h 12m'), watch([wline(*B, f'{MOON} Asleep 1h 12m'), wline(*K, 'Fed 2h 05m ago  +2')])),
]
cells = ''.join(f'<div style="width:400px"><h3 style="margin:0 0 2px;font-size:17px">{t}</h3><p style="margin:0 0 10px;color:#6B5E52;font-size:13.5px;min-height:38px">{d}</p>{l}'
                f'<div style="display:flex;gap:12px;align-items:center;margin-top:10px">{i}</div><div style="margin-top:10px">{w}</div></div>' for t, d, l, i, w in CASES)
html = f'''<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#F2ECDD;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1300px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Live Activity for a family: one card, a row for each child</h1>
<p style="margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:100ch">Drawn, not built. Each case shows the Lock Screen card, the closed Dynamic Island and the Apple Watch card. Today each child has a card of their own, which iOS stacks and collapses as it likes.</p>
<div style="display:flex;flex-wrap:wrap;gap:34px 34px">{cells}</div>
<p style="margin:26px 0 0;color:#6B5E52;font-size:14px;max-width:110ch"><b style="color:#3A2A20">Who goes first:</b> a running feed, then a running sleep, then whoever was fed longest ago. The closed island shows that child's number, with everyone's badges on the left. Only the first row has a button.</p>
</body>'''
open(OUT, 'w').write(html)
print('wrote', OUT)
