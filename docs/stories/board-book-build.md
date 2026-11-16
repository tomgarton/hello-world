# A board book on the screen: how to build it

16 November 2026. Tom asked for the best way to build a cardboard book with pages that turn and
lift-the-flap recesses that convince. This is what was weighed up, what was built to find out, and what is
left. The first try is in the app (`app/Puggle/Features/Play/BoardBook.swift`), opened with
"-debugBook 1"; a recording is in `docs/previews/play/board-book.gif`.

## What makes it read as card, not paper

A board book does not behave like a paper book, and most page-turn effects imitate paper. Card is stiff:
a page does not curl, it swings on its spine in one flat piece, and it has an edge you can see. The eye
takes it for card when these are all present:

1. **The page stays flat as it turns.** It hinges on the spine like a door.
2. **Its cut edge shows** as it stands up: a strip of grey board the thickness of the card.
3. **The other pages show as a stack of edges** at the right and below, and on the left once read.
4. **Rounded corners,** as every board book has.
5. **It throws a shadow on the page beneath,** which shrinks as it falls.
6. **It darkens as it turns from the light,** and a soft shine crosses it, as coated card does.
7. **The page dips toward the spine:** a narrow shadow down the gutter.
8. **It moves like something with weight:** it falls faster as it goes and lands without a bounce, with one
   small thud in the hand.

And a flap reads as cut from the page when:

1. **Shut, it is level with the page,** with a hairline cut all round: dark on one side, a thin light edge
   on the side the light comes from.
2. **It has a thumb notch,** through which the recess shows. This is what tells a child where to lift.
3. **Lifted, it swings on one edge** and shows its bare card back.
4. **It leaves a recess as deep as the card:** a shadow inside the top and left walls, a light lip
   opposite, and the hidden picture at the bottom, a little in shade.
5. **Its shadow grows as it rises** and settles when it lies open.
6. **It springs a little as it lands open,** and falls shut faster than it lifts.

## Four ways to build it

| | How | For | Against |
|---|---|---|---|
| **A. Flat SwiftUI views, turned in 3D** | Each page and flap is an ordinary view, rotated on an edge with perspective. Edges, shadows and shine are drawn. | Pages are real views: text is text, VoiceOver works, the cast's own drawings are used as they are, flaps are buttons. Small, fast, no new tools. A stiff page is exactly what this does well. | The depth is drawn, not real: the card's edge and the recess are tricks that hold from the front only. Nothing can bend. |
| **B. The system's page curl** | `UIPageViewController` with the curl style. | Free, and follows the finger well. | It is paper: the page bends and curls. Wrong for card, and cannot be made stiff. |
| **C. Real 3D** (SceneKit or RealityKit) | The book is a model: boxes for pages, flaps as hinged pieces, real lights. | Real thickness, real shadows, real recesses, any angle. | Every picture becomes a texture, so text and the cast are images; VoiceOver and Dynamic Type are lost and must be rebuilt. Heavy to make and to change. Easy to look like a game. |
| **D. Drawn animation, played back** | The turn and the flaps are animated by hand (in Rive, or as video) and played. | Can be made beautiful. | Does not follow the finger, and a flap that does not follow the finger is not a flap. Every book is new animation work. |

**The choice: A.** A board book's page is stiff and flat, which is the one thing a flat view turned in 3D
does perfectly, and it keeps everything else the app has: real text, VoiceOver, the cast's rigs. C is the
only one that would look better, and it gives up too much for it. If a book ever wants a showpiece (a
pop-up, a wheel), that one spread could be built in 3D on its own.

## What the first try does

- One page to a screen, the spine at the left, the pages still to come stacked behind.
- A swipe turns the page with the finger. Past a third of the way, or flicked, it goes over; otherwise it
  falls back. A tap on either side edge turns it for a child who does not swipe.
- All eight page cues above, and all six flap cues, are in.
- A flap opens and shuts with a tap, on any of its four edges, in any of four outlines.
- With a flap, the page shows only the question; the answer comes when the flap is lifted.
- The little paper boat wobbles when found.
- "One Boot" is in it as a storyboard: eleven pages of rough flat scenes with the cast as they are in the app.

## What it does not do yet

- **A flap does not follow the finger.** It opens on a tap. Dragging it up by the notch is the next thing
  to add, and the most worth adding.
- **No sound.** A soft thud for a page and a small card sound for a flap would do a lot, off by default.
- **No cover.** A book wants a front, a title page and a back.
- **No two-page spread.** On an iPad, or a phone turned on its side, a book is two pages across with the
  spine in the middle. The same page view can be used twice.
- **Reduce Motion.** Pages and flaps ought to cross-fade, not swing. Not done.
- **VoiceOver.** Flaps are buttons and pages are read, but the order has not been checked.
- **Card grain.** The app already has a paper shader (`Paper.metal`); a faint grain on the card would help.
- **The pictures are storyboard quality.** Flat shapes placed by eye, with a few props.
- **Not on a phone.** Seen only in the simulator. How it feels under a thumb, and under a two-year-old's,
  is not known. Speed on a phone is not measured.

## How a real page would be made

Each page is three layers, drawn the way the app's scenes are drawn (flat shapes with no outline, and the
cast from their rigs):

1. **The scene,** with a hole's worth of nothing special where the flap sits.
2. **Under the flap:** what is found, drawn for the recess.
3. **The flap's face:** the piece of the scene that lifts, cut to the flap's outline.

The flap's outline is a shape in code, so it can be anything: a log, a leaf, a hat. A page is then data
(where things are, who is there, where the flap is, the words), as `OneBoot.swift` shows, and a new book
is a new list of pages, not new code.
