"""Activity icons in dark: thinner lines and a yellow from the dark palette (15 November 2026).

Tom: the icons are hard to read in dark. The lines want to be thinner, and the yellow beside the pale line
does not have the contrast it has in light. Drawn, not installed. Writes docs/previews/icons/dark-options.html.

    python3 docs/tools/make_icon_dark_options.py
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_icons as M

OUT = os.path.join(M.OUT, 'dark-options.html')
NAMES = ['bottle', 'nappy', 'potty', 'sleep', 'solids', 'breastfeed']
LABELS = {'bottle': 'Feeding', 'nappy': 'Nappy', 'potty': 'Potty', 'sleep': 'Sleep', 'solids': 'Solids', 'breastfeed': 'Breastfeed'}

def draw(name, line, fill, k, size, regular=True, dim=0.8):
    """One icon in full colour: the accent in `fill`, fixed colours dimmed, the line in `line` at `k` of its weight."""
    spec = M.regular(name) if regular else M.ICONS[name]
    path = lambda d, more: f'<path d="{d}" {more}/>'
    inner = ''.join(path(d, f'fill="{fill}"') for d in spec['wattle'])
    inner += ''.join(path(t[0], f'fill="{M.dimmed(t[1], dim) if dim != 1 else t[1]}"') for t in spec['tint'])
    stroke = f'fill="none" stroke="{line}" stroke-linecap="round" stroke-linejoin="round" stroke-width='
    inner += ''.join(path(d, f'{stroke}"{round(spec.get("weight", M.W) * k, 2)}"') for d in spec['lines'])
    inner += ''.join(path(d, f'{stroke}"{round(spec.get("fineweight", 1.2) * k, 2)}"') for d in spec.get('fine', []))
    inner += ''.join(path(d, f'fill="{line}"') for d in spec['ink'])
    box = spec.get('box', 24)
    if spec['turn']: inner = f'<g transform="rotate({spec["turn"]} {box / 2} {box / 2})">{inner}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {box} {box}" width="{size}" height="{size}">{inner}</svg>'

def tiles(line, fill, k, dark=True, dim=0.8):
    ground, tile, text, sub = ('#14110F', '#231E1A', '#EBDDC4', '#B3A590') if dark else ('#F2ECDD', '#EAE2D2', '#3A2A20', '#6B5E52')
    cells = ''.join(f'<div style="flex:1;background:{tile};border-radius:20px;padding:14px 0 11px;text-align:center">{draw(n, line, fill, k, 40, dim=dim)}'
                    f'<div style="font-weight:650;font-size:14px;color:{text};margin-top:4px">{LABELS[n]}</div></div>' for n in NAMES)
    small = ''.join(f'<span style="display:inline-flex;align-items:center;gap:6px;margin-right:16px;color:{sub};font-size:13px">{draw(n, line, fill, k, 22, regular=False, dim=dim)}{LABELS[n]}</span>' for n in NAMES)
    return f'<div style="background:{ground};border-radius:26px;padding:14px"><div style="display:flex;gap:9px">{cells}</div><div style="margin:12px 4px 2px">{small}</div></div>'

def row(title, note, block, tag=''):
    return (f'<div style="margin-bottom:22px"><div style="font-weight:700;font-size:16px">{title} <span style="font-weight:600;font-size:12px;color:#3C9A5F">{tag}</span></div>'
            f'<p style="margin:2px 0 9px;color:#6B5E52;font-size:13.500px;max-width:95ch">{note}</p>{block}</div>')

PALE = M.DARK
html = f"""<!doctype html><meta charset="utf-8"><body style="margin:0;padding:34px;background:#E4DCC8;font:15px/1.4 -apple-system,system-ui,sans-serif;color:#3A2A20;width:860px">
<h1 style="margin:0 0 4px;font-size:30px;letter-spacing:-.02em">Icons in dark: thinner lines, a darker yellow</h1>
<p style="margin:0 0 22px;color:#6B5E52;font-size:17px;max-width:90ch">Drawn, not installed. Each row is the six main icons as tiles on Today (40 points) and small, as in a list (22 points).</p>
{row('In light, for comparison', 'A dark line beside Wattle: plenty of contrast, and the yellow reads as a fill.', tiles(M.INK, M.WATTLE, 1, dark=False, dim=1))}
{row('In dark, as it is now', 'The line is a fifth thinner than in light. The pale line and the bright yellow are close in lightness, so the yellow reads as part of the line and shapes run together.', tiles(PALE, M.WATTLE, 0.8))}
{row('A. Thinner lines only', 'The line is about two-thirds of its light weight. The yellow is unchanged.', tiles(PALE, M.WATTLE, 0.62))}
{row('B. Thinner lines, deep mustard', 'The yellow drops to a mustard from the dark palette, so it sits back from the pale line as it does in light.', tiles(PALE, '#B8861B', 0.62), 'Recommended')}
{row('C. Thinner lines, dark amber', 'Darker again. The line stands out most here, but the icons lose some of their warmth.', tiles(PALE, '#86641A', 0.62))}
{row('D. Thinnest lines, deep mustard', 'The line at about half its light weight. Finer, but the small list icons start to look faint.', tiles(PALE, '#B8861B', 0.5))}
</body>"""
open(OUT, 'w').write(html)
print('wrote', OUT)
