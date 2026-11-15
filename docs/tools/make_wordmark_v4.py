"""Puggle wordmark, B1 v4: four fixes to Tom's v3 (15 November 2026). Writes the SVGs and a comparison sheet
into docs/previews/logo/wordmark-B1/.

    python3 docs/tools/make_wordmark_v4.py docs/previews/logo/wordmark-B1/puggle_B1_v3.svg

It also writes the app's copy, the image `Wordmark` in the asset catalogue: the same letters in black, trimmed
to their edges, for the app to tint.
"""
import os, re, sys
HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'logo', 'wordmark-B1')
V3 = open(sys.argv[1]).read()
glyphs = dict((i, (t, d)) for i, t, d in re.findall(r'id="(glyph[^"]+)" transform="translate\(([\d.]+),0\)"><path d="([^"]+)"', V3))
INK, PAPER = '#3A2A20', '#FBF6E9'

G = glyphs['glyph-03-g'][1]
# 1. The ear: a plain round-topped stem, built like the p's, in place of the bulge that tapered back in.
ear_old = 'C 405 149 412 146 420 146 C 430 146 437 153 437 163 C 437 168 435 171 434 176 L 434 250'
ear_new = 'C 404.5 152.5 410 149 417 149 C 427 149 434 156.5 434 167 L 434 250'
# 3. The tail: ends lower and further in, at the weight of the other strokes, so it no longer crowds the bowl.
tail_old = 'C 342 313 318 303 311 286 C 306 276 310 262 319 258 C 328 253 336 255 343 266 C 350 275 360 279 373 279 C 387 279 399 270 399 255'
tail_new = 'C 346 313 326 305 318 291 C 313 282 316 271 324 267 C 332 263 340 265 346 272 C 352 277 361 280 373 280 C 387 280 399 270 399 255'
assert ear_old in G and tail_old in G
G4 = G.replace(ear_old, ear_new).replace(tail_old, tail_new)
# 2. The e: a taller counter with round corners, and a bar of one thickness. The slant stays.
E = glyphs['glyph-06-e'][1]
eye_old = 'M 644 191 C 648 180 659 173 670 173 C 681 173 687 180 688 189 Z'
eye_new = 'M 650 193.5 L 685 188.7 C 689 188.2 691 185 690 181.5 C 687.5 175 680 171.5 670 171.5 C 659 171.5 649.5 178 645.5 187 C 644 190.5 646.5 194 650 193.5 Z'
assert eye_old in E
E4 = E.replace(eye_old, eye_new)
# 4. Spacing: 7 between a straight side and a round one, 11 between two straight sides (g and l).
MOVE = {'glyph-01-p': 0, 'glyph-02-u': 2, 'glyph-03-g': 4, 'glyph-04-g': 127, 'glyph-05-l': 8, 'glyph-06-e': 8}
PATH = {'glyph-03-g': G4, 'glyph-04-g': G4, 'glyph-06-e': E4}

def mark(colour, v4=True):
    out = ''
    for gid, (t, d) in glyphs.items():
        x, path = (MOVE[gid], PATH.get(gid, d)) if v4 else (t, d)
        out += f'<g id="{gid}" transform="translate({x},0)"><path d="{path}" fill-rule="evenodd"/></g>'
    return f'<g fill="{colour}">{out}</g>'

def svg(body, width=None, vb='65 90 688 232', extra=''):
    size = f' width="{width}"' if width else ' width="1376" height="464"'
    return f'<svg xmlns="http://www.w3.org/2000/svg"{size} viewBox="{vb}" role="img" aria-label="puggle"{extra}>{body}</svg>'

open(os.path.join(HERE, 'puggle_B1_v4.svg'), 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n' + svg('<title>Puggle wordmark, B1 v4</title>' + mark(INK)))
open(os.path.join(HERE, 'puggle_B1_v4_reversed.svg'), 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n' + svg('<title>Puggle wordmark, B1 v4, reversed</title>' + mark(PAPER)))

asset = os.path.join(HERE, '..', '..', '..', '..', 'app', 'Puggle', 'Resources', 'Assets.xcassets', 'Wordmark.imageset')
os.makedirs(asset, exist_ok=True)
open(os.path.join(asset, 'Wordmark.svg'), 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="653" height="218" viewBox="75 95 653 218">{mark("#000000")}</svg>')
open(os.path.join(asset, 'Contents.json'), 'w').write('''{
  "images": [{"idiom": "universal", "filename": "Wordmark.svg"}],
  "info": {"author": "xcode", "version": 1},
  "properties": {"preserves-vector-representation": true, "template-rendering-intent": "template"}
}
''')

old, new = mark('#332116', False), mark(INK)
ghost = lambda: mark('#E5553B', False) + mark(INK).replace(f'fill="{INK}"', f'fill="{INK}" fill-opacity="0.82"')
crop = lambda body, vb, w: svg(body, w, vb)
sizes = lambda body: ''.join(svg(body, w) for w in (240, 160, 110, 72, 48, 32))
html = f'''<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#F2ECDD;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:1300px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Puggle wordmark: v3 and v4</h1>
<p style="margin:0 0 20px;color:#6B5E52;font-size:17px;max-width:90ch">Four fixes to v3: the top of each g, the inside of the e, the g tails, and the spacing. The p, u and l are not redrawn.</p>
<div style="display:flex;gap:40px"><div>{svg(old, 610)}<b>v3</b></div><div>{svg(new, 610)}<b>v4</b></div></div>
<div style="margin-top:18px">{svg(ghost(), 1240)}<div><b>Laid over each other.</b> Red is v3 showing from behind v4: where the drawing was taken away, and how far letters moved.</div></div>
<div style="display:flex;gap:26px;margin-top:22px">
<div>{crop(old, '380 135 70 60', 250)}<div>g top, v3</div></div><div>{crop(new, '384 135 70 60', 250)}<div>g top, v4</div></div>
<div>{crop(old, '300 235 110 85', 250)}<div>g tail, v3</div></div><div>{crop(new, '304 235 110 85', 250)}<div>g tail, v4</div></div></div>
<div style="display:flex;gap:26px;margin-top:18px">
<div>{crop(old, '612 140 125 130', 250)}<div>e, v3</div></div><div>{crop(new, '611 140 125 130', 250)}<div>e, v4</div></div>
<div style="background:#F4BE2C;padding:26px 30px;border-radius:20px;align-self:center">{svg(new, 300)}</div>
<div style="background:#1B2440;padding:26px 30px;border-radius:20px;align-self:center">{svg(mark(PAPER), 300)}</div></div>
<div style="margin-top:22px"><div style="display:flex;gap:26px;align-items:flex-end">{sizes(old)}<b>v3</b></div><div style="display:flex;gap:26px;align-items:flex-end;margin-top:12px">{sizes(new)}<b>v4</b></div></div>
</body>'''
open(os.path.join(HERE, 'v3-v4.html'), 'w').write(html)
