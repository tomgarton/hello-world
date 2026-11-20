# Puggle: where things are

Updated 13 November 2026 by the cloud session, for the Claude Code session on Tom's Mac. Work happens in two places on the same branch: the Mac builds the app; the cloud session does design, flows and documents. Pull before starting; both push here.

## Pull first, and what the pull does

- **The build folder is no longer tracked.** `app/DerivedData-cloudsim` (5,024 files, about 295 MB) was committed by accident with the widgets commit. It is removed from the branch and already covered by `app/.gitignore`. **Pulling deletes that folder on the Mac.** It is only a build cache; pull when no build is running. If there are unpushed commits, pull (rebase) before pushing.
- The 295 MB is still in the branch's history. Squash-merging the pull request keeps it out of master.
- Before committing, check `git status` for build output. Build into a folder the ignore file covers.

## What the cloud session did on 13 November

1. **Recorded Tom's three decisions of 12 November** (he confirmed them): coloured outlines, eyebrows only with a feeling, and the new face (eyes, oval cheeks, light blue pocket, webbed feet, tail markings). They are in the spec under "As built in the app", and the Rive contract and this file no longer say "no brows".
2. **Rebuilt the model sheet from the app's rig file,** so the canvas and the app match. `design/canvas/gen/rig.py` reads a copy of `puggle.rig.json`; `model2.py` draws the sheet. If the rig file changes, copy it to `design/canvas/gen/puggle.rig.json` and tell the cloud session.
3. **Rolled the new look across the canvas:** expressions, hands, family, cast line-up, glasses, scenes, wallpapers, books, onboarding and the refined screens. Not yet: flows, motion studies, logos, icon and sticker boards.
4. **Compared the app with the flows,** journey by journey, from the code. Result: `docs/app-vs-flows.md`. Read that next.

## For the Mac session to do

In this order. Details and file references are in `docs/app-vs-flows.md`.

**Check first (possible faults, read from code, not tested)**

1. "Delete everything" deletes every family the phone can see (`Data/FamilyStore.swift:410`). Confirm an invited person cannot wipe a shared family; if they can, limit it to the family they own.
2. A new child's birth date defaults to six months ago (`Features/Family/ChildForm.swift:6`). Make the parent choose it.
3. Widget buttons log with no Undo for a stray tap.

**Ideas from the flows that were lost.** Tom has not yet chosen which to bring back; the cloud session's suggested first three are marked. Ask him before building.

- People and roles: a list of who is in the family, change or end access *(suggested first)*
- A join screen, and plain words when joining fails *(suggested first)*
- Medicine rules shared across the family, not kept on one phone *(suggested first)*
- Helper mode (journey 13): nothing built
- Night wakings added or fixed afterwards
- Insights for more than one child at once
- "Just logging" respected by widgets; medicine "Due" kept in that mode
- Finding support in Help
- Log sheets at the largest text (list rows, no segmented controls); chart text sizes
- Two taps deep for solids, weight, health and past sleep; Undo that survives a restart
- "Growing up" as a suggestion the parent accepts, not a silent switch
- Characters or a photo for each child
- The newborn row (side, start of last feed, last 24 hours)
- Growth beyond weight; WHO bands; birth weight
- Import from another tracker
- Offline and iCloud-full notes where logging happens
- Pro and tips (no StoreKit code yet)

**Small slips against the flows**

- Today's empty state says "Nothing logged yet today", which the flows ruled out.
- The "dry days" sticker counts accident-free days; the rule is that an accident never takes anything away.
- Reminders use the default sound; the flows asked for quiet ones.

**Housekeeping**

- `app/README.md` is out of date: it says first run has no invite, and lists pumping, reminders, widgets and night mode as not built.
- `design/rive/puggle-parts.svg` is the old drawing. Either regenerate it from the rig file or delete it.

## Decisions waiting on Tom

- Which lost ideas to bring back, and in what order
- Friends (Quill, Kip, Digby, Sunny): plain oval cheeks like Puggle, or keep the stitches
- Logos and the app icon: keep the dark line (the animation plan says yes; check at small sizes)
- Renaming the repository from `hello-world` to `puggle`. Tom does this in GitHub's settings; afterwards run `git remote set-url origin https://github.com/tomgarton/puggle.git` on the Mac
- Still open from before: Apple Developer account, Pebble's name, Pro price and contents, potty method, trade mark checks, and the Tier 3 list in `docs/persona-testing.md`

## What the cloud session can do next

- Bring the flows on the canvas and `docs/flows.md` in line with the app, add the new features as journeys, and mark the lost ideas
- Finish the new look on the flows, motion studies and "three additions"
- Refresh the pull request description, which still describes 11 November

## Where everything is

| What | Where |
|---|---|
| Plan and spec (decisions, rules, launch checklist in §13) | `docs/baby-tracker-spec.md` |
| The app compared with the flows | `docs/app-vs-flows.md` |
| Flows and journeys as designed (seventeen) | `docs/flows.md`; screens on the canvas page "Flows" |
| Line style, night and animation plan | `docs/animation-plan.md` |
| Persona walkthroughs and open decisions | `docs/persona-testing.md` |
| Review of Apollo and other iOS apps | `docs/ios-craft-review.md` |
| iOS app | `app/`, start with `app/README.md` |
| Puggle as the app draws her (parts, faces, moves) | `app/Puggle/Resources/Rigs/puggle.rig.json`, played by `app/Puggle/Design/Rig.swift` |
| Design canvas (live) | https://claude.ai/artifact/7YuMrXnyazxos3Hnfr6uAd |
| Canvas sources | `design/canvas/`, see its README |
| Rive contract (names and inputs; the rig answers the same ones) | `design/rive/README.md` |
| Branch and pull request | `claude/baby-tracking-app-spec-fhtvex`, PR #2 |

## Rules worth remembering

- The app name appears only on the splash screen, the app icon and Help.
- Nothing Indigenous or with strong Indigenous meaning; no Sydney Opera House (trade mark); generic places only.
- Puggle's bill never changes with emotion. No mouth. Eyebrows only with a feeling: never at rest, never angry, sad or worried.
- Characters are outlined in a darker shade of each part's own colour. The world has no outlines.
- She is never sad or disappointed about what a parent did or did not log.
- The child's real name never appears in the repo or on the canvas.
- References are for study. Nothing is copied from Miffy, Bluey, Nintendo or anyone else.
