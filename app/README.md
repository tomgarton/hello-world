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

The stickers are system symbols standing in for the Puggle sticker art. Not built in these journeys: regular medicines with reminders and "due on Today", the potty reminder, the holographic sticker art, milestones, the growth chart, and birth weight at setup.

Not built: the character builder and photos, invitations in first run, archiving a child, the doctor's PDF summary, import, Pro and tips, settings for night mode, units and reminders, a way to contact us from Help, and the "just log" mode. Whole journeys not started: helpers (13), twins' own amounts and pumping (14), large text and night (16), and widgets, Lock Screen and Siri (17).

Left out of those two journeys: the Lock Screen timer (needs a widget extension), the breastfeed timers, "how it went" for solids, a night waking inside a sleep, starting twins' sleep together, per-child amounts for "Both", and Puggle's nod on save.

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

### Optional: the brand font

Titles use Bricolage Grotesque when it's present. Download it from Google Fonts (Open Font License), add `BricolageGrotesque-ExtraBold.ttf` to `Puggle/Resources`, and add it to `Info.plist` under `UIAppFonts`. Until then, the system rounded font stands in.

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
    Features/History/         History
    Features/Family/          Children and sharing
    Resources/                Info.plist, entitlements, assets
```

## Next (v0.2)

1. Live Activity and Lock Screen timer for sleep
2. Home Screen widgets: last feed, asleep for
3. Custom Puggle activity icons as SF Symbols (from the icon sheet on the canvas)
4. Potty sticker chart for the toddler
5. Onboarding and the splash screen
