# Future native 3D book: implementation handoff (draft)

This is a brief for Claude Code **after** the storyboard/world approval. It is not a claim that a working app has already been created.

## Target

Native interactive, convincing heavy-cardboard lift-the-flap book for **iPadOS** and **tvOS**. *One Boot* is the first content package. Build an engine with story data separated from the renderer.

## Suggested architecture (verify on current Apple SDK)

- **Shell:** SwiftUI for navigation, accessibility, reading modes and parent settings.
- **3D:** RealityKit for board pages, camera, lighting, shadow and flap transforms; use custom Metal shader work only if RealityKit materials cannot deliver controlled laminated-paper highlights.
- **Materials:** matte cardboard base with restrained rough satin lamination, optional subtle spot varnish. Artwork itself stays flat and faithful to the app illustration style.
- **Motion:** use filtered Core Motion device attitude on iPad to subtly adjust the simulated light/reflection, not to spin the whole book. Motion off/Reduced Motion fallback.
- **tvOS:** remote-focus navigation and obvious selectable flaps, no dependence on tilt or drag.
- **Touch:** tap-to-open baseline, optional direct drag gesture; do not rely on tiny finger notch as hit target.
- **Content:** JSON-like beat/spread/flap schema referencing separate sprites/textures and localised strings.

## Minimal prototype slice

1. Book opens to one two-page board spread with substantial edges and a plausible hinge.
2. Raised flap (log) and recessed flap (dirt, thumb notch) run through identical state API.
3. Illustration remains fixed relative to the paper; physical board has the small sheen shift when iPad rotates.
4. Equivalent interaction on Siri Remote.
5. Narration optional, sound not essential, story text separate for dynamic sizing and VoiceOver.
6. No unnecessary moving sprites or game mechanics; child and caregiver can linger.

## Likely content schema fields

`bookId`, `locale`, `beats`, `physicalSpreads`, `artAssets`, `pageGeometry`, `textBlocks`, `flaps[] {id, type, hingeAxis, hingeOrigin, restingAngle, openingAngle, closedArt, undersideArt, revealArt, hitRegion}`, `audioCues`, `accessibilityLabels`, `reducedMotionBehaviour`.

Start content with storyboard placeholders, not invented final illustrations. Reserve implementation details (shadow cost, mesh shape, resource budgets, support matrix, motion permissions and controls) for device benchmarking.
