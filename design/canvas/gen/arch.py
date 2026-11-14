import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/express.py').read(); src = src[:src.index('EX = [')]
x = {}; exec(src, x)
O, head, body, wrap = x['O'], x['head'], x['body'], x['wrap']
w = {'__name__': 'x'}; ws = open(ROOT + '/gen/world.py').read(); exec(ws[:ws.index('walls = f')], w); inner = w['inner']
B = "font-family: 'Bricolage Grotesque', system-ui, sans-serif; font-weight: 800; letter-spacing: -0.04em"
def wm(px, color=O): return f'<div style="{B}; font-size: {px}px; line-height: 1; color: {color}">puggle</div>'
icon = f'<div style="width: 120px; height: 120px; border-radius: 28px; background: #F4BE2C; display: flex; align-items: center; justify-content: center; overflow: hidden"><svg role="img" aria-label="App icon" width="112" height="100" viewBox="40 34 160 146">{head("happy")}</svg></div>'
appstore = (f'<div style="display: flex; gap: 14px; align-items: center">{icon}<div style="display: flex; flex-direction: column; gap: 4px"><div style="font-size: 20px; font-weight: 800">Puggle</div><div style="font-size: 14px; font-weight: 500; color: #4A3B30">Baby and family tracker</div>'
            f'<div style="width: 76px; height: 30px; border-radius: 15px; background: #2A62B8; color: #FBF6E9; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 800">Get</div></div></div>')
label = f'<div style="width: 190px; height: 70px; background: #FBF6E9; border: 2px dashed #C9B89F; outline: 6px solid {O}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px">{wm(34)}<div style="font-size: 10px; font-weight: 700; letter-spacing: 0.12em">2–3 YEARS</div></div>'
company = f'<div style="display: flex; flex-direction: column; gap: 4px"><div style="{B}; font-size: 30px; color: {O}">Puggle &amp; Co.</div></div>'
cast = ''.join(f'<g transform="translate({i*84} 0) scale(0.35)">{s}</g>' for i, s in enumerate([body('wave', 'happy', '#2A62B8'), inner('koala', 'dress', '#F4BE2C'), inner('wombat', 'tee', '#E5553B'), inner('echidna', 'dungarees', '#3C9A5F')]))
book = (f'<div style="width: 300px; height: 160px; background: #BFD9F5; display: flex; flex-direction: column; justify-content: space-between; padding: 16px 18px 10px 18px; box-sizing: border-box">'
        f'<div style="{B}; font-size: 30px; line-height: 1; color: {O}">Puggle<span style="font-size: 22px; font-weight: 700; letter-spacing: 0"> and Friends</span></div>'
        f'<svg role="img" aria-label="Puggle, Kip, Digby and Quill" width="264" height="84" viewBox="0 0 330 104">{cast}</svg></div>')
def tile(title, inner_html, note):
    return f'<div style="display: flex; flex-direction: column; gap: 10px"><div style="font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636">{title}</div>{inner_html}<div style="font-size: 13px; font-weight: 500; color: #4A3B30; max-width: 360px; line-height: 1.4">{note}</div></div>'
bodyh = f'''<div style="width: 1080px; height: 560px; box-sizing: border-box; background: #F2ECDD; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 26px">
<h1 style="margin: 0; font-size: 34px; font-weight: 800; letter-spacing: -0.02em">One name, many places</h1>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 30px 40px">
{tile("Master brand", wm(76), "Puggle alone: the character, logotype and trademark. Like Miffy, Bluey, Peppa.")}
{tile("App", appstore, "Puggle on the home screen; the subtitle does the explaining for search.")}
{tile("Clothing label", label, "Puggle on the tag. Short enough for a woven label.")}
{tile("Stories and shows", book, "Puggle and Friends: the series name, as Miffy and Friends was.")}
{tile("Company", company, "The company: the legal and trading name, in footers and on invoices.")}
</div>
</div>'''
wrap('One name, many places', bodyh, 1080, 560, 'Architecture.dc.html', 23380)
