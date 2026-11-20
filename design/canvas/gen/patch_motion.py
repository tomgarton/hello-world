f='motion.py'; s=open(f).read()
def rep(a,b):
    global s; assert a in s, a[:70]; s=s.replace(a,b,1)
a=s.index("def headparts("); b=s.index("def shadow(")
s=s[:a]+'''def headparts(kind, blink=True, a_clip='', a_eyes='', eyes_svg=None):
    return (G(f'<ellipse cx="120" cy="108" rx="70" ry="60" fill="{PF}" stroke="{O}" stroke-width="7"></ellipse>', '', 'head-shape')
            + G(''.join(f'<circle cx="{x0}" cy="127" r="10" fill="{BL}"></circle><path d="M{x0-7} 132l5-9M{x0+2} 132l5-9" stroke="{ST}" stroke-width="3.5" stroke-linecap="round"></path>' for x0 in (67, 173)), '', 'blush')
            + G(f'<ellipse cx="120" cy="151" rx="47" ry="19" fill="{BILL}" stroke="{O}" stroke-width="6"></ellipse><circle cx="114" cy="143" r="1.8" fill="{O}"></circle><circle cx="126" cy="143" r="1.8" fill="{O}"></circle>', '', 'bill')
            + G(eyes_svg if eyes_svg is not None else eyes(kind, blink), a_eyes, 'eyes') + G(ACC['clip'](160, 56, WARATAH), a_clip, 'clip'))
def rig(col, arms, eye, a_tail='', a_armL='', a_armR='', a_head='', a_body='', a_all='', blink=True, a_clip='', a_eyes='', a_squash='', eyes_svg=None):
    (lx0, ly0, lx1, ly1, lb), (rx0, ry0, rx1, ry1, rb) = X['ARMS'][arms]
    inner = (G(p['tail'](PF), a_tail, 'tail') + G(p['legs'](PF) + p['feet'](BILL), '', 'legs')
             + G(G(p['trap'](col) + p['pocket'](210), '', 'dress') + G(limb(lx0, ly0, lx1, ly1, col, lb), a_armL, 'arm-left') + G(limb(rx0, ry0, rx1, ry1, col, rb), a_armR, 'arm-right')
                 + G(headparts(eye, blink, a_clip, a_eyes, eyes_svg), a_head, 'head'), a_body, 'upper'))
    if a_squash:   # squash and stretch about the feet
        inner = f'<g transform="translate(120 290)"><g data-m="1">{a_squash}<g transform="translate(-120 -290)">{inner}</g></g></g>'
    return G(inner, a_all, 'puggle')
'''+s[b:]
a=s.index("idle = shadow()"); b=s.index("def tile(")
new = open('motion_new_block.txt').read()
s=s[:a]+new+s[b:]
rep("tile(idle, 'Idle', 'Breathes, blinks every four seconds, tail drifts. The default on Today.')","tile(idle, 'Idle', 'Breathes and blinks; now and then she glances aside and her tail flicks, so it never reads as a loop.')")
rep("tile(wave, 'Wave', 'Hello on launch and on the splash. Arm from the shoulder, head tilts with it.', SUN)","tile(wave, 'Wave', 'The arm dips, then swings up and waves twice. Head, tail and clip follow a beat late.', SUN)")
rep("tile(hooray, 'Hooray', 'After a log or a milestone. Squash, jump, land; quatrefoils pop.', MINT)","tile(hooray, 'Hooray', 'Crouch and squash, stretch into the jump, squash on landing, settle. Tail and clip lag.', MINT)")
rep("tile(sleepy, 'Sleepy', 'When a child is asleep or it is night. Slow breath, nodding head.', '#D9DEEF')","tile(sleepy, 'Falling asleep', 'Eyes droop twice and fight back, the head nods further each time, then she is out.', '#D9DEEF')")
rep("tile(walkc, 'Walk', 'Pull to refresh and the books. Two key poses for now; Rive adds the in-betweens.', SHELL)","tile(walkc, 'Walk', 'Four key poses a step, with the head arriving late. Rive smooths between them.', SHELL)")
rep("<div style=\"display: flex; gap: 16px; align-items: stretch\">{machine}{how}</div>",
    "<div style=\"display: flex; gap: 22px; align-items: flex-start\"><div style=\"display: flex; flex-direction: column; gap: 8px\"><div style=\"{H}\">Walk: the four key poses</div><div style=\"display: flex; gap: 10px\">{pose_sheet}</div></div><div style=\"display: flex; flex-direction: column; gap: 8px; flex: 1\"><div style=\"{H}\">What the second pass added</div>{prin_html}</div></div>\n<div style=\"display: flex; gap: 16px; align-items: stretch\">{machine}{how}</div>")
rep("body = f'''<div style=\"width: 1080px; height: 1090px;", """principles = [('Anticipation', 'A small move the other way first: the crouch before the jump, the dip before the wave.'), ('Squash and stretch', 'She squashes wider when she lands and stretches taller in the air, always about her feet.'),
              ('Follow-through', 'Tail, clip and head start and stop a beat after the body, so nothing moves as one block.'), ('Not a loop', 'Idle has rare one-off moments on a longer cycle than the breath.')]
prin_html = ''.join(f'<div style="{T}; font-size: 12px"><b>{n}.</b> {d}</div>' for n, d in principles)
body = f'''<div style=\"width: 1080px; height: 1400px;""")
rep("body, 1080, 1090,","body, 1080, 1400,")
open(f,'w').write(s)
