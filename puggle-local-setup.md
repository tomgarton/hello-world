# Setting up a local Puggle session on a second Mac

This sets up a Mac so a local Claude Code session can build, test and upload Puggle. It takes about 30 minutes, most of it the Xcode download.

**First, a caveat.** Today's work is in seven commits that so far exist only on the first Mac. Until that Mac pushes them, this Mac starts from GitHub's copy, which ends at `4be0423` on 18 November. Read the last section before changing any code here.

## 1. Install the tools

1. **Xcode:** install it from the Mac App Store, open it once, and accept the licence. Then, in Xcode → Settings → Components, install the iOS platform and an iPhone 17 simulator.
2. **Command line tools:** in Terminal, run:

   ```bash
   xcode-select --install
   ```

3. **Homebrew:** skip this if `brew --version` already works. Otherwise follow the instructions at https://brew.sh.
4. **XcodeGen and the GitHub CLI:**

   ```bash
   brew install xcodegen gh
   ```

5. **Claude Code:**

   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

   If that changes, the current command is at https://code.claude.com/docs. The Claude desktop app's Code tab works too.

## 2. Sign in

1. **GitHub,** so this Mac can push:

   ```bash
   gh auth login
   ```

   Choose GitHub.com, HTTPS, and log in with a browser. Then run:

   ```bash
   gh auth setup-git
   ```

2. **Xcode:** in Xcode → Settings → Accounts, add your Apple ID and check that team **X2UM64LDU4** is listed. That's what lets this Mac sign the app and upload to TestFlight.

## 3. Get the code

The first Mac keeps its copy in `~/Desktop/Claude Code/hello-world`. Using the same place here keeps paths in the docs familiar.

```bash
mkdir -p ~/Desktop/"Claude Code" && cd ~/Desktop/"Claude Code"
```

```bash
git clone --branch claude/baby-tracking-app-spec-fhtvex https://github.com/tomgarton/hello-world.git
```

```bash
cd hello-world/app && xcodegen generate
```

`Puggle.xcodeproj` isn't kept in git, so XcodeGen has to make it. Re-run `xcodegen generate` after every pull that adds or removes files.

## 4. Check it builds

From `app/`:

```bash
xcodebuild -project Puggle.xcodeproj -scheme "Puggle Local" -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath DerivedData test
```

You should see `TEST SUCCEEDED`. GitHub's copy had about 133 tests; with the first Mac's commits it's 138.

Then check signing without uploading anything:

```bash
zsh tools/testflight.sh --archive-only
```

This should end with "Archived to build/Puggle.xcarchive. Nothing uploaded." If it fails on signing, open `Puggle.xcodeproj` in Xcode once. Under Signing & Capabilities, pick team X2UM64LDU4 for the Puggle and PuggleWidgets targets. Xcode then creates this Mac's certificate. Run the command again.

## 5. Start Claude Code

From the repository folder, not `app/`:

```bash
cd ~/Desktop/"Claude Code"/hello-world && claude
```

To drive it from your phone like the first Mac, type `/remote-control` in the session, or start it with `claude remote-control`.

Paste this as the first message:

> This is Puggle, an iOS SwiftUI baby and family tracker, on branch `claude/baby-tracking-app-spec-fhtvex`; the app is in `app/`. I've been building it with a Claude session on another Mac, which is offline right now. Read `docs/baby-tracker-spec.md` (especially "Questions for Tom" and the dated sections at the end), `docs/HANDOFF.md` and `app/README.md`. Then read the handoff note I'll paste next.
>
> Rules: ask me for a fresh yes before every git push, phone install or TestFlight upload; one yes covers one. Use the sample family only (Bea 2½, Ollie 5 months, Alex, Robin, Nan, Kit), never my children's real names. Never commit my own screenshots. Copy follows `docs/writing-guide.md`. Keep every unchosen option. I like being asked and deciding.
>
> Tell me what state the branch is in, then wait.

Then paste the contents of `puggle-handoff-2026-11-19.md`, the handoff note from the cloud session. It's in the Claude app on your phone, or on GitHub once it's pushed.

## 6. While the first Mac's commits aren't on GitHub

Stick to work that won't clash:

- **Safe:** reading, planning, and drawing mock-ups as pictures. A TestFlight upload of GitHub's copy is also safe, though it would only resend 18 November's build, so it isn't useful.
- **Avoid:** editing Swift files or `docs/baby-tracker-spec.md`. The first Mac changed many of those today, and two Macs editing the same files leads to merge conflicts.

When the first Mac is back:

1. In its session, say **push**.
2. Here, run:

   ```bash
   git pull --rebase && (cd app && xcodegen generate)
   ```

3. From then on, either Mac can work, as long as each pulls before starting and pushes when done. App Store Connect numbers the builds, so uploads from both Macs won't clash.
4. Only one Mac should work on the branch at a time. Before switching, push from the one you're leaving.

## Optional: Xcode Cloud

To stop depending on any one Mac, set up Xcode Cloud: Xcode → Product → Xcode Cloud → Create Workflow, with a TestFlight action on the branch. After that, pushing builds and uploads automatically. Turn it on only after the first Mac's commits are pushed, so the first cloud build is the current app.
