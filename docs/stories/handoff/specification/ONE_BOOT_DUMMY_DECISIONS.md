# One Boot — physical dummy 01: editorial decisions and open questions

**Date:** 16 November 2026  
**Status:** First-pass *structural* dummy, not approved production layout, finished illustration, buildable USDZ, or native app.  
**Primary source:** `ONE_BOOT_MANUSCRIPT.md`, unchanged.  
**Related files:** `ONE_BOOT_SPREAD_PLAN.json`, `One_Boot_Interactive_Dummy.html`, `One_Boot_Storyboard_Review.pdf`.

## What we tested

1. **One story beat per opening** (11 physical openings). This is an editorial proposal. It avoids exposing the next narrative answer on a facing page; each of the seven search/reveal beats has one main flap. A real thick-board dummy is needed to validate total bulk and opening sequence.
2. **Question before lift, answer after lift.** The book leaves all author text intact. In the interactive dummy the reveal lines and refrain appear after the flap opens, standing in for text or art concealed in a physical flap book. In the eventual printed/3D layout they must be placed where a child can see/read them naturally, not mechanically pop in as an overlay unless deliberately chosen.
3. **Physical world continuity.** Home front step → log pile → hole → tree with creek in sight → Nan/Pop's garden → veranda hat → biscuit tin → wet path → creek basket → shared moment → splash.
4. **Seven flaps:** six raised-hinged (logs, leaves, towel, hat, tin lid, blanket) and one recessed hinged (dirt) with a finger notch. Actual hinge side, final shape and physical hinge relief need real composition tests.
5. **Quiet pages as key story beats:** opening 1 (premise), 8 (movement), 10 (Pebble and Puggle), 11 (ending). No gratuitous hotspots or loops.
6. **All 11 spreads use existing concept environment assets** as placeholders. Characters in the PDF and HTML were isolated by basic background keying from the creator's *existing cast sheet*, NOT redrawn or generated. These rough image crops are only placeholders; final art must use approved original source files.

## Editorial questions to evaluate in a family read-aloud

- Does the one-boot visual state read instantly? Current footwear props are **placeholder geometry** and need a clearly separate final asset compatible with the precise approved character construction.
- Is the repeated line placed where the adult can join in **without waiting for the child to complete a fiddly gesture**?
- Does the progression of companions appear across the later drawings, without visual overload from the accumulating cast?
- Is the transition into Nan and Pop's house legible without adding extra manuscript text?
- Are the Pebble and missing-boot positions on opening 9 obvious when the blanket lifts, but genuinely hidden beforehand?
- Is there enough room in opening 10 to read Puggle's "Mine" → "Ba" shift through the art while preserving her face rules?
- Does opening 11 communicate both boots off, a single splash and a quiet creek without fireworks or sentimental explanation?

## Trade-offs and recommendations

- **11 openings vs 7–9:** Eleven creates a calm, spacious story but a thicker real book. Keep it for first tests; then compare against a condensed 8-opening dummy. Never merge openings 9 and 10 if that gives away the boot or makes the sibling exchange too fast.
- **One flap per opening:** Useful for the initial reading experience, not a law for every future Puggle book. If a later story benefits from a two-flap spread, test it rather than rejecting it on principle.
- **Read-together default:** Keep narration off by default and adult in control of the page. The HTML dummy uses text visible/hidden on action only to test pacing; do not claim this is optimal comprehension design without family tests.
- **Page geometry:** Working dimensions below are model benchmarks rather than measured existing books. Validate in a physical paper/card mock-up before fixing the native camera and meshes.

## Provisional book-object model

| Parameter | Working starting value | Status |
|---|---:|---|
| Page face | 175 × 175 mm | Provisional |
| Board core | 2.0 mm per leaf | Provisional |
| Corner radius | 6 mm | Provisional |
| Flap thickness | 1.0–1.5 mm | Provisional |
| Recess depth | ~1 mm (cutout + backing art) | Provisional |
| Finger notch diameter | ~14 mm (visible semicircle) | Provisional |
| Spine | Derived from actual leaf count and hinge allowance, not a fixed number | Open |
| Default page pose | Double spread, front-facing, camera at slight overhead angle | Proposal |
| Material response | Matte board plus faint laminating sheen; tilt affects light only | Proposal |

## Approval gates

1. **Story pacing:** agree whether 11 openings feels right after reading the PDF/HTML with a child.
2. **Visual direction:** confirm exterior architecture, Nan/Pop's green roof, creek crossing and garden path; concept images have not been canonised.
3. **Artwork masters:** supply/export separate approved, clean Puggle and cast art layers (character silhouettes, clothing and bill must not be regenerated).
4. **Production geometry:** approve representative flap geometry for log + recessed earth patch + basket blanket.
5. **Native development:** build a minimal RealityKit spread and a *single* reusable flap component; only then implement other pages or tvOS behaviours.

## Handoff hazards

- Do **not** treat the 3D rendering shown in the interactive HTML as RealityKit. It is a simplified **CSS/SVG interactive dummy** and pointer-controlled sheen simulation.
- Do **not** treat any scene or cutout in this pack as a clean final vector. Concept images are raster studies.
- Do **not** move the author's words, invent dialogue, or automatically rewrite the manuscript to match a layout.
- Do **not** assume the front-of-book or inside-cover printing imposition is solved by the 11-opening plan.
