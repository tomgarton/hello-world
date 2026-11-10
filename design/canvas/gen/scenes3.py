import sys, json, math, random
ROOT = sys.argv[1]
_t = open(ROOT + '/gen/three.py').read()
exec(_t[:_t.index('# ---------------- board ----------------')])     # helpers, cast, morning, bedtime, celebrate
adult, quokka = cx['adult'], cx['quokka_kid']
def grown(kind, col): return small(adult(col, kind))
def kid(animal, outfit, col, acc=''): return small(friend(animal, outfit, col)) + acc
def sunny(col): return small(quokka(col)) + ACC['sunhat'](SUN)
def digby(col): return small(friend('wombat', 'tee', col)) + ACC['beanie'](WARATAH)
def kip(col): return small(friend('koala', 'dress', col)) + ACC['bow'](150, 50, HARBOUR)
def quill(col): return small(friend('echidna', 'dungarees', col))
def A_(svg, x, base, h=128): return put(svg, x, base, h, 456)          # grown-up
def K_(svg, x, base, h=86): return put(svg, x, base, h)                 # child
def B_(x, base, col=A): return put(small(baby('happy', col)), x, base, 52, 270)
def sh(x, y, w, c, o=1): return e(x, y, w, w*0.16, c, o)
def bgc(c): return f'<rect x="0" y="0" width="{W}" height="{Hh}" fill="{c}"></rect>'
def band(y0, y1, c, o=1): return f(f'M-4 {y0}H{W+4}V{y1}H-4Z', c, o)
def wavy(x0, x1, y, amp, step, depth, c, o=1):
    d = f'M{x0} {y}'; x = x0
    while x < x1: d += f'q{step/4} {-amp} {step/2} 0t{step/2} 0'; x += step
    return f(d + f'v{depth}H{x0}Z', c, o)
def cloudf(cx_, cy, w, c=PAPER, o=1): return f(scallop(cx_, cy, w/2, w/5, 7, True), c, o)
def gullf(x, y, s=1, c=PAPER): return stroke(f'M{x} {y}q{6*s} {-7*s} {12*s} 0q{6*s} {-7*s} {12*s} 0', c, 2.4)
def awn(x0, x1, y, h, c, c2=PAPER, n=None):
    n = n or max(int((x1 - x0)/26), 3); w = (x1 - x0)/n; out = ''
    for i in range(n):
        col = c if i % 2 == 0 else c2
        out += f(f'M{x0+i*w:.1f} {y}h{w:.1f}v{h}a{w/2:.1f} {w/2.6:.1f} 0 0 1 {-w:.1f} 0z', col)
    return out
def glass(x, y, w, h, c='#6E8798', hi='#8FA6B5'):
    return f(R(x, y, w, h, 6), c) + f(f'M{x+w*0.12:.0f} {y+h}L{x+w*0.42:.0f} {y}h{w*0.12:.0f}L{x+w*0.24:.0f} {y+h}Z', hi, 0.7) + f(f'M{x+w*0.5:.0f} {y+h}L{x+w*0.8:.0f} {y}h{w*0.05:.0f}L{x+w*0.55:.0f} {y+h}Z', hi, 0.7)

BL0, BL1, BL2, BL3 = '#D5E8FA', '#A9C6EC', '#7FA9E0', '#6795D6'      # sky and water tones
SN0, SN1, SN2 = '#F4E7B0', '#E9D79A', '#DCC57F'                      # sand tones
WOOD = '#B0835A'

# ---------- Beach ----------
def big_umbrella(cx_, cy, rx, ry):
    out = ''
    for i in range(6):
        a0, a1 = math.radians(180 + i*30), math.radians(180 + (i+1)*30)
        p0 = (cx_ + rx*math.cos(a0), cy + ry*math.sin(a0)); p1 = (cx_ + rx*math.cos(a1), cy + ry*math.sin(a1))
        out += f(f'M{cx_} {cy}L{p0[0]:.1f} {p0[1]:.1f}A{rx} {ry} 0 0 1 {p1[0]:.1f} {p1[1]:.1f}Z', WARATAH if i % 2 == 0 else PAPER)
    return out + f(f'M{cx_-rx} {cy}H{cx_+rx}v7H{cx_-rx}Z', '#C9432F', 0.35)
beach = (bgc(BL0) + cloudf(70, 46, 80, PAPER, 0.9) + gullf(150, 70) + gullf(178, 58, 0.8)
         + f('M-4 120Q34 92 96 120Z', BL1) + band(120, 190, BL2) + band(120, 132, BL3) + wavy(-4, W + 4, 152, 2.5, 30, 3, PAPER, 0.7)
         + band(178, Hh + 4, SN0) + band(178, 194, SN1) + wavy(-4, W + 4, 180, 3, 22, 7, PAPER)
         + stroke('M52 180V150M74 180V150', '#8FA9D6', 2) + f('M52 150h14v6h-14z', WARATAH) + f('M52 156h14v6h-14z', A) + f('M74 150h14v6h-14z', WARATAH) + f('M74 156h14v6h-14z', A)
         + e(262, 276, 150, 22, SN2)                                                                                     # the umbrella's shadow
         + stroke('M300 112L316 286', WOOD, 5) + big_umbrella(300, 112, 156, 104)
         + f('M92 286V262h8v-7h7v7h8v-7h7v7h8v-7h7v7h5V286Z', SN2) + f('M108 255V238h5v-6h6v6h5v-6h5v17Z', SN2) + f('M92 286V262h8v-7h4v31Z', SN1) + stroke('M121 232V218', WOOD, 2) + f('M121 218l10 3.5-10 3.5z', WARATAH)
         + f('M-10 250l74 -12l10 34l-74 14z', SKY) + f('M12 246l12 -2l10 35l-12 2zM40 242l12 -2l10 34l-12 2z', PAPER)
         + sh(190, 289, 44, SN2) + K_(pug('tada', 'proud', A), 190, 290) + B_(268, 290, SKY))
# ---------- Bush walk ----------
bush = (bgc('#E3EEFA') + f'<circle cx="120" cy="96" r="52" fill="{PAPER}" opacity="0.6"></circle><circle cx="120" cy="96" r="30" fill="{A}"></circle>'
        + f('M-4 132Q60 84 140 112T270 92T394 112V304H-4Z', '#C3D7F1') + f('M-4 160Q80 122 180 148T394 132V304H-4Z', BL1) + f('M-4 186Q100 160 200 178T394 168V304H-4Z', BL2)
        + f(scallop(64, 164, 22, 16, 7), '#8FB0E4') + f(scallop(96, 170, 14, 11, 6), '#8FB0E4')
        + f('M-4 208Q120 190 240 204T394 198V304H-4Z', '#CFE5D2') + f('M-4 208Q120 190 240 204T394 198V214Q250 216 120 206T-4 222Z', '#E3F1E0')
        + f('M150 304C150 262 214 256 232 236S262 214 280 208L288 211C276 220 262 232 252 246S226 274 226 304Z', '#F2E6C4')
        + f('M318 304L150 304L318 262Z', '#B2D3B9')                                                                      # the big gum's shadow
        + f('M312 304C318 200 326 100 318 -4H374C368 100 374 200 388 304Z', '#F1E3D3') + f('M352 304C356 200 360 100 356 -4H374C368 100 374 200 388 304Z', '#E0CDB8')
        + stroke('M330 210q6 10 2 24M338 110q5 12 0 26M344 54q4 8 0 18', '#D2BBA2', 3)
        + f(scallop(330, 14, 120, 44, 11), T1) + f(scallop(250, 2, 70, 30, 8), T2) + f(scallop(384, 40, 50, 30, 7), T2)
        + leaves(-10, 268, T2) + gullf(214, 56, 0.7, '#9DB6DC')
        + sh(128, 287, 34, '#B2D3B9') + sh(196, 289, 42, '#B2D3B9') + K_(quill(A), 128, 288, 80) + K_(pug('wave', 'happy', HARBOUR), 196, 290))
# ---------- Sydney Harbour ----------
NV, NV2, STONE, STONE2 = '#2C3E73', '#3E5290', '#EBD2AC', '#D6B88C'
def arch(x0, x1, y):
    span = x1 - x0; m = (x0 + x1)/2; to, ti = y - span*0.74, y - span*0.46
    out = f(f'M{x0} {y}Q{m} {to} {x1} {y}L{x1-14} {y}Q{m} {ti} {x0+14} {y}Z', NV)
    for i in range(1, 12):
        u = i/12; xx = x0 + 14 + (span - 28)*u; yy = (1-u)**2*y + 2*(1-u)*u*ti + u*u*y
        out += stroke(f'M{xx:.1f} {yy:.1f}V{y}', NV, 1.6)
    out += f(f'M{x0-60} {y-5}H{x1+60}v7H{x0-60}Z', NV)
    for px in (x0 - 22, x1 + 22):
        out += f(R(px-13, y-58, 26, 62, 2), STONE) + f(f'M{px+4} {y-58}h9v62h-9z', STONE2) + f(R(px-15, y-63, 30, 7, 2), STONE)
    return out
def ferryf(x, y, s=1):
    out = f(f'M{x-50*s} {y-14*s}H{x+50*s}L{x+42*s} {y}H{x-42*s}Z', T1) + f(R(x-36*s, y-30*s, 72*s, 16*s, 3), PAPER) + f(f'M{x-36*s} {y-20*s}h{72*s}v{6*s}h{-72*s}z', A) + f(R(x-20*s, y-42*s, 40*s, 12*s, 3), PAPER)
    out += ''.join(f'<circle cx="{x - 28*s + i*11.2*s:.1f}" cy="{y-25*s:.1f}" r="{2.2*s:.1f}" fill="{NV}"></circle>' for i in range(6))
    return out + stroke(f'M{x} {y-42*s}V{y-52*s}', NV, 1.6) + f(f'M{x} {y-52*s}l{9*s} {3*s}-{9*s} {3*s}z', WARATAH)
HB = 128
harbour = (bgc('#F6CFA4') + band(64, HB, '#FBE3C0') + f'<circle cx="150" cy="{HB-6}" r="64" fill="{PAPER}" opacity="0.45"></circle><circle cx="150" cy="{HB-6}" r="40" fill="{A}"></circle>'
           + cloudf(318, 40, 70, '#FBE9D2')
           + ''.join(f(R(x, HB-h, w, h, 3), '#E6B58C') + ''.join(f(R(x+5, HB-h+8+r*13, w-10, 3, 1.5), A, 0.9) for r in range(int(h/15))) for x, w, h in ((292, 26, 46), (320, 22, 70), (344, 30, 40), (372, 24, 58)))
           + band(HB, Hh + 4, '#5E86CF') + band(HB, HB + 12, '#4E74BD')
           + ''.join(f(R(150 - w/2, y, w, 5, 2.5), A) for y, w in ((HB + 6, 66), (HB + 18, 50), (HB + 30, 34), (HB + 44, 20)))
           + arch(46, 254, HB) + wavy(250, 394, 176, 2.5, 30, 3, PAPER, 0.5)
           + f('M236 204q-40 8 -92 2q52 0 92 -8z', PAPER, 0.8) + f('M240 212q-56 12 -126 6q70 -2 126 -12z', PAPER, 0.6) + ferryf(292, 208, 1)
           + band(250, Hh + 4, STONE) + band(250, 256, '#F5E4C6') + stroke(''.join(f'M{x} 250V224' for x in range(8, 400, 40)), NV, 3.2) + stroke('M-4 224H394M-4 237H394', NV, 2.2)
           + sh(98, 291, 40, STONE2) + sh(172, 290, 40, STONE2) + A_(grown('pop', SKY), 98, 292) + K_(pug('wave', 'happy', WARATAH), 172, 291) + gullf(214, 44, 0.9, '#FBE9D2'))
# ---------- The park ----------
def slidef(x, y):
    return (stroke(f'M{x} {y}V{y-84}M{x+20} {y}V{y-84}', WOOD, 4) + stroke(''.join(f'M{x} {y-14-i*17}h20' for i in range(4)), WOOD, 3)
            + f(f'M{x+20} {y-84}C{x+56} {y-84} {x+66} {y-8} {x+104} {y-6}l-2 10C{x+58} {y+4} {x+48} {y-72} {x+20} {y-72}Z', WARATAH) + f(f'M{x+20} {y-76}C{x+50} {y-74} {x+60} {y-2} {x+102} {y}l0 4C{x+58} {y+4} {x+48} {y-72} {x+20} {y-72}Z', '#C9432F') + f(R(x-5, y-94, 30, 11, 4), A))
def swingf(x, y):
    out = stroke(f'M{x-42} {y}L{x-30} {y-90}L{x-18} {y}M{x+42} {y}L{x+30} {y-90}L{x+18} {y}M{x-32} {y-90}H{x+32}', WOOD, 4)
    for sx, c in ((-12, SKY), (12, PAPER)): out += stroke(f'M{x+sx-6} {y-90}V{y-30}M{x+sx+6} {y-90}V{y-30}', WOOD, 1.6) + f(R(x+sx-9, y-32, 18, 6, 3), c)
    return out
def kitef(x, y):
    return f(rpoly([(x, y-26), (x+18, y), (x, y+30), (x-18, y)], 3), A) + f(rpoly([(x, y-26), (x+18, y), (x, y)], 2), '#F9D465') + stroke(f'M{x} {y+30}q-10 18 4 30q12 14 -2 30', WARATAH, 1.8)
park = (bgc(BL0) + cloudf(300, 44, 70) + kitef(262, 62) + band(196, Hh + 4, '#CFE5D2') + f('M-4 196Q200 180 394 198V206Q200 192 -4 206Z', '#E3F1E0')
        + swingf(292, 220) + slidef(150, 224) + sh(200, 226, 52, '#B2D3B9') + sh(292, 222, 46, '#B2D3B9')
        + e(96, 272, 170, 36, '#B2D3B9') + ''.join(e(x, y, r, r*0.5, '#CFE5D2') for x, y, r in ((30, 262, 12), (70, 284, 9), (120, 258, 10), (160, 276, 8), (206, 268, 6), (4, 286, 8)))   # dappled shade
        + f('M22 304C28 220 34 140 28 60H64C60 140 66 220 74 304Z', '#F1E3D3') + f('M50 304C54 220 56 140 52 60H64C60 140 66 220 74 304Z', '#E0CDB8')
        + stroke('M36 250q6 12 2 28M40 170q5 12 0 26M34 110q4 10 0 20', '#D2BBA2', 3) + e(46, 214, 5, 8, '#D2BBA2') + f('M22 304Q10 296 -2 300V304Z', '#F1E3D3') + f('M74 304Q88 294 100 300V304Z', '#E0CDB8')
        + f(scallop(60, 44, 150, 62, 12), T1) + f(scallop(150, 22, 80, 40, 8), T2) + f(scallop(-10, 88, 60, 36, 7), T2)
        + e(332, 292, 50, 6, '#B2D3B9') + f('M284 258l76 -11l11 29l-76 13z', PAPER) + ''.join(stroke(f'M{284+76*t:.0f} {258-11*t:.0f}l11 29', BLUSH, 4) + stroke(f'M{284+11*t:.0f} {258+29*t:.0f}l76 -11', BLUSH, 4) for t in (0.25, 0.5, 0.75))
        + sh(196, 289, 42, '#9CC4A5') + sh(256, 288, 36, '#9CC4A5') + K_(pug('up', 'happy', HARBOUR), 196, 290) + K_(kip(A), 256, 289, 84))
# ---------- Rainy day ----------
RG0, RG1, RG2, RG3 = '#C5D3E2', '#AFC0D4', '#8FA3BC', '#7389A6'
def rainf():
    """Rain in two depths, gusting: far drops short and faint, near drops longer and brighter, with gaps and small bursts."""
    rnd = random.Random(9); out = ''
    for _ in range(70):                                   # far
        x, y = rnd.uniform(-10, 400), rnd.uniform(78, 250); l = rnd.uniform(6, 10)
        out += stroke(f'M{x:.1f} {y:.1f}l{-l*0.42:.1f} {l:.1f}', PAPER, 1.3, rnd.uniform(0.3, 0.5))
    n = 0
    while n < 46:                                         # near, in loose gusts
        gx, gy = rnd.uniform(-10, 400), rnd.uniform(70, 262)
        for _ in range(rnd.choice([1, 1, 2, 3])):
            x, y = gx + rnd.uniform(-16, 16), gy + rnd.uniform(-22, 22); l = rnd.uniform(11, 20)
            out += stroke(f'M{x:.1f} {y:.1f}l{-l*0.42:.1f} {l:.1f}', PAPER, rnd.uniform(1.8, 2.6), rnd.uniform(0.6, 0.9)); n += 1
    for x, y in ((40, 236), (86, 258), (318, 262), (356, 228), (20, 276), (366, 280), (300, 222)):   # little splashes where drops land
        out += stroke(f'M{x-5} {y}q2 -5 5 -1M{x+1} {y-1}q3 -4 5 1', PAPER, 1.4, 0.8)
    return out
def rainbowf(cx_, cy, r):
    return ''.join(stroke(f'M{cx_-(r-i*9)} {cy}A{r-i*9} {r-i*9} 0 0 1 {cx_+(r-i*9)} {cy}', c, 9, 0.7) for i, c in enumerate((WARATAH, A, T1, SKY)))
rainy = (bgc(RG0) + rainbowf(352, 208, 70) + f('M-4 208V176L40 150L84 176V160H140V208Z', RG1) + f('M150 208V168Q190 146 230 168V208Z', RG1)
         + f(scallop(120, 46, 200, 44, 12, True), RG2) + f(scallop(330, 30, 120, 30, 9, True), RG1) + f(scallop(40, 26, 110, 26, 8, True), RG3)
         + band(208, Hh + 4, '#A9C9B0') + band(208, 218, '#97BBA0') + rainf()
         + e(190, 284, 132, 17, '#B9CDE4') + e(190, 284, 96, 11, '#D3E2F2') + e(330, 240, 40, 6, '#B9CDE4')
         + ''.join(f(f'M{x} 280q{dx*0.5:.0f} {-h} {dx} {-h*0.2:.0f}q{-dx*0.3:.0f} {h*0.5:.0f} {-dx} {h*0.2:.0f}z', PAPER, 0.9) for x, dx, h in ((160, -34, 34), (226, 34, 34), (150, -52, 16), (236, 52, 16)))
         + ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}"></circle>' for x, y, r in ((122, 246, 3), (262, 244, 3), (106, 266, 2.4), (280, 264, 2.4), (140, 232, 2), (246, 230, 2)))
         + K_(pug('up', 'laughing', A), 192, 284) + sh(300, 289, 36, '#8FB39A') + K_(digby(HARBOUR), 300, 290, 90))
# ---------- The pool ----------
def lanef(y, c):
    return stroke(f'M-4 {y}H394', PAPER, 1.4, 0.8) + ''.join(f'<circle cx="{x}" cy="{y}" r="3.4" fill="{c if i % 2 else PAPER}"></circle>' for i, x in enumerate(range(0, 396, 10)))
def ringf(x, y, r):
    out = e(x + 4, y + 6, r*1.05, r*0.5, BL3, 0.7) + f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}"></circle>'
    for a in (0, 90, 180, 270):
        out += f(f'M{x} {y}L{x + r*math.cos(math.radians(a-24)):.1f} {y + r*math.sin(math.radians(a-24)):.1f}A{r} {r} 0 0 1 {x + r*math.cos(math.radians(a+24)):.1f} {y + r*math.sin(math.radians(a+24)):.1f}Z', WARATAH)
    return out + f'<circle cx="{x}" cy="{y}" r="{r*0.46:.1f}" fill="{BL2}"></circle>'
PAVE, PAVE2 = '#FBF6E9', '#EADFCB'
pool = (bgc(BL0) + ''.join(f(rpoly([(x-10, 14 + 30*2*t*(1-t)), (x+10, 14 + 30*2*t*(1-t)), (x, 34 + 30*2*t*(1-t))], 2.5), (WARATAH, PAPER, A)[i % 3]) for i, (x, t) in enumerate(((-6 + 402*(k+0.5)/11, (k+0.5)/11) for k in range(11))))
        + stroke(f'M-6 12Q195 44 396 12', '#9DB6DC', 1.6)
        + ''.join(f(scallop(x, 112, 34, 20, 7, True), T1) for x in range(10, 420, 56)) + ''.join(f(scallop(x, 114, 22, 12, 6, True), T2) for x in range(38, 420, 56))
        + band(112, 142, PAVE) + band(136, 142, PAVE2) + e(120, 128, 70, 8, PAVE2)
        + stroke('M40 128V52M196 128V64', WOOD, 3.4) + f('M40 52Q120 70 196 64Q150 84 132 104Q96 76 40 52Z', MINT) + f('M132 104Q150 84 196 64Q160 92 132 104Z', '#B2D3B9')
        + band(142, 252, BL2) + band(142, 152, BL3) + wavy(-4, 394, 176, 3, 44, 5, PAPER, 0.45) + wavy(20, 394, 226, 3, 52, 5, PAPER, 0.45) + lanef(164, WARATAH) + lanef(204, A)
        + ringf(318, 228, 22)
        + band(252, Hh + 4, PAVE) + band(252, 258, PAVE2) + stroke(''.join(f'M{x} 258V304' for x in range(20, 400, 46)), PAVE2, 1.4)
        + stroke('M352 262V226q0-9 9-9M372 262V226q0-9 9-9', '#9DB6DC', 4) + f(R(26, 276, 46, 15, 7), A)
        + sh(190, 289, 42, PAVE2) + sh(252, 288, 36, PAVE2) + K_(pug('up', 'happy', WARATAH), 190, 290) + K_(sunny(T1), 252, 289, 92))
# ---------- Grandma's house ----------
WALL, WALL2, ROOF2 = '#FBF6E9', '#ECE2CE', '#C9432F'
grandma = (bgc(BL0) + cloudf(318, 46, 80) + f(scallop(330, 196, 60, 40, 9), T1) + f(scallop(372, 204, 40, 30, 7), T2)
           + band(216, Hh + 4, '#CFE5D2')
           + ''.join(f(f'M{x} 218V196l5 -6l5 6V218Z', PAPER) for x in range(232, 396, 14)) + band(204, 208, PAPER, 1).replace('M-4 204H394', 'M232 204H394')
           + f('M176 20h20v40h-20z', WALL2) + ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}"></circle>' for x, y, r in ((188, 10, 6), (196, -4, 8)))
           + f('M-30 228V106H214V228Z', WALL) + f('M-30 124H214V228H-30Z', WALL2)                                          # verandah shade on the wall
           + ''.join(stroke(f'M-30 {y}H214', '#DDD0B8', 1) for y in range(140, 228, 14))
           + f('M-44 108L22 34H178L236 108Z', WARATAH) + f('M100 34H178L236 108H150Z', ROOF2)                              # one big shape: the roof
           + f('M-40 106H236v12H-40Z', PAPER) + ''.join(f(R(x-4, 118, 8, 110, 2), PAPER) for x in (40, 136, 222))
           + f(R(78, 150, 40, 78, 4), A) + f'<circle cx="110" cy="192" r="2.4" fill="{WOOD}"></circle>' + glass(160, 152, 44, 40, '#9DB6DC', '#C3D7F1') + glass(-6, 152, 30, 40, '#9DB6DC', '#C3D7F1')
           + f('M-30 228H236L290 256H-30Z', '#B2D3B9')                                                                     # the house's shadow on the lawn
           + f('M78 228C84 256 190 262 250 304H318C250 262 150 250 118 228Z', '#F2E6C4')
           + ''.join(f(scallop(x, 232, 26, 17, 8), T1) + f(scallop(x-8, 226, 10, 8, 6), c) + f(scallop(x+9, 230, 9, 7, 6), c) for x, c in ((20, SKY), (200, BLUSH), (252, SKY)))
           + stroke('M360 296V266', WOOD, 4) + f(R(346, 248, 28, 20, 7), WARATAH)
           + A_(grown('nan', WARATAH), 126, 232, 112) + sh(262, 289, 42, '#9CC4A5') + K_(pug('up', 'happy', HARBOUR), 262, 290))
# ---------- The café ----------
CW, CW2, PV, PV2 = '#F3D9C9', '#E3C2AE', '#F2E9D8', '#E4D8C2'
def tablef(x, y):
    chair = lambda cx_: stroke(f'M{cx_} {y}V{y-28}M{cx_+18} {y}V{y-28}M{cx_-1} {y-28}h20', '#6E7F8D', 3) + f'<circle cx="{cx_+9}" cy="{y-44}" r="13" fill="none" stroke="#6E7F8D" stroke-width="3"></circle>'
    return (chair(x-52) + chair(x+32) + stroke(f'M{x} {y}V{y-36}M{x-13} {y}h26', '#6E7F8D', 3.4) + e(x, y-38, 30, 7, PAPER) + e(x, y-35, 30, 7, PV2, 0.0)
            + f(f'M{x-7} {y-54}h14v8a7 7 0 0 1 -14 0z', PAPER) + f(f'M{x-7} {y-54}h14v3h-14z', '#D9B48A') + e(x, y-40, 11, 2.4, PV2))
cafe = (bgc(CW) + ''.join(stroke(f'M-4 {y}H394', CW2, 1, 0.5) for y in range(96, 232, 17))
        + band(86, 126, CW2)                                                                                                # the awning's shadow
        + glass(26, 132, 204, 84) + f'<circle cx="182" cy="162" r="14" fill="{A}" opacity="0.85"></circle>' + f(R(20, 126, 216, 8, 3), PAPER) + f(R(20, 214, 216, 8, 3), PAPER)
        + f(R(252, 122, 62, 110, 4), T1) + f(R(262, 134, 42, 44, 3), '#9DB6DC') + f'<circle cx="304" cy="190" r="2.6" fill="{A}"></circle>'
        + awn(-10, 400, 18, 62, WARATAH, PAPER, 13) + f(f'M-10 18H400V30H-10Z', '#C9432F', 0.35)                         # one big shape
        + f'<circle cx="352" cy="156" r="20" fill="{PAPER}"></circle>' + f('M343 150h16v7a8 8 0 0 1 -16 0z', WARATAH) + stroke('M359 152a4 4 0 0 1 0 8', WARATAH, 2.2) + stroke('M352 136V92', '#6E7F8D', 2.4)
        + band(232, Hh + 4, PV) + band(232, 238, PV2) + f('M120 304L170 238H330L394 304Z', '#FBF6E9') + stroke(''.join(f'M{x} 238L{x + (x-195)*0.5:.0f} 304' for x in range(10, 400, 46)), PV2, 1.2)
        + tablef(62, 294) + f('M344 296l5 -24h22l5 24z', WARATAH) + leaves(340, 262, T2).replace('rotate(-', 'rotate(-')
        + sh(198, 291, 40, PV2) + sh(264, 289, 42, PV2) + A_(grown('mum', T1), 198, 292) + K_(pug('down', 'happy', HARBOUR), 264, 290))
# ---------- The farm ----------
WH0, WH1 = '#F4E7B0', '#E6D28F'
def sheepf(x, y, s=1, flip=False):
    hx = x + (22 if not flip else -22)*s
    return stroke(f'M{x-11*s} {y-10*s}V{y}M{x-3*s} {y-10*s}V{y}M{x+6*s} {y-10*s}V{y}M{x+13*s} {y-10*s}V{y}', '#5A4636', 2.6*s) + f(scallop(x, y-21*s, 21*s, 13*s, 9), PAPER) + f(scallop(x+3*s, y-17*s, 14*s, 8*s, 7), '#EFE6D2') + e(hx, y-25*s, 6.5*s, 8.5*s, '#5A4636')
def windmillf(x, y, h):
    top = y - h; G = '#8794A0'
    out = stroke(f'M{x-22} {y}L{x-5} {top+12}M{x+22} {y}L{x+5} {top+12}', G, 3.2) + stroke(''.join(f'M{x-22+17*t:.1f} {y-(h-12)*t:.1f}L{x+22-17*t:.1f} {y-(h-12)*t:.1f}' for t in (0.2, 0.4, 0.6, 0.8)), G, 2)
    out += stroke(f'M{x-22} {y}L{x+15} {y-(h-12)*0.4:.1f}M{x+22} {y}L{x-15} {y-(h-12)*0.4:.1f}', G, 1.4)
    for i in range(14):
        a = math.radians(i*360/14); out += stroke(f'M{x + 10*math.cos(a):.1f} {top + 10*math.sin(a):.1f}L{x + 46*math.cos(a):.1f} {top + 46*math.sin(a):.1f}', G, 5.5)
    return out + f'<circle cx="{x}" cy="{top}" r="8" fill="{A}"></circle>' + f(f'M{x+8} {top-3}h44l9 -11v28l-9 -11z', WARATAH)
farm = (bgc(BL0) + f'<circle cx="70" cy="56" r="40" fill="{PAPER}" opacity="0.6"></circle><circle cx="70" cy="56" r="22" fill="{A}"></circle>' + cloudf(210, 40, 80)
        + f('M-4 126Q90 96 200 118T394 104V304H-4Z', '#B9D6BE') + f(scallop(238, 100, 24, 16, 7), T1) + f(scallop(268, 104, 16, 12, 6), T2) + sheepf(196, 122, 0.4)
        + f('M-4 152Q120 132 240 148T394 140V304H-4Z', WH0) + ''.join(stroke(f'M{x} 304Q{x*0.6+80:.0f} 220 {x*0.36+125:.0f} 148', WH1, 2) for x in range(-200, 620, 44))
        + f('M30 176V124H128V176Z', WARATAH) + f('M96 176V124H128V176Z', '#C9432F') + f('M22 126L79 96L136 126Z', '#8794A0') + f('M79 96L136 126H106Z', '#6E7F8D') + f(R(60, 140, 26, 36, 2), WOOD)
        + f(R(142, 132, 40, 44, 3), '#8794A0') + f('M166 132h16v44h-16z', '#6E7F8D') + f('M139 132L162 120L185 132Z', '#8794A0')
        + f('M-4 196Q200 180 394 196V304H-4Z', '#CFE5D2') + f('M-4 196Q200 180 394 196V206Q200 190 -4 206Z', '#E3F1E0')
        + f('M318 304L170 304L330 240Z', '#B2D3B9') + windmillf(332, 244, 214)
        + stroke(''.join(f'M{x} 226V200' for x in range(10, 300, 48)), WOOD, 4) + stroke('M-4 208H290M-4 218H290', WOOD, 1.2)
        + e(60, 286, 30, 5, '#B2D3B9') + f'<circle cx="60" cy="264" r="22" fill="{A}"></circle><circle cx="60" cy="264" r="13" fill="none" stroke="#F9D465" stroke-width="3"></circle><circle cx="60" cy="264" r="5" fill="#F9D465"></circle>'
        + sheepf(118, 262, 0.9) + sh(196, 289, 42, '#9CC4A5') + sh(256, 289, 38, '#9CC4A5') + K_(pug('wave', 'happy', HARBOUR), 196, 290) + K_(digby(A), 256, 290, 90))
# ---------- The shops ----------
def shop(x, w, wall, aw, sign, n=5):
    return (f(f'M{x} 232V40H{x+w}V232Z', wall) + f(f'M{x} 100H{x+w}v34H{x}Z', '#3A2A20', 0.10)
            + glass(x+12, 138, w*0.52, 78) + f(R(x+w*0.66, 132, w*0.25, 100, 4), WOOD) + f(R(x+w*0.69, 142, w*0.19, 34, 3), '#9DB6DC')
            + awn(x+4, x+w-4, 82, 26, aw, PAPER, n) + f'<circle cx="{x+w/2}" cy="60" r="16" fill="{PAPER}"></circle>' + sign(x + w/2, 60))
def s_apple(x, y): return f(f'M{x} {y-5}c-6-4-11 0-10 6s5 8 10 6c5 2 11-1 10-6s-4-10-10-6z', WARATAH) + stroke(f'M{x} {y-5}q1-4 4-6', T2, 2)
def s_loaf(x, y): return f(f'M{x-11} {y+6}V{y}a11 8 0 0 1 22 0v6z', '#D9A066')
def s_flower(x, y): return f(quatre(x, y, 10), BLUSH) + f'<circle cx="{x}" cy="{y}" r="2.6" fill="{A}"></circle>'
def crate(x, y, w, fruit, rows=2):
    out = f(R(x, y-30, w, 30, 3), '#D9B48A') + f(R(x, y-30, w, 8, 3), '#C99F70')
    n = int(w/15)
    for r in range(rows):
        for i in range(n - r): out += f'<circle cx="{x + 10 + i*15 + r*7.5:.1f}" cy="{y - 34 - r*11}" r="8" fill="{fruit}"></circle><circle cx="{x + 7.5 + i*15 + r*7.5:.1f}" cy="{y - 37 - r*11}" r="2.2" fill="{PAPER}" opacity="0.6"></circle>'
    return out
def bucketf(x, y):
    out = ''.join(stroke(f'M{x} {y-26}L{x+dx} {y-52}', T1, 2.4) + f(quatre(x+dx, y-54, 9), c) + f'<circle cx="{x+dx}" cy="{y-54}" r="2" fill="{A}"></circle>' for dx, c in ((-13, BLUSH), (0, PAPER), (13, SKY), (-5, WARATAH), (7, BLUSH)))
    return out + f(f'M{x-15} {y-28}h30l-3 28h-24z', '#8794A0') + f(f'M{x+5} {y-28}h10l-3 28h-8z', '#6E7F8D')
shops = (bgc(BL0) + shop(-6, 136, '#F3D9C9', WARATAH, s_apple, 5) + shop(130, 132, '#F8E6DA', WARATAH, s_loaf, 7) + shop(262, 134, '#EDCDBB', WARATAH, s_flower, 5)
         + band(232, Hh + 4, PV) + band(232, 238, PV2) + stroke(''.join(f'M{x} 238L{x + (x-195)*0.5:.0f} 304' for x in range(10, 400, 46)), PV2, 1.2)
         + crate(-14, 300, 96, A, 3) + crate(60, 304, 70, WARATAH, 2)                                                       # one big shape: the fruit, cropped
         + bucketf(350, 298) + bucketf(378, 302)
         + sh(184, 290, 42, PV2) + sh(250, 289, 38, PV2) + K_(pug('wave', 'happy', HARBOUR), 184, 291) + K_(quill(WARATAH), 250, 290, 82))

SCENES = [('Beach', beach, [BL0, BL2, SN0, WARATAH], 'A giant striped umbrella and its shadow. Puggle shows off her sandcastle; Pebble stays in the shade.'),
          ('Bush walk', bush, ['#E3EEFA', BL2, T1, '#F1E3D3'], 'A big gum frames the right and throws its shadow across the track. Puggle and Quill set off.'),
          ('Sydney Harbour', harbour, ['#F6CFA4', '#5E86CF', NV, A], 'The sun sets inside the arch and lays a path on the water. Puggle waves at the ferry with Pop.'),
          ('Backyard', morning, [Y0, Y2, L1, T1], 'Morning. The sun over the fence, a magpie singing, Puggle stretching and Pebble already up.'),
          ('The park', park, [BL0, '#CFE5D2', T1, WARATAH], 'A huge gum with dappled shade. Puggle and Kip in front of the slide and swings.'),
          ('Rainy day', rainy, [RG0, RG2, '#B9CDE4', A], 'Heavy cloud, even rain, one big puddle. Puggle jumps in it in her yellow raincoat; Digby keeps his distance.'),
          ('The pool', pool, [BL0, BL2, PAVE, WARATAH], 'Sunlit water with lane ropes and a ring, a shade sail and bunting. Puggle and Sunny on the deck.'),
          ("Grandma's house", grandma, [BL0, WARATAH, WALL, '#CFE5D2'], 'The red roof fills the corner; Nan waits on the verandah as Puggle runs up the path.'),
          ('The café', cafe, [CW, WARATAH, T1, PAPER], 'One long awning and its shadow. Mum and Puggle, and a babyccino on the table.'),
          ('The farm', farm, [BL0, WH0, '#CFE5D2', WARATAH], 'A windmill towers over wheat and paddock. Puggle and Digby meet the sheep.'),
          ('The shops', shops, ['#F3D9C9', WARATAH, PAPER, '#6E8798'], 'Grocer, bakery, florist, told apart by their picture signs. Fruit crates crop the corner; Puggle and Quill do the shopping.'),
          ('Night street', bedtime, [N1, N3, MOON, A], 'Bedtime. The moon behind the terraces, each house keeping a whisper of its daytime colour.')]
KIT = [('Sun and glow', f'<circle cx="40" cy="40" r="34" fill="{PAPER}" opacity="0.7"></circle><circle cx="40" cy="40" r="20" fill="{A}"></circle>', '0 0 80 80'),
       ('Cloud', cloudf(40, 46, 64), '0 10 80 50'), ('Gum tree', f('M34 100C36 70 38 50 36 30H48C46 50 48 70 52 100Z', '#F1E3D3') + f(scallop(42, 28, 38, 24, 9), T1) + f(scallop(58, 34, 20, 14, 7), T2), '0 0 84 102'),
       ('Lemon tree', lemon_m(70, 160), '0 0 140 164'), ('Umbrella', stroke('M80 74L88 150', WOOD, 4) + big_umbrella(80, 74, 76, 52), '0 16 160 138'),
       ('Sandcastle', f('M12 60V36h8v-7h7v7h8v-7h7v7h8v-7h7v7h5V60Z', SN2) + f('M28 29V12h5v-6h6v6h5v-6h5v17Z', SN2) + f('M41 6V-8l10 3.5-10 3.5z', WARATAH), '0 -12 80 76'),
       ('Arch bridge', arch(40, 160, 80), '-10 0 220 90'), ('Ferry', ferryf(60, 62, 1), '0 4 120 62'), ('Kite', kitef(30, 30), '0 0 60 126'),
       ('Slide', slidef(10, 100), '0 0 124 110'), ('Swings', swingf(50, 96), '0 0 100 100'), ('Swim ring', ringf(40, 36, 26), '6 4 76 70'),
       ('Hills Hoist', hoist_m(80, 170, 150), '10 4 140 170'), ('Magpie', magpie(34, 40), '0 4 70 44'), ('Sheep', sheepf(34, 40, 1), '4 4 70 40'),
       ('Windmill', windmillf(60, 220, 190), '0 -22 124 246'), ('Hay bale', f'<circle cx="30" cy="30" r="24" fill="{A}"></circle><circle cx="30" cy="30" r="14" fill="none" stroke="#F9D465" stroke-width="3"></circle><circle cx="30" cy="30" r="5" fill="#F9D465"></circle>', '0 0 60 60'),
       ('Fruit crate', crate(6, 62, 70, WARATAH, 2), '0 0 82 66'), ('Flowers', bucketf(34, 70), '0 4 68 68'), ('Café table', tablef(70, 70), '6 4 128 70'),
       ('Awning', awn(0, 130, 6, 30, WARATAH, PAPER, 5), '-4 0 138 52'), ('Balloon', balloon(30, 34, 26, SKY, 6), '0 0 60 150'), ('Rainbow', rainbowf(60, 62, 52), '0 0 120 66'),
       ('Street lamp', lampsil(40, 130, 110), '0 0 80 134'), ('Cat', catsil(30, 44), '6 2 56 44'), ('Quatrefoil star', f(quatre(20, 20, 14), MOON), '0 0 40 40')]
# ---- BOARD ----
T = 'font-size: 13px; font-weight: 500; color: #4A3B30; line-height: 1.4'
H = 'font-size: 13px; font-weight: 800; letter-spacing: 0.06em; text-transform: uppercase; color: #5A4636'
def chips(cols): return ''.join(f'<div style="width: 16px; height: 16px; border-radius: 99px; background: {c}; border: 1.2px solid rgba(58,42,32,0.25)"></div>' for c in cols)
scene_html = ''.join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 312px"><svg role="img" aria-label="{n} scene" width="312" height="240" viewBox="0 0 {W} {Hh}" style="border-radius: 22px; display: block">{s}</svg>'
                     f'<div style="display: flex; align-items: center; gap: 8px"><div style="font-size: 16px; font-weight: 800">{n}</div><div style="display: flex; gap: 3px">{chips(k)}</div></div><div style="{T}">{d}</div></div>' for n, s, k, d in SCENES)
rules = [('No outlines on the world', 'Places are flat shapes. Only the cast keeps the Ink line, so they are always the first thing you see.'),
         ('A colour key', 'Three or four colours per scene, shown as dots beside each name. Light and shade are tones of those colours.'),
         ('One big shape', 'Each scene has one shape that owns it: an umbrella, an arch, a roof, a tree. Things overlap and crop at the edges.'),
         ('Real light', 'Every scene knows where the sun is: a lit side, a shade side and a cast shadow on the ground.'),
         ('A moment', 'The cast is doing something, in their small versions, about 86 units tall in a 390 × 300 scene.')]
rule_html = ''.join(f'<div style="flex: 1; display: flex; flex-direction: column; gap: 3px"><div style="font-size: 15px; font-weight: 800">{i+1}. {n}</div><div style="{T}; font-size: 12px">{d}</div></div>' for i, (n, d) in enumerate(rules))
kit_html = ''.join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 4px; width: 100px"><div style="width: 100px; height: 88px; border-radius: 16px; background: {NIGHT if n in ("Street lamp", "Cat", "Quatrefoil star") else BL0}; display: flex; align-items: center; justify-content: center">'
                   f'<svg role="img" aria-label="{n}" width="78" height="72" viewBox="{vb}" preserveAspectRatio="xMidYMid meet">{sv}</svg></div><div style="font-size: 12px; font-weight: 700; text-align: center">{n}</div></div>' for n, sv, vb in KIT)
body = f'''<div style="width: 1080px; height: 2050px; box-sizing: border-box; background: {SAND}; color: #2A1F18; font-family: 'Bricolage Grotesque', system-ui, sans-serif; padding: 40px 48px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; flex-direction: column; gap: 6px"><h1 style="margin: 0; font-size: 36px; font-weight: 800; letter-spacing: -0.02em">Set pieces and backgrounds</h1>
<div style="{T}; font-size: 15px; max-width: 940px">Places from a Sydney family's week, redrawn as pictures: flat shapes, a small colour key, real light, and the cast in the middle of something.</div></div>
<div style="display: flex; gap: 18px">{rule_html}</div>
<div style="display: flex; flex-wrap: wrap; gap: 22px 24px">{scene_html}</div>
<div style="display: flex; flex-direction: column; gap: 10px"><div style="{H}">Kit of parts</div><div style="display: flex; flex-wrap: wrap; gap: 10px 8px">{kit_html}</div></div>
</div>'''
if __name__ == '__main__':
    wrap('Set pieces and backgrounds', body, 1080, 2050, 'Scenes2.dc.html', 0)
    P = ROOT + '/project/'
    c = json.load(open(P + 'canvas.json'))
    c['boards']['Scenes2.dc.html'].update(page='brand', x=1200, y=3640)
    json.dump(c, open(P + 'canvas.json', 'w'), separators=(',', ':'))
