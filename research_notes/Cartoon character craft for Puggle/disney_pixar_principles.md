# Disney and Pixar character design and animation principles, applied to a simple flat 2D part-based character (Puggle)

Notes on conventions used below:
- Frame counts are as given by the sources, which assume film rate (24 frames per second) unless stated. 1 frame at 24 fps = about 42 ms; at 60 fps multiply the frame count by 2.5.
- Text in "quotation marks" is a direct quotation (kept very short). Everything else is paraphrase.
- "Lasseter 1987" = John Lasseter, "Principles of Traditional Animation Applied to 3D Computer Animation", SIGGRAPH 87. I read the full scanned paper. It is the best freely available primary source because it restates Thomas and Johnston (The Illusion of Life) and Whitaker and Halas (Timing for Animation) with citations, and applies them to a character with no face at all (Luxo Jr.), which is the closest classic analogue to a no-mouth, few-part rig.
- I did NOT have direct access to the text of The Illusion of Life, The Animator's Survival Kit, Drawn to Life, or Preston Blair's books. Claims attributed to them come through the secondary sources cited. Items I could not verify are listed under Gaps and must not be treated as sourced.

## 1. Disney's 12 principles: what each is, and which matter most for a simple cut-out / part-based character

### Takeaway
For a rig with few parts and no mouth, the load-bearing principles are timing and spacing, staging (one idea at a time, clear silhouette), anticipation, slow in and slow out, follow-through and overlap (offsetting parts by a frame or two, never stopping everything on the same frame), arcs, whole-body squash and stretch for attitude, and appeal (simplicity, asymmetry). Lasseter's Luxo Jr. shows all of these working on a hinged character with no face; "solid drawing" and "straight ahead" are the two that transfer least.

### Cited Findings

Origin and list
- The twelve principles were set out by Frank Thomas and Ollie Johnston in The Illusion of Life: Disney Animation (1981): squash and stretch, anticipation, staging, straight ahead and pose to pose, follow through and overlapping action, slow in and slow out, arc, secondary action, timing, exaggeration, solid drawing, appeal. — [Wikipedia, Twelve basic principles of animation](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- The principles came out of 1930s Disney: Walt Disney set up drawing classes under Don Graham, animators studied live action frame by frame, and procedures were gradually isolated, named and taught as rules of the trade. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Lasseter lists 11 (he omits solid drawing) and says timing, anticipation, staging, follow through, overlap, exaggeration and secondary action apply identically in any medium, while squash and stretch, slow in and out, arcs, appeal, straight ahead and pose to pose keep their meaning but change in application. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Squash and stretch
- Lasseter calls it the most important principle. Definition: defining rigidity and mass by distorting shape during action. The key rule is constant volume: if a shape squashes down its sides must bulge out, otherwise it reads as shrinking; if it stretches up it must narrow, otherwise it reads as growing. The reference object is the half-filled flour sack. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- In practice this is done with scale: scale up on the axis of travel and scale down on the other axes to hold volume, and rotate so the stretch lies along the path of action. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- A character need not deform to squash and stretch: a hinged object like Luxo Jr. squashes by folding over on itself and stretches by extending fully. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- How much it squashes tells the audience what it is made of: soft things squash a lot, rigid things little; parts of different materials should respond differently. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Anti-strobing rule: when an object moves so fast that its position on one frame does not overlap its position on the previous frame, the eye sees separate images. Stretch it along the path until successive positions overlap, or nearly. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- In faces, squash and stretch links the parts: a broad smile pushes cheeks up into the eyes, making them squint, which lowers the brows; surprise does the reverse (eyes wide, brows pushed up). — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Ollie Johnston's notes: squash and stretch the entire body for attitudes; pick the best areas of a pose to show it and keep those areas simple; keep skull size consistent but give cheeks, mouth and eyes a plastic quality. — [Notes from a lecture by Ollie Johnston, PDF by Jon Hooper 1999](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

Timing and spacing
- Timing is the number of frames given to an action, and so its speed; it communicates weight, mood, emotion and personality. — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- Give enough time, but no more, to each of three beats: the anticipation, the action, and the reaction. Too long and attention wanders; too short and the idea is over before it is noticed. — [Lasseter 1987, citing Whitaker and Halas](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Weight and size come from timing: heavy and large characters start, stop and change direction slowly; small characters have less inertia and move more quickly. Perceived weight depends on the spacing of poses, not the poses themselves. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Emotional state is defined more by movement than appearance: speed variation shows lethargic, excited, nervous or relaxed. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- The Thomas and Johnston head-turn table (quoted in Lasseter): take two drawings of a head, tilted one way then the other. The number of inbetweens alone changes the meaning. Paraphrased: 0 = struck by huge force; 1 = hit by an object; 2 = nervous tic; 3 = dodging; 4 = a crisp order; 5 = a friendlier beckon; 6 = sees something desirable; 7 = trying to get a better look; 8 = searching; 9 = appraising thoughtfully; 10 = stretching a sore muscle. So a head tilt lasting about 5 to 8 frames (0.2 to 0.33 s) reads as snappy and commanding or eager, and about 9 to 11 frames (0.4 to 0.45 s) reads as considered or thoughtful. — [Lasseter 1987, quoting The Illusion of Life](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- A very fast action can be only 3 or 4 frames if it is well prepared: Wally B.'s zip-off is 3 or 4 frames long but is preceded by a long anticipation. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- The audience loses the first 6 to 8 frames of a scene (about a quarter to a third of a second), so nothing important should happen there. — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

Anticipation
- An action has three parts: preparation, the action proper, and termination. Anticipation is the preparation. It has a physical basis (a foot pulls back before a kick) and without it actions look abrupt and stiff. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- It is also an attention device: it tells the audience what is about to happen and where to look. In Luxo Jr., Dad looks offstage and reacts before Jr. hops in, so the audience is ready. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Trade-off rule: the more the audience is prepared, the faster the action can be. If an action is very fast, make the anticipation bigger or slow the action. In slow actions anticipation is often minimal. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Anticipation also works for subtle acting, for example looking toward something before acting on it. — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)

Staging
- Thomas and Johnston's definition, widely quoted: presenting an idea so that it is "completely and unmistakably clear". — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- Only one idea should be seen at a time. If a lot moves at once the eye does not know where to look. In a still scene the eye goes to movement; in a busy scene the eye goes to what is still. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Stage in silhouette. Early Disney characters were solid black, so a hand in front of the chest vanished; animators learned to put actions out to the side where they read against the background. Andre scratches his side, not his stomach, for this reason. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Johnston: changes of expression are points of interest; hold the character still for them, because if the head moves too much the subtle action is not seen. Actions can be eliminated and staging "cheated" if it simplifies the picture. — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

Follow through and overlapping action (and drag)
- Follow through is the termination of an action; actions rarely stop dead but carry past their end point. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Parts do not move simultaneously. One part leads and the rest follow. Most body actions start at the hips; the wrist leads the fingers; and the eyes usually lead the head. — [Lasseter 1987, citing Don Graham](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Loose parts drag behind the lead and take longer to settle; the amount of drag and settle time is proportional to weight (light antennae drag slightly, heavy floppy feet drag far behind). — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Offsets can be tiny: Wally B.'s feet leave one after the other about one or two frames apart. On Luxo Jr.'s landing, the arms compress two frames after the base hits the floor. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Overlap also applies between whole actions: never bring one action to a complete stop before starting the next. Walt Disney's explanation (quoted in Lasseter) is that a character who knows what it is going to do starts the next action before finishing the current one. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Follow through includes overshoot then return toward the centre of mass with damped oscillation; fleshy parts move more independently than bony parts. — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)

Moving holds
- A moving hold is a way to keep a character on a key pose for a long time without it looking dead. — [Animation Mentor, Shawn Kelly (as surfaced in search; page itself returned 403)](https://animationmentor.com/blog/why-all-animators-need-to-master-the-moving-hold)
- Pixar animator Bobby Beck: a pose that emphasises an idea must stay alive, and the moving hold is as hard as any other part of the shot. Plan which parts arrive first, whether they overshoot, and how they settle; in close-ups the eyes do most of the work of keeping the character alive. — [Bobby Beck on the moving hold](https://filmmakingstuffs.blogspot.com/2008/03/moving-hold-bobby-beck-pixar-animator.html)
- The balance, per AnimSchool: too much movement in the hold feels floaty; a complete stop kills the animation. — [AnimSchool blog, moving holds tag (via search snippet)](https://blog.animschool.edu/tag/moving-holds/)
- Counterpoint from Pixar's Up: animation supervisor Scott Clark said the stylised Carl felt more alive when animated less, and that they would put the face in a pose and let the pose speak. — [Computer Graphics World, The Shape of Animation, June 2009](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx)

Slow in and slow out
- More frames near the start and end of a move and fewer in the middle. — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- Historical reason: once poses became expressive, animators wanted the audience to see them, so they bunched inbetweens close to each extreme with only one fleeting drawing halfway. The result is a spirited zip from one attitude to the next. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Software caution: spline easing overshoots when there is a big value change over few frames. Luxo Jr.'s base dipped through the floor before and after each hop until extra keys locked the curve flat. A heavy thing should pop up and land with a thud, not ease into the floor. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Arcs
- The path between two extremes is almost always an arc; straight paths look stiff and mechanical. Even on a straight-line move, the object usually rotates. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Interpolation flattens arcs on fast moves (the faster, the flatter), which can kill the action; ideally the path of action is controlled separately from the timing curve. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Secondary action
- Lasseter defines it narrowly as an action resulting from another action (the cord rippling as Luxo Jr. hops). Wikipedia's wording of the Thomas and Johnston version is broader: supporting actions that reinforce the main one (arm swing in a walk). Both agree it must stay subordinate; if it competes, cut it or restage it. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf); [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- Expression changes are often secondary to a body move. The risk is not that they dominate but that they are never seen. Change the expression before or after the move, never in the middle of it. — [Lasseter 1987, citing The Illusion of Life](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Johnston's test question: does the secondary action contribute to the main idea or confuse it? — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

Exaggeration
- Not arbitrary distortion. Find the essence of the idea and push it: sad becomes sadder, worried becomes fretting. Exaggeration should be balanced across design, action, emotion, colour and sound, with some elements left natural as a reference point. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Straight ahead vs pose to pose
- Straight ahead gives fresh, zany, scrambling action; pose to pose is for acting, where poses and timing matter most. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- For a hierarchical rig Lasseter recommends working layer by layer: animate the root motion first, then each child transform in turn, with keys on different frames for different channels. Luxo Jr.'s hop was built this way: forward travel (2 keys) set the timing, then height, then arm rotation for anticipation, stretch and follow through, then base and shade. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Solid drawing
- Treating forms as three-dimensional with weight and balance; includes the warning against "twins" (mirrored left and right). — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)

Appeal
- Appeal does not mean cuddly. It means anything a person likes to see: charm, pleasing design, simplicity, communication, magnetism. Complicated or hard-to-read designs, clumsy shapes and awkward moves lack appeal. Appeal is to the animated character what charisma is to an actor. — [Lasseter 1987, citing The Illusion of Life](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Avoid twins in poses and in faces: both arms or legs doing the same thing looks stiff and wooden, and one side of a face should not mirror the other. Andre's yawn works because one arm leads, the head tilts, and the two sides overlap in time. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)

Personality as the goal of all of it
- Personality is not a separate principle; it is the intelligent application of all of them. All actions should result from the character's thought process; without it, actions are unrelated motions. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Same action, different mood: Luxo Jr. chasing the ball hops fast, head up, with very little time on the ground; after the ball pops, each hop is slower, with much more time on the ground, head down. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Same action, different character: Dad (larger, older) leans over and bats the ball with only his shade; Jr. whacks it with his whole body. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Johnston: do not illustrate words or mechanical movements, illustrate ideas or thoughts; ask what the character is thinking; make definite changes from one attitude to another; "Don't move anything without a purpose"; and "Animate simple shapes." — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

### Inferences
(My application to Puggle; not sourced claims.)
- Priority order for a part-based rig with breathing, blink, head tilt, nod, wave, hop:
  1. Timing and spacing: no linear interpolation anywhere; vary durations by mood (the Luxo hop example is a direct template: happy hop = short ground contact, head up; sad hop = long ground contact, head down).
  2. Staging: one idea at a time; expression change before or after a body move, never during; keep waves and props outside the body silhouette.
  3. Anticipation: a small dip or squash before the hop; a small counter-tilt before a head tilt; an eye move before a head move ("eyes lead the head").
  4. Overlap by offset: delay child parts (head after body, tail or bill after head, hand after arm) by 1 to 2 film frames (roughly 40 to 80 ms) and let them settle later. This is nearly free in a rig and is what the sources credit for removing stiffness.
  5. Squash and stretch via non-uniform scale with volume preserved (if scaleY = s, scaleX is about 1/s for a flat character). A flat outlined character can also "squash" by folding or tilting parts like Luxo Jr. Keep the head (skull) rigid and squash the body, consistent with Johnston's note about constant skull size. Constant outline weight under scale is a practical concern the sources do not address.
  6. Arcs: head tilts and waves are rotations so they arc for free; hop travel needs an explicit arc path. Watch for flattened arcs on fast moves.
  7. Moving hold: breathing is Puggle's moving hold. The Up comment suggests a simple stylised design tolerates, and even benefits from, very little motion in holds; so breathing plus blinks plus occasional small settles is probably enough, and constant fidgeting would hurt.
- Lasseter's spline-overshoot warning maps directly onto spring or ease curves in iOS: a hop landing should hit the ground hard and then squash, not ease into or through the ground line.
- The head-turn inbetween table is a ready-made timing dictionary for the head tilt: roughly 0.2 to 0.3 s for alert or eager, 0.4 to 0.45 s for thoughtful. These conversions assume one inbetween = one frame at 24 fps (on ones); if the original was shot on twos the durations double. The source does not say which.
- Principles that transfer poorly: solid drawing (needs drawn volume; replaced here by consistent parts, so the team's equivalent is asset consistency), straight-ahead animation, facial squash and stretch around a mouth (no mouth; cheeks and brows carry it instead), and drawn smear/stretch frames for anti-strobing (scale stretch is the substitute).
- "Twins" is the default failure mode of a symmetrical front-facing cut-out character. Cheap fixes: head tilt, one arm leading, offset timing between left and right parts, asymmetric brows.

### Gaps
- I could not read The Illusion of Life directly; all quotations of it are via Lasseter 1987 or Wikipedia.
- No source I could access gives a frame count or duration for a moving hold. The Animation Mentor (Shawn Kelly) article that reportedly gives tips such as using overshoot and defining an end pose returned HTTP 403, so its details are unverified.
- Richard Williams (The Animator's Survival Kit) on timing charts, "ones and twos", breakdowns and the moving hold: not accessed, nothing verified. Commonly repeated claims (for example that most animation is shot on twos at 12 drawings per second, with ones for fast action) are background knowledge only and unverified here.
- Common rules of thumb such as "anticipation lasts N frames" or "settle lasts N frames" were not found in any accessed primary source.
- Walt Stanchfield's Drawn to Life: not accessed.

## 2. Appeal and character design at Disney: silhouette, line of action, shape language, proportions, model sheets

### Takeaway
Disney-tradition appeal rests on simplicity and readability: a design that reads in silhouette, baby-like proportions for cute characters (big head, low wide-set eyes, short limbs, round tummy), and asymmetry in posing. The cited sources support the silhouette rule and the cute-proportion rules well; shape-language meanings are widely taught conventions sourced mostly to design blogs, and I found no verified numeric head-to-body ratio.

### Cited Findings

Silhouette
- The silhouette rule originates from early black-and-white Disney characters whose bodies, arms and hands were all black; an action could only be read if it was staged clear of the body. Animators concluded it is always better to show an action in silhouette. Thomas and Johnston attribute to Chaplin the idea that an actor who truly knows the emotion can show it in silhouette. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Design guides describe starting a character from its silhouette (a filled outline with no detail) and testing whether it is still recognisable. — [3dsense, Shape language in character design](https://3dsense.net/blogs/shape-language-in-character-design-communicating-through-geometry) (secondary, design blog)
- An academic thesis treats silhouette as one of six design elements affecting perceived appeal, with proportion, exaggeration, colour palette, costume and skin tone. — [Purdue thesis, From Silhouette to Soul (title and abstract via search only)](https://hammer.purdue.edu/articles/thesis/_b_FROM_SILHOUETTE_TO_SOUL_INVESTIGATING_THE_DESIGN_ELEMENTS_THAT_SHAPE_CHARACTER_APPEAL_IN_ANIMATION_b_/28899167)

Cute and young proportions
- Preston Blair's cute-character formula (Advanced Animation), as quoted by Cartoon Brew: head large in relation to body; eyes set low on the head, wide and far apart; fat, short legs tapering into small feet; a bulging, well-fed tummy. Blair bases cuteness on baby proportions plus expressions of shyness or coyness. — [Cartoon Brew, Chappell Ellison, 2013](https://www.cartoonbrew.com/ideas-commentary/why-is-it-so-difficult-to-make-cute-characters-81160.html)
- Lorenz's baby schema (Kindchenschema) lists a relatively large head, large and low-lying eyes, bulging cheek region, and short thick extremities. — [MDPI Behavioral Sciences 14(1):68](https://www.mdpi.com/2076-328x/14/1/68)
- Disney Research reports that infants and young children have much higher head-size-to-body-length ratios, relevant to designing characters for and as young children. — [Disney Research, Designing Animated Characters for Children of Different Ages](https://la.disneyresearch.com/wp-content/uploads/Designing-Animated-Characters-for-Children-of-Different-Ages-Paper.pdf) (via search summary; paper not read in full)
- Lasseter made Luxo Jr. read as a child by scaling parts unevenly, the way a puppy differs from a dog: the bulb (the "head feature") stays the same size while the shade is smaller, and the rods keep the same thickness but are much shorter. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Mickey Mouse's design drifted over time toward larger eyes and head and chubbier limbs. A minimal face (Hello Kitty has no mouth) lets the audience project feeling onto the character. Cute fails when it is over-sweet or when something unsettling sits under it. — [Cartoon Brew](https://www.cartoonbrew.com/ideas-commentary/why-is-it-so-difficult-to-make-cute-characters-81160.html)
- Likeable characters often have symmetrical or baby-like faces; complicated or hard-to-read faces lack appeal. — [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)

Shape language
- The common convention: circles read as friendly and approachable; squares as stable, reliable, stubborn; triangles as dangerous or menacing. Guides stress these are conventions, not fixed rules. — [CG-Wire, Character shape language](https://blog.cg-wire.com/character-shape-language/); [Dream Farm Studios](https://dreamfarmstudios.com/blog/shape-language-in-character-design/) (secondary, design blogs)

Model sheets, consistency
- Johnston's working checklist asks the animator whether they have the model sheets for the character before starting, and his notes stress consistency: keep skull size constant; keep the relationship between eyebrow break and the high point of the eye consistent; check proportions against a profile view. — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)
- Johnston on the face: the eye is pulled by the eyebrow muscles (brows and eyes move as a unit). — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

### Inferences
- Puggle's Miffy-like spec already matches the Blair and Lorenz lists (big head, small body, dot eyes). The items to check on the design are: eyes low on the head and wide apart; short tapering limbs; a slight tummy bulge; cheeks as a distinct feature (the baby schema's "bulging cheek region" supports using cheeks as an emotion channel).
- Luxo Jr.'s method is the cleanest rule for a family cast built from shared parts: to make a child version, keep the "face" features (eyes, bill) near adult size, shrink the body and shorten the limbs, and keep line weight constant.
- With no mouth, Johnston's brow rule matters more: brows and eyes should move together (brow raise slightly lifts or widens the eye; brow lower squashes it), and the cheek should push up into the eye for happiness as in Lasseter's description of a smile.
- The silhouette test for Puggle should be run on poses as well as the design: wave, hop, and any prop interaction should read as a solid black shape.
- "On model" for a rig is mostly enforced by the assets, so the remaining risks are scale and squash limits (do not squash the head), outline weight consistency, and feature placement (eye spacing and height) across characters.

### Gaps
- No verified numeric head-to-body ratio for cute characters (for example "2 to 3 heads tall") from Blair or Disney; the search did not surface one and I did not access the books. Treat any specific ratio as unverified.
- Line of action: not covered by any source I accessed. The usual teaching (a single curved line through the pose, attributed to Preston Blair's Cartoon Animation and to Stanchfield) is background knowledge and unverified here. It applies weakly to a short, round, big-headed character except through head tilt and body lean.
- Formal definitions of model sheet, turnaround and "on model": not found in an authoritative accessed source; only the indirect Johnston references above.
- Shape-language claims rest on design blogs, not Disney primary sources.
- Walt Stanchfield's Drawn to Life (gesture, simplification): not accessed.

## 3. Pixar: appeal, shape language, simplicity, cast contrast, colour, and what Pixar says about eyes and thinking

### Takeaway
Pixar's published position, from Lasseter's 1987 paper onward, is that life comes from a visible thought process and from timing, not from facial detail; Luxo Jr. carried story and emotion with no face. In design, Up is the documented case of pushed shape language ("simplexity": square Carl, round Ellie and Russell), and its animators found that simple designs need restrained animation.

### Cited Findings

Thinking and personality
- Lasseter (citing Don Graham): a character that thinks becomes a character; with a thought process connecting them, actions bring it to life. Animators should always be able to ask what mood the character is in and how it would do this action. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Luxo Jr. told its story with movement alone, in pantomime, with sometimes very subtle movement; this is why attention control (staging) was treated as critical. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Lasseter kept a photocopy of Ollie Johnston's notes (written down by Glen Keane when he was Johnston's assistant) pinned to his desk at Disney and presented them at SIGGRAPH 94, saying they still apply to computer animation. — [frankanollie.com, Animation Notes from Ollie](https://www.frankanollie.com/AnimationNotesFromOllie.html)
- On Toy Story, the animation of Woody's eyes was described as crucial to convincing the audience there is thought behind his actions. — [CACM, Creating Lifelike Characters in Pixar Movies (via search snippet; full text not accessed)](https://cacm.acm.org/magazines/2000/1/7745-on-site-creating-lifelike-characters-in-pixar-movies/abstract)

Eyes (Pixar animators' teaching blog)
- Spline Doctors (blog run by Pixar animators; post signed Andrew, credited to "Dr. Gordon", who worked on Mike Wazowski): the eyes are the first place the audience looks, then the hands. Eye darts are mostly two frames, sometimes one, with no fixed rule; know why the character darts before animating it. A typical close-up dart pattern goes from one of the other person's eyes to the other, then down to the mouth. Blinks need a soft settle as the lid reaches fully open, or they look mechanical. The lid shape should help sell eye direction, and the lid partly closes on a quick sideways eye move. — [Spline Doctors, Eyes in Animation, 2006](https://splinedoctors.blogspot.com/2006/09/eyes-in-animation.html)

Shape language and simplicity (Up)
- Up's visual style is built on square versus circle: Carl is square; Ellie, Russell and Kevin are round. Production designer Ricky Nierva named the approach "simplexity". He warned that stripping away too much detail makes CG look cheap. — [Computer Graphics World, The Shape of Animation, June 2009](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx); [AWN, Going Simplexity](https://www.awn.com/animationworld/going-simplexity)
- Carl is described as three heads tall with stocky limbs (the article's description, not an artist quote). Supervising TD Steve May said they removed anything extra from the models. — [Computer Graphics World](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx)
- Co-director Bob Peterson's reasoning for the square: a cube does not roll or move fast, it is stable, which suits Carl. — [Shmoop study guide quoting Peterson (secondary)](https://www.shmoop.com/study-guides/up/shapes-symbol.html)
- The shape motif extends to props: Carl's photos are in square frames, Ellie's in round ones. — [Pixar Planet, Designing Up inside and out](https://pixarplanet.com/blog/designing-up-inside-and-out/)
- Simple designs are fragile: on Russell, character supervisor Thomas Jordan said the smallest facial change made him look too old; animation supervisor Scott Clark said too much neck movement made him feel "gummy". Clark also said Carl felt more alive when animated less, with the face put in a pose and left to speak. Animators used to subtle pose differences found the restriction frustrating. — [Computer Graphics World](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx)
- Design blogs extend the pattern across Pixar: round protagonists, a blocky Mr. Incredible, a triangular villain dog (Alpha) against a round friendly one (Dug). — [Dream Farm Studios](https://dreamfarmstudios.com/blog/shape-language-in-character-design/) (secondary)

Appeal
- Lasseter's definition of appeal for Pixar's first shorts: charm, pleasing design, simplicity, communication, magnetism; not cuddliness. Appeal in Luxo Jr. came from the baby-versus-adult proportion contrast. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Cartoon Brew credits forward-facing eyes as central to emotional connection across Pixar's non-human characters. — [Cartoon Brew](https://www.cartoonbrew.com/ideas-commentary/why-is-it-so-difficult-to-make-cute-characters-81160.html)

Pixar in a Box
- Pixar in a Box is a Pixar and Khan Academy collaboration taught by Pixar artists; it includes storytelling units (among them character and visual language lessons). — [Pixar, Pixar in a Box](https://pixar.com/pixar-in-a-box); [BMCC OpenLab course page on the Visual Language unit](https://openlab.bmcc.cuny.edu/ani402/?p=291)

### Inferences
- The Up findings are the most directly relevant Pixar evidence for Puggle: a highly simplified character goes off model with very small changes and reads best with held poses and little motion. This argues for a small, fixed set of eye, brow and cheek states with clean transitions, and for testing that no state makes the toddler look older (lowered brows and narrowed eyes are the likely culprits; this specific risk is my inference).
- Luxo Jr. is the proof that a mouthless character can carry emotion through timing, posture (head up or down), and where it looks. Puggle has more to work with than Jr. did (eyes, brows, cheeks).
- Shape motifs can be carried into each character's props and scene elements, as in Up's frames.

### Gaps
- Pixar in a Box lesson content (character, visual language, animation units): I confirmed the course exists but did not retrieve the lesson text or videos, so nothing specific is attributed to it.
- Colour scripts: no source accessed. The CGW article only notes in passing that Up's depth script was tied to its colour script. How Pixar uses colour scripts to plan emotion across a film is unverified here.
- Pixar's "22 rules of storytelling" (Emma Coats): not researched; no claim made. They concern story structure more than design or animation.
- No on-record Pixar "blink rule" (for example for WALL-E) was found.
- The Art of books: not accessed.

## 4. Blinks and eyes: when and why characters blink, timing in frames, eye darts, showing thought with eyes and head only

### Takeaway
Teaching sources agree that blinks are acting, not a timer: blink on a change of thought, on a fast head turn, and on a major change of eye direction, and withhold blinks for intensity. A standard blink is about 6 to 8 frames at 24 fps (roughly 0.25 to 0.33 s) with the eye fully closed for 1 to 2 frames and a slower open than close; eye darts take 1 to 3 frames.

### Cited Findings

Why and when
- Shawn Kelly (Animation Mentor, ILM animator) calls the blink one of the most essential acting tools. He rejects the school rule that characters blink on a fixed interval. People blink when the brain shifts from one thought or emotion to another, on a rapid head turn, and on a major change in eye direction (and to wet the eye). — [Animation Mentor newsletter, Shawn Kelly, Blinks, Nov 2005](https://newsletters.animationmentor.com/newsletter/1105/feature_tiptricks.html)
- Emotion through blink rate: rapid blinks suggest shyness or nerves; withholding blinks suggests intensity. Kelly's example is Tom Hanks in Forrest Gump, who stops blinking on the realisation that the boy is his son. — [Shawn Kelly, Blinks](https://newsletters.animationmentor.com/newsletter/1105/feature_tiptricks.html)
- Kelly cites film editor Walter Murch (In the Blink of an Eye): a blink works like a cut between thoughts. — [Shawn Kelly, Blinks](https://newsletters.animationmentor.com/newsletter/1105/feature_tiptricks.html)
- Kelly's general rule: never animate anything without a reason (matching Johnston's rule about purpose). Decide the character's emotional state first, then ask how someone in that state blinks. — [Shawn Kelly, Blinks](https://newsletters.animationmentor.com/newsletter/1105/feature_tiptricks.html)
- Alexander Williams (Animation Apprentice; feature animator): characters should blink every time they change eye direction; a head turn means new visual information, and the blink edits out the in-between, like a cut. The rule can be broken, but if in doubt add a blink. Without blinks characters look robotic or "zombie-eyed". — [Animation Apprentice, 2020](https://animationapprentice.blogspot.com/2020/09/do-animated-characters-need-to-blink.html)
- Bloop Animation: a blink is not random. Blink on a head turn or any fast head move (almost always), on a change of thought (to mark a realisation), and after a long lingering stare to keep the character alive. — [Bloop Animation, blinks and eye movement](https://www.bloopanimation.com/blinking-animation/)
- Older classroom guidance of a blink at least every 2 seconds is noted by Animation Mentor as resting on the eye-moisture idea, and is contrasted with the acting-based approach. — [Animation Mentor (via search summary)](https://www.animationmentor.com/blog/tutorial-animate-blinks-eye-movement/)

Blink timing in frames (24 fps)
- Standard blink: about 8 frames overall with lids closed for about 2, eased in and out. Offset the lids by one frame. Add a little eyebrow motion with the blink. — [Animation Apprentice](https://animationapprentice.blogspot.com/2020/09/do-animated-characters-need-to-blink.html)
- Bloop's breakdown: regular blink = 2 frames closing, 1 frame closed, 3 frames opening (6 total); fast blink (anxiety, anger, something passing the face) = 2 closing, 3 opening, no hold (5 total); long blink (long head moves, change of thought) = 3 closing, 2 closed, 4 opening (9 total); eye batting = lids three-quarters closed for 1 frame, 2 frames opening. — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- All sources give an asymmetric blink: closing is faster than opening. — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/); [Animation Apprentice](https://animationapprentice.blogspot.com/2020/09/do-animated-characters-need-to-blink.html)
- Add a soft settle at the top of the opening, or the blink looks mechanical. — [Spline Doctors](https://splinedoctors.blogspot.com/2006/09/eyes-in-animation.html)

Eye darts
- Usually two frames, sometimes one; no fixed rule. — [Spline Doctors (Pixar animators)](https://splinedoctors.blogspot.com/2006/09/eyes-in-animation.html)
- Bloop gives 3 frames (start position, one transitional frame, end position), and 3 to 4 frames for a change of point of interest. Meaning by pattern: side to side = conversation, looking between the other person's eyes; up and down = sizing someone up; a triangle = scanning a new place. — [Bloop Animation](https://www.bloopanimation.com/blinking-animation/)
- AnimSchool: about 80 percent of a dart's travel happens in a single frame with a small settle after. — [AnimSchool blog (via search snippet)](https://blog.animschool.edu/2022/08/)
- Too many darts read as spastic or frightened. — [Escape Studios animation blog, How to animate eye darts (via search snippet)](https://escapestudiosanimation.blogspot.com/2020/02/how-to-animate-eye-darts.html)

Showing thought with eyes and head
- The eyes usually lead the head in an action. — [Lasseter 1987, citing Don Graham](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Hold the head still for expression changes; too much head movement hides subtle action. — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)
- The face should not be contradicted by the body; the entire pose should express the thought. — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)
- A head move of about 9 inbetweens reads as appraising or considering; about 7 as trying to get a better look. — [Lasseter 1987, quoting The Illusion of Life](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- In close-ups, the eyes are what keep a held pose alive. — [Bobby Beck](https://filmmakingstuffs.blogspot.com/2008/03/moving-hold-bobby-beck-pixar-animator.html)

### Inferences
- A workable blink spec for Puggle at 60 fps, derived from the frame counts above: close in about 80 ms, stay closed about 40 to 80 ms, open in about 125 to 165 ms with ease-out; total roughly 250 to 330 ms. "Thinking" blink: about 375 ms total with a longer closed hold. Nervous blink: about 200 ms, no hold, possibly doubled.
- For dot eyes with no lids, the blink has to be a vertical squash of the dot to a short line (or a swap to a closed-eye line). The "offset lids by one frame" tip then becomes "offset the two eyes by a frame or less" or is simply dropped; the "brows move slightly with the blink" tip transfers directly and is cheap.
- Idle blinking should be event-driven first (on head tilt, on gaze change, on the moment an idea lands) and only then filled with irregular background blinks so long stares do not die. A fixed timer contradicts the sources; a randomised interval is a compromise the sources do not explicitly endorse.
- A thought beat with only eyes and head, assembled from the sources: hold still; eyes dart (2 to 3 frames) toward the thing; blink; head follows the eyes with slow in and out over roughly 8 to 10 frames; small settle; brows change after the head arrives, not during.
- Withholding the blink is a usable signal for wonder or intense attention in a toddler character; rapid blinks for shyness, which also matches Blair's "shyness or coyness" as part of cute.
- Whether dot eyes can dart at all depends on the design (the dots would have to shift within the head, or the head must turn). If the dots are fixed, gaze has to be shown by head rotation and tilt, and the "eyes lead the head" principle is unavailable; a small shift of both dots toward the target a few frames before the head moves would restore it.

### Gaps
- Richard Williams' The Animator's Survival Kit on blinks and eyes: not accessed. One blog illustration is credited to the book but no text or numbers were verifiable.
- Keith Lango's writing on eyes and blinks: nothing retrieved.
- Animation Mentor's full blink and eye-movement tutorial returned HTTP 403; only search-summary fragments were available.
- No source gave a recommended background blink frequency for an idle character beyond the discredited "every 2 seconds" classroom rule. Human physiological blink rates were not researched.
- None of the sources address blinks for dot eyes or lidless designs specifically.

## 5. Designing a cast as a set, and two characters acting together

### Takeaway
The clearest documented method for a cast that reads as a family is Lasseter's: build members from the same parts and vary proportion, then differentiate them further by how they move (the big one slower and economical, the small one quick and whole-bodied). For two characters on screen, the Luxo Jr. rule is explicit: only one does an important action at a time, attention passes by contrast in motion, and encounters are staged in profile so both silhouettes and the eye line read.

### Cited Findings

Cast contrast in design
- Luxo Dad and Jr. are the same design with parts scaled differently: same bulb size, smaller shade, same rod and spring thickness but much shorter lengths. This both unifies the pair and makes one read as a child. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Up assigns each character a base shape tied to personality (square Carl, round Ellie, Russell and Kevin), and pushes the contrast. — [Computer Graphics World](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx)
- The same film contrasts two dogs by shape: the menacing Alpha is angular against the round, friendly Dug. — [Dream Farm Studios](https://dreamfarmstudios.com/blog/shape-language-in-character-design/) (secondary)
- In The Incredibles each family member's build is said to reflect their power (for example a blocky Mr. Incredible). — [CG-Wire](https://blog.cg-wire.com/character-shape-language/) (secondary)

Cast contrast in movement
- No two characters do the same action the same way: Dad bats the ball by leaning and using only his shade; Jr. throws his whole body into it. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Size dictates tempo: larger characters take longer to start and stop; tiny characters are quicker. — [Lasseter 1987, citing Whitaker and Halas](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Personalities should be distinct yet have traits familiar to the audience. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- In Up, behaviour was tuned per character: Carl barely bends or twists because he is old; Dug's rig behaviour was pushed toward realism; Kevin, an invented creature, was given the most freedom. — [Computer Graphics World](https://cgw.com/Publications/CGW/2009/Volume-32-Issue-6-June-2009-/The-Shape-of-Animation.aspx)

Two characters together
- In Luxo Jr. the action was paced so that only Dad or Jr. was doing an important action at any one time, never both. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Attention transfer by contrast: Jr. moves faster than Dad, so the eye goes to him; while Jr. carries the story, Dad's actions are kept very subtle; when Dad's reaction matters (the head shake after the ball pops), Jr. is toned down and Dad is emphasised. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- General rule behind it: in a still scene the eye goes to what moves; in a busy scene, to what is still. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Pre-direct the eye: Dad looks offstage and reacts before Jr. enters, so the audience is already looking there. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Stage the pair side-on: when Dad and Jr. first meet face to face it reads because it is staged in profile; with Jr. in front of Dad looking up it would be hard to read. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Each beat needs time for anticipation, action and reaction. — [Lasseter 1987](https://www.ics.uci.edu/~fowlkes/class/ics162/exercises/lasseter.pdf)
- Johnston's planning question: where should the audience look, at one character, two, or three? — [Ollie Johnston notes](https://eclass.aegean.gr/modules/document/file.php/511154/Theory/ollie_johnston_notes.pdf)

### Inferences
- For Puggle's family: derive parents and siblings from the same part set with different proportions (Luxo method) so the family reads as a set; give animal friends a different base shape and size class (Up method) so they read as distinct. Colour contrast is the third lever but is not supported by any source I accessed.
- Give each cast member a movement signature using the existing rig verbs: same hop, wave, nod and tilt, but different durations, amplitudes and anticipation sizes per character (parent: slower, smaller, head-only gestures; toddler: quick, whole-body, bigger squash).
- A two-character scene script that follows the Luxo rule: A acts while B holds (breathing and blinks only); A settles; B looks at A (eye or head turn, with a blink); B reacts; then B acts while A holds. The listener's moving hold should be quieter than the actor's smallest gesture.
- Eye lines: a character who looks at the other tells the audience where to look next, and the listener looking at the speaker keeps focus on the speaker. This follows from the Dad-looks-offstage example but the sources do not state it as an eye-line rule.
- A flat, front-facing Miffy-style design conflicts with profile staging. Practical substitutes: put the two characters side by side with clear space between silhouettes, use head tilt and lean toward each other, and keep gestures (waves, pointing) on the outside edge or in the gap, never across the body.

### Gaps
- No primary Disney or Pixar source accessed on designing a line-up (size-comparison sheets, colour contrast across a cast, "squint test"). The common practice of a cast line-up sheet with heights and distinct silhouettes is background knowledge, unverified here.
- No accessed source gives explicit rules on eye lines between two animated characters or on listener behaviour (how much a listening character may move); the guidance above is extrapolated from the Luxo Jr. account.
- Colour as a cast-differentiation tool, and colour scripts, remain unsourced.
