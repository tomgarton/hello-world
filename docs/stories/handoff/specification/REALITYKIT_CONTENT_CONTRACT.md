# Puggle native lift-the-flap book — initial content/engine contract

**Status:** Engineering proposal; verify with the installed iPadOS/tvOS SDK before implementation. Not a statement that this code already exists.

## Separation of concerns

**Book content package** (per title): manifest, story text and localisation, 11 story openings, art-layer references and approved character assets, structured flap descriptors, optional sound design, accessibility labels.

**Book renderer** (shared): board pages and spine geometry, camera, material models, animation timelines, ray-cast hit areas, page-state navigation, input reconciliation, accessibility and platform bridge.

**Platform-specific input**: iPadOS touch and optional filtered device-attitude illumination; tvOS focus/remote activation. Never make gyroscope movement necessary to reveal an answer.

## Proposed data model (sketch)

```json
{
  "bookId": "puggle.one-boot",
  "locale": "en-GB",
  "manuscript": "ONE_BOOT_MANUSCRIPT.md",
  "openings": [
    {
      "id": "opening-03-hole",
      "storyBeat": 3,
      "sceneId": "garden-hole",
      "textPre": "Is it down the hole?",
      "textPost": ["No boot. A flower! And Digby.", "\"Me too!\" says Digby.", "One boot on. One boot gone."],
      "flap": {
        "id": "earth-01",
        "type": "recessed-hinged",
        "hingeEdge": "TBD_BY_ART",
        "closedFace": "TBD/earth-face.png",
        "undersideFace": "TBD/earth-underside.png",
        "revealFace": "TBD/digby-flower.png",
        "dieCutMask": "TBD/earth-cutout.svg",
        "thumbNotch": "TBD/earth-notch.svg",
        "targetArea": "full-flap-mesh-plus-margin",
        "reducedMotion": "instant-open-pose"
      }
    }
  ]
}
```

`textPre`, `textPost` above demonstrate how to model exact author text in data; use the full source manuscript and `ONE_BOOT_SPREAD_PLAN.json` for all 11 openings, preserving punctuation.

## Component/state model

```
BookState: closed | opening | reading(openingId) | turning | closing
FlapState: closed | opening | open | closing
FlapType: raised-hinged | recessed-hinged
InputIntent: openFlap(id) | closeFlap(id) | nextOpening | previousOpening
```

- State changes should be deterministic and interruptible without mesh snapping or doubled animations.
- A flap tap/click must not also trigger a page turn (event/gesture ownership).
- A page turn returns flaps to a defined canonical pose; reopened pages should be predictable.
- Every major scene is comprehensible without sound, excessive motion or a successful drag gesture.
- Text is stored and rendered semantically, not baked into printed textures, to support dynamic type and assistive technology. A screen-reader reveal should be announced once when triggered.
- No analytics, outbound links or advertising in the child-facing story. Parent controls outside the reading surface.

## Art asset contract for a raised flap

1. `static_page_art`: background image behind all interactive geometry, without the flap or reveal characters baked into it.
2. `flap_closed_art`: printed face of the cardboard flap.
3. `flap_underside_art`: optional printed reverse face.
4. `reveal_art`: object/character visible under the flap. May be combined with a separated base layer for art direction, but not with the flap.
5. `flap_mesh_or_mask`: thickness, contour, real hinge strip, hit-testing region.
6. `transforms`: hinge origin, axis, open angle and ease curve authored per flap.

For recessed earth, add `aperture_mesh_or_cutout` and `thumb_notch` as real geometry. Printed fake shadows can be placeholders in the dummy but are not part of the final art pipeline.

## First physical/engine spike

A single sample page with two selectable flap fixtures (log raised, earth recessed) is acceptable as a **mechanical test scene** even though the final story has them on separate openings. This isolates engineering validation from story pagination. Test on device for real light/shadows, stable FPS and child-sized touch zones before duplicating the pattern across the book.
