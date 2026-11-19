# Puggle rework: rebuilding the seven unpushed commits

The first Mac is out of reach for six weeks. It holds seven commits from 18 and 19 November that never reached GitHub. They have been rebuilt here from that session's transcript, as seven patches in their original order, with their original messages.

## How sure each one is

| Patch | Original | What | How it was rebuilt |
|---|---|---|---|
| 0001 | `abef6a9` | Spec note: the TestFlight upload of 18 November | Exact: the appended text is in the transcript |
| 0002 | `6263eba` | Speed pass, and the "held" animation for carrying Puggle | Every edit and script replayed. All matched once. Spec text re-added from the transcript. |
| 0003 | `3504179` | Tea with the family, bedtime following the children, sleepovers, the entrance | 37 steps replayed (3 new files, 31 scripts, 3 seds). All matched, except one that was also a no-op on the first Mac. |
| 0004 | `aeccd5f` | Sleep button for any child under four in the day | Exact: the session's script, replayed |
| 0005 | `3c3b8dd` | Ages written as "2½y" | Exact: the session's script and test |
| 0006 | `5e44f05` | Fact lines led by their activity's icon | Exact: the session's script |
| 0007 | `90bd2d0` | Potty and nappy together | Exact: the session's three scripts and spec text |

Every replacement was checked against the file it changed. The final code is identical whether the patches are applied in this order or a different one.

**Not checked here:** none of it was compiled. These were made in a Linux cloud session without Xcode. Every line was written and built on the first Mac, but a slip in the rebuild would only show up when building. So build and test after each patch, as below.

The two briefs in `briefs/` hold the full detail for the two large commits:
- what was asked
- the behaviour as built
- each file's changes
- the pitfalls the session hit (the entrance's one-frame flash took eight tries)
- how to check it

The other five are small enough to read in their patches.

## Applying them on the second Mac

From the repository folder, on a clean `claude/baby-tracking-app-spec-fhtvex` at `4be0423`:

1. Get this folder from GitHub without switching branches. It lives on the `claude/friendly-brown-h65dur` branch:

   ```bash
   git fetch origin claude/friendly-brown-h65dur
   ```

   ```bash
   mkdir -p ~/puggle-rework && git archive FETCH_HEAD puggle-rework | tar -x -C ~/puggle-rework --strip-components=1
   ```

2. Apply one patch at a time, building and testing after each. For patch 0002, for example:

   ```bash
   git am ~/puggle-rework/patches/0002-*.patch
   ```

   ```bash
   cd app && ~/.local/xcodegen-dl/xcodegen/bin/xcodegen generate && xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData test 2>&1 | grep -E "error:|' failed|TEST (SUCCEEDED|FAILED)|Executed [0-9]+ tests" | tail -3; cd ..
   ```

   Use whatever path `xcodegen` has on this Mac; `brew install xcodegen` puts it on the PATH. XcodeGen must run after 0003, which adds three files.

3. Expected test counts on the first Mac:
   - 133 after 0002
   - 137 after 0003
   - 137 after 0004
   - 138 after 0005, 0006 and 0007

   If a build fails, fix it in place, then `git add` and `git am --continue`. The brief for that patch explains what each change was for.

4. When all seven are in, look at each change in the simulator. The briefs have the launch arguments:
   - `-debugBed`, `-debugTea`, `-debugSleepover`, `-debugArrive`, `-debugMinute`
   - `-debugHour`, `-debugRoom` (a number)

   Then ask Tom before pushing or uploading to TestFlight.

## Hints for the session doing this

Paste this to the local Claude session:

> Rebuild the seven unpushed Puggle commits from `~/puggle-rework` (read its README and both briefs first). Apply the patches one at a time with `git am` onto `claude/baby-tracking-app-spec-fhtvex` at 4be0423, regenerate with XcodeGen, build and run the tests after each, and fix anything that doesn't compile without changing the intended behaviour. Then check the new scenes and the potty sheet in the simulator and send me screenshots. Don't push or upload until I say yes.

The patches carry the author "Tom Garton" and the original Claude trailer.

## When the first Mac is back in six weeks

Its seven original commits will clash with these rebuilt ones. **Don't push from it as it is.** In its session or Terminal:

1. Keep a copy:

   ```bash
   git branch backup/mac-19-november
   ```

2. Compare it with the rebuilt work on GitHub:

   ```bash
   git fetch && git diff backup/mac-19-november origin/claude/baby-tracking-app-spec-fhtvex -- app
   ```

   Lines that differ only because of work done since the rebuild are expected. Anything else is a detail the rebuild missed, so copy it across by hand.

3. Then move the first Mac onto GitHub's version:

   ```bash
   git reset --hard origin/claude/baby-tracking-app-spec-fhtvex
   ```

   The backup branch keeps the originals.

## Left open from the 19 November session

- The potty and nappy design: Tom chose option B, then said it "needs more work". Box 3 and Sheet 2 were built for him to try.
- Push the work and upload a TestFlight build? This was the last question asked. The last upload was on 18 November, probably build 16.
- Not checked on a phone: how fast the speed pass feels, the carrying animation, the entrance from a cold start, and the night scenes.
- With Reduce Motion on, Puggle's legs still kick while she's carried. Only the lift and swing are left out.
