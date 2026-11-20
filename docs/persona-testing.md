# Puggle: persona walkthroughs of the flows

Date: 11 November 2026. Input: `docs/flows.md` and the wireframes on the canvas page "Flows".

**What this is.** Eight AI agents each read the ten journeys and the wireframe screens and walked through them as a particular kind of parent or carer. It is a structured critique, good at finding gaps, unclear wording and missing flows before anything is built. **It is not user testing.** No real parent has used the app. Tap counts and sizes are read off drawings. Repeat this with real families once there is a build.

## The personas

| # | Persona | Would they keep using it? |
|---|---|---|
| 1 | Mum and Dad, first four days home; caesarean recovery, breastfeeding trouble, a midwife asking for every feed and nappy | For nappies and top-ups, yes, alongside the midwife's paper chart. It reads as a tracker for a six-month-old, not for week one |
| 2 | Parents at three months; looking for patterns, medicine, a return to work, switching from another app | Would try it, would not stay: no health logging, and Insights is too shallow |
| 3 | Toddler mid potty-training plus a two-week-old | Would keep the potty sticker and the feed timer, and drop the rest within a fortnight |
| 4 | Grandmother minding two children; large text, no glasses, unsure of iCloud | Not on her own by day two |
| 5 | Parents of eight-week-old premature twins on a hospital schedule | Not yet: better than apps that switch between babies, but every sheet assumes one child and one amount |
| 6 | The invited second parent, and a professional nanny | He would drift after a few weeks; she cannot do her job with it |
| 7 | Accessibility: a blind father (VoiceOver), a low-vision colour-blind mother, anyone one-handed | Not yet accessible |
| 8 | An anxious mother, a privacy-minded father, a parent burned by other apps | Not safe for the anxious mother as drawn; the other two would probably stay |

## What came up again and again

Ordered by how many personas raised it.

### Raised by four or more

1. **No way to log a breastfeed properly.** Today has no Breastfeed card, and the sheet is timer-only, so a feed can't be entered after the fact. (1, 2, 3, 5)
2. **No health logging.** Medicine, supplements, temperature and vaccinations appear in no flow, and nothing reminds about a dose or warns it's too soon. The only workaround is a milestone, which would celebrate a jab. (1, 2, 4, 5, 6)
3. **Entries can go to the wrong child.** Sheets open on the child last logged, the child chips are small and pale, and one tap saves. With twins the default is wrong half the time. (3, 4, 5, 7)
4. **Undo is too short.** A five-second toast is the only way back from a one-tap save. (1, 3, 4, 7)
5. **The "Asleep" button reads as a status.** It is also easy to hit by accident, and two children give two identical buttons. (1, 3, 4, 7)
6. **The Carer role is thin.** It doesn't say whether a carer can fix her own mistake, there's nowhere for the parents' instructions or a handover note, and what she can see is undefined. (2, 3, 4, 6)
7. **iPhone only.** An Android partner, grandparent, nanny or day care is locked out. (1, 2, 3, 6)
8. **Today doesn't answer "how are we doing today?"** No running totals, no last-24-hours counts, no "what's due next" per child. (1, 2, 3, 5)
9. **Wording that breaks the no-guilt rule.** "Nothing logged yet today", "slept through" beside "woke twice", "Accidents this week 2", and the dry-week streak. (1, 3, 5, 8)

### Raised by two or three

10. **Weight is wrong for small babies.** Steps of 0.1 kg where grams are needed; no birth weight or percentage change; buried four levels down. (1, 3, 5)
11. **The sticker chart is a streak in disguise.** "3 more dry days" means an accident costs the shiny sticker, which contradicts "no lost stickers". (3, 8)
12. **Insights pulls two ways.** Three-month parents find it too shallow (no wake windows, nap versus night, longest stretch). The anxious mother needs less, not more, and the flow shows averages its own rule forbids. (2, 8)
13. **"Both" assumes the same amount.** Twins on different amounts need a row each. (5)
14. **Pumping belongs to the parent, not a child,** and no flow has it. (1, 2, 5)
15. **The two parents aren't equal.** "Owner" appears above "Dad · Can log and edit". Nothing covers leaving with a copy or transferring ownership. (6, 8)
16. **Privacy answers are buried.** No one-screen explanation of where data lives, no "delete everything", and "no analytics that identify a family" reads as a hedge. (8)
17. **Nothing is toddler-proof.** The sticker screen hands the phone to a two-year-old with no lock. (3)
18. **Quiet mode is too broad.** "Any child asleep" is nearly always true with a newborn or twins, so the toddler's reward is usually muted. (3, 5)
19. **The surfaces outside the app aren't designed.** Widgets, the Lock Screen with two children, per-person notifications and the watch are named but not drawn. (6)
20. **Import is hidden,** six taps deep, and first run never mentions it. (2)

### Accessibility (persona 7, measured)

- **Contrast.** Ink and muted text pass AA on every surface. These fail: red "Delete" text on Paper (3.4:1), muted text on Sky (4.3:1), selected chips against their background (1.2 to 1.6:1), card and field edges (1.1 to 1.2:1), chart bars (1.4 to 1.6:1). Shell pink and Mint green have identical lightness, so colour alone cannot tell two children apart.
- **Tap targets.** Chips are about 22 pt high, the + on cards 33 pt, the sheet close button 28 pt. The minimum is 44 pt.
- **Text size.** Status lines and chips are drawn at 10 to 12 pt. At the largest text sizes the two-column card grid, the child row, segmented controls and the big number stepper will all break; none has a large-text layout.
- **VoiceOver.** Child rows read as five separate stops; the stepper has no spoken value; a nappy saves silently.
- **The flows claim** that Reduce Motion, Dynamic Type and VoiceOver are "supported on every screen". Only Reduce Motion is true of the code today.

## Mistakes in the flows that the walkthroughs caught

- "Bea is 6 months. Hide Bottle and show Solids?" is wrong: bottles continue. The prompt also has no way to decline.
- The Last night card says "9 h 20 min, 7:10 pm to 6:05 am", but that span is 10 h 55 min.
- "He woke at" uses a pronoun the app never asked for.
- The spec puts the doctor's PDF in Pro; the flows show it free.
- The accessibility claim above.

## Status (11 November 2026)

- **Tier 1: applied** to the flows and wireframes (`docs/flows.md`, canvas page "Flows", journeys 1 to 10).
- **Tier 2: drawn** as seven new journeys, 11 to 17. The sticker goal, hand-over lock and quiet-mode change (item 16) went into journey 4, not a journey of their own.
- **Tier 3: still open.** These are decisions for Tom. Where a flow touches one, it is drawn one way and marked "Open decision".
- None of this is in the app code yet, and none of it has been tried by a real parent.

Changes made along the way that were not in the list: "Carer" is now "Helper" (the grandparent persona read "Carer" as staff); the bottle reminder is off by default; ranges replace averages in Insights and the summary.

## Recommended changes

### Tier 1: fix in the flows before building

1. Add a Breastfeed card to Today, and manual entry (side, minutes, start time) on its sheet.
2. Stop wrong-child saves: no last-child default when children share a birth date, bigger chips with a tick on the selected one, and the child's name in every confirmation.
3. Replace the five-second toast with a persistent "Last saved: … Undo / Change" row.
4. Rename "Asleep" to a verb with the name ("Start Ollie's sleep"), and let a just-started sleep be cancelled.
5. Make every control at least 44 pt, mark selection with more than colour, and darken the destructive red.
6. Fix the wording: remove "Nothing logged yet today", "slept through", "woke twice" and the accident count; correct the three factual errors.
7. Show each child's day on Today: last feed (and side), time awake, today's total, and a rolling last-24-hours count.
8. Weight in grams from a card on Today, with birth weight captured at setup.
9. Show both parents as equal "Parent"; show "Owner" nowhere.
10. Let carers edit their own entries.

### Tier 2: new flows to add

11. **Health:** medicine and supplements with a schedule, next-due time and a too-soon warning; temperature; vaccinations. Logged plainly, no celebration.
12. **Setup questions** per child (how they feed, whether they're potty training) that build Today, with a newborn layout for babies under three months.
13. **Helper view** for carers: status at the top, four large buttons, no Insights or Family tabs; a parent-written "For today" card; a handover note back.
14. **Per-child amounts** when more than one child is selected; a **Pump** entry that belongs to the parent.
15. **"Just log" mode** that hides Insights, averages, elapsed-time counters and percentile bands; and a **"Your data" screen** (what leaves the phone, export everything, delete everything).
16. **Sticker goal** that adds up ("10 stickers earns a shiny one") in place of the streak; a hand-over lock on the sticker screen; quiet mode scoped to night hours or per child.
17. **Large-text layouts**, VoiceOver labels and a dark night theme.
18. **Outside the app:** widgets, Lock Screen with several children, notifications each person controls for themselves.

### Tier 3: decisions for Tom

19. **Non-iPhone carers.** At minimum say "needs an iPhone" on the invite. A web link for carers needs a server, which the app avoids today.
20. **How deep Insights goes.** Suggested: calm by default, depth on request (a multi-day timeline, nap versus night, wake windows).
21. **What Pro contains,** in writing, with a promise that nothing free moves into it. The doctor's PDF: free or Pro?
22. **Premature babies:** a due date for corrected age, used in charts and milestones.
23. **Twins side by side,** as an opt-in exception to the no-comparison rule.
24. **Day care:** an "at day care" state and a handover card.
25. **Ownership:** leaving with a copy, transferring, and who can delete a child.
