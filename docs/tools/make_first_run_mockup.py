"""The first-run mock-up: five feature pages and three setup pages on the repeat patterns, in light and dark.

Every piece of the app on a page is drawn here as a clean element of its own, not cropped from a screenshot,
so all of them share one width, corner, shadow and type scale.

Run `python3 docs/tools/make_first_run_mockup.py` from the repo. Writes docs/previews/onboarding/patterned.html.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_patterns as mp

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'previews', 'onboarding', 'patterned.html')


def ic(name, size=22):
    """One of the app's own line icons, in the text colour."""
    svg = open(os.path.join(mp.ICONS, f'icon-{name}-plain.imageset', f'icon-{name}-plain.svg')).read()
    inner = re.sub(r'#000000|#000\b', 'currentColor', svg[svg.index('>') + 1:svg.rindex('</svg>')])
    return f'<svg viewBox="0 0 24 24" width="{size}" height="{size}">{inner}</svg>'


TICK = '<svg viewBox="0 0 24 24" width="18" height="18"><path d="M6 12.5l4 4 8-9" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>'

CSS = '''
@font-face{font-family:'SF Rounded';src:url('file:///System/Library/Fonts/SFNSRounded.ttf');font-weight:100 900}
:root{--ink:#3A2A20;--paper:#FBF6E9;--sand:#F2ECDD;--field:#EAE2D2;--muted:#6B5E52;--line:#DDD2BC;--red:#B23A26;--bar:#2A62B8;--track:#D9CFBB;--input:#FFFCF3;--shadow:rgba(58,42,32,.16)}
.dk{--ink:#EBDDC4;--paper:#2A2420;--sand:#14110F;--field:#3B332D;--muted:#A8998A;--line:#3B332D;--bar:#7FA3DE;--track:#3B332D;--input:#221C18;--shadow:rgba(0,0,0,.4)}
*{box-sizing:border-box}
body{margin:0;background:#E4DCC8;color:#3A2A20;font:15px/1.35 -apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;padding:34px 34px 40px;width:1720px}
h1{font-size:32px;margin:0 0 4px;letter-spacing:-.02em}.lede{color:#6B5E52;font-size:17px;margin:0 0 22px;max-width:120ch}
h2{font-size:20px;margin:26px 0 12px}h2 b{color:#B23A26}
.row{display:flex;gap:26px;align-items:flex-start}.col{width:306px}
.cap{font-weight:700;margin:0 0 8px}.cap span{color:#B23A26;margin-right:6px}.note{color:#6B5E52;font-size:14px;margin:10px 2px 0;min-height:38px}
.phone{width:306px;height:664px;background:var(--sand);color:var(--ink);border-radius:38px;overflow:hidden;position:relative;border:1px solid var(--line)}
.panel{position:absolute;left:0;right:0;top:0;height:300px;display:flex;flex-direction:column;justify-content:center;align-items:center;gap:10px;padding:74px 18px 22px}
.panel.low{height:128px}
.skip{position:absolute;top:38px;right:12px;height:36px;padding:0 15px;border-radius:18px;background:var(--paper);display:grid;place-items:center;font-weight:650;font-size:15px;box-shadow:0 2px 6px var(--shadow)}
.bar{position:absolute;left:18px;right:18px;display:flex;gap:6px}.bar i{flex:1;height:5px;border-radius:3px;background:var(--track)}.bar i.on{background:var(--ink)}
.text{position:absolute;left:18px;right:18px}
.big{font-family:'SF Rounded',ui-rounded,system-ui;font-size:26px;line-height:1.12;font-weight:800;letter-spacing:-.01em;margin:0;height:60px}
.sub{color:var(--muted);font-size:15.5px;line-height:1.38;margin:8px 0 0;text-wrap:balance}
.cta{position:absolute;left:18px;right:18px;bottom:26px;height:52px;border-radius:26px;background:var(--ink);color:var(--sand);display:grid;place-items:center;font-weight:650;font-size:17px}
/* The pieces of the app: one width, one corner, one shadow. */
.pc{width:270px;background:var(--paper);border-radius:20px;box-shadow:0 8px 22px var(--shadow);padding:14px 16px}
.num{font-family:'SF Rounded',ui-rounded,system-ui;font-weight:800}
.q{color:var(--muted);font-size:13.5px;white-space:nowrap}
.tiles{width:270px;display:flex;gap:8px}
.tile{flex:1;height:62px;border-radius:16px;background:var(--paper);box-shadow:0 8px 22px var(--shadow);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;font-size:11.5px;font-weight:650}
.tile.on{background:var(--ink);color:var(--sand)}
.amt{display:flex;align-items:center;justify-content:space-between}.amt b{font-size:36px;line-height:1}.amt b small{font-size:14px;font-weight:600;color:var(--muted)}
.rb{width:44px;height:44px;border-radius:50%;background:var(--field);display:grid;place-items:center;font-size:24px;font-weight:500}
.kid{display:flex;align-items:center;gap:12px;padding:12px 12px 12px 14px}
.kid.asleep{background:#1B2440;color:#FBF6E9}.kid.asleep .q{color:#C9CCE0}
.av{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;font-weight:800;font-size:18px;color:#3A2A20;flex:none}
.kid .who{flex:1;min-width:0}.kid b{font-size:16px}
.pill{height:36px;padding:0 13px;border-radius:18px;background:var(--field);display:grid;place-items:center;font-weight:650;font-size:13.5px;white-space:nowrap}
.pill.moon{background:#F3E0B8;color:#3A2A20}
.rows{padding:4px 16px}.r{display:flex;align-items:center;gap:12px;padding:10px 0}.r+.r{border-top:1px solid var(--line)}
.r .ico{width:34px;height:34px;border-radius:50%;background:var(--field);display:grid;place-items:center;flex:none}
.r .what{flex:1;min-width:0}.r b{font-size:14.5px;font-weight:650}
.chipn{display:inline-block;padding:1px 8px;border-radius:9px;font-size:11.5px;font-weight:700;color:#3A2A20;margin-right:5px}
.bars{display:flex;align-items:flex-end;gap:8px;height:92px;margin-top:10px}.bars i{flex:1;border-radius:6px 6px 3px 3px;background:var(--bar)}
.days{display:flex;gap:8px;margin-top:5px}.days i{flex:1;text-align:center;font-style:normal;font-size:11px;color:var(--muted)}
.ok{width:30px;height:30px;border-radius:50%;background:#CFE5D2;color:#1F6B3C;display:grid;place-items:center;flex:none}
.field{background:var(--input);border-radius:16px;height:52px;display:flex;align-items:center;padding:0 16px;color:var(--muted);font-size:16.5px;margin-top:10px}
.field.set{color:var(--ink)}.field:first-child{margin-top:0}
.chips{display:flex;gap:10px;margin-top:14px}.chips u{text-decoration:none;width:36px;height:36px;border-radius:50%}
'''


def bar(top, n, total):
    return f'<div class="bar" style="top:{top}px">' + ''.join(f'<i class="{"on" if i < n else ""}"></i>' for i in range(total)) + '</div>'


def feature(num, cap, pattern, field, dark, piece, n, big, sub, note, cta='Continue'):
    return f'''<div class="col"><p class="cap"><span>{num}</span>{cap}</p><div class="phone">
 <div class="panel" style="{mp.css(pattern, field, 0.75, dark)}">{piece}</div><div class="skip">Skip</div>{bar(322, n, 5)}
 <div class="text" style="top:346px"><div class="big">{big}</div><p class="sub">{sub}</p></div><div class="cta">{cta}</div></div><p class="note">{note}</p></div>'''


def setup(num, cap, pattern, field, n, big, sub, fields, cta, note):
    return f'''<div class="col"><p class="cap"><span>{num}</span>{cap}</p><div class="phone">
 <div class="panel low" style="{mp.css(pattern, field, 0.75)}"></div><div class="skip">Skip</div>{bar(150, n, 3)}
 <div class="text" style="top:174px"><div class="big">{big}</div><p class="sub">{sub}</p></div>
 <div class="text" style="top:316px">{fields}</div><div class="cta">{cta}</div></div><p class="note">{note}</p></div>'''


def tile(name, label, on=False):
    return f'<div class="tile{" on" if on else ""}">{ic(name, 22)}{label}</div>'


LOG = (f'<div class="tiles">{tile("bottle", "Feed", True)}{tile("sleep", "Sleep")}{tile("nappy", "Nappy")}{tile("potty", "Potty")}</div>'
       '<div class="pc"><div class="q" style="font-weight:650;margin-bottom:6px">Bottle</div>'
       '<div class="amt"><span class="rb">−</span><b class="num">160 <small>ml</small></b><span class="rb">+</span></div></div>')
KIDS = ('<div class="pc kid"><div class="av" style="background:#BFD9F5">H</div><div class="who"><b>Harry</b> <span class="q">· 2½</span><div class="q">Awake · <span class="num">2h</span></div></div><div class="pill">Start sleep</div></div>'
        '<div class="pc kid asleep"><div class="av" style="background:#F3D9C9">S</div><div class="who"><b>Sam</b> <span class="q">· 5mo</span><div class="q">Asleep · <span class="num">42m</span></div></div><div class="pill moon">Woke up</div></div>')


def row(icon, what, kid, colour, who, when):
    return (f'<div class="r"><div class="ico">{ic(icon, 20)}</div><div class="what"><b>{what}</b><div class="q"><span class="chipn" style="background:{colour}">{kid}</span>by {who}</div></div>'
            f'<div class="q">{when}</div></div>')


SHARE = ('<div class="pc rows">' + row('bottle', 'Bottle · 180 ml', 'Sam', '#F3D9C9', 'Nan', '14:52')
         + row('sleep', 'Slept 1h 59m', 'Sam', '#F3D9C9', 'Alex', '12:54') + row('potty', 'Potty · wee', 'Harry', '#BFD9F5', 'Robin', '11:40') + '</div>')
WEEK = ('<div class="pc"><div class="q" style="font-weight:650">Sleep this week</div><div class="num" style="font-size:30px;line-height:1.1">91h</div>'
        '<div class="bars">' + ''.join(f'<i style="height:{h}%"></i>' for h in (84, 84, 90, 88, 96, 92, 60)) + '</div>'
        '<div class="days">' + ''.join(f'<i>{d}</i>' for d in 'MTWTFSS') + '</div></div>')
PRIVATE = ('<div class="pc rows">'
           f'<div class="r"><div class="ok">{TICK}</div><div class="what"><b>No account</b><div class="q">No email or password.</div></div></div>'
           f'<div class="r"><div class="ok">{TICK}</div><div class="what"><b>No ads</b><div class="q">Nothing is sold or shared.</div></div></div>'
           '<div class="r" style="justify-content:space-between"><b>See how your data is kept</b><span class="q">›</span></div></div>')

PAGES = [
    ('Logging', 'pills', 'sun', LOG, 'Log the day<br>in a tap or two', 'Feeds, sleeps, nappies and the potty, with&nbsp;one&nbsp;hand.',
     'The four things logged most, and one of them open.'),
    ('Every child', 'mix', 'sky', KIDS, 'Every child<br>on one screen', 'A baby and a toddler side by side, each&nbsp;with their own sleep&nbsp;timer.',
     'One awake, one asleep, so the timer is in the picture.'),
    ('Together', 'bloom', 'shell', SHARE, 'Share the day<br>with your family', 'Invite a partner, a grandparent or a carer. You&nbsp;choose what each&nbsp;can&nbsp;do.',
     'Three entries by three people.'),
    ('Looking back', 'comb', 'mint', WEEK, 'Look back<br>over the week', 'Totals and patterns for each child, whenever&nbsp;you&nbsp;want&nbsp;them.',
     'One chart, whole, with its days.'),
    ('Private', 'sparkle', 'lilac', PRIVATE, 'Your entries<br>stay private', 'Kept on this iPhone and in iCloud.',
     'The same rows as the entries page.'),
]


def features(dark):
    return ''.join(feature(i + 1, cap, pattern, field, dark, piece, i + 1, big, sub, '&nbsp;' if dark else note,
                           'Set up your family' if i == 4 else 'Continue')
                   for i, (cap, pattern, field, piece, big, sub, note) in enumerate(PAGES))


CHIPS = ('<div class="chips"><u style="background:#BFD9F5;outline:3px solid var(--ink);outline-offset:2px"></u>'
         + ''.join(f'<u style="background:{c}"></u>' for c in ('#F3D9C9', '#CFE5D2', '#F4E7B0', '#E0D3EE', '#F5CEDB')) + '</div>')
SETUP = [
    setup(6, 'You', 'check', 'sand', 1, "Who's logging<br>on this iPhone?", 'Your name shows beside what you log.',
          '<div class="field">Your name</div><div class="field">Family name, if you like</div>', 'Continue', 'A short band, so the keyboard has room.'),
    setup(7, 'First child', 'scales', 'sky', 2, 'Add your<br>first child', 'Their age sets what shows on Today.',
          '<div class="field set">Harry</div><div class="field">Birth date</div>' + CHIPS, 'Add Harry', "The band is the child's own colour."),
    setup(8, 'Anyone else', 'scales', 'shell', 3, 'Anyone else<br>to add?', 'Twins and siblings share one Today.',
          '<div class="pc kid" style="width:auto;box-shadow:none"><div class="av" style="background:#BFD9F5">H</div><div class="who"><b>Harry</b><div class="q">2½ years</div></div></div>'
          '<div class="field set" style="justify-content:center;font-weight:650">Add another child</div>', 'Continue', "The next child's colour."),
]


def main():
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>First run on patterns</title><style>{CSS}{mp.DRIFT}</style></head><body>
<h1>First run on repeat patterns</h1>
<p class="lede">A mock-up, not built. Each piece of the app is drawn as a clean element of its own: one width, one corner, one shadow, one type scale. In a browser the patterns drift slowly down and to the right.</p>
<h2><b>Before setup</b></h2><div class="row">{features(False)}</div>
<h2><b>The same pages in dark mode</b></h2><div class="row dk">{features(True)}</div>
<h2><b>Setup:</b> a short band of pattern, then the question</h2><div class="row">{"".join(SETUP)}</div></body></html>'''
    with open(OUT, 'w') as out: out.write(html)
    print('wrote', os.path.relpath(OUT))


if __name__ == '__main__':
    main()
