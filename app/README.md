# Puggle iOS app (v0.1, household build)

The first working version of Puggle, for our own family: two children on one screen, quick logging, a shared history, and sharing with a partner through iCloud. See `docs/baby-tracker-spec.md` §11 step 3.

> **Status (13 November 2026):** runs on Tom's iPhone with iCloud, push and the App Group (the "Puggle" scheme), and in the simulator without them ("Puggle Local"). 26 unit tests in `PuggleTests`. Sharing between two Apple Accounts has still not been tested: it needs a second iPhone. Sections below were written as each round was built, oldest first, so an early section may describe something a later one replaced.

## What's in v0.1

| Area | What it does |
|---|---|
| Today | Every child at once: who is asleep (live timer) and when they last fed. Cards for Bottle, Sleep, Nappy, Potty, Solids and Breastfeed showing the latest for each child, each with a + to log |
| Logging | One sheet for every activity. Pick one child, several, or Everyone. Bottle: volume, formula or breast milk. Nappy and potty: one tap saves. Sleep: start and stop from Today, or log a past nap |
| History | Everything, newest first, grouped by day, filter by activity, swipe to delete |
| Family | Add and edit children. Invite someone with Apple's sharing sheet (iCloud build). Your data, Help and about |
| Insights | Last night and the last seven days, per child |
| Sync and sharing | Core Data with CloudKit: private store for your family, shared store for a family someone shared with you. No server, no sign-up |

### Flows built so far (from `docs/flows.md`)

Journeys 2 (everyday logging) and 3 (sleep), built on 11 November 2026 and checked in the simulator:

| Flow step | In the app |
|---|---|
| Last saved, with Undo and Change | A row on Today that stays until the next save. It resets when the app restarts |
| Edit or delete | Tap any entry on a Today card or in History. Delete asks once |
| Bottle | Opens on the child's last amount and milk. The number can be typed |
| Log something earlier | "Now", "Earlier today" (back one hour per tap) and "Yesterday" under the time |
| Who it's for | Opens on the child last logged for that activity, shown with a tick. Children born on the same day: no guess. Several children get one entry each |
| Solids | Foods logged before appear as chips |
| The day so far | Tap a child's row: counts for today and the last 24 hours |
| Start sleep | A verb, read by VoiceOver with the name. The row turns night blue with a live timer |
| Cancel | For the first minute the button reads "Cancel" and leaves no entry |
| Woke up | Ends the sleep and shows its length in Last saved; Change adjusts start and end |
| Still asleep? | A timer running 14 hours or more gets one question when the app opens, with "Set wake time" |

Also built on 11 November 2026, as thinner versions of journeys 1, 5, 7, 9, 12 and 15:

| Flow | In the app |
|---|---|
| First run (1) | Splash with the name, two skippable hello screens, add your first child, "Anyone else?", then Today. Later rounds added "I've been invited", "Welcome back" and a sample family; there is still no character step |
| Setup that fits the child (12) | "How do they feed?" for babies and "Potty training" for older children decide which tiles show. Children added before this keep every tile until the question is answered on their page |
| Children (7) | Tap a child on the Family tab to change name, birth date, colour and setup answers. Delete asks twice and removes their entries |
| History (5) | Filter by child and by activity. The filter stays set until cleared |
| Insights (5) | A new tab: last night per child, and the last seven days as outlined bars with a value on each. Says so when there are fewer than three days of entries |
| Your data (15) | Where the data lives, export everything as a CSV file, and delete everything, which returns to first run |
| Help and about (9) | Five short answers, and the name and version |

A third round on 11 November 2026, as thinner versions of journeys 4, 8, 11 and 12:

| Flow | In the app |
|---|---|
| Potty stickers (4) | After a wee, a poo or a try, the phone offers nine stickers to choose from; a grown-up holds the bottom line for two seconds to skip. "Tried" earns one too. Accidents are logged plainly and never appear on the chart |
| Sticker chart (4) | From Today: the last seven days and every sticker so far. Every tenth is a shiny one. It only adds up. Can be switched off on the Family tab |
| Health (11) | One Health tile: medicine (name, dose as written, optional smallest gap), temperature (number and where it was taken), vaccination (name). No colour, no "high", no advice |
| Too soon? (11) | If a medicine is logged inside the gap the parent set for it, the app asks once and never blocks. Medicines used before are one tap |
| Weight (8, 12) | A Weight tile for children under two, typed in grams, showing the change since the first weight logged |

New optional fields on Event for these: `dose`, `value` (°C or grams) and `sticker`. Medicine gaps are kept on the phone, not synced.

Fourth round, 11 November 2026:

| Flow | In the app |
|---|---|
| Breastfeed timers (2, 12) | The Breastfeed tile opens a left and a right timer. Tapping a side starts it and stops the other; tapping again pauses. The feed keeps running with the sheet closed and shows on the child's row. "Enter a past feed" is one tap from there. No Lock Screen timer yet |
| Twins' own amounts (14) | A bottle for several children gives each a row, filled in from their own last bottle |
| Milestones (8) | On each child's page: pick a first or write your own. The list shows the date and their age then. Saving one plays the one big "Hooray!" |
| Growth (8) | On each child's page: their weights as a line chart and a list with their age at each. No percentile bands. Always carries the line about the nurse or GP |
| Summary for the doctor (5) | On each child's page: a one-page PDF of the last seven days, recent weights, and health entries from the last 14 days, to share or print |
| Hide a child (7) | "Hide from Today" on the child's page keeps their history and can be undone from the Family tab |

Fifth round, 11 November 2026:

| Flow | In the app |
|---|---|
| App icon | `Puggle/Resources/AppIcon.icon`, an Icon Composer document: Puggle's face on Wattle in three layers (head, face, clip), made from `design/rive/puggle-parts.svg`. Open it in Icon Composer to adjust. Light, dark and tinted versions come from the one file |
| Settings (9) | Family tab, top row. Your name, appearance, how much to see, potty stickers, the sample family, Your data, Help |
| Who logged it (6) | The name in Settings is saved on each new entry and shown in History and the export |
| Appearance | Same as iPhone, Light or Dark. The palette has a dark twin for every colour |
| Just logging (15) | Today shows names and tiles only, no elapsed times or day so far, and Insights is hidden. Not yet asked in setup |
| Sample family | Two made-up children with two weeks of entries, in memory only and labelled on Today and Family. The real family is untouched; nothing done there is kept |

Sixth round, 11 November 2026:

| Flow | In the app |
|---|---|
| Lock Screen and Dynamic Island timers (3, 17) | A Live Activity for each running sleep and each running breastfeed, one per child. The Lock Screen shows the name, a clock that counts by itself and a button: "Woke up" for a sleep, "Finish" for a feed. The Dynamic Island shows a moon or heart and the clock, with the button when expanded. iOS ends a Live Activity after about eight hours; the sleep itself keeps running in the app |

The timers live in a second target, `PuggleWidgets` (a widget extension), with the shared types in `Shared/`. It needs no entitlements, so the free Apple ID build includes it. A timer started on another phone does not appear on this phone's Lock Screen until the app is opened here.

Seventh round, 11 November 2026:

| Flow | In the app |
|---|---|
| One Lock Screen card per child | The card shows a running feed, else a running sleep, else the glance. It changes in place, so "Woke up" on the Lock Screen turns it into "Awake" without opening the app |
| Feed from the Lock Screen | Left, Right and Finish on the card. Tapping the running side pauses it |
| The glance | For babies: "Fed … ago" and "Awake …", counting up, for up to eight hours after the last feed or wake. Never "due", nothing turns red. On by default; a switch in Settings; hidden in "Just logging" |
| Splash | Puggle's mark and the wordmark for about a second on each cold start, matching the launch screen |
| Illustrations | The 12 Puggle line icons replace SF Symbols on the Today tiles, History and milestones (light and dark versions, from `design/canvas/gen/iconsys3.py`). Puggle stands on the first-run pages, the empty Today and the celebration; her mark is on the splash and in Help |

The pictures are in `Assets.xcassets` as SVGs. Still to come from the canvas: the scenes (Morning, Bedtime, Celebration), the friends, the sticker art and the animated Puggle (Rive).

Eighth round, 11 November 2026:

| Flow | In the app |
|---|---|
| Haptics | One helper, `Design/Feel.swift`: success when something is saved or finished, selection when a child, chip or colour changes, a notch for each step of an amount, a light tap for + and Undo, and a warning with "Too soon?". Nothing plays for scrolling or navigation |
| Press states | Buttons give slightly under the finger (`PressStyle`); with Reduce Motion they dim instead |
| Small animations | "Last saved" eases in when it changes, a child's row fades to night blue when a sleep starts, chips and feed sides animate their selection |

Ninth round, 11 November 2026:

| Flow | In the app |
|---|---|
| Touch feedback switch | Settings: turns every haptic off |
| Calmer motion | Everyday buttons press with no bounce; the milestone celebration winds up, then lets go; the feed clocks and a child's status line roll between values |
| Liquid Glass | On iOS 26 the + buttons on the tiles and the sleep button are interactive glass, so they lift and warp when pressed. The + buttons use the quiet variant (clear glass tinted to the tile), because seven bright raised circles outshone the children's rows (`glassControl` in `Design/Feel.swift`). Earlier versions keep the flat fill. Cards, rows and the pinned Save button stay solid: glass on content hurt legibility, and a glass Save button all but vanished when disabled |

Tenth round, 11 November 2026:

| Flow | In the app |
|---|---|
| Siri, Action button, Shortcuts (17) | `App/Shortcuts.swift`: Start sleep, Woke up, Log a nappy, Log a bottle (uses the last amount if none is said) and Last feed. They run without opening the app. Because they are Shortcuts actions, an NFC tag or a time of day can trigger them too. A Lock Screen card only appears once the app has been opened, since iOS will not start a Live Activity from the background |
| Night look from a Focus (16) | A Focus filter: add "Night look" to the Sleep Focus in the Settings app and the app goes dark while that Focus is on |
| Lock with Face ID | Settings: asks for Face ID or the passcode each time the app is opened. Lock Screen timers and Siri still work |
| Milestone haptic | A composed pattern (three rising ticks, then a full beat) timed to the celebration's windup. The only custom pattern |

Eleventh round, 11 November 2026 (from testing on the phone):

| Fix | In the app |
|---|---|
| Undo for twins | Sleeps stopped within two minutes of each other share one "Last saved" row, and Undo resumes them all |
| Child picker | Child chips and "Everyone" are one size |
| Dynamic Island | Expanded: the name on the left, the number that matters large on the right, the buttons beneath. Compact: icon and time |
| Glance | Hours and minutes with no ticking seconds. Shown for children under two with a feed in the last eight hours; "Awake" is added only under 18 months. The glance has a Start sleep button |

Twelfth round, 11 November 2026 (a calmer Today):

| Change | In the app |
|---|---|
| Child rows | Two fixed lines, what then when, with interpuncts: "Bottle · 150 ml" over "14 min ago". Every row is the same height |
| Tiles | The whole tile is the button; the + circles are gone, leaving a small + as a hint. One quiet line shows the latest in the last 24 hours ("Ollie 19:27 · Bea 20:55"), so every tile is the same height. Touch and hold a tile to change the latest entry |
| Last saved | Floats above the tab bar, so saving never moves the tiles |

Thirteenth round, 11 November 2026 (Today, option C from `docs/mockups/today-proposed.html`):

| Change | In the app |
|---|---|
| Header | The date with Puggle beside it, in place of the children's names. Tap her and she hops; while a child sleeps she sways instead. She hops once on the first open of each day. Wired to `PuggleController`, so the animated character takes over when the Rive file exists |
| Tiles | Up to three large tiles in a row and the rest as chips (`Features/Today/Tiles.swift`). Suggested from what the children use; "Edit" opens a chooser where each is a main tile, a chip or hidden |
| Sleep | No Sleep tile. Sleep starts from each child's row; "Add a past sleep" is in the child's day sheet |

Fourteenth round, 11 November 2026 (stamp cards; prototype in `docs/mockups/stamp-prototype.html`):

| Change | In the app |
|---|---|
| Stamp cards (4) | Replaces the sticker chart. Each wee, poo or try earns one ink stamp on a kraft paper card: one ink colour, a little crooked, dated. Five stamps fill a card and the sixth space takes a shiny sticker. Cards take turns between three crayon pictures (Beach, Backyard, Night) |
| Stamping | The stamper drops, the card dips and settles, a ring runs out through the paper and a heavy haptic lands. Dragging the card tilts it. The paper is matte; only the sticker shines |
| The shiny sticker | After the fifth stamp the child drags it (or taps it) onto the last space. The card lifts and quatrefoils scatter |
| Stamp book | The card being filled, finished cards, and stickers earned |
| Earned stickers | For finished cards, firsts on the potty, new foods tried, milestones and dry days in total (`Features/Potty/StampBook.swift`). Only earned ones are shown. No streaks, nothing expires, nothing for logging. Also on each child's page |

The stamps use system symbols and the card pictures are simple strokes: stand-ins for the sticker art on the canvas. Not built: a paper ripple or curl shader, foil that follows the phone's tilt, sound.

Fifteenth round, 11 November 2026 (stamp cards, second pass):

| Change | In the app |
|---|---|
| Card edge | Cut by hand: `PaperEdge`, a slightly uneven outline in place of a perfect rounded rectangle |
| Stamps | The eight Australiana drawings from `design/canvas/gen/world_style.py` (thong, esky, Hills Hoist, lamington, fairy bread, pavlova, surfboard, zinc stick), exported as one-colour images. The selector is two rows of larger stamps on a paper sheet that stays light in dark mode |
| Stickers | Each uses one of the soft shapes (quatrefoil, blossom, soft hexagon, scallop, pebble, soft square) and one of five foils (rainbow, sea, sunset, pearl, gold), with a quatrefoil repeat pressed into the foil. Card stickers carry Puggle's face; others carry their activity icon |
| Peel and fold | The shiny sticker sits on a backing sheet, leaves its outline when lifted, and folds down onto the last space |

Sixteenth round, 11 November 2026:

| Change | In the app |
|---|---|
| First run (1, 12, 15) | Eight steps: welcome (with "Look around a sample family first"), two short pages, your name, add a child, "Anyone else?", "How much to see", and "You're set". Back, Skip and progress dots. `Features/Onboarding/` |
| Night look (16) | Very dim warm text on near-black. Comes on by itself at set times (default 9 pm to 6 am), while a child sleeps, or both; `Design/NightMode.swift`. The root view is rebuilt when it flips, which closes open sheets |
| Settings (9) | Grouped: You, Look and feel (Appearance and night, Units, Touch feedback), Today (How much to see, Tiles on Today, Lock Screen), Privacy, and the rest. Units are stored but entries still show millilitres, grams and Celsius |
| Paper | The ripple and corner curl shaders are on (`Design/Paper.metal`; needs Apple's Metal Toolchain to build). Card drawings have a wax crayon texture |
| Stamps | Redrawn as bold solid shapes with cut-out details and drawn larger. A cricket bat replaces the zinc stick |

Seventeenth round, 11 November 2026 (stamps, third pass; mockup in `docs/mockups/stamps-v3.html`):

| Change | In the app |
|---|---|
| Stamp set | Thirteen: star, heart, sun, moon, duck, fish, butterfly, train, balloon, kangaroo, thong, surfboard, cricket bat. Things a toddler anywhere can name, with a little Australia. The earlier Australian set (esky, Hills Hoist, lamington, fairy bread, pavlova, zinc stick) is no longer offered but still draws on old cards |
| Icon pack | Nine pictures are from Phosphor Icons, fill style (MIT; `Resources/PhosphorIcons-LICENSE.txt`). This is an exception to "our own drawings only", made for stamps because they must read at a centimetre across. The kangaroo, duck, thong and surfboard are drawn for the app; no pack has them |
| Ink pads | Eight inks. The child picks a stamp and a pad; the entry saves "stamp:ink" |
| Date | Runs round the bottom rim in a gap in the inner ring |
| Card stickers | Round shapes only; the scallop was too flat for Puggle's face |

Eighteenth round, 11 November 2026 (the stamper; prototype in `docs/mockups/stamper-prototype.html`):

| Change | In the app |
|---|---|
| Page one: get your stamp ready | Pick a picture (13, in rows of five), press the wooden stamper on one of eight ink pads, and try it on scrap paper. Play stamps fade over about ten seconds and never count. The ink lasts eight presses, the last three fading. "Stamp my card" wiggles after fifteen seconds of play |
| Page two: stamp your card | Opens on the whole card, moves in on the glowing space, and back out once stamped. The stamp lands where it was pressed, up to a little off centre, and the screen closes by itself. The shiny sticker follows on the fifth |
| Stamp wear | Modelled on real postmarks: uneven pressure fading softly to one side, paper specks, lighter middles, breaks in the ring, and the odd heavy or doubled print (`StampWear`). Card stamps are gentler so the picture always reads. Each stamp saves its seed and offset ("stamp:ink:seed:dx:dy") so it looks the same every time |
| Skip | For grown-ups: a ring fills over two seconds while held, and drains if let go |
| Tap or drag | Everything that can be dragged can also be tapped |

Nineteenth round, 12 November 2026 (`docs/next-steps.md`, then phase A of `docs/end-to-end-plan.md`):

| Change | In the app |
|---|---|
| Dark mode on the stamp screens | Scrap paper, picture tray, card, sticker backing and inks all follow dark mode and night |
| Night look in place | Night is a trait the colours read, so switching at 21:00, 06:00 or when a sleep starts no longer closes open sheets. Puggle dims at night |
| Still feeding? | A breastfeed timer running 90 minutes asks once: finish the feed, or keep going |
| Paper curl | The stamp card corner wraps round a roll, with a highlight, a crease shadow and the plainer back of the paper |
| Interpuncts | "Bottle · 150 ml · formula" everywhere, as on the child rows |
| Reminders | Settings → Reminders. Each person's own, kept on their phone: hours since a feed, regular medicines at set times, potty "Time to try?". Permission is asked when the first one is switched on |
| Due on Today | A regular medicine shows quietly as "Due · Iron drops · 8:00" on the child's row, and goes once a dose is logged. Its name is a one-tap chip on the medicine sheet |
| Night wakings | Start sleep within 90 minutes of a sleep that ended at night asks "Back to sleep?". Carrying on keeps one sleep with the waking inside it ("woke once"), left out of totals and shown as a gap in Insights |
| Sleep together | With two or more children, one button starts sleep for everyone awake, or ends it for everyone asleep |
| Pump | A chip for breastfed children. Left and right amounts, and fridge, freezer or fed. The pump belongs to the parent, not a child |
| Milk on hand | Worked out from the last count: pumps add, breast-milk bottles take from the fridge first. "Update" sets a fresh count. Shown on the pump and bottle sheets |
| Solids and nappies | Solids can note how it went; a nappy can note its colour before the one-tap save |
| Logged twice? | A second bottle for the same child within five minutes asks first, and says who logged the first |
| Puggle's nod | A small nod each time something is saved |

## Not built (as of 13 November 2026)

The paragraphs that used to be here listed things as missing that have since been built: widgets and the Control Centre control, pumping and milk on hand, reminders and regular medicines, the night look, units, Contact us in Help, "how much to see" in setup, twins' sleep together, and Puggle's reactions to a save.

Still not built:

- People and roles: a list of who is in the family, and changing or ending access
- A join screen, and plain words when joining fails
- Leaving a family you were invited to ("Delete everything" leaves it alone)
- Medicine rules shared across the family (they are kept on one phone)
- Helper mode (journey 13)
- Adding or fixing a night waking afterwards
- Characters or a photo for each child; milestone photos; suggested milestones
- Growth beyond weight, WHO percentile bands, birth weight
- Import from another tracker
- Pro and tips (no StoreKit code)
- Swimmers for Puggle, and the friends drawn in the canvas style

The fuller comparison with the designed flows is `docs/app-vs-flows.md`.

## Build it on your Mac

1. Install XcodeGen: `brew install xcodegen`
2. Generate the project: `cd app && xcodegen` (creates `Puggle.xcodeproj`)
3. Open `Puggle.xcodeproj` in Xcode.
4. **Bundle ID and iCloud container.** These are `com.tomgarton.puggle` and `iCloud.com.tomgarton.puggle`. To change them, edit three places:
   - `project.yml` (`bundleIdPrefix` and `PRODUCT_BUNDLE_IDENTIFIER`), then re-run `xcodegen`
   - `Puggle/Resources/Puggle.entitlements`
   - `Puggle/Data/Persistence.swift` (`cloudKitContainerID`)
5. In the target's **Signing & Capabilities**, choose your team. Check that **iCloud → CloudKit** (with your container ticked), **Push Notifications** and **Background Modes → Remote notifications** are all present; Xcode creates the container in your developer account.
6. Run on your iPhone (or a simulator signed in to iCloud).

### Running on a phone with the paid account (from 12 November 2026)

The paid Apple Developer Program membership is active on the same team (X2UM64LDU4). Build the **Puggle** scheme (Debug) for the phone: it has the iCloud and push entitlements, so entries sync to the family's own iCloud and sharing can work. Profiles last a year, not 7 days. Xcode must be signed in to the Apple Account (Settings → Accounts) for it to register capabilities.

On 12 November 2026 the Puggle build was installed over the Puggle Local build on Tom's phone. The same database files picked up CloudKit: all entries were kept (checked against a backup taken first) and were exported to iCloud. The backup is in `puggle-backup-20261112-1826` beside the repository.

### Running on a phone with a free Apple ID

A free Apple ID cannot sign the iCloud and push entitlements, so use the **Puggle Local** scheme. It builds the `Local` configuration: no entitlements, and `LOCAL_ONLY` set, which makes `Persistence.cloudSyncEnabled` false. Data stays on the phone, the Family tab says sharing is off, and the app needs reinstalling every 7 days.

1. Xcode → Settings → Accounts: add your Apple ID.
2. Plug in the iPhone, tap Trust, and turn on Settings → Privacy & Security → Developer Mode.
3. Choose the **Puggle Local** scheme and your iPhone, pick your personal team in Signing & Capabilities, and Run.
4. First launch: on the phone, Settings → General → VPN & Device Management, trust your developer certificate.

Installing a build from the **Puggle** scheme over the top (paid account) turns sync on for the same local data; this was done on 12 November 2026 and kept every entry.

### Testing sharing

Sharing needs two different Apple Accounts. On your phone, go to Family → Invite someone and send the link to your partner. When they open it on their iPhone with Puggle installed, your family appears in their app and both of you can log.

### The brand font

Titles and big numbers use Bricolage Grotesque (SIL Open Font License; the licence is beside the font in `Puggle/Resources`). The file is the variable font from Google Fonts, `BricolageGrotesque-Variable.ttf`, listed in `Info.plist` under `UIAppFonts`. It has an optical-size axis from 12 to 96, and left alone it draws the 96-point cut at every size. `DisplayType` in `Design/Theme.swift` sets the axis to the point size being drawn, so a 32-point heading gets the open, sturdy cut and 64-point numerals get the tight display cut. If the file is removed, the system rounded font stands in.

All display type goes through `.displayFont(size)`, which also follows Dynamic Type up to one and a half times the design size. Interface text uses the system text styles, which choose their own optical size.

## Layout

```
app/
  project.yml                 XcodeGen project definition
  Puggle/
    App/PuggleApp.swift       App entry, tabs, accepting invitations
    Data/Model.swift          Core Data model, built in code (Family, Child, Event)
    Data/Persistence.swift    CloudKit stores and sharing
    Data/FamilyStore.swift    All writes: add child, log, sleep timer
    Design/Theme.swift        Palette, pill buttons, chips, avatars
    Design/PuggleView.swift   Animated Puggle (Rive), still image without it; see design/rive/README.md
    Features/Today/           Today screen
    Features/Log/             Log sheet
    (PuggleWidgets/ and Shared/ sit beside Puggle/: the Lock Screen timers)
    Features/History/         History
    Features/Family/          Children and sharing
    Features/Growing/         Milestones, growth, summary for the doctor
    Resources/                Info.plist, entitlements, assets
```

## Next

See `docs/HANDOFF.md` for the current list, and `docs/testflight.md` for sending a build to TestFlight.
