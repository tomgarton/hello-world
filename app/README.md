# Puggle iOS app (v0.1, household build)

The first working version of Puggle, for our own family: two children on one screen, quick logging, a shared history, and sharing with a partner through iCloud. See `docs/baby-tracker-spec.md` §11 step 3.

> **Status:** builds for the iOS simulator (first built on a Mac on 11 November 2026). Not yet installed on a phone, and CloudKit sync and sharing have not been tested between two Apple Accounts. There are no automated tests.

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
| First run (1) | Splash with the name, two skippable hello screens, add your first child, "Anyone else?", then Today. No character step or invite yet |
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

Stars stand in for the quatrefoils and shiny sticker in the celebration. Not built in these journeys: milestone photos, suggested milestones by country, WHO percentile bands, units other than grams and millilitres, pumping and milk on hand.

The stickers are system symbols standing in for the Puggle sticker art. Not built in these journeys: regular medicines with reminders and "due on Today", the potty reminder, the holographic sticker art, and birth weight at setup.

Not built: the character builder and photos, invitations in first run, import, Pro and tips, automatic night mode, units and reminders, a way to contact us from Help, and "how much to see" in setup. Whole journeys not started: helpers (13), pumping (14), large text and night (16), and widgets, Lock Screen and Siri (17).

Left out of those two journeys: "how it went" for solids, a night waking inside a sleep, starting twins' sleep together, and Puggle's nod on save.

Not yet: Live Activities, widgets, the custom Puggle icons (SF Symbols stand in), characters, potty sticker chart, growth, onboarding, import.

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

### Running on a phone with a free Apple ID

A free Apple ID cannot sign the iCloud and push entitlements, so use the **Puggle Local** scheme. It builds the `Local` configuration: no entitlements, and `LOCAL_ONLY` set, which makes `Persistence.cloudSyncEnabled` false. Data stays on the phone, the Family tab says sharing is off, and the app needs reinstalling every 7 days.

1. Xcode → Settings → Accounts: add your Apple ID.
2. Plug in the iPhone, tap Trust, and turn on Settings → Privacy & Security → Developer Mode.
3. Choose the **Puggle Local** scheme and your iPhone, pick your personal team in Signing & Capabilities, and Run.
4. First launch: on the phone, Settings → General → VPN & Device Management, trust your developer certificate.

The CloudKit code is untouched. Installing a build from the **Puggle** scheme over the top (paid account) should turn sync on for the same local data; this has not been tested.

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

## Next (v0.2)

1. Live Activity and Lock Screen timer for sleep
2. Home Screen widgets: last feed, asleep for
3. Custom Puggle activity icons as SF Symbols (from the icon sheet on the canvas)
4. Potty sticker chart for the toddler
5. Onboarding and the splash screen
