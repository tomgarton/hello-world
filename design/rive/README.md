# Rive contract

The agreement between the Rive file (built by Tom in the Rive editor) and the app code (`app/Puggle/Design/PuggleView.swift`). If the names here match on both sides, either side can change freely.

Names are case-sensitive. Change one here first, then in the file and the code.

## Files

| File | What | Where it goes |
|---|---|---|
| `puggle-parts.svg` | Puggle's parts with named groups, for import into Rive | this folder |
| `puggle.riv` | The exported character file | `app/Puggle/Resources/puggle.riv` |
| `scenes.riv` | The exported scenes file (later) | `app/Puggle/Resources/scenes.riv` |

Keep a link to the Rive editor file in this README once it exists, so the source is not only on one machine.

## Character file: `puggle.riv`

**Artboard:** `Puggle`, 240 × 300, transparent background. Feet on the bottom edge, centred.

**State machine:** `Mood`

| Input | Type | Set by the app when | Behaviour |
|---|---|---|---|
| `greet` | Trigger | The app opens; the splash screen | Plays Wave once, returns to Idle |
| `celebrate` | Trigger | A log is saved; a milestone is added | Plays Hooray once, returns to Idle |
| `asleep` | Boolean | A sleep timer is running for the child shown, or it is night | True: go to Sleepy and stay. False: back to Idle |
| `walking` | Boolean | Pull to refresh is in progress | True: Walk loop. False: back to Idle |

| `nod` | Trigger | An everyday log is saved (bottle, nappy, solids) | One small happy bounce, 0.4 s |
| `proud` | Trigger | A potty success | Ta-da, tail straight up, 1.5 s |
| `wake` | Trigger | A sleep ends | Stretch and wake, 1.2 s, then Idle |
| `energy` | Number, 0 to 1 | The app sets 1 by day and 0.5 at night (about 10 pm to 6 am) | Scales how big and fast reactions are. Below 1 there are no jumps |
| `lookX`, `lookY` | Number, -1 to 1 | A finger is on or near her | Her eyes shift up to 5 px towards it. Back to 0 when the finger lifts |

If `asleep` is true, every trigger except `wake` is ignored (she stays asleep).

`celebrate` is now only for milestones; everyday logs use `nod`.

## Reaction rules (canvas: "Motion direction")

- **Never in the way.** Nothing in the app waits for an animation.
- **No guilt.** She is never sad, worried or disappointed about what a parent did or did not log. There is no input for it, on purpose.
- **Quiet at night.** `energy` drops; idle becomes Sleepy while a child is asleep.
- **Silent by default.** Sound only if switched on; a soft haptic when she lands.
- **One thing at a time.** While she reacts, the scene's ambient loops pause.

## Timing: snappy for reactions, smooth for ambient

Reactions (Wave, Hooray, nod, proud) are pose-to-pose: hold each pose, move to the next in about 0.05 to 0.1 s. Breathing, sleeping and scene loops ease all the way. Tom to confirm after watching both on the canvas.

## The tail shows the feeling

| Feeling | Tail |
|---|---|
| Calm | Resting, slightly raised (the default) |
| Happy | Up and wagging |
| Proud | Straight up |
| Surprised | Stiff, straight out |
| Sad | Drooping to the ground (her own stories only) |
| Shy | Tucked close, half hidden |
| Sleepy | Curled around her feet |

## Acting view and toddler moves

Reactions are staged in the three-quarter view where possible. Key poses to build towards: **potty dance** (knees together, hands at the front of her dress, tail stiff), **flop-sit** (bottom lands, legs out, arms up), **tippy-toe reach** (on her toes, one arm stretched, tail as counterweight).

**Layers**

1. Body: Idle, Wave, Hooray, FallAsleep, Sleepy, Walk
2. Blink: runs all the time over layer 1, except in FallAsleep and Sleepy

**Motion principles** (what makes it feel alive; keep them when rebuilding)

- Anticipation: a small move the other way first.
- Squash and stretch: about the feet, volume roughly constant.
- Follow-through: tail, clip and head start and stop a beat after the body.
- Idle is not a pure loop: rare one-off moments on a longer cycle.

**Timelines**

Timings come from the motion studies on the canvas ("Motion studies for Rive", Characters page; source `design/canvas/gen/motion.py`). Treat them as a starting point.

| Timeline | Length | Loops | What happens |
|---|---|---|---|
| `Idle` | 3.6 s breath, inside a 7.2 s cycle | yes | Head sinks 2 px and returns (breath); the body follows 0.15 s earlier, the clip 0.3 s later. Arms swing about 3°. Tail drifts between -4° and 5°. Once per 7.2 s: the eyes glance 5 px to one side for a second, and the tail flicks to 12° and back |
| `Blink` | 4.2 s | yes | Eyes open for most of it; close and reopen over the last 0.4 s |
| `Wave` | 2.6 s | no | Starts with the arm down. It dips 9° the wrong way (anticipation), swings up 82°, waves twice (82° to 64°), and returns with a 4° overshoot. Head tilts up to 4.5°, starting 0.08 s after the arm. Tail wags 0.12 s late. Clip wobbles 0.14 s late. Eyes are happy arcs |
| `Hooray` | 1.8 s | no | Crouch (wider 110%, shorter 86%, about the feet). Jump 38 px, stretched (93% wide, 110% tall). Land, squash (112% by 84%), recover with a small overshoot, settle. Arms dip in the crouch and fling up. Tail lags by 0.07 s, head by 0.05 s, clip by 0.1 s. Shadow widens in the crouch and shrinks at the peak. Four quatrefoils pop at the peak |
| `FallAsleep` | 7 s | no | The transition into Sleepy. Eyes droop, reopen, droop further, reopen less, then close. The head nods 4°, 7°, then 9° and stays. Arms hang lower. Z's begin once the eyes are shut |
| `Sleepy` | 5 s | yes | Eyes closed (downward arcs). Head stays nodded and rises 1° with each breath. Body breathes 3 px. Three small z's float up and fade, 0.9 s apart |
| `Walk` | 0.6 s a step | yes | Side view, four keys a step: **Contact** (legs and arms widest, body level), **Down** (weight lands, body 5 px lower, tail drops), **Passing** (free leg passes, arms cross, body 2 px up), **Up** (push off, body 7 px up, tail lifts). The head takes the body's height from the key before, so it arrives late |

**Transitions:** blend 0.15 to 0.25 s between states. Wave and Hooray exit to Idle when they finish. `asleep` turning true plays FallAsleep, then loops Sleepy; turning false blends back to Idle over 0.5 s.

**Rules that hold in every state**

- The bill never moves, opens, tilts or changes shape. No mouth, no brows.
- Emotion is eyes (dots, happy arcs, sleepy arcs), floating marks and body.
- The quatrefoil clip stays on her head, top right as we see her.

## Scenes file: `scenes.riv` (later)

One artboard per scene, each 390 × 300, with the character nested as a component so she is the same Puggle everywhere.

| Artboard | Ambient loops | Cast |
|---|---|---|
| `Morning` | Sun rises and settles (14 s), glow pulses (5 s), washing sways (4 s), magpie bobs (0.9 s), dew twinkles (2.6 s) | Puggle stretching, Pebble |
| `Bedtime` | Stars twinkle out of step (2 to 5.5 s), moon halo pulses (6 s), lamp flickers (3.4 s), shooting star every 9 s | Puggle under the lamp |
| `Celebration` | Confetti falls without a seam (7 s), balloons bob (2.6 to 3.8 s), big quatrefoil pulses (2.4 s) | Puggle, Quill, Kip |
| `Rainy` | Rain loops (0.5 s), rings spread on the puddle (1.6 s) | Puggle jumping |

Each scene artboard has a state machine called `Ambient` with no inputs to begin with. The app picks the artboard by name.

## App side

- `PuggleView` loads `puggle.riv`, artboard `Puggle`, state machine `Mood`, and offers `greet()`, `celebrate()`, `asleep` and `walking`.
- With Reduce Motion on, or if the file is missing, it shows the still image `PuggleStill` from the asset catalogue.
- Widgets and Live Activities use still images; Rive does not run there.

### Turning Rive on in the project

The view compiles without Rive and shows the still image. To switch Rive on, add the runtime to `app/project.yml` and re-run `xcodegen`:

```yaml
packages:
  RiveRuntime:
    url: https://github.com/rive-app/rive-ios
    from: "6.0.0"        # check the current release first
targets:
  Puggle:
    dependencies:
      - package: RiveRuntime
```

Then add `puggle.riv` to `app/Puggle/Resources/`.

## Order of work

1. Idle and Blink only. Export, add to the app, see it on a phone.
2. Wave and Hooray, with the two triggers.
3. Sleepy and the `asleep` input.
4. Walk.
5. Scenes.
