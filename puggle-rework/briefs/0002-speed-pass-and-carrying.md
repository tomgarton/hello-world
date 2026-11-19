# Rebuild brief: commit 6263eba "Speed pass on Today, and a held animation for carrying Puggle"

**Repo:** `tomgarton/hello-world`, branch `claude/baby-tracking-app-spec-fhtvex`.
**Last pushed base:** `4be0423` (Special days). The lost commit sat on top of `abef6a9` (spec note only: "## Build sent to TestFlight (18 November 2026)", appended to `docs/baby-tracker-spec.md`). Rebuild `abef6a9` first (see brief 1), then this one. This commit touches **no file that `abef6a9` touches except the spec**, and only appends to the spec, so the order matters only for where the spec section lands.

**Short version:** every app-code change in this commit has been replayed, in order, on a copy of `4be0423`. Each `str.replace` in the session's python scripts matched exactly once, and each Edit `old_string` was found (except one that depended on an earlier edit in the same commit, as expected). The result is the unified diff in **Appendix A**. It passes `git apply --check` against a clean `4be0423` tree. The fastest faithful rebuild is:

1. `git apply` Appendix A from the repo root (12 files under `app/Puggle/`).
2. Append the spec text in section 2 to `docs/baby-tracker-spec.md`.
3. Build, run the tests (expect 133 passing, the same count as before: no tests were added), and check on the simulator (section 4).
4. Commit with the message in section 7.

The diff was replayed from the session's own scripts, not copied out of git, so it is a reconstruction. See section 6 for what can't be confirmed.

---

## 1. What Tom asked for (verbatim)

Context: the previous turn (18 Nov, 08:11) reported that build 16 was uploaded to TestFlight, with the spec note committed (`abef6a9`) and not pushed.

> **2026-11-19 01:39 Tom:** "The app is feeling a bit laggy and stuttery now, we should do a quality and performance pass"

> **2026-11-19 01:51 Tom:** "I noticed that dragging Puggle is also very stuttery. We need an animation for her whilst you're holding her"

(02:19:02: a USER turn that is only an image, 1206x2622. It is almost certainly the simulator screenshot the session took of itself (`held-live.png`), not something Tom sent. It carries no instructions.)

Tom made no other decisions in this commit. The design choices were the session's own:
- the look of the held move (arms out, hands up, legs kicking in turn, tail swinging, happy eyes)
- swinging from the top behind the finger
- the smaller, fainter shadow left on the ground
- the land with a squash, a wag and a haptic
- turning off the button's pressed dimming

At the end the session asked whether to push and send a TestFlight build. Tom didn't answer that. His next message moved on to the entrance animation and bedtime, which is commit 3, `3504179`.

## 2. Intended behaviour

### Final assistant message (02:19:35, verbatim)

> I've done the speed pass and given Puggle a held animation; both are committed as `6263eba`. I measured the app in the simulator before changing anything. Neither is tested on a phone yet, so I can't say how much smoother it feels there.
>
> **What was slowing it down, and the fix:**
> - **Room wallpaper:** each flower was drawn as a separate layer, dozens of them 20 times a second. This was the slowest thing on Today. Now the whole wall is drawn in one layer and coloured once, and still looks tone on tone.
> - **Characters:** every outline was being re-read from text on every frame. Now each outline and each drawing file is read once and kept.
> - **Scrolling Today:** every scroll movement rebuilt the whole page. Now only the soft fade under the clock updates.
> - **Looking after card:** it went through every entry several times for each item whenever it redrew. Now it goes through them once per child.
> - **Dragging Puggle:** every finger movement rebuilt the sky, the room and her friend. Now only she follows your finger. This was the stutter you noticed.
> - **Sample family:** it saved after each of several hundred entries, so it took about 15 seconds to open in the simulator. It now saves once at the end and opens in about 6.
>
> **Carrying Puggle:** when you pick her up she lifts off the ground with her arms out and hands up, legs kicking in turn and tail swinging. She swings a little behind your finger, more the faster you move, and hangs straight when you stop. Her shadow stays on the ground, smaller and fainter. When you put her down she lands with a small squash, a wag and a haptic tap. She also no longer looks faded while you're holding her.
>
> - **If the children are asleep:** she stays asleep when picked up. She's lifted and swings, but doesn't kick.
> - **With Reduce Motion on:** she moves along the ground as before, without the lift or the swing.
>
> I couldn't catch her mid-hold in a simulator screenshot. What I've checked is the frame-by-frame render I sent, and that she lands where she's put down. All 133 tests pass, and the spec has a note on all of this. Nothing is pushed.
>
> Shall I push and send a build to TestFlight so you can try it on your phone, or hold off for now?

### Spec text appended to `docs/baby-tracker-spec.md` (verbatim; re-append exactly)

It was appended with `cat >> docs/baby-tracker-spec.md <<'EOF' ... EOF`. The heredoc began with an empty line, so the file gets a blank line and then the heading. It goes straight after the `## Build sent to TestFlight (18 November 2026)` section from `abef6a9`.

````markdown
## Speed pass, and carrying Puggle (19 November 2026)

Tom found the app laggy, and dragging Puggle stuttery. Measured by sampling the app in the simulator on Today,
idle, scrolling and dragging, then fixed what showed up most:

- **The room's wallpaper** was drawn as a separate layer for every shape, dozens of them twenty times a
  second: the single slowest thing on Today. Now the whole repeat is drawn into one layer and coloured once.
- **The characters** re-read every outline from text on every frame. Each outline is now read once and kept;
  each drawing file is read once too.
- **Scrolling Today** rebuilt the whole page on every frame, because the scroll position was kept in Today's
  own state. Only the soft edge under the clock reads it now.
- **Looking after** went through every entry for each child several times per item each time it drew. It now
  goes through them once per child.
- **Dragging Puggle** rebuilt the sky, the room and her friend on every finger movement, and asked several
  times whether it was night. Now only she follows the finger, and the scene changes once when she is picked up
  and once when she is put down.
- **Today's special day and the sky's part of the day** were worked out many times a frame; now once a minute.
- **The sample family** saved after each of several hundred entries, and opened in about fifteen seconds in
  the simulator. It saves once at the end now, in about six.

**Carrying Puggle.** Picking her up lifts her off the ground: arms out and hands up, legs kicking in turn,
tail swinging, happy eyes and raised brows (a new looping move, `held`, in her rig). She swings a little
behind the finger, more the faster it moves, and hangs straight when it stops. Her shadow stays on the ground,
smaller and fainter. Put down, she lands with a small squash, a wag and a tap. She is no longer dimmed while
pressed. While the children are asleep she stays asleep when carried: lifted and swinging, without the kicks.
With Reduce Motion she moves along the ground as before, without the lift or the swing.

Not yet checked on a phone: the frame rate there, and how the held move feels under a real finger.
````

## 3. File-by-file changes

There are 12 files, all under `app/Puggle/`, plus the spec. The exact final code is in Appendix A. Below, for each file: what changed, why, and how the session got there, including steps it later reverted. "Base" means `4be0423`. Line numbers are the base's.

### 3.1 `Design/Rooms.swift`: wallpaper drawn in one layer; shadow switch

**Why:** profiling idle Today showed the room's wallpaper as the most expensive app code. `RoomPainter.walls` called `soft(...)` for every flower, and `soft` makes a separate `drawLayer` with a `.sourceIn` tint fill, so dozens of offscreen layers were drawn on every frame (the scene runs at 30 fps).

**History:**
1. 01:46:54, Edit to `soft(...)`: `.renderingMode(.template)` plus `image.shading = .color(colour)` with no layer. *Reverted later.*
2. 01:56:05, Edit to `walls(...)`: resolve the image once per wall, still tinted with `.template` + `shading`. *Replaced later.*
3. 02:00–02:01: **the wallpaper flowers came out bright white** instead of tone on tone. The session compared them with `docs/previews/` and inspected `Resources/Assets.xcassets/shape-blossom.imageset/Contents.json`. Template rendering with `shading` did not tint these assets. What exactly in the asset blocked it is unknown, because the output wasn't captured.
4. 02:01:19, final python script:
   - restores `soft(...)` **exactly to the base code** (the per-shape `drawLayer` + `.sourceIn`, kept for the other single shapes in rooms);
   - rewrites the repeat in `walls` as one `context.drawLayer`: draw every untinted shape (resolved once), then `layer.blendMode = .sourceIn` and fill `CGRect(0, 0, w, top + Self.floor)` with `tint` once.

   The result looked tone on tone again.

**Final code (`walls`, replacing the base `while` loop at about lines 182–192):**
```swift
        // A quiet repeat of one brand shape, tone on tone, all the way up.
        // The whole repeat is drawn into one layer and coloured once. It was a layer for each shape, dozens
        // of them twenty times a second, the slowest thing on Today.
        let image = context.resolve(Image("shape-\(pattern)"))
        let wallTop = top + Self.floor
        context.drawLayer { layer in
            var row = 0
            var y = Self.floor - 34
            while top + y > -30 {
                var x: CGFloat = row.isMultiple(of: 2) ? 30 : 64
                while x < w + 20 {
                    var copy = layer
                    copy.translateBy(x: x, y: top + y)
                    if !row.isMultiple(of: 2) { copy.rotate(by: .degrees(20)) }
                    copy.draw(image, in: CGRect(x: -9, y: -9, width: 18, height: 18))
                    x += 68
                }
                y -= 46
                row += 1
            }
            layer.blendMode = .sourceIn
            layer.fill(Path(CGRect(x: 0, y: 0, width: w, height: wallTop)), with: .color(tint))
        }
```
(The base used `soft(pattern, x, y, 18, tint, turn: row.isMultiple(of: 2) ? 0 : 20)`. `soft` places the shape at `top + cy` with size 18, and the new code does the same.)

**Shadow switch (01:56:00, two scripts):**
- `RoomFrame` gets `var puggleShadow = true` after `var puggleX: CGFloat = 0`, and passes it on with `painter.puggleShadow = puggleShadow` after `painter.puggleX = puggleX`.
- `RoomPainter` gets `var puggleShadow = true` after its `var puggleX: CGFloat = 0`. The second script inserted this by list index (`lines.insert(124, ...)` after asserting that `lines[123]` contains `var puggleX`). It matched the base, at base line 122.
- In `rug(...)`: `// Her shadow on it.` becomes `// Her shadow on it, unless she is being carried.`, and the `oval(...)` line becomes `if puggleShadow { oval(w / 2 + puggleX, 224, 36, 4.5, Palette.fixedInk.opacity(dark ? 0.3 : 0.12)) }`.

### 3.2 `Design/Rig.swift`: path cache, rig-file cache, `carried` flag

**Why:** every character re-parsed each SVG-like path string from text on every frame (`RigRenderer.path(from:)`), and `Rig.load` decoded the JSON drawing again for friends and portraits on redraws. This showed up in the idle profile after the room fix.

1. **Path cache** (Edit at 01:46:57; the `nonisolated(unsafe)` was added by an Edit at 01:47:51 whose old_string `    private static var read: [String: Path] = [:]` exists only after the first edit, which is expected). The old `path(from:)` body becomes `private static func parse(_ d: String) -> Path`. Final code, inserted before the base's `/// Reads "M88 166 ..."` doc comment in `enum RigRenderer`:
```swift
    /// Paths already read, by their text. Every character is drawn many times a second from the same few
    /// hundred paths, so each is read once.
    nonisolated(unsafe) private static var read: [String: Path] = [:]
    private static let readLock = NSLock()

    /// Reads "M88 166 Q120 156 152 166 L180 244 Z": absolute M, L, Q, C and Z.
    static func path(from d: String) -> Path {
        readLock.lock()
        defer { readLock.unlock() }
        if let kept = read[d] { return kept }
        let path = parse(d)
        read[d] = path
        return path
    }

    private static func parse(_ d: String) -> Path {
```
2. **Rig file cache** (Edit at 01:58:59; its old_string matches the base). `Rig` is a struct (a value type), so handing out the cached copy is safe:
```swift
    /// Drawings already read, by name. Each file is read and decoded once; a portrait or a friend
    /// appearing again takes the copy kept here.
    nonisolated(unsafe) private static var loaded: [String: Rig] = [:]
    private static let loadLock = NSLock()

    static func load(_ name: String) -> Rig? {
        loadLock.lock()
        defer { loadLock.unlock() }
        if let kept = loaded[name] { return kept }
        guard let url = Bundle.main.url(forResource: "\(name).rig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rig = try? JSONDecoder().decode(Rig.self, from: data) else { return nil }
        loaded[name] = rig
        return rig
    }
```
3. **`carried` on `RigRuntime`**, inserted before `    /// One move per track.` and modelled on the existing `walking` flag. It was first written as `var held` (01:54:54), and then **renamed to `carried`** (01:56:24) after the build. The reason: `RigRuntime` already has `var held: [String: PartState]` (base line 424, "Poses held on top of everything else"), so `var held = false` is a redeclaration.
```swift
    /// Being carried, for as long as this is true: lifted, legs kicking.
    var carried = false {
        didSet {
            guard carried != oldValue else { return }
            if carried { play("held") } else if playing["body"]?.name == "held" { playing["body"] = nil }
        }
    }
```
Note that `play()` returns early when `asleep` (unless the move's name starts with "wake"). That is why, while the children are asleep, she is lifted and swings but doesn't kick, which matches the spec.

### 3.3 `Design/PuggleView.swift` (`PuggleController`): publish only on change; `held`

**Why:** a drag set `walking` on every movement, and every `didSet { push() }` republished and redrew the whole of Today's header under the finger.
```swift
    // Each pushes only when it changes: a drag sets them on every movement, and publishing each time
    // redrew the whole of Today's header under the finger.
    @Published var asleep = false { didSet { if asleep != oldValue { push() } } }
    ...
    @Published var walking = false { didSet { if walking != oldValue { push() } } }
    /// Picked up and carried by a finger.
    @Published var held = false { didSet { if held != oldValue { push() } } }
```
In `push()`, `if asleep || walking { bubbles(false) }` becomes `if asleep || walking || held { bubbles(false) }`, and `rig?.carried = held` is added after `rig?.walking = walking`. The script first wrote `rig?.held = held`, and the rename step changed it. Rive inputs are unchanged: there is no Rive input for held.

### 3.4 `Features/Today/Tiles.swift` (`PuggleHeader`): `CarriedPuggle`, `Carry`, `Undimmed`

**Why:** the old drag set `walkedTo` (a `@State` on `PuggleHeader`) on every movement. That rebuilt the scene (sky, room, friend) on every movement, and `PuggleScene.isNight(dark:)` (which "means drawing a frame of the scene") was called about 7 times per body. Tom also wanted a held animation.

Changes, made by four scripts at 01:55:09, 01:55:49 and 02:16:53, all of which apply cleanly to the base:
- **State:** `@State private var walkStart: CGFloat?` is replaced by `@State private var carry = Carry()` and `@State private var holding = false`, each with a doc comment.
- **`isNight` computed once** in `sceneContent(width:)`: `let isNight = PuggleScene.isNight(dark: dim)`, with the comment "Asked once here: working it out means drawing a frame of the scene." Every `PuggleScene.isNight(dark: dim)` in that function becomes `isNight`. `canBubble` also gets `&& !holding`.
- `PuggleScene(..., puggleX: x)` becomes `PuggleScene(..., puggleX: x, puggleShadow: !holding)`.
- `if room == nil { PuggleRain(...) }` becomes `if room == nil, !holding { PuggleRain(...) }`. The rain in front of her is hidden while she's carried.
- **The whole old `Button { ... } label: { PuggleView ... }` block**, with its inline `DragGesture` and accessibility modifiers (from `            Button {\n                if justWalked` through the line containing `.accessibilityAction(named: "Walk right")`), is replaced by:
```swift
            CarriedPuggle(controller: controller, carry: carry, restX: x, reach: reach, canWalk: canWalk, quiet: quiet,
                          holding: $holding, justWalked: $justWalked, shadowNight: room == nil && isNight,
                          outfit: room?.outfit ?? weather.outfit(night: isNight),
                          warmLight: room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: isNight),
                          lift: lift, tilt: tilt, nod: nod, onTap: tapped, onPutDown: { walkedTo = $0; land() })
                // She pops up from behind the hill when Today first opens.
                .offset(y: appeared ? 0 : 60)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 26)
```
- In `pulled(to:)`, `controller.walking = amount > 24 && !quiet` becomes `let walk = amount > 24 && !quiet` followed by `if controller.walking != walk { controller.walking = walk }`.
- New private funcs before `private func react()`:
  - `tapped()`: the old button action, moved out unchanged.
  - `land()`: `Haptics.tap()`; return if Reduce Motion is on; `controller.rig?.play("wag")`; `nod` goes to 1 (0.5 if quiet) over 0.08 s ease-out, then springs back to 0 (`.spring(duration: 0.35, bounce: 0.35).delay(0.08)`).
- New types inserted before `/// Your photo (or initial), top right of Today.`, in this order:
  - `@Observable final class Carry` (`x`, `start`, `sway`, `@ObservationIgnored settle: Task`);
  - `private struct CarriedPuggle: View`;
  - `private struct Undimmed: ButtonStyle`, added at 02:16:53, placed after `CarriedPuggle` and before `YouButton`'s doc comment.

  The full code is in Appendix A.
- **Behaviour of `CarriedPuggle`:**
  - **Pick-up.** `DragGesture(minimumDistance: 12)`, which needs a horizontal-dominant start and `canWalk`. On the first change it sets `carry.start = restX`, `justWalked = true`, `holding = true` (0.2 s ease-out), `controller.held = true`, and a haptic.
  - **While carried.** `carry.x` follows the finger, clamped to ±reach. Unless Reduce Motion is on, `carry.sway = clamp(velocity.width / 70, ±14)` degrees, and a 90 ms `Task` resets the sway to 0 when the finger stops.
  - **Put down.** On end she is put down at `carry.x` through `onPutDown`, which sets `walkedTo` and calls `land()`. Then `carry.x = nil`, and `justWalked` is cleared after 0.15 s.
  - **Looks.**
    - While held (and not Reduce Motion): `scaleEffect(x: 0.97, y: 1.04 × squash)` anchored at the bottom, and offset y −26.
    - `.rotationEffect(carry.sway, anchor: .top)`, so she hangs from the finger.
    - Springs: `.spring(duration: 0.32, bounce: 0.25)` on `up`, and `.spring(response: 0.5, dampingFraction: 0.42)` on sway.
    - Ground shadow while held: `Ellipse` 48×7, offset y 3.5. Night colour `Color(hex: 0x15163A).opacity(0.2)`, day `Palette.fixedInk.opacity(0.06)`. The scene's own shadow is 72×9 at 0.32 / 0.1.
  - **Accessibility.** `.accessibilityElement(children: .combine)` is new. The label and hint are the same as before. "Walk left/right" now call `onPutDown(...)`, so they also trigger the land animation.
- **Button dimming fix (02:16:53):** see pitfall 5.4. `.buttonStyle(.plain)` becomes `// Not dimmed while pressed: she is held for as long as she is carried, and stays herself.` followed by `.buttonStyle(Undimmed())`, where
```swift
/// A button that shows no pressed look of its own.
private struct Undimmed: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.contentShape(Rectangle()) }
}
```
- **Changed behaviour versus the base:** during a drag she used to walk on the spot (`controller.walking = true`). Now she plays `held` instead, and `walking` is no longer set by the drag at all.

### 3.5 `Design/Scenes.swift`: sky phase cached per minute; shadow switch

1. **Edit at 01:48:06** (matches the base). `SkyPhase.at(hour:exact:)` caches by `(minute, hour)` when `exact` is non-nil. The old body becomes `private static func work(hour:exact:)`. The new static is `nonisolated(unsafe) private static var kept: (minute: Int, hour: Int, phase: SkyPhase)?`. Comment: "The scene asks many times a frame; the answer only changes from one minute to the next."
2. **Shadow switch (01:56:00):**
   - `PuggleScene` gets `/// False while she is carried: she draws her own shadow then.` and `var puggleShadow = true` after `puggleX`, and passes `puggleShadow: puggleShadow` into both `SceneFrame(...)` calls, before `seasonOverride:`.
   - `SceneFrame` gets `var puggleShadow = true` and passes it to `RoomFrame(..., puggleX: puggleX, puggleShadow: puggleShadow)`.
   - The outdoor shadow `Ellipse` is wrapped in `if puggleShadow { ... }`.

### 3.6 `Design/SpecialDays.swift`: `SpecialDay.today` cached for a minute

This is an Edit at 01:47:50 and matches the base. After the `debugDay` and on/off checks:
```swift
        // Asked for by every frame of the scene, so worked out once a minute, not each time.
        let now = Date.now
        if let kept = Self.kept, now < kept.until { return kept.day }
        let day = on(now, region: Locale.current.region?.identifier)
        kept = (now.addingTimeInterval(60), day)
        return day
    }

    nonisolated(unsafe) private static var kept: (until: Date, day: SpecialDay?)?
```
The debug override and the Settings switch are still checked before the cache, so the tests (`SpecialDayTests`) were unaffected: 133 passed.

### 3.7 `Data/Care.swift`: `careIndex(for:)`, and `careGap` taking `done:`

**Why:** the "Looking after" card (`CareCard`) called `lastCare`/`booked`/`careDone`, each a filter and sort over all of a child's events, several times per item per child per redraw. This is an Edit at 01:47:24 and matches the base. It adds `func careIndex(for child: Child) -> [String: (done: [Event], booked: Event?)]`, which makes one pass over `child.events` with `kind == .care && isLive`, keyed by `detail`. `done` holds non-booked events, sorted oldest first. `booked` is the earliest booked event. This has the same semantics as the base `careDone` and `booked`. `careGap(_:for:)` gains `done: [Event]? = nil` and uses `(done ?? careDone(...))`. The full code is in Appendix A.

### 3.8 `Features/Today/CareCard.swift`: one index per draw

This is a python script at 01:47:34. All 10 replaces matched once.
- `import CoreData` is added above `import SwiftUI`.
- The computed `shown` is removed. In its place: a `typealias Index = [NSManagedObjectID: [String: (done: [Event], booked: Event?)]]` and a `has(_:_:in:)` helper.
- `body` builds `index` once: `Dictionary(uniqueKeysWithValues: children.map { ($0.objectID, store.careIndex(for: $0)) })`. It also builds `items`, and returns the `VStack`. The old inner `let items = shown` is removed.
- `row(item)` becomes `row(item, index)`.
- `line(...)` takes `entry: (done:, booked:)` and uses `entry.booked`, `entry.done.last?.startedAt`, and `careGap(item, for: child, done: entry.done)`.
- `text(_:_:last:)` takes the `done` array instead of a child, so brushing counts `done.filter { isDateInToday }`.

### 3.9 `Features/Today/TodayView.swift`: scroll depth moved out of Today's state

This is a python script at 01:47:41. All 4 replaces matched once.
- `@State private var scrolledUp: CGFloat = 0` becomes `@State private var scroll = ScrollDepth()`, with the doc comment "Kept outside Today's own state and read only by the edge...".
- In the `onChange`, `scrolledUp = max(-y, 0)` becomes `scroll.up = max(-y, 0)`.
- In the overlay, `TopScrim(strength: ...)` becomes `ScrollScrim(scroll: scroll)`.
- New `@Observable final class ScrollDepth { var up: CGFloat = 0 }` and `private struct ScrollScrim: View`, which computes `TopScrim(strength: Double(min(max((scroll.up - PuggleHeader.sceneHeight + 110) / 60, 0), 1)))`.
- **Quirk, reproduced faithfully:** the script inserted the new types directly before `struct ChildStatusRow: View {`. In the base, that line has a doc comment above it ("/// One row per child: who is asleep, ... starts and stops their sleep."). The result is that this doc comment now sits on top of the `ScrollDepth` doc comment, so it attaches to `ScrollDepth`. This is harmless, and the original commit almost certainly has the same misplacement. You can tidy it, but tidying makes the rebuild differ from the original.

### 3.10 `Resources/Rigs/puggle.rig.json`: new looping move `held`

Added as the last entry in `moves` (after `bubbles`). The file is re-serialised with `json.dumps(r, indent=1, ensure_ascii=False) + "\n"`, which matches the original formatting: the diff against the base is pure addition apart from one `}` → `},` line.
- The first script (01:54:32) wrote it with `indent=2`. A second script (01:54:43) rewrote it with `indent=1` to match the original style.
- The arms went through three attempts (see 5.3), and the in-between legs were zeroed (5.3).

Final move:
```json
"held": {"about": "Picked up and carried: lifted under her arms, legs kicking in turn, tail swinging, delighted. Goes round until she is put down.", "loops": true, "length": 0.9, "keys": [
 {"t": 0,    "pose": {"arm-left": {"r": 36}, "forearm-left": {"r": 44}, "arm-right": {"r": -36}, "forearm-right": {"r": -44}, "upper": {"sy": 1.03}, "blush": {"sx": 1.12, "sy": 1.12}, "brow-left": {"y": -4, "r": -6}, "brow-right": {"y": -4, "r": 6}, "leg-left": {"r": 0, "y": 3}, "leg-right": {"r": 0, "y": 3}, "tail": {"r": 14}, "head": {"r": -3}}, "face": {"eyes": "happy", "brows": "on"}},
 {"t": 0.22, "pose": {"arm-left": {"r": 36}, "forearm-left": {"r": 44}, "arm-right": {"r": -36}, "forearm-right": {"r": -44}, "upper": {"sy": 1.03}, "blush": {"sx": 1.12, "sy": 1.12}, "brow-left": {"y": -4, "r": -6}, "brow-right": {"y": -4, "r": 6}, "leg-left": {"r": -20.4, "y": 1}, "foot-left": {"r": -30.0}, "leg-right": {"r": 0, "y": 3}, "tail": {"r": -6}, "head": {"r": 1}}, "face": {"eyes": "happy", "brows": "on"}},
 {"t": 0.45, "pose": {"arm-left": {"r": 36}, "forearm-left": {"r": 44}, "arm-right": {"r": -36}, "forearm-right": {"r": -44}, "upper": {"sy": 1.03}, "blush": {"sx": 1.12, "sy": 1.12}, "brow-left": {"y": -4, "r": -6}, "brow-right": {"y": -4, "r": 6}, "leg-left": {"r": 0, "y": 3}, "leg-right": {"r": 0, "y": 3}, "tail": {"r": -14}, "head": {"r": 3}}, "face": {"eyes": "happy", "brows": "on"}},
 {"t": 0.67, "pose": {"arm-left": {"r": 36}, "forearm-left": {"r": 44}, "arm-right": {"r": -36}, "forearm-right": {"r": -44}, "upper": {"sy": 1.03}, "blush": {"sx": 1.12, "sy": 1.12}, "brow-left": {"y": -4, "r": -6}, "brow-right": {"y": -4, "r": 6}, "leg-right": {"r": 20.4, "y": 1}, "foot-right": {"r": 30.0}, "leg-left": {"r": 0, "y": 3}, "tail": {"r": 6}, "head": {"r": -1}}, "face": {"eyes": "happy", "brows": "on"}}
]}
```
The key order inside each pose is as shown, because Python dicts keep insertion order. Values like `-20.4` and `-30.0` are floats, because they came from multiplying by 1.7 and 1.5. To regenerate it exactly with a script rather than from the patch, run this from `app/`:
```python
import json
p='Puggle/Resources/Rigs/puggle.rig.json'
r=json.load(open(p))
arms={"arm-left":{"r":36},"forearm-left":{"r":44},"arm-right":{"r":-36},"forearm-right":{"r":-44},"upper":{"sy":1.03},"blush":{"sx":1.12,"sy":1.12},"brow-left":{"y":-4,"r":-6},"brow-right":{"y":-4,"r":6}}
face={"eyes":"happy","brows":"on"}
def key(t, extra):
    pose=json.loads(json.dumps(arms)); pose.update(extra); return {"t":t,"pose":pose,"face":face}
r['moves']['held']={
 "about":"Picked up and carried: lifted under her arms, legs kicking in turn, tail swinging, delighted. Goes round until she is put down.",
 "loops":True,"length":0.9,
 "keys":[
  key(0,{"leg-left":{"r":0,"y":3},"leg-right":{"r":0,"y":3},"tail":{"r":14},"head":{"r":-3}}),
  key(0.22,{"leg-left":{"r":-20.4,"y":1},"foot-left":{"r":-30.0},"leg-right":{"r":0,"y":3},"tail":{"r":-6},"head":{"r":1}}),
  key(0.45,{"leg-left":{"r":0,"y":3},"leg-right":{"r":0,"y":3},"tail":{"r":-14},"head":{"r":3}}),
  key(0.67,{"leg-right":{"r":20.4,"y":1},"foot-right":{"r":30.0},"leg-left":{"r":0,"y":3},"tail":{"r":6},"head":{"r":-1}}),
 ]}
open(p,'w').write(json.dumps(r,indent=1,ensure_ascii=False)+"\n")
```
(This produces the same final JSON as the session's chain of four scripts. The 0 values for in-between legs are ints, as the session's `po[leg]['r']=0` wrote them.)

### 3.11 `Data/Persistence.swift`: `holdingSaves`

**Why:** the launch profile showed that the sample family saved after each of several hundred entries. In the simulator, the sample showed "Add a child" for about 9 s or more after launch, and took about 15 s to open in total. This is a script at 02:10:57 that matches the base:
```swift
    /// True while many entries are being made at once (the sample family): each save waits, and one
    /// save at the end keeps them all. Saving after each of hundreds made opening the sample take seconds.
    var holdingSaves = false

    func save() {
        guard viewContext.hasChanges, !holdingSaves else { return }
```

### 3.12 `Data/SampleFamily.swift`

Around `SampleData(store: sample).fill()` (base line 28):
```swift
            sample.persistence.holdingSaves = true
            SampleData(store: sample).fill()
            sample.persistence.holdingSaves = false
            sample.persistence.save()
```
(`sample.persistence` was accessible: the session checked first. The tests' own `SampleData(store:)` calls were left alone.)

### 3.13 Not in the commit

- `app/PuggleTests/ScratchRender.swift`: a temporary render test, deleted before running the full suite. See section 4.
- `app/DerivedDataProfile/`: the optimised profiling build, `rm -rf`'d before committing. **It isn't covered by `app/.gitignore`**, which lists `DerivedData/` and `DerivedData-*/` but not `DerivedDataProfile`. Delete it, or name it `DerivedData-Profile`, before `git add`.
- The commit ran `git add docs/baby-tracker-spec.md app/Puggle`, so nothing outside those paths was included.

## 4. Measurements and verification

**What the session measured.** Raw numbers aren't in the transcript extract, because tool outputs weren't captured. The findings, as stated in the assistant's messages:
- **Idle Today, before:** the room wallpaper (`RoomPainter.walls`→`soft`→`drawLayer`) was the slowest app code, followed by rig path parsing and `SpecialDay.today`/`SkyPhase.at` being called many times a frame.
- **Scrolling, before:** the whole `TodayView` body was recomputed on every scroll frame (from `scrolledUp` `@State`), along with `CareCard` combing through entries.
- **After the fixes, idle:** "The room no longer shows up in the profile." A new hotspot appeared, `Rig.load` decoding a friend's JSON on redraws, and was fixed with the load cache.
- **Drag, after:** "The drag no longer rebuilds the scene. Now only Puggle's own drawing shows up in the profile."
- **Launch:** the sample family opened in about 6 s instead of about 15 s (simulator, optimised build).
- **Tests:** "All 133 tests pass". This was after deleting ScratchRender and regenerating the project. It is the same count as the base, so no new tests were added.
- **Visual checks:**
  - the wallpaper was checked against `docs/previews/` (bedroom) for tone on tone;
  - the held move was checked in an 8-frame contact strip;
  - "she lands where she's put down" was checked in the simulator.

  A live mid-hold screenshot wasn't caught. **Not checked on a phone:** the frame rate, and how the held move feels.

**How the session profiled.** Tom's Mac, simulator `AF626ED5-1676-4A46-9416-799115D54713` (iPhone 17), bundle id `com.tomgarton.puggle`.
```bash
cd app
# optimised build (Debug + LOCAL_ONLY conditions via the "Puggle Local" scheme, -O)
xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedDataProfile SWIFT_OPTIMIZATION_LEVEL=-O build 2>&1 | grep -E "error:|BUILD"
ID=AF626ED5-1676-4A46-9416-799115D54713
xcrun simctl install $ID DerivedDataProfile/Build/Products/Local-iphonesimulator/Puggle.app
xcrun simctl launch --terminate-running-process $ID com.tomgarton.puggle -uitest 1 -debugHour 11 &
sleep 7
# xctrace --attach failed in every form tried (pid, --device + name); `sample` worked:
sample $(pgrep -f "Puggle.app/Puggle" | head -1) 6 -file /tmp/idle.txt
# main thread only, app's own frames ranked:
awk '/Main Thread/{m=1} /Thread_.*eventfetch/{m=0} m' /tmp/idle.txt > /tmp/m_idle.txt
grep -E "\(in Puggle\)" /tmp/m_idle.txt | sed -E 's/^[ +!:|]*//' \
 | awk '{c=$1; $1=""; sub(/\+ [0-9]+ \[0x[0-9a-f]+\]/,""); a[$0]+=c} END{for(k in a) print a[k], k}' | sort -nr | sed -n 2,16p | cut -c1-130
```
- `-uitest 1` opens the sample family.
- `-debugHour 11` forces late morning. Without it, at night the sample children are asleep and Puggle is quiet or asleep, so the held move won't kick.
- For scroll and drag profiles, run `sample` for 5–8 s while scrolling or dragging by hand in the simulator.

**Re-verify on the Mac:**
1. `cd app && ~/.local/xcodegen-dl/xcodegen/bin/xcodegen generate` (`*.xcodeproj` is gitignored and generated). Then run the full tests: `xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData test 2>&1 | grep -E "error:|Executed|TEST " | tail -4`. Expect 133 tests, 0 failures. (If brief 1 or a later commit has been applied first, the count may differ. At 6263eba it was 133.)
2. Profile idle Today, scrolling and dragging as above. `RoomPainter.walls`/`soft`, `RigRenderer.parse`, `Rig.load`, `SpecialDay.today` and `SkyPhase.at` should not dominate.
3. **Visual:**
   - The bedroom wallpaper is tone on tone, not white (`-debugHour 19` or so, to get the bedroom).
   - Drag Puggle sideways at 11:00. Check that she:
     - lifts about 26 pt, with arms out and hands up, and legs kicking alternately;
     - swings from the top behind the finger;
     - leaves a small faint shadow on the ground, with no big shadow under her;
     - is not dimmed;
     - lands with a squash, a wag and a haptic at the drop point.
   - At night with the children asleep: she is lifted and swings, with no kicks.
   - Turn on Reduce Motion: no lift and no swing, and she still moves.
   - Check that tapping her without dragging still gets shy on the first tap, then reactions.
4. **Optional render check of the held move:** the session's temporary test, in its final form. Add it as `app/PuggleTests/ScratchRender.swift`, regenerate with xcodegen, run `-only-testing:PuggleTests/ScratchRender`, look at the PNGs, then **delete it**. Change `out` to a local path.
```swift
import SwiftUI
import XCTest
@testable import Puggle

@MainActor
final class ScratchRender: XCTestCase {
    func testHeldStrip() throws {
        let out = "/private/tmp/claude-501/-Users-tomgarton-Desktop-Claude-Code/34bd4bb6-830a-48d5-af67-2fa79c98b382/scratchpad/held"
        try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        for (index, t) in [0.0, 0.11, 0.22, 0.34, 0.45, 0.56, 0.67, 0.8].enumerated() {
            let runtime = RigRuntime(rig: Rig.load("puggle")!)
            let start = Date.now
            runtime.carried = true
            // Run the springs up to this moment so the follow-through shows.
            var states: [String: PartState] = [:]
            var at = 0.0
            while at <= t + 0.9 { states = runtime.advance(to: start.addingTimeInterval(at)); at += 1.0 / 60 }
            let view = RigFrame(rig: runtime.rig, states: states, face: runtime.face)
                .frame(width: 240, height: 300).background(Color(hex: 0xF6EFE3))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let data = renderer.uiImage!.pngData()!
            try data.write(to: URL(fileURLWithPath: "\(out)/\(index).png"))
        }
    }
}
```
The session tiled the 8 PNGs with a private scratch tool, `sheetmake`, which is lost (see section 6). Any image tool will do, for example `montage` or a short PIL script.

## 5. Pitfalls and fixes along the way

1. **Wallpaper turned white.** `Image(...).renderingMode(.template)` plus `GraphicsContext.ResolvedImage.shading = .color(...)` didn't tint the `shape-*` assets, so the flowers drew bright white instead of tone on tone. The fix was one `drawLayer` for the whole wall, then a `.sourceIn` fill of the tint. The single-shape `soft(...)` was restored to its original per-layer tint. Don't use the template/shading approach.
2. **`static var` caches under strict concurrency.** The session used `nonisolated(unsafe) private static var` for the caches: `read` and `loaded` (protected by an `NSLock`), `SpecialDay.kept` and `SkyPhase.kept` (main-thread use, unlocked). The `read` cache was first written without `nonisolated(unsafe)` and fixed one edit later.
3. **Arm angles and the rig's sign convention.** The rig's arm rotation runs the opposite way to what you'd guess:
   - The first attempt was `arm ±64`, `forearm ±28`, with the left arm positive. The arms bent in to her cheeks, like her "oh" move.
   - `arm ±96`, `forearm ∓34`: the arms still crossed inwards.
   - Flipped sign, `arm-left −75`, `forearm-left −30`, right arm positive.
   - Final: `arm-left 36`, `forearm-left 44`, `arm-right −36`, `forearm-right −44`. This reads as a happy "wheee" with arms out and hands up.

   The kicks were also enlarged: legs with |r| ≥ 10 were multiplied by 1.7 and feet by 1.5, giving ±20.4 and ±30. **Her feet crossed in the in-between frames,** so every leg with |r| < 10 was set to r = 0.
4. **Name clash:** `RigRuntime` already has `var held: [String: PartState]`, so the runtime flag is `carried`. The controller's published property is still `held`.
5. **Button dimming:** while she was held she looked faded. That was `.buttonStyle(.plain)`'s pressed dimming, which stays on for the whole drag because the press never ends. The fix was the `Undimmed` ButtonStyle, which returns the label with `contentShape(Rectangle())`.
6. **Render test reuse:** the first version of ScratchRender shared one `RigRuntime` across all frames, so later frames started from the wrong time. The fix was a fresh runtime and start date per frame, with the springs run at 60 Hz up to `t + 0.9`.
7. **Profiler:** `xcrun xctrace record --attach` failed both by host pid and by `--device ... --attach Puggle`, so the session used `/usr/bin/sample` instead.
8. **Simulator time:** at night the sample children are asleep, so Puggle is asleep and won't kick. Use `-debugHour 11` to see the held move.
9. **Sample family slow to appear:** the screen said "Add a child" about 9 s after launch, because of per-entry saves (fixed in 3.11).
10. **The live screenshot mid-hold** (`simctl io screenshot` after `sleep 2.2` during a manual drag) didn't catch her in the air. A `sips -c` crop attempt and a PIL crop were tried, and only the `sips --cropToHeightWidth` form worked.
11. **Profiling build folder:** `DerivedDataProfile` isn't gitignored. Remove it before committing.

## 6. Uncertain or unrecoverable

- **Tool outputs aren't in the extract.** Build errors, sample counts and file contents the session read are missing. The only numbers known are the ones in assistant messages (about 15 s → about 6 s, 133 tests). The diff in Appendix A comes from replaying the scripts against `4be0423`. Every replace and Edit matched exactly once, so it should match `6263eba` byte for byte. It can't be checked against the lost commit itself.
- **The python scripts' effects were order-dependent:**
  - `Rig.swift`'s `nonisolated(unsafe) read` edit needed the 01:46:57 edit.
  - The `Rooms.swift` revert (02:01:19) needed the 01:46:54 and 01:56:05 edits.
  - `RoomPainter`'s `puggleShadow` was inserted by line index 124 (after asserting line 123 contained `var puggleX`).
  - The 01:55:49 Tiles script needed the 01:55:09 call site.
  - The `carried` rename needed `held`.

  All of these were replayed in order and resolved as described. Nothing else depended on uncommitted work: the only intervening commit, `abef6a9`, touched the spec only.
- **Why the shape assets refused template tinting** isn't known: `Contents.json` was read, but its output wasn't captured. It doesn't matter for the rebuild.
- **The rename `held` → `carried`:** the reason given above (a redeclaration with `RigRuntime.held`) is inferred from the base code, not from a captured error.
- **`sheetmake`** (the session's contact-sheet script in its scratchpad) and the rendered strip and screenshot images are lost. They aren't needed.
- **Reduce Motion detail:** under Reduce Motion, `controller.held` is still set, so the `held` move (kicking) still plays on the rig. Only the lift, the swing and the land squash are skipped. The spec says "she moves along the ground as before, without the lift or the swing", which is consistent with this. Keep it as written unless Tom says otherwise.
- **Not checked on a phone:** the frame rate, and how the held move feels.

## 7. Commit message (verbatim)

```
Speed pass on Today, and a held animation for carrying Puggle

Wallpaper drawn in one layer, rig outlines and drawings read once, scrolling and dragging no longer rebuild
the page or the scene, care card reads entries once per child, special day and sky phase worked out once a
minute, sample family saved once. Picking Puggle up now lifts her, legs kicking, swinging behind the finger.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```
(Use whatever attribution trailer the Mac session is told to use. The original was the line above.)
Command: `git add docs/baby-tracker-spec.md app/Puggle && git commit`.

---

## Appendix A: reconstructed diff of `app/Puggle` against 4be0423 (`git apply` from the repo root)

This is also saved next to this brief as `2-6263eba-reconstructed.patch`. It covers 12 files: 534 insertions and 103 deletions.

```diff
diff --git a/app/Puggle/Data/Care.swift b/app/Puggle/Data/Care.swift
index a7d307c..60995ad 100644
--- a/app/Puggle/Data/Care.swift
+++ b/app/Puggle/Data/Care.swift
@@ -119,12 +119,30 @@ extension FamilyStore {
             .min { ($0.startedAt ?? .distantFuture) < ($1.startedAt ?? .distantFuture) }
     }
 
+    /// Every care entry for a child in one pass, by item: done ones oldest first, and the next booked.
+    /// For Today, which would otherwise go through all the child's entries once per item, per line.
+    func careIndex(for child: Child) -> [String: (done: [Event], booked: Event?)] {
+        var index: [String: (done: [Event], booked: Event?)] = [:]
+        for event in child.events ?? [] where event.kind == .care && event.isLive {
+            guard let key = event.detail else { continue }
+            if event.isBooked {
+                let kept = index[key]?.booked
+                if kept == nil || (event.startedAt ?? .distantFuture) < (kept?.startedAt ?? .distantFuture) { index[key, default: ([], nil)].booked = event }
+            } else {
+                index[key, default: ([], nil)].done.append(event)
+            }
+        }
+        for key in index.keys { index[key]?.done.sort { ($0.startedAt ?? .distantPast) < ($1.startedAt ?? .distantPast) } }
+        return index
+    }
+
     /// How often it happens for this child: as a parent set it, else as learned, else a starting guess.
-    func careGap(_ item: CareItem, for child: Child) -> CareGap? {
+    /// `done` is the child's done entries for the item, if already to hand.
+    func careGap(_ item: CareItem, for child: Child, done: [Event]? = nil) -> CareGap? {
         if let set = guides(.care).first(where: { $0.key == item.key }), set.gapHours > 0 {
             return CareGap(days: set.gapHours / 24, source: .set)
         }
-        if let learned = Self.learnedGap(careDone(item.key, for: child).compactMap(\.startedAt)) {
+        if let learned = Self.learnedGap((done ?? careDone(item.key, for: child)).compactMap(\.startedAt)) {
             return CareGap(days: learned, source: .learned)
         }
         return item.startingGap(ageMonths: child.ageMonths).map { CareGap(days: $0, source: .starting) }
diff --git a/app/Puggle/Data/Persistence.swift b/app/Puggle/Data/Persistence.swift
index 4406345..dfc9d57 100644
--- a/app/Puggle/Data/Persistence.swift
+++ b/app/Puggle/Data/Persistence.swift
@@ -87,8 +87,12 @@ final class Persistence {
         viewContext.transactionAuthor = "app"
     }
 
+    /// True while many entries are being made at once (the sample family): each save waits, and one
+    /// save at the end keeps them all. Saving after each of hundreds made opening the sample take seconds.
+    var holdingSaves = false
+
     func save() {
-        guard viewContext.hasChanges else { return }
+        guard viewContext.hasChanges, !holdingSaves else { return }
         if readOnly {
             viewContext.rollback()
             return
diff --git a/app/Puggle/Data/SampleFamily.swift b/app/Puggle/Data/SampleFamily.swift
index 3b10d2e..2fe9e15 100644
--- a/app/Puggle/Data/SampleFamily.swift
+++ b/app/Puggle/Data/SampleFamily.swift
@@ -25,7 +25,10 @@ final class SampleFamily: ObservableObject {
             #endif
             let sample = FamilyStore(persistence: big ? Persistence(scratch: true) : Persistence(inMemory: true))
             sample.isSample = true
+            sample.persistence.holdingSaves = true
             SampleData(store: sample).fill()
+            sample.persistence.holdingSaves = false
+            sample.persistence.save()
             sample.authorOverride = nil
             #if DEBUG
             // For checking the app with a long history, as after an import: "-debugBig 150" adds that many
diff --git a/app/Puggle/Design/PuggleView.swift b/app/Puggle/Design/PuggleView.swift
index c376319..8172e3e 100644
--- a/app/Puggle/Design/PuggleView.swift
+++ b/app/Puggle/Design/PuggleView.swift
@@ -30,10 +30,14 @@ enum PuggleRive {
 /// the view shows the still image, so the app works either way.
 @MainActor
 final class PuggleController: ObservableObject {
-    @Published var asleep = false { didSet { push() } }
+    // Each pushes only when it changes: a drag sets them on every movement, and publishing each time
+    // redrew the whole of Today's header under the finger.
+    @Published var asleep = false { didSet { if asleep != oldValue { push() } } }
     /// Her rig, drawn and moved by the app itself (Design/Rig.swift). Used whenever there is no Rive file.
     let rig: RigRuntime? = Rig.load("puggle").map(RigRuntime.init)
-    @Published var walking = false { didSet { push() } }
+    @Published var walking = false { didSet { if walking != oldValue { push() } } }
+    /// Picked up and carried by a finger.
+    @Published var held = false { didSet { if held != oldValue { push() } } }
     /// She has her bubble wand out. Anything else she is asked to do puts it away.
     @Published private(set) var makingBubbles = false
 
@@ -111,9 +115,10 @@ final class PuggleController: ObservableObject {
     }
 
     private func push() {
-        if asleep || walking { bubbles(false) }
+        if asleep || walking || held { bubbles(false) }
         rig?.asleep = asleep
         rig?.walking = walking
+        rig?.carried = held
         #if canImport(RiveRuntime)
         rive?.setInput(PuggleRive.Input.asleep, value: asleep)
         rive?.setInput(PuggleRive.Input.walking, value: walking)
diff --git a/app/Puggle/Design/Rig.swift b/app/Puggle/Design/Rig.swift
index cd3b039..9ce9d5d 100644
--- a/app/Puggle/Design/Rig.swift
+++ b/app/Puggle/Design/Rig.swift
@@ -113,10 +113,20 @@ struct Rig: Codable {
         var sx: Double?, sy: Double?
     }
 
+    /// Drawings already read, by name. Each file is read and decoded once; a portrait or a friend
+    /// appearing again takes the copy kept here.
+    nonisolated(unsafe) private static var loaded: [String: Rig] = [:]
+    private static let loadLock = NSLock()
+
     static func load(_ name: String) -> Rig? {
+        loadLock.lock()
+        defer { loadLock.unlock() }
+        if let kept = loaded[name] { return kept }
         guard let url = Bundle.main.url(forResource: "\(name).rig", withExtension: "json"),
-              let data = try? Data(contentsOf: url) else { return nil }
-        return try? JSONDecoder().decode(Rig.self, from: data)
+              let data = try? Data(contentsOf: url),
+              let rig = try? JSONDecoder().decode(Rig.self, from: data) else { return nil }
+        loaded[name] = rig
+        return rig
     }
 }
 
@@ -317,8 +327,22 @@ enum RigRenderer {
         }
     }
 
+    /// Paths already read, by their text. Every character is drawn many times a second from the same few
+    /// hundred paths, so each is read once.
+    nonisolated(unsafe) private static var read: [String: Path] = [:]
+    private static let readLock = NSLock()
+
     /// Reads "M88 166 Q120 156 152 166 L180 244 Z": absolute M, L, Q, C and Z.
     static func path(from d: String) -> Path {
+        readLock.lock()
+        defer { readLock.unlock() }
+        if let kept = read[d] { return kept }
+        let path = parse(d)
+        read[d] = path
+        return path
+    }
+
+    private static func parse(_ d: String) -> Path {
         var path = Path()
         var command: Character = "M"
         var numbers: [CGFloat] = []
@@ -448,6 +472,14 @@ final class RigRuntime {
         }
     }
 
+    /// Being carried, for as long as this is true: lifted, legs kicking.
+    var carried = false {
+        didSet {
+            guard carried != oldValue else { return }
+            if carried { play("held") } else if playing["body"]?.name == "held" { playing["body"] = nil }
+        }
+    }
+
     /// One move per track.
     private var playing: [String: (name: String, start: Date)] = [:]
     /// Her face just now, for the drawing.
diff --git a/app/Puggle/Design/Rooms.swift b/app/Puggle/Design/Rooms.swift
index 9c34c71..b342595 100644
--- a/app/Puggle/Design/Rooms.swift
+++ b/app/Puggle/Design/Rooms.swift
@@ -74,6 +74,7 @@ struct RoomFrame: View {
     var hour = 20
     var weather: Weather = .clear
     var puggleX: CGFloat = 0
+    var puggleShadow = true
     @Environment(\.lineStyle) private var lineStyle
 
     var body: some View {
@@ -81,6 +82,7 @@ struct RoomFrame: View {
         return Canvas { context, size in
             var painter = RoomPainter(context: &context, w: size.width, top: size.height - 250, dark: dark, t: t, hour: hour, weather: weather, style: style)
             painter.puggleX = puggleX
+            painter.puggleShadow = puggleShadow
             painter.paint(room)
         }
         .opacity(appeared ? 1 : 0.6)
@@ -120,6 +122,7 @@ struct RoomPainter {
     let w: CGFloat, top: CGFloat, dark: Bool, t: Double, hour: Int, weather: Weather, style: LineStyle
     /// How far Puggle stands from the middle of the room.
     var puggleX: CGFloat = 0
+    var puggleShadow = true
     /// Fireworks in the window on New Year's Eve and Bonfire Night, lights along the wall at Christmas.
     var special: SpecialDay? = SpecialDay.today
 
@@ -179,16 +182,27 @@ struct RoomPainter {
     private func walls(_ wall: Color, pattern: String, tint: Color) {
         context.fill(Path(CGRect(x: 0, y: 0, width: w, height: top + Self.floor)), with: .color(wall))
         // A quiet repeat of one brand shape, tone on tone, all the way up.
-        var row = 0
-        var y = Self.floor - 34
-        while top + y > -30 {
-            var x: CGFloat = row.isMultiple(of: 2) ? 30 : 64
-            while x < w + 20 {
-                soft(pattern, x, y, 18, tint, turn: row.isMultiple(of: 2) ? 0 : 20)
-                x += 68
+        // The whole repeat is drawn into one layer and coloured once. It was a layer for each shape, dozens
+        // of them twenty times a second, the slowest thing on Today.
+        let image = context.resolve(Image("shape-\(pattern)"))
+        let wallTop = top + Self.floor
+        context.drawLayer { layer in
+            var row = 0
+            var y = Self.floor - 34
+            while top + y > -30 {
+                var x: CGFloat = row.isMultiple(of: 2) ? 30 : 64
+                while x < w + 20 {
+                    var copy = layer
+                    copy.translateBy(x: x, y: top + y)
+                    if !row.isMultiple(of: 2) { copy.rotate(by: .degrees(20)) }
+                    copy.draw(image, in: CGRect(x: -9, y: -9, width: 18, height: 18))
+                    x += 68
+                }
+                y -= 46
+                row += 1
             }
-            y -= 46
-            row += 1
+            layer.blendMode = .sourceIn
+            layer.fill(Path(CGRect(x: 0, y: 0, width: w, height: wallTop)), with: .color(tint))
         }
         // The skirting board, then the floor in the page's own colour with a little shade by the wall.
         rect(0, Self.floor - 7, w, 7, 0, tint.opacity(dark ? 0.9 : 0.75))
@@ -201,8 +215,8 @@ struct RoomPainter {
     private func rug(_ colour: Color, _ edge: Color) {
         oval(w / 2, 228, 96, 15, edge)
         oval(w / 2, 228, 86, 11.5, colour)
-        // Her shadow on it.
-        oval(w / 2 + puggleX, 224, 36, 4.5, Palette.fixedInk.opacity(dark ? 0.3 : 0.12))
+        // Her shadow on it, unless she is being carried.
+        if puggleShadow { oval(w / 2 + puggleX, 224, 36, 4.5, Palette.fixedInk.opacity(dark ? 0.3 : 0.12)) }
     }
 
     /// A window with whatever is outside: the evening sky, or the moon and stars, and rain on the glass.
diff --git a/app/Puggle/Design/Scenes.swift b/app/Puggle/Design/Scenes.swift
index 56bf887..88caf55 100644
--- a/app/Puggle/Design/Scenes.swift
+++ b/app/Puggle/Design/Scenes.swift
@@ -43,6 +43,20 @@ enum SkyPhase {
     /// With the weather switched on it follows the real sunrise and sunset where the family is;
     /// without, it keeps to fixed hours. `exact` is nil when an hour is being forced for checking.
     static func at(hour: Int, exact: Date?) -> SkyPhase {
+        // The scene asks many times a frame; the answer only changes from one minute to the next.
+        if let exact {
+            let minute = Int(exact.timeIntervalSince1970 / 60)
+            if let kept, kept.minute == minute, kept.hour == hour { return kept.phase }
+            let phase = work(hour: hour, exact: exact)
+            kept = (minute, hour, phase)
+            return phase
+        }
+        return work(hour: hour, exact: nil)
+    }
+
+    nonisolated(unsafe) private static var kept: (minute: Int, hour: Int, phase: SkyPhase)?
+
+    private static func work(hour: Int, exact: Date?) -> SkyPhase {
         if let exact, let sun = WeatherWatch.sun(on: exact) {
             if exact < sun.rise.addingTimeInterval(-40 * 60) || exact >= sun.set.addingTimeInterval(40 * 60) { return .night }
             if exact < sun.rise.addingTimeInterval(90 * 60) { return .dawn }
@@ -81,6 +95,8 @@ struct PuggleScene: View {
     var rooms = false
     /// How far Puggle stands from the middle, so her shadow is under her.
     var puggleX: CGFloat = 0
+    /// False while she is carried: she draws her own shadow then.
+    var puggleShadow = true
     /// For pictures of each season. Nil means the season it is.
     var season: SplashLook.Season?
     @Environment(\.accessibilityReduceMotion) private var reduceMotion
@@ -93,13 +109,13 @@ struct PuggleScene: View {
         if still || reduceMotion {
             // Half a second in, so rain and snow are already falling in a still picture.
             SceneFrame(kind: kind, dark: dark, appeared: appeared, pull: pull, hourOverride: hourOverride, t: 0.5, weather: weather, rooms: rooms, puggleX: puggleX,
-                       seasonOverride: season, stillRain: reduceMotion)
+                       puggleShadow: puggleShadow, seasonOverride: season, stillRain: reduceMotion)
         } else {
             // Thirty times a second is plenty for things that drift and sway.
             TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                 SceneFrame(kind: kind, dark: dark, appeared: appeared, pull: pull, hourOverride: hourOverride,
                            t: timeline.date.timeIntervalSince(SceneClock.start), weather: weather, rooms: rooms, puggleX: puggleX,
-                           seasonOverride: season)
+                           puggleShadow: puggleShadow, seasonOverride: season)
             }
         }
     }
@@ -144,6 +160,7 @@ struct SceneFrame: View {
     var weather: Weather = .clear
     var rooms = false
     var puggleX: CGFloat = 0
+    var puggleShadow = true
     var seasonOverride: SplashLook.Season?
     /// With Reduce Motion nothing lands or drips: the scene is a still picture then.
     var stillRain = false
@@ -186,7 +203,7 @@ struct SceneFrame: View {
 
     var body: some View {
         if rooms, let room = Room.at(hour: hour, dark: dark) {
-            RoomFrame(room: room, dark: dark, appeared: appeared, pull: pull, t: t, hour: hour, weather: weather, puggleX: puggleX)
+            RoomFrame(room: room, dark: dark, appeared: appeared, pull: pull, t: t, hour: hour, weather: weather, puggleX: puggleX, puggleShadow: puggleShadow)
         } else {
             outdoors
         }
@@ -247,8 +264,10 @@ struct SceneFrame: View {
                     seasonal(w, h)
                     specialGround(w, h)
                     // Puggle's shadow, so she stands on the hill.
-                    Ellipse().fill(starry ? Color(hex: 0x15163A).opacity(0.32) : Palette.fixedInk.opacity(0.1))
-                        .frame(width: 72, height: 9).position(x: w / 2 + puggleX, y: h - 27)
+                    if puggleShadow {
+                        Ellipse().fill(starry ? Color(hex: 0x15163A).opacity(0.32) : Palette.fixedInk.opacity(0.1))
+                            .frame(width: 72, height: 9).position(x: w / 2 + puggleX, y: h - 27)
+                    }
                     friend(w, h)
                     // Drops landing on the friend, the fence, the ground and the water, and drips off edges.
                     if let strength = Rain.strength(weather), !stillRain {
diff --git a/app/Puggle/Design/SpecialDays.swift b/app/Puggle/Design/SpecialDays.swift
index 7c397ee..37db2c6 100644
--- a/app/Puggle/Design/SpecialDays.swift
+++ b/app/Puggle/Design/SpecialDays.swift
@@ -88,9 +88,16 @@ enum SpecialDay: String, CaseIterable, Identifiable {
         if let forced = defaults.string(forKey: "debugDay") { return SpecialDay(rawValue: forced) }
         #endif
         guard defaults.object(forKey: onKey) as? Bool ?? true else { return nil }
-        return on(.now, region: Locale.current.region?.identifier)
+        // Asked for by every frame of the scene, so worked out once a minute, not each time.
+        let now = Date.now
+        if let kept = Self.kept, now < kept.until { return kept.day }
+        let day = on(now, region: Locale.current.region?.identifier)
+        kept = (now.addingTimeInterval(60), day)
+        return day
     }
 
+    nonisolated(unsafe) private static var kept: (until: Date, day: SpecialDay?)?
+
     /// Fireworks in the night sky, and in the window after dark.
     var fireworks: Bool { self == .newYearsEve || self == .bonfireNight }
 }
diff --git a/app/Puggle/Features/Today/CareCard.swift b/app/Puggle/Features/Today/CareCard.swift
index 4d36f49..d05371e 100644
--- a/app/Puggle/Features/Today/CareCard.swift
+++ b/app/Puggle/Features/Today/CareCard.swift
@@ -1,3 +1,4 @@
+import CoreData
 import SwiftUI
 
 /// Looking after, on Today: one quiet card listing, for each thing the family has logged or booked, how long
@@ -9,15 +10,19 @@ struct CareCard: View {
     var onLog: (CareItem) -> Void
     var onSettings: () -> Void
 
-    /// What has been logged or booked for anyone here, in the usual order.
-    private var shown: [CareItem] {
-        store.careItems().filter { item in
-            children.contains { store.lastCare(item.key, for: $0) != nil || store.booked(item.key, for: $0) != nil }
-        }
+    /// Each child's care entries by item, worked out once per drawing of the card.
+    private typealias Index = [NSManagedObjectID: [String: (done: [Event], booked: Event?)]]
+
+    private func has(_ item: CareItem, _ child: Child, in index: Index) -> Bool {
+        guard let entry = index[child.objectID]?[item.key] else { return false }
+        return !entry.done.isEmpty || entry.booked != nil
     }
 
     var body: some View {
-        VStack(alignment: .leading, spacing: 0) {
+        let index: Index = Dictionary(uniqueKeysWithValues: children.map { ($0.objectID, store.careIndex(for: $0)) })
+        // What has been logged or booked for anyone here, in the usual order.
+        let items = store.careItems().filter { item in children.contains { has(item, $0, in: index) } }
+        return VStack(alignment: .leading, spacing: 0) {
             HStack {
                 Text("Looking after").font(.headline)
                 Spacer()
@@ -29,7 +34,6 @@ struct CareCard: View {
             }
             .padding(.horizontal, 16)
             .padding(.top, 4)
-            let items = shown
             if items.isEmpty {
                 Button { onLog(.bath) } label: {
                     HStack(spacing: 12) {
@@ -50,7 +54,7 @@ struct CareCard: View {
                 .disabled(!store.canLog)
             } else {
                 ForEach(items) { item in
-                    row(item)
+                    row(item, index)
                     if item.id != items.last?.id {
                         Divider().padding(.leading, 54)
                     }
@@ -62,14 +66,14 @@ struct CareCard: View {
         .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
     }
 
-    private func row(_ item: CareItem) -> some View {
+    private func row(_ item: CareItem, _ index: Index) -> some View {
         Button { onLog(item) } label: {
             HStack(alignment: .top, spacing: 12) {
                 item.image().frame(width: 26, height: 26).padding(.top, 2)
                 VStack(alignment: .leading, spacing: 3) {
                     Text(item.name).fontWeight(.semibold)
-                    ForEach(children.filter { store.lastCare(item.key, for: $0) != nil || store.booked(item.key, for: $0) != nil }) { child in
-                        line(item, child)
+                    ForEach(children.filter { has(item, $0, in: index) }) { child in
+                        line(item, child, index[child.objectID]?[item.key] ?? ([], nil))
                     }
                 }
                 Spacer(minLength: 0)
@@ -84,9 +88,9 @@ struct CareCard: View {
     }
 
     /// One child's line: "Bea · 9 days ago", with the soft mark if it has been a while, or the booking.
-    @ViewBuilder private func line(_ item: CareItem, _ child: Child) -> some View {
+    @ViewBuilder private func line(_ item: CareItem, _ child: Child, _ entry: (done: [Event], booked: Event?)) -> some View {
         let who = children.count > 1 ? "\(child.displayName) · " : ""
-        if let visit = store.booked(item.key, for: child), let at = visit.startedAt {
+        if let visit = entry.booked, let at = visit.startedAt {
             HStack(spacing: 8) {
                 Text(who + CareLine.booked(at)).font(.subheadline).foregroundStyle(Palette.muted)
                 if store.canLog {
@@ -101,14 +105,14 @@ struct CareCard: View {
                     .accessibilityLabel("Mark \(item.name.lowercased()) for \(child.displayName) as done")
                 }
             }
-        } else if let last = store.lastCare(item.key, for: child)?.startedAt {
-            let gap = store.careGap(item, for: child)
+        } else if let last = entry.done.last?.startedAt {
+            let gap = store.careGap(item, for: child, done: entry.done)
             let pastUsual = CareLine.pastUsual(last: last, gap: gap)
             HStack(spacing: 6) {
                 if pastUsual {
                     Circle().fill(Palette.wattle).frame(width: 7, height: 7)
                 }
-                Text(who + text(item, child, last: last)).font(.subheadline).foregroundStyle(Palette.muted)
+                Text(who + text(item, entry.done, last: last)).font(.subheadline).foregroundStyle(Palette.muted)
                 if pastUsual, let gap {
                     Text("· usually \(gap.text.lowercased())").font(.footnote).foregroundStyle(Palette.muted)
                 }
@@ -118,9 +122,9 @@ struct CareCard: View {
     }
 
     /// For brushing, today's count ("Twice today"); for the rest, how long since.
-    private func text(_ item: CareItem, _ child: Child, last: Date) -> String {
+    private func text(_ item: CareItem, _ done: [Event], last: Date) -> String {
         if item.key == CareItem.brushing.key {
-            let today = store.careDone(item.key, for: child).filter { Calendar.current.isDateInToday($0.startedAt ?? .distantPast) }.count
+            let today = done.filter { Calendar.current.isDateInToday($0.startedAt ?? .distantPast) }.count
             switch today {
             case 0: break
             case 1: return "Once today"
diff --git a/app/Puggle/Features/Today/Tiles.swift b/app/Puggle/Features/Today/Tiles.swift
index 3f507a9..3f54874 100644
--- a/app/Puggle/Features/Today/Tiles.swift
+++ b/app/Puggle/Features/Today/Tiles.swift
@@ -361,7 +361,10 @@ struct PuggleHeader: View {
     @State private var tilt: Double = 0
     /// Where she has been walked to, in points from the middle. Nil until she is moved: she starts a little to one side.
     @State private var walkedTo: CGFloat?
-    @State private var walkStart: CGFloat?
+    /// Where she is while being carried. Read only by her own view, so a drag moves her and nothing else.
+    @State private var carry = Carry()
+    /// True while a finger is carrying her: the scene leaves out her shadow and she draws her own.
+    @State private var holding = false
     /// True for a moment after a walk, so letting go of her is not taken for a tap.
     @State private var justWalked = false
     @State private var lastTap: Date?
@@ -471,68 +474,34 @@ struct PuggleHeader: View {
         let x = canWalk ? min(max(walkedTo ?? home, -reach), reach) : 0
         // In the backyard on a fine day she gets her bubble wand out now and then.
         let fine = ["none", "sun"].contains(weather.outfit(night: false))
-        let canBubble = room == nil && SceneKind.today == .backyard && !PuggleScene.isNight(dark: dim) && fine && !quiet && !reduceMotion && appeared
+        // Asked once here: working it out means drawing a frame of the scene.
+        let isNight = PuggleScene.isNight(dark: dim)
+        let canBubble = room == nil && SceneKind.today == .backyard && !isNight && fine && !quiet && !reduceMotion && appeared && !holding
         return ZStack(alignment: .bottom) {
-            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x)
+            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x, puggleShadow: !holding)
             // Whoever is with her today stands behind her, on the same ground.
             if let company = Company.today(kind: .today, room: room,
-                                           afterDark: room == nil && (PuggleScene.isNight(dark: dim) || Room.hourNow >= 18)) {
+                                           afterDark: room == nil && (isNight || Room.hourNow >= 18)) {
                 // Dressed for the weather when they are out in it, as she is.
-                let wearing = room == nil ? weather.outfit(night: PuggleScene.isNight(dark: dim)) : "none"
+                let wearing = room == nil ? weather.outfit(night: isNight) : "none"
                 CompanyView(company: company, puggleReacted: reactions, quiet: quiet, appeared: appeared, dark: dim, rain: wearing == "rain",
-                            weather: room == nil ? weather : nil, night: PuggleScene.isNight(dark: dim))
-                    .environment(\.moonlit, room == nil && PuggleScene.isNight(dark: dim))
+                            weather: room == nil ? weather : nil, night: isNight)
+                    .environment(\.moonlit, room == nil && isNight)
                     .environment(\.outfit, wearing)
                     .environment(\.shades, Shades.forOutfit(wearing))
                     .offset(x: company.x * width)
                     .padding(.bottom, 26)
                     .id("\(company.member.rawValue)-\(wearing)")
             }
-            Button {
-                if justWalked { justWalked = false } else {
-                    // The first tap in a while takes her by surprise: she is shy for a moment, then herself.
-                    let first = lastTap.map { Date.now.timeIntervalSince($0) > 600 } ?? true
-                    lastTap = .now
-                    if first { controller.rig?.feel(.shy, for: 1.3) } else { react() }
-                    reactions += 1
-                }
-            } label: {
-                PuggleView(controller: controller)
-                    .environment(\.moonlit, room == nil && PuggleScene.isNight(dark: dim))
-                    .environment(\.outfit, room?.outfit ?? weather.outfit(night: PuggleScene.isNight(dark: dim)))
-                    .environment(\.shades, Shades.forOutfit(room?.outfit ?? weather.outfit(night: PuggleScene.isNight(dark: dim))))
-                    .environment(\.warmLight, room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: PuggleScene.isNight(dark: dim)))
-                    .frame(height: 118)
-                    .scaleEffect(x: 1, y: 1 - nod * 0.06, anchor: .bottom)
-                    .offset(y: lift + nod * 3)
-                    .rotationEffect(.degrees(tilt), anchor: .bottom)
-            }
-            .buttonStyle(.plain)
-            // Drag her sideways and she walks there, and stays.
-            .simultaneousGesture(DragGesture(minimumDistance: 12)
-                .onChanged { drag in
-                    guard canWalk, walkStart != nil || abs(drag.translation.width) > abs(drag.translation.height) else { return }
-                    if walkStart == nil { walkStart = x }
-                    justWalked = true
-                    walkedTo = min(max((walkStart ?? 0) + drag.translation.width, -reach), reach)
-                    if !quiet && !reduceMotion { controller.walking = true }
-                }
-                .onEnded { _ in
-                    guard walkStart != nil else { return }
-                    walkStart = nil
-                    controller.walking = false
-                    Haptics.tap()
-                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { justWalked = false }
-                })
-            .offset(x: x)
-            // She pops up from behind the hill when Today first opens.
-            .offset(y: appeared ? 0 : 60)
-            .opacity(appeared ? 1 : 0)
-            .padding(.bottom, 26)
-            .accessibilityLabel(quiet ? "Puggle, being quiet" : "Puggle")
-            .accessibilityHint("Says hello")
-            .accessibilityAction(named: "Walk left") { if canWalk { walkedTo = max(x - 60, -reach) } }
-            .accessibilityAction(named: "Walk right") { if canWalk { walkedTo = min(x + 60, reach) } }
+            CarriedPuggle(controller: controller, carry: carry, restX: x, reach: reach, canWalk: canWalk, quiet: quiet,
+                          holding: $holding, justWalked: $justWalked, shadowNight: room == nil && isNight,
+                          outfit: room?.outfit ?? weather.outfit(night: isNight),
+                          warmLight: room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: isNight),
+                          lift: lift, tilt: tilt, nod: nod, onTap: tapped, onPutDown: { walkedTo = $0; land() })
+                // She pops up from behind the hill when Today first opens.
+                .offset(y: appeared ? 0 : 60)
+                .opacity(appeared ? 1 : 0)
+                .padding(.bottom, 26)
             // Her bubbles, rising from the wand in her right hand. Only while she is making them.
             TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !controller.makingBubbles)) { timeline in
                 Bubbles(t: timeline.date.timeIntervalSince(SceneClock.start), margin: 20)
@@ -555,8 +524,8 @@ struct PuggleHeader: View {
                 }
             }
             // Out in the rain: the nearest drops in front of her, pops on her hat and shoulders, drips off her brim.
-            if room == nil {
-                PuggleRain(weather: weather, night: PuggleScene.isNight(dark: dim), puggleX: x)
+            if room == nil, !holding {
+                PuggleRain(weather: weather, night: isNight, puggleX: x)
                     .opacity(appeared ? 1 : 0)
             }
             // The tea table stands in front of her.
@@ -581,7 +550,8 @@ struct PuggleHeader: View {
     private func pulled(to amount: CGFloat) {
         pull = amount
         // While the sky is being pulled down she walks on the spot.
-        controller.walking = amount > 24 && !quiet
+        let walk = amount > 24 && !quiet
+        if controller.walking != walk { controller.walking = walk }
         if amount > furthest { furthest = amount }
         if amount < 4 {
             if furthest > 120 { react() }
@@ -589,6 +559,24 @@ struct PuggleHeader: View {
         }
     }
 
+    private func tapped() {
+        if justWalked { justWalked = false; return }
+        // The first tap in a while takes her by surprise: she is shy for a moment, then herself.
+        let first = lastTap.map { Date.now.timeIntervalSince($0) > 600 } ?? true
+        lastTap = .now
+        if first { controller.rig?.feel(.shy, for: 1.3) } else { react() }
+        reactions += 1
+    }
+
+    /// Put down: she lands with a little squash and a wag.
+    private func land() {
+        Haptics.tap()
+        guard !reduceMotion else { return }
+        controller.rig?.play("wag")
+        withAnimation(.easeOut(duration: 0.08)) { nod = quiet ? 0.5 : 1 }
+        withAnimation(.spring(duration: 0.35, bounce: 0.35).delay(0.08)) { nod = 0 }
+    }
+
     private func react() {
         // In the rain a tap is a jump in her puddle.
         if weather.outfit == "rain", let rig = controller.rig, !quiet, !reduceMotion {
@@ -613,6 +601,116 @@ struct PuggleHeader: View {
     }
 }
 
+/// Where Puggle is while a finger carries her, and how far she swings. Watched only by `CarriedPuggle`.
+@Observable final class Carry {
+    var x: CGFloat?
+    var start: CGFloat?
+    var sway: Double = 0
+    @ObservationIgnored var settle: Task<Void, Never>?
+}
+
+/// Puggle on Today. Tap her and she answers; pick her up and carry her sideways and she is lifted off the
+/// ground, legs kicking, swinging a little behind the finger, then lands where she is put down. Only this
+/// view follows the finger, so a drag never redraws the scene behind her.
+private struct CarriedPuggle: View {
+    @ObservedObject var controller: PuggleController
+    let carry: Carry
+    let restX: CGFloat
+    let reach: CGFloat
+    let canWalk: Bool
+    let quiet: Bool
+    @Binding var holding: Bool
+    @Binding var justWalked: Bool
+    let shadowNight: Bool
+    let outfit: String
+    let warmLight: UnitPoint?
+    let lift: CGFloat
+    let tilt: Double
+    let nod: CGFloat
+    let onTap: () -> Void
+    let onPutDown: (CGFloat) -> Void
+    @Environment(\.accessibilityReduceMotion) private var reduceMotion
+
+    var body: some View {
+        let x = carry.x ?? restX
+        let up = holding && !reduceMotion
+        ZStack(alignment: .bottom) {
+            // Her shadow stays on the ground while she is up, smaller and fainter.
+            if holding {
+                Ellipse().fill(shadowNight ? Color(hex: 0x15163A).opacity(0.2) : Palette.fixedInk.opacity(0.06))
+                    .frame(width: 48, height: 7)
+                    .offset(y: 3.5)
+                    .transition(.opacity)
+            }
+            Button(action: onTap) {
+                PuggleView(controller: controller)
+                    .environment(\.moonlit, shadowNight)
+                    .environment(\.outfit, outfit)
+                    .environment(\.shades, Shades.forOutfit(outfit))
+                    .environment(\.warmLight, warmLight)
+                    .frame(height: 118)
+                    // Held up, she hangs a little longer; put down, she squashes as she lands.
+                    .scaleEffect(x: up ? 0.97 : 1, y: (1 - nod * 0.06) * (up ? 1.04 : 1), anchor: .bottom)
+                    .offset(y: lift + nod * 3 + (up ? -26 : 0))
+                    .rotationEffect(.degrees(tilt), anchor: .bottom)
+                    // She hangs from the finger, so she swings from the top.
+                    .rotationEffect(.degrees(carry.sway), anchor: .top)
+                    .animation(.spring(duration: 0.32, bounce: 0.25), value: up)
+                    .animation(.spring(response: 0.5, dampingFraction: 0.42), value: carry.sway)
+            }
+            // Not dimmed while pressed: she is held for as long as she is carried, and stays herself.
+            .buttonStyle(Undimmed())
+            .simultaneousGesture(carrying)
+        }
+        .offset(x: x)
+        .accessibilityElement(children: .combine)
+        .accessibilityLabel(quiet ? "Puggle, being quiet" : "Puggle")
+        .accessibilityHint("Says hello")
+        .accessibilityAction(named: "Walk left") { if canWalk { onPutDown(max(x - 60, -reach)) } }
+        .accessibilityAction(named: "Walk right") { if canWalk { onPutDown(min(x + 60, reach)) } }
+    }
+
+    private var carrying: some Gesture {
+        DragGesture(minimumDistance: 12)
+            .onChanged { drag in
+                guard canWalk, carry.start != nil || abs(drag.translation.width) > abs(drag.translation.height) else { return }
+                if carry.start == nil {
+                    carry.start = restX
+                    justWalked = true
+                    withAnimation(.easeOut(duration: 0.2)) { holding = true }
+                    controller.held = true
+                    Haptics.tap()
+                }
+                carry.x = min(max((carry.start ?? 0) + drag.translation.width, -reach), reach)
+                guard !reduceMotion else { return }
+                // She swings behind the finger, more the faster it goes, and back to hanging straight when it stops.
+                carry.sway = Double(min(max(drag.velocity.width / 70, -14), 14))
+                carry.settle?.cancel()
+                carry.settle = Task { @MainActor in
+                    try? await Task.sleep(for: .milliseconds(90))
+                    if !Task.isCancelled { carry.sway = 0 }
+                }
+            }
+            .onEnded { _ in
+                guard carry.start != nil else { return }
+                let at = carry.x ?? restX
+                carry.settle?.cancel()
+                carry.start = nil
+                carry.sway = 0
+                controller.held = false
+                holding = false
+                onPutDown(at)
+                carry.x = nil
+                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { justWalked = false }
+            }
+    }
+}
+
+/// A button that shows no pressed look of its own.
+private struct Undimmed: ButtonStyle {
+    func makeBody(configuration: Configuration) -> some View { configuration.label.contentShape(Rectangle()) }
+}
+
 /// Your photo (or initial), top right of Today. Opens the "You" sheet.
 struct YouButton: View {
     let action: () -> Void
diff --git a/app/Puggle/Features/Today/TodayView.swift b/app/Puggle/Features/Today/TodayView.swift
index 7dfc7a4..39c2bd9 100644
--- a/app/Puggle/Features/Today/TodayView.swift
+++ b/app/Puggle/Features/Today/TodayView.swift
@@ -29,8 +29,9 @@ struct TodayView: View {
     @State private var editing: EditTarget?
     /// An entry opened to read, from Today so far.
     @State private var looking: EditTarget?
-    /// How far Today has scrolled up, for the soft edge under the clock.
-    @State private var scrolledUp: CGFloat = 0
+    /// How far Today has scrolled up, for the soft edge under the clock. Kept outside Today's own state and
+    /// read only by the edge, so scrolling redraws the edge and not the whole page on every frame.
+    @State private var scroll = ScrollDepth()
     @State private var dayOf: Child?
     @State private var addingChild = false
     /// True once this phone has ever shown a child, so an empty Today is never the cheerful first-time one again.
@@ -101,7 +102,7 @@ struct TodayView: View {
                     header
                         .background(GeometryReader { geometry in
                             Color.clear.onChange(of: geometry.frame(in: .named("todayScroll")).minY) { _, y in
-                                scrolledUp = max(-y, 0)
+                                scroll.up = max(-y, 0)
                             }
                         })
                     SampleBanner()
@@ -150,7 +151,7 @@ struct TodayView: View {
             .ignoresSafeArea(edges: .top)
             // Only once the cards reach the clock; over the sky it isn't needed.
             .overlay(alignment: .top) {
-                TopScrim(strength: Double(min(max((scrolledUp - PuggleHeader.sceneHeight + 110) / 60, 0), 1)))
+                ScrollScrim(scroll: scroll)
             }
             .toolbar(.hidden, for: .navigationBar)
             // Floats above the tab bar, so saving never moves the tile under your thumb.
@@ -489,6 +490,19 @@ struct TodayView: View {
 
 /// One row per child: who is asleep, or what happened last. Tapping the row
 /// shows their day so far; the button starts and stops their sleep.
+/// How far Today has scrolled. Only the views that read `up` are redrawn when it changes.
+@Observable final class ScrollDepth {
+    var up: CGFloat = 0
+}
+
+/// The soft edge under the clock, once the cards reach it; over the sky it isn't needed.
+private struct ScrollScrim: View {
+    let scroll: ScrollDepth
+    var body: some View {
+        TopScrim(strength: Double(min(max((scroll.up - PuggleHeader.sceneHeight + 110) / 60, 0), 1)))
+    }
+}
+
 struct ChildStatusRow: View {
     @EnvironmentObject private var store: FamilyStore
     @ObservedObject var child: Child
diff --git a/app/Puggle/Resources/Rigs/puggle.rig.json b/app/Puggle/Resources/Rigs/puggle.rig.json
index 640b052..fdeb880 100644
--- a/app/Puggle/Resources/Rigs/puggle.rig.json
+++ b/app/Puggle/Resources/Rigs/puggle.rig.json
@@ -5496,6 +5496,219 @@
      }
     }
    ]
+  },
+  "held": {
+   "about": "Picked up and carried: lifted under her arms, legs kicking in turn, tail swinging, delighted. Goes round until she is put down.",
+   "loops": true,
+   "length": 0.9,
+   "keys": [
+    {
+     "t": 0,
+     "pose": {
+      "arm-left": {
+       "r": 36
+      },
+      "forearm-left": {
+       "r": 44
+      },
+      "arm-right": {
+       "r": -36
+      },
+      "forearm-right": {
+       "r": -44
+      },
+      "upper": {
+       "sy": 1.03
+      },
+      "blush": {
+       "sx": 1.12,
+       "sy": 1.12
+      },
+      "brow-left": {
+       "y": -4,
+       "r": -6
+      },
+      "brow-right": {
+       "y": -4,
+       "r": 6
+      },
+      "leg-left": {
+       "r": 0,
+       "y": 3
+      },
+      "leg-right": {
+       "r": 0,
+       "y": 3
+      },
+      "tail": {
+       "r": 14
+      },
+      "head": {
+       "r": -3
+      }
+     },
+     "face": {
+      "eyes": "happy",
+      "brows": "on"
+     }
+    },
+    {
+     "t": 0.22,
+     "pose": {
+      "arm-left": {
+       "r": 36
+      },
+      "forearm-left": {
+       "r": 44
+      },
+      "arm-right": {
+       "r": -36
+      },
+      "forearm-right": {
+       "r": -44
+      },
+      "upper": {
+       "sy": 1.03
+      },
+      "blush": {
+       "sx": 1.12,
+       "sy": 1.12
+      },
+      "brow-left": {
+       "y": -4,
+       "r": -6
+      },
+      "brow-right": {
+       "y": -4,
+       "r": 6
+      },
+      "leg-left": {
+       "r": -20.4,
+       "y": 1
+      },
+      "foot-left": {
+       "r": -30.0
+      },
+      "leg-right": {
+       "r": 0,
+       "y": 3
+      },
+      "tail": {
+       "r": -6
+      },
+      "head": {
+       "r": 1
+      }
+     },
+     "face": {
+      "eyes": "happy",
+      "brows": "on"
+     }
+    },
+    {
+     "t": 0.45,
+     "pose": {
+      "arm-left": {
+       "r": 36
+      },
+      "forearm-left": {
+       "r": 44
+      },
+      "arm-right": {
+       "r": -36
+      },
+      "forearm-right": {
+       "r": -44
+      },
+      "upper": {
+       "sy": 1.03
+      },
+      "blush": {
+       "sx": 1.12,
+       "sy": 1.12
+      },
+      "brow-left": {
+       "y": -4,
+       "r": -6
+      },
+      "brow-right": {
+       "y": -4,
+       "r": 6
+      },
+      "leg-left": {
+       "r": 0,
+       "y": 3
+      },
+      "leg-right": {
+       "r": 0,
+       "y": 3
+      },
+      "tail": {
+       "r": -14
+      },
+      "head": {
+       "r": 3
+      }
+     },
+     "face": {
+      "eyes": "happy",
+      "brows": "on"
+     }
+    },
+    {
+     "t": 0.67,
+     "pose": {
+      "arm-left": {
+       "r": 36
+      },
+      "forearm-left": {
+       "r": 44
+      },
+      "arm-right": {
+       "r": -36
+      },
+      "forearm-right": {
+       "r": -44
+      },
+      "upper": {
+       "sy": 1.03
+      },
+      "blush": {
+       "sx": 1.12,
+       "sy": 1.12
+      },
+      "brow-left": {
+       "y": -4,
+       "r": -6
+      },
+      "brow-right": {
+       "y": -4,
+       "r": 6
+      },
+      "leg-right": {
+       "r": 20.4,
+       "y": 1
+      },
+      "foot-right": {
+       "r": 30.0
+      },
+      "leg-left": {
+       "r": 0,
+       "y": 3
+      },
+      "tail": {
+       "r": 6
+      },
+      "head": {
+       "r": -1
+      }
+     },
+     "face": {
+      "eyes": "happy",
+      "brows": "on"
+     }
+    }
+   ]
   }
  },
  "face": {
@@ -5507,4 +5720,4 @@
   "shades": "none"
  },
  "sideroom": 30
-}
\ No newline at end of file
+}
```
