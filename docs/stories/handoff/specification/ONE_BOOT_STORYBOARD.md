# One Boot — environment + physical-flap storyboard v0.1

**Source:** author's original 11-section manuscript, copied verbatim in `ONE_BOOT_MANUSCRIPT.md`. This is **blocking**, not a rewrite. Story-section numbers are **not** necessarily physical page numbers.

| Beat | Proposed place | On-page setup / visible pre-reveal | Flap / after-reveal | Art continuity / editorial test |
|---|---|---|---|---|
| 1 | Front step, Puggle's house | Puggle front-facing in one boot, home/garden visible; one missing boot is the focus | None | House recognisable from app visual world; never depict two boots on |
| 2 | Log pile beyond garden | Logs prominent and clearly liftable; space for Quill to join | Raised log flap → one cone and Quill | Show companion entering journey; no invented dialogue |
| 3 | Digging patch, nearby path | Clearly bounded hole with earth patch | Recessed/flush die-cut earth flap with semicircular finger notch → flower and Digby | Depth of physical cutout; reveal doesn't require dexterous dragging |
| 4 | Tree near creek approach | Leaves obscure a small part of tree | Raised leaf-mass flap → a leaf and Kip | Show creek in distance, supporting Kip's line; avoid requiring profile of main characters |
| 5 | Nan and Pop's garden | Towel draped over line or low rail | Towel flap → bucket and Sunny | Sunny can join group; show scene transition through recognisable house architecture |
| 6 | By veranda / garden chair | Pop's hat clearly isolated | Hat flap → duck | Nan delivers line; no new speech for Pop unless authorised |
| 7 | Grandparents' table | Biscuit tin with recognisable lid | Lid flap → biscuit | Preserve “Two, at Nan's” ambiguity and charm; don't explain in narration |
| 8 | Wet path towards creek | Friends move past puddles; one booted foot makes the sound | None | Sound optional, rhythm in text should carry beat |
| 9 | Creekside picnic spot | Basket, blanket flap covering focal area | Blanket flap → Pebble (“Ba!”); stage boot to be discoverable | Biggest surprise; ensure reader understands physical whereabouts before beat 10 |
| 10 | Creekside, close emotional view | Puggle looks at boot, Pebble looks at Puggle | None | Text “Mine” then “Ba” should be readable through body language, without sermon |
| 11 | Creek edge | Puggle with both boots off, water calm | None | The quiet 'Splash' moment and the creek passing by; no confetti/game finish |

## Flap design rules

- A flap must provide the answer to its on-page question. No unrelated tappable objects.
- The child can **tap** the entire flap; optional drag lifts it physically. Hit area exceeds the decorative thumb notch.
- Two classes: `raised-hinged` (log, leaves, towel, hat, lid, blanket) and `recessed-hinged` (dirt), exact hinge side chosen per composition.
- Each flap has **closed artwork**, **underside artwork if needed**, **under-flap reveal artwork**, a **hinge transform**, and a **hit shape**. Don't bake reveal and flap together into one raster.
- Flap stays open until child closes it or turns the page; no automatic hurry.
- Strong, soft shadow under flaps; 3D board edges and cutouts are geometry, not illustrated fake shading.
- Open one meaningful flap at a time in the first prototype. With multiple flap assets later, ensure screen reader traversal order follows the story.

## Physical book architecture

- Prototype a thick board-book leaf with rounded corners, visible board edge and layered ink/lamination look.
- The narrator's text should be a **separate semantic text layer** for localisation, resizing and accessibility, not embedded in art.
- Do not freeze 11 story beats into 11 facing-page spreads. Begin with thumbnail dummy; test whether pairs can share spreads without spoiling reveals, and whether a child sees a future answer before lifting.
- Keep original opening/closing manuscript exact; a dummy can add wordless art/cover pages without adding dialogue.

## Critical tests with children/adults

1. Can a child point to the missing boot after beat 1?
2. Does every pre-reveal scene invite exactly the intended flap action?
3. Does the cast actually appear to join the search as it progresses?
4. Can a two-year-old understand where Pebble and the boot are at beat 9/10?
5. Does the last splash feel satisfying *without* extra explanation?
6. During screen reading, are adults talking about the story rather than operating the interface?
