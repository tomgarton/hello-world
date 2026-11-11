# Next steps (written 11 November 2026, 23:25)

A plan for the next working session on the Puggle iOS app, in order. Each step says what done looks like. Steps marked **needs Tom** are left alone until he decides.

## Ground rules

- Work in `app/`. Build with the "Puggle Local" scheme. Re-run `~/.local/xcodegen-dl/xcodegen/bin/xcodegen` in `app/` after adding files.
- Compile-only build (no simulator): `xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData build`
- The Mac is older: one simulator at a time, and shut it down (`xcrun simctl shutdown all`) when not testing.
- Do not change how sync works (`Persistence.swift`, the Core Data model's sync setup, CloudKit). Adding optional attributes is fine; say so in the commit.
- Commit locally with `git -c user.name="tomgarton" -c user.email="tomgarton@users.noreply.github.com"`. **Do not push.** Tom approves each push.
- Copy rules: British and Australian spelling, plain sentences, no em dashes, no guilt wording, no medical advice. The app's name appears only on the splash, the icon and Help. Example child name is "Ollie".
- Never install on Tom's iPhone without him; that needs the phone unlocked and nearby.

## 1. Check what was built today and not yet tested

In the iPhone 17 simulator, using Settings → "Look around a sample family" (or the welcome page's "Look around a sample family first"):

- Stamper: run out of ink (eight presses), hold Skip for two seconds, and stamp a card to its fifth space so the shiny sticker appears; peel and stick it.
- The stamp book and a child's Stickers page.
- Onboarding steps three to eight (fresh install: `xcrun simctl uninstall "iPhone 17" com.tomgarton.puggle` first; this only clears the simulator).
- Day and night looks of Today, Settings and the stamping screens. Night comes on by itself 21:00 to 06:00.
- Page one of the stamper on a small iPhone: create an "iPhone 16e" or "iPhone SE (3rd generation)" simulator with the installed iOS 26.5 runtime, check nothing is cut off, then delete that simulator.

Done: every item seen working, or a list of what broke. Fix small breakages straight away.

## 2. Fix known rough edges

- After inking, the stamper stays on the ink pads where it was dropped. Spring it back to its rest spot on the scrap paper.
- Night mode switching rebuilds the whole app (`.id(...)` on `RootView` in `PuggleApp.swift`), which closes open sheets at 21:00, 06:00 or when a sleep starts. Make the palette re-resolve without rebuilding (for example an environment value the colours read, or `Palette` colours that observe `NightMode`), so sheets stay open.
- At night the tab bar icons and Puggle are not dimmed. Dim them.
- A breastfeed timer can run for hours with nothing asking about it. Add a "Still feeding?" check like "Still asleep?" (after 90 minutes; offer to finish the feed or keep going).
- The Health tile's + was changed to quiet glass without being looked at. Look at it.

Done: each fixed, built, seen in the simulator.

## 3. A real paper curl

The corner fold on the stamp card is a flat mirror fold. Rewrite `paperCurl` in `app/Puggle/Design/Paper.metal` as a cylinder curl: the corner wraps round an invisible roll, with a highlight along the top of the roll, shading into the crease, a soft shadow on the card beneath, and the plainer back of the paper on the flap. Keep `PaperEffects` as the entry point and the same drag gesture.

Done: dragging a corner in the simulator shows a curved roll, not a crease. Send a screenshot.

## 4. Tidy copy and consistency

- Use interpuncts in the "Last saved" row and History, as on the child rows ("Ollie: Nappy · wet").
- Settings → Units: either apply the chosen units on display (volume, weight, temperature) or keep the "coming soon" note. Applying them is preferred if it can be done in one place.

## Needs Tom (do not start)

- Pushing the commits to GitHub.
- Puggle's three sleep states (awake, quiet, asleep with closed eyes).
- Reminders, regular medicines and notifications.
- Pro, tips and anything with in-app purchases (needs the paid developer account).
- Sharing and sync testing (needs the paid developer account).
- Character art for stamps and stickers (needs drawings).

## At the end

Update `app/README.md` with a short table for the round, commit locally, shut the simulator down, and write a summary: what was done, what was checked, what failed or was skipped, and what needs Tom.
