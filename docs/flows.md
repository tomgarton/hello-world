# Puggle: flows and journeys

Generated from `design/canvas/gen/flows.py`; the canvas page "Flows" shows each step as a screen. Change the script, not this file.

## App map

- **First time:** Splash (name shows here); Hello (2 screens, skippable); Add a child (the only required step); Character (friend or photo); Invite (optional)
- **Today (tab):** Children (status, sleep button); Activity cards (+ opens a sheet); Log sheets (bottle, nappy, potty…); Sticker moment (after a potty success); Milestone (the big celebration)
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
8. **Today, empty.** Lands on Today with one gentle nudge to log something.

Rules and edge cases:

- Skip at any point lands on “Add your first child”, the only required step.
- Notifications are asked for later, the first time a reminder is switched on, never at launch.
- If iCloud is signed out, setup still works; sharing explains what’s needed (see Edge states).

## 2. Everyday logging

The core loop. One tap for the common case, a sheet for detail, never more than two taps deep.

1. **Today.** Every child at once. + on a card opens that activity’s sheet.
2. **Bottle sheet.** Who (one, several or everyone), how much, what, when. Remembers the last amount.
3. **Saved.** Saves instantly. Puggle nods; a toast offers Undo for five seconds.
4. **Nappy: one tap.** Three big choices; tapping one saves. No Save button.
5. **Breastfeed timer.** Left and right timers. Runs on the Lock Screen; survives closing the app.
6. **Solids.** Food as chips, how it went. New foods are remembered for next time.
7. **Edit or delete.** Tap any entry, anywhere, to change it. Delete asks once.
8. **Log something earlier.** Time opens a wheel. “Earlier today” and “Yesterday” are one tap.

Rules and edge cases:

- Twins: “Both” logs one entry per child, each editable on its own.
- Each sheet opens with the child you last logged that activity for.
- Offline: saves on the phone and syncs later, with no error shown.
- Reactions never delay a save (see Motion direction).

## 3. Sleep

Start and stop from Today, see it on the Lock Screen, fix it afterwards if you forgot.

1. **Tap “Asleep”.** One tap on the child’s row starts the timer. No sheet.
2. **Sleeping.** The row turns night blue with a live timer. Puggle falls asleep in the header.
3. **Lock Screen.** A Live Activity shows who is asleep and for how long, with a Woke up button.
4. **Woke up.** Stops the timer and shows the length. Start and end can be nudged.
5. **Forgot to start it.** Log a past sleep from the Sleep card: two times and it’s done.

Rules and edge cases:

- Forgot to stop it: after 14 hours the app asks “Still asleep?” next time it’s opened, and offers to set the wake time.
- Each child has their own timer; twins can be started together with “Both”.
- While any child is asleep, the app is in quiet mode: no sounds, smaller reactions.

## 4. Potty training

For the toddler. Logging is quick; the reward is a sticker the child chooses.

1. **Potty sheet.** What happened and where. “Tried” counts: effort is rewarded too.
2. **Pick a sticker.** After a success the phone goes to the child: they choose. Puggle is proud.
3. **Sticker chart.** A week at a glance. Lives under the Potty card and on Ollie’s page.
4. **A dry week.** Seven dry days earns a holographic sticker that shimmers when the phone tilts.
5. **Time to try?.** An optional reminder. Puggle does the potty dance; never a nag.

Rules and edge cases:

- Accidents are logged plainly, with no sad Puggle and no lost stickers.
- The sticker step can be skipped or switched off.
- Open decision: the potty method (child-led or timed) changes the default reminder.

## 5. History and insights

Look back, spot patterns, and hand a clear summary to a doctor or a carer.

1. **History.** Everything, newest first, by day. Tap to edit; swipe to delete.
2. **Filter.** By child and by activity. Stays set until cleared.
3. **Last night.** The question every parent asks at 7 am, answered in one card per child.
4. **Trends.** Simple weekly charts. No scores, no judgement, no “behind”.
5. **Share a summary.** A one-page PDF for the GP, the child health nurse or day care.

Rules and edge cases:

- Insights never compare a child with other children or with averages.
- With less than three days of data, Insights says so plainly and shows what there is.

## 6. Family and sharing

One family, many phones. Built on iCloud sharing: no accounts, no passwords.

1. **Family.** Children at the top, the people who help below.
2. **Invite.** Choose what they can do, then Apple’s share sheet sends the link.
3. **They open the link.** On their phone: who invited them and to what. One button.
4. **Shared day.** Their Today is the same Today. Entries say who logged them.
5. **Manage a person.** Change what they can do, or remove them. Removing keeps their past entries.

Rules and edge cases:

- Needs iCloud on both phones. If the app isn’t installed, the link goes to the App Store first and resumes after.
- An invite link works once and expires after seven days.
- Android and web guests are out of scope for v1 (noted for later).

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
4. **Log a measurement.** Weight, height, head. Units follow the phone’s region.
5. **Growth chart.** Plotted on WHO percentile bands. Shown, never scored.

Rules and edge cases:

- Milestone suggestions come from public child-health sources for the user’s country and are phrased as “around”, never as deadlines.
- Growth charts say “talk to your nurse or GP” and nothing diagnostic.

## 9. Settings, Pro and Help

Few settings, honest pricing, and the only other place the app’s name appears.

1. **Settings.** Reached from the Family tab. Short on purpose.
2. **Pro and tips.** Everything needed to track is free, for ever. Pro is a one-off; tips are thanks.
3. **Thank you.** A real thank-you, then straight back. No upsell after.
4. **Import.** Bring history from another tracker. Shows what it found before adding.
5. **Help and about.** Short answers, a way to reach us, and the name.

Rules and edge cases:

- Open decision: the Pro price.
- No ads, no data sold, no analytics that identify a family.
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
- Reduce Motion, Dynamic Type and VoiceOver are supported on every screen above.
