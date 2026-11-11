# Puggle: handoff to the Mac

Written at the end of the cloud session on 2026-11-10, so work can carry on in Claude Code on Tom's Mac.

## Where everything is

| What | Where |
|---|---|
| Plan and spec (decisions, rules, open items) | `docs/baby-tracker-spec.md` |
| Flows and journeys (ten journeys, step by step, with rules and edge cases) | `docs/flows.md`; screens on the canvas page "Flows" |
| iOS app, v0.1 (never compiled) | `app/`, start with `app/README.md` |
| Design canvas (live) | https://claude.ai/artifact/7YuMrXnyazxos3Hnfr6uAd |
| Canvas sources (generator scripts and board files) | `design/canvas/`, see `design/canvas/README.md` |
| Rive contract (names, timings, order of work) | `design/rive/README.md` |
| Puggle's parts for Rive (named groups) | `design/rive/puggle-parts.svg` |
| App view that plays the Rive file | `app/Puggle/Design/PuggleView.swift` (not compiled yet; works without Rive) |
| Branch | `claude/baby-tracking-app-spec-fhtvex` |

## First job on the Mac: build v0.1

The app was written without a Mac. Expect a handful of small compile fixes.

1. `brew install xcodegen`
2. `cd app && xcodegen`, then open `Puggle.xcodeproj`
3. Change the placeholder bundle ID and iCloud container (three places, listed in `app/README.md`)
4. Pick a team in Signing & Capabilities, build, fix errors, run on a phone

Sync and sharing use CloudKit, which needs a paid Apple Developer account. Without one, the quickest way to see the app run is to make the store local-only for now (swap `NSPersistentCloudKitContainer` for `NSPersistentContainer` and drop the shared store in `app/Puggle/Data/Persistence.swift`), then put CloudKit back once the account exists.

A good first prompt for Claude Code on the Mac:

> Read docs/HANDOFF.md and app/README.md. Generate the Xcode project, build the Puggle app for the simulator, and fix compile errors until it runs. Tell me before changing how sync works.

## After it builds (v0.2, from the spec)

1. Live Activity and Lock Screen timer for sleep
2. Home Screen widgets
3. The Puggle activity icons as custom SF Symbols (drawings in `design/canvas/gen/style.py`)
4. Today header scenes: Morning, Bedtime, Celebration (`design/canvas/gen/three.py`)
5. Potty sticker chart, including the holographic stickers
6. Onboarding and the splash screen

## Design state at handoff

Settled and on the canvas:

- Puggle's refreshed face and legs, with small-size versions for the whole young cast
- Activity icons: line with colour by activity; sticker, holographic and print finishes
- Twelve scenes in the flat, lit style, with a kit of parts; three of them shown as Today headers
- Wallpapers (eight) and book covers built from the scenes

Motion: "Motion studies for Rive" on the Characters page shows five Puggle loops, the state machine and four animated scenes. They are sketches; the real files get built in the Rive editor.

Proposed, not yet decided (Characters page, "Puggle: three additions"):

- A patterned outfit (quatrefoil, gum leaf, wattle)
- A flat, no-outline Puggle
- A side-on walk (the roughest of the three; needs another pass)

Open decisions are listed at the top of the spec: Apple Developer account, Pebble's name, Pro price, potty method, Today as list or cards, trade mark checks.

## Rules worth remembering

- The app name appears only on the splash screen, the app icon and Help.
- Nothing Indigenous or with strong Indigenous meaning; no Sydney Opera House (trade mark); generic places only.
- Puggle's bill never changes with emotion. No mouth, no brows.
- References are for study. Nothing is copied from Miffy, Bluey, Nintendo or anyone else.
