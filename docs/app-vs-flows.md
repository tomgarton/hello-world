# The app compared with the flows

Written 13 November 2026, against the app at commit `3c8a644` and `docs/flows.md`.

Two readers compared each journey in `docs/flows.md` with the Swift code, half the journeys each. They read the code; nobody built or ran the app, so behaviour here is read, not observed. File references are under `app/Puggle/` unless they say otherwise.

`app/README.md` is out of date in places: it says first run has no invite, and lists pumping, reminders, widgets and night mode as not built. All of those exist.

## Ideas that were lost, most valuable first

1. **People and roles (journeys 6 and 13).** The Family tab has one "Invite someone" button (`Features/Family/FamilyView.swift:86`). There is no list of who is in the family, no way to change or end someone's access, and one level of access only (read and write).
2. **Helper mode (journey 13).** Nothing is built: no simple four-button Today, no "For today" note, no handover note, no end-of-day summary, no day limits.
3. **Joining, and joining that fails (journeys 6 and 10).** An invite is accepted silently and a failed join is only printed to the console (`App/PuggleApp.swift:258`). The flows had a screen saying who invited you and to what, and plain words with a next step on failure.
4. **Medicine rules shared across the family (journey 11).** Smallest gap, dose limit and regular medicines are stored on one phone (`Features/Log/MedicineLabel.swift:9`, `Features/Reminders/Reminders.swift:44`). The other parent gets no "Too soon?" and no "Due" line.
5. **Night wakings added or fixed afterwards (journey 3).** A waking is only recorded by tapping Start sleep within 90 minutes and choosing to carry on the same sleep. There is no way to add one later.
6. **Insights for more than one child (journey 5).** One child at a time with a picker. The flows had a card per child, so twins' nights sit side by side.
7. **"Just logging" everywhere (journeys 11 and 15).** Widgets still show "Since a feed" and asleep timers in that mode (`app/PuggleWidgets/FamilyWidgets.swift:100`). Medicine "Due" is hidden in that mode, where the flows kept it.
8. **Finding support (journey 15).** No helplines or support resources anywhere in Help.
9. **Log sheets at the largest text (journey 16).** Segmented controls remain (`Features/Log/LogSheet.swift:449`); the flows used list rows with ticks. Chart axis text is below the 13 pt rule and bars are filled, not outlined with a value on each.
10. **Two taps deep (journey 2).** Solids, weight, health and past sleep are now three taps away, behind each child's panel. Undo is lost if the app restarts (`Data/FamilyStore.swift:19`).
11. **"Growing up" as a suggestion (journeys 7 and 12).** Tiles switch on the child's age without asking (`Data/Model.swift:284`). The flows had the app suggest and the parent decide.
12. **Characters or a photo for each child (journeys 1, 7 and 14).** Children are a colour and an initial, so twins with the same initial differ only by colour.
13. **The newborn row (journey 12).** No side or start time of the last feed, and no last-24-hours line on the row.
14. **Growth (journey 8).** Weight only: no length or head circumference, no WHO percentile bands, no birth weight field.
15. **Import from another tracker (journeys 1 and 9).** None.
16. **Offline and iCloud-full notes (journey 10).** Nothing watches the network; the iCloud card shows only on Family and in first run.
17. **Smaller things.** The honest "less than three days of data" state in Insights; the summary reachable from Insights; milestone photos and suggested milestones; the potty method and "where"; the week-at-a-glance chart; Siri for every log action (five are covered); Lock Screen accessory widgets; a feed button on the widget.

Pro and tips are also absent (no StoreKit code). That matters to the business, not to a tired parent.

## Built differently

Mostly deliberate, and several are better than the flows:

- **Today** has a Puggle scene header, child rows, up to three large tiles chosen by the parent, a Stamp book row and "Today so far". Feeding is one merged tile.
- **Potty stickers became stamp cards:** five stamps earn a shiny sticker, with a two-page stamper. The stamp is only offered when the entry is for one child.
- **Tapping an entry opens it to read first,** then Edit. Safer, one tap deeper.
- **Nappy has four choices** (wet, dirty, both, dry) with colour picked before saving; the flows had three choices and colour added after.
- **First run is longer** (name, "how much to see", two hello pages), and Skip shows on four steps, not all.
- **Settings is long** (nine sections) and a second "You" sheet repeats some of it.
- **Lock Screen:** one card per child, not one card with a line each.
- **Export** is one CSV file.

Three wording or rule slips against the flows:

- Today's empty state says "Nothing logged yet today", a line the flows ruled out.
- A "dry days" sticker counts accident-free days, which leans against "an accident never takes anything away".
- Reminders use the default sound; the flows asked for quiet ones.

## To check before anyone else uses it

- **Delete everything** deletes "every family this phone can see" (`Data/FamilyStore.swift:410`). It reads as though an invited person could wipe the shared family. Not tested.
- **A child's birth date defaults to six months ago** (`Features/Family/ChildForm.swift:6`), which is easy to leave wrong.
- **Widget buttons log without opening the app,** so a stray tap has no Undo.
- **"Logged twice?"** checks bottles only and only before saving, so two phones saving offline would still duplicate.

## In the app but in no journey

Worth adding to the flows and the canvas, because they are now part of the product:

- Weather on Today, and Puggle dressed for it
- The play pad (crayons, pens, colouring sheets) and the cover that guards against stray swipes while a child holds the phone
- Stamp cards, the stamp book and earned stickers, with the 3D sticker viewer
- "Today so far" with a swipe to log the same again
- Recently deleted (30 days) and Undo after a delete
- "Back to sleep?", "Still feeding?", and starting or ending both twins' sleep together
- The "most doses in 24 hours" limit and reading a medicine box with the camera
- Lock with Face ID
- "I've been invited", "Welcome back" and a sample family in first run
- A Control Centre "Start sleep", the Lock Screen glance, and the Siri and shortcuts page
- The tile chooser, units and words (nappy or diaper), searchable Help with Contact us
- The night look as its own setting, with a Focus filter
