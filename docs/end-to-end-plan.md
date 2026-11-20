# Filling the gaps: a plan for end-to-end use

Written 11 November 2026. Measured against the 17 journeys in `docs/flows.md`, the App Store checklist in `docs/baby-tracker-spec.md` §13, and what `app/README.md` records as built. `docs/next-steps.md` (tonight's scheduled run) comes first; this picks up after it.

"End-to-end" here means a real family can rely on Puggle every day: both parents log on their own phones, nothing is lost, the app reminds them only when asked, and it can be handed to a grandparent. Today it works well on **one phone**, with **no reminders**, and it **expires every 7 days** because it is signed with a free Apple ID.

## Where each journey stands

| # | Journey | State | What is missing |
|---|---|---|---|
| 1 | First run | Built | Invite step, link to "Your data", character step |
| 2 | Everyday logging | Mostly built | Puggle's nod on save, "how it went" for solids |
| 3 | Sleep | Mostly built | A night waking inside a sleep; starting twins' sleep together |
| 4 | Potty training | Built (stamp cards) | "Time to try?" reminder; real stamp and sticker art |
| 5 | History and insights | Built | Nothing major |
| 6 | Family and sharing | Written, never run | Needs the paid developer account; then: invite, accept, manage a person, roles |
| 7 | Children and characters | Partly | Character builder, photos |
| 8 | Milestones and growth | Mostly built | Milestone photos, percentile bands (data and licence to check), units |
| 9 | Settings, Pro and Help | Partly | Pro and tips, import, "Contact us", fuller Help |
| 10 | When things go wrong | Partly | No iCloud, offline, "Logged twice?", invite errors, notifications off, iCloud full |
| 11 | Health | Partly | Regular medicines, reminders, "due" on Today |
| 12 | Setup that fits the child | Mostly built | Nappy colour (for midwives who ask), suggesting tile changes as a child grows |
| 13 | Helpers | Not started | Depends on sharing (6) |
| 14 | Twins and pumping | Partly | Pumping, milk on hand |
| 15 | Calm and private | Mostly built | Finding support (helplines per country), "Our promise" |
| 16 | Large text, VoiceOver, night | Night built | Largest text layouts, VoiceOver pass, contrast check |
| 17 | Outside the app | Partly | Home Screen widgets, Control Centre controls, "My notifications" |

Across everything: there are **no automated tests**, no crash or data-loss safety net beyond export, and no import.

## The one decision that gates the most

**The paid Apple Developer Program ($99 a year).** Without it there is no iCloud sync, no sharing (journeys 6 and 13, and part of 10), no TestFlight for other families, no in-app purchases, and the app stops opening every 7 days. Everything in phase A below can be done without it; phases C and E cannot.

Linked to it, from the launch checklist: Apple's guideline on health data in iCloud (5.1.3) needs checking before relying on CloudKit, and individual versus organisation enrolment is slow to change later.

## Phases

### A. One phone, complete (no paid account needed)

Makes daily use on one phone feel finished.

1. **Reminders and notifications.** Permission asked only when a reminder is first switched on, with the reason. Each person sets their own. Kinds: "it's been N hours since a feed" (interval set by the parent), regular medicines, potty "Time to try?". No nagging copy. (Journeys 4, 10, 11, 17)
2. **Regular medicines and "due".** Set once: name, dose, times, smallest gap. What's due shows quietly on the child's row and goes when logged. Nothing turns red. (11)
3. **Sleep and feed gaps.** A night waking inside a sleep without ending it. Start twins' sleep together. "Still feeding?" (if not done tonight). (3, 14)
4. **Pumping and milk on hand.** A Pump entry that belongs to the parent, left and right, where it went; a running total in the fridge and freezer that breast-milk bottles draw from. (14)
5. **Smaller logging gaps.** Solids "how it went"; nappy colour as an optional extra; "Logged twice?" when two bottles for the same child land within five minutes. (2, 10, 12)
6. **Home Screen widgets and Control Centre.** Small: one child at a glance; medium: every child with log buttons. A "Start sleep" control. Widgets need to read the app's data, which needs an App Group; **check whether a free Apple ID can sign one** before building. (17)
7. **Puggle's reactions.** The nod on save; the three sleep states (awake, quiet, asleep). The sleep states **need Tom's go-ahead** (asked, not yet answered). (2, 3)

### B. Trust and safety (no paid account needed)

Makes it safe to rely on.

1. **Automated tests** for the store's logic: logging, undo, sleep and feed timers, stamp cards, earned stickers, the day-so-far sums, CSV export. A test target in `project.yml`.
2. **Import.** From a CSV (ours, and the common trackers' exports where the format is public). Shows what it found before adding. (9)
3. **Help, Contact us and support.** Short answers for every journey; "Contact us" opens a pre-filled email with the app version; "Finding support" with helplines. **Helpline numbers must be checked per country by a person** before release. (9, 15)
4. **Error states.** No iCloud, offline, iCloud full: each says so once, in plain words, and logging keeps working. (10)
5. **Accessibility pass.** Every screen at the largest text size, with VoiceOver, with Reduce Motion; fix what breaks. Measure contrast in day and night. (16)
6. **Data safety.** A migration test that opens a store from each earlier model version; soft delete for entries (undo after delete); export reminder in "Your data".

### C. Two phones (needs the paid account)

1. Switch to the "Puggle" scheme with iCloud, deploy the CloudKit schema to development, and test with two Apple Accounts: invite, accept, both log, edits and deletes sync, "latest edit wins".
2. Manage a person: what they can do, end access (everything they added stays). Roles: parent and carer. (6)
3. Helpers: the simpler one-column Today, the parents' "For today" note, the end-of-day summary. (13)
4. Invite failures and "No iCloud" explained with the next step. (10)
5. Live Activities: a timer started on one phone shows in the app on the other; note on the Lock Screen that it is only on the phone that started it. (17)

### D. Characters and art (needs drawings)

Character builder and photos (7); real stamp and sticker art; the animated Puggle (Rive); the card scenes. Code is ready to take the files; the drawings are the work.

### E. Launch (needs the paid account)

1. Pro and tips with StoreKit: a one-off Pro, three or four tips with a small thank-you (an alternate icon or an outfit for Puggle), Restore Purchases. **Pro's contents and price are Tom's decision.** (9)
2. App Store paperwork from the spec's checklist: privacy policy and support URLs, privacy labels, privacy manifest, age rating, screenshots.
3. A website with the privacy policy, support and a newsletter sign-up.
4. TestFlight with a handful of families for two to four weeks before release.

## Suggested order

Tonight's run (`next-steps.md`), then **A1 to A5**, then **B1, B4, B5**, then the rest of A and B. Decide on the paid account while those are being built, since C and E take the longest to get through Apple. D runs alongside whenever drawings arrive.

Rough size, in the "rounds" used so far today (one round is roughly one feature built, checked in the simulator and committed): A is about 7 rounds, B about 6, C about 5 once the account exists, E about 4 plus Apple's review time.

## Decisions waiting on Tom

1. The paid developer account, and individual or organisation.
2. Whether CloudKit is acceptable under guideline 5.1.3 (to check before C).
3. Puggle's three sleep states.
4. What Pro contains and costs; what a tipper gets.
5. Whether units should convert on display (ml/oz, g/lb, °C/°F).
6. Who checks helpline numbers per country.
7. Drawings: characters, stamps and stickers, scenes.
