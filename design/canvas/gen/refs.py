import sys, json
ROOT = sys.argv[1]
_s = open(ROOT + '/gen/scenes3.py').read()
exec(_s[:_s.index('# ---- BOARD ----')])
SC = {n: s for n, s, _, _ in SCENES}
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'

def thumb(n):
    return (f'<div style="display: flex; flex-direction: column; gap: 2px; align-items: flex-start; width: 62px"><svg role="img" aria-label="{n} scene" width="62" height="48" viewBox="0 0 {W} {Hh}" style="border-radius: 8px; display: block">{SC[n]}</svg>'
            f'<div style="font-size: 9.5px; font-weight: 700; color: #6B5E52; width: 62px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{n}</div></div>')
def chip(t, c): return f'<span style="display: inline-block; padding: 2px 9px; border-radius: 99px; background: {c}; font-size: 11px; font-weight: 800">{t}</span>'

GROUP = {'Simple shapes': SUN, 'Mid-century': MINT, 'Australian picture books': SHELL, 'Posters and colour': SKY, 'Screen and games': '#E4DDF0'}
REFS = [
 ('Dick Bruna, Miffy', 'Simple shapes', 'Bold flat colour, a heavy even line, nothing extra. Front-on, calm, symmetrical.', 'Copying Miffy’s face, proportions or colour blocks.', ['Night street', 'The shops']),
 ('Taro Gomi', 'Simple shapes', 'Sparse scenes, playful colour, very few lines; the page can be mostly empty.', 'His loose hand-drawn wobble; we stay crisp.', ['The pool', 'Rainy day']),
 ('Charley Harper', 'Simple shapes', 'Nature reduced to geometry and rhythm: trees, birds, waves as repeatable shapes.', 'Hard angles; we round every corner.', ['Bush walk', 'Beach']),
 ('Owen Davey', 'Simple shapes', 'Rounded animals and places in a tight, limited palette. Close to our sticker and print finishes.', 'Texture and grain; we keep fills flat.', ['The farm', 'The park']),
 ('Miroslav Šašek, This is Sydney', 'Mid-century', 'The harbour, ferries and streets drawn simply and with wit. A place made charming, not grand.', 'Landmarks we can’t use (the Opera House).', ['Sydney Harbour', 'The shops']),
 ('Alice and Martin Provensen', 'Mid-century', 'A gentle storybook mood: farms, kitchens, family days, soft warm colour.', 'Muted, aged colour; ours is fresh.', ['The farm', "Grandma's house"]),
 ('Mary Blair', 'Mid-century', 'Confident colour and joyful flat shapes; brilliant at night and weather moods.', 'Her stylised faces and Disney associations.', ['Night street', 'Rainy day']),
 ('Alison Lester', 'Australian picture books', 'Our world exactly: beach, farm, bush, family life, cosy and readable. The closest match in spirit.', 'Her loose watercolour; we are vector and flat.', ['Beach', 'The farm', 'Backyard']),
 ('Bob Graham', 'Australian picture books', 'Gentle suburban family scenes with small, true details: the washing, the cat, the corner shop.', 'Busy cross-hatching; we keep one hero object.', ['Backyard', 'The shops', 'Night street']),
 ('Pamela Allen', 'Australian picture books', 'Very simple Australian picture books with lots of white space. A reminder of how little a scene needs.', 'Sketchy line.', ['The pool', 'Beach']),
 ('Marc Martin', 'Australian picture books', 'Contemporary Australian city and nature scenes in flat shapes and lovely colour.', 'His textures and print grain (we save texture for clothing).', ['The café', 'Bush walk']),
 ('May Gibbs', 'Australian picture books', 'How Australian flora can feel magical: gum blossom, gumnuts, the bush as a world.', 'Her characters and motifs; heritage material, inspiration only.', ['Bush walk', 'The park']),
 ('1930s Australian travel posters', 'Posters and colour', 'Percy Trompf, James Northfield: beaches, mountains and harbour in flat sunny colour with strong horizons.', 'Period lettering and the adult glamour.', ['Beach', 'Bush walk', 'Sydney Harbour']),
 ('Ken Done', 'Posters and colour', 'The joy of Sydney colour: bright harbour blues, sunny yellows, nothing serious.', 'His very recognisable look; borrow the joy, not the style.', ['Sydney Harbour', 'The pool']),
 ('Bluey (backgrounds)', 'Screen and games', 'Australian suburbia kids recognise: yards, houses, light that feels like home.', 'Its look is strongly protected. Study only, never echo.', ['Backyard', 'The park']),
 ('Animal Crossing', 'Screen and games', 'Cosy places, seasons and time of day; objects that invite play. A model for our living scenes.', 'Its 3D toy look and character designs.', ['Night street', 'Rainy day']),
]
def card(name, g, take, avoid, scenes):
    return (f'<div style="width: 232px; box-sizing: border-box; padding: 14px; background: {PAPER}; border-radius: 20px; display: flex; flex-direction: column; gap: 8px">'
            f'<div>{chip(g, GROUP[g])}</div><div style="font-size: 16px; font-weight: 800; line-height: 1.2">{name}</div>'
            f'<div style="{T}; font-size: 12px"><b>Take:</b> {take}</div><div style="{T}; font-size: 12px; color: #7A6B60"><b>Avoid:</b> {avoid}</div>'
            f'<div style="display: flex; gap: 6px; flex-wrap: wrap; margin-top: 2px">{"".join(thumb(s) for s in scenes)}</div></div>')
cards = ''.join(card(*r) for r in REFS)

words = ['Sunny', 'Calm', 'Suburban', 'Cosy', 'Clear', 'Handmade', 'Playful', 'Unfussy']
mood = ''.join(f'<div style="padding: 8px 16px; border-radius: 99px; background: {c}; font-size: 17px; font-weight: 800">{w}</div>' for w, c in zip(words, [A, SKY, MINT, SHELL, PAPER, SUN, BLUSH, PAPER]))
wall = ''.join(f'<div style="flex: 1; padding: 14px 16px; background: {c}; border-radius: 18px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.04em; text-transform: uppercase; color: #5A4636">{k}</div><div style="font-size: 18px; font-weight: 800; margin-top: 2px">{n}</div><div style="{T}; font-size: 12px; margin-top: 4px">{d}</div></div>'
               for k, n, d, c in (('The look', 'Dick Bruna, Miffy', 'Flat, bold, calm, nothing extra.', SUN), ('The world', 'Alison Lester', 'Our places and family life, cosy and true.', SHELL),
                                  ('The place', 'Šašek, This is Sydney', 'Sydney made simple and charming.', MINT), ('The light', '1930s travel posters', 'Sunny colour, strong horizons.', SKY)))

body = f'''<div style="width: 1080px; height: 1560px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 20px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Illustration references</h1>
<div style="{T}; font-size: 15px; max-width: 940px">What we learn from each, what we leave alone, and which of our scenes it informs. Described in words and shown through our own scenes, so the board carries no one else’s artwork. Study, never trace.</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">On the wall</div><div style="display: flex; gap: 12px">{wall}</div></div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Mood</div><div style="display: flex; gap: 10px; flex-wrap: wrap">{mood}</div></div>
<div style="display: flex; flex-wrap: wrap; gap: 14px">{cards}</div>
</div>'''
wrap('Illustration references', body, 1080, 1560, 'References.dc.html', 0)
P = ROOT + '/project/'
c = json.load(open(P + 'canvas.json'))
c['boards']['References.dc.html'].update(page='brand', x=1200, y=6060)
o = c['order']; o.remove('References.dc.html'); o.insert(o.index('Scenes.dc.html') + 1, 'References.dc.html')
json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
