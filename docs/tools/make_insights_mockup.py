"""Insights, reviewed against Gentler Streak and Apple Fitness (16 November 2026): a mock-up of where it could go.

Writes docs/previews/insights/next.html. Drawn, not built. Sample family only: Ollie (5 months) and Bea (2 and a half).
"""
import math, os, random
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'insights')
INK, MUTED, PAPER, SAND, FIELD = '#3A2A20', '#7A6B5E', '#FBF6E9', '#F2ECDD', '#EAE2D2'
SLEEP, FEED, NAPPY, SOLID, NIGHT = '#5B7FBF', '#D9A441', '#4F9D8E', '#E5825F', '#1B2440'
random.seed(4)


def band_chart(w=318, h=150):
    """Each day a dot; behind them the child's own usual range, as Gentler Streak's Activity Path does."""
    days = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon']
    vals = [12.4, 12.9, 13.3, 12.1, 13.6, 14.4, 12.7]
    lo, hi = 11.8, 13.7
    top, bot, y0, y1 = 16.0, 10.0, 8, h - 26
    y = lambda v: y0 + (top - v) / (top - bot) * (y1 - y0)
    xs = [22 + i * (w - 60) / 6 for i in range(7)]
    wave = lambda base, amp: ' '.join(f'{"M" if i == 0 else "L"}{x:.1f} {y(base) + math.sin(i * 1.3) * amp:.1f}' for i, x in enumerate([0] + xs + [w - 30]))
    upper = wave(hi, 3)
    lower = ' '.join(f'L{x:.1f} {y(lo) + math.cos(i * 1.1) * 3:.1f}' for i, x in reversed(list(enumerate([0] + xs + [w - 30]))))
    s = f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
    s += f'<path d="{upper} {lower} Z" fill="{SLEEP}" opacity=".18"/>'
    for v in (10, 13, 16):
        s += f'<text x="{w - 2}" y="{y(v) + 4:.0f}" font-size="11" fill="{MUTED}" text-anchor="end">{v}h</text>'
    pts = ' '.join(f'{x:.1f},{y(v):.1f}' for x, v in zip(xs, vals))
    s += f'<polyline points="{pts}" fill="none" stroke="{SLEEP}" stroke-width="2" stroke-linejoin="round" opacity=".55"/>'
    for i, (x, v) in enumerate(zip(xs, vals)):
        out = v > hi or v < lo
        last = i == 6
        s += f'<circle cx="{x:.1f}" cy="{y(v):.1f}" r="{7 if last else 5}" fill="{PAPER if last else (SOLID if out else SLEEP)}" stroke="{SOLID if out else SLEEP}" stroke-width="{3 if last else 0}"/>'
        s += f'<text x="{x:.1f}" y="{h - 6}" font-size="11" fill="{MUTED}" text-anchor="middle" font-weight="{700 if last else 400}">{days[i]}</text>'
    s += f'<text x="4" y="{y(hi) - 7:.0f}" font-size="10.5" fill="{SLEEP}" font-weight="600">Ollie’s usual</text></svg>'
    return s


def ring(parts, size=92, width=15, centre='', sub=''):
    """A ring of rounded blocks with gaps, as in the reference Tom liked."""
    r, total, a, s = (size - width) / 2, sum(v for v, _ in parts), -90.0, f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}">'
    for v, colour in parts:
        sweep = 360 * v / total - 9
        x0, y0 = size / 2 + r * math.cos(math.radians(a + 4.5)), size / 2 + r * math.sin(math.radians(a + 4.5))
        x1, y1 = size / 2 + r * math.cos(math.radians(a + 4.5 + sweep)), size / 2 + r * math.sin(math.radians(a + 4.5 + sweep))
        s += f'<path d="M{x0:.1f} {y0:.1f}A{r} {r} 0 {1 if sweep > 180 else 0} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{colour}" stroke-width="{width}" stroke-linecap="round"/>'
        a += 360 * v / total
    s += f'<text x="{size / 2}" y="{size / 2 + 2}" font-size="17" font-weight="800" fill="{INK}" text-anchor="middle">{centre}</text>'
    s += f'<text x="{size / 2}" y="{size / 2 + 15}" font-size="9" fill="{MUTED}" text-anchor="middle">{sub}</text></svg>'
    return s


def day_clock(size=280):
    """One usual day round a 24-hour clock: when Ollie is usually asleep, and when the feeds fall."""
    c, r = size / 2, size / 2 - 40
    s = f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}"><circle cx="{c}" cy="{c}" r="{r}" fill="none" stroke="{FIELD}" stroke-width="22"/>'
    arc = lambda h0, h1, colour, wd, op=1: (lambda a0, a1: f'<path d="M{c + r * math.cos(a0):.1f} {c + r * math.sin(a0):.1f}A{r} {r} 0 {1 if (h1 - h0) % 24 > 12 else 0} 1 {c + r * math.cos(a1):.1f} {c + r * math.sin(a1):.1f}" fill="none" stroke="{colour}" stroke-width="{wd}" stroke-linecap="round" opacity="{op}"/>')(math.radians(h0 * 15 - 90), math.radians(h1 * 15 - 90))
    s += arc(19.2, 30.5, NIGHT, 22) + arc(9.3, 10.6, SLEEP, 22) + arc(13.0, 14.8, SLEEP, 22) + arc(16.6, 17.1, SLEEP, 22, .6)
    for h in (6.8, 10.9, 15.0, 18.6, 23.0, 3.2):
        a = math.radians(h * 15 - 90)
        s += f'<circle cx="{c + (r - 24) * math.cos(a):.1f}" cy="{c + (r - 24) * math.sin(a):.1f}" r="5" fill="{FEED}"/>'
    for h, label in ((0, 'Midnight'), (6, '6 am'), (12, 'Noon'), (18, '6 pm')):
        a = math.radians(h * 15 - 90)
        s += f'<text x="{c + (r + 21) * math.cos(a):.1f}" y="{c + (r + 21) * math.sin(a) + 4:.1f}" font-size="10.5" fill="{MUTED}" text-anchor="middle">{label}</text>'
    # now
    a = math.radians(14.2 * 15 - 90)
    s += f'<circle cx="{c + r * math.cos(a):.1f}" cy="{c + r * math.sin(a):.1f}" r="7" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
    s += f'<text x="{c}" y="{c - 4}" font-size="22" font-weight="800" fill="{INK}" text-anchor="middle">Asleep</text><text x="{c}" y="{c + 14}" font-size="11" fill="{MUTED}" text-anchor="middle">about now, most days</text></svg>'
    return s


def stack(values, colours, w=132, h=46):
    total, x, s = sum(values), 0, f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
    for v, colour in zip(values, colours):
        ww = w * v / total
        s += f'<rect x="{x + 1:.1f}" y="0" width="{ww - 2:.1f}" height="{h}" rx="7" fill="{colour}"/>'
        x += ww
    return s + '</svg>'


def grid(n, colour, cols=11, cell=11):
    rows = (n + cols - 1) // cols
    s = f'<svg viewBox="0 0 {cols * cell} {rows * cell}" width="{cols * cell}" height="{rows * cell}">'
    for i in range(n):
        s += f'<rect x="{i % cols * cell + 1}" y="{i // cols * cell + 1}" width="{cell - 3}" height="{cell - 3}" rx="2.5" fill="{colour}" opacity="{1 if i < n - 7 else .45}"/>'
    return s + '</svg>'


def bars(vals, colour, w=132, h=46):
    m, bw, s = max(vals), w / len(vals), f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
    for i, v in enumerate(vals):
        s += f'<rect x="{i * bw + 2:.1f}" y="{h - h * v / m:.1f}" width="{bw - 4:.1f}" height="{h * v / m:.1f}" rx="4" fill="{colour}" opacity="{1 if i == len(vals) - 1 else .5}"/>'
    return s + '</svg>'


chip = lambda arrow, text: f'<span class="cmp"><b>{arrow}</b>{text}</span>'
card = lambda label, lead, big, cmp_, art: f'<div class="card"><div class="lab">{label}</div><div class="lead">{lead}</div><div class="bigrow">{big}</div>{cmp_}<div class="art">{art}</div></div>'

legend = lambda items: '<div class="leg">' + ''.join(f'<span><i style="background:{c}"></i>{t}</span>' for t, c in items) + '</div>'
top = f'''<div class="chips"><span class="child on"><i style="background:#BFD9F5">O</i>Ollie</span><span class="child"><i style="background:#F3D9C9">B</i>Bea</span></div>
<div class="seg"><span class="on">Week</span><span>Month</span><span>Year</span></div>'''
phone1 = f'''{top}
<div class="hero"><div class="lab">Sleep · 10 to 16 Nov</div>
<div class="heroline"><b>13h 05m</b><span>a day</span></div>
<div class="typ"><i style="background:{SLEEP}"></i>Within Ollie’s usual</div>
{band_chart()}
<div class="metrics"><span class="on">Sleep</span><span>Feeds</span><span>Milk</span><span>Nappies</span></div></div>
<div class="h2">This week</div>
<div class="two">
{card('NIGHTS', 'The longest stretch was', '<b>7h 35m</b>', chip('↑', '40 min longer than last week'), bars([5.2, 6.1, 5.8, 6.4, 6.9, 7.2, 7.6], NIGHT))}
{card('DAY AND NIGHT', 'Ollie slept by day for', '<b>3h 10m</b>', chip('=', 'About the same'), stack([9.9, 3.2], [NIGHT, SLEEP]) + legend([('Night', NIGHT), ('Day', SLEEP)]))}
</div>'''
phone2 = f'''<div class="two" style="margin-top:6px">
{card('MILK', 'Bottles came to', '<b>780 ml</b><small>a day</small>', chip('↓', '60 ml less than last week'), bars([820, 860, 790, 840, 760, 720, 690], FEED) + '<div class="note">The tin suggests about 900 ml</div>')}
{card('FEEDS', 'Ollie fed', '<b>5.4</b><small>times a day</small>', chip('=', 'About the same'), '<div class="rr">' + ring([(26, FEED), (12, SOLID)], centre='38', sub='this week') + legend([('Bottle', FEED), ('Breast', SOLID)]) + '</div>')}
{card('NAPPIES', 'This week there were', '<b>24</b>', chip('=', 'About the same'), grid(24, NAPPY) + legend([('Wet 15', NAPPY), ('Dirty 9', '#8A5A3C')]))}
{card('FIRSTS', 'New this month', '<b>2</b>', '<span class="cmp">Rolled over · First tooth</span>', '<div class="stars">✦ ✦</div>')}
</div>
<div class="h2">Ollie’s usual day</div>
<div class="hero" style="display:grid;place-items:center;padding-bottom:10px">{day_clock()}{legend([('Night sleep', NIGHT), ('Naps', SLEEP), ('Feeds', FEED)])}</div>
<div class="h2">What is changing</div>
<div class="list">
<div><b class="ar up">↑</b><span><b>Sleeping longer at night</b><small>About 40 minutes more than a month ago</small></span></div>
<div><b class="ar">→</b><span><b>Naps are settling into two</b><small>Three a day a month ago</small></span></div>
<div><b class="ar dn">↓</b><span><b>A little less milk</b><small>Solids started on 2 November</small></span></div>
</div>'''
html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Insights, where it could go</title><style>
body{{margin:0;padding:34px;background:#E4DBC8;font:15px/1.35 -apple-system,system-ui,sans-serif;color:{INK};width:1180px}}
h1{{margin:0 0 4px;font-size:30px;letter-spacing:-.02em}}.sub{{color:{MUTED};margin:0 0 22px;max-width:86ch;font-size:16px}}
.row{{display:flex;gap:26px;align-items:flex-start}}.col{{width:370px}}.col h3{{margin:0 0 3px;font-size:16px}}.col p{{margin:0 0 12px;color:{MUTED};font-size:13.5px}}
.phone{{background:{SAND};border-radius:40px;padding:22px 16px 24px;box-shadow:0 0 0 1px #d6ccb6}}
.chips{{display:flex;gap:8px;margin-bottom:12px}}.child{{display:flex;align-items:center;gap:7px;padding:5px 14px 5px 5px;border-radius:22px;background:{PAPER};font-weight:600}}.child.on{{background:{INK};color:{PAPER}}}
.child i{{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;font-style:normal;font-size:12px;font-weight:700;color:{INK}}}
.seg{{display:flex;background:{PAPER};border-radius:22px;padding:4px;margin-bottom:14px}}.seg span{{flex:1;text-align:center;padding:8px 0;border-radius:18px;color:{MUTED};font-weight:600}}.seg .on{{background:{FIELD};color:{INK}}}
.hero{{background:{PAPER};border-radius:24px;padding:16px}}.lab{{font-size:11.5px;font-weight:700;color:{MUTED};letter-spacing:.04em}}
.heroline{{display:flex;align-items:baseline;gap:7px;margin-top:2px}}.heroline b{{font-size:38px;font-weight:800;letter-spacing:-.02em}}.heroline span{{color:{MUTED};font-weight:600}}
.typ{{display:inline-flex;align-items:center;gap:6px;font-weight:600;font-size:13.5px;margin:2px 0 8px;color:{SLEEP}}}.typ i{{width:9px;height:9px;border-radius:50%}}
.metrics{{display:flex;gap:7px;margin-top:10px}}.metrics span{{padding:8px 13px;border-radius:18px;background:{FIELD};font-weight:600;font-size:14px}}.metrics .on{{background:{INK};color:{PAPER}}}
.h2{{font-size:19px;font-weight:800;margin:20px 4px 10px;letter-spacing:-.01em}}
.two{{display:grid;grid-template-columns:1fr 1fr;gap:10px}}.card{{background:{PAPER};border-radius:22px;padding:13px 13px 14px;display:flex;flex-direction:column;min-height:186px}}
.lead{{font-size:13px;color:{MUTED};margin-top:5px}}.bigrow{{display:flex;align-items:baseline;gap:5px}}.bigrow b{{font-size:25px;font-weight:800;letter-spacing:-.02em}}.bigrow small{{color:{MUTED};font-weight:600;font-size:12px}}
.cmp{{font-size:11.5px;color:{MUTED};display:flex;gap:5px;align-items:center;margin-top:2px}}.cmp b{{width:17px;height:17px;border-radius:50%;background:{FIELD};display:grid;place-items:center;color:{INK};font-size:11px}}
.art{{margin-top:auto;padding-top:10px}}.leg{{display:flex;gap:10px;flex-wrap:wrap;font-size:11px;color:{MUTED};margin-top:6px}}.leg i{{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:4px}}
.note{{font-size:11px;color:{MUTED};margin-top:5px}}.rr{{display:flex;align-items:center;gap:8px}}.rr .leg{{flex-direction:column;gap:3px}}.stars{{font-size:30px;color:{FEED};letter-spacing:6px}}
.list{{background:{PAPER};border-radius:22px;padding:4px 14px}}.list div{{display:flex;gap:12px;align-items:center;padding:11px 0;border-bottom:1px solid {FIELD}}}.list div:last-child{{border:0}}
.list span{{display:flex;flex-direction:column}}.list small{{color:{MUTED};font-size:12.5px}}.ar{{width:30px;height:30px;border-radius:50%;background:{FIELD};display:grid;place-items:center;flex:none}}
.ar.up{{background:#CFE5D2}}.ar.dn{{background:#F4E7B0}}
.now img{{width:370px;border-radius:40px;display:block}}
ul{{margin:6px 0 0;padding-left:18px;color:{MUTED};font-size:13.5px}}li{{margin-bottom:4px}}
</style></head><body><h1>Insights, where it could go</h1>
<p class="sub">Drawn, not built. The first phone is Insights as it is. The other two are one screen, top and bottom, taking from Gentler Streak (your own usual range, a recap in cards, plain words) and Apple Fitness (what is changing, with an arrow).</p>
<div class="row">
<div class="col now"><h3>Now</h3><p>Totals for the week and a count of what was logged.</p><div style="height:742px;overflow:hidden;border-radius:40px"><img src="now.png" style="width:1110px;max-width:none"></div>
<ul><li>88h for a week means little; a day is what a parent thinks in.</li><li>No sense of what is usual for Ollie, so no way to see an odd day.</li><li>Nothing set against last week.</li><li>The ring counts entries, which is about the logging, not the baby.</li></ul></div>
<div class="col"><h3>Next, top</h3><p>The week against Ollie’s own usual range, then a recap in cards.</p><div class="phone">{phone1}</div></div>
<div class="col"><h3>Next, further down</h3><p>More cards, a usual day round the clock, and what is changing.</p><div class="phone">{phone2}</div></div>
</div></body></html>'''
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, 'next.html'), 'w').write(html)
print('wrote next.html')
