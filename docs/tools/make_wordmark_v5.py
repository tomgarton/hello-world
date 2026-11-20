"""Puggle wordmark, B1 v5: the e redrawn and the p's descender levelled, on top of v4 (15 November 2026).
A proposal: the app and the brand book still use v4.

    python3 docs/tools/make_wordmark_v5.py docs/previews/logo/wordmark-B1/puggle_B1_v4.svg
"""
import re, sys, os
HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'logo', 'wordmark-B1')
V4 = open(sys.argv[1]).read()
INK = '#3A2A20'
glyphs = [(i, float(t), d) for i, t, d in re.findall(r'id="(glyph[^"]+)" transform="translate\(([\d.]+),0\)"><path d="([^"]+)"', V4)]
E = dict((i, d) for i, t, d in glyphs)['glyph-06-e']
# The e: the eye was a flat bean, smaller than the pocket under the bar, and that pocket was almost shut at the
# right (11 units). The bar now sits lower, so the eye is the bigger space (30 tall, near the size of the round
# counters in the p and g), and the terminal ends sooner, so the opening is 16 to 20.
E5 = ('M 665 147 C 698 147 720 169 720 191 C 720 203 717 211.5 709 212.5 L 644 222 '
      'C 648 229.5 660 234.5 673 234.5 C 681 234.5 688 233.5 693 230.5 C 698 227 706 227 710.5 232 C 715 237 714.5 243 711 247 '
      'C 701 258 684 264 666 264 C 630 265 607 241 607 206 C 607 171 631 147 665 147 Z '
      'M 650 201 L 686 195.5 C 690.5 194.8 693 191 691.5 187 C 688 177 680 171 670 171 C 658 171 648.5 179 645 192.5 C 644 197.5 646.5 201.5 650 201 Z')
def squash(d, k, top=147):
    """Scales heights towards the top of the letter, so the e stops being the tallest round in the word."""
    out, tok, i = [], d.split(), 0
    while i < len(tok):
        if tok[i].isalpha(): out.append(tok[i]); i += 1
        else: out += [tok[i], f'{top + (float(tok[i + 1]) - top) * k:.1f}'.rstrip('0').rstrip('.')]; i += 2
    return ' '.join(out)
E5 = squash(E5, (261 - 147) / (264 - 147))
P = dict((i, d) for i, t, d in glyphs)['glyph-01-p']
# The p's descender: 3 lower, to end level with the g tails.
old = 'L 112 290 C 112 303 103 310 94 310 C 83 310 75 301 75 290'
assert old in P
P5 = P.replace(old, 'L 112 293 C 112 306 103 313 94 313 C 83 313 75 304 75 293')
def mark(colour, v5=True):
    body = ''
    for gid, t, d in glyphs:
        if v5: d = {'glyph-06-e': E5, 'glyph-01-p': P5}.get(gid, d)
        body += f'<g id="{gid}" transform="translate({t:g},0)"><path d="{d}" fill-rule="evenodd"/></g>'
    return f'<g fill="{colour}">{body}</g>'
def svg(body, w, vb='65 90 688 232'): return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" viewBox="{vb}">{body}</svg>'
open(os.path.join(HERE, 'puggle_B1_v5.svg'), 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="1376" height="464" viewBox="65 90 688 232" role="img" aria-label="puggle"><title>Puggle wordmark, B1 v5</title>' + mark(INK) + '</svg>')
open(os.path.join(HERE, 'puggle_B1_v5_reversed.svg'), 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="1376" height="464" viewBox="65 90 688 232" role="img" aria-label="puggle"><title>Puggle wordmark, B1 v5, reversed</title>' + mark('#FBF6E9') + '</svg>')
old4, new5 = mark(INK, False), mark(INK)
neg = lambda m: f'<rect x="0" y="0" width="900" height="400" fill="{INK}"/>' + m.replace(INK, '#F4BE2C')
sizes = lambda b: ''.join(svg(b, w) for w in (240, 160, 110, 72, 48, 32))
html = f'''<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#F2ECDD;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1300px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Puggle wordmark: v4 and v5</h1>
<p style="margin:0 0 20px;color:#6B5E52;font-size:17px;max-width:92ch">The e redrawn, and the p's descender level with the g tails. Nothing else moves.</p>
<div style="display:flex;gap:40px"><div>{svg(old4, 610)}<b>v4</b></div><div>{svg(new5, 610)}<b>v5</b></div></div>
<div style="display:flex;gap:30px;margin-top:22px;align-items:flex-end">
<div>{svg(old4, 300, '606 138 136 136')}<div>e, v4</div></div><div>{svg(new5, 300, '606 138 136 136')}<div>e, v5</div></div>
<div>{svg(neg(old4), 300, '606 138 136 136')}<div>v4, the spaces inside</div></div><div>{svg(neg(new5), 300, '606 138 136 136')}<div>v5, the spaces inside</div></div></div>
<div style="display:flex;gap:30px;margin-top:22px;align-items:center">
<div style="background:#F4BE2C;padding:26px 30px;border-radius:20px">{svg(new5, 300)}</div>
<div style="background:#1B2440;padding:26px 30px;border-radius:20px">{svg(mark('#FBF6E9'), 300)}</div>
</div>
<div style="margin-top:22px"><div style="display:flex;gap:26px;align-items:flex-end">{sizes(old4)}<b>v4</b></div><div style="display:flex;gap:26px;align-items:flex-end;margin-top:12px">{sizes(new5)}<b>v5</b></div></div>
</body>'''
open(os.path.join(HERE, 'v4-v5.html'), 'w').write(html)
