# Puggle: handoff, 19 November 2026

Written from the transcript of the Remote Control session "Baby tracking app spec", which runs on Tom's Mac. That Mac went offline at about 04:18 UTC on 19 November. This note is for whichever session picks the work up next.

## Where the code is

- **Repository:** `tomgarton/hello-world` (the repo was never renamed to `puggle`).
- **Branch:** `claude/baby-tracking-app-spec-fhtvex` (PR #2). The app is in `app/`; the docs are in `docs/`.
- **On the Mac:** `~/Desktop/Claude Code/hello-world`.
- **On GitHub:** the branch ends at `4be0423` ("Special days: New Year's Eve, Bonfire Night…"), pushed 18 November at 08:03 UTC.

### Seven commits exist only on the Mac

The session's last message said "five commits are waiting". Counting from the transcript, there are seven, because the first two were made after the last push.

| Commit | What it holds |
|---|---|
| `abef6a9` | Spec note recording the TestFlight upload of 18 November |
| `6263eba` | Speed pass, and the "held" animation when Puggle is carried |
| `3504179` | Entrance animation, tea with the family, bedtime following the children, sleepovers |
| `aeccd5f` | Sleep button offered for any child under four during the day |
| `3c3b8dd` | Ages written as "2½y", to match "6mo" and "2y" |
| `5e44f05` | Lines under a child's three facts start with their activity's icon |
| `90bd2d0` | Potty box with a nappy line, and a sheet with Nappy and Potty rows |

At the last check on the Mac, 138 tests passed. Until these are pushed, no other machine can carry this work on. **Building from GitHub now would leave all of this out.**

## TestFlight and release setup

It's set up and has worked many times.

- **Builds uploaded:** builds 1 to 16 of version 0.1.0. The last upload was on 18 November (probably build 16) and holds care tracking, the night sky by hemisphere, special days, cloudy nights, rain and the One Boot book. **Nothing from 19 November has been uploaded.**
- **Testers:** Tom and Clara.
- **How to upload:** from `app/`, run `zsh tools/testflight.sh`. It archives a Release build and uploads it. `--archive-only` stops before the upload. The Mac session ran it from a detached git worktree in its scratchpad, after running `xcodegen generate` there, in the background (about 10 minutes).
- **Signing:** automatic, team `X2UM64LDU4`, with `-allowProvisioningUpdates`. It uses the Apple ID signed in to Xcode. `app/ExportOptions.plist` has method `app-store-connect`, destination `upload`, and `manageAppVersionAndBuildNumber` set to true.
- **Build numbers:** App Store Connect assigns them, so two Macs won't collide. `project.yml` keeps `CURRENT_PROJECT_VERSION: "1"`.
- **Bundle IDs:** `com.tomgarton.puggle`, `.widgets`, `.tests` and `.uitests`.
- **CloudKit:** deploy the schema in the CloudKit Console only when a build adds synced fields. None of the 19 November work was flagged as adding any. Check before uploading anyway.
- **Apple's warning:** from April 2027, uploads must be built with Xcode 27 (iOS 27 SDK).
- **Xcode Cloud:** not set up.

### To build from a second Mac

1. Push the seven commits from the first Mac, then clone the branch on the second Mac.
2. Sign in to Xcode on the second Mac with the Apple ID on team X2UM64LDU4. Keep automatic signing.
3. Install XcodeGen. The first Mac used `~/.local/xcodegen-dl/xcodegen/bin/xcodegen`. Run `xcodegen generate` in `app/`, because `Puggle.xcodeproj` is generated and not in git.
4. Run `zsh tools/testflight.sh --archive-only` once to check signing, then a real upload when Tom says yes.

## Tom's standing rules

- **Every push, phone install and TestFlight upload needs a fresh, explicit yes.** One yes covers one push or upload. Uploads go to Apple and can't be deleted.
- Keep every unchosen variant or option.
- Use the sample family only: Bea (2½), Ollie (5 months), Alex, Robin, Nan and Kit. Never use the real children's names in mock-ups, the repo or the canvas.
- Never save Tom's own screenshots into the repo. They show his name, email and contacts.
- Copy follows `docs/writing-guide.md`:
  - plain words
  - no "we" or "us"
  - no "should"
  - no em dashes
  - buttons start with a verb
  - facts joined by interpuncts
  - never "overdue" and never nagging
- Never put Tom's personal details in requests to outside services. Tom enters any token or password himself.
- Tom likes being asked and deciding. Open questions go under "Questions for Tom" in `docs/baby-tracker-spec.md`, and parked work goes under "Backlog".
- Tom works from his phone over Remote Control. Send pictures of changes, and end each reply with only the one question needed.
- Hold the ChatGPT brief, the reference pages and the screens PDF until the design has settled.

## What was done on 19 November (only on the Mac)

1. **Speed pass:** the wallpaper is drawn in one layer, rig paths and drawings are cached, a Today scroll no longer rebuilds the page, and the care card makes one pass per child. Dragging Puggle no longer rebuilds the scene. The sample family saves once, so it opens in about 6 seconds instead of 15.
2. **Carrying Puggle:** a new "held" move with arms up, kicking legs and a swinging tail. She sways behind the finger, and on landing gives a squash, a wag and a haptic tap. When the children are asleep she stays asleep, and with Reduce Motion on she moves along the ground without lifting.
3. **Entrance:** it has weight, the characters arrive staggered, and each comes from its own side. Outdoors she mostly rises from behind the hill. Indoors she walks in from the door's side. The full entrance plays only on the first visit of the day.
4. **Evenings:** tea with Mum and Dad, sometimes with Nan and Pop, and with the friend on sleepover nights. Bedtime follows the children's logged sleep. Without logs it follows age: 19:00 for babies, 19:15 for toddlers, 19:45 up to six, otherwise 20:00, with reading in bed for 30 minutes before. She sits up sleepily when a night feed or nappy is logged. About one night in five is a sleepover with a sleeping bag, and a grown-up sits in the armchair. New file `Design/Evening.swift`.
5. **Sleep button:** shown in the day for any child under four. It used to show only under 18 months.
6. **"2½y"** age labels.
7. **Fact lines** start with an icon.
8. **Potty and nappy together:** for a child learning the potty who still wears nappies, the Potty box shows the time since the last nappy too. Its sheet has a Nappy row (Wet, Dirty, Dry) above the Potty row (Wee, Poo, Tried, Accident), and Save becomes "Save both" when both rows are picked.

None of it has been tried on a phone. It was checked in the simulator, in renders and by tests.

## Waiting on Tom

- **Push the seven commits and upload a TestFlight build?** This was the last question asked.
- The potty and nappy design: Tom chose option B but said it "needs more work". Box 3 and Sheet 2 were built for him to try and react to.
- Still open under "Questions for Tom" in the spec:
  - Imported entries on Clara's phone
  - The Kendamil tin reading
  - The weather line on an empty day
  - How a tile's icon looks on save
  - The per-child setting for actions under the plus
- Special days left open:
  - Puggle's costume
  - The friends joining in
  - Starting days early
  - Christmas on the beach in the southern hemisphere
- Older decisions in `docs/HANDOFF.md`, last updated 13 November and partly out of date:
  - Which lost flow ideas to bring back
  - The friends' cheeks
  - The logo's dark line
  - Renaming the repository

## Useful references

- Spec, decisions and dated build notes: `docs/baby-tracker-spec.md`
- App readme: `app/README.md`. The older handoff, `docs/HANDOFF.md`, dates from 13 November.
- Build for the simulator, from `app/`:

  ```bash
  xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData build
  ```

- Tests, from `app/`:

  ```bash
  xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData test
  ```

- Launch arguments for checking scenes:
  - `-uitest 1` loads the sample family.
  - Time and place: `-debugHour`, `-debugMinute`, `-debugRoom`, `-debugDay`, `-debugSouth`, `-debugWeather`.
  - Evenings: `-debugBed reading|asleep|stirring|up`, `-debugSleepover <friend>`, `-debugTea <who>`.
- Scratch renders use a temporary `PuggleTests/ScratchRender.swift`. Never commit it. Delete it and re-run XcodeGen afterwards.
- Commits are staged by path and end with a `Co-Authored-By` trailer.
