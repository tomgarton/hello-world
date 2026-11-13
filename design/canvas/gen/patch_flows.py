f = 'flows.py'; s = open(f).read()
def rep(a, b, n=1):
    global s
    assert a in s, a[:80]
    s = s.replace(a, b) if n == 0 else s.replace(a, b, n)
# kit overrides go just before the sample data
rep("OL, BE = ('Ollie', SKY), ('Bea', SHELL)", open('kit_new.txt').read() + "OL, BE = ('Ollie', SKY), ('Bea', SHELL)")
# the later bars() must keep the outlined version
a = s.index("def bars(vals, col):\n    m = max(vals); return '<div style=\"display: flex; align-items: flex-end; gap: 6px; height: 90px\">' + ''.join(f'<div style=\"flex: 1; height: {max(v/m*90, 4):.0f}px; background: {col}; border-radius: 6px\"></div>'")
b = s.index("\n", s.index("\n", a) + 1)
s = s[:a] + s[b+1:]
# Today: each child's day so far, and tiles
rep("today_rows = crow('Ollie', '2½', 'Awake since 6:50 am', SKY) + crow('Bea', '6 mo', 'Bottle 150 ml, 40 min ago', SHELL, baby_=True)",
    "today_rows = crow('Ollie', '2½', 'Awake 2 h 50 min · potty 40 min ago', SKY, sub='Today: 2 potty, 1 nap') + crow('Bea', '6 mo', 'Fed 40 min ago, 150 ml · awake 1 h 20 min', SHELL, baby_=True, sub='Today: 4 bottles, 610 ml · 5 nappies')")
a = s.index("today_cards = grid("); b = s.index("\n", a)
s = s[:a] + "today_cards = TILES" + s[b:]
rep("chips([('●', SKY), ('●', SHELL, False), ('●', MINT, False), ('●', SUN, False)])", "chips([('Sky', SKY), ('Shell', SHELL, False), ('Mint', MINT, False), ('Sun', SUN, False)])", 0)
rep("chips([('●', HARB), ('●', WAR), ('●', GUM, False), ('●', A, False)])", "chips([('Blue', SKY), ('Red', BLUSH), ('Green', MINT, False), ('Yellow', A, False)])")
# 1 first run
rep("field('Name', 'Ollie'), field('Born', '14 May 2024'), p('Their colour', 14, INK, 700)", "field('Name', 'Ollie', 'A nickname is fine'), field('Born', '14 May 2024'), p('Their colour', 14, INK, 700)")
rep("crow('Ollie', '2½', 'Nothing logged yet today', SKY), crow('Bea', '6 mo', 'Nothing logged yet today', SHELL, baby_=True), banner('Tap + on any card to log. It takes one tap.', SUN, 'Start anywhere.'), grid(card('Bottle', 'Bottle', []), card('Sleep', 'Sleep', []), card('Nappy', 'Nappy', []), card('Potty', 'Potty', []))",
    "crow('Ollie', '2½', '', SKY), crow('Bea', '6 mo', '', SHELL, baby_=True), banner('Tap any tile to log. Most take one tap.', SUN, 'Start anywhere.'), grid3(tile('Breastfeed', 'Breastfeed'), tile('Bottle', 'Bottle'), tile('Nappy', 'Nappy'), tile('Sleep', 'Sleep'), tile('Solids', 'Solids'), tile('Potty', 'Potty'))")
rep("('Today, empty', 'Lands on Today with one gentle nudge to log something.'", "('Today, empty', 'Lands on Today with one hint. No “nothing logged yet”: an empty day is just an empty day.'")
rep("'Skip at any point lands on “Add your first child”, the only required step.'", "'Skip at any point lands on “Add your first child”, the only required step. Two setup questions per child follow it (see Setup that fits the child).', 'Coming from another app? Import is offered on the “Anyone else?” screen as well as in Settings.'")
# 2 logging
rep("('Today', 'Every child at once. + on a card opens that activity’s sheet.', TODAY)", "('Today', 'Every child at once, each with their day so far. Tap a tile to open that activity’s sheet.', TODAY)")
rep("toggle('Remind me in 3 hours', True), btn('Save bottle')", "toggle('Remind me in 3 hours', False), btn('Save bottle')")
rep("('Bottle sheet', 'Who (one, several or everyone), how much, what, when. Remembers the last amount.'", "('Bottle sheet', 'Who (ticked, never colour alone), how much, what, when. Remembers each child’s last amount. The number can be typed. Reminders are off until asked for.'")
a = s.index(" ('Saved', 'Saves instantly."); b = s.index("\n", a)
s = s[:a] + " ('Saved', 'Saves instantly and Puggle nods. “Last saved” stays on Today, with Undo and Change, until the next save. It names the child.', S(hdr('Tuesday 10 November', 'Ollie and Bea'), lastrow('Bottle, 150 ml for Bea · 2:50 pm'), crow('Ollie', '2½', 'Awake 2 h 50 min · potty 40 min ago', SKY, sub='Today: 2 potty, 1 nap'), crow('Bea', '6 mo', 'Fed just now, 150 ml · awake 1 h 20 min', SHELL, baby_=True, sub='Today: 5 bottles, 760 ml · 5 nappies'), TILES))," + s[b:]
rep("grid(card('Nappy', 'Wet', [], False), card('Nappy', 'Dirty', [], False)), card('Nappy', 'Both', [], False), p('Tap one to save. Add a note after if you need to.', 13, center=True)",
    "p('For Bea', 16, INK, 800), grid(card('Nappy', 'Wet', [], False), card('Nappy', 'Dirty', [], False)), card('Nappy', 'Both', [], False), p('Tap one to save. Time, colour or a note can be added from “Last saved”.', 13, center=True)")
rep("('Breastfeed timer', 'Left and right timers. Runs on the Lock Screen; survives closing the app.'", "('Breastfeed', 'From its own tile. Left and right timers that run on the Lock Screen, or “Enter a past feed” with side, start and length.'")
rep("over=sheet('Breastfeed', chips([('Bea', SHELL)]), grid(", "over=sheet('Breastfeed', chips([('Bea', SHELL)]), seg(['Timer', 'Enter a past feed']), grid(")
rep(" ('Log something earlier',", " ('The day so far', 'Tap a child’s row. Counts for today and the last 24 hours, from the first entry.', S(nav('Bea today', 'Today', ''), seg(['Today', 'Last 24 hours'], 1), panel('Feeds', kv('Bottles', '6 · 860 ml'), kv('Breastfeeds', '2 · 25 min')), panel('Nappies', kv('Wet', '5'), kv('Dirty', '2')), panel('Sleep', kv('Asleep', '13 h 10 min'), kv('Longest stretch', '5 h 40 min')), tab=None)),\n ('Log something earlier',")
rep("'Each sheet opens with the child you last logged that activity for.'", "'Each sheet opens on the child last logged for that activity, shown with a tick. For children born on the same day it never guesses: pick one, or Both.', 'Undo never times out; it is replaced by the next save.'")
# 3 sleep
rep("('Tap “Asleep”', 'One tap on the child’s row starts the timer. No sheet.', TODAY)", "('Tap “Start sleep”', 'One tap on the child’s row starts the timer. The button is a verb, and VoiceOver reads it with the name: “Start Ollie’s sleep”.', TODAY)")
rep("('Sleeping', 'The row turns night blue with a live timer. Puggle falls asleep in the header.'", "('Sleeping', 'The row turns night blue with a live timer. For the first minute “Woke up” reads “Cancel”, so a stray tap leaves no entry.'")
rep("display: flex; align-items: center; font-size: 14px; font-weight: 700\">Woke up</div></div>', crow('Bea', '6 mo', 'Bottle 150 ml, 40 min ago', SHELL, baby_=True), today_cards)", "display: flex; align-items: center; font-size: 14px; font-weight: 700\">Woke up</div></div>', crow('Bea', '6 mo', 'Fed 40 min ago, 150 ml · awake 1 h 20 min', SHELL, baby_=True, sub='Today: 4 bottles, 610 ml · 5 nappies'), today_cards)")
rep("'While any child is asleep, the app is in quiet mode: no sounds, smaller reactions.'", "'Quiet mode follows night hours, or the one child who is asleep. A sleeping baby does not mute a toddler’s sticker.', 'A night waking can be added inside a sleep without ending it.'")
# 4 potty: goal that adds up, hand-over lock
rep("banner('3 more dry days for a shiny sticker.', MINT, '4 dry days in a row.'), field('Accidents this week', '2'), tab=None)", "banner('3 more for a shiny one.', MINT, '7 of 10 stickers.'), tab=None)")
rep("('A dry week', 'Seven dry days earns a holographic sticker that shimmers when the phone tilts.'", "('Ten stickers', 'Every ten stickers earns a holographic one. It adds up; an accident never takes anything away.'")
rep("h('Dry all week!', 34, True)", "h('Ten stickers!', 34, True)")
rep("('Pick a sticker', 'After a success the phone goes to the child: they choose. Puggle is proud.'", "('Pick a sticker', 'After a success the phone goes to the child. Only the stickers can be tapped; a parent holds the corner for two seconds to take it back.'")
rep("fill(), btn('Skip', 'quiet'), tab=None, bg=SUN)),\n ('Sticker chart'", "fill(), p('Grown-ups: hold here to go back', 13, center=True), tab=None, bg=SUN)),\n ('Sticker chart'")
rep("'Accidents are logged plainly, with no sad Puggle and no lost stickers.'", "'Accidents are logged plainly, with no sad Puggle, and are never shown on the child’s chart. Parents can see them in History.', 'The sticker moment plays in full even when a baby is asleep.'")
# 5 history
rep("<div style=\"font-size: 14px; opacity: 0.8\">7:10 pm to 6:05 am · woke twice · 2 feeds</div>", "<div style=\"font-size: 14px; opacity: 0.8\">asleep, between 7:10 pm and 6:05 am · 2 feeds</div>")
rep("<div style=\"font-size: 14px; opacity: 0.8\">7:40 pm to 6:45 am · slept through</div>", "<div style=\"font-size: 14px; opacity: 0.8\">asleep, between 7:40 pm and 6:45 am</div>")
rep("<div style=\"font-size: 13px; color: {MUTED}; margin-bottom: 10px\">Average 13 h 40 min</div>", "<div style=\"font-size: 13px; color: {MUTED}; margin-bottom: 10px\">Mon to Sun · tap a bar for that day</div>")
rep("<div style=\"font-size: 13px; color: {MUTED}; margin-bottom: 10px\">Average 820 ml</div>", "<div style=\"font-size: 13px; color: {MUTED}; margin-bottom: 10px\">Mon to Sun · tap a bar for that day</div>")
rep("('Trends', 'Simple weekly charts. No scores, no judgement, no “behind”.'", "('Trends', 'Simple weekly charts with outlined bars. No averages, no scores, no “behind”.'")
rep("{p(\"Feeds: 6 a day, 820 ml average\")}{p(\"Sleep: 13 h 40 min average\")}{p(\"Nappies: 7 a day\")}", "{p(\"Bottles: 5 to 7 a day, 780 to 900 ml\")}{p(\"Sleep: 12 h 30 to 14 h 30 a day\")}{p(\"Nappies: 6 to 8 a day, 4 to 6 wet\")}{p(\"Medicine: reflux medicine twice daily\")}")
rep("'Insights never compare a child with other children or with averages.'", "'Insights never compare a child with other children, and show ranges, not averages. Each child has their own card with their name on it.', 'Open decision: whether the summary for the doctor is free or part of Pro. It is drawn as free.'")
# 6 family: equal parents, helper
rep("lst(row('M', 'Mum (you)', 'Owner'), row('D', 'Dad', 'Can log and edit'), row('N', 'Nan', 'Can log'))", "lst(row('M', 'Mum (you)', 'Parent'), row('D', 'Dad', 'Parent'), row('N', 'Nan', 'Helper · Tuesdays and Thursdays'))")
rep("seg(['Parent', 'Carer']), p('<b>Parent</b> can log, edit, add children and invite. <b>Carer</b> can log and see today and yesterday.', 14), field('Send with', 'Messages')", "seg(['Parent', 'Helper']), p('<b>Parents</b> are equal: each can do everything. A <b>helper</b> adds what happens on their days and can fix what they added.', 14), field('Send with', 'Messages'), p('They’ll need an iPhone signed in to iCloud.', 13)")
rep("p('Mum invited you to see and log their day.', 17, MUTED, 400, True)", "p('Mum invited you as a parent. You’ll both see the same day and can both do everything.', 17, MUTED, 400, True)")
rep("seg(['Parent', 'Carer'], 1), toggle('Notify me when Nan logs', False)", "seg(['Parent', 'Helper'], 1), toggle('Notify me when Nan logs', False, 'Nan can see this is on')")
rep("btn('Remove from family', 'danger')", "btn('End Nan’s access', 'danger')")
rep("('Manage a person', 'Change what they can do, or remove them. Removing keeps their past entries.'", "('Manage a person', 'Change what they can do, or end their access. Everything they added stays.'")
rep("'Android and web guests are out of scope for v1 (noted for later).'", "'The interface never shows an “owner”. If the parent whose iCloud holds the family leaves, the app offers to move it to the other parent first.', 'Open decision: people without an iPhone cannot join in v1, and the invite sheet says so.'")
# 7 children
rep("banner('Hide Bottle and show Solids on her card?', MINT, 'Bea is 6 months.'), f'<div style=\"display: flex; gap: 10px\">{btn(\"Yes, update\", \"ghost\")}</div>'", "banner('Would you like a Solids tile on her screen?', MINT, 'Bea is 6 months.'), grid(btn('Add Solids', 'ghost'), btn('Not now', 'quiet'))")
# 8 milestones
rep("('First tooth', A, False), ('Slept through', A, False), ('+ Your own', A, False)", "('First tooth', A, False), ('First smile', A, False), ('+ Your own', A, False)")
rep("row('Milestone', 'Slept through', '5 months', 'Oct 2024')", "row('Milestone', 'First smile', '7 weeks', 'Jul 2024')")
rep("seg(['Weight', 'Height', 'Head']), big('7.4', 'kg'), field('When', 'Today'), btn('Save')", "seg(['Weight', 'Height', 'Head']), big('7,420', 'g'), field('When', 'Today'), btn('Save')")
rep("('Log a measurement', 'Weight, height, head. Units follow the phone’s region.'", "('Log a measurement', 'From the Weight tile on Today. Typed to the gram; units follow the phone’s region.'")
rep("<div style=\"font-size: 14px; color: {MUTED}\">7.4 kg at 6 months</div>", "<div style=\"font-size: 14px; color: {MUTED}\">7,420 g at 6 months. The band shows the usual range. Talk to your nurse or GP about growth.</div>")
rep("'Growth charts say “talk to your nurse or GP” and nothing diagnostic.'", "'Growth charts always carry the same line about the nurse or GP, whatever the numbers. The band is labelled and can be hidden.'")
# 9 settings
rep("p('That keeps Puggle free for other families.', 17, MUTED, 400, True)", "p('It means a lot to the two of us.', 17, MUTED, 400, True)")
rep("'No ads, no data sold, no analytics that identify a family.'", "'No ads, no tracking, no analytics. See “Your data” in Calm and private.'")
# 10 edges
rep("sheet('Is Ollie still asleep?', p('The sleep timer has been running since 7:40 pm yesterday.', 15), field('He woke at', '6:45 am')", "sheet('The sleep timer is still on', p('When did Ollie wake?', 15), field('Woke at', '6:45 am')")
rep("'Reduce Motion, Dynamic Type and VoiceOver are supported on every screen above.'", "'Every screen must work with Reduce Motion, the largest text size and VoiceOver before it ships (see Large text, VoiceOver and night). The first build does not yet.'")
# Tier 2 flows before the renderer; helper functions used by Tier 1 edits come first
t2 = open('t2.txt').read()
helpers = t2[:t2.index("flow('health'")]
rest = t2[t2.index("flow('health'"):]
rep("# ---------------- the flows ----------------", helpers + "# ---------------- the flows ----------------")
rep("# ---------------- render ----------------", rest + "# ---------------- render ----------------")
rep("('Today (tab)', [('Children', 'status, sleep button'), ('Activity cards', '+ opens a sheet'), ('Log sheets', 'bottle, nappy, potty…'), ('Sticker moment', 'after a potty success'), ('Milestone', 'the big celebration')], PAPER)",
    "('Today (tab)', [('Children', 'their day so far'), ('Tiles', 'built from two setup questions'), ('Log sheets', 'feed, nappy, health…'), ('Last saved', 'undo that stays'), ('Sticker moment', 'after a potty success')], PAPER)")
rep("Ten journeys follow on this page", "Seventeen journeys follow on this page")
rep("height: 760px", "height: 800px"); rep("map_body, 760)", "map_body, 800)")
open(f, 'w').write(s)
