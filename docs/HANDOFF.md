# Puggle: where things are

Updated 11 November 2026. Work now happens in two places on the same branch: Claude Code on Tom's Mac builds the app, and the cloud session does design, flows and documents. Pull before starting; both push here.

## Where everything is

| What | Where |
|---|---|
| Plan and spec (decisions, rules, open items, App Store launch checklist in §13) | `docs/baby-tracker-spec.md` |
| Flows and journeys (seventeen journeys, step by step, with rules and edge cases) | `docs/flows.md`; screens on the canvas page "Flows" |
| Persona walkthroughs of the flows: findings, what has been applied, open decisions | `docs/persona-testing.md` |
| Review of Apollo and other well-crafted iOS apps | `docs/ios-craft-review.md` |
| iOS app, v0.1 | `app/`, start with `app/README.md` |
| Design canvas (live) | https://claude.ai/artifact/7YuMrXnyazxos3Hnfr6uAd |
| Canvas sources (generator scripts and board files) | `design/canvas/`, see `design/canvas/README.md` |
| Rive contract (names, timings, order of work) | `design/rive/README.md` |
| Puggle's parts for Rive (named groups) | `design/rive/puggle-parts.svg` |
| App view that plays the Rive file | `app/Puggle/Design/PuggleView.swift` |
| Branch and pull request | `claude/baby-tracking-app-spec-fhtvex`, PR #2 |

## State of the app

As reported in the Mac session's commits on 11 November 2026. The cloud session has not built or run the app.

- **It builds.** v0.1 built for the iOS simulator on the Mac with two small fixes to Today.
- **Two schemes.** **Puggle** uses CloudKit sync and sharing and needs a paid Apple Developer account. **Puggle Local** runs without iCloud on a free Apple ID: data stays on the phone and sharing is off. Steps for both are in `app/README.md`.
- **The bundle ID is real:** `com.tomgarton.puggle`, with a matching iCloud container.
- **Journeys 2 and 3 are built** (everyday logging and sleep): Last saved with Undo and Change, edit and delete, typed bottle amounts, logging earlier, the day so far, Start sleep with Cancel, and the "still asleep?" question. `app/README.md` lists each step and what was left out.

Not yet verified by anyone:

- Installing on a phone (both schemes build for the simulator only so far).
- CloudKit sync and sharing between two Apple Accounts.
- The Rive path in `PuggleView`. The file compiles and shows a placeholder; the Rive calls were written from memory and there is no `.riv` file yet.
- There are no automated tests.

## What to build next

In the order the flows suggest. Each journey in `docs/flows.md` lists its steps, rules and edge cases.

1. The rest of journeys 2 and 3: breastfeed timers and past-feed entry, per-child amounts for "Both", a night waking inside a sleep.
2. Journey 12, setup that fits the child: the two questions and a newborn's Today.
3. Journey 11, health: medicine, temperature, vaccinations.
4. Journey 4, potty: the sticker moment and chart.
5. Journey 16, large text, VoiceOver and night. Better done alongside each screen than at the end.
6. Journey 17, outside the app: Lock Screen timers and widgets (needs a widget extension).
7. Journeys 13 to 15: helpers, twins and pumping, calm and private.

Before any of the sharing journeys: a paid Apple Developer account, and a test with two phones.

## From the original v0.2 list

1. Live Activity and Lock Screen timer for sleep
2. Home Screen widgets
3. The Puggle activity icons as custom SF Symbols (drawings in `design/canvas/gen/style.py`)
4. Today header scenes: Morning, Bedtime, Celebration (`design/canvas/gen/three.py`)
5. Potty sticker chart, including the holographic stickers
6. Onboarding and the splash screen

## Design state

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

Open decisions are listed at the top of the spec: Apple Developer account, Pebble's name, Pro price, potty method, Today as list or cards, trade mark checks. The persona walkthroughs added seven more (Tier 3 in `docs/persona-testing.md`): helpers without an iPhone, how deep Insights goes, what Pro contains, premature babies, twins side by side, day care, and ownership.

## Rules worth remembering

- The app name appears only on the splash screen, the app icon and Help.
- Nothing Indigenous or with strong Indigenous meaning; no Sydney Opera House (trade mark); generic places only.
- Puggle's bill never changes with emotion. No mouth, no brows.
- References are for study. Nothing is copied from Miffy, Bluey, Nintendo or anyone else.
