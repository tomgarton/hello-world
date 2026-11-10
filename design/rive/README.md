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

If `asleep` is true, `greet` and `celebrate` are ignored (she stays asleep).

**Layers**

1. Body: Idle, Wave, Hooray, Sleepy, Walk
2. Blink: runs all the time over layer 1, except in Sleepy (eyes are closed)

**Timelines**

Timings come from the motion studies on the canvas ("Motion studies for Rive", Characters page; source `design/canvas/gen/motion.py`). Treat them as a starting point.

| Timeline | Length | Loops | What happens |
|---|---|---|---|
| `Idle` | 3.2 s | yes | Head sinks 2 px and returns (breath). Arms swing about 3° at the shoulder. Tail rotates between -4° and 5° on a 2.4 s cycle |
| `Blink` | 4.2 s | yes | Eyes open for most of it; close and reopen over the last 0.4 s |
| `Wave` | 1.8 s | no | Right arm up, rotates 18° at the shoulder twice. Head tilts 3.5°. Eyes are happy arcs. Tail wags faster |
| `Hooray` | 1.3 s | no | Squash down 6 px, jump 30 px, land with a small squash, settle. Both arms up. Shadow shrinks at the top of the jump. Four quatrefoils pop around her at the peak |
| `Sleepy` | 5 s | yes | Eyes closed (downward arcs). Head nods forward 5° and holds, then lifts. Body breathes 3 px. Three small z's float up and fade, 0.9 s apart |
| `Walk` | 0.56 s | yes | Side view. Stride pose and passing pose, with a 5 px lift on passing. Arms swing opposite the legs |

**Transitions:** blend 0.15 to 0.25 s between states. Wave and Hooray exit to Idle when they finish. Sleepy blends in and out over 0.5 s.

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
