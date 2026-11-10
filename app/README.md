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

Not yet: Live Activities, widgets, the custom Puggle icons (SF Symbols stand in), characters, potty sticker chart, growth, onboarding, import.

## Build it on your Mac

1. Install XcodeGen: `brew install xcodegen`
2. Generate the project: `cd app && xcodegen` (creates `Puggle.xcodeproj`)
3. Open `Puggle.xcodeproj` in Xcode.
4. **Bundle ID and iCloud container.** `app.puggle.Puggle` and `iCloud.app.puggle.Puggle` are placeholders; bundle IDs are global, so pick your own (for example `com.<you>.puggle`) and change it in three places:
   - `project.yml` (`bundleIdPrefix` and `PRODUCT_BUNDLE_IDENTIFIER`), then re-run `xcodegen`
   - `Puggle/Resources/Puggle.entitlements`
   - `Puggle/Data/Persistence.swift` (`cloudKitContainerID`)
5. In the target's **Signing & Capabilities**, choose your team. Check that **iCloud → CloudKit** (with your container ticked), **Push Notifications** and **Background Modes → Remote notifications** are all present; Xcode creates the container in your developer account.
6. Run on your iPhone (or a simulator signed in to iCloud).

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
