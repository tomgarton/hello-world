"""The import mock-up (15 November 2026): what the import screen says when a file overlaps with entries
already in the family, and when someone who has just joined is still catching up with iCloud.

Run `python3 docs/tools/make_import_mockup.py` from the repo. Writes docs/previews/import/overlaps.html.
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'previews', 'import', 'overlaps.html')

CSS = '''
:root{--ink:#3A2A20;--paper:#FBF6E9;--sand:#F2ECDD;--field:#EAE2D2;--muted:#6B5E52;--line:#DDD2BC;--red:#B23A26;--blue:#2A62B8}
*{box-sizing:border-box}
body{margin:0;background:#E4DCC8;color:var(--ink);font:15px/1.35 -apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;padding:34px;width:1100px}
h1{font-size:30px;margin:0 0 4px;letter-spacing:-.02em}.lede{color:var(--muted);font-size:16px;margin:0 0 22px;max-width:92ch}
.row{display:flex;gap:30px;align-items:flex-start}.col{width:324px}
.cap{font-weight:700;margin:0 0 8px}.cap span{color:var(--red);margin-right:6px}.note{color:var(--muted);font-size:14px;margin:10px 2px 0}
.phone{width:324px;height:700px;background:var(--sand);border-radius:38px;overflow:hidden;border:1px solid var(--line);padding:54px 16px 0}
.nav{display:flex;align-items:center;justify-content:center;position:relative;height:36px;font-weight:650;font-size:16px;margin-bottom:10px}
.nav i{position:absolute;left:0;font-style:normal;color:var(--blue);font-weight:500}
.hd{font-size:12.5px;color:var(--muted);text-transform:uppercase;letter-spacing:.02em;margin:16px 14px 6px}
.ft{font-size:12.5px;color:var(--muted);margin:6px 14px 0}
.card{background:var(--paper);border-radius:14px;overflow:hidden}
.r{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:11px 14px;border-top:1px solid var(--line);font-size:15px}
.r:first-child{border-top:0}.r em{font-style:normal;color:var(--muted)}.r.link{color:var(--blue)}.r.off{color:#B5AA98}
.r b{font-weight:650}
.seg{display:flex;background:var(--field);border-radius:10px;padding:2px;margin:10px 14px 12px}
.seg span{flex:1;text-align:center;padding:6px 0;border-radius:8px;font-size:13.5px;font-weight:600}
.seg .on{background:var(--paper);box-shadow:0 1px 3px rgba(58,42,32,.2)}
.pair{padding:11px 14px;border-top:1px solid var(--line)}.pair:first-child{border-top:0}
.pair p{margin:0;font-size:14.5px}.pair p small{display:inline-block;width:76px;color:var(--muted);font-size:12.5px}
.spin{width:18px;height:18px;border-radius:50%;border:2.5px solid var(--line);border-top-color:var(--muted)}
'''

def phone(title, body):
    return f'<div class="phone"><div class="nav"><i>‹ Your data</i>{title}</div>{body}</div>'

A = phone('Import', '''
<div class="card"><div class="r">Entries from the Baby Tracker app can be brought in from its CSV export.</div></div>
<div class="card" style="margin-top:16px"><div class="r"><span>Catching up with the family</span><span class="spin"></span></div>
<div class="r off">Choose the export file</div></div>
<p class="ft">You joined a few minutes ago and entries are still arriving from iCloud. Importing now could add entries that are already on their way.</p>
<div class="card" style="margin-top:16px"><div class="r link">Import now</div></div>
<p class="ft">For when this phone has no connection and the wait will not end.</p>''')

B = phone('Import', '''
<div class="hd">What the file holds</div>
<div class="card"><div class="r">From<em>2 Jun 2026</em></div><div class="r">To<em>14 Nov 2026</em></div>
<div class="r">Bottles<em>412</em></div><div class="r">Sleeps<em>388</em></div><div class="r">Nappy changes<em>530</em></div></div>
<div class="hd">Possibly already here</div>
<div class="card"><div class="r"><span><b>9 entries</b> overlap with ones already in the family</span></div>
<div class="seg"><span class="on">Leave them out</span><span>Bring them in</span></div>
<div class="r link">Look at the 9<span>›</span></div></div>
<p class="ft">A sleep or feed for the same child at a time that overlaps one logged here. It is likely the same one, entered in both apps.</p>
<div class="card" style="margin-top:16px"><div class="r link"><b>Import 1,321 entries</b></div></div>
<p class="ft">A backup is made first, and the whole import can be undone from this screen.</p>''')

def pair(what, file, here, who, keep=False):
    seg = '<span>Leave out</span><span class="on">Keep both</span>' if keep else '<span class="on">Leave out</span><span>Keep both</span>'
    return (f'<div class="card" style="margin-top:12px"><div class="pair"><p><b>{what}</b></p>'
            f'<p><small>In the file</small>{file}</p><p><small>Already here</small>{here}, by {who}</p></div>'
            f'<div class="seg">{seg}</div></div>')

C = phone('9 overlap', '<p class="ft" style="margin-top:0">Ollie, newest first.</p>'
          + pair('Sleep, Fri 13 Nov', '1:10 to 2:40 pm', '1:02 to 2:35 pm', 'Alex')
          + pair('Sleep, Fri 13 Nov', '7:20 pm to 6:05 am', '7:15 pm to 6:10 am', 'Alex')
          + pair('Breastfeed, Thu 12 Nov', '3:40 pm, 14 min', '3:44 pm, 12 min', 'Robin', keep=True)
          + pair('Sleep, Thu 12 Nov', '9:30 to 10:15 am', '9:34 to 10:15 am', 'Nan'))

PAGE = f'''<!doctype html><meta charset="utf-8"><style>{CSS}</style>
<h1>Import: overlaps and catching up</h1>
<p class="lede">Two changes to the import screen, for a family where both parents bring entries in. Nothing here is built yet.</p>
<div class="row">
<div class="col"><p class="cap"><span>A</span>Just joined</p>{A}<p class="note">Shown only while entries are still arriving after joining. The wait ends by itself.</p></div>
<div class="col"><p class="cap"><span>B</span>The file overlaps</p>{B}<p class="note">Left out unless the person importing says otherwise. The count on the button already leaves them out.</p></div>
<div class="col"><p class="cap"><span>C</span>Looking at them</p>{C}<p class="note">Each pair can be decided by itself. The entry already here is never changed.</p></div>
</div>'''

open(OUT, 'w').write(PAGE)
print('wrote', OUT)
