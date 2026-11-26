# App character animation: rigged and part-based 2D characters in interactive products

Notes on reading this file:
- "Primary" means the organisation's own page was fetched and read. "Search summary only" means the claim comes from a search-result summary and the page itself was not opened; treat those as leads to check.
- "Opinion" marks practitioner blogs, tutorials and vendor marketing.
- Numbers are quoted as the source gives them. Where frame counts are given, the source usually assumes 24 fps film/TV animation unless stated; at 24 fps one frame is about 42 ms.

## 1. Duolingo: how the characters are designed and animated

### Takeaway
Duolingo's published approach is one state machine per character with pose states and mouth states running side by side, small modular clips that are combined at runtime instead of long baked animations, and idle life made from only three things: head nods, blinks and eyebrow movement. The art style is deliberately minimal (few shapes, clear silhouette, exaggerated key details), and personality is controlled by restraint as much as by exaggeration.

### Cited Findings

Rive and state machines (primary: Duolingo blog, Nov 2022)
- Duolingo has ten "World Characters" and teaches 40+ languages across 100+ courses, so hand-animating lip movement was ruled out. Requirements were: scalable, small file size on Android, iOS and web, no loss of animation quality — [Duolingo blog: world character visemes](https://blog.duolingo.com/world-character-visemes)
- Reasons given for choosing Rive: small files, clean fit with the app architecture, a "seamless" animator-to-engineer handoff, and above all the State Machine, which lets code decide which animation states are called and how they transition and blend — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- State machine structure: each character has general pose states for the lesson, and separate mouth states that "have to run at the same time" as the pose states. Mouth inputs are wired into the same state machine, and the whole thing ships as a single runtime file — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- Idle behaviours named in the post are head nods, blinking and eyebrow movement. Final states show a reaction to a correct or incorrect answer — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- Interruptibility is built in: if the learner finishes the exercise before speech ends, the character stops speaking. Tapping a word makes the character say and animate that word — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- Lip sync: "20+ mouths designed for everyone", a viseme chart per character. Speech is run through in-house speech recognition and pronunciation models to get per-word and per-phoneme timing; at runtime the app fetches audio plus timing data and uses the timings to drive the state machine. The post says this is "much less than sending down a little movie" — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- The post gives no file sizes, frame rates or transition timings — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)

Lily in Video Call (primary: Rive's blog about Duolingo; vendor-published case study)
- Lily is described as a "modular actor": motion is split into small pieces that the state machine combines, instead of a pre-baked clip per reaction — [Rive blog: Lily video call](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Idle variety: eight head animations and eight body animations combine to give 64+ neutral movement variations, specifically to avoid a repetitive idle loop. Head and body sit in separate nested artboards so each moves independently — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Expressions are built by layering eyes, brows and mouth separately (compared to risograph printing), so expressions can be mixed on the fly — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Reactions tied to app state: leans in or furrows brows while listening; tilts head or "ponders" during processing delays so the wait looks intended; squints or shakes head when confused; raises an eyebrow and nods when impressed — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Personality through restraint: Lily is deadpan, so wide eyes made her read as too cheerful and the team toned exaggerated movement down while keeping her engaged — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- The final Rive file is under 1 MB — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Workflow: logical input names for developers; designers, animators and engineers met twice a week; a weekly file handoff every Monday — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)

Art style and cast (primary: Duolingo blog)
- Style rules: use few, deliberately placed vector shapes; give key shapes room so the object is "clearly silhouetted"; use the fewest details that make the subject obvious (too few confuses, too many distracts); exaggerate key details nearly to caricature; frame art with white space so it does not interrupt the app — [Duolingo blog: shape language](https://blog.duolingo.com/shape-language-duolingos-art-style/)
- The style moved from flat, pointy shapes to rounder, friendlier forms; animation is used on purpose to draw the eye because motion catches attention — [Duolingo blog: shape language](https://blog.duolingo.com/shape-language-duolingos-art-style/)
- The cast was built to match Duo's visual language: simple geometric shapes, large expressive eyes, a distinctive body shape, detached feet. Design took about 18 months — [Duolingo blog: building character](https://blog.duolingo.com/building-character/)
- Each character has a unique animation on a correct answer, and mid-lesson animations reward several correct answers in a row — [Duolingo blog: building character](https://blog.duolingo.com/building-character/)
- Search summary only (pages not opened; the design.duolingo.com character guide now redirects to the blog hub): shadows under characters are pill-shaped, not ovals, because ovals suggest perspective; repeat shapes across a character for cohesion; mouths are the least geometric element and usually favour one side — [design.duolingo.com illustration](https://design.duolingo.com/illustration)
- Search summary only: in the Vikram redesign the team swapped a circular torso for a pill and describes shapes as carrying personality cues — [Duolingo blog: Vikram redesign](https://blog.duolingo.com/vikram-redesign/)

File size and Lottie versus Rive (conflicting vendor claims, search summary only)
- Rive's marketing page says Duolingo achieved a 15x reduction in file size with Rive — [Rive: Rive as a Lottie alternative](https://www.rive.app/blog/rive-as-a-lottie-alternative); LottieFiles' case study says Duolingo still relies on Lottie to keep files small and performance reliable — [LottieFiles Duolingo case study](https://lottiefiles.com/case-studies/duolingo). Both are vendor pages; neither was opened. The likely reading is that Duolingo uses both, for different jobs.

### Inferences
- The Duolingo pattern maps directly onto Puggle's rig: one layer for held body poses, an independent layer for the face, and a tiny idle vocabulary. Puggle has no mouth, so her "face layer" is eyes, brows and cheeks, which is the same three-part layering Lily uses minus the mouth.
- Lily's 8 x 8 scheme is the cheapest known way to hide a loop: a few short head clips and a few short body clips chosen independently. For Puggle, four head moves and four body moves would give 16 combinations from eight small moves.
- "Processing delay becomes a ponder" is a useful rule: any wait the app imposes can be covered by a character beat, but the beat must be interruptible the moment the wait ends, as Duolingo does when the learner finishes early.
- Lily shows that calm is a personality setting, not a lack of animation: fewer wide-eye poses and smaller amplitudes.

### Gaps
- Duolingo's character personality sheets and the full character section of its design site could not be read (301 redirect to the blog hub). The pill-shadow, shape-repetition and mouth rules are from a search summary only.
- No published Duolingo numbers were found for transition durations, blink intervals, frame rates or per-character file size other than Lily's "under 1 MB".
- The 2023 Duocon talk the visemes post points to was not located or viewed.
- Whether Duolingo "moved" wholly from Lottie to Rive is not established; the two vendor accounts conflict.

## 2. Rive, Spine and Lottie: recommended practice for interactive character rigs

### Takeaway
The common structure across tools is layers (Rive) or tracks (Spine): a base loop on the lowest layer, with reactions on higher layers that key only the parts they need, crossfaded with short mixes. Rive's own performance advice is to let the state machine come to rest so the runtime can pause itself, which matters for battery in an app that sits open at night.

### Cited Findings

Rive (primary: Rive docs)
- A Rive state machine layer plays one state at a time; add layers to run several animations at once. If several layers drive the same property, they mix and one layer wins, so keep separate concerns on separate properties (search summary of Rive layers docs and forum) — [Rive docs: layers](https://rive.app/docs/editor/state-machine/layers)
- The runtime pauses itself when no looping animations or active blend states are playing, so avoid unnecessary looping and use one-shot animations for static idle states — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Blend states must transition to another state or an exit state when finished, otherwise the state machine keeps running — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Pause graphics that are offscreen, and pause when a state machine is idle and waiting on the user or data — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- For Reduce Motion: pause the graphic, turn autoplay off, or load an alternative artboard or state machine — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Part swaps: use Solos to show and hide objects because inactive objects are not rendered — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Keep vertex counts low (thousands hurt), clip specific groups and not the whole artboard, size raster images to display size, cache a file used in several places and make instances from it — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Test on low-end devices; fall back to static graphics, fewer animating entities, or a reduced-motion state machine on older devices — [Rive docs: best practices](https://rive.app/docs/getting-started/best-practices.md)
- Eye tracking of pointer or touch is done with a Pointer Move listener on a hit area plus the Align Target action, which moves a target object to the pointer; pupils follow that target through a constraint. Tracking stops when the pointer leaves the listening area (search summary only; tutorials are practitioner opinion) — [Rive docs: actions](https://rive.app/docs/editor/state-machine/actions.md); [Rive blog: listeners](https://rive.app/blog/a-wild-listener-appears); [Better Programming tutorial](https://betterprogramming.pub/rive-2-2-5d-avatar-with-pointer-tracking-6ea069df2fa)

Spine (primary: Esoteric Software runtime guide)
- "Tracks allow animations to be applied in layers." Tracks apply lowest first, and a higher track overrides only the properties it keys. Example: a shoot animation that keys only arm and gun on track 1 over a walk on track 0 — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- A higher track's alpha blends it with the tracks below, so a layered behaviour can be faded in by degree — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- Crossfades are automatic from a table of mix times. Example values in the docs: default mix 0.1 (seconds), walk to jump 0.2, jump to walk 0.4, jump to run 0.25. These are examples, not recommendations — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- To fade a layered animation in from or out to the rest pose, mix with an "empty animation"; clearing a track without one leaves or snaps the pose — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- Queueing: `addAnimation` plays after the current one finishes; `setAnimation` replaces the current and all queued animations on that track — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- Search summary only (Spine forum, staff replies): large numbers of skins and animations are fine apart from load time; avoid deform keys for performance — [Spine forum](https://ko.esotericsoftware.com/forum/d/27238-scalability-how-many-skins--animations-realistically-fit-into-one-skeleton)

Lottie
- Lottie is a playback format for baked timelines; LottieFiles presents it as small and reliable for one-shot reward animations such as Duolingo's streak milestones (vendor claim, search summary only) — [LottieFiles Duolingo case study](https://lottiefiles.com/case-studies/duolingo)

### Inferences
- Pitfall list implied by the sources: (1) two layers fighting over one property; (2) a blend state or loop that never exits and keeps the renderer awake; (3) reactions that replace the whole pose and so kill the breath; (4) snapping back to rest instead of mixing out; (5) queued reactions piling up when the user taps repeatedly. Spine's set-versus-add distinction is the model answer to (5): a new user-driven reaction should replace the queue, an ambient fidget should wait its turn.
- Asymmetric mixes are worth copying: Spine's own example blends into a jump faster (0.2 s) than out of it (0.4 s). For Puggle, enter a reaction quickly and settle back to idle more slowly.
- For a custom rig, the "self-pause" idea translates to: if Puggle is in a held pose with only breath running and the screen is static, the display link can run at a lower rate or stop between breaths.
- Touch tracking for Puggle should move pupils (and perhaps a few degrees of head) toward the touch and release back to neutral when the touch ends, since the tools all stop tracking when the pointer leaves.

### Gaps
- No authoritative Rive guidance on bones versus part swaps for characters was found; the best-practices page does not cover bones or meshes.
- Spine's additive blending and "hold previous" options are not explained on the page fetched.
- No independent benchmark of Rive versus Lottie versus Spine on iOS was read; a Callstack comparison exists but was not opened ([Callstack](https://callstack.com/blog/lottie-vs-rive-optimizing-mobile-app-animation)).

## 3. Idle animation design: alive without being distracting

### Takeaway
Build idle in layers: a clean base loop (breath) as "ground texture", blinks on a randomised timer, and a small pool of two to four fidgets fired at random intervals, never the same one twice running. A single unvaried loop is reported to become noticeable after about 90 seconds.

### Cited Findings

Structure and variety
- Start with a base loop such as a breathing cycle that loops cleanly and acts as the "ground texture"; add layers (slight head movement, accessory jiggle) that complement each other (instructor blog, opinion) — [AnimSchool](https://blog.animschool.edu/2024/06/14/breathing-life-into-idle-animations)
- Add macro variations that occur over roughly three to six loops, vary timing and frequency, and avoid repeating the same fidget several times in a row — [AnimSchool](https://blog.animschool.edu/2024/06/14/breathing-life-into-idle-animations)
- A single idle loop playing indefinitely becomes noticeable "after about 90 seconds"; recommended remedy is 2 to 4 secondary idles over the base loop at random intervals (vendor blog, opinion; no evidence given for the 90 s figure) — [MoCap Online](https://mocaponline.com/blogs/mocap-news/idle-animation-loop)
- Blend time into and out of idle variations: 0.15 to 0.25 s (Unreal example); variations should finish before returning to base idle — [MoCap Online](https://mocaponline.com/blogs/mocap-news/idle-animation-loop)
- Duolingo's Lily avoids a visible loop by combining 8 head and 8 body animations into 64+ neutral variations — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Duolingo's lesson characters idle with just head nods, blinks and eyebrow movement — [Duolingo blog](https://blog.duolingo.com/world-character-visemes)
- Counter-view (opinion, search summary only): game designer Guido Henkel argues idle breathing is often overdone and near-invisible motion is frequently better — [Guido Henkel](https://guidohenkel.com/?p=1859)

Blinks and eyes
- Blink frame counts (closing / held shut / opening): regular 2 / 1 / 3; fast 2 / 0 / 3; long 3 / 2 / 4. Regular is for keeping the character alive, long is for changes of thought and long head moves (tutorial, opinion; frame rate not stated, presumably 24 fps, which makes a regular blink about 250 ms and a long blink about 375 ms) — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- Opening is slower than closing in every variant above — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- When to blink: on head turns (quick head movements almost always carry a blink), at a realisation, and after a long stare — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- Eye darts take about 3 frames (start, one in-between, end); a change of point of interest 3 to 4 frames — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- Search summary only: Animation Mentor calls the "blink every 2 seconds" teaching outdated and advises blinking for a reason — [Animation Mentor](https://www.animationmentor.com/?p=10065); a tutorial uses roughly one blink every three seconds as a starting cycle — [Pixelbakery](https://pixelbakery.com/education/tutorials/characters-blink-after-effects); a forum implementation randomises the gap between 2 and 5 seconds — [Unreal forum](https://forums.unrealengine.com/t/how-do-i-animate-2d-eyes-on-a-3d-character/468058)

### Inferences
- A workable Puggle idle stack, bottom to top: breath (always on, under everything); blink (random gap, plus forced blinks on head turns and pose changes); eye dart or small head tilt (occasional); fidget pool (rare, long timer); reactions (event-driven, on top).
- Blink timer: draw each gap at random from a range instead of a fixed period; the sources cluster at 2 to 5 s for an alert character. For a calm, sleepy night mood a longer and wider range, with the "long blink" variant used more often, fits the Bloop mapping of long blinks to slow thought. The longer night range is my inference, not a sourced number.
- Fidget pool rules drawn from the sources: 2 to 4 fidgets; never the same twice in a row; aim for something to change within each roughly 90 s window; at most one fidget every three to six breath cycles.
- Given Henkel's caution and the tired-parent setting, amplitude should be small enough that the idle is felt more than seen; the test is whether it pulls the eye away from the data the parent came to read.

### Gaps
- No authoritative source was found for breathing rate in animated idles (breaths per minute or loop length). MoCap Online says only that rate varies by state. Any specific figure (for example a 3 to 5 s breath cycle) would be unsourced.
- No source was found on idle amplitude limits (pixels or percent scale) for UI mascots.
- GDC "Animation Bootcamp" talks and Jonathan Cooper's Game Anim were not accessed; nothing here is drawn from them.

## 4. Timing for UI character reactions

### Takeaway
UI motion guidance converges on 100 to 500 ms, with 200 to 300 ms typical on a phone, ease-out for anything arriving, and shorter and subtler motion the more often it is seen. Springs are the preferred tool on iOS because they keep velocity continuous when interrupted; Apple says bounce 0 is the safe default and bounce above about 0.4 is usually too much for UI.

### Cited Findings

Durations
- General range 100 to 500 ms; use the shortest that is not jarring; animations run too long "far more" often than too short — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)
- About 100 ms feels immediate (toggles, checkboxes); 200 to 300 ms for substantial changes; 400 ms is very slow; at 500 ms animation starts to feel like a drag — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)
- Entering takes slightly longer than leaving: for example 300 ms in, 200 to 250 ms out — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)
- "The more often users see an animation, the more subtle and shorter it should be" (paraphrase of NN/g rule) — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)
- Material Design (original spec): mobile typical about 300 ms; large full-screen up to 375 ms; entering 225 ms; leaving 195 ms; over 400 ms may feel too slow; wearables about 30% shorter, tablets about 30% longer — [Material Design 1: duration and easing](https://m1.material.io/motion/duration-easing.html)
- IBM Carbon duration tokens (search summary only, values from the @carbon/motion package): 70, 110, 150, 240, 400, 700 ms; "productive" motion is significantly faster than "expressive"; duration should grow with distance or size change — [Carbon motion](https://carbondesignsystem.com/elements/motion/overview/)
- Opinion: one Disney-to-UI article says most interface animations fall between 200 and 600 ms (search summary only) — [Marvel blog](https://blog.marvelapp.com/disneys-motion-principles-in-designing-interface-animations/)

Easing
- Ease-out most often, because it feels responsive and lets the eye settle; ease-in for exits; linear looks unnatural — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)
- Material curves: standard cubic-bezier(0.4, 0.0, 0.2, 1); deceleration (entering) (0.0, 0.0, 0.2, 1); acceleration (leaving) (0.4, 0.0, 1, 1). Acceleration and deceleration should be asymmetric — [Material Design 1](https://m1.material.io/motion/duration-easing.html)
- Carbon curves (search summary only): productive standard cubic-bezier(0.2, 0, 0.38, 0.9); expressive standard (0.4, 0.14, 0.3, 1) — [Carbon motion](https://carbondesignsystem.com/elements/motion/overview/)

Springs (primary: Apple WWDC23 "Animate with springs")
- Apple specifies a spring by perceptual duration and bounce (range -1 to 1). Session examples use durations of 0.4, 0.5 and 0.6 s — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Bounce 0: smooth with a long tail, the default and "most versatile"; about 0.15: slightly brisker, not really bouncy; about 0.3: noticeably bouncy; above about 0.4: often too exaggerated for UI — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Choose duration first for pacing, then bounce for character; add bounce for playful feel or to finish a physical gesture; stay consistent with the app's character (serious or playful, relaxed or fast) — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Springs keep position and velocity continuous when retargeted mid-flight; easing curves cannot carry an initial velocity; linear has velocity jumps — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Bounce above 0 is underdamped, 0 is critically damped, below 0 is overdamped. With mass 1, stiffness = (2π ÷ duration)² — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Do not wait on a spring's settling time before letting the user proceed; use the perceptual duration — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Material 3 Expressive splits spring tokens into "spatial" (position, size) and "effects" (opacity, colour), each fast, default and slow. Third-party ports list default expressive spatial at stiffness 380 with damping ratio 0.8 (another port says 0.73) and effects at stiffness 1600, damping ratio 1 (unofficial, search summary only, sources disagree) — [pub.dev M3E motion](https://pub.dev/documentation/m3e_slider/0.0.2/common_m3e_common/M3EMotion-class.html)

Anticipation, overshoot, squash (all opinion, search summary only, values conflict)
- Community guidance: micro-interactions 100 to 200 ms (another says 100 to 300 ms); squash 5% for professional contexts, 5 to 10% for bouncy buttons, 10 to 15% for playful; overshoot 2 to 5% past target; anticipation 20 to 30 ms before a 150 ms action or 40 to 60 ms before a 200 ms action — [playbooks.com animation principles](https://playbooks.com/skills/dylantarre/animation-principles/micro-interactions)

Apple HIG
- Apple's App Store guidance treats "any other ongoing motion" as something to stop, or give the user a control for, under Reduce Motion — [Apple: reduced motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)

### Inferences
- The controlling rule for a character in a utility app: the reaction must never gate the user. The log is saved and the UI is ready at tap; Puggle's nod plays alongside and is cut or retargeted by the next input. Duolingo's "character stops speaking when the learner finishes" is the same rule.
- A reasonable timing budget, derived from the UI ranges above and not from a character-specific source: acknowledgement of a tap (blink, eye glance, small squash) starts within about 100 ms and reads within 200 to 300 ms; a full gesture such as a nod or wave may run longer because it is non-blocking, but its informative part should land inside the first 300 to 500 ms.
- Frequency rule applied: logging a feed happens many times a day, so its reaction should be the smallest and shortest; rare events (first log, milestone, wake-up in the morning) can have the larger moves.
- For calm, Apple's guidance implies bounce 0 to about 0.15 for most body motion, saving 0.2 to 0.3 for daytime hops and waves. Using Apple's stiffness formula, a 0.5 s spring at mass 1 has stiffness of about 158; a 0.4 s spring about 247; a 0.6 s spring about 110 (my arithmetic from the cited formula).
- Anticipation in short UI motion is tiny: on the community figures, a few tens of milliseconds and a few percent. For Puggle that means a slight dip before a hop, not a wind-up.

### Gaps
- Apple's HIG Motion page could not be read (the fetch returned only the title). The commonly cited HIG points (purposeful, brief, optional, subtle for frequent interactions, cancellable) are unverified here.
- Current Material 3 duration and spring token values were not confirmed against m3.material.io; only the older Material 1 page was read directly.
- The damping formula in the WWDC summary came through garbled, so no damping coefficients are quoted; use `Spring(duration:bounce:)` to read exact values.
- No source specific to character reaction length in apps (as opposed to UI transitions) was found.

## 5. Emotional design of companions in calm and wellbeing apps

### Takeaway
The best-documented pattern (Finch) is a companion with a life of its own that keeps going when the user is away, sleeps at night, and invites instead of nags. Published sources say little about how these characters are animated; the evidence is about behaviour and tone, and some of it is contested by users who still report guilt.

### Cited Findings

Finch
- The pet goes on "adventures during the day" and sleeps at night; it is not frozen when the user is away. Completing enough self-care tasks sends it on a timer-based adventure (a 6-hour adventure is cited) (industry analysis, opinion) — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)
- The home-screen widget is described as "non-forceful" and "anti-nag", using event-driven hooks (adventure in progress, rewards ready, a friend visiting) to create curiosity instead of interruption — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)
- Reported retention: D1 54%, D7 37%, against Duolingo's 51% and 35% (third-party estimates in the same article) — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)
- Search summary only: one review says a skipped day does not make the bird suffer the way a broken streak does elsewhere, and attributes the "cozy game" look to reducing "guilt-debt" — [Headway review](https://makeheadway.com/blog/finch-app-review/); a Pratt design critique argues the stress on daily completion can still create pressure and guilt for users who miss days — [Pratt IXD critique](https://ixd.prattsi.org/2024/09/design-critique-finch-ios-app)

Gentler Streak
- The mascot Yorhart (designed with Sören Selleslagh) sits in the top of the Streak tab with the daily status, described as "a love letter from your heart"; it was designed to resonate "regardless of age, gender, race, or body shape" — [Sketch blog interview](https://sketch.com/blog/gentler-streak)
- Users can set status to sick, injured or on a break, which the team frames as designing for real life — [Sketch blog interview](https://sketch.com/blog/gentler-streak)
- Tone rules for copy: supportive without being cheesy, motivating without fake hype, light-hearted — [Sketch blog interview](https://sketch.com/blog/gentler-streak)
- Illustration, transitions and animation exist to make the app feel soft and welcoming, with occasional playful surprises — [Sketch blog interview](https://sketch.com/blog/gentler-streak)

Headspace (search summary only)
- Anna Charity, who led Headspace's brand art direction from 2011, says characters and storytelling break down barriers around a difficult subject and stand in for "the weirdness inside your head"; the brand designs "with feeling and empathy in mind" — [Creative Lives in Progress](https://creativelivesinprogress.com/article/anna-charity); [Dribbble team story](https://dribbble.com/stories/2017/06/21/team-timeout-headspace)
- A third-party analysis (opinion) says of Headspace that the animation timing is the design, citing a breathing circle that expands and contracts with the spoken guidance — [Blake Crosley guide](https://blakecrosley.com/guides/design/headspace)

Neko Atsume (search summary only)
- The developer's stated aim was a game anyone could enjoy without investing skill or time; sessions are very short, often seconds; critics note the passive design avoids challenge so players only receive light, rewarding signals — [Wikipedia: Neko Atsume](https://en.wikipedia.org/wiki/Neko_Atsume); [Ludus Novus](https://ludusnovus.net/2015/07/30/the-feline-grace-of-neko-atsume)

### Inferences
- Rules that transfer to Puggle: the character never looks sad, hungry or neglected because of what the parent did not log; she has her own small life (she dozes, plays, is found doing something) so that opening the app is a discovery, not a debt; she mirrors time of day by sleeping at night.
- Night behaviour that follows from Finch's sleeping pet and the app's users: at night Puggle is asleep or drowsy by default, with breath only, and a tap gets at most a small stir (ear or eyelid) instead of a full wake. The "wake" move belongs to morning. This is inference; no source specifies night-mode animation for any of these apps.
- The Pratt critique is a warning that even kindly framed companions produce guilt if tied to daily completion. Puggle's reactions should attach to what was done, never to gaps.
- Gentler Streak's sick or on-a-break status suggests a similar kindness for parents: hard nights are normal states, not failures, and the character's manner should match.

### Gaps
- No primary source from Finch's founders on a "never punish" rule was found; the anti-guilt framing is from reviewers and an industry blog.
- No source was found describing Calm's or Forest's character or motion behaviour, Tamagotchi-style neglect mechanics, or any app's night or low-energy animation rules.
- Headspace's animation style guide itself was not found; nothing here quotes it. The Anna Charity podcast on character design was not accessible.
- Nothing was found on how Yorhart is animated; the Sketch interview treats it as an illustration.

## 6. Accessibility: Reduce Motion, vestibular safety, flashing, still fallback

### Takeaway
Apple's own decision rule is: decorative motion stops under Reduce Motion; meaningful motion is replaced with a dissolve, highlight fade or colour shift; motion without known triggers may stay. A looping character idle counts as "ongoing motion", so under Reduce Motion it should stop or the user should have a control.

### Cited Findings
- Apple's three-step test per animation: purely decorative, stop it when Reduce Motion is on; conveys meaning, keep the meaning with a motion-free or low-motion substitute; no problematic triggers, may keep as is — [Apple: reduced motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- Named triggers: parallax, animated blur and depth effects, multi-axis motion, multi-speed motion, spinning and vortex effects, scaling and other 3D simulation, peripheral motion, auto-advancing carousels and "any other ongoing motion" — [Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- Suggested replacements: dissolve, highlight fade, colour shift — [Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- Ongoing motion should stop on the user's setting or have a control to stop it — [Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- Apple warns against stripping all animation, since removing meaningful motion can make the app more confusing; an in-app setting is acceptable if it matches or refines the system one; re-check on every update — [Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- WCAG 2.3.3 (Level AAA): motion animation triggered by interaction can be disabled unless essential. Colour and opacity changes are not "motion animation"; an erratum removed blur from that exemption — [W3C: Understanding 2.3.3](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html)
- Vestibular reactions listed by W3C: distraction, dizziness, nausea, headaches, in severe cases needing bed rest — [W3C](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html)
- Rive's guidance for reduced motion: pause, disable autoplay, or load an alternative artboard or state machine — [Rive docs](https://rive.app/docs/getting-started/best-practices.md)
- SwiftUI's built-in symbol effects with significant motion (bounce, scale, rotate, wiggle) dampen or skip under Reduce Motion; custom animation must handle it itself, commonly by swapping a bouncy spring for a calmer one or removing the animation (practitioner blogs, search summary only) — [Use Your Loaf](https://useyourloaf.com/blog/reducing-motion-of-animations/)
- NN/g: respect Reduce Motion and limit parallax, scroll-jacking and flashing, which can cause dizziness, nausea or seizures — [Nielsen Norman Group](https://www.nngroup.com/articles/animation-duration/)

### Inferences
- Mapping to Puggle under Reduce Motion: breath, sway, hop, walk-on-the-spot and spring secondary motion are decorative ongoing or scaling motion, so they stop. State changes that carry meaning (asleep versus awake, acknowledged a log) are kept by cross-dissolving between held poses over a short fade. Blinks are a small, local, non-translating change; keeping them is defensible but is a judgement call, and the strict reading of "ongoing motion" would remove them too.
- The still fallback should be a deliberately chosen held pose per state (a good drawing for awake, for asleep, for pleased), not a frozen frame of the idle, with pose changes by fade.
- Squash and stretch is scaling, which Apple lists as often problematic; under Reduce Motion drop it entirely.
- Hops and bounces near the edge of the screen are peripheral motion; in normal mode keep large moves for when the character is the focus of the screen.

### Gaps
- The WCAG flashing limit (three flashes per second, SC 2.3.1) and the five-second rule for auto-playing motion (SC 2.2.2) were not fetched in this session; they are stated from general knowledge and need a citation check before use.
- Apple's HIG Motion and Accessibility pages could not be read directly.
- No source addresses animated characters under Reduce Motion specifically; Apple's page does not mention characters or loops by name.

## 7. Two or more characters on screen

### Takeaway
No source was found that gives rules for multi-character idle scenes in apps. The closest solid ground is the classical staging principle, that the audience can only follow one idea at a time, plus the eye-dart and blink conventions for showing attention between characters.

### Cited Findings
- Staging: present one idea at a time and lead the viewer's eye to where the action will occur, or viewers may watch the wrong thing (search summary only) — [SIGGRAPH education: staging](https://education.siggraph.org/static/HyperGraph/animation/character_animation/principles/staging.htm)
- A game-design article qualifies this: in interactive work several things do happen at once, so stage the most important element as the core (opinion, search summary only) — [Game Developer: staging](https://gamedeveloper.com/design/adding-weight-to-your-game-design-part-3-staging)
- Left-to-right eye darts read as conversation, looking at the other person's eyes; a change of point of interest takes 3 to 4 frames; head turns almost always carry a blink — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- Animal Crossing: villagers hold conversations with each other when facing each other, and the player can listen or sometimes join; character interaction flow is managed by an internal Nintendo system called EventFlow; behaviour is driven by personality type and not species so players feel a consistent connection (fan wiki and news coverage, search summary only) — [Nookipedia: Conversation](https://nookipedia.com/wiki/Conversation); [My Nintendo News](https://mynintendonews.com/2020/09/06/nintendo-discussed-how-they-created-animal-crossing-new-horizons-villagers/)
- Players criticise Animal Crossing: New Horizons for repetitive villager dialogue shared across a personality type (community opinion, search summary only) — [Twinfinite](https://twinfinite.net/features/ways-animal-crossing-new-horizons-even-better/3/)
- Duolingo gives each character its own unique correct-answer animation, so the cast is told apart by how they move — [Duolingo blog: building character](https://blog.duolingo.com/building-character/)
- Finch surfaces random friend visits as a light social event — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)

### Inferences
These are design proposals derived from the staging principle, not sourced rules.
- One mover at a time: a scene-level "conductor" owns a single gesture token. Breath and blinks are always allowed for everyone; any larger move (wave, nod, hop, fidget) needs the token. This turns the staging rule into a scheduler.
- Offset the always-on layers: give each character a different breath period and phase and an independent blink timer so they never pulse in unison, which reads as mechanical.
- Call and response: A looks at B (eye dart, then small head turn with a blink), a short beat, B looks back, then B answers with a gesture. The gap is what reads as listening.
- User tap takes priority: the tapped character reacts first and at once; the others glance toward it after a short delay and stay smaller. A tap pre-empts any ambient exchange.
- Relationship comes from a small set of repeatable scripted pairs (one waves, the other nods; one dozes, the other glances and settles) drawn from a pool with no immediate repeats. The Animal Crossing complaint suggests per-pair variation matters more than quantity.
- Distinct movement signatures per character (tempo, amplitude, favourite gesture), following Duolingo's unique-animation-per-character practice.
- At night, the scene's default should be that most of the cast are dozing and only one is ever awake enough to react.

### Gaps
- No primary or practitioner source was found on turn-taking, gaze between characters, or scripted pair interactions in apps or virtual pets. Neko Atsume sources found describe its passive play, not how cats interact with each other.
- Nintendo's own account of villager interaction design was not read; the EventFlow detail is from news coverage of a talk.
- No numbers were found for delays between one character's action and another's response.

## 8. Technical craft for part-based rigs

### Takeaway
Treat the rig as layers with breath at the bottom, reactions keyed only on the parts they need, short asymmetric crossfades, and springs for anything that trails (tail, bill, accessories). Start secondary springs near critical damping and loosen until the motion looks alive; over-damped secondary motion reads as sluggish, under-damped as jittery.

### Cited Findings

Springs and secondary motion
- Damping ratio below 1 oscillates before settling; exactly 1 reaches the target without overshoot (Unity and Unreal definitions, search summary only) — [Unity docs: SpringJoint2D dampingRatio](https://docs.unity3d.com/450/Documentation/ScriptReference/SpringJoint2D-dampingRatio.html)
- A tutorial suggests starting near critical damping and lowering the ratio until motion looks alive, around 0.5 to 0.6 for hands and gestures, warning that over-damped secondary motion looks sluggish (opinion, search summary only) — [Three.js From Zero](https://masterallarts.pages.dev/learn/threejs-from-zero/s3-05-procedural-animation/)
- In a chain, each joint lags its parent and the lag accumulates toward the tip, so chains "bend and whip" instead of swinging as one piece; offset a keyed wave slightly per segment and let the spring add lag on top (mod-library docs, search summary only) — [AzureLib: secondary motion](https://moddedmc.wiki/en/project/azurelib/latest/docs/misc/animating/secondary_motion)
- Apple: bounce 0 is critically damped, positive is underdamped; around 0.15 is brisk without visible bounce, 0.3 visibly bouncy; springs carry velocity through interruptions — [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10158/)
- Material 3 Expressive default spatial spring: stiffness 380, damping ratio 0.8 or 0.73 depending on the port (unofficial, search summary only) — [pub.dev M3E motion](https://pub.dev/documentation/m3e_slider/0.0.2/common_m3e_common/M3EMotion-class.html)
- Academic work on secondary motion for 2D rigs: Willett et al. 2017 describe composable "follow", "rest pose" and "collision" rigs for performed 2D animation (paper not read, search summary only) — [Willett et al., Princeton](https://pixl.cs.princeton.edu/pubs/Willett_2017_SMF/paper.pdf)

Layering and blending
- Higher layers should key only the parts they need, so the lower layer (walk, breath) continues underneath — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- Example mixes: 0.2 s into an action, 0.4 s back out; default 0.1 s — [Spine: applying animations](https://esotericsoftware.com/spine-applying-animations)
- Idle variation blends of 0.15 to 0.25 s — [MoCap Online](https://mocaponline.com/blogs/mocap-news/idle-animation-loop)
- Breath as base "ground texture" with overlap travelling up from the hips through the spine (3D-oriented, opinion) — [AnimSchool](https://blog.animschool.edu/2024/06/14/breathing-life-into-idle-animations)
- Build expression from separately layered eyes, brows and (for Lily) mouth — [Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)

Squash and stretch through scale
- Community figures: 5% squash for restrained contexts, 5 to 10% for bouncy, 10 to 15% for playful; overshoot 2 to 5% (opinion, search summary only, not from a standards body) — [playbooks.com animation principles](https://playbooks.com/skills/dylantarre/animation-principles/micro-interactions)
- Scaling is on Apple's list of often-problematic motion for sensitive users — [Apple: reduced motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)

Performance
- Let the animation system rest when nothing is moving; pause offscreen; keep vector complexity low — [Rive docs](https://rive.app/docs/getting-started/best-practices.md)

### Inferences
- Suggested spring feel by part, from the cited ranges (values to test, not sourced per part): head and body pose changes at damping ratio about 0.8 to 1.0 (Apple bounce 0 to 0.15) for calm; tail and loose accessories at about 0.5 to 0.7 with lower stiffness so they trail and settle with one small overshoot; at night push everything toward 1.0.
- Delay down the chain: drive the tail tip from the tail base's motion with a softer spring, so lag accumulates as the AzureLib description says. With only one or two tail parts, a softer spring plus a small rotation offset is enough to suggest an arc.
- Pose-to-pose with holds suits this rig and the calm brief: move quickly between strong held drawings on a spring, then hold with only breath and blink. Continuous motion everywhere is what reads as restless. This matches Duolingo's "pose states" plus small idle set, though Duolingo does not state it as a rule.
- Squash on a part: apply through scale about a pivot at the contact point (feet for a hop landing), keep the area roughly constant (widen as you shorten), and stay in the 5% region for this app.
- Breath under everything: implement breath as an additive offset (small scale or translate on torso, passed to head and arms with slight delay) applied after the pose is resolved, so no reaction can cancel it. This mirrors Spine's "higher tracks only key what they need".
- Arcs with few parts: rotate about pivots instead of translating, and let the head lead with the body following a few frames later, which gives overlap without extra parts.

### Gaps
- No source gave tested spring constants for 2D character parts (tails, ears, accessories); the 0.5 to 0.6 figure is from a single 3D web tutorial.
- No source was found on pose-to-pose versus continuous motion specifically for app mascots, or on area-preserving squash values for flat part rigs.
- The Willett et al. paper, the most relevant 2D-specific source, was not read.
- Classical sources on drag and overlapping action timing (frame offsets between parent and child parts) were not retrieved.
