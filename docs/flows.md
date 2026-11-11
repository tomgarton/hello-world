# Puggle: flows and journeys

Generated from `design/canvas/gen/flows.py`; the canvas page "Flows" shows each step as a screen. Change the script, not this file.

## App map

- **First time:** Splash (name shows here); Hello (2 screens, skippable); Add a child (the only required step); Character (friend or photo); Invite (optional)
- **Today (tab):** Children (their day so far); Tiles (built from two setup questions); Log sheets (feed, nappy, health…); Last saved (undo that stays); Sticker moment (after a potty success)
- **History (tab):** Timeline (by day); Filter (who and what); Edit entry (change or delete)
- **Insights (tab):** Last night (per child); Trends (weekly); Summary (PDF to share)
- **Family (tab):** Children (pages, characters); People (invite, roles); Settings (night, units, reminders); Pro and tips (free core); Help and about (name shows here)
- **Outside the app:** Lock Screen (sleep and feed timers); Widgets (last feed, asleep for); Notifications (only ones you switch on); Invite link (opens Join)

## 1. First run

From install to the first log, in under a minute. No account, no email, no password.

1. **Splash.** The only place the name shows in the app. Puggle waves.
2. **Hello.** One line on what it is. Skip is always there.
3. **Everyone sees the same day.** The promise of sharing, before any setup.
4. **Add your first child.** Name and birth date only. Colour is picked for them and can change.
5. **Their character.** Pick a friend and an outfit, or use a photo. Can be changed any time.
6. **Anyone else?.** Twins and siblings are first-class: add them now or later.
7. **Invite your partner.** Optional. Uses Apple’s share sheet; no account to make.
8. **Today, empty.** Lands on Today with one hint. No “nothing logged yet”: an empty day is just an empty day.

Rules and edge cases:

- Skip at any point lands on “Add your first child”, the only required step. Two setup questions per child follow it (see Setup that fits the child).
- Coming from another app? Import is offered on the “Anyone else?” screen as well as in Settings.
- Notifications are asked for later, the first time a reminder is switched on, never at launch.
- If iCloud is signed out, setup still works; sharing explains what’s needed (see Edge states).

## 2. Everyday logging

The core loop. One tap for the common case, a sheet for detail, never more than two taps deep.

1. **Today.** Every child at once, each with their day so far. Tap a tile to open that activity’s sheet.
2. **Bottle sheet.** Who (ticked, never colour alone), how much, what, when. Remembers each child’s last amount. The number can be typed. Reminders are off until asked for.
3. **Saved.** Saves instantly and Puggle nods. “Last saved” stays on Today, with Undo and Change, until the next save. It names the child.
4. **Nappy: one tap.** Three big choices; tapping one saves. No Save button.
5. **Breastfeed.** From its own tile. Left and right timers that run on the Lock Screen, or “Enter a past feed” with side, start and length.
6. **Solids.** Food as chips, how it went. New foods are remembered for next time.
7. **Edit or delete.** Tap any entry, anywhere, to change it. Delete asks once.
8. **The day so far.** Tap a child’s row. Counts for today and the last 24 hours, from the first entry.
9. **Log something earlier.** Time opens a wheel. “Earlier today” and “Yesterday” are one tap.

Rules and edge cases:

- Twins: “Both” logs one entry per child, each editable on its own.
- Each sheet opens on the child last logged for that activity, shown with a tick. For children born on the same day it never guesses: pick one, or Both.
- Undo never times out; it is replaced by the next save.
- Offline: saves on the phone and syncs later, with no error shown.
- Reactions never delay a save (see Motion direction).

## 3. Sleep

Start and stop from Today, see it on the Lock Screen, fix it afterwards if you forgot.

1. **Tap “Start sleep”.** One tap on the child’s row starts the timer. The button is a verb, and VoiceOver reads it with the name: “Start Ollie’s sleep”.
2. **Sleeping.** The row turns night blue with a live timer. For the first minute “Woke up” reads “Cancel”, so a stray tap leaves no entry.
3. **Lock Screen.** A Live Activity shows who is asleep and for how long, with a Woke up button.
4. **Woke up.** Stops the timer and shows the length. Start and end can be nudged.
5. **Forgot to start it.** Log a past sleep from the Sleep card: two times and it’s done.

Rules and edge cases:

- Forgot to stop it: after 14 hours the app asks “Still asleep?” next time it’s opened, and offers to set the wake time.
- Each child has their own timer; twins can be started together with “Both”.
- Quiet mode follows night hours, or the one child who is asleep. A sleeping baby does not mute a toddler’s sticker.
- A night waking can be added inside a sleep without ending it.

## 4. Potty training

For the toddler. Logging is quick; the reward is a sticker the child chooses.

1. **Potty sheet.** What happened and where. “Tried” counts: effort is rewarded too.
2. **Pick a sticker.** After a success the phone goes to the child. Only the stickers can be tapped; a parent holds the corner for two seconds to take it back.
3. **Sticker chart.** A week at a glance. Lives under the Potty card and on Ollie’s page.
4. **Ten stickers.** Every ten stickers earns a holographic one. It adds up; an accident never takes anything away.
5. **Time to try?.** An optional reminder. Puggle does the potty dance; never a nag.

Rules and edge cases:

- Accidents are logged plainly, with no sad Puggle, and are never shown on the child’s chart. Parents can see them in History.
- The sticker moment plays in full even when a baby is asleep.
- The sticker step can be skipped or switched off.
- Open decision: the potty method (child-led or timed) changes the default reminder.

## 5. History and insights

Look back, spot patterns, and hand a clear summary to a doctor or a carer.

1. **History.** Everything, newest first, by day. Tap to edit; swipe to delete.
2. **Filter.** By child and by activity. Stays set until cleared.
3. **Last night.** The question every parent asks at 7 am, answered in one card per child.
4. **Trends.** Simple weekly charts with outlined bars. No averages, no scores, no “behind”.
5. **Share a summary.** A one-page PDF for the GP, the child health nurse or day care.

Rules and edge cases:

- Insights never compare a child with other children, and show ranges, not averages. Each child has their own card with their name on it.
- Open decision: whether the summary for the doctor is free or part of Pro. It is drawn as free.
- With less than three days of data, Insights says so plainly and shows what there is.

## 6. Family and sharing

One family, many phones. Built on iCloud sharing: no accounts, no passwords.

1. **Family.** Children at the top, the people who help below.
2. **Invite.** Choose what they can do, then Apple’s share sheet sends the link.
3. **They open the link.** On their phone: who invited them and to what. One button.
4. **Shared day.** Their Today is the same Today. Entries say who logged them.
5. **Manage a person.** Change what they can do, or end their access. Everything they added stays.

Rules and edge cases:

- Needs iCloud on both phones. If the app isn’t installed, the link goes to the App Store first and resumes after.
- An invite link works once and expires after seven days.
- The interface never shows an “owner”. If the parent whose iCloud holds the family leaves, the app offers to move it to the other parent first.
- Open decision: people without an iPhone cannot join in v1, and the invite sheet says so.

## 7. Children and characters

Each child has a page: who they are, their character, and what’s theirs.

1. **Child page.** Their summary and everything that belongs to them.
2. **Edit details.** Name, birth date, colour. All optional except the name.
3. **Character builder.** Friend, outfit, colour. The same builder as on the canvas.
4. **Or a photo.** A photo sits in the same round frame everywhere a character would.
5. **Growing up.** Activities change with age. The app suggests; the parent decides.

Rules and edge cases:

- Archiving hides a child from Today but keeps all their history; it can be undone.
- Deleting a child is separate, asks twice and removes their entries for everyone.

## 8. Milestones and growth

The moments worth keeping, and the numbers the nurse asks for.

1. **Add a milestone.** Pick a first, or write your own. Photo optional.
2. **Celebrate.** The one big reaction in the app: hooray, quatrefoils, a shiny sticker.
3. **Their timeline.** Milestones in order, with ages worked out for you.
4. **Log a measurement.** From the Weight tile on Today. Typed to the gram; units follow the phone’s region.
5. **Growth chart.** Plotted on WHO percentile bands. Shown, never scored.

Rules and edge cases:

- Milestone suggestions come from public child-health sources for the user’s country and are phrased as “around”, never as deadlines.
- Growth charts always carry the same line about the nurse or GP, whatever the numbers. The band is labelled and can be hidden.

## 9. Settings, Pro and Help

Few settings, honest pricing, and the only other place the app’s name appears.

1. **Settings.** Reached from the Family tab. Short on purpose.
2. **Pro and tips.** Everything needed to track is free, for ever. Pro is a one-off; tips are thanks.
3. **Thank you.** A real thank-you, then straight back. No upsell after.
4. **Import.** Bring history from another tracker. Shows what it found before adding.
5. **Help and about.** Short answers, a way to reach us, and the name.

Rules and edge cases:

- Open decision: the Pro price.
- No ads, no tracking, no analytics. See “Your data” in Calm and private.
- Export gives the family everything, in plain files, at any time.

## 10. When things go wrong

Calm, plain and never the parent’s fault. Logging always works, whatever else is broken.

1. **No iCloud.** The app works on this phone. Sharing explains exactly what to switch on.
2. **Offline.** No error. A small note; everything syncs when it can.
3. **Logged twice.** Two people log the same bottle. The app asks once, kindly.
4. **Invite didn’t work.** Says why in plain words and offers the next step.
5. **Still asleep?.** A timer left running for 14 hours gets a gentle question, not a wrong chart.
6. **Notifications off.** Asked only when a reminder is first switched on, with the reason.

Rules and edge cases:

- Sync conflicts resolve by “latest edit wins” per entry; deletes win over edits.
- If iCloud storage is full, the app says so once and keeps working on the phone.
- Every screen must work with Reduce Motion, the largest text size and VoiceOver before it ships (see Large text, VoiceOver and night). The first build does not yet.

## 11. Health

Medicine, temperature and vaccinations, logged plainly. The app records what the parent tells it; it never advises.

1. **Log a medicine.** From the Health tile. The medicines this family uses are one tap; the next time comes from the gap the parent set.
2. **Too soon?.** If a dose is logged inside the gap the parent set, the app asks once. It never blocks.
3. **A regular medicine.** Set once: dose, times, the smallest gap. Reminders are quiet and belong to whoever switches them on.
4. **Due on Today.** What is due shows on the child’s row and goes when it’s logged. Nothing turns red if it’s late.
5. **Temperature.** A number, where it was taken, and the time. No colour, no “high”, no alarm.
6. **Vaccination.** A record, not an event: saved with the usual small nod, never the celebration.

Rules and edge cases:

- The app never suggests a dose, a gap, or whether a temperature is high or normal. Every number comes from the parent.
- Health entries appear in History and in the summary for the doctor.
- A helper sees only the medicine due during their day, unless a parent chooses otherwise.
- Supplements and vitamins are regular medicines.

## 12. Setup that fits the child

Two questions per child build their Today. A newborn’s screen is not a toddler’s.

1. **How do they feed?.** Asked once per baby, after their name. It decides which tiles they get.
2. **What about a toddler?.** For older children: potty training and naps, yes or not yet.
3. **A newborn’s Today.** Feeds, nappies and weight first. The row shows the side and when the last feed started, and the last 24 hours.
4. **A feed, after the fact.** No timer needed: side, start and length. At 3 am this is how most feeds get logged.
5. **Nappy, with more if asked.** One tap still saves. Colour and time can be added after, for families whose midwife asks.
6. **Weight in grams.** Typed, to the gram, from a tile on Today. Shows the change from birth as a plain number.

Rules and edge cases:

- Tiles follow the answers and the child’s age; the app suggests changes as they grow and the parent can always say no.
- The last-24-hours panel shows from the first entry, with no wait for “enough data”.
- The change from birth is a number only. The app does not say whether it is fine.
- Babies under two weeks get no percentile chart unless a parent asks for it.

## 13. Helpers

For a grandparent, a nanny or a friend: a simpler app that only logs, with the parents’ notes at the top.

1. **Invite a helper.** A parent chooses Helper and which days. The sheet says plainly what a helper needs.
2. **What you’re joining.** Three plain lines before anything else. Nothing to set up.
3. **A helper’s Today.** One column, large type, four big buttons, no other tabs. The parents’ note is at the top.
4. **A note for the parents.** Free text that belongs to the day, not to an entry.
5. **The parents’ side.** A parent writes “For today” once; it shows to whoever is helping that day.
6. **End of the day.** A summary of the helper’s day to hand over, then they’re done.

Rules and edge cases:

- A helper’s screen is designed at the largest text size first.
- Every entry shows who added it; every edit shows who changed it and when.
- Outside their days a helper gets no notifications and sees nothing new.
- Ending a helper’s access keeps everything they added.
- Open decision: a helper without an iPhone cannot join. A link that works in any browser would need a server.

## 14. Twins and pumping

Two babies at once with their own amounts, and milk that belongs to the parent.

1. **Pick a twin, or both.** For children born on the same day the sheet never guesses. Each twin gets a different character.
2. **Both, with their own amounts.** Choosing Both gives a row each, filled in from each baby’s last feed.
3. **Pump.** A Pump entry belongs to the parent, not to a baby. Left, right and where it went.
4. **Milk on hand.** A simple running total of what’s in the fridge and freezer. Bottles of breast milk take from it.

Rules and edge cases:

- “Same bottle?” is only asked about the same child. Two twins fed at the same minute is normal.
- The Lock Screen shows a line per sleeping or feeding child.
- Open decisions: a side-by-side view for twins, and corrected age for babies born early.

## 15. Calm and private

For parents who want less on the screen, and for anyone who asks where their data goes.

1. **How much to see.** Asked once in setup. Either choice logs the same things.
2. **Today, just logging.** Names and tiles. Nothing counts up and nothing is totalled.
3. **Your data.** One screen, in Settings and linked from setup. Plain answers and two buttons.
4. **Delete everything.** Says exactly what will happen, offers a copy first, and then does it.
5. **Finding support.** Always in Help, the same for everyone. The app never decides a parent needs it.
6. **Our promise.** On the Pro screen and in Help, in writing.

Rules and edge cases:

- “Just log” hides Insights, elapsed-time counters, totals, percentile bands and all counts, on widgets too.
- The app never reacts to how often it is opened or to gaps in the log.
- Helpline numbers must be checked for each country before release.
- Open decision: exactly what Pro contains.

## 16. Large text, VoiceOver and night

The same screens for a parent who can’t see them well, can’t see them at all, or is looking at them in the dark.

1. **Today at the largest text.** One column. Each child’s row stacks; the button names the child and spans the width.
2. **A sheet at the largest text.** Choices become a list of large rows with a tick. No segmented controls, nothing truncated.
3. **Night.** Very dim, warm text on near-black, no white anywhere. Switches by itself after dark or while a child sleeps.
4. **What VoiceOver says.** Each row is one stop with a full sentence, and its actions are named.

Rules and edge cases:

- Every control is at least 44 pt, with 8 pt between neighbours.
- Selection is always a tick and a border as well as a colour. Children are always named; colour and character are extras.
- Text is never below 13 pt at the default size; status lines are 15 pt.
- Charts have outlined bars, a value on each, and a spoken description.
- Undo never times out.
- Measured contrast: main and muted text pass AA on every surface; destructive red is darkened to pass.

## 17. Outside the app

Most looks at Puggle should never open it: the Home Screen, the Lock Screen, a notification, a word to Siri.

1. **Home Screen widgets.** Small: one child at a glance. Medium: every child, with buttons that log without opening the app.
2. **Lock Screen, several at once.** One line per running timer, each with its own button.
3. **My notifications.** Each person chooses their own. Nobody is switched on by someone else.
4. **Ask Siri.** Every log action works by voice, from the Action button and in Shortcuts.

Rules and edge cases:

- Widgets, Lock Screen timers and Siri are free, for ever.
- Lock Screen timers last about eight hours on iOS; a longer sleep carries on in the widget.
- A timer started on one phone shows in the app on the others straight away, but not on their Lock Screen. That would need a server.
- In “Just log” mode widgets show names and buttons only.
- Apple Watch is planned for later.
