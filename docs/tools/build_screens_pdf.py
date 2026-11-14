#!/usr/bin/env python3
"""Builds docs/Puggle-app-screens-and-flows.pdf.

    python3 docs/tools/build_screens_pdf.py <folder with img/ and the Bricolage font> <out.html>

Then print the HTML to PDF with Chrome:
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-pdf-header-footer \
        --print-to-pdf=docs/Puggle-app-screens-and-flows.pdf file://<out.html>

Layout: A4 portrait on a twelve-column grid. Columns 1 to 3 are a spine for captions, notes and sources;
columns 4 to 12 carry the text and screens. Each section has a brand colour, a divider page, and a
running head in that colour. Flow text comes from docs/flows.md; screens are saved from the app.
"""
import html, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
ASSETS, OUT = sys.argv[1], sys.argv[2]
# Page numbers for the contents come from a first pass: build once, read which page each marker landed on, build again.
import json
PAGES = json.load(open(sys.argv[3])) if len(sys.argv) > 3 else None
def mark(anchor): return f'<a id="{anchor}"></a>' + ('' if PAGES else f'<span class="mark">@@{anchor}@@</span>')
def page_of(anchor): return str(PAGES.get(anchor, '')) if PAGES else '00'

INK, PAPER, SAND, MOON = '#3A2A20', '#FBF6E9', '#F2ECDD', '#F3E0B8'
WATTLE, HARBOUR, WARATAH, GUM, NIGHT = '#F4BE2C', '#2A62B8', '#E5553B', '#3C9A5F', '#1B2440'
SKY, SHELL, MINT, SUN = '#BFD9F5', '#F3D9C9', '#CFE5D2', '#F4E7B0'

# The brand's soft shapes, on a 24-unit square.
SHAPES = {
    'quatrefoil': 'M7.31 7.31A4.7 4.7 0 0 1 16.69 7.31A4.7 4.7 0 0 1 16.69 16.69A4.7 4.7 0 0 1 7.31 16.69A4.7 4.7 0 0 1 7.31 7.31Z',
    'blossom': 'M7.85 6.28A4.3 4.3 0 0 1 16.15 6.28A4.3 4.3 0 0 1 18.72 14.18A4.3 4.3 0 0 1 12.00 19.07A4.3 4.3 0 0 1 5.28 14.18A4.3 4.3 0 0 1 7.85 6.28Z',
    'pill': 'M6.5 8H17.5Q21.5 8 21.5 12V12Q21.5 16 17.5 16H6.5Q2.5 16 2.5 12V12Q2.5 8 6.5 8Z',
    'scallop': 'M4.5 18.5a1.5 1.5 0 0 1-1.5-1.5V12.5a3 3 0 0 1 6 0a3 3 0 0 1 6 0a3 3 0 0 1 6 0V17a1.5 1.5 0 0 1-1.5 1.5Z',
    'square': 'M8.5 3.5H15.5Q20.5 3.5 20.5 8.5V15.5Q20.5 20.5 15.5 20.5H8.5Q3.5 20.5 3.5 15.5V8.5Q3.5 3.5 8.5 3.5Z',
    'pebble': 'M12 3.5C18.5 3.5 21.3 7.5 20.8 12.6S16.6 20.8 11 20.4S2.8 16.8 3.3 11.4S6 3.5 12 3.5Z',
    'half': 'M5 6H14a6 6 0 0 1 0 12H5a1.5 1.5 0 0 1-1.5-1.5V7.5A1.5 1.5 0 0 1 5 6Z',
}

def shape(name, colour, x, y, size, turn=0, opacity=1):
    """A soft shape placed on the page, in millimetres from the top left."""
    return (f'<svg class="shape" style="left:{x}mm;top:{y}mm;width:{size}mm;height:{size}mm;transform:rotate({turn}deg);opacity:{opacity}" '
            f'viewBox="0 0 24 24"><path d="{SHAPES[name]}" fill="{colour}"/></svg>')

def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    return re.sub(r'`(.+?)`', r'<code>\1</code>', text)

def md(text):
    out, mode = [], None
    def close():
        nonlocal mode
        if mode: out.append(f'</{mode}>'); mode = None
    for line in text.split('\n'):
        if not line.strip(): close(); continue
        m = re.match(r'(\d+)\. (.*)', line)
        if m:
            if mode != 'ol': close(); out.append('<ol>'); mode = 'ol'
            out.append(f'<li>{inline(m.group(2))}</li>'); continue
        if line.startswith('- '):
            if mode != 'ul': close(); out.append('<ul>'); mode = 'ul'
            out.append(f'<li>{inline(line[2:])}</li>'); continue
        close()
        if line.rstrip() == 'Rules and edge cases:': out.append('<h4>Rules and edge cases</h4>')
        else: out.append(f'<p>{inline(line)}</p>')
    close()
    return '\n'.join(out)

flows = {}
for part in re.split(r'\n## ', open(ROOT + '/docs/flows.md').read())[1:]:
    title, _, body = part.partition('\n')
    flows[title.strip()] = body.strip()

SCREENS = {
    1: [('01-welcome', 'Welcome. The egg hatches, then the name appears.'), ('02-onboarding-logging', 'Page 1, with a stepper to try.'),
        ('03-onboarding-together', 'Page 2, as a test build shows it.'), ('04-onboarding-looking-back', 'Page 3, a made-up week.'), ('05-set-up-family', 'Set up your family.'),
        ('06-first-child', 'Add your first child.'), ('09-family-heap', 'The finish: your family.'), ('10-join', 'Joining by invite.')],
    2: [('20-today', 'Today, by day.'), ('21-bottle-sheet', 'The bottle sheet, with the tin under the milk.'), ('22-nappy-sheet', 'Nappy: one tap saves.')],
    5: [('30-history', 'History.'), ('31-entry', 'An entry, opened to read.'), ('40-insights', 'Insights: the week.'), ('41-patterns', 'Insights: patterns by age.')],
    6: [('50-family', 'The Family tab.'), ('62-today-viewer', 'Today as a Viewer: can see, cannot log.')],
    9: [('52-settings', 'Settings.')],
    15: [('60-today-evening', 'Evening: indoors after 18:00.'), ('61-today-night', 'Bedtime, in the night look.')],
    4: [('70-play', 'The play pad.')],
}
NOTES = {
    1: 'The yellow "Demo" bar is the Developer menu\'s run-through, not part of first run. Page 2 is a test build that keeps data on the phone; the iCloud build shows three people at three levels and adds "Who else looks after them?".',
    4: 'Only the play pad is pictured. The stamp cards are built but not shown here.',
}

# Sections: number, title, colour, text colour on it, a line about it, the flows in it.
SECTIONS = [
    (1, 'The people', WARATAH, PAPER, 'Who Puggle is for, the personas who have walked through it, and the app at a glance.', []),
    (2, 'Starting out', WATTLE, INK, 'From install to a family on Today: first run, setup that fits each child, and bringing in the people who help.', [1, 12, 6, 13]),
    (3, 'Every day', HARBOUR, PAPER, 'The core loop. Feeds, sleeps, nappies, the potty and health, for one child or several at once.', [2, 3, 4, 11, 14]),
    (4, 'Looking back', GUM, PAPER, 'What was logged, seen as days, weeks and firsts.', [5, 8]),
    (5, 'Around the edges', NIGHT, MOON, 'Children and characters, settings, the things that go wrong, calm and privacy, access, and life outside the app.', [7, 9, 10, 15, 16, 17]),
    (6, 'Reference', SKY, INK, 'The words this document uses, and where everything in it comes from.', []),
]
def entries(number, flow_numbers):
    """What is inside a section: (label, anchor) pairs."""
    if number == 1: return [('Who it is for', 'who'), ('Personas', 'personas'), ('The app at a glance', 'glance')]
    if number == 6: return [('Glossary', 'glossary'), ('References', 'references')]
    return [(by_number[n].split('. ', 1)[1], f'flow-{n:02d}') for n in flow_numbers]
by_number = {int(t.split('.')[0]): t for t in flows if t[0].isdigit()}

PERSONAS = [
    ('Mum and Dad, first four days home', 'Caesarean recovery, breastfeeding trouble, a midwife asking for every feed and nappy.', 'For nappies and top-ups, yes, alongside the midwife\'s paper chart. It reads as a tracker for a six-month-old, not for week one.'),
    ('Parents at three months', 'Looking for patterns, giving medicine, a return to work, switching from another app.', 'Would try it, would not stay: no health logging, and Insights is too shallow.'),
    ('A toddler mid potty-training, plus a two-week-old', 'Two children at very different stages.', 'Would keep the potty sticker and the feed timer, and drop the rest within a fortnight.'),
    ('A grandmother minding two children', 'Large text, no glasses, unsure of iCloud.', 'Not on her own by day two.'),
    ('Parents of eight-week-old premature twins', 'On a hospital schedule.', 'Not yet: better than apps that switch between babies, but every sheet assumes one child and one amount.'),
    ('The invited second parent, and a professional nanny', 'Joining someone else\'s family.', 'He would drift after a few weeks; she cannot do her job with it.'),
    ('Accessibility', 'A blind father using VoiceOver, a low-vision colour-blind mother, anyone one-handed.', 'Not yet accessible.'),
    ('An anxious mother, a privacy-minded father, a parent burned by other apps', 'Trust, calm and data.', 'Not safe for the anxious mother as drawn; the other two would probably stay.'),
]
TESTERS = [
    'A single parent with a three-week-old, alone, one-handed at night.',
    'A grandmother who is the sole carer of a 14-month-old and a four-year-old, at the largest text size.',
    'One family at every level: two mothers, twins and a toddler, a Nan as Helper, an uncle as Viewer, a nanny added and removed.',
    'Families the design did not have in mind: co-parents in two homes, a foster carer, a baby born at 29 weeks, a family after a loss, a parent with postnatal anxiety, adoptive and trans parents.',
    'Accessibility: VoiceOver, the largest text, one hand or a tremor, colour blindness with twins, reading difficulty, Reduce Motion.',
    'Hands-on in the simulator: first run, logging and undoing, History, Insights, Family, Play, and the Helper and Viewer views.',
]

def spread(spine, main, cls=''):
    """One block on the grid: the spine in columns 1 to 3, the body in 4 to 12."""
    return f'<div class="grid {cls}"><aside class="spine">{spine}</aside><div class="main">{main}</div></div>'

def tag(label): return f'<div class="tag">{html.escape(label)}</div>'
def callout(label, text): return f'<div class="callout">{tag(label)}<p>{inline(text)}</p></div>'

def divider(number, title, colour, on, line, contents):
    # contents: (label, anchor) pairs
    decor = {
        1: shape('quatrefoil', WATTLE, 96, -40, 190, 12) + shape('pill', PAPER, -40, 196, 150, -24, 0.9) + shape('pebble', NIGHT, 128, 206, 110, 10, 0.25),
        2: shape('blossom', WARATAH, 100, -52, 200, 0) + shape('half', HARBOUR, -46, 190, 150, 18) + shape('square', PAPER, 130, 214, 96, 14, 0.9),
        3: shape('scallop', WATTLE, 88, -64, 210, 8) + shape('pebble', SKY, -50, 188, 160, -10) + shape('quatrefoil', WARATAH, 136, 206, 104, 0),
        4: shape('square', WATTLE, 108, -50, 180, 16) + shape('blossom', MINT, -54, 184, 170, 0) + shape('pill', WARATAH, 110, 222, 130, -14),
        5: shape('pebble', HARBOUR, 96, -46, 196, 0) + shape('quatrefoil', MOON, -44, 198, 140, 10) + shape('half', WARATAH, 132, 210, 104, -20),
        6: shape('blossom', WATTLE, 100, -50, 196, 0) + shape('scallop', HARBOUR, -52, 186, 160, -8) + shape('pebble', WARATAH, 132, 210, 100, 0),
    }[number]
    items = ''.join(f'<li><a href="#{a}">{html.escape(c)}<span>{page_of(a)}</span></a></li>' for c, a in contents)
    return (f'<section class="divider" style="background:{colour};color:{on}">{mark(f"sec-{number}")}{decor}'
            f'<div class="num">{number:02d}</div><h1>{html.escape(title)}</h1><p class="line">{html.escape(line)}</p><ol class="toc">{items}</ol></section>')

def flow_block(number, colour):
    title = by_number[number]
    name = title.split('. ', 1)[1]
    text = flows[title]
    first, _, rest = text.partition('\n')
    shots = SCREENS.get(number, [])
    figures = ''.join(f'<figure><img src="img/{f}.jpg"><span class="chip">{i}</span></figure>' for i, (f, _) in enumerate(shots, 1))
    captions = ''.join(f'<li><b>{i}</b> {html.escape(c)}</li>' for i, (_, c) in enumerate(shots, 1))
    anchor = f'flow-{number:02d}'
    spine = f'<div class="flowno" style="color:{colour}">{number:02d}</div>{tag("In short")}<p class="intent">{inline(first)}</p>'
    spine += (tag('Screens') + f'<ul class="captions">{captions}</ul>') if shots else callout('Screens', 'None pictured for this flow.')
    if number in NOTES: spine += callout('Note', NOTES[number])
    spine += callout('Source', f'`docs/flows.md`, journey {number}. The text is the design; the app does not yet do every step.')
    main = f'{mark(anchor)}<h2>{html.escape(name)}</h2>' + (f'<div class="shots">{figures}</div>' if shots else '') + md(rest)
    return spread(spine, main, 'flow')

parts = []

# Cover
parts.append(f'''<section class="cover">
{shape('quatrefoil', WARATAH, 92, -58, 210, 14)}{shape('pill', PAPER, -62, 150, 190, -28)}{shape('blossom', SKY, 118, 150, 130, 0)}{shape('pebble', GUM, -30, 236, 96, 8)}
<img class="hero" src="img/hero-waving.png">
<div class="rail">Working document · 14 November 2026</div>
<div class="word">puggle</div>
<div class="what">App screens,<br>flows and<br>the people<br>it is for</div>
</section>''')

# Contents: every page, each line a link, with its page number.
rows = ''
for number, title, colour, on, line, flow_numbers in SECTIONS:
    lines = ''.join(f'<a class="line" href="#{anchor}"><span class="what">{html.escape(label)}</span><span class="dots"></span><span class="pg">{page_of(anchor)}</span></a>'
                    for label, anchor in entries(number, flow_numbers))
    rows += (f'<div class="row"><a class="swatch" href="#sec-{number}" style="background:{colour};color:{on}">{number:02d}</a>'
             f'<div><a class="line head" href="#sec-{number}"><span class="what">{html.escape(title)}</span><span class="dots"></span><span class="pg">{page_of(f"sec-{number}")}</span></a>{lines}</div></div>')
parts.append('<section class="page front">' + spread(
    tag('About') + '<p class="intent">Screens are from the app as built on 14 November 2026, running a made-up sample family. No real family\'s data appears.</p>'
    + callout('Read this first', 'The flow text is the design. The app does not yet do every step described, and ten flows have no screens pictured.')
    + callout('Finding your way', 'Every line here is a link. The PDF also carries bookmarks, so the same list sits in your reader\'s sidebar.')
    + callout('The grid', 'Twelve columns. This spine, columns 1 to 3, carries captions, notes and sources. Text and screens sit in columns 4 to 12.')
    + callout('Colour', 'Each section has a brand colour: on its divider, in the running head and on its flow numbers. Words in the glossary are explained on the last pages.'),
    f'<h2>Contents</h2><div class="contents">{rows}</div>') + '</section>')

# Section 1
number, title, colour, on, line, _ = SECTIONS[0]
parts.append(divider(number, title, colour, on, line, entries(number, [])))
people = spread(
    f'<div class="flowno" style="color:{colour}">A</div>' + tag('In short') + '<p class="intent">Families with more than one child, and everyone who helps look after them.</p>'
    + callout('First household', 'A bottle-fed six-month-old and a potty-training two-and-a-half-year-old. Twins are an explicit design target.')
    + callout('Source', '`docs/baby-tracker-spec.md`, sections 1 and 4.'),
    mark('who') + '''<h2>Who it is for</h2>
<p class="lead">Every leading tracker is built around one baby and one subscription. Real families have a newborn and a toddler, or twins, plus a partner, grandparents and a nanny. Puggle is family-first: several children logged at once without switching profiles, properly native to iPhone, fairly priced, and calm.</p>
<div class="three">
<div><h4>Primary</h4><p>Parents of a newborn who also have an older child, and parents of twins or more.</p></div>
<div><h4>Secondary</h4><p>First-time parents who want a calmer, better-made tracker.</p></div>
<div><h4>Supporting cast</h4><p>A partner, grandparents, a nanny, daycare. A simple role, limited permissions, no account to make.</p></div>
</div>
<h4>The three levels in a family</h4>
<ul><li><b>Parent:</b> can do everything.</li><li><b>Helper:</b> logs the day, and can change only their own entries.</li><li><b>Viewer:</b> sees the day, cannot log.</li></ul>''')
cards = ''.join(f'<div class="persona"><div class="pn" style="color:{colour}">{i}</div><h4>{html.escape(n)}</h4><p class="dim">{html.escape(d)}</p><p>{html.escape(v)}</p></div>'
                for i, (n, d, v) in enumerate(PERSONAS, 1))
personas = spread(
    f'<div class="flowno" style="color:{colour}">B</div>' + tag('In short') + '<p class="intent">Eight personas walked the flows. Six testers then tried the built app.</p>'
    + callout('Not user testing', 'Both rounds were run by AI agents acting as a particular parent or carer. No real parent has used the app. They are good at finding gaps and unclear wording.')
    + callout('Read the verdicts as', 'A judgement on the design as it stood on 11 November. Many of the gaps have been worked on since.')
    + callout('Source', '`docs/persona-testing.md` and `docs/usability-findings.md`.'),
    f'{mark("personas")}<h2>Personas</h2><h3>Round 1: eight personas walk the flows</h3><p class="dim">11 November 2026. Under each: who they are, then whether they would keep using it.</p><div class="personas">{cards}</div>'
    f'<h3>Round 2: six testers on the built app</h3><p class="dim">13 November 2026.</p><ol>{"".join(f"<li>{html.escape(t)}</li>" for t in TESTERS)}</ol>')
glance = spread(
    f'<div class="flowno" style="color:{colour}">C</div>' + tag('In short') + '<p class="intent">Four tabs, a first run, and a few things outside the app.</p>'
    + callout('Source', '`docs/flows.md`, app map.'),
    mark('glance') + '<h2>The app at a glance</h2>' + md(flows['App map']))
parts.append(f'<section class="page s1">{people}</section><section class="page s1">{personas}</section><section class="page s1">{glance}</section>')

# Flow sections
for number, title, colour, on, line, flow_numbers in SECTIONS[1:5]:
    parts.append(divider(number, title, colour, on, line, entries(number, flow_numbers)))
    for n in flow_numbers:
        parts.append(f'<section class="page s{number}">{flow_block(n, colour)}</section>')

GLOSSARY = [
    ('Backup', 'A copy of the whole family kept on the phone. One is taken each day and before anything risky, and a parent can go back to one.'),
    ('Cast', 'Puggle\'s family and friends: Pebble, Mum, Dad, Nan, Pop, Kip, Quill, Digby and Sunny.'),
    ('Dynamic Type', 'The iPhone setting for larger or smaller text. The app follows it.'),
    ('Entry', 'One thing logged: a bottle, a sleep, a nappy.'),
    ('First run', 'The screens from installing the app to reaching Today. Also called onboarding.'),
    ('Flow', 'One path through the app, such as logging a feed. `docs/flows.md` calls these journeys and numbers them 1 to 17.'),
    ('Helper', 'The middle level in a family. Logs the day, and can change only their own entries.'),
    ('Holder', 'The person whose iCloud holds the family. Only they can invite people, remove them or change their level.'),
    ('Invite', 'How someone joins a family. It is sent through iCloud; nobody makes an account.'),
    ('Just logging', 'A setting that hides counters, totals and Insights, for a parent who wants to log and nothing more.'),
    ('Last saved', 'The bar on Today after a save, with Undo and Change. It stays until the next save.'),
    ('Live Activity', 'The iPhone feature that shows a running timer on the Lock Screen.'),
    ('Log sheet', 'The panel that opens from a tile, where an entry\'s details are set and saved.'),
    ('Night look', 'Darker, dimmer colours, on by default from 21:00 to 06:00.'),
    ('Parent', 'The top level in a family. Can do everything.'),
    ('Patterns', 'The part of Insights that shows how a child\'s days have changed with age. It needs five days with entries in a month before it says anything.'),
    ('Persona', 'An invented parent or carer, used to critique the design. Not a real user.'),
    ('Play pad', 'A full-screen pad for a child to stamp and draw on. It is held to close.'),
    ('Puggle', 'The app, and its character: a platypus, a girl, two and a half.'),
    ('Reduce Motion', 'The iPhone setting that asks apps to stop animation. The app shows still pictures.'),
    ('Room', 'Where Puggle is after 18:00: the tea table, the living room, the play room or her bedroom.'),
    ('Sample family', 'A made-up family, Ollie and Bea, for looking around. Its entries never mix with a real family\'s.'),
    ('Scene', 'The picture at the top of Today: hills, beach, backyard or bush, at the real time of day.'),
    ('Soft shapes', 'The brand\'s eight rounded shapes: quatrefoil, pill, scallop, soft square, soft hexagon, pebble, half pill and blossom.'),
    ('Spine', 'In this document, the narrow left column for captions, notes and sources.'),
    ('Stamp card', 'Potty rewards. Five stamps on a card earn a sticker.'),
    ('The tin, the box', 'The table on a formula tin or a medicine box, read from a photo, checked row by row by a parent, and shared with the family.'),
    ('Tile', 'A large button on Today that opens a log sheet: Feeding, Nappy, Potty.'),
    ('Today', 'The first tab. Every child at once, with tiles to log.'),
    ('Viewer', 'The lowest level in a family. Sees the day, cannot log.'),
    ('VoiceOver', 'The iPhone screen reader, for people who cannot see the screen.'),
    ('Widget', 'A small panel on the Home Screen or Lock Screen showing the family\'s day.'),
]
PROJECT_REFS = [
    ('`docs/flows.md`', 'The seventeen journeys and the app map. The flow text in this document.'),
    ('`docs/baby-tracker-spec.md`', 'The product specification: the thesis, who it is for, scope and design decisions.'),
    ('`docs/persona-testing.md`', 'Round 1: eight personas walk the flows, 11 November 2026.'),
    ('`docs/usability-findings.md`', 'Round 2: six testers on the built app, 13 November 2026, and what has been fixed since.'),
    ('`docs/app-vs-flows.md`', 'Where the app differs from the flows, 13 November 2026. Partly out of date.'),
    ('`docs/brand/Puggle-brand-2026-11-14.pdf`', 'The brand book: name, colour, type, Puggle, the cast, icons and the world.'),
    ('`docs/previews/reference/brief-for-chatgpt.md`', 'The handover brief: fixed rules, what is newer than the brand book, and what is open.'),
    ('`reports/Cartoon character craft for Puggle.md`', 'Research on character design and animation, 14 November 2026.'),
    ('`docs/for-review-tips-and-links.md`', 'The health links the app shows, and the rules for when, written for a GP to review.'),
    ('`docs/previews/screens/`', 'The screens pictured here, saved from the app on 14 November 2026.'),
]
OUTSIDE_REFS = [
    ('NHS website', 'The app links to NHS pages on sleep and weaning, credited "Information from the NHS website". It never rewords them.'),
    ('NASA Graphics Standards Manual, 1975', 'Danne & Blackburn. The model for this document\'s numbered sections and large numerals.'),
    ('Josef Müller-Brockmann, Grid Systems in Graphic Design', 'The asymmetric page with a narrow column for captions. Cited from memory, not checked.'),
    ('New York City Transit Authority Graphics Standards Manual, 1970', 'Unimark. Colour-coded sections. Cited from memory, not checked.'),
]
number, title, colour, on, line, _ = SECTIONS[5]
parts.append(divider(number, title, colour, on, line, entries(number, [])))
terms = ''.join(f'<div class="term"><dt>{html.escape(t)}</dt><dd>{inline(d)}</dd></div>' for t, d in GLOSSARY)
parts.append(f'<section class="page s6">' + spread(
    f'<div class="flowno" style="color:{HARBOUR}">A</div>' + tag('In short') + f'<p class="intent">{len(GLOSSARY)} words this document and the app use, in alphabetical order.</p>'
    + callout('App words', 'Parent, Helper, Viewer, Today, tile and the rest are the app\'s own words, as a parent sees them.')
    + callout('iPhone words', 'Dynamic Type, VoiceOver, Reduce Motion, Live Activity and widget are Apple\'s.'),
    f'{mark("glossary")}<h2>Glossary</h2><dl class="glossary">{terms}</dl>') + '</section>')
def reflist(items): return '<dl class="refs">' + ''.join(f'<div class="term"><dt>{inline(t)}</dt><dd>{inline(d)}</dd></div>' for t, d in items) + '</dl>'
parts.append(f'<section class="page s6">' + spread(
    f'<div class="flowno" style="color:{HARBOUR}">B</div>' + tag('In short') + '<p class="intent">Where everything in this document comes from.</p>'
    + callout('Paths', 'File paths are inside the project folder, `hello-world`.')
    + callout('Checked or not', 'Two of the design references are cited from memory and say so.'),
    f'{mark("references")}<h2>References</h2><h3>In the project</h3>{reflist(PROJECT_REFS)}<h3>Outside the project</h3>{reflist(OUTSIDE_REFS)}') + '</section>')

named = ''.join(f'''
@page s{number} {{ @top-left {{ content: "{number:02d}   {title}"; color: {colour if colour != WATTLE else '#B8892A'}; font: 700 8pt "Bricolage"; letter-spacing: 0.04em; vertical-align: bottom; padding-bottom: 3mm; }} }}'''
                for number, title, colour, *_ in [(n, t, HARBOUR if n == 6 else c) for n, t, c, *_ in SECTIONS])

css = f'''
@font-face {{ font-family: "Bricolage"; src: url("BricolageGrotesque-Variable.ttf"); font-weight: 200 800; }}
@page {{ size: A4; margin: 22mm 14mm 18mm 14mm;
  @top-right {{ content: "Puggle · App screens and flows"; color: #6B5E52; font: 8pt -apple-system, "Helvetica Neue", sans-serif; vertical-align: bottom; padding-bottom: 3mm; }}
  @bottom-right {{ content: counter(page); color: {INK}; font: 700 9pt "Bricolage"; vertical-align: top; padding-top: 4mm; }}
  @bottom-left {{ content: "14 November 2026 · Working document"; color: #6B5E52; font: 8pt -apple-system, "Helvetica Neue", sans-serif; vertical-align: top; padding-top: 4mm; }} }}
@page bleed {{ margin: 0; @top-right {{ content: none }} @top-left {{ content: none }} @bottom-right {{ content: none }} @bottom-left {{ content: none }} }}
@page front {{ @top-left {{ content: "Contents"; color: {INK}; font: 700 8pt "Bricolage"; letter-spacing: 0.04em; vertical-align: bottom; padding-bottom: 3mm; }} }}
{named}
* {{ box-sizing: border-box; }}
html {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
body {{ margin: 0; color: {INK}; font: 9.5pt/13.5pt -apple-system, "Helvetica Neue", Arial, sans-serif; }}
section {{ break-before: page; }}
section.page.front {{ page: front; }} section.cover, section.divider {{ page: bleed; position: relative; width: 210mm; height: 297mm; overflow: hidden; }}
{''.join(f"section.s{n} {{ page: s{n}; }}" for n, *_ in SECTIONS)}
.shape {{ position: absolute; }}

/* The grid: twelve columns with a 4 mm gutter. Spine 1 to 3, body 4 to 12. */
.grid {{ display: grid; grid-template-columns: repeat(12, 1fr); column-gap: 4mm; border-top: 0.6pt solid {INK}; padding-top: 4mm; }}
.spine {{ grid-column: 1 / 4; font-size: 7.6pt; line-height: 10.5pt; color: #5A4B40; padding-right: 2mm; }}
.main {{ grid-column: 4 / 13; border-left: 0.4pt solid #CFC3AC; padding-left: 4mm; }}

h1, h2, h3, .flowno, .num, .word {{ font-family: "Bricolage", sans-serif; font-weight: 800; font-variation-settings: "opsz" 96; letter-spacing: -0.02em; }}
h2 {{ font-size: 25pt; line-height: 27pt; margin: -1mm 0 5mm; }}
h3 {{ font-size: 13pt; line-height: 15pt; margin: 7mm 0 1.5mm; break-after: avoid; letter-spacing: 0; font-variation-settings: "opsz" 14; font-weight: 700; }}
h4 {{ font-size: 9.5pt; margin: 5mm 0 1mm; break-after: avoid; }}
p {{ margin: 0 0 2.4mm; }} ol, ul {{ margin: 0 0 3mm; padding-left: 4.4mm; }} li {{ margin-bottom: 1.3mm; break-inside: avoid; }}
code {{ font: 7.6pt ui-monospace, Menlo, monospace; background: {SAND}; padding: 0 1mm; border-radius: 1mm; }}
.lead {{ font-size: 11.5pt; line-height: 16pt; }} .dim {{ color: #6B5E52; }}

.flowno {{ font-size: 46pt; line-height: 40pt; margin: -1mm 0 4mm; }}
.tag {{ font: 700 6.4pt -apple-system, "Helvetica Neue", sans-serif; letter-spacing: 0.09em; text-transform: uppercase; color: {INK}; margin: 0 0 1mm; }}
.intent {{ font-size: 8.6pt; line-height: 11.5pt; color: {INK}; margin-bottom: 4.5mm; }}
.callout {{ border-top: 0.4pt solid #CFC3AC; padding-top: 1.6mm; margin-bottom: 3.5mm; break-inside: avoid; }}
.captions {{ list-style: none; padding: 0; margin: 0 0 4.5mm; }} .captions li {{ margin-bottom: 1mm; padding-left: 4.4mm; text-indent: -4.4mm; }}
.captions b {{ display: inline-block; width: 4.4mm; text-indent: 0; font-family: "Bricolage"; color: {INK}; }}

.shots {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 3mm; margin: 0 0 6mm; }}
figure {{ margin: 0; position: relative; break-inside: avoid; }}
figure img {{ width: 100%; display: block; border-radius: 3.4mm; border: 0.4pt solid #CFC3AC; }}
.chip {{ position: absolute; left: -1.6mm; top: -1.6mm; width: 5.4mm; height: 5.4mm; border-radius: 50%; background: {INK}; color: {PAPER}; border: 0.9pt solid #fff; font: 800 7pt "Bricolage"; text-align: center; line-height: 4.9mm; }}
.mark {{ font-size: 1pt; color: transparent; position: absolute; }}
a {{ color: inherit; text-decoration: none; }}

.glossary {{ columns: 2; column-gap: 6mm; margin: 0; }}
.term {{ break-inside: avoid; border-top: 0.4pt solid #CFC3AC; padding: 1.6mm 0 1.8mm; }}
dt {{ font: 800 9.5pt "Bricolage"; margin: 0 0 0.4mm; }} dd {{ margin: 0; font-size: 8.6pt; line-height: 11.8pt; }}
.refs {{ margin: 0 0 4mm; }} .refs dt {{ font: 600 8.6pt -apple-system, "Helvetica Neue", sans-serif; }}
.three {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 3mm; margin: 4mm 0; }}
.three div {{ background: {PAPER}; border: 0.4pt solid #CFC3AC; border-radius: 3mm; padding: 3mm; }} .three h4 {{ margin-top: 0; }}
.personas {{ display: grid; grid-template-columns: 1fr 1fr; gap: 0 5mm; }}
.persona {{ border-top: 0.4pt solid #CFC3AC; padding: 2.4mm 0 1mm 8mm; position: relative; break-inside: avoid; }}
.persona h4 {{ margin: 0 0 0.6mm; }} .persona p {{ margin-bottom: 1.2mm; font-size: 8.6pt; line-height: 11.5pt; }}
.pn {{ position: absolute; left: 0; top: 1.4mm; font: 800 17pt "Bricolage"; }}

.contents .row {{ display: grid; grid-template-columns: 13mm 1fr; gap: 4mm; border-top: 0.4pt solid #CFC3AC; padding: 2.6mm 0 2mm; break-inside: avoid; }}
.swatch {{ height: 13mm; border-radius: 3mm; font: 800 13pt "Bricolage"; display: flex; align-items: flex-end; padding: 0 0 1mm 1.6mm; }}
.line {{ display: flex; align-items: baseline; gap: 1.5mm; font-size: 9pt; line-height: 13pt; }}
.line.head {{ font: 800 12.5pt/16pt "Bricolage"; margin-bottom: 0.6mm; }}
.dots {{ flex: 1; border-bottom: 0.6pt dotted #9A8C7A; transform: translateY(-1mm); }}
.pg {{ font: 700 9pt "Bricolage"; min-width: 6mm; text-align: right; }} .line.head .pg {{ font-size: 12.5pt; }}

/* Dividers and the cover: full bleed. */
.divider .num {{ position: absolute; left: 14mm; top: 16mm; font-size: 150pt; line-height: 120pt; letter-spacing: -0.05em; }}
.divider h1 {{ position: absolute; left: 14mm; top: 92mm; margin: 0; font-size: 54pt; line-height: 52pt; width: 130mm; }}
.divider .line {{ position: absolute; left: 14mm; top: 150mm; width: 96mm; font-size: 12pt; line-height: 16.5pt; margin: 0; }}
.divider .toc {{ position: absolute; left: 14mm; top: 186mm; width: 96mm; margin: 0; padding: 0; list-style: none; font: 700 11pt/16pt "Bricolage"; counter-reset: none; }}
.divider .toc li {{ border-top: 0.5pt solid currentColor; padding: 1.4mm 0; margin: 0; }}
.divider .toc a {{ display: flex; justify-content: space-between; }}
.cover {{ background: {WATTLE}; }}
.cover .word {{ position: absolute; left: 12mm; top: 14mm; font-size: 150pt; line-height: 118pt; letter-spacing: -0.055em; color: {INK}; }}
.cover .what {{ position: absolute; left: 14mm; top: 70mm; font: 800 30pt/31pt "Bricolage"; letter-spacing: -0.02em; color: {INK}; }}
.cover .hero {{ position: absolute; right: -8mm; bottom: -34mm; width: 168mm; }}
.cover .rail {{ position: absolute; left: 7mm; bottom: 14mm; transform-origin: left bottom; transform: rotate(-90deg); font: 700 8pt -apple-system, "Helvetica Neue", sans-serif; letter-spacing: 0.1em; text-transform: uppercase; color: {INK}; white-space: nowrap; }}
'''
open(OUT, 'w').write(f'<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Puggle: app screens and flows</title><style>{css}</style></head><body>{"".join(parts)}</body></html>')
print('written', OUT)
