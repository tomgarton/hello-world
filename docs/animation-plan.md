# Puggle and friends: line style and animation plan

Written 12 November 2026. Nothing here is built yet.

## Where things stand

- Puggle is one vector drawing (`design/rive/puggle-parts.svg`) with named parts:
  tail, legs, upper, dress, arm-left, arm-right, head, bill, eyes, blush.
- The app shows her as a still image. Her "animation" is the whole picture
  tilting, squashing and hopping. No part moves on its own, which is why she
  feels stiff.
- A Rive contract exists (`design/rive/README.md`) listing her moods and
  inputs. The Rive file was never made, and the Rive runtime is not in the app.
- The friends (bird, crab, snail, butterfly, kookaburra) are drawn in code and
  do not move after they pop in.

## Line style

What the two references do:

- **Miffy:** one heavy black line of even weight round everything, flat
  colours, very few features. Reads at any size. Can feel stark.
- **Bluey:** a thinner line, and each line is a darker shade of the colour it
  goes round (blue fur has a deeper blue line, the tan muzzle an ochre one).
  Black is kept for pupils, nose and mouth. Some inside shapes, like the belly,
  have no line at all. Backgrounds have no lines: flat shapes, each with one
  lighter shape on top for volume, and a soft shadow under the feet.

Recommendation: **Miffy's weight, Bluey's colour.**

- Keep the bold, even line. Puggle is about 120 points tall and the friends
  about 40. A thin television line would break up at that size.
- Colour each line as a darker shade of its own fill. Keep the dark brown only
  for eyes, nostrils and mouths.
- Inside shapes (blush, belly, wing patches) get no line.
- Scenery stays without lines. Each cloud, tree and hill gets one lighter
  shape for volume.

Why:

- Puggle is already half way there: her dress has a blue line and her flower
  a red one. Her bill and the friends are the odd ones out.
- After dark, a dark brown line disappears into the dark ground. A coloured
  line keeps its shape.
- It is softer, which suits a calm app, and it keeps her her own character
  rather than a copy of either reference.

Keep the dark line for the app icon and the small mark, where contrast matters
more than softness. Check both at small sizes before changing them.

## Animation: the choices

| Choice | Good at | Weak at | Who makes it |
|---|---|---|---|
| **Rive** | Characters that react: moods, blending, eyes following a finger. Small files, very smooth. | Has to be built by hand in Rive's editor. Exporting for an app needs a paid plan. | A person, in the editor. Claude cannot make Rive files. |
| **Lottie** | One-off films: a splash, a celebration. | Reacting to the app. Needs After Effects or a similar tool. | A person, in After Effects. |
| **A rig in code** (SwiftUI) | Reacting to the app, exact control, nothing to install, easy to test. | Bending and stretching soft shapes takes more work than in Rive. | Claude, from the parts file we already have. |
| **Drawn frames** | The hand-made look of real cartoons. | Every pose is a new drawing. Large files. Cannot react. | An illustrator. |

Recommendation: **build the rig in code now, and keep Rive as a later upgrade.**

The deciding point is who can make it. A Rive or Lottie file needs hours of
hand work in an editor, and the contract has been waiting on that. A code rig
can be built and checked straight away from the parts file, and it uses the
same contract. If a Rive file is made later, it drops into the same place and
the code rig becomes the fallback.

## How the rig works

1. **Parts.** Each named part becomes its own layer with a pivot: tail at its
   base, arms at the shoulders, head at the neck, legs at the hips.
2. **Poses.** A pose is a small set of numbers: each part's angle and shift,
   plus eye and bill shapes. Idle, wave, hooray, nod, proud, sleepy, walk.
3. **Moving between poses.** Reactions snap pose to pose and hold (as decided
   on 11 November). Ambient motion eases.
4. **Layers of motion, added together:**
   - breathing (always, slow)
   - blinking (every few seconds, never in step)
   - eyes following a finger
   - the reaction on top
   - follow-through: tail, flower and arms arrive a beat late and settle
5. **The things that make it feel alive:** a small crouch before a jump,
   squash on landing, arms that travel in arcs, a hold at the top of a wave,
   and the tail showing the feeling.

## Steps

1. **Line style test.** Puggle and the five friends side by side in both line
   styles, by day and after dark. Pick one.
2. **Split Puggle into parts** in the app, drawn exactly as the still. Check
   against the still image so nothing shifts.
3. **Idle:** breathing, blinking, tail sway, eyes following a finger.
4. **Reactions,** one at a time, each checked as a strip of frames: nod, wave,
   proud, hooray, wake, sleepy, walk.
5. **Friends:** one small loop each. Bird hops and pecks, crab scuttles
   sideways, snail feelers wave, butterfly flutters, kookaburra tilts its head.
6. **Rules:** Reduce Motion shows the still. Night halves the energy. Nothing
   in the app ever waits for her.
7. **Later, if wanted:** rebuild in Rive for softer bends, using the same
   contract.

## How each step is checked

- A strip of frames for every reaction, like the scene sheets, so poses can be
  judged without running the app.
- A gallery in the Developer menu to play each reaction on demand.
- On the phone, for smoothness and battery.

## What is not known yet

- How much bend the bill and tail need. If a lot, that favours Rive.
- Whether the splash should use the same rig or stay as it is.
