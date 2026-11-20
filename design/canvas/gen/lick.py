"""Adds Puggle's lick of hair to boards drawn by the older scripts (15 November 2026).

Those scripts draw her head as one ellipse and share it with her family, so this works on the finished board
files: wherever that head is followed by her flower clip, the lick from the app's rig goes in straight after it,
in the head's own line colour and weight. Heads without the clip (Mum, Dad, Nan, Pop, Pebble, and Puggle in a hat)
are left alone. Safe to run twice.

    python3 lick.py ..            # every board on the Characters, Brand and App pages
"""
import sys, re, json
ROOT = sys.argv[1]
P = ROOT + '/project/'
rig = json.load(open(ROOT + '/gen/puggle.rig.json'))
outline, patch = [s['d'] for p in rig['parts'] if p['id'] == 'lick' for s in p['shapes']]
HEAD = re.compile(r'<ellipse cx="120" cy="108" rx="70" ry="60" fill="#8A5A3C" stroke="(#[0-9A-Fa-f]{6})" stroke-width="([\d.]+)"[^>]*></ellipse>')
ANYHEAD = re.compile(r'<ellipse cx="1[012]\d" cy="1[01]\d" rx="[67]\d" ry="[56]\d" ')
CLIP = re.compile(r'<circle [^>]*r="1[0-4](\.\d+)?" fill="#E5553B" stroke="#(B23A26|3A2A20)"')
# Boards about Puggle alone, where she is drawn without her clip: every plain head on them is hers.
ALL = {'Expressions.dc.html', 'Manpu.dc.html', 'Hands.dc.html', 'Construction.dc.html', 'Glasses.dc.html', 'Family.dc.html', 'Logos.dc.html', 'LogotypeE.dc.html',
       'Architecture.dc.html', 'Merch.dc.html', 'OnboardCharacter.dc.html', 'OnboardShared.dc.html'}
# The heads on those boards that are not hers, counted from the first: Pebble, and Nan and Pop in their glasses.
NOT_HERS = {'Family.dc.html': {1}, 'Glasses.dc.html': {6, 7}}
SKIP = {'ModelSheet.dc.html', 'AppIcon.dc.html', 'ActivityIcons.dc.html', 'PuggleAdds.dc.html', 'Motion.dc.html', 'Motion2.dc.html'}

def add(text, everyone=False, skip=()):
    out, at, n = '', 0, 0
    for i, m in enumerate(HEAD.finditer(text)):
        rest = text[m.end():]
        ends = [e for e in (rest.find('</svg>'), (ANYHEAD.search(rest) or re.search('$', rest)).start()) if e >= 0]
        figure = rest[:min(ends)]
        out += text[at:m.end()]; at = m.end()
        if i in skip or 'data-lick' in figure[:200] or not (everyone or CLIP.search(figure)): continue
        line, width = m.group(1), m.group(2)
        out += (f'<path data-lick="1" d="{outline}" fill="#8A5A3C" stroke="{line}" stroke-width="{width}" stroke-linejoin="round"></path>'
                f'<path d="{patch}" fill="#8A5A3C"></path>')
        n += 1
    return out + text[at:], n

boards = json.load(open(P + 'canvas.json'))['boards']
for name, board in boards.items():
    if board.get('page') not in ('characters', 'brand', 'app') or name in SKIP: continue
    text = open(P + name).read()
    new, n = add(text, name in ALL, NOT_HERS.get(name, ()))
    if n:
        open(P + name, 'w').write(new)
        print(f'{name}: {n} of {len(HEAD.findall(text))} heads')
