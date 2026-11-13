# Usability findings, 13 November 2026

Six testers looked at the app at commit `6b5d218`. Five read the code and copy as particular people. One used the app in the iPhone 17 simulator. Nobody tested sharing between two real phones.

File references are under `app/Puggle/`. "Checked" means the claim was read again in the code after the testers reported. "Seen" means the hands-on tester saw it on screen. "Inferred" means it follows from the code but was not run.

## Who tested

1. A single parent with a three-week-old, alone, one-handed at night.
2. A grandmother who is the sole carer of a 14-month-old and a four-year-old, at the largest text size.
3. One family at every level: two mothers, twins and a toddler, a Nan as Helper, an uncle as Viewer, a nanny added and removed.
4. Families the design did not have in mind: co-parents in two homes, a foster carer, a baby born at 29 weeks, a family after a loss, a parent with postnatal anxiety, adoptive and trans parents.
5. Accessibility: VoiceOver, the largest text, one hand or a tremor, colour blindness with twins, reading difficulty, Reduce Motion.
6. Hands-on: first run, logging and undoing, History, Insights, Family, Play, and the Helper and Viewer views.

## Safety and data, fix before anyone else uses it

| # | Finding | Where | Status |
|---|---|---|---|
| 1 | Medicine gaps and dose limits are kept on one phone. Another carer gets no "Too soon?" and no "Due". | `Features/Log/MedicineLabel.swift:9`, `Features/Reminders/Reminders.swift:233` | Checked. Found by two testers. |
| 2 | A Helper can still delete other people's entries three ways: "Set wake time" opens the full log sheet with "Delete entry"; the widget's Undo deletes anyone's recent nappy; "Cancel" deletes anyone's sleep under a minute old. | `Features/Today/TodayView.swift:207`, `Features/Log/LogSheet.swift:73`, `Data/LiveTimers.swift:158`, `Data/FamilyStore.swift:348` | Checked. |
| 3 | Someone who joins a family and already has children of their own sees both sets. Logging for their own child puts the entry in the shared family against a child in their private one, and the save fails silently. | `Data/FamilyStore.swift:77`, `:121`; child fetches are not scoped to a family | Code checked, outcome inferred. |
| 4 | The person whose iCloud holds the family cannot be replaced. There is no transfer and they cannot leave. "Delete everything" asks once and removes it for everyone. | `Features/Family/YourDataView.swift:45`, `PeopleViews.swift:234` | Checked. |
| 5 | An invited Parent can delete a child and all their entries, for everyone. Nothing is kept to bring back. | `Features/Family/ChildForm.swift:184` | Checked. |
| 6 | After "You're in", a new phone goes back to the welcome screen with "Start a new family" as the main button. A phone already set up shows "Add your little ones". There is no waiting screen. | `Features/Family/JoinView.swift:203`, `App/PuggleApp.swift:240` | Checked. |
| 7 | What the share sheet saves is not written back before the list of people is rebuilt, so a new person's level may be lost and they fall back to Helper. | `Features/Family/PeopleViews.swift:467` | Inferred. Needs two phones. |
| 8 | Any level can export everything and open the summary for the doctor. | `Features/Family/YourDataView.swift:24` | Checked. |
| 9 | Reminders for a child removed on another phone keep firing until this phone next opens the app. | `Features/Reminders/Reminders.swift:102` | Inferred. |

## What the app assumes about a family

- **"How do they feed?" has no "neither".** A child under two must be Bottle, Breastfeeding or Both. There is no tube feeding, cup or cow's milk. `Features/Family/ChildForm.swift:78`. Checked.
- **The top level is called "Parent".** A grandmother, foster carer or guardian is labelled a parent on her own row. `Data/People.swift:20`.
- **Partners are assumed.** "For a partner", "a partner, Nan or the nanny", "Mum", "Dad" and "Nan" in the first-run pictures and the sample family. `Data/People.swift:46`, `Features/Onboarding/OnboardingView.swift:220`, `Data/SampleFamily.swift:47`.
- **Three of eight first-run steps are about other adults.** A single parent meets "Everyone sees the same day" and "Log together" before reaching Today.
- **An exact birth date is required.** A foster carer may not have one. There is no corrected age for a baby born early. `ChildForm.swift:36`.
- **Small volumes don't fit.** Bottles start at 150 ml, move in steps of 10 and stop at 10. `Features/Log/LogSheet.swift:30`, `:426`.
- **A four-year-old is treated as a baby.** Meals are "Solids" and "What did they try?"; milestones are all firsts.
- **"Breastfeed" cannot be changed.** The words setting covers nappy and Mum only.
- **After a child is removed** the app and the widget say "Add your little ones". `Features/Today/TodayView.swift:367`, `app/PuggleWidgets/FamilyWidgets.swift:239`.
- **Help has no support topic.** `docs/flows.md` section 15 promises one.
- **Leftover verdicts.** "Slept through", "3 things logged today", "Loved it / Some / Not today". `Features/Insights/InsightsView.swift:383`, `TodayView.swift:360`.
- **"What should we call you?"** breaks the writing guide's rule against "we". `OnboardingView.swift:338`.

## Seen in the simulator

- **Birth date.** "Choose" sets today's date with no picker. A second tap opens a calendar with no Done. "Add" stays disabled with no reason until the feeding question, which only appears once a date is set, is answered.
- **Undo after a delete in History** only appears on Today.
- **A sleep just started** shows "Cancel" for a minute before "Woke up", which reads as discard.
- **The "Last saved" bar** never went away and covered the tile labels when Today was at the top.
- **Sheets clip their last row:** the bottle sheet, the nappy sheet and "Delete entry" on an entry.
- **The delete confirmation** appears at the top of the sheet with no Cancel.
- **First-run dots** jump from the fifth to the seventh.
- **The Time row on an entry** looks tappable and is not.
- **Last night:** "11h 52m" beside "19:06 to 10:06", a 15-hour span, with nothing to explain the difference.
- **Levels are not explained to the person in them.** A Helper's Today looks like a Parent's. A Viewer is told "Mum or Dad can change that", when only the person holding the family can.
- **Two "You" rows** on the Family tab.
- **"Go to Today" did nothing** at the end of the first-run demo. This was under the `-debugFirstRun` launch flag, where there is nothing to dismiss. Opened from the Developer menu it should close; that path was not tested.

## Accessibility

- **VoiceOver:** a save announces nothing. The app posts no announcements at all. `TodayView.swift:167`.
- **Insights bars** are plain shapes with a tap, so the per-day values are probably not read. Month bars are about 7 points wide. `InsightsView.swift:251`.
- **Largest text:** the log sheets, the Last saved bar and the child panel's three-column grid never change layout. Only five files check the text size.
- **Text under the 13-point rule** in six places, including chart labels at 11 and the tile's last line shrinking to 9.
- **Contrast:** the "Not joined yet" pill fails in dark and at night (3.3 and 2.95 to 1). Light chart fills on paper are 2.1 to 3.1 to 1. Muted body text passes everywhere.
- **Voice Control:** "Start sleep" is labelled "Start Ollie's sleep", so saying what is on screen may not work.
- **Hold to close** on the play pad may not be possible with Voice Control or Switch Control.
- **Twins sharing an initial** get near-identical avatars: the four child colours differ in contrast by 1.01 to 1.20.
- **Targets under 44 points:** Week and Month at 40, widget buttons at 30, the demo's Close at 32.

## What already works

- Nothing outside the Family tab asks a person to invite anyone after setup.
- No account is needed and logging works with no signal.
- "Just logging" removes counters and totals. There are no averages or targets.
- Undo never times out, and deleted entries are kept for 30 days.
- The night look is on by default from 21:00 to 06:00.
- A name is free text, so "Nana" can sit beside entries.
- The medicine box reader asks for each field to be checked and never chooses a dose.
- Reduce Motion is honoured in the scenes, the rig and the stamp flow.

## The changes that would help most, for the effort

1. Close the three Helper delete paths by checking the level inside the store, not only in the screens.
2. Share medicine rules with the family. Until then, say "Checked on this iPhone only" on the medicine sheet.
3. Add "Neither" and "Tube" to the feeding question, and allow small volumes.
4. Replace "Add your little ones" with a plain state once a family has had a child, in the app and the widget.
5. A waiting screen after joining, and a "you're no longer in this family" screen after removal.
6. Rename the top level and take "partner", "Mum" and "Dad" out of fixed copy.
7. Open the date picker on the first tap, and say why "Add" is disabled.
8. Announce saves to VoiceOver, and make each chart bar a labelled button.
9. Let the log sheets and the Last saved bar stack at the largest text sizes.
10. Add Help topics for finding support and for what the app cannot do: two homes with equal control, handing a child's record to someone else, corrected age.

## What has been done since

Fixed on 13 November, in the commit after this report. 34 tests pass. Only the Family tab and the Add a child sheet were looked at in the simulator afterwards.

- **Helper delete paths (1 in the list above):** the store itself now refuses to delete an entry the person may not change, so the log sheet, the widget's Undo and "Cancel" on a sleep are all covered. A helper cancelling someone else's new sleep ends it instead.
- **Medicine rules (2):** not shared yet. The medicine sheet now says "Checked on this iPhone only."
- **Feeding (3):** "Neither now" is offered. Bottles go down to 5 ml, in steps of 5 at 30 ml and under. Tube feeding and cow's milk are not added.
- **Empty states (4):** once a phone has shown a child, an empty Today says "No children on Today" with no picture. The widget says "No children to show."
- **Joining and removal (5):** a "Getting the family" screen shows after an invite is accepted, for up to 15 minutes or until children arrive. A notice says "You're no longer in this family" if a joined family goes. Neither has been run on two phones.
- **Wording (6):** "partner", "Mum" and "Dad" are out of first run, the invite levels and the sample family. "What should we call you?" is now "Your name". The top level is still called "Parent".
- **Birth date (7):** "Choose" opens a date wheel at once, and the form says what is still needed before "Add" works.
- **VoiceOver (8):** a save and a delete are announced. Each chart bar is read as its day and amount.
- **Largest text (9):** the Last saved bar stacks its buttons underneath, the child panel's grid goes to one column, and log sheets open full height. Segmented pickers and chip rows inside the log sheets are unchanged.
- **Help (10):** two new topics, "Finding support" and "What the app can't do". No helpline numbers are given.

Also: two children's real names were in the test file and one was in a Help answer. Both are replaced with made-up names.

Still open from the tables above: sharing medicine rules, a joiner who already has children, transferring a family, a recoverable copy when a child is deleted, limiting export by level, writing the share back before the list of people is rebuilt, and the smaller simulator findings (Undo on every tab, clipped sheet rows, the delete confirmation, first-run dots, the Time row, last night's figures).
