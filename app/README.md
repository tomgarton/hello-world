# Puggle iOS app (v0.1, household build)

The first working version of Puggle, for our own family: two children on one screen, quick logging, a shared history, and sharing with a partner through iCloud. See `docs/baby-tracker-spec.md` §11 step 3.

> **Status:** written in a cloud session without a Mac, so it has **not been compiled yet**. Expect a handful of small compile fixes on the first build. The quickest way through them is to open this repo in Claude Code on your Mac and ask it to build and fix.

## What's in v0.1

| Area | What it does |
|---|---|
| Today | Every child at once: who is asleep (live timer) and when they last fed. Cards for Bottle, Sleep, Nappy, Potty, Solids and Breastfeed showing the latest for each child, each with a + to log |
| Logging | One sheet for every activity. Pick one child, several, or Everyone. Bottle: volume, formula or breast milk. Nappy and potty: one tap saves. Sleep: start and stop from Today, or log a past nap |
| History | Everything, newest first, grouped by day, filter by activity, swipe to delete |
| Family | Add children (name, birth date, colour). Invite someone with Apple's sharing sheet |
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
