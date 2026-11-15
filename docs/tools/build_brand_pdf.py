"""Builds the brand book PDF from the design canvas boards (15 November 2026).

Every page is the same size, 1080 by 1527 (the proportions of A4, upright). Each board from design/canvas/project
sits under a strip with its section and title. Short boards that follow each other in a section share a page; a
board too tall for the page is drawn smaller to fit. There is a cover, a contents page, a divider for each section
and the rules at the end. Section 7 ("In the app now") is pictures the
app saves of its own drawings, kept in docs/brand/app-now/.

    python3 docs/tools/build_brand_pdf.py            # writes docs/brand/Puggle-brand-<date>.pdf
    python3 docs/tools/build_brand_pdf.py --refresh  # first copies fresh pictures from the simulator

Before --refresh, build the app for the simulator and launch it once with "-uitest 1 -hasOnboarded YES -debugSheet 1":
it saves every sheet to its Documents folder. The first-run and pattern pictures are copied from docs/previews.

Needs Google Chrome (to print each page) and Swift (PDFKit, to join them). The boards load Bricolage Grotesque
from Google Fonts, so it needs a connection.
"""
import json, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.join(HERE, '..', '..')
CANVAS = os.path.join(REPO, 'design', 'canvas')
NOW = os.path.join(REPO, 'docs', 'brand', 'app-now')
DATE, STAMP = '15 November 2026', '2026-11-15'
OUT = os.path.join(REPO, 'docs', 'brand', f'Puggle-brand-{STAMP}.pdf')
PAGE_H = 1527
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
sys.path.insert(0, os.path.join(CANVAS, 'gen'))
import rig

_w = open(os.path.join(REPO, 'docs', 'previews', 'logo', 'wordmark-B1', 'puggle_B1_v4.svg')).read()
WORDMARK = _w[_w.index('<g fill'):_w.rindex('</svg>')]
FONT = '<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400..800&display=swap" rel="stylesheet">'
BASE = "font-family: 'Bricolage Grotesque', system-ui, sans-serif; color: #2A1F18"
HAIR = "Her lick of hair was added to this board on 15 November."

# Section, what it is about, then each board with the note under its title.
SECTIONS = [
    ('Name and logo', 'The name, the logotype and how one name works across the app, clothing and books.', [
        ('Wordmark', 'Chosen on 15 November.'), ('LogotypeE', 'The earlier wordmark, set in Bricolage Grotesque.'), ('Logos', 'Drawn on 10 November. The line faces (G, H and I) have no lick of hair yet.'),
        ('Architecture', ''), ('AppIcon', 'New on 15 November. Drawn from the app\'s own icon file.')]),
    ('Colour and type', 'The palette, the typefaces and how words appear inside the world.', [('Palette', ''), ('Signs', '')]),
    ('Puggle', 'How she is drawn, what her face can do and what it never does.', [
        ('ModelSheet', 'Drawn from the app\'s file of her parts as it stood on 15 November. She always faces the viewer.'),
        ('Construction', 'The steps do not mention the lick of hair yet.'), ('Expressions', 'The silhouettes have no lick of hair yet.'), ('Manpu', ''), ('Hands', ''),
        ('PuggleAdds', 'Proposals, not decisions. The side-on walk here is retired: she always faces the viewer.'),
        ('Motion2', 'A still of an animated board. Its side-on walk is retired.')]),
    ('The cast', 'Family and friends, and what tells them apart.', [
        ('Lineup', 'The friends still have stitched cheeks here; the app\'s drawings of them are newer.'), ('Family', ''),
        ('Heads', 'Puggle has a lick of hair since 14 November. The rest of the cast have none.'), ('Glasses', '')]),
    ('Icons, stickers and shapes', 'The activity icons as the app draws them, then one drawing style in four finishes.', [
        ('ActivityIcons', 'New on 15 November. Drawn from the app\'s own icon sources.'),
        ('PuggleStyle', 'The style study the icons grew from. Its icons are the earlier set.'), ('StyleWorld', ''),
        ('Holo', 'These shimmer on the canvas; this is a still.')]),
    ('The world', "Places from a Sydney family's week, and what they become on a phone, a page and a jumper.", [
        ('Scenes2', ''), ('AppScenes', ''), ('Wallpapers', ''), ('Books', ''),
        ('Merch', 'Drawn on 10 November. The line faces have no lick of hair yet.'), ('References', 'For study only. Nothing is copied from any of them.')]),
]
APP_NOW = ('In the app now', 'What the app itself draws today: the cast, their clothes, how she shows a feeling, the scenes, the rooms and the weather. '
           'These are pictures saved by the app\'s own build on 15 November, so they are ahead of the boards in sections 3, 4 and 6.')
# Picture, title, note, and the most height it may take on the page.
PICTURES = [
    ('cast', 'The cast, by day and after dark', 'Each has their own file of parts.', 420),
    ('portraits', 'Portraits', 'For the family list and anywhere a face stands for a person.', 150),
    ('pebble-dummy', 'Pebble', 'Awake with his bottle, asleep with his dummy, in each colour.', 520),
    ('wardrobe', 'Clothes', 'Every garment in every colour, and everyone dressed for rain, cold and heat.', 800),
    ('hats-off', 'Under the hats', 'Hats come off indoors.', 500),
    ('going-grey', 'Nan and Pop going grey', '', 1150),
    ('sunglasses-built', 'Sunglasses', 'Every style on everyone, with hats in the heat, and pushed up in a reaction.', 1250),
    ('feelings', 'Feelings', 'How each of the cast shows the same feelings.', 1250),
    ('tail-motion', 'Tails in motion', '', 700),
    ('bending-arms', 'Arms that bend', '', 1100),
    ('scenes', 'The four outdoor scenes', 'Hills, beach, backyard and bush, from dawn to dark.', 770),
    ('scenes-pulled', 'The scenes with the sky pulled down', '', 1380),
    ('rooms', 'The four rooms', 'After dark she is indoors.', 310),
    ('rooms-pulled', 'The rooms with the wall pulled down', '', 600),
    ('firework', 'The firework', 'A milestone, after dark.', 125),
    ('weather', 'Weather by day', 'Each scene in rain, storm, heat, wind, cold, snow and fog.', 1240),
    ('weather-night', 'Weather after dark', '', 1240),
    ('firstrun', 'First run', 'A picture from 14 November.', 430),
    ('patterns', 'Repeat patterns, light and dark', 'A picture from 14 November.', 610),
]
RULES = [
    ('The name', 'Appears only on the splash screen, the app icon and Help.'),
    ('Wordmark', 'The six drawn letters, lower case, in Ink or Paper. It is a drawing, not a typeface: no other word is set in it.'),
    ('Her face', 'No mouth. The bill never moves or changes. Eyebrows appear only with a feeling: never at rest, never angry, sad or worried.'),
    ('Her view', 'She always faces the viewer. No three-quarter, side or back view.'),
    ('Her hair', 'A lick of hair, part of her head in the same fur and line. The rest of the cast have no hair and wear accessories; Pebble keeps a curl.'),
    ('Her feelings', 'Eyes, eyebrows, cheeks, floating marks, her body and her tail show them. She is never sad or disappointed about what a parent did or did not log.'),
    ('Line', "Characters are outlined in a darker shade of each part's own colour. The world has no outlines."),
    ('Hands', 'Always visible, clear of the head and body. Peekaboo is the only time they cover the face.'),
    ('Activity icons', "One line in Ink and one flat fill. The fill is Wattle unless the family chooses a colour of their own or the child's colour. Skin, poo, wee and anything with a real colour keep it. No faces on objects."),
    ('App icon', 'Her face on Wattle, flat, in the coloured line. In dark the ground goes deep brown.'),
    ('Stickers', 'One drawing, three more finishes: sticker, holographic and print. The slipped colour lives only in print.'),
    ('Scenes', 'A small colour key, one big shape, real light and a moment for the cast.'),
    ('Places and culture', 'Nothing Indigenous or with strong Indigenous meaning. Generic places only; no Sydney Opera House.'),
    ('Originality', 'Solid colours and shapes of our own. References are for study; nothing is copied.'),
    ('Children', "A child's real name never appears in the work."),
]
OPEN = ["The mark that goes with the wordmark: an exploration is under way in the app's previews (the little sister hatching from an egg).",
        'The wordmark has not been proofed on a woven label or a book cover, and the app does not use it yet.',
        "Pebble's name.", 'Trade mark checks for the name and logotype.',
        'Two proposed additions to Puggle: a patterned outfit and a flat version.',
        'Which breastfeeding drawing the app uses, and a setting for skin tone.',
        'The large icon drawings are not in the app yet.']


def page(body, height=PAGE_H, extra='', ground='#F2ECDD'):
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8">{FONT}<style>@page{{size:1080px {height}px;margin:0}}'
            f'html,body{{margin:0;-webkit-print-color-adjust:exact;print-color-adjust:exact}}a{{color:#2A1F18}}{extra}</style></head>'
            f'<body><div style="width: 1080px; height: {height}px; overflow: hidden; background: {ground}">{body}</div></body></html>')


def strip(section, number, title, note):
    return (f'<div style="height: 63px; box-sizing: border-box; background: #FBF6E9; border-top: 1px solid #E4DCC8; border-bottom: 1px solid #E4DCC8; padding: 0 48px; display: flex; align-items: center; gap: 14px; {BASE}">'
            f'<div style="font-size: 12px; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; color: #5A4636; white-space: nowrap">{number}. {section}</div>'
            f'<div style="font-size: 14px; font-weight: 800; white-space: nowrap">{title}</div>'
            f'<div style="font-size: 13px; font-weight: 500; color: #5A4636">{note}</div></div>')


def board(name, section, number, note, boards):
    """One board under its strip, and how tall the two are. A board too tall for a page is drawn smaller."""
    text = open(os.path.join(CANVAS, 'project', f'{name}.dc.html')).read()
    inner = re.sub(r'<helmet>.*?</helmet>', '', text[text.index('<x-dc>') + 6:text.index('</x-dc>')], flags=re.S)
    info = boards[f'{name}.dc.html']
    room = PAGE_H - 63
    if info['h'] > room:
        k = room / info['h']
        note = (note + ' ' if note else '') + f'Shown at {round(k * 100)}% to fit the page.'
        inner = (f'<div style="width: 1080px; height: {room}px; overflow: hidden"><div style="width: 1080px; height: {info["h"]}px; transform: scale({k:.4f}); transform-origin: top left; margin-left: {(1080 - 1080 * k) / 2:.1f}px">{inner}</div></div>')
    return strip(section, number, info['title'], note) + inner, 63 + min(info['h'], room)


def packed(items):
    """Boards in order, as many to a page as fit."""
    pages, now, used = [], '', 0
    for markup, height in items:
        if now and used + height > PAGE_H: pages.append(now); now, used = '', 0
        now += markup; used += height
    return pages + ([now] if now else [])


def divider(number, title, about):
    return page(f'<div style="width: 1080px; height: {PAGE_H}px; box-sizing: border-box; padding: 620px 72px 0; {BASE}; color: #FBF6E9">'
                f'<div style="font-size: 300px; font-weight: 800; line-height: 1; position: absolute; left: 60px; top: 60px; opacity: 0.16">{number}</div>'
                f'<div style="font-size: 22px; font-weight: 700">Section {number}</div><div style="font-size: 84px; font-weight: 800; letter-spacing: -0.03em; line-height: 1.05; max-width: 900px">{title}</div>'
                f'<div style="font-size: 20px; font-weight: 500; margin-top: 22px; max-width: 760px; line-height: 1.4">{about}</div></div>', ground='#2A62B8')


def cover():
    wave = rig.render(**rig.key('greet', 0.52))
    return page(f'<div style="width: 1080px; height: {PAGE_H}px; box-sizing: border-box; padding: 110px 72px; position: relative; {BASE}">'
                f'<svg xmlns="http://www.w3.org/2000/svg" role="img" aria-label="puggle" width="640" height="216" viewBox="65 90 688 232" style="margin-left: -9px">{WORDMARK}</svg>'
                f'<div style="font-size: 40px; font-weight: 700; margin-top: 26px">The brand so far</div>'
                f'<div style="font-size: 19px; font-weight: 500; margin-top: 14px; max-width: 520px; line-height: 1.4">Name and logo, colour and type, Puggle and her family, icons and stickers, and the world they live in.</div>'
                f'<div style="position: absolute; left: 72px; bottom: 72px; font-size: 16px; font-weight: 700">{DATE} · Working document</div>'
                f'<svg xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Puggle waving" width="640" height="800" viewBox="0 0 240 300" style="position: absolute; right: 60px; bottom: 60px">{wave}</svg></div>', ground='#F4BE2C')


def contents(rows):
    lines = ''.join(f'<div style="display: flex; gap: 30px; padding: 16px 0; border-top: 1px solid #DDD2BC"><div style="width: 22px; font-size: 17px; font-weight: 800">{i}</div>'
                    f'<div><div style="font-size: 18px; font-weight: 800">{t}</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30; margin-top: 3px; max-width: 800px; line-height: 1.4">{a}</div></div></div>'
                    for i, (t, a) in enumerate(rows, 1))
    return page(f'<div style="width: 1080px; height: {PAGE_H}px; box-sizing: border-box; padding: 110px 72px; {BASE}">'
                f'<div style="font-size: 36px; font-weight: 800; letter-spacing: -0.02em">What\'s inside</div>'
                f'<div style="font-size: 15px; font-weight: 500; color: #4A3B30; margin: 14px 0 30px; max-width: 820px; line-height: 1.45">Each page is a board from the design canvas, as it stood on {DATE}. '
                f'Every page is one size; short boards share a page and a few tall ones are drawn smaller. A note beside a page title says where a board is behind. Since the last edition (14 November): Puggle has her lick of hair and always faces the viewer, the wordmark is chosen, and the app icon and the activity icons have pages of their own.</div>{lines}</div>')


def rules():
    rows = ''.join(f'<div style="display: flex; gap: 30px; padding: 13px 0; border-top: 1px solid #DDD2BC"><div style="width: 200px; flex: none; font-size: 16px; font-weight: 800">{a}</div>'
                   f'<div style="font-size: 15px; font-weight: 500; line-height: 1.4">{b}</div></div>' for a, b in RULES)
    still = ''.join(f'<li style="margin: 8px 0">{t}</li>' for t in OPEN)
    return page(f'<div style="width: 1080px; height: {PAGE_H}px; box-sizing: border-box; padding: 80px 72px; {BASE}">'
                f'<div style="font-size: 36px; font-weight: 800; letter-spacing: -0.02em; margin-bottom: 26px">Rules</div>{rows}'
                f'<div style="font-size: 24px; font-weight: 800; margin: 34px 0 10px">Still open</div><ul style="margin: 0; padding-left: 20px; font-size: 15px; font-weight: 500; line-height: 1.4">{still}</ul></div>')


JOIN = '''
import PDFKit
let a = CommandLine.arguments
let out = PDFDocument()
for item in a[2...] { let d = PDFDocument(url: URL(fileURLWithPath: item))!; for i in 0..<d.pageCount { out.insert(d.page(at: i)!, at: out.pageCount) } }
out.documentAttributes = [PDFDocumentAttribute.titleAttribute: "Puggle: the brand so far"]
out.write(to: URL(fileURLWithPath: a[1]))
print(out.pageCount, "pages")
'''
def refresh():
    """Copies the pictures the app saved in the simulator into docs/brand/app-now, as smaller JPEGs."""
    os.makedirs(NOW, exist_ok=True)
    box = subprocess.run(['xcrun', 'simctl', 'get_app_container', 'iPhone 17', 'com.tomgarton.puggle', 'data'], capture_output=True, text=True).stdout.strip()
    elsewhere = {'firstrun': os.path.join(REPO, 'docs', 'previews', 'onboarding', 'built-light.png'),
                 'patterns': os.path.join(REPO, 'docs', 'previews', 'patterns', 'repeats.png')}
    for name, *_ in PICTURES:
        src = elsewhere.get(name, os.path.join(box, 'Documents', name + '.png'))
        assert os.path.exists(src), src
        subprocess.run(['sips', '--resampleWidth', '2160', '-s', 'format', 'jpeg', '-s', 'formatOptions', '86', src, '--out', os.path.join(NOW, name + '.jpg')], capture_output=True)


def picture(name, title, note, most):
    size = subprocess.run(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', os.path.join(NOW, name + '.jpg')], capture_output=True, text=True).stdout
    wide, tall = (int(v) for v in re.findall(r'pixel\w+: (\d+)', size))
    height = min(most, round(984 * tall / wide))
    return (strip(APP_NOW[0], 7, title, note) + f'<div style="height: {height + 40}px; display: flex; align-items: center; justify-content: center">'
            f'<img src="file://{os.path.abspath(os.path.join(NOW, name + ".jpg"))}" style="max-width: 984px; height: {height}px; border-radius: 10px"></div>', 63 + height + 40)


def main():
    if '--refresh' in sys.argv: refresh()
    boards = json.load(open(os.path.join(CANVAS, 'project', 'canvas.json')))['boards']
    work = tempfile.mkdtemp()
    pages = [cover(), contents([(t, a) for t, a, _ in SECTIONS] + [APP_NOW[:2], ('Rules', 'The short list that everything above follows.')])]
    for number, (title, about, items) in enumerate(SECTIONS, 1):
        pages.append(divider(number, title, about))
        pages += [page(body) for body in packed([board(name, title, number, note, boards) for name, note in items])]
    pages.append(divider(7, APP_NOW[0], APP_NOW[1]))
    pages += [page(body) for body in packed([picture(*p) for p in PICTURES])]
    pages.append(rules())
    parts = []
    for i, html in enumerate(pages):
        src, pdf = os.path.join(work, f'p{i:02}.html'), os.path.join(work, f'p{i:02}.pdf')
        open(src, 'w').write(html)
        subprocess.run([CHROME, '--headless', '--disable-gpu', '--no-pdf-header-footer', '--virtual-time-budget=4000', f'--print-to-pdf={pdf}', 'file://' + src],
                       capture_output=True)
        assert os.path.exists(pdf), i
        parts.append(pdf)
    script = os.path.join(work, 'join.swift')
    open(script, 'w').write(JOIN)
    print(subprocess.run(['swift', script, OUT] + parts, capture_output=True, text=True).stdout.strip(), '->', OUT)


if __name__ == '__main__':
    main()
