# Rebuild brief 3 of the lost Mac commits: `3504179` "entrance animation, tea with the family, bedtime following the children, sleepovers"

**Where it sits.** `4be0423` (last pushed, branch `claude/baby-tracking-app-spec-fhtvex` of `tomgarton/hello-world`) → `6263eba` (speed pass + "held" carry animation, briefed separately; rebuild that FIRST) → **`3504179` (this one)**. Neither unpushed commit exists anywhere except Tom's unreachable Mac.

**Source.** An extract of the Mac session's transcript (USER/ASSISTANT messages, WRITE blocks, BASH commands; most edits were `python3` heredoc scripts doing `str.replace` / slice-replace, a few `sed -i ''`). Timestamps below are 19 Nov 2026 (UTC) from that transcript.

**How the code below was recovered.** I replayed every WRITE and every python/sed edit from the transcript, in order, onto the `4be0423` versions of the files (in a scratch copy, not the repo). Every edit to `Design/Cast.swift`, `Design/Rooms.swift`, `Features/Today/TodayView.swift`, `Design/Evening.swift`, `Design/Arrival.swift` applied cleanly to `4be0423`, so the diffs for those files in section 3 are the exact net result of the session's edits (assuming `6263eba` didn't touch those same lines; it didn't touch any anchor these edits use). `Features/Today/Tiles.swift` is different: several anchors only exist after `6263eba` (the `CarriedPuggle` view, `holding`, `isNight`, `land()`, `carry.sway`). For those, I put the anchor text the scripts expected in place and replayed onto it, so the Tiles diff is exact for every line the session wrote, but the surrounding `6263eba` context lines are shown as they appear in the scripts' search strings, not as the real file. Those hunks are marked.

**UPDATE (second pass):** all edits were replayed in order onto the scratch checkout `rework/wt` (4be0423 + reconstructed 6263eba + the later scripted commits). Everything matched, Tiles.swift included. The full commit is now in `rework/3-3504179-reconstructed.patch` (8 files: 3 new, 5 modified); `git apply --whitespace=error` applies it cleanly to the pre-edit tree, and the result is byte-identical to `rework/wt`. Section 3.6 now shows the real Tiles diff.

---

## 1. What Tom asked for, and what he decided

### Tom's messages (verbatim)

02:19:39, after the 6263eba summary:
> I feel like the entering animation for the characters could be improved. What would you suggest? I also feel like Puggle should go to sleep in bed when she's in her bedroom at night; how else would you handle this with the other characters/parents/grandparents

02:30:13, after the assistant's proposal (entrance: weight, stagger, arrive to suit the place, scale to how recently you were here; bed: reading / asleep / stirring / morning stretch / touch; friends sleepover vs gone home; Mum/Dad story; Nan/Pop babysitting in an armchair; late night alone):
> For the entrance, should they also move in from only the left or right? Sleepovers sometimes sounds good.
>
> Bedtime should follow the real children's sleep or what would be acceptable for children and their age.
>
> Puggle eating alone at the dinner table is also weird, it should be the whole family eating at the table etc.

02:31:59, after the assistant's answer (quoted below), which ended "do you want all four changes ..., or should I start with weight and staggering?":
> That sounds good

(The assistant took this as "all four changes" and said: "I'll build all of it in stages: the entrance first, then tea time, then bedtime and sleepovers." In practice it built evening/tea/bedtime first, then the entrance, and made one commit.)

02:45:07, mid-build:
> I also just noticed that the start sleep is missing for [the toddler]

**Not addressed in this commit; it was fixed in the next one, aeccd5f (patch 0004: the sleep button for any child under four).** Nothing in the transcript for 3504179 responds to it or changes code for it. Treat it as an open bug report ([the toddler] is presumably one of Tom's real children in the sample/real family; "start sleep" is probably the Start-sleep quick action on Today missing for that child). Ask Tom or check whether a later commit dealt with it.

The other USER entries (02:47:08, 02:47:23, 02:48:47, 02:49:34, 03:10:53, 03:17:12 ×2, 03:19:29, 03:22:49 ×2, 03:24:52, 03:29:45, 03:33:05, 03:35:55, 03:42:32 ×2) are only `[Image: ...]` placeholders. From their timing they are almost certainly the session viewing its own screenshots / contact sheets (tool-result images show up as user turns), not messages from Tom. Their content is not recoverable; what the session changed after each is described in section 5.

### The assistant's answer at 02:30:41, which Tom accepted with "That sounds good" (verbatim; this is the agreed design)

> **Should they come in from the left or right?** Sometimes, not always, and never both from the same side.
>
> - **Each character comes from the edge nearest where they'll stand.** The friend stands to one side of Puggle, so they come from that side and their paths never cross. Two characters walking in from the same side looks like a queue.
> - **Indoors, they walk in from the door's side of the room.** Each room keeps its door on one side, so it's always the same in that room.
> - **Outdoors, they mostly pop up from behind the hill.** About one day in four, one of them walks in along the ground instead, so it isn't the same every time.
> - **Walking in is only for the first full entrance of the day.** Today opens many times a day, and a long walk-on would get slow. Coming back within a few minutes, she's already there.
>
> **Bedtime.** Puggle goes to sleep when the real children are all asleep. If no sleep has been logged, she goes at a usual bedtime for the oldest child's age: about 7pm for babies, 7 to 7:30pm for toddlers, 7:30 to 8pm for four-to-sixes. For half an hour before that she sits up in bed reading. If you log a night feed or nappy, she sits up sleepily, then settles again.
>
> **Sleepovers sometimes.** About one evening in five, a friend comes for tea, stays, and sleeps in a sleeping bag beside her bed. On other nights she's on her own, with a grown-up for the story.
>
> **Tea time.** Agreed, eating alone is sad. I'd seat her family round the table:
>
> - **Every evening:** Mum and Dad, one either side of her.
> - **Some evenings:** Nan and Pop too.
> - **Sleepover nights:** the friend sits at the table, then goes up to bed with her.
>
> The table only fits about four characters at phone width, so the most at once would be Puggle plus three.
>
> This is Puggle's own family, not a copy of yours. Matching her family to your real grown-ups would mean guessing who's who, and I'd rather not.
>
> **The bed needs new drawing work.** Her rig is drawn standing, so lying down needs something new. I'd show her tucked under the quilt with only her head on the pillow, plus a sitting-up pose for reading. Both use her existing head and arms.

### Relevant parts of the earlier proposal (02:20:13) that the build also followed

- Entrance: "Give it weight" (crouch before rising, stretch on the way up, squash on landing); "Stagger them" (friend first, Puggle about a fifth of a second later, then she glances over); "Arrive to suit the place" (outdoors pop up from behind the hill; indoors walk in from the side); "Scale it to how recently you were here" (full entrance first time; back within a few minutes she's already there and just blinks and looks up); "With Reduce Motion on, it's a simple fade."
- Night company: Mum or Dad read a bedtime story then leave once she's asleep; Nan or Pop babysit in an armchair by the lamp and doze off; late night (after about 10pm) just Puggle asleep (plus any sleepover friend).
- Not built (were only suggestions): per-friend entrances (digger digging up), "strip of light under the door", night light change, tap-in-bed one-eye-open behaviour, sleepy roll-over instead of carrying, daytime naps outdoors, "walk in from the door's side of the room" (built instead as "from the nearest screen edge", see below), morning stretch on "Woke up" (only the existing `quiet`→`wake()` path, and `stirring` plays the `wake` move).

### Decisions as built (differences from the proposal in **bold**)

| Topic | Decision |
|---|---|
| Entrance sides | Each character walks in from the screen edge nearest where they'll stand. **With a companion present, Puggle comes from the opposite side to the first companion, so the two walk towards each other.** Indoors (standing) always walk. Outdoors: rise from behind the hill, except **one day in four (`day % 4 == 3`) walk**. Seated (table) or in bed: fade in place. Back within **20 minutes**: no entrance; a blink and she looks up. Reduce Motion: fade. |
| Stagger | Companions start at `beat (0.2s) + order*0.15s`; Puggle at `beat + 0.2s` if anyone's there. She glances at the first companion ~1.8s after the entrance starts (outdoors / tea / bedroom-reading only). |
| Sleepovers | One evening in five: day index (day-of-era computed from now − 6h, so the "evening" runs past midnight) `% 5 == 2`; friend cycles through kip, quill, digby, sunny, pebble. A sleepover friend joins tea and is in a sleeping bag in the bedroom (sitting up while she reads, tucked in asleep when she sleeps). **No "out after dark" walk on a sleepover night.** |
| Bedtime rule | If any child has an active sleep or woke in the last 2 days → follow logs: asleep when all children are asleep (even straight after tea, from 18:30); otherwise reading in the evening / "stirring" at night (before 06:00 or from 22:00). No logs → by oldest child's age: <12 months 19:00, <36 months 19:15, <72 months 19:45, else 20:00; reads for 30 min before. In bedroom from wind-down until 06:00. Within 8 minutes after anything is logged at night → stirring. |
| Tea | Room `.dining` is still hour 18 only. Mum (x −0.3) and Dad (x +0.3) every evening, Puggle in the middle. Guest: the sleepover friend, else Nan or Pop on `day % 3 == 1` (Nan on even days, Pop on odd). With a guest: Mum −0.36, guest +0.12, Dad +0.36, Puggle −0.12. Table spans the room, cloth to the floor, a plate and cup per person. |
| Bedtime company | Grown-up rotates `[.mum, .dad, .nan, .pop][day % 4]` (same −6h day). Reading (or `.up`): grown-up in the armchair (x 0.34). Asleep: Mum/Dad leave; Nan/Pop stay dozing in the armchair until 22:00. Late (22:00–06:00): only Puggle and any sleepover friend. |
| Lying down | **Tried and dropped**: rotating characters −90° to lie down made front-drawn faces unreadable. Everyone (Puggle and the sleepover friend) stays upright, "tucked in" with a quilt/bag up to the chin. Rig-drawn Zs are left as they are (the room's own drawn Zs were removed). |
| Family identity | Puggle's own cast family (Mum, Dad, Nan, Pop), not mapped to Tom's real grown-ups. |

---

## 2. Intended behaviour as finally built

There is **no final summary message after the commit** in the extract: the last assistant messages are "Everyone ends up where they belong outdoors, at tea, at bedtime with a grown-up in the armchair, and late at night. Running the tests next.", "All 133 pass. I'm adding tests for the new bedtime rules, then the spec section.", and "137 pass. Committing." The commit message and the spec section are the authoritative description.

### Commit message (verbatim)

```
Tea with the family, bedtime that follows the children, sleepovers, and a weighted entrance

Puggle eats at the table with Mum, Dad and sometimes a guest. In her bedroom she reads, then
sleeps, following logged sleep or a usual bedtime for the oldest child's age, and stirs when a
child is seen to in the night. A grown-up reads from the armchair; one evening in five a friend
sleeps over. Everyone arrives one after another: rising from behind the hill with a crouch,
stretch and squash, or walking in from the nearest edge, or fading in when seated; a quick
return skips the entrance.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

(Use the current attribution trailer for the rebuilt commit, per the session's own instructions.)

Files committed: `app/Puggle/Design/Cast.swift`, `app/Puggle/Design/Rooms.swift`, `app/Puggle/Features/Today/Tiles.swift`, `app/Puggle/Features/Today/TodayView.swift`, `docs/baby-tracker-spec.md`, new `app/Puggle/Design/Arrival.swift`, new `app/Puggle/Design/Evening.swift`, new `app/PuggleTests/EveningTests.swift`. (`Design/Rig.swift` was edited and then fully reverted, so it is not in the commit. `*.xcodeproj` is git-ignored; it's regenerated with xcodegen.)

### Spec section appended to `docs/baby-tracker-spec.md` (verbatim, appended with `cat >>` after the existing last line, which in 6263eba is that commit's own spec note)

```markdown

## Tea, bedtime, sleepovers and the entrance (19 November 2026)

Tom asked for Puggle to go to bed in her bedroom at night, for her not to eat alone at the tea table, for
bedtime to follow the real children, for sleepovers now and then, and for a better entrance.

**Tea with the family.** At tea time Puggle sits at the table between Mum and Dad, each with a plate and a cup,
her bowl steaming. Some days a guest joins: Nan or Pop one day in three, or the friend sleeping over. The
table runs the width of the room and its cloth hides everyone's feet.

**Bedtime follows the children.** If the family has logged a sleep in the last two days, Puggle follows the
logs: she reads in bed while any child is still up, and sleeps once they all are, even straight after tea. If
not, she follows a usual bedtime for the oldest child's age: about 19:00 for a baby, 19:15 under three, 19:45
under six, 20:00 after that. She reads in bed for the half hour before. In the night, for a few minutes after
something is logged for a child, she sits up, sleepy, then settles again. Asleep, she is tucked in with the
quilt to her chin and her rabbit beside her, upright like everyone in the cast, since their faces are drawn
from the front.

**Night company.** While she reads, a grown-up sits in the armchair (Mum, Dad, Nan or Pop, in turn). Once she is
asleep, Mum and Dad leave; Nan or Pop dozes in the chair until late. One evening in five a friend comes for tea
and stays the night, in a sleeping bag on the floor: sitting up while she reads, asleep when she is.

**The entrance.** Everyone arrives with weight now, one after another: whoever is with her first, Puggle a
moment later, then she glances over at them.
- Outdoors they mostly come up from behind the hill: a crouch, a stretch on the way up, a squash as they land.
  One day in four they walk in along the ground instead.
- Indoors, standing, they walk in, each from the edge of the screen nearest where they will stand. With a
  friend there, Puggle comes from the other side, so the two walk towards each other.
- Sat at the table or in bed, they fade in where they are.
- Back within twenty minutes, she is already there: a blink, and she looks up.
- With Reduce Motion, everyone fades in.

For checking, in the Developer launch arguments: `-debugArrive walk` or `rise` (and every return plays the full
entrance), `-debugBed reading|asleep|stirring|up`, `-debugSleepover kip|none`, `-debugTea nan|none`,
`-debugMinute`.

Not yet checked on a phone: the entrance's timing as the app opens from cold, which in the simulator is held
up by the sample family loading.
```

Note: the heredoc starts with a blank line, so there is one blank line between the previous last line of the spec and `## Tea, bedtime, ...`.

---

## 3. File-by-file changes

Paths are relative to `app/Puggle/` unless noted. Order of work in the session: Evening.swift → Rooms `at(hour:)` → TodayView `evening` → Cast poses/gathering → CompanyView pose placement → Tiles header (bed/tea placement, gathering, settle, 30s re-check) → Rooms drawing (armchair, bag, quilt, Zs, long table) → build → screenshots → seat-at-floor fix → upright/tucked-in rework → quilt/rabbit tweak → Arrival.swift → wiring the entrance → many entrance fixes → tests → spec → commit.

### 3.1 NEW `Design/Evening.swift` (final version)

Written once at 02:34:24; one later edit (02:50:27) changed the `asleep` doc comment from `/// Tucked in, lying down.` to `/// Tucked in, the quilt up to her chin.`. Final file:

```swift
import Foundation

/// Puggle's evening follows the real children's (Tom, 19 November 2026). If the family logs sleep, she goes to
/// bed when they are all asleep; if not, at a usual bedtime for the oldest child's age. For half an hour before
/// that she sits up in bed reading, and she stirs when a child is seen to in the night.
///
/// Today sets what it knows about the children here; the scenes read it, as they read the clock.
struct Evening: Equatable {
    /// Minutes after midnight the oldest child would usually go to sleep.
    var bedtime = 19 * 60 + 15
    /// The family has logged a sleep in the last two days, so the logs are followed rather than the clock.
    var followsLogs = false
    /// Every child on Today has a sleep running.
    var allAsleep = false
    /// When something was last logged for a child, for her stirring in the night.
    var lastLogged: Date?

    /// What Today last said. Read by the rooms and the scene.
    nonisolated(unsafe) static var now = Evening()

    /// A usual bedtime by age, as minutes after midnight: babies about seven, toddlers a little after, four to
    /// six year olds by eight.
    static func bedtime(ageMonths: Int) -> Int {
        switch ageMonths {
        case ..<12: 19 * 60
        case ..<36: 19 * 60 + 15
        case ..<72: 19 * 60 + 45
        default: 20 * 60
        }
    }

    /// How long she reads in bed before she sleeps.
    static let windDown = 30

    /// Minutes after midnight, from the clock or the Developer menu ("-debugHour 20" is 20:00).
    static var minuteNow: Int {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "debugHour") != nil {
            let minute = UserDefaults.standard.string(forKey: "debugMinute").flatMap(Int.init) ?? 0
            return Room.hourNow * 60 + minute
        }
        #endif
        let parts = Calendar.current.dateComponents([.hour, .minute], from: .now)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// True from the start of her wind-down in the evening until six in the morning: she is in her bedroom.
    func inBedroom(minute: Int) -> Bool {
        if minute < 6 * 60 { return true }
        if minute < 18 * 60 + 30 { return false }
        // Asleep already, as logged, after tea.
        if followsLogs && allAsleep { return true }
        return minute >= bedtime - Self.windDown
    }

    /// What she is doing in her bedroom at this minute.
    func pose(minute: Int, at date: Date = .now) -> BedPose {
        #if DEBUG
        // For checking: "-debugBed reading", "asleep", "stirring" or "up".
        if let forced = UserDefaults.standard.string(forKey: "debugBed").flatMap(BedPose.init(rawValue:)) { return forced }
        #endif
        let night = minute < 6 * 60 || minute >= 22 * 60
        // A child seen to in the night: she sits up, sleepy, for a few minutes.
        if night, let lastLogged, date.timeIntervalSince(lastLogged) < 8 * 60, date >= lastLogged { return .stirring }
        if followsLogs {
            if allAsleep { return .asleep }
            return night ? .stirring : .reading
        }
        let asleep = minute < 6 * 60 || minute >= bedtime
        return asleep ? .asleep : .reading
    }

    /// One evening in five a friend comes for tea and stays the night.
    static var sleepover: CastMember? {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now.addingTimeInterval(-6 * 3600)) ?? 0
        let friends: [CastMember] = [.kip, .quill, .digby, .sunny, .pebble]
        #if DEBUG
        // For checking: "-debugSleepover kip", or "none".
        if let forced = UserDefaults.standard.string(forKey: "debugSleepover") { return CastMember(rawValue: forced) }
        #endif
        guard day % 5 == 2 else { return nil }
        return friends[(day / 5) % friends.count]
    }
}

/// Puggle in her bedroom.
enum BedPose: String {
    /// Standing on the rug, as before bed.
    case up
    /// Sitting up in bed with her book.
    case reading
    /// Tucked in, the quilt up to her chin.
    case asleep
    /// Sitting up, sleepy, while a child is seen to in the night.
    case stirring
}

```

Notes:
- `Evening.now` is a global mutable static (`nonisolated(unsafe)`, needs Swift 5.10, which project.yml sets). TodayView writes it while building the header; `Room.at(hour:)`, `RoomPainter` (bedFront/bedroom) and `PuggleHeader` read it.
- `minuteNow` uses `-debugMinute` only when `-debugHour` is set. Depends on existing `Room.hourNow` (Rooms.swift, already in 4be0423).
- `pose(...)` reads `-debugBed`; `sleepover` reads `-debugSleepover` (any non-member value like `none` → nil).

### 3.2 NEW `Design/Arrival.swift` (final version)

First written at 02:53:00 with a `switch style { case .rise: ... case .walk: ... }` holding different `KeyframeTrack` sets per case. That doesn't compile (the keyframes builder needs the same tracks in every branch), so at 02:56:12 the keyframes were rewritten so every style drives the same tracks with different values. Later edits: `max(delay, 0.001)` (03:02:19, NaN crash), initial opacity 0 before the first trigger (03:04:22), `away` parameter (03:11:06; `.opacity(away && style != .none ? 0 : 1)`, then `.opacity(away ? 0 : 1)` at 03:30:28), a `run` track (03:33:22, didn't work), replaced by the `live` track + `unhideAfter`/`liveFor` (03:38:21), and NSLog lines added and removed. Final file after all edits:

```swift
import SwiftUI

/// How someone arrives in the scene when Today opens (Tom, 19 November 2026).
enum ArrivalStyle: Equatable {
    /// Up from behind the hill: a crouch, a stretch on the way up, a squash as they land.
    case rise
    /// In along the ground from the edge nearest where they stand, walking.
    case walk
    /// Already there and settled (in bed, at the table): they fade in.
    case fade
    /// Back within a few minutes: already there, no entrance at all.
    case none
}

/// The numbers an arrival moves.
struct ArrivalPose {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var stretch: CGFloat = 1
    var opacity: Double = 1
    /// 1 while an entrance is playing. On the first frame after a new entrance is asked for, SwiftUI draws the
    /// keyframes' end values (everyone in place), and this is 0 then: with Today still marked away, nobody is
    /// drawn, rather than flashing up in place before arriving.
    var live: Double = 0
}

/// Plays an arrival each time `trigger` changes. `edge` is how far sideways the nearest edge of the scene is,
/// signed, for walking in; `delay` staggers one character after another.
struct Arrival: ViewModifier {
    let trigger: Int
    let style: ArrivalStyle
    var edge: CGFloat = 0
    var delay: Double = 0
    /// Told when a walk-in starts and ends, so the legs move.
    var walking: (Bool) -> Void = { _ in }
    /// Today is out of sight: hidden until the next entrance, so the app switcher's picture is the empty scene.
    var away = false

    /// How long a walk-in takes.
    static let walkTime = 0.9
    /// How long after an entrance starts Today stops marking itself away. Every entrance has begun by then, and
    /// each stays marked live until well after.
    static let unhideAfter = 1.0
    static let liveFor = 4.0

    func body(content: Content) -> some View {
        // Out of sight until the first entrance, so nobody is seen standing in place before they arrive.
        content
            .keyframeAnimator(initialValue: ArrivalPose(opacity: trigger == 0 && style != .none ? 0 : 1),
                              trigger: trigger) { view, pose in
                // Squash and stretch keep their volume: taller is narrower.
                view.scaleEffect(x: 1 / pose.stretch, y: pose.stretch, anchor: .bottom)
                    .offset(x: pose.x, y: pose.y)
                    .opacity(pose.opacity)
                    .opacity(away && pose.live < 1 ? 0 : 1)
            } keyframes: { _ in
                // Every style moves the same four numbers, so the tracks are the same and only their values differ.
                let rise = style == .rise, walk = style == .walk
                // A keyframe that takes no time at all divides by nothing: never quite zero.
                let delay = max(delay, 0.001)
                // The squash and stretch: a crouch, a stretch on the way up, a squash on landing (rising); a little
                // settle as they stop (walking).
                let squash: [(CGFloat, Double)] = rise ? [(0.88, 0.08), (1.1, 0.18), (1, 0.12), (0.86, 0.1)]
                    : walk ? [(1, 0.001), (1, 0.001), (1, 0.001), (0.94, 0.1)]
                    : [(1, 0.001), (1, 0.001), (1, 0.001), (1, 0.001)]
                // On from the first moment, and on for longer than any entrance takes. See `Arrival.liveFor`.
                KeyframeTrack(\.live) {
                    LinearKeyframe(1, duration: 0.001)
                    LinearKeyframe(1, duration: Self.liveFor)
                    LinearKeyframe(0, duration: 0.001)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(style == .rise || style == .fade ? 0 : 1, duration: 0.001)
                    LinearKeyframe(style == .rise || style == .fade ? 0 : 1, duration: delay)
                    CubicKeyframe(1, duration: style == .fade ? 0.5 : 0.12)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(rise ? 64 : 0, duration: 0.001)
                    LinearKeyframe(rise ? 64 : 0, duration: delay + 0.08)
                    // Up past where they stand, then down onto it.
                    CubicKeyframe(rise ? -12 : 0, duration: 0.3)
                    CubicKeyframe(0, duration: 0.16)
                }
                KeyframeTrack(\.x) {
                    LinearKeyframe(walk ? edge : 0, duration: 0.001)
                    LinearKeyframe(walk ? edge : 0, duration: delay)
                    CubicKeyframe(0, duration: Self.walkTime)
                }
                KeyframeTrack(\.stretch) {
                    LinearKeyframe(1, duration: 0.001)
                    LinearKeyframe(1, duration: delay + (walk ? Self.walkTime : 0))
                    CubicKeyframe(squash[0].0, duration: squash[0].1)
                    CubicKeyframe(squash[1].0, duration: squash[1].1)
                    CubicKeyframe(squash[2].0, duration: squash[2].1)
                    CubicKeyframe(squash[3].0, duration: squash[3].1)
                    SpringKeyframe(1, duration: 0.4, spring: .init(duration: 0.4, bounce: 0.45))
                }
            }
            .task(id: trigger) {
                guard style == .walk, trigger > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                walking(true)
                try? await Task.sleep(for: .seconds(Self.walkTime))
                walking(false)
            }
    }
}

extension View {
    func arrival(_ trigger: Int, _ style: ArrivalStyle, edge: CGFloat = 0, delay: Double = 0, away: Bool = false,
                 walking: @escaping (Bool) -> Void = { _ in }) -> some View {
        modifier(Arrival(trigger: trigger, style: style, edge: edge, delay: delay, walking: walking, away: away))
    }
}

```

How it works: `trigger` (Today's `entrance` counter) changing starts the keyframes. `live` is 1 for 4 s from the start of each run, otherwise 0. SwiftUI's `keyframeAnimator` renders the keyframes' **end values** (everyone in place, opacity 1) for a frame when the trigger changes, before the timeline starts. So while Today is marked `away`, anything with `live < 1` is hidden. Today clears `away` 1.0 s after bumping the trigger (`Arrival.unhideAfter`), by which time every entrance is running. A walk tells the rig to move its legs via the `walking` callback for `walkTime` after `delay`.

### 3.3 `Design/Cast.swift`: net diff against 4be0423 (exact)

What and why:
- `CastMember.isParent` (Mum/Dad leave once she's asleep; Nan/Pop stay).
- New `CastPose` (`standing`, `atTable`, `armchair`, `bagSitting`, `bagLying`). A `lying` helper was added, then removed at 02:50:27, which leaves a stray blank line before the closing brace. Harmless; tidy it if you like.
- `Company.pose`, `Company.gathering(kind:room:afterDark:bed:minute:)`, `Company.tea()`, private `Company.bedtime(_:minute:)`.
- `CompanyView`: new stored props and init params `entrance`, `arrive`, `edge`, `delay`, `away`. A `drop` that seats anyone not standing 26 pt lower, so the cloth, chair skirt or bag hides their feet (first version used `h*0.22`/`h*0.2`/`h*0.3` and a rotated lying pose; changed at 02:47:43 and 02:50:16). The ground shadow is hidden unless standing. The old `.offset(y: appeared ? 0 : 50).opacity(appeared ? 1 : 0)` entrance is replaced by `.offset(y: drop).arrival(...)`. Interim states (`.rotationEffect(-90)` for lying, `.onAppear { controller.rig?.hideZs(...) }`) were removed at 02:50:16.

```diff
--- a/app/Puggle/Design/Cast.swift
+++ b/app/Puggle/Design/Cast.swift
@@ -9,6 +9,7 @@
     var id: String { rawValue }
     var name: String { rawValue.capitalized }
     var grownUp: Bool { self == .nan || self == .mum || self == .dad || self == .pop }
+    var isParent: Bool { self == .mum || self == .dad }
 
     /// Each drawing's size and headroom, read once.
     private static let drawn: [CastMember: (height: CGFloat, headroom: CGFloat)] = Dictionary(uniqueKeysWithValues: allCases.map { member in
@@ -81,12 +82,75 @@
     case digging
 }
 
+/// How someone is placed in the scene.
+enum CastPose: Equatable {
+    case standing
+    /// Sitting at the tea table: lower, behind it.
+    case atTable
+    /// In the armchair by the bed, for a story, or dozing while babysitting.
+    case armchair
+    /// In a sleeping bag on the bedroom floor on a sleepover: sitting up, or tucked in asleep.
+    case bagSitting, bagLying
+
+}
+
 /// Who is with Puggle today, where they stand, and what they are doing.
 struct Company: Equatable {
     let member: CastMember
     /// Where they stand, as a share of the width from the middle.
     let x: CGFloat
     var activity: CastActivity = .with
+    var pose: CastPose = .standing
+
+    /// Everyone with her: at tea her family round the table, at bedtime whoever is reading or sleeping over,
+    /// anywhere else today's one companion (or nobody).
+    static func gathering(kind: SceneKind, room: Room?, afterDark: Bool, bed: BedPose?, minute: Int) -> [Company] {
+        switch room {
+        case .dining: return tea().others
+        case .bedroom: return bedtime(bed ?? .asleep, minute: minute)
+        default: return today(kind: kind, room: room, afterDark: afterDark).map { [$0] } ?? []
+        }
+    }
+
+    /// Tea: Mum and Dad either side of her every evening; Nan or Pop some evenings, or the friend staying
+    /// the night. Four at most, so everyone fits. `puggle` is where her own place is.
+    static func tea() -> (others: [Company], puggle: CGFloat) {
+        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
+        var guest: CastMember? = Evening.sleepover
+        #if DEBUG
+        // For checking: "-debugTea nan" (or pop, or a friend), or "none".
+        if let forced = UserDefaults.standard.string(forKey: "debugTea") { guest = CastMember(rawValue: forced) }
+        else if guest == nil, day % 3 == 1 { guest = day.isMultiple(of: 2) ? .nan : .pop }
+        #else
+        if guest == nil, day % 3 == 1 { guest = day.isMultiple(of: 2) ? .nan : .pop }
+        #endif
+        guard let guest else {
+            return ([Company(member: .mum, x: -0.3, pose: .atTable), Company(member: .dad, x: 0.3, pose: .atTable)], 0)
+        }
+        // Mum, Puggle, the guest, Dad: a child guest sits next to her.
+        return ([Company(member: .mum, x: -0.36, pose: .atTable), Company(member: guest, x: 0.12, pose: .atTable),
+                 Company(member: .dad, x: 0.36, pose: .atTable)], -0.12)
+    }
+
+    /// Bedtime. While she reads, a grown-up sits in the armchair: Mum or Dad for a story, or Nan or Pop
+    /// babysitting, who dozes off and stays until ten. A friend on a sleepover is in a sleeping bag on the
+    /// floor all night. Late at night it is only her, and any friend.
+    private static func bedtime(_ bed: BedPose, minute: Int) -> [Company] {
+        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now.addingTimeInterval(-6 * 3600)) ?? 0
+        var here: [Company] = []
+        if let friend = Evening.sleepover {
+            here.append(Company(member: friend, x: 0.04, activity: bed == .reading ? .with : .dozing,
+                                pose: bed == .reading ? .bagSitting : .bagLying))
+        }
+        let grownUp: CastMember = [.mum, .dad, .nan, .pop][day % 4]
+        let late = minute < 6 * 60 || minute >= 22 * 60
+        switch bed {
+        case .reading, .up: here.append(Company(member: grownUp, x: 0.34, pose: .armchair))
+        case .asleep where !late && !grownUp.isParent: here.append(Company(member: grownUp, x: 0.34, activity: .dozing, pose: .armchair))
+        default: break
+        }
+        return here
+    }
 
     /// Some days she is on her own; others her family or a friend is there. It changes each time
     /// the same place comes round, so a scene is not always the same company.
@@ -206,11 +270,24 @@
     /// The weather they are out in, for the rain landing on their umbrella. Nil indoors.
     var weather: Weather?
     var night = false
+    /// Their arrival: counts up each time Today opens, and how they come in. See `Arrival`.
+    var entrance = 0
+    var arrive: ArrivalStyle = .none
+    /// How far sideways the nearest edge of the scene is, for walking in.
+    var edge: CGFloat = 0
+    var delay: Double = 0
+    var away = false
     @StateObject private var controller: CastController
     @Environment(\.accessibilityReduceMotion) private var reduceMotion
     @Environment(\.outfit) private var outfit
 
-    init(company: Company, puggleReacted: Int, quiet: Bool, appeared: Bool, dark: Bool, rain: Bool = false, weather: Weather? = nil, night: Bool = false) {
+    init(company: Company, puggleReacted: Int, quiet: Bool, appeared: Bool, dark: Bool, rain: Bool = false, weather: Weather? = nil, night: Bool = false,
+         entrance: Int = 0, arrive: ArrivalStyle = .none, edge: CGFloat = 0, delay: Double = 0, away: Bool = false) {
+        self.away = away
+        self.entrance = entrance
+        self.arrive = arrive
+        self.edge = edge
+        self.delay = delay
         self.weather = weather
         self.night = night
         self.company = company
@@ -229,10 +306,22 @@
         controller.rig?.rig.parts.contains { $0.id == "umbrella" } == true && (outfit == "rain" || (outfit == "sun" && company.member == .nan))
     }
 
+    /// How far down from standing, in points, for sitting at the table, in the armchair or in a sleeping bag.
+    private var drop: CGFloat {
+        switch company.pose {
+        case .standing: return 0
+        // Sitting, they come down to the foot of the scene, where the cloth, the chair or the bag hides their feet.
+        // Asleep in the bag they are upright too, head on a pillow and the bag up to their chin: every face in
+        // the cast is drawn from the front, and turned on its side it no longer reads.
+        case .atTable, .armchair, .bagSitting, .bagLying: return 26
+        }
+    }
+
     var body: some View {
         ZStack(alignment: .bottom) {
             Ellipse().fill(dark ? Color(hex: 0x15163A).opacity(0.3) : Palette.fixedInk.opacity(0.1))
                 .frame(width: 76, height: 8)
+                .opacity(company.pose == .standing ? 1 : 0)
                 .offset(y: 3)
             if company.activity == .digging, !sleeps {
                 // The heap he has dug, beside him, and sand flying.
@@ -264,8 +353,8 @@
                 // on the side nearer her, and its canopy stays clear of the edge of the screen.
                 .scaleEffect(x: umbrellaUp && company.x > 0 ? -1 : 1, y: 1)
         }
-        .offset(y: appeared ? 0 : 50)
-        .opacity(appeared ? 1 : 0)
+        .offset(y: drop)
+        .arrival(entrance, arrive, edge: edge, delay: delay, away: away) { [controller] in controller.rig?.walking = $0 }
         .allowsHitTesting(false)
         .onAppear { controller.asleep = sleeps }
         .onChange(of: sleeps) { _, now in
```

### 3.4 `Design/Rooms.swift`: net diff against 4be0423 (exact)

What and why:
- `Room.at(hour:dark:)`: the bedroom now follows `Evening.now.inBedroom(minute:)` (minute-precise for the current hour) and wins over everything, `-debugRoom` excepted. Out-tonight is skipped on a sleepover night, and it now runs from 18:00 until her wind-down instead of until 22:00. Hours 19–23 not in bed → the living room or playroom (alternating days). The old fixed `20...23, 0..<6 → .bedroom` is gone. (The script's trailing `grep "One evening in three"` was only a check.)
- `RoomFront`: now also draws for `.bedroom` (calls the new `bedFront()`), and passes `Room.hourNow` instead of a hard-coded 18.
- Bedroom background: the rabbit on the pillow is hidden once she's asleep (it's drawn beside her in `bedFront`). Added the armchair back by the bed at `w*0.84`, plus the back of a sleepover friend's sleeping bag and their pillow when asleep.
- New `// MARK: Bedtime`: `tonight`, `sleepingBag(_:)`, `bedFront()` (quilt over her legs when reading/stirring; quilt to the chin with a turned-back top and the rabbit beside her when asleep; the armchair's arms and a skirt to the floor; the front of the sleeping bag with its turned-back top).
- `table()`: spans the room (`left = 10, width = w - 20`), cloth to the floor (02:47:43), a plate and cup at each companion's place, and her bowl and cup at `Company.tea().puggle`.
- Intermediate states that were removed: a `zeds(from:salt:)` helper drawing rising "z" text over the asleep Puggle, the dozing armchair sitter and the bag; a lying quilt "mound" path; lying sleeping-bag geometry with `length`/`thick`. Quilt rects went `142/140` → `152/150`, rabbit `(118,128)` → `(118,136)` at 02:51:36.

```diff
--- a/app/Puggle/Design/Rooms.swift
+++ b/app/Puggle/Design/Rooms.swift
@@ -30,19 +30,23 @@
     /// The room for this hour, or nil while she is outdoors. `dark` is the dark or night look:
     /// by day it keeps her in on most days, since the scene outside would be drawn as night.
     /// When she is outdoors after dark, `Company` always gives her a grown-up.
+    /// From her wind-down until morning she is in her bedroom, at a time that follows the real children.
     static func at(hour: Int, dark: Bool) -> Room? {
         let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
         let evening: Room = day.isMultiple(of: 2) ? .living : .playroom
-        // Out with a grown-up: from tea time until ten. Bed is still bed.
-        if outTonight, !(22...23).contains(hour), !(0..<6).contains(hour), hour >= 18 { return nil }
+        // The minute as well as the hour, when the hour is the one showing now.
+        let minute = hour == hourNow ? Evening.minuteNow : hour * 60
+        let bed = Evening.now.inBedroom(minute: minute)
         #if DEBUG
         // For checking a room at any hour: launch with "-debugRoom 0" to "3".
         if let forced = UserDefaults.standard.string(forKey: "debugRoom").flatMap(Int.init), let room = Room(rawValue: forced) { return room }
         #endif
+        if bed { return .bedroom }
+        // Out with a grown-up after tea, until it is time to wind down. Never on a sleepover night.
+        if outTonight, Evening.sleepover == nil, hour >= 18 { return nil }
         switch hour {
         case 18: return .dining
-        case 19: return evening
-        case 20...23, 0..<6: return .bedroom
+        case 19...23: return evening
         // By day she is outdoors, whatever the phone's look: where she is follows the clock.
         default: return nil
         }
@@ -95,12 +99,12 @@
     @Environment(\.accessibilityReduceMotion) private var reduceMotion
 
     var body: some View {
-        if room == .dining {
+        if room == .dining || room == .bedroom {
             TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
                 Canvas { context, size in
-                    RoomPainter(context: &context, w: size.width, top: size.height - 250, dark: dark,
-                                t: timeline.date.timeIntervalSince(SceneClock.start), hour: 18, weather: .clear, style: .ink)
-                        .table()
+                    let painter = RoomPainter(context: &context, w: size.width, top: size.height - 250, dark: dark,
+                                              t: timeline.date.timeIntervalSince(SceneClock.start), hour: Room.hourNow, weather: .clear, style: .ink)
+                    if room == .dining { painter.table() } else { painter.bedFront() }
                 }
             }
             .allowsHitTesting(false)
@@ -467,7 +471,8 @@
             soft("blossom", x, 172 + CGFloat(index % 2) * 8 - 4, 13, col(0xBFD9F5, 0x5A78B8), turn: Double(index) * 25)
         }
         rect(8, 190, 8, 14, 3, col(0xB89A78, 0x5E4A3C)); rect(164, 190, 8, 14, 3, col(0xB89A78, 0x5E4A3C))
-        rabbit(60, 122)
+        // Her rabbit waits on the pillow; once she is tucked in, it is beside her (see `bedFront`).
+        if tonight.bed != .asleep { rabbit(60, 122) }
         // The table by the bed: a lamp left on, and tonight's book.
         let wood = col(0xD9B48A, 0x5E4A3C)
         rect(w - 138, 128, 58, 40, 7, wood)
@@ -483,6 +488,20 @@
         // The lamp's light lying on the floor, reaching her.
         oval(w / 2 + 44, 214, 100, 20, Color(hex: 0xFFD98A).opacity(dark ? 0.16 : 0.12))
         rug(col(0xCFE5D2, 0x35485A), col(0x3C9A5F, 0x2A5A48).opacity(0.5))
+        // The armchair by the bed, for stories and for whoever is babysitting. Its arms are drawn in front.
+        let chair = w * 0.84
+        oval(chair, 242, 52, 6, Palette.fixedInk.opacity(dark ? 0.3 : 0.1))
+        rect(chair - 44, 116, 88, 92, 26, col(0xE9B872, 0x6A5468))
+        rect(chair - 34, 128, 68, 66, 18, col(0xDDA75E, 0x5E4A60))
+        // A friend sleeping over: the inside of their sleeping bag, and a pillow.
+        if let friend = tonight.people.first(where: { $0.pose == .bagSitting || $0.pose == .bagLying }) {
+            let bag = sleepingBag(friend)
+            // Asleep, a pillow behind their head.
+            if friend.pose == .bagLying {
+                rect(bag.back.minX - 6, bag.head.y - 4, bag.back.width + 12, 30, 14, col(0xFFFCF6, 0x8A88B0))
+            }
+            rect(bag.back.minX, bag.back.minY, bag.back.width, bag.back.height, 20, col(0x2E7A8C, 0x23465A))
+        }
         // Higher up: more stars, a mobile turning, and clouds painted near the ceiling.
         if shown(66) > 0 {
             for (index, star) in [(0.2, -60.0), (0.5, -84), (0.8, -66), (0.36, -104), (0.66, -110)].enumerated() {
@@ -501,24 +520,91 @@
         }
     }
 
+    // MARK: Bedtime
+
+    /// Her bed and who is with her, as Today shows them (see `Evening` and `Company.gathering`).
+    private var tonight: (bed: BedPose, people: [Company]) {
+        let minute = Evening.minuteNow
+        let bed = Evening.now.pose(minute: minute)
+        return (bed, Company.gathering(kind: .hills, room: .bedroom, afterDark: true, bed: bed, minute: minute))
+    }
+
+    /// Where a friend's sleeping bag goes, from where they are and how big they are: the back of it, and the front
+    /// that covers them, to the waist sitting up or to the chin asleep.
+    private func sleepingBag(_ friend: Company) -> (back: CGRect, front: CGRect, head: CGPoint) {
+        let cx = w / 2 + friend.x * w
+        let height = friend.member.height, across = height * friend.member.aspect
+        let cover = friend.pose == .bagLying ? 0.5 : 0.36
+        return (CGRect(x: cx - across * 0.55, y: 250 - height * cover - 16, width: across * 1.1, height: height * cover + 16),
+                CGRect(x: cx - across * 0.58, y: 250 - height * cover, width: across * 1.16, height: height * cover),
+                CGPoint(x: cx, y: 250 - height * 0.68))
+    }
+
+    /// In front of whoever is at bedtime: her quilt over her, the armchair's arms and seat, and a sleeping bag.
+    func bedFront() {
+        let (bed, people) = tonight
+        let quilt = col(0x2A62B8, 0x2B3F7A), flower = col(0xBFD9F5, 0x5A78B8)
+        switch bed {
+        case .reading, .stirring:
+            // Sitting up: the quilt over her legs, as it lies on the bed.
+            rect(4, 150, 172, 46, 16, quilt)
+            for (index, x) in [28.0, 66, 104, 142].enumerated() {
+                soft("blossom", x, 172 + CGFloat(index % 2) * 8 - 4, 13, flower, turn: Double(index) * 25)
+            }
+        case .asleep:
+            // Tucked in: the quilt up to her chin, its top turned back, her head on the pillow and her rabbit by her.
+            rect(4, 152, 172, 44, 16, quilt)
+            rect(4, 150, 172, 12, 6, col(0xFFFCF6, 0x8A88B0))
+            for (index, x) in [36.0, 72, 108, 146].enumerated() {
+                soft("blossom", x, 174 + CGFloat(index % 2) * 8 - 4, 13, flower, turn: Double(index) * 25)
+            }
+            rabbit(118, 136)
+        case .up:
+            break
+        }
+        // The armchair's arms and seat, in front of whoever sits in it.
+        let chair = w * 0.84, cloth = col(0xE9B872, 0x6A5468), deep = col(0xDDA75E, 0x5E4A60)
+        // Its skirt reaches the floor, so the feet of whoever sits in it are hidden.
+        rect(chair - 44, 200, 88, 50, 12, deep)
+        rect(chair - 52, 170, 22, 80, 11, cloth)
+        rect(chair + 30, 170, 22, 80, 11, cloth)
+        // A sleeping bag over a friend staying the night.
+        if let friend = people.first(where: { $0.pose == .bagSitting || $0.pose == .bagLying }) {
+            let bag = sleepingBag(friend)
+            rect(bag.front.minX, bag.front.minY, bag.front.width, bag.front.height, 20, col(0xF4BE2C, 0x8A6F2A))
+            // Its turned-back top.
+            rect(bag.front.minX, bag.front.minY, bag.front.width, 10, 5, col(0xE5553B, 0x7A3A34))
+        }
+    }
+
     // MARK: Things in the rooms
 
-    /// The tea table, in front of her: a cloth with a scalloped edge, her bowl, steam, and her cup.
+    /// The tea table, in front of the family: a cloth with a scalloped edge, a place for each of them, her bowl
+    /// with steam coming off, and her cup. Long enough for four.
     func table() {
         let cloth = col(0xFFFCF6, 0x6A6890), wood = col(0xD9B48A, 0x5E4A3C)
-        let left = w / 2 - 122, width: CGFloat = 244
+        let left: CGFloat = 10, width = w - 20
         rect(left + 14, 214, 10, 32, 4, wood); rect(left + width - 24, 214, 10, 32, 4, wood)
         rect(left, 200, width, 14, 7, wood)
-        // The cloth hangs down in scallops.
-        rect(left + 8, 198, width - 16, 26, 4, cloth)
-        let scallops = 9
+        // The cloth hangs almost to the floor, in scallops, so no one's feet show under it.
+        rect(left + 8, 198, width - 16, 44, 4, cloth)
+        let scallops = Int((width - 16) / 26)
         for index in 0..<scallops {
             let each = (width - 16) / CGFloat(scallops)
-            oval(left + 8 + each * (CGFloat(index) + 0.5), 224, each / 2, 9, cloth)
+            oval(left + 8 + each * (CGFloat(index) + 0.5), 242, each / 2, 8, cloth)
         }
         rect(left + 8, 198, width - 16, 5, 2.5, Color(hex: 0xE5553B).opacity(dark ? 0.6 : 0.85))
+        // A plate and a cup at each grown-up's or friend's place.
+        let (others, puggle) = Company.tea()
+        for (index, person) in others.enumerated() {
+            let x = w / 2 + person.x * w
+            oval(x, 196, 24, 5, col(0xF3D9C9, 0x6A5560))
+            oval(x, 195, 16, 3, col(0xE9B872, 0x8A6F5A))
+            let colour: UInt32 = [0x3C9A5F, 0x2A62B8, 0xE5553B][index % 3]
+            rect(x + 26, 180, 13, 16, 4, Color(hex: colour).opacity(dark ? 0.7 : 1))
+        }
         // Her bowl and spoon, with steam coming off, and her cup.
-        let x = w / 2 - 74
+        let x = w / 2 + puggle * w
         oval(x, 195, 25, 6, col(0xA6C6EC, 0x4A5F8A))
         var bowl = Path()
         bowl.move(to: CGPoint(x: x - 25, y: top + 195))
@@ -535,7 +621,7 @@
             wisp.addQuadCurve(to: CGPoint(x: base.x + 2, y: base.y - 10), control: CGPoint(x: base.x + 5 * CGFloat(sin(rise * 6 + Double(index))), y: base.y - 5))
             context.stroke(wisp, with: .color(Color.white.opacity((dark ? 0.35 : 0.7) * sin(rise * .pi))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
         }
-        let cup = w / 2 + 76
+        let cup = x - 36
         rect(cup - 9, 174, 18, 24, 6, Color(hex: 0xF4BE2C).opacity(dark ? 0.75 : 1))
         rect(cup - 10, 171, 20, 6, 3, Color(hex: 0xE5553B).opacity(dark ? 0.75 : 1))
         rect(cup - 2.5, 164, 5, 9, 2.5, Color(hex: 0xE5553B).opacity(dark ? 0.75 : 1))
```

### 3.5 `Features/Today/TodayView.swift`: net diff against 4be0423 (exact)

Today works out the children's `Evening`, publishes it to `Evening.now` before the header draws (so `Room.at` and the painters see it), and passes it into `PuggleHeader(evening:)` so the header re-settles her when it changes. Relies on existing `store.activeSleep(for:)`, `store.lastWoke(for:)`, `Child.ageMonths`, `store.lastSaved?.events` (`Event.createdAt`), all present in 4be0423.

```diff
--- a/app/Puggle/Features/Today/TodayView.swift
+++ b/app/Puggle/Features/Today/TodayView.swift
@@ -401,9 +401,25 @@
         }
     }
 
+    /// What the scene needs to know about the children's evening: see `Evening`.
+    private var evening: Evening {
+        let kids = Array(children)
+        let twoDays = Date.now.addingTimeInterval(-2 * 86_400)
+        let logs = kids.contains { child in
+            store.activeSleep(for: child) != nil || (store.lastWoke(for: child) ?? .distantPast) > twoDays
+        }
+        let oldest = kids.map(\.ageMonths).max() ?? 30
+        return Evening(bedtime: Evening.bedtime(ageMonths: oldest), followsLogs: logs,
+                       allAsleep: !kids.isEmpty && kids.allSatisfy { store.activeSleep(for: $0) != nil },
+                       lastLogged: store.lastSaved?.events.compactMap(\.createdAt).max())
+    }
+
     private var header: some View {
         let words = headerWords
-        return PuggleHeader(quiet: children.contains { store.activeSleep(for: $0) != nil }, title: words.title, line: words.line) {
+        // Set before the scene draws, so the rooms follow the children.
+        let evening = evening
+        let _ = { Evening.now = evening }()
+        return PuggleHeader(quiet: children.contains { store.activeSleep(for: $0) != nil }, evening: evening, title: words.title, line: words.line) {
             showingYou = true
         }
     }
```

`let evening = evening` shadows the computed property inside `header`. It built on the Mac (Xcode with Swift 5.10 mode). If your compiler complains, write `let evening = self.evening`.

### 3.6 `Features/Today/Tiles.swift` (`PuggleHeader` and `CarriedPuggle`): diff against the reconstructed 6263eba (exact)

**This file depends on 6263eba.** UPDATE: I replayed every 3504179 edit onto the scratch checkout `rework/wt` (4be0423 + reconstructed 6263eba + the later scripted commits). **Every Tiles.swift replacement found its anchor**: `PuggleScene(... puggleShadow: !holding)`, `isNight`, the `CarriedPuggle(controller:carry:restX:reach:canWalk:quiet: lift:tilt:nod:onTap:onPutDown:)` call with its old entrance modifiers, `CarriedPuggle`'s `let nod`/`let onTap`, and `.rotationEffect(.degrees(carry.sway), anchor: .top)` (`.offset(y: drop)` lands between it and the following `.animation(.spring(response: 0.5, dampingFraction: 0.42), value: carry.sway)`). So the diff below is exact against that tree. It is also in `rework/3-3504179-reconstructed.patch`, which holds the whole commit.

What and why:
- `PuggleHeader.evening` (input), `@State bedNow`, `entrance`, `fullEntrance`, `away` (**starts `true`**, 03:42:44, so nobody shows before the first entrance on cold launch either), `glancing`, `static leftAt`.
- `.onAppear`: settle her bed pose, then play the entrance. A `.task` loop re-checks the bed pose every 30 s so bedtime arrives while Today is open. `.onChange(of: evening)` re-settles.
- `.onDisappear` and scene phase: mark `away` and record `leftAt` when going. Also mark `away` as soon as the app goes `.inactive` (while it can still draw: by the time it's backgrounded it may not redraw, and the scene as left would flash up on return). If it goes `inactive` → `active` without backgrounding (Control Centre, notification), un-hide via `glancing`.
- `.onChange(of: quiet)` is ignored while she's in her bedroom (the bed decides).
- Placement: in bed or at the table she can't be walked. Bed x = `70 - width/2` reading/stirring, `61 - width/2` asleep (the first version had 81 with a −90° rotation). Drop: −51 sitting up in bed (negative = raised up onto the bed), −25 asleep, 26 at the table. No ground shadow in bed. At the table x = `Company.tea().puggle * width`.
- Company: `ForEach` over `Company.gathering(...)` instead of the single optional `Company.today`. `.id` includes the pose.
- `bedPose(_:)`, `settle(in:)` (stop `read`, then: reading → `asleep=false` + play `read`; asleep → `asleep=true`; stirring → `asleep=false` + play `wake`; otherwise `asleep = quiet`). An interim `rig.hideZs(...)` call was removed.
- `arrival(room:settled:)`, `beat` (0.3 → 0.45 → final **0.2**), `edge(from:width:awayFrom:mine:)` (the side is decided from stage fractions because `width` can be 0 during the first layout, which made Puggle pick the wrong side).
- `playEntrance()` rewritten: full entrance if away > 20 min (`-debugArrive` forces full). Full: after 0.2 s a Task bumps `entrance`, then 1.0 s later clears `away`. Not full or Reduce Motion: bump and clear at once. Not full: blink + look up (−0.6) for 1.2 s. Full: the old `appeared` spring is kept (it still drives `RoomFront`/scene opacity), then `glanceAtCompany()`.
- `glanceAtCompany()`: looks toward the first companion after **1.8 s** (see below) for 1.1 s; skipped in the bedroom unless reading.

**Line-number seds:** `sed -i '' '666s/1.1/1.6/'` (03:04:23, right after adding the 0.3 s beat; preceded by `grep -n "1.1)" ... | head -3`), then `sed -i '' '680s/1.6/1.8/'` (03:17:30, after `grep -n "1.6))"` found exactly one line; the beat was 0.45 then). Both target one `Task.sleep(for: .seconds(1.1))` in `glanceAtCompany()`. On the reconstructed tree, line 666 at that point was exactly the **first** `Task.sleep(for: .seconds(1.1))` (the wait before she looks over), and line 680 at the later point was that same line, now 1.6. So line numbers match the Mac's tree and the guess is **confirmed**: 1.8 s wait before the glance, 1.1 s look.

```diff
diff --git a/app/Puggle/Features/Today/Tiles.swift b/app/Puggle/Features/Today/Tiles.swift
index 3f54874..dea9972 100644
--- a/app/Puggle/Features/Today/Tiles.swift
+++ b/app/Puggle/Features/Today/Tiles.swift
@@ -334,6 +334,8 @@ struct TileChooserView: View {
 struct PuggleHeader: View {
     /// True while any child is asleep.
     let quiet: Bool
+    /// The children's evening, for her bedtime. See `Evening`.
+    var evening = Evening()
     /// The greeting: "Afternoon, Tom".
     let title: String
     let line: String
@@ -372,6 +374,17 @@ struct PuggleHeader: View {
     private var bubblesFirst: Double { UserDefaults.standard.string(forKey: "debugBubbles") == "1" ? 2.5 : 7 }
     /// Counts her reactions to a tap, so whoever is with her can answer.
     @State private var reactions = 0
+    /// Her bed as last settled, so a change of minute that changes it is noticed.
+    @State private var bedNow: BedPose?
+    /// Counts each entrance, and whether it is the full one or she was here a moment ago.
+    @State private var entrance = 0
+    @State private var fullEntrance = true
+    /// Today is out of sight; everyone is hidden until they arrive again.
+    @State private var away = true
+    /// Today went inactive without going to the background: Control Centre, a notification, an alert.
+    @State private var glancing = false
+    /// When Today was last left, for how big a hello to give on coming back.
+    nonisolated(unsafe) private static var leftAt: Date?
 
     static let sceneHeight: CGFloat = 250
 
@@ -398,19 +411,38 @@ struct PuggleHeader: View {
         // The entrance plays once the splash has gone, each time Today comes
         // back into view, and when the app is opened again.
         .onAppear {
-            controller.asleep = quiet
+            bedNow = bedPose(PuggleScene.room(dark: scheme == .dark || night))
+            settle(in: bedNow)
             if !splashing { playEntrance() }
         }
-        .onDisappear { appeared = false }
+        // Bedtime comes while Today is open: look again each half minute.
+        .task {
+            while !Task.isCancelled {
+                try? await Task.sleep(for: .seconds(30))
+                let now = bedPose(PuggleScene.room(dark: scheme == .dark || night))
+                if now != bedNow { bedNow = now; settle(in: now) }
+            }
+        }
+        .onDisappear { appeared = false; away = true; Self.leftAt = .now }
         .onChange(of: splashing) { _, now in if !now { playEntrance() } }
         .onChange(of: scenePhase) { old, now in
-            if now == .background { appeared = false }
+            // Hidden as soon as Today starts to go, while it can still draw: by the time it is in the background
+            // it may not draw again, and the scene as left would flash up on the way back.
+            if now == .inactive, old == .active { away = true; glancing = true }
+            if now == .background { appeared = false; away = true; glancing = false; Self.leftAt = .now }
             if old == .background, now != .background, !splashing { playEntrance() }
+            // Only a glance at Control Centre or a notification: everyone is still there.
+            if old == .inactive, now == .active, glancing { glancing = false; away = false }
         }
-        // Asleep while a child sleeps; a stretch and a yawn when the last one wakes.
+        // Asleep while a child sleeps; a stretch and a yawn when the last one wakes. In her bedroom, her bed decides.
         .onChange(of: quiet) { _, now in
+            guard bedPose(PuggleScene.room(dark: scheme == .dark || night)) == nil else { return }
             if now { controller.asleep = true } else { controller.wake() }
         }
+        .onChange(of: evening) { _, _ in
+            bedNow = bedPose(PuggleScene.room(dark: scheme == .dark || night))
+            settle(in: bedNow)
+        }
         // She answers each save: a nod for everyday things, more for the big ones.
         // No sound or tap: the save has its own. Nothing waits for her.
         .onChange(of: store.lastSaved?.id) { _, id in
@@ -467,40 +499,63 @@ struct PuggleHeader: View {
         let dim = scheme == .dark || night
         // After tea time she is indoors: lamplight, no coat, and pyjamas at bedtime.
         let room = PuggleScene.room(dark: dim)
-        // She sits at the tea table; anywhere else she can be walked along the ground.
-        let canWalk = room != .dining
+        // In bed, or at her place at the tea table, she stays put; anywhere else she can be walked along the ground.
+        let bed = bedPose(room)
+        let inBed = bed != nil && bed != .up
+        let canWalk = room != .dining && !inBed
         let reach = max(width / 2 - 58, 0)
         let home = room == nil ? PuggleScene.stand(for: .today) * width : 0
-        let x = canWalk ? min(max(walkedTo ?? home, -reach), reach) : 0
+        let x: CGFloat = switch (room, bed) {
+        // Sitting up against her pillow, or tucked in with her head on it. See `RoomPainter.bedFront`.
+        case (.bedroom, .reading?), (.bedroom, .stirring?): 70 - width / 2
+        case (.bedroom, .asleep?): 61 - width / 2
+        case (.dining, _): Company.tea().puggle * width
+        default: canWalk ? min(max(walkedTo ?? home, -reach), reach) : 0
+        }
+        // How far down from standing: sat behind the table, sitting up in bed, or tucked in.
+        let drop: CGFloat = switch (room, bed) {
+        case (.bedroom, .reading?), (.bedroom, .stirring?): -51
+        case (.bedroom, .asleep?): -25
+        case (.dining, _): 26
+        default: 0
+        }
         // In the backyard on a fine day she gets her bubble wand out now and then.
         let fine = ["none", "sun"].contains(weather.outfit(night: false))
         // Asked once here: working it out means drawing a frame of the scene.
         let isNight = PuggleScene.isNight(dark: dim)
         let canBubble = room == nil && SceneKind.today == .backyard && !isNight && fine && !quiet && !reduceMotion && appeared && !holding
         return ZStack(alignment: .bottom) {
-            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x, puggleShadow: !holding)
-            // Whoever is with her today stands behind her, on the same ground.
-            if let company = Company.today(kind: .today, room: room,
-                                           afterDark: room == nil && (isNight || Room.hourNow >= 18)) {
-                // Dressed for the weather when they are out in it, as she is.
+            PuggleScene(kind: .today, dark: dim, appeared: appeared, pull: pull, rooms: true, puggleX: x, puggleShadow: !holding && !inBed)
+            // Whoever is with her: today's companion behind her on the same ground, her family at the tea table,
+            // or at bedtime whoever is reading to her or sleeping over.
+            let gathering = Company.gathering(kind: .today, room: room, afterDark: room == nil && (isNight || Room.hourNow >= 18),
+                                              bed: bed, minute: Evening.minuteNow)
+            let arrive = arrival(room: room, settled: inBed || room == .dining)
+            ForEach(Array(gathering.enumerated()), id: \.element.member) { order, company in
+                // Dressed for the weather when they are out in it, as she is; in pyjamas on a sleepover.
                 let wearing = room == nil ? weather.outfit(night: isNight) : "none"
                 CompanyView(company: company, puggleReacted: reactions, quiet: quiet, appeared: appeared, dark: dim, rain: wearing == "rain",
-                            weather: room == nil ? weather : nil, night: isNight)
+                            weather: room == nil ? weather : nil, night: isNight,
+                            entrance: entrance, arrive: arrive, edge: Self.edge(from: company.x * width, width: width, mine: company.x),
+                            delay: Self.beat + Double(order) * 0.15, away: away)
                     .environment(\.moonlit, room == nil && isNight)
                     .environment(\.outfit, wearing)
                     .environment(\.shades, Shades.forOutfit(wearing))
                     .offset(x: company.x * width)
                     .padding(.bottom, 26)
-                    .id("\(company.member.rawValue)-\(wearing)")
+                    .id("\(company.member.rawValue)-\(wearing)-\(company.pose)")
             }
             CarriedPuggle(controller: controller, carry: carry, restX: x, reach: reach, canWalk: canWalk, quiet: quiet,
                           holding: $holding, justWalked: $justWalked, shadowNight: room == nil && isNight,
                           outfit: room?.outfit ?? weather.outfit(night: isNight),
                           warmLight: room.map { dim ? $0.lamp : nil } ?? PuggleScene.lamp(for: .today, night: isNight),
-                          lift: lift, tilt: tilt, nod: nod, onTap: tapped, onPutDown: { walkedTo = $0; land() })
-                // She pops up from behind the hill when Today first opens.
-                .offset(y: appeared ? 0 : 60)
-                .opacity(appeared ? 1 : 0)
+                          lift: lift, tilt: tilt, nod: nod, drop: drop,
+                          onTap: tapped, onPutDown: { walkedTo = $0; land() })
+                // She arrives a moment after whoever is with her, so they seem to have been waiting.
+                .arrival(entrance, arrive, edge: Self.edge(from: x, width: width, awayFrom: gathering.first.map { $0.x },
+                                                  mine: width > 0 ? x / width : PuggleScene.stand(for: .today)), delay: Self.beat + (gathering.isEmpty ? 0 : 0.2), away: away) { [controller] in
+                    controller.walking = $0
+                }
                 .padding(.bottom, 26)
             // Her bubbles, rising from the wand in her right hand. Only while she is making them.
             TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !controller.makingBubbles)) { timeline in
@@ -529,6 +584,7 @@ struct PuggleHeader: View {
                     .opacity(appeared ? 1 : 0)
             }
             // The tea table stands in front of her.
+            // The tea table in front of everyone at it; at bedtime her quilt, the armchair's arms, a sleeping bag.
             if let room { RoomFront(room: room, dark: dim).opacity(appeared ? 1 : 0) }
         }
         .overlay(alignment: .topTrailing) {
@@ -538,12 +594,113 @@ struct PuggleHeader: View {
         }
     }
 
+    /// What she is doing in her bedroom, from the children's evening. Nil anywhere else.
+    private func bedPose(_ room: Room?) -> BedPose? {
+        room == .bedroom ? Evening.now.pose(minute: Evening.minuteNow) : nil
+    }
+
+    /// Puts her into the pose for her bed: reading with her book, asleep, or
+    /// sitting up with a stretch and a yawn when a child is seen to in the night.
+    private func settle(in bed: BedPose?) {
+        guard let rig = controller.rig else { return }
+        rig.stop("read")
+        switch bed {
+        case .reading?:
+            controller.asleep = false
+            rig.play("read")
+        case .asleep?:
+            controller.asleep = true
+        case .stirring?:
+            controller.asleep = false
+            rig.play("wake")
+        default:
+            controller.asleep = quiet
+        }
+    }
+
+    /// How everyone arrives just now. Back within twenty minutes, she is already there. Sat at the table or in
+    /// bed, they fade in where they are. Indoors they walk in; outdoors they mostly come up from behind the hill,
+    /// and walk in along the ground one day in four.
+    private func arrival(room: Room?, settled: Bool) -> ArrivalStyle {
+        guard fullEntrance else { return .none }
+        if reduceMotion || settled { return .fade }
+        if room != nil { return .walk }
+        #if DEBUG
+        // For checking: "-debugArrive walk" or "rise".
+        if let forced = UserDefaults.standard.string(forKey: "debugArrive") { return forced == "walk" ? .walk : .rise }
+        #endif
+        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
+        return day % 4 == 3 ? .walk : .rise
+    }
+
+    /// A moment of the empty scene before anyone arrives, while Today finishes opening.
+    private static let beat = 0.2
+
+    /// From where someone stands to just past the nearer edge of the scene.
+    /// With someone already there, she comes from the other side, so the two walk towards each other
+    /// rather than her walking through them.
+    /// Which side is decided from places on the stage (fractions of its width), so it holds while the scene is
+    /// still being laid out.
+    private static func edge(from x: CGFloat, width: CGFloat, awayFrom other: CGFloat? = nil, mine: CGFloat? = nil) -> CGFloat {
+        let here = mine ?? (width > 0 ? x / width : 0)
+        let side: CGFloat = other.map { $0 > here ? -1 : 1 } ?? (here < 0 ? -1 : 1)
+        return side * (width / 2 + 70) - x
+    }
+
     private func playEntrance() {
-        guard !reduceMotion else { appeared = true; return }
+        let gone = Self.leftAt.map { Date.now.timeIntervalSince($0) } ?? .infinity
+        fullEntrance = gone > 20 * 60
+        #if DEBUG
+        // Checking an entrance: play it in full every time.
+        if UserDefaults.standard.string(forKey: "debugArrive") != nil { fullEntrance = true }
+        #endif
+        if fullEntrance, !reduceMotion {
+            // Coming back to Today can keep the phone busy for a moment. The entrance starts from a task, which runs
+            // only once that is over, so the walk or the rise is seen rather than played behind a frozen screen.
+            Task {
+                try? await Task.sleep(for: .seconds(0.2))
+                entrance += 1
+                // Nobody shows until their entrance has begun. See `ArrivalPose.live`.
+                try? await Task.sleep(for: .seconds(Arrival.unhideAfter))
+                self.away = false
+            }
+        } else {
+            entrance += 1
+            self.away = false
+        }
+        guard fullEntrance, !reduceMotion else {
+            appeared = true
+            // Back after a moment: she was here all along. A blink, and she looks up at you.
+            guard !reduceMotion, controller.rig?.asleep == false else { return }
+            controller.rig?.blinkAt = .now.addingTimeInterval(0.15)
+            controller.look(x: 0, y: -0.6)
+            Task {
+                try? await Task.sleep(for: .seconds(1.2))
+                controller.look(x: 0, y: 0)
+            }
+            return
+        }
         var instant = Transaction()
         instant.disablesAnimations = true
         withTransaction(instant) { appeared = false }
         withAnimation(.spring(duration: 0.75, bounce: 0.35).delay(0.12)) { appeared = true }
+        glanceAtCompany()
+    }
+
+    /// Once she has arrived she looks over at whoever is with her, and they answer with their hello.
+    private func glanceAtCompany() {
+        let room = PuggleScene.room(dark: scheme == .dark || night)
+        let bed = bedPose(room)
+        let first = Company.gathering(kind: .today, room: room, afterDark: room == nil && Room.hourNow >= 18,
+                                      bed: bed, minute: Evening.minuteNow).first
+        guard let first, room != .bedroom || bed == .reading else { return }
+        let mine = room == nil ? PuggleScene.stand(for: .today) : (room == .dining ? Company.tea().puggle : 0)
+        Task {
+            try? await Task.sleep(for: .seconds(1.8))
+            controller.look(x: first.x < mine ? -0.8 : 0.8, y: 0)
+            try? await Task.sleep(for: .seconds(1.1))
+            controller.look(x: 0, y: 0)
+        }
     }
 
     /// Pulling the sky down and letting go past the balloon makes Puggle hop.
@@ -627,6 +784,8 @@ private struct CarriedPuggle: View {
     let lift: CGFloat
     let tilt: Double
     let nod: CGFloat
+    /// How far down from standing: behind the tea table, or in bed.
+    var drop: CGFloat = 0
     let onTap: () -> Void
     let onPutDown: (CGFloat) -> Void
     @Environment(\.accessibilityReduceMotion) private var reduceMotion
@@ -655,6 +814,7 @@ private struct CarriedPuggle: View {
                     .rotationEffect(.degrees(tilt), anchor: .bottom)
                     // She hangs from the finger, so she swings from the top.
                     .rotationEffect(.degrees(carry.sway), anchor: .top)
+                    .offset(y: drop)
                     .animation(.spring(duration: 0.32, bounce: 0.25), value: up)
                     .animation(.spring(response: 0.5, dampingFraction: 0.42), value: carry.sway)
             }
```

Also note: the 02:37:37 edit put the new comment `// The tea table in front of everyone at it; at bedtime her quilt, the armchair's arms, a sleeping bag.` above the `RoomFront` line without removing the existing `// The tea table stands in front of her.`, so both comments sit there (as shown). Clean that up if you like.

### 3.7 NEW `app/PuggleTests/EveningTests.swift` (written once, 03:46:19)

```swift
import XCTest
@testable import Puggle

/// Puggle's evening follows the children's (19 November 2026).
final class EveningTests: XCTestCase {
    func testBedtimeByAge() {
        XCTAssertEqual(Evening.bedtime(ageMonths: 5), 19 * 60)
        XCTAssertEqual(Evening.bedtime(ageMonths: 30), 19 * 60 + 15)
        XCTAssertEqual(Evening.bedtime(ageMonths: 60), 19 * 60 + 45)
        XCTAssertEqual(Evening.bedtime(ageMonths: 96), 20 * 60)
    }

    func testByTheClockSheReadsThenSleeps() {
        let evening = Evening(bedtime: 19 * 60 + 15)
        XCTAssertFalse(evening.inBedroom(minute: 18 * 60 + 40))
        XCTAssertTrue(evening.inBedroom(minute: 18 * 60 + 45))
        XCTAssertEqual(evening.pose(minute: 19 * 60), .reading)
        XCTAssertEqual(evening.pose(minute: 19 * 60 + 15), .asleep)
        XCTAssertTrue(evening.inBedroom(minute: 3 * 60))
        XCTAssertFalse(evening.inBedroom(minute: 7 * 60))
    }

    func testFollowingTheLogs() {
        var evening = Evening(bedtime: 19 * 60, followsLogs: true, allAsleep: false)
        // Someone is still up: she reads in the evening, and sits up in the night.
        XCTAssertEqual(evening.pose(minute: 20 * 60), .reading)
        XCTAssertEqual(evening.pose(minute: 23 * 60), .stirring)
        // Everyone asleep straight after tea: she is in bed too.
        evening.allAsleep = true
        XCTAssertTrue(evening.inBedroom(minute: 18 * 60 + 30))
        XCTAssertEqual(evening.pose(minute: 18 * 60 + 30), .asleep)
    }

    func testSheStirsWhenAChildIsSeenToInTheNight() {
        let now = Date.now
        let evening = Evening(bedtime: 19 * 60, followsLogs: true, allAsleep: true, lastLogged: now.addingTimeInterval(-120))
        XCTAssertEqual(evening.pose(minute: 2 * 60, at: now), .stirring)
        XCTAssertEqual(evening.pose(minute: 2 * 60, at: now.addingTimeInterval(600)), .asleep)
    }
}

```

### 3.8 `Design/Rig.swift`: no net change

At 02:36:35 a `hideZs(_:)` method was added to `RigRuntime` before `/// Being carried, for as long as this is true` (a 6263eba comment), setting `held["zed…"]` to a near-zero-scale `PartState`. The first version used `PartState(r: 0, x: 0, y: 0, sx: 0.001, sy: 0.001)`, which doesn't compile (PartState declares `var r = 0.0, x = 0.0, ...` in one line, so there's no such labelled init); it was fixed at 02:39:39 with `var gone = PartState(); gone.sx = 0.001; gone.sy = 0.001`. The whole method was deleted at 02:50:16 when lying down was dropped. **Don't add it.** (Replayed on `rework/wt`: the add, fix and removal all matched the reconstructed 6263eba Rig.swift, and the file is byte-identical afterwards.)

### 3.9 Project file

New Swift files need `xcodegen generate` (run from `app/`, uses `app/project.yml`) before building. The session used `~/.local/xcodegen-dl/xcodegen/bin/xcodegen generate`.

---

## 4. Debug launch arguments and verification

### Launch arguments added in this commit (all `#if DEBUG`)

| Argument | Effect | Where |
|---|---|---|
| `-debugMinute N` | Minute of the hour, only when `-debugHour` is set | `Evening.minuteNow` |
| `-debugBed reading\|asleep\|stirring\|up` | Forces her bed pose (whenever she's in the bedroom) | `Evening.pose` |
| `-debugSleepover <member>\|none` | Forces tonight's sleepover friend (`none` or any non-member → none) | `Evening.sleepover` |
| `-debugTea nan\|pop\|<friend>\|none` | Forces the tea guest | `Company.tea()` |
| `-debugArrive walk\|rise` | Forces the outdoor entrance style; also makes every return play the full entrance | `PuggleHeader.arrival` / `playEntrance` |

Existing arguments used for checking: `-debugHour H`, `-debugOut 0|1`, `-debugCompany kip|none`, `-debugRoom 0..3` (an Int, so the final check's `-debugRoom living` was silently ignored), and `-uitest 1` (always passed by the session; loads the sample family, I believe).

### What the session checked (iPhone simulator `AF626ED5-…`, scheme "Puggle Local", bundle `com.tomgarton.puggle`)

Build: `xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData build`, then `xcrun simctl install $ID DerivedData/Build/Products/Local-iphonesimulator/Puggle.app`.

Screenshots (`xcrun simctl launch --terminate-running-process $ID com.tomgarton.puggle -uitest 1 <args>`, wait 9–13 s, `xcrun simctl io $ID screenshot`):
- Tea: `-debugHour 18 -debugTea nan -debugOut 0`, later `-debugTea kip`.
- Reading in bed with a sleepover: `-debugHour 20 -debugBed reading -debugSleepover kip`.
- Asleep with a sleepover: `-debugHour 20|21 -debugBed asleep -debugSleepover kip|quill`.
- Late at night alone: `-debugHour 23 -debugBed asleep -debugSleepover none`.
- Final settled check (03:42:44): `-debugHour 10`, `-debugHour 18`, `-debugHour 20 -debugRoom living`, `-debugHour 23`. The session's verdict: "Everyone ends up where they belong outdoors, at tea, at bedtime with a grown-up in the armchair, and late at night."

Entrances, recorded as video because screenshots are too slow:
- Cold launch: `xcrun simctl io $ID recordVideo --force v.mp4 &`, launch with `-debugHour 10|14 -debugArrive walk|rise -debugCompany kip`, stop with `pkill -INT -f recordVideo`.
- Return from background: launch, wait 12 s, `xcrun simctl launch $ID com.apple.Preferences`, wait 2 s, start recording, `xcrun simctl launch $ID com.tomgarton.puggle`, wait 4–5 s, stop.
- Frames were pulled with a small Swift tool (`swiftc -O -o vframes frames.swift`; AVAssetImageGenerator at zero tolerance, args `video outdir start step count`) and tiled with an existing `sheetmake` helper. The tool source is in the transcript:
  ```swift
  import AVFoundation
  import AppKit
  let a = CommandLine.arguments
  let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
  let gen = AVAssetImageGenerator(asset: asset)
  gen.requestedTimeToleranceBefore = .zero; gen.requestedTimeToleranceAfter = .zero
  let start = Double(a[3])!, step = Double(a[4])!, count = Int(a[5])!
  for i in 0..<count {
      let t = CMTime(seconds: start + Double(i) * step, preferredTimescale: 600)
      guard let img = try? gen.copyCGImage(at: t, actualTime: nil) else { continue }
      let rep = NSBitmapImageRep(cgImage: img)
      try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(a[2])/v\(String(format: "%02d", i)).png"))
  }
  ```
  (`sheetmake` isn't in the transcript. Any montage tool, such as ImageMagick `montage` or a few lines of Swift/Python, will do.)
- The shell was zsh: arguments in a variable need `${=a}` to split. The first re-shoot loop at 02:47:43 passed them unsplit, so it was redone at 02:48:59.

Tests: `xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData test`. **133 passed before the new tests** (the 6263eba count), **137 after** adding `EveningTests` (4 tests).

### How to re-verify on the Mac

1. Rebuild 6263eba first and confirm its 133 tests pass.
2. Add `Evening.swift` and `Arrival.swift`, apply the Cast/Rooms/TodayView/Tiles changes, add `EveningTests.swift`, run `cd app && xcodegen generate`, build "Puggle Local".
3. Screenshot the scenes above. Expect: tea with Mum/Dad (+ a guest), the cloth hiding feet and a plate+cup per person; reading in bed with the quilt over her legs, a grown-up in the armchair, a friend sitting up in a teal/yellow sleeping bag; asleep tucked in to the chin with the rabbit beside her, the friend's bag to the chin with a pillow; 23:00 alone (no armchair sitter).
4. Record walk and rise entrances, both from cold and from a return from background. Expect: nobody visible before their entrance (no one-frame flash in place); companion first, Puggle 0.2 s later from the opposite side when walking; a squash on landing for rise; Puggle glances at the companion.
5. Return within 20 min without `-debugArrive`: no entrance, a blink and a look up.
6. Pull down Control Centre and back: everyone stays (the `glancing` path).
7. Reduce Motion on: everyone fades.
8. Run the tests: expect 137.

---

## 5. Pitfalls and fixes along the way

1. **Rig `PartState` labelled init doesn't exist** (02:38:54 build error): used `var gone = PartState(); gone.sx = ...`. Moot, since `hideZs` was later removed.
2. **Feet showing under the table / chair / bag** (first screenshots, 02:47:43): every seated pose now drops a fixed 26 pt to the scene foot; the tablecloth grew to 44 pt high with scallops at y 242; the armchair skirt reaches the floor (`rect(chair - 44, 200, 88, 50, 12, deep)`, arms 80 tall); the sitting-up bag front was resized.
3. **Lying down didn't read** (02:50:16): rotating Puggle and the sleepover friend −90° made their front-drawn faces unreadable. Everyone stays upright and "tucked in" (quilt or bag to the chin). Removed the rotation, the `lying` flags, `hideZs`, and the room-drawn Zs.
4. **Quilt too high / rabbit placement** (02:51:36): quilt `rect(4,152,172,44,16)` with the top band at y 150; rabbit beside her at `(118,136)`; the pillow rabbit in the bedroom background is hidden while asleep.
5. **`keyframeAnimator` with different tracks per `switch` branch doesn't compile** (02:55:36): rewrote it as the same four tracks for every style, with values chosen by style.
6. **`CompanyView` has a custom `init`**: the new properties needed init parameters (02:57:03).
7. **Crash on launch: a zero-duration keyframe gives NaN** when `delay` is 0 (03:02:13). Fix: `let delay = max(delay, 0.001)` inside the keyframes builder.
8. **Screenshots too slow for a 1 s walk**: switched to `simctl recordVideo` plus the frame extractor.
9. **The entrance "flash frame" bug** (03:04 → 03:42). Symptom: on entrance, especially returning from background, everyone appeared in their final place for a frame (or the app-switcher snapshot showed them), then vanished and walked or rose in. The walk also stalled at the edge while the app was still busy loading. Steps tried, in order:
   - a. Initial pose opacity 0 when `trigger == 0` (hides them before the very first entrance), plus a 0.3 s `beat` before anyone moves. Fixed the cold-launch case only.
   - b. An `away` flag: Today hides everyone (`.opacity(away ? 0 : 1)` in `Arrival`) from leaving until the next entrance, so the app-switcher picture is the empty scene. Compile clash with the local `let away` in `playEntrance` → renamed it `gone`.
   - c. Clear `away` 0.08 s after the trigger; beat 0.45. Still a flash.
   - d. Start the entrance from a `Task` after 0.2 s (returning to Today can keep the main thread busy; doing it in a task makes the animation play after that, not behind a frozen screen); unhide 0.08 s → 0.2 s later; beat back to 0.2.
   - e. Puggle sometimes picked the wrong side: during the first layout `width` can be 0, so `x/width` was meaningless. Side is now decided from stage fractions (`mine:` param; companion `x` fractions). NSLog tracing showed only one trigger firing and the side now correct. An apparent stray figure was the next contact-sheet thumbnail bleeding in, not the app.
   - f. Hide on `.inactive` (not just `.background`), since a backgrounded app may not redraw and its last frame flashes on return; added `glancing` so a Control Centre / notification glance un-hides without an entrance.
   - g. Gated on a `run` track equal to the trigger. **Didn't work**: frame logging (`ARRIVE draw ...` NSLog in the animator content closure) showed that on the first frame after the trigger changes, SwiftUI draws the keyframes' **end values**, which is everyone in place with the new run value.
   - h. **Final fix**: a `live` track that is 1 for `liveFor` (4 s) from the start of each run and 0 otherwise (including that first end-value frame). Content is hidden while `away && live < 1`. Today clears `away` only `Arrival.unhideAfter` (1.0 s) after bumping the trigger. `@State away` starts `true` so a cold launch is covered too.
   - All NSLog lines were removed before committing. Re-check with `grep -n NSLog Design/Arrival.swift Features/Today/Tiles.swift`.
10. **The simulator shut down** mid-test (03:36:55): `xcrun simctl boot $ID`.
11. **Spec claim**: "Not yet checked on a phone: the entrance's timing as the app opens from cold, which in the simulator is held up by the sample family loading."

---

## 6. Uncertain or unrecoverable

- **Tiles.swift context**: resolved. On `rework/wt` every edit matched; see 3.6. The only "miss" in the whole replay is the 03:30:14 replace of `.opacity(away && style != .none ? 0 : 1)` in Tiles.swift. That text never lived in Tiles (it is in Arrival.swift), so it was a no-op on the Mac too; the next step (03:30:28) made that change in Arrival.swift, and that one matched.
- **Spec placement**: in `rework/wt` the 3504179 section is inserted after the "Build sent to TestFlight (18 November 2026)" section and before the later notes (starting "**The sleep button for toddlers (19 November 2026).**"). On the Mac it came straight after 6263eba's "## Speed pass, and carrying Puggle (19 November 2026)" section, **but that section isn't in `rework/wt`** (the reconstructed 6263eba patch has no spec change). When it is added, put it before "## Tea, bedtime, sleepovers and the entrance".
- **Image turns**: the content of every `[Image]` turn is lost. They appear to be the session's own screenshots and contact sheets, not Tom's. If any was Tom's own feedback, it isn't recoverable.
- **Read-only exploration output** (e.g. `sed -n` views of FamilyStore, CompanyView, the rig `read` move) isn't in the extract. Nothing depends on it beyond what's above.
- **No final post-commit summary to Tom** is in the extract. Whether the session then pushed or told Tom anything isn't known (it wasn't pushed).
- **Addressed in aeccd5f (patch 0004)**: Tom's "the start sleep is missing for [the toddler]" (02:45:07).
- **The final check's `-debugRoom living`** was a no-op (the argument takes an Int), so the 20:00 shot showed whatever the evening logic chose. With no sleep logs that's probably the bedroom (reading), given wind-down from 18:45 for a 19:15 bedtime; the sample family may have logs.
- **Behaviour quirks that shipped** (left as they were; consider with Tom):
  - `Room.at` uses `Evening.now`, which is only refreshed when TodayView's `header` is evaluated. Other callers (widgets, tests) see the default `Evening()` (19:15 bedtime, by the clock).
  - The sleepover check uses day-of-era for now − 6 h, but the tea guest and `Room.at` use today's day, so "comes for tea" and "sleeps over" share a day only because tea (18:00) is after 06:00.
  - Out-tonight (`outTonight`) now ends at wind-down rather than 22:00.
