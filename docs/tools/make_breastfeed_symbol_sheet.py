"""The breastfeeding icon after the International Breastfeeding Symbol, beside the rest of the set (15 November 2026).

Writes docs/previews/icons/breastfeeding-symbol.html. The drawings are `SYMBOL` in make_icons.py.
The symbol itself (Matt Daigle, 2006) is in the public domain; it is shown here for comparison.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_icons as M

K = 26 / 705
REF = ('<svg viewBox="0 0 32 32" width="150" height="150"><g transform="translate(16 3) scale(%s) translate(-512.5 -160)" fill="#2A62B8">'
       '<circle cx="512.2" cy="276.4" r="116"/>'
       '<path fill-rule="evenodd" d="M610.3,423.8c12.7,0,24.2,1.6,34.4,4.9c18.9,6,33.5,17.2,45,30c19.9,22.2,36.3,54.1,54,86  c16.9,30.4,36.4,63.1,36,104c-0.4,40.7-19.9,70.1-40,92c-27.2,29.7-63.2,65.7-118,65c-27.6-0.4-53.4-15.9-49-48  c3.4-24.8,26.1-35.3,40-52c-68.3,7.1-97.8-27.5-124-69c-10.8-17.1-17.7-42-39-46c-42.5-8-37.4,40.9-27,68c3.4,8.9,14.7,24.8,14,32  c-1.2,12.3-25.5,17.3-39,20c-17.4,3.4-38,2.7-51,8c5.1,10.8,18.7,15.6,30,20c11.4,4.4,24.6,8.1,38,11c30.2,6.5,62.6,2.9,93,6  c28,2.9,60,27.8,44,65c-11.7,27.2-46.9,41.9-85,44c-65.2,3.6-143.6-29.9-177-60c-27.6-24.9-48.5-65.3-45-114  c3.4-47.4,26.4-94,45-131c23.3-46.3,43.9-96,85-121c13.4-8.2,32.7-14.9,55-14.9z'
       'M680.2,610.4a80,80 0 1,0 -160,0a80,80 0 1,0 160,0z"/></g></svg>') % K
MUSTARD = '#B8861B'   # Palette.iconYellow in dark


def light(spec, size): return M.svg('x', spec=spec, size=size)


def dark(spec, size):
    """As the app draws it in dark: a line 0.62 as heavy, and the deep mustard in place of Wattle."""
    thin = dict(spec, weight=spec.get('weight', M.W) * M.DARK_LINE)
    return M.svg('x', spec=thin, ink=M.DARK, size=size).replace(M.WATTLE, MUSTARD)


def tiles(first, draw, cls):
    names = [('Breastfeed', first), ('Bottle', M.ICONS['bottle']), ('Nappy', M.ICONS['nappy']),
             ('Sleep', M.ICONS['sleep']), ('Solids', M.ICONS['solids'])]
    return f'<div class="tiles {cls}">' + ''.join(f'<div class="tile">{draw(s, 40)}<b>{n}</b></div>' for n, s in names) + '</div>'


def block(title, text, spec, simple):
    row = ''.join(light(simple, s) for s in (24, 17)) + f'<span class="pl">{M.svg("x", spec=simple, plain=True, size=22).replace("#000000", "#3A2A20")}</span>'
    return (f'<section><div class="top"><div class="big">{light(spec, 150)}</div><div class="big dk">{dark(spec, 150)}</div>'
            f'<div class="words"><h2>{title}</h2><p>{text}</p><div class="r">{row}</div></div></div>'
            f'{tiles(spec, light, "")}{tiles(spec, dark, "dk")}</section>')


def main():
    now = M.ICONS['breastfeed']
    body = block('In the app now', 'The current drawing, for comparison.', now, M.small(now))
    for key, (spec, simple, title, text) in list(M.HELD.items()) + list(M.SYMBOL.items()):
        body += block(title, text, spec, simple)
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Breastfeeding, after the symbol</title><style>
body{{margin:0;padding:30px;background:#EFE7D4;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:760px}}
h1{{margin:0 0 4px;font-size:28px;letter-spacing:-.02em}}h2{{margin:0 0 4px;font-size:19px}}p{{margin:0;color:#6B5E52}}
.lede{{display:flex;gap:18px;align-items:center;margin:14px 0 8px}}.lede .big{{flex:none}}
section{{margin-top:26px;padding-top:22px;border-top:1px solid #D9CFB8}}
.top{{display:flex;gap:14px;align-items:center}}.big{{width:170px;height:170px;border-radius:22px;background:#FBF6E9;display:grid;place-items:center;flex:none}}
.big.dk{{background:#1C1815}}.words{{padding-left:6px}}
.r{{display:flex;align-items:center;gap:12px;margin-top:10px}}.pl{{background:#EAE2D2;border-radius:50%;width:38px;height:38px;display:grid;place-items:center}}
.tiles{{display:flex;gap:8px;margin-top:12px;padding:10px;border-radius:22px}}.tiles.dk{{background:#141110}}
.tile{{width:140px;height:96px;border-radius:20px;background:#FBF6E9;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px}}
.tile b{{font-size:14px}}.dk .tile{{background:#2A2420;color:#EBDDC4}}
</style></head><body><h1>Breastfeeding, a parent and baby</h1>
<div class="lede"><div class="big">{REF}</div><p>The International Breastfeeding Symbol, by Matt Daigle, 2006. Its maker gave it to the public domain, so it can be used and redrawn. Below, after the current icon, are three of a parent holding a wrapped baby and then the symbol redrawn six ways, all for this set: the set&rsquo;s line and weight, round ends, and one spot of colour. Each is shown in light and dark, in the small sizes, in one colour for lists, and on Today tiles beside the bottle, nappy, sleep and solids icons.</p></div>
{body}</body></html>'''
    out = os.path.join(M.OUT, 'breastfeeding-symbol.html')
    open(out, 'w').write(html)
    print('wrote', out)


if __name__ == '__main__':
    main()


def runners():
    """The short list (15 November 2026): the earlier 'Parent and baby', the symbol in line, and held with the wrap in colour."""
    now = M.ICONS['breastfeed']
    body = block('In the app now', 'The current drawing, for comparison.', now, M.small(now))
    for key in ('held-refined', 'held-wrap', 'held-hair'):
        spec, title, text = M.ALTERNATES[key]
        if key == 'held-hair': title, text = 'Before any refining', 'Parent and baby, hair in colour, as it was.'
        body += block(title, text, spec, M.small(spec))
    html = open(os.path.join(M.OUT, 'breastfeeding-symbol.html')).read()
    head = html[:html.index('<body>')]
    out = os.path.join(M.OUT, 'breastfeeding-runners.html')
    open(out, 'w').write(f'{head}<body><h1>Breastfeeding, the short list</h1><p>The one chosen, Parent and baby with hair in colour, refined. Shown with the current icon and as it was before, in light and dark, small, in one colour, and on Today tiles.</p>{body}</body></html>')
    print('wrote', out)



def faces():
    """Eyes or smiles on the chosen drawing (15 November 2026)."""
    body = ''.join(block(title, text, spec, M.small(spec)) for spec, title, text in M.NURSE_FACES.values())
    html = open(os.path.join(M.OUT, 'breastfeeding-symbol.html')).read()
    out = os.path.join(M.OUT, 'breastfeeding-faces.html')
    open(out, 'w').write(f'{html[:html.index("<body>")]}<body><h1>Breastfeeding, the faces</h1><p>The chosen drawing with ten faces. The first two use the tummy time baby&rsquo;s eye; the next three are closed eyes drawn so they cannot be taken for mouths. At 24 points and under, no face is drawn.</p>{body}</body></html>')
    print('wrote', out)


if __name__ == '__main__':
    runners()
    faces()