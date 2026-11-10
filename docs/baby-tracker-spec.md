# Puggle — Plan & Spec (v1.0)

_Status: design foundation agreed; first build starting. App, brand and character name: **Puggle**._
_Last updated: 2026-11-10._

**How to read this:** §1–3 are the market assessment and where the opening is. §4–7 are the product. §8–10 are how we build and run it. §12 lists the decisions we need to make together.

**Design canvas:** all mockups live on the Puggle canvas, organised into four pages: App, Characters, Brand and world, and Archive (earlier explorations kept for reference).

Claims marked **[verify]** come from third-party roundups or from memory, not from a primary source, and must be checked before we rely on them.

---

## Where we are (2026-11-10)

| Area | Decision |
|---|---|
| Product | Native iOS family tracker for several children at once, newborn to school age; free core, tip jar, one-off Pro unlock later |
| Platform | iOS first, SwiftUI, Core Data with CloudKit (private and shared databases) so a household can share without a server |
| Name and brand | **Puggle** for the app, character, label and trademark; **Puggle and Friends** for stories; **Puggle & Co.** for the company. Logotype: Bricolage Grotesque ExtraBold, lowercase |
| App look | Refined Puggle: calm, native controls (filled pills, soft fields, system toggles), line icons with one accent, character used sparingly. App name only on splash, icon and Help |
| Characters | Puggle (platypus, 2½, potty training) and Pebble (baby platypus, Kewpie curl); friends Quill, Kip, Digby, Sunny; Mum, Dad, Nan, Pop. Flat colour, warm brown outline, dot eyes, blush with stitches, no mouth or brows; emotion through eyes, marks and body; hands always visible; quatrefoil clip |
| World | Australian everyday places and objects; full-colour props for books, fabric and wallpapers; blob sign text; no Aboriginal motifs or trademarked landmarks |
| Next | v0.1 code written in `app/` (Today, logging, history, family sharing on Core Data + CloudKit); build and fix on Tom's Mac (§11 step 3) |

## 0. Working assumptions (agreed 2026-11-10)

- **Team:** Tom (product design) and Claude (engineering). No hired engineers.
- **Shape:** an indie product born from Tom's own two-kid friction, in the Apollo/Crouton mould. Start small, ship, grow from use.
- **Money:** free app with a tip jar, as Apollo did, and a one-off Pro unlock for a handful of extras later. No subscription planned.
- **Household:** all Apple devices; Tom has a Mac with Xcode. CloudKit is confirmed for v1.
- **First users:** Tom's own children, a **6-month-old, bottle-fed** and a **2.5-year-old about to start potty training**. These two define the first build (§11).
- **Consequence:** every choice below favours the least infrastructure to run and the fastest route to an app on Tom's own phone. §8 and §11 were rewritten on that basis.

### How we work together

| Tom | Claude |
|---|---|
| Product decisions, flows, visual design, illustration direction | Architecture, all code, tests, build config |
| Uses the app daily with the family and reports friction | Turns friction into fixes and features |
| Owns Apple Developer account, App Store listing, brand | Drafts store copy, privacy policy, website, support docs |

**Practical constraint:** iOS apps can only be built and run on a Mac with Xcode. This cloud session runs on Linux, so here I can write the spec, website and Swift source, but cannot compile or run the app. For the app itself we work in Claude Code on Tom's Mac, where I can build, run the simulator and fix what breaks.

---

## 1. The thesis in one paragraph

Every leading tracker is built around **one baby and one subscription**. Real families have a newborn *and* a toddler, or twins, plus a partner, grandparents and a nanny on a mix of iPhones and Androids. The opening is a tracker that is **family-first** (several children logged at once, without switching profiles), **properly native** (Live Activities, widgets, watch, gestures, at Apollo/Crouton level of craft), **fairly priced** (all tracking free, no data held hostage, a one-time purchase option) and **region-aware** (official growth charts, check-up and vaccine schedules for the family's own country rather than US defaults).

## 2. Competitor assessment

Prices are US figures from 2026 third-party reviews. **[verify]** all of them in the stores before quoting.

| App | What it is best at | Where it falls short | Pricing |
|---|---|---|---|
| **Huckleberry** | Sleep. "SweetSpot" nap prediction is the feature parents pay for. | SweetSpot has been paid-only since June 2021. Reviews say growth charts and journaling are thin, and low-star reviews focus on how much sits behind Premium. | Free tracker. Plus about $11.99/mo or $58.99–68.99/yr. Premium about $14.99/mo or $119.99/yr. |
| **Baby Tracker (Nighp)** | Fast, comprehensive logging; long-time category staple. **This is what Tom's family uses.** | Ads in the app (Tom's experience). Feels like a web view in a wrapper, so it uses none of the native surfaces (Tom's impression; not confirmed technically). | Free with paid upgrade **[verify]**. |
| **Nara Baby** | Clean, free, multi-child and caregiver sync. Often named the best free option. | Shallow insights, few platform integrations **[verify]**. | Free **[verify business model]**. |
| **Glow Baby** | Multi-user sync, community. | Sits inside a fertility/pregnancy bundle; upsell-heavy **[verify]**. | Sources conflict: $4.99 one-time vs $59.99/yr bundle. |
| **Baby Daybook / BabyConnect** | Breadth of things you can log; cross-platform. | Utilitarian design **[verify]**. | Freemium **[verify]**. |
| **Napper** | Sleep schedules, warmer design. | Sleep only **[verify]**. | Subscription **[verify]**. |
| **Nanit** | Camera-driven sleep analytics, polished design. | Needs the hardware. Analytics, video history and milestone features need an Insights plan after the trial. | About $120/yr and $300/yr tiers (Nanit support page). |
| **Piyolog (Japan)** | Dominant in Japan; voice logging, daily summary **[verify]**. | Japan-centric. | Freemium **[verify]**. |
| **Gaia Baby** (found by Tom, 2026-11-10) | Closest to our pitch: a free shared baby log with a clean, premium feel and a little character. An import tool for people leaving Nara (feeds, nappies, sleep, pumping, growth, milestones, with dates and units); imports of the same file by both parents land once. | Tom's view: not native-feeling, a bit clunky. One review reports an account-creation error. | Free (per its listing). |
| **Sofi Baby Tracker** | Imports from Huckleberry and Nara. | Not reviewed. | Not checked. |
| **Twin-specific apps** (DoubleLoving, Multibaby, TandemBaby, Twiniversity) | Logging two babies side by side. | Small, feeding-focused, twins only. Their existence shows the mainstream apps under-serve this. | Mixed. |
| **CDC Milestone Tracker** | Official US milestone checklists, free. | Milestones only, US only. | Free. |

### What parents complain about

1. **Paywalls on the useful part.** The logging is free; the thing that makes logging worthwhile (predictions, insights, history, export) costs $60–300 a year.
2. **Multiple children are an afterthought.** You switch profiles to log, timers do not run concurrently, and a combined day view is rare. I could not find independent reviews confirming this for each app, so we should **test the top five ourselves with two profiles** before building the pitch around it.
3. **Logging takes too many taps** at 3am, one-handed, with a baby on you.
4. **Apps stop at 12 months.** Solids, potty training, toddler sleep and school-age growth are missing or bolted on.
5. **US-centric content.** Units, percentile charts, vaccine schedules and advice default to the US.
6. **Privacy unease.** The FTC has settled with Premom and Flo over sharing health data with third parties. Parents are right to be wary of a free app holding their child's data.
7. **Cross-platform caregivers.** Sync that breaks, or that costs extra per caregiver.

## 3. Where the opening is

| Gap | Our answer |
|---|---|
| One-baby design | Family timeline, concurrent timers, log one event for several children, sibling comparison |
| Subscription fatigue | Everything essential free. Tip jar, plus a one-off Pro unlock for extras |
| Generic cross-platform UI | SwiftUI and Jetpack Compose, with every relevant OS surface used |
| Ends at age one | Stages: newborn → baby → toddler → child, with the UI changing as the child grows |
| US defaults | Region packs: growth reference, check-up schedule, vaccine schedule, official links |
| Data distrust | No ads, no data sale, no third-party analytics SDKs, full export and delete |

Risks to this thesis: Nara already offers free multi-child tracking, so "free and multi-child" alone is not enough; craft, stages and region packs have to carry it. And free-core economics only work if costs per family stay very low (§9).

## 4. Who it is for

- **Primary:** parents of a newborn who also have an older child, and parents of twins/multiples.
- **Secondary:** first-time parents who want a calmer, better-made tracker.
- **Supporting cast:** partner, grandparents, nanny, daycare. They need a simple role with limited permissions and no account friction.

## 5. Product scope

### 5.1 Tracking

| Area | Details |
|---|---|
| Breastfeeding | Left/right timers, switch side, pause, last-side reminder, tandem feeding of two babies |
| Bottle | Breast milk / formula / mixed, volume, formula brand presets |
| Pumping | Per-side volume, **milk stash inventory** (fridge/freezer, expiry) |
| Solids | Foods tried, reactions, **allergen introduction checklist** |
| Sleep | Naps and night sleep, wake windows, where/how they fell asleep |
| Nappies / potty | Wet/dirty, colour and consistency, then potty attempts, successes, accidents, dry nights |
| Growth | Weight, length/height, head circumference, percentile charts, **corrected age for preemies** |
| Health | Temperature, symptoms, medication with dose and next-dose-due timer, vaccines, appointments, teeth |
| Milestones | Checklist by age from the region's official source, plus free-form firsts with photo |
| Other | Bath, tummy time, outdoor time, reading, custom trackers |
| Journal | Daily note and photo, monthly recap |

### 5.2 Multi-child (the differentiator)

- **Family timeline:** one day view with all children, colour-coded, filterable.
- **No profile switching to log.** Each log button shows the children; tap one, or several to log for both.
- **Concurrent timers.** Baby A feeding on the left, Baby B on the right, toddler napping, all live at once, each with its own Live Activity.
- **Twin mode:** side-by-side layout, "same as sibling" one-tap copy, tandem feed.
- **Sibling comparison:** "Your eldest at 4 months" overlaid on charts.
- **No per-child or per-caregiver charge, ever.**
- **Per-child sharing:** the nanny sees the baby, not the older child's health notes.

Twins are an explicit design target (confirmed by Tom), even though the first household test is a baby plus a toddler. Twin mode needs its own testers in the beta.

### 5.3 Stages

The home screen changes with age instead of showing every tracker forever.

| Stage | Emphasis |
|---|---|
| Newborn (0–3 mo) | Feeds, nappies, sleep, weight regain, jaundice/health notes |
| Baby (3–12 mo) | Sleep schedule, solids and allergens, milestones, teeth |
| Toddler (1–3 y) | Potty training, sleep transitions, words, behaviour notes, medicine |
| Child (3 y+) | Growth, health record, vaccines, teeth lost, memories. Low-frequency use |

### 5.4 Insights

- Daily and weekly summaries, trends, and a **paediatrician report** (PDF) for appointments.
- Nap and feed predictions from the child's own history. This is the feature Huckleberry charges for; ours should start as transparent statistics ("usually naps 2h10 after waking"), computed on-device.
- Handoff summary for the incoming caregiver: "last fed 14:10, 120 ml; nap due about 15:30".

### 5.5 Out of scope for v1

Community/forums, sleep coaching, camera or hardware integration, AI chat, pregnancy tracking.

## 6. Native experience

### What we take from Apollo and Crouton

- **Apollo:** configurable swipe gestures, haptics everywhere, deep but well-organised settings, alternate app icons, speed, visible personality, a developer who talks to users.
- **Crouton:** calm and uncluttered, platform conventions over custom chrome, hands-free use, Live Activities for timers, iCloud-grade sync that just works, family sharing, fair pricing.

### Principles

1. **Two taps to log, one hand, in the dark.** A true night mode (dim, warm, no white flashes).
2. **Log without opening the app.** Lock Screen, widget, watch, voice.
3. **Platform-native on each side.** iOS feels like iOS, Android like Material You. No shared UI layer.
4. **Works fully offline.** Sync is a background detail.
5. **Accessible:** Dynamic Type, VoiceOver/TalkBack, large touch targets, colour is never the only signal.

### Refined Puggle (direction, 2026-11-10)

Prompted by Gaia Baby: the app itself should feel clean, calm and premium, with character dropped in sparingly; the full playful Puggle world lives in the books, clothes, wallpapers and celebrations.

- **Controls follow Gaia's lead and iOS:** filled pill buttons with no outline or hard shadow (Ink primary, soft secondary); soft filled fields; system toggles and segmented controls; list rows with tinted icon circles and thin dividers; large numbers in Bricolage at medium weight. This replaces the chunky outlined, hard-shadow buttons for the app UI.
- **No app name inside the app** (Tom, 2026-11-10). The wordmark appears only on the splash screen, the app icon and in Help / About. Screens are titled by what they show ("Today", the children's names), not the brand. The character can still appear.
- **Character, sparingly:** child avatars, empty states, onboarding, milestones and celebrations. Never on every row.
- **Drawn on the canvas:** controls sheet; Today; bottle sheet; import screen.

### Gaia Baby teardown (from Tom's screenshots, 2026-11-10)

**Structure:** five tabs in a floating bar (Activity, History, Trends, Routine, Food). Activity is a grid of large cards, each with a hand-drawn icon carrying one yellow accent and a "+" button. A dismissible tip carousel at the top (connect to AI, set up a routine, Android support). Cards can be added, hidden and reordered, per device ("Other caregivers keep their own"). History has a week strip, Today / Last 24 h, a category filter sheet and sharing. Trends has Activity and Growth, with WHO curves and a careful note on what percentiles mean. Routine offers "Help me build a routine". Food (beta) has meal plans, freezer and fridge, a shopping list, recipes with AI-generated images, allergen history and a needs screen with medical disclaimers.

**Borrow:** character through illustrated icons with one accent colour (our props sheet does this); a customisable, per-device card layout; dismissible tips for features; calm empty states that say what will appear; plain-language growth notes; a category filter for history; restraint in medical claims.

**Do better:**
- **Several children.** Gaia's home is one child at a time ("[name], 0 days old"); Puggle shows everyone at once (drawn on the canvas as "Today as cards", each card showing both children).
- **Density.** Gaia's cards repeat empty text and need scrolling; Puggle cards show the latest for each child, and the Lock Screen and widgets mean less opening the app at all.
- **Native:** system tab bar, sheets, Live Activities, widgets, Watch.
- **Polish and care:** the screenshots show "her" used for a boy whose sex was not set in the app, and "0 days old"; small errors undermine trust in a health app. Puggle uses the child's name or "they" until sex is set.
- **Local language and units:** nappy, ml, Australian health references.
- **Imagery:** no AI-generated food photos; drawn props or real photography.
- **Toddlers:** potty, big bed, growing up.

**Watch:** Gaia is on Android and connects to AI assistants, which our iOS-first, iCloud plan does not cover. Revisit once iOS is proven.

### Import (new feature)

Parents switch apps mid-baby. Import from Nara Baby, Huckleberry, Baby Tracker (CSV) and any CSV, keeping dates and units; de-duplicate when both parents import the same file. Gaia and Sofi already do this, so it is table stakes for winning switchers. Formats of each app's export need checking **[verify]**.

### Onboarding (first draft, 2026-11-10)

Reference from Tom: onboarding screens from an app called Gaia (not identified in a web search). What it does well: one message per screen, a real piece of the product shown inside the onboarding, an honest "Sample data" label, Skip always available, identical light and dark versions.

Puggle's four screens (on the canvas):
1. **Hello from Puggle.** Puggle and Pebble; one line on what the app is.
2. **Everyone sees the same day.** A partner's entry arriving, above a shared timeline. Labelled "Example family".
3. **All your little ones, in one place.** Two children with live status side by side, and "Add a child" (twins and siblings welcome).
4. **Make their character.** Pick a friend, outfit colour or a photo; changeable later.

Then the setup itself: add the first child (name, birth date, photo or character), invite a partner, choose region and units, allow notifications with a plain explanation. Each step skippable.

### Where theming stops and iOS begins

A theme is **data, not layout**: colours, type, corner radius, shadow, icon set, scene artwork, animation files and copy voice. Navigation and screen structure are the same in every theme.

| Layer | Approach | Cost of theming |
|---|---|---|
| Our content: scene header, cards, log buttons, steppers, chips, charts | Custom SwiftUI views and button styles built on real system controls | Low. This is where the character lives |
| System structure: navigation, tab bar, sheets, lists, menus, date and time pickers, swipe actions, alerts, keyboard, share sheet | Keep stock. Tint and font only | High if we fight it, and it breaks with each iOS release |
| System-drawn surfaces: widgets, Live Activities, Dynamic Island, notifications, Watch complications | Follow the system's rules; themes supply colours and still artwork | Fixed by Apple. No Rive, little animation **[verify]** |

Rules that follow:
- Style real controls, never rebuild them. A themed button is still a system button underneath, so VoiceOver, Dynamic Type and Reduce Motion keep working.
- Custom pull to refresh is the one place we replace a system behaviour. It needs its own implementation and testing.
- Stock structure picks up each year's iOS design changes for free; custom chrome has to be redone.
- Apollo and Crouton both work this way: stock structure, strong personality in content, icons and settings.

### Lessons from Tom's references (Nanit screenshots, Claude's iOS sheet)

Borrow the principle, not the look.

| Seen | Take | Avoid |
|---|---|---|
| Nanit: deep navy, one warm accent, large light numerals | Night is the premium register. One accent, restraint, big numbers | Tiles that are mostly empty space around a single number |
| Nanit: moon and stars behind the Insights header; Day/Night toggle re-skins the whole screen | Atmosphere sits behind content and reflects what you are looking at | |
| Nanit: "Hey Dad, I was helped to sleep 3 hours and 47 minutes ago" | Voice carries character even with no illustration | |
| Nanit: hamburger menu plus five tabs; one child at a time, switched in a drawer | | Two navigation systems. Per-child silos. We use three tabs and show all children together |
| Nanit: blurred paid tiles, "Shop" buttons and "Shop Offers" inside the data | | Upsells inside the family's data. Paid extras live in one settings screen |
| Nanit: nappy sheet needs a type, then Save | One tap on the type saves it | A confirm step for the commonest actions |
| Nanit: activity list of repeated machine events | A timeline of what people logged, grouped and quiet | |
| Claude iOS: sheet with grabber, round close button, centred title, half height then full | Use the system sheet with half and full heights for all logging. Half height keeps the scene visible; pull up for time and notes | Custom modal behaviour |

### OS surfaces

| iOS | Android |
|---|---|
| Live Activities and Dynamic Island for timers | Ongoing notifications / Live Updates |
| Home and Lock Screen widgets, interactive | Glance widgets |
| Control Center controls, Action Button | Quick Settings tiles |
| App Intents: Siri, Shortcuts, Spotlight | App Actions / Assistant |
| Apple Watch app and complications | Wear OS app and tiles |
| HealthKit (where child data types allow) **[verify]** | Health Connect **[verify]** |
| iPad layout, StandBy | Tablet and foldable layouts |

## 7. Government-backed content by region

Approach: a **region pack** per country containing (a) growth reference data, (b) the routine check-up schedule, (c) the vaccine schedule, (d) milestone checklists where an official set exists, (e) deep links to official guidance. We bundle data and schedules; for advice text we link out unless the licence clearly permits reuse.

| Region | Sources | Use | Licence position |
|---|---|---|---|
| Global | **WHO Child Growth Standards** (0–5) and Growth Reference (5–19) | Default growth charts everywhere | Tables are published by WHO; commercial reuse terms **[verify]** |
| US | **CDC** growth charts (2–20 y), **CDC "Learn the Signs. Act Early."** milestones (revised 2022 with AAP), CDC immunisation schedule, **CPSC** recall data | Charts, milestone checklists, vaccine reminders, product recall alerts | US federal works are generally public domain, but CDC asks not to use its logo and has an attribution form. Confirm with the programme **[verify]** |
| UK | **NHS Website Content API v2**, **UK-WHO growth charts** via RCPCH Digital Growth Charts API, NHS vaccination schedule, the "red book" (PCHR) review schedule | Syndicated NHS articles in-app, UK centiles, check-up timeline | NHS content is under the Open Government Licence via free syndication; some campaigns (e.g. Best Start in Life) are excluded. RCPCH API is paid in tiers (about £250–500 listed) and licensed per reference **[verify]** |
| EU | No single source. **ECDC Vaccine Scheduler** (per-country schedules), national programmes: Germany's U1–U9 check-ups (Gelbes Heft), France's carnet de santé | Start with WHO charts plus per-country vaccine and check-up schedules for DE, FR, ES, IT, NL | Per-country terms **[verify]**. GDPR applies to everything |
| Japan | **母子健康手帳 (Boshi Techo)** structure, national infant growth survey curves, MHLW weaning guide, national check-ups (1 mo, 3–4 mo, 18 mo, 3 y) | Japanese growth curves, check-up timeline mirroring the handbook | Japan is moving to an electronic handbook as the default from FY2026. That is both an integration opportunity and a competitor. Government site terms are broadly CC BY-compatible **[verify]** |
| Australia | **Raising Children Network** (government-funded), National Immunisation Program schedule, state child health records (Blue/Red/Green books), Product Safety Australia recalls | Schedules bundled; advice by link only | Raising Children requires a licensing agreement for in-app reuse of text, images and video; linking is allowed |
| New Zealand | **Well Child Tamariki Ora** My Health Book (0–5 y checks, B4 School Check), NZ-WHO growth charts, National Immunisation Schedule | Check-up timeline, growth charts, vaccine reminders | Reuse terms on HealthEd **[verify]** |

### Regulatory line we must not cross

Showing a measurement on a published chart is record-keeping. Interpreting it ("your baby is underweight", "see a doctor") can make the app a **medical device** under EU MDR, UK MDR and FDA rules. v1 displays official references and schedules, attributes them, and does not diagnose. Get a short regulatory opinion before launch **[action]**.

## 8. Technical plan

### 8.1 Recommendation for v1: iOS only, no server

| Layer | Choice | Why |
|---|---|---|
| App | Swift, SwiftUI, WidgetKit, ActivityKit, App Intents | Truly native; needed for the surfaces in §6 |
| Storage | Local database on device (Core Data, SwiftData or GRDB; decided by a short spike) | Works offline; fast |
| Sync and sharing | **CloudKit** (the user's own iCloud), with CloudKit sharing for partner and caregivers | No backend to build, run, secure or pay for. No sign-up screen. Data sits in the family's iCloud, not ours |
| Payments | StoreKit 2 (add RevenueCat only if we go cross-platform) | One less dependency |
| Website | Next.js on **Vercel** | Landing page, privacy policy, help pages |
| Diagnostics | Apple's built-in crash and usage reports | No third-party SDKs |

This reverses Draft 0.1, which proposed Supabase from day one. With two of us and a start-small brief, running a server that holds children's health data is the biggest avoidable cost and liability. CloudKit is what Crouton uses.

**The trade-off:** CloudKit sharing only works between Apple devices. An Android partner or grandparent could not join in v1. If your own household is mixed, tell me and we go straight to the cross-platform backend instead.

**The spike:** CloudKit *sharing* (as opposed to single-user sync) is not supported equally by all three storage options **[verify for current iOS]**. One week of prototyping "two iCloud accounts editing the same child" settles the choice before we build on it.

**On Vercel:** right for the website, not needed for the app in v1.

### 8.2 Later: Android and a backend

Android is a decision for after iOS has real users. At that point we add Postgres (Supabase), an offline sync layer (PowerSync has Swift and Kotlin SDKs) and a Jetpack Compose app, and migrate families from CloudKit. To keep that migration cheap, v1 uses a platform-neutral data model (§8.3), stable UUIDs, and keeps sync behind one interface in the code.

Not React Native or Flutter: the brief is Apollo/Crouton-level native feel, and widgets, Live Activities and watch apps need native code regardless.

### 8.3 Data model (sketch)

```
Family ─┬─ Member (user, role: owner | parent | caregiver | viewer)
        ├─ Child (name, dob, due_date, sex, colour, avatar, region)
        │    └─ ChildAccess (member, permission)        # per-child sharing
        └─ Event (id, type, started_at, ended_at, payload JSON,
                  created_by, updated_at, deleted_at)
             └─ EventChild (event, child)               # one event, many children
Measurement (child, kind, value, unit, measured_at)
Milestone (child, key | custom, achieved_at, photo)
RegionPack (country, version, growth refs, schedules, links)  # read-only, bundled + updatable
```

Key decisions: events are append-friendly with soft deletes and last-write-wins per field, so two caregivers editing offline do not lose data. `EventChild` is what makes "bath for both" a single entry. Units are stored in SI and displayed in the user's preference.

### 8.4 Privacy and security

- Children's health data: treat as special-category data under GDPR; UK Children's Code, COPPA and the FTC Health Breach Notification Rule (extended to health apps in 2024) are all relevant.
- No ad SDKs, no data sale, no third-party trackers. Say so on the App Store privacy label.
- In v1 the data lives in the family's own iCloud; we hold none of it. That is the privacy story.
- One-tap export (CSV, JSON, PDF) and full account deletion.
- No account to create in v1: identity is the iCloud account. Caregivers join by an iCloud share link.

## 9. Business model

Positioning: **a premium product for parents who notice craft**, funded by people choosing to pay for character, not by ads or by locking their data.

Principle: **never charge for the family's own data, or per child, or per caregiver.**

| Layer | Contents | When |
|---|---|---|
| **Free** | All tracking, unlimited children and caregivers, sync, full history, export, growth charts, widgets, Live Activities, the default theme | Launch |
| **Tip jar** | Three or four tip sizes. A thank-you only: a supporter badge | Launch |
| **Themes and icons** | Illustrated themes (each restyles colour, type, illustration, copy voice, widgets and Live Activities) and matching app icons. Sold as a one-off "all themes" unlock; possibly single packs later | After beta |
| **Pro extras** | Paediatrician PDF report, nap/feed predictions. Bundled with the themes unlock rather than sold separately | After beta |
| Subscription | Only if we add something that costs us money every month | Not planned |

Precedents (from memory, **[verify]**): Apollo sold a one-off Pro unlock and offered many alternate icons, some by guest artists. Andy Works' (Not Boring) apps charge for visual skins on top of simple utilities. Carrot Weather sells personality and customisation on top of weather data.

Why this fits: with CloudKit our running costs are about $99/yr plus a domain, so revenue only has to repay illustration and reward the work.

Honest limits:
- Cosmetic-only revenue is usually modest. Bundling two or three useful extras with the themes makes the unlock easier to justify.
- Every theme is an illustration set, so themes are our main cost as well as our main product. Launch with one signature theme done properly and one or two more, not ten.
- "Premium" and "free with a tip jar" pull in different directions. The resolution proposed here: free is complete and ad-free; the paid layer is priced with confidence (to test: $29.99–39.99 one-off for everything). These are starting numbers, not researched price points.

## 10. Design, brand and operations

### Character and illustration

The reference is Citymapper: a utility people are fond of, because of its voice and illustration as much as its function.

- **Voice:** short, dry, kind. "One down, one to go." Never guilt, never medical-sounding. Voice can vary by theme.
- **A reactive home screen:** the header illustration reflects the real state of the family (who is asleep, time of day), so it is information as well as decoration.
- **Rewards for the child, not the parent:** the potty sticker chart is designed to be shown to a toddler.
- **Early direction (superseded for the app UI by Refined Puggle in §6; still informs books and scenes):** a mix of A Daybreak and C Night Nursery, with B Sticker Book's chunky, tactile style for buttons and inputs. In practice: A's scene, type and voice by day; C's palette and calm at night; outlined, hard-shadowed controls throughout; soft tinted cards for information. Playful but solid, in the way Duolingo is.
- **Tom draws the characters and scenes for the concept and proof-of-concept stage.** Commissioning a lead illustrator or guest artists is a later decision, once the system is proven.
- Illustrations must be inclusive across skin tones, family structures and feeding choices.

#### Character style: the discipline of Miffy

Tom's reference for cute characters is Miffy (Dick Bruna). We take the method, not the character; Miffy itself is protected and its owners enforce that.

- Heavy, slightly hand-drawn black outline. Flat colour, no shading or gradients.
- Very few shapes. Two dots for eyes. Always facing the viewer.
- A fixed palette of about six colours, used as large flat fields.
- Movement is small and gentle: a blink, a tilt, a hop.

Why it suits us: it is cute and premium at once, it reads at avatar and widget size, simple shapes are quick to animate in Rive, and flat colours print cleanly on fabric for the clothing label.

A study of an original character, a puggle (baby echidna), is on the mockup canvas. If the puggle becomes the character, **Puggle** could name the character, the app and the label, in the way Miffy does.

Further references from Tom and his wife, and what each contributes (characterised from memory):

| Reference | What to take |
|---|---|
| Sylvanian Families | Animal **families**, and animals that **wear clothes**. The characters can wear the label's range; each child's colour becomes their character's jumper |
| Animal Crossing | Big head, small body. A world that follows the real clock, seasons and holidays, and rewards a short daily visit. This is the model for the living scene |
| Kirby | One round shape, blush cheeks, emotion through squash and stretch |
| Spot the Dog | Flat colour, one identifying mark, and lift-the-flap reveals, which suit sheets and pull to refresh |
| Also worth a look | Moomin (loved by adults, strong in fashion), Barbapapa (a family told apart by colour), Maisy, Bluey (written for parents as much as children), Paddington and Peter Rabbit (one signature garment), Totoro, Pingu |

Resulting rules for our characters: head as large as the body; one signature feature (for the puggle, the long snout and crown of spines); clothed; a family of sizes; six or seven flat colours.

#### The world: Puggle and friends (Australiana)

Tom and his wife are Australian. The cast is Australian baby animals, which is distinctive in a market of bears and bunnies and, as Bluey shows, travels well.

| Character | Animal | Signature feature | Natural role |
|---|---|---|---|
| **Puggle** | Platypus | Bill, flat paddle tail, webbed feet | The lead; the app icon. Chosen over the echidna (Tom, 2026-11-10) because a platypus is recognised worldwide and cannot be mistaken for a hedgehog |
| The other puggle | Echidna | Long snout, crown of spines | A sibling or twin for Puggle |
| Wombat | Wombat joey | Square head, big nose | Sleep, and potty training (wombats are known for cube-shaped droppings) |
| Koala | Koala joey | Big round ears, tall nose | Naps and cuddles |
| Quokka | Quokka joey | The smile | Milestones and celebrations |
| Later | Bilby, kookaburra, emu chick, little penguin, sugar glider | | Bilby for Easter and night; kookaburra for morning; emu chick and penguin for toddlers |

- **Start with Puggle plus two or three friends.** Each is a full set of states to draw and animate.
- **How they are used:** a child can choose a friend as their character in the scene (photo stays the main avatar). Friends also turn up for the moments they suit.
- **Settings and seasons are Australian by default:** gum trees, the beach, the backyard; Christmas in summer; wattle in spring; jacaranda in November. Seasons flip for northern-hemisphere families.
- **Plants as pattern:** gum leaves, wattle, banksia and bottlebrush make repeat prints for both the app's backgrounds and the clothing.
- **Local references:** Bluey, May Gibbs's gumnut babies, Possum Magic, Diary of a Wombat, Blinky Bill (from memory).
- **Care:** do not borrow Aboriginal art styles, motifs or stories without a proper collaboration and permission.
- A New Zealand kiwi chick would be an easy friend to add for NZ families.

#### Our formula, and where we depart from it

Bluey took Peppa Pig's formula (flat shapes, a family of animals, short everyday stories) and changed specific things on purpose. We do the same with Miffy's.

| Keep from Miffy | Change deliberately |
|---|---|
| Heavy outline, flat colour, very few shapes | **Dark warm-brown outline** in place of black: softer, and it works on the night palette |
| Dot eyes, facing the viewer | **The nose is the face.** No mouth; each species is told apart by its nose, snout or bill |
| One fixed small palette | **The garment is the body.** A simple flared jumper shape, so the clothing label's pieces define the silhouette |
| A single character | **A cast and a family**, including a parent. The app is for parents, so the humour is too |
| | **Australian** species, settings and seasons |

Signature marks under test (see the mockup canvas):
- **Decided: blush with stitches.** Round blush cheeks with two short stitches over them. Originally proposed as stitches in place of blush: It nods to the clothing label and is ours in the way the X mouth is Miffy's. Options shown: stitches with no mouth (preferred), freckles, stitches with a small smile.
- **The pouch pocket:** every jumper has a front pouch pocket. Echidnas carry their puggle in a pouch, hoodies call it a kangaroo pocket, and it can be a real detail on the garments.

Wardrobe: jumper with pouch pocket, dungarees and overalls, dresses, T-shirts and shorts, pyjamas. Each child's character can be dressed, and the clothes mirror the label's range.

A note on the word: "puggle" is the usual name for a baby echidna; for a baby platypus it is widely used but informal **[verify]**. That does not stop us using it as a character name.

Body rules: head and body about equal; short legs under the hem; arms that can wave and hold; babies sit, toddlers stand; Puggle sleeps curled into a ball of spines.

#### Mono characters, builder and soft shapes

- **Mono version of every character:** one ink on paper (and a night variant, cream on navy). For embroidery, single-colour print and stamps, small sizes, widgets, the Lock Screen and Live Activities. Blush drops out in mono; the stitches stay.
- **Character builder:** parents make their child's character by choosing friend, outfit, outfit colour, background and colour or mono. A working prototype is on the mockup canvas. Later options: hats, accessories, names on garments, seasonal outfits (themes and the clothing label feed this). The built character is what stands in for the child in the scene and widgets.
- **Soft shapes:** a small set of rounded geometric shapes (quatrefoil, pill, scallop, soft square, soft hexagon, pebble, half pill, blossom), prompted by Tom's reference (Amigável by Latinotype). The shapes are our own drawings; the typeface is not used. Uses: repeat pattern for fabric and app backgrounds, potty-chart stickers, chips and buttons, and a mark after the logotype.

#### Character names (proposed)

Rules: one or two syllables a toddler can say; each name hints at the character's personality or role; drawn from the Australian world, in the way Bluey's names are descriptive.

| Name | Animal | Personality | Role in app and stories |
|---|---|---|---|
| **Puggle** | Platypus | She is 2½, curious, always in the water; potty training | The lead; the toddler stories |
| **Pebble** (proposed) | Platypus | Puggle's baby sibling, about 6 months; a curl on top | The baby stories: bottles, first foods, teeth, rolling |
| **Quill** | Echidna | A friend; gets prickly when tired | Friendship stories |
| **Kip** | Koala | Puggle's best friend; can fall asleep anywhere ("kip" is a nap) | Naps and sleep |
| **Digby** | Wombat | Loves digging; the potty jokes | Potty training |
| **Sunny** | Quokka | Always smiling | Milestones and celebrations |
| Later | Kookaburra (**Chuck**, wakes everyone at dawn), Mum, Dad, Nan and Pop | | Mornings; the parent and grandparent cast |

Trademark checks needed for Puggle before launch; the others matter only if sold as products in their own right.

#### Style direction: the original Puggle

Explorations toward Bluey (brows, eye glints, a mouth drawn on the bill, chubbier bodies) were rejected: they lost the cuteness, and a mouth on a bill makes no sense. **Tom prefers the original Puggle**, and Puggle is a girl ("she").

**Rule (Tom, 2026-11-10): Puggle emotes only through her eyes, floating marks, and body shape and language. Her bill never changes:** it does not open, tilt, smile or frown. (Open-bill options were explored and set aside; the sheet stays on the canvas marked superseded.)

- **Eyes:** dots, happy arcs, sleepy closed arcs, bigger dots for surprise, a wink, dots glancing aside, stars, squeezed (> <), swirls.
- **Cheeks:** bigger blush, and a third stitch when shy; puffed when cross.
- **Floating marks:** "!", "z z z", sparkles, laugh lines, a tear, a sweat drop, hearts, flowers, gloom lines, a sleep bubble.
- **Body:** poses (hello, hooray, shy, oh no, ta-da), and squash and stretch in animation: a jump for surprise, a bounce for laughter, a droop for sad.
- Never brows, never a mouth, no dark patches on the face.
- **Hands and feet (decided 2026-11-10):** round ball hands in fur brown (not slate), slightly larger; a thin cuff line where sleeve meets hand; feet stay slate and are a little larger and more paddle-like. Applied across the current canvas sheets (expressions, family, hands, builder, wallpapers, books); earlier exploration sheets are left as they were. Hands do things: wave (with motion arcs), clap (with clap marks), hands to cheeks for "oh!", peekaboo (the only time hands cover the face; arms tuck behind the head), and holding props. Next: a prop library (bottle, nappy, potty, toothbrush, book, wattle, balloon).
- **Arms and hands always visible** (Tom, 2026-11-10). Arms sit in front of the garment and behind the head. Raised arms go up and out at about 45 degrees, hands clear of the head; never straight up behind it. Lowered hands stick out past the garment's edge. Hands held in front rest on the garment, never over the face or bill. Every pose is checked as a solid silhouette: if a hand disappears in the silhouette, redraw the pose.
- Never brows, never a mouth, no dark patches on the face.

Bluey's contribution is behaviour, not drawing style: family stories, humour for parents, everyday Australian settings.

#### Japanese character design

References (from memory): Sanrio (Hello Kitty, Pompompurin, Cinnamoroll), San-X (Rilakkuma, Sumikko Gurashi), Chiikawa, Totoro.

What to take:
- **Kawaii proportions** are already ours: big head, small body, simple face, eyes low and wide apart.
- **Expression marks (manpu)** layered on a face that never changes. Drawn on the canvas: sparkly eyes, squeezed eyes (> <), sweat drop, dizzy swirls, sleep bubble, tear streams, gloom lines, flower burst, hearts, puffed cheeks. Each maps to an app or story moment (the nappy explosion, 3 am, a first). Our stitched blush is already a version of anime blush lines.
- **A cast with small personalities and backstories** (Sumikko Gurashi), shown in profile cards and in merchandise.
- **Kawaii merchandise culture:** stationery, stickers, plush, collectable seasonal sets. Relevant to the label and to the Japanese market (§7).

Avoid anger veins and anything aggressive.

#### Her name

Recommendation: **Puggle is her name**, and she is a platypus. One word for the character, app and label, as Miffy and Bluey are; children can say it. Books: "Puggle the platypus". The alternative (a P-name such as Pearl, with Puggle as the brand) splits recognition and needs a second trademark. Caveat: "puggle" is also a common noun for a baby echidna or platypus, so trademark strength in some classes may be weaker; check with an adviser.

#### Model sheets (how other characters are kept consistent)

Long-running characters are held on model by a style guide of model sheets. The Simpsons had an early guide of nearly 500 pages setting poses, movements and expressions, down to the shape of Lisa's hair. Mickey's white gloves were added so his hands showed against his black body (and, Disney said, to make him more human). Miffy is drawn flat and front-on, without perspective, in a small set of specially mixed "Bruna colours".

Puggle's style guide should contain:
1. **Model sheet:** turnaround (front, three-quarter, side, back), proportions (about 2 heads tall: head 1, body ¾, legs ⅓), colours with values, line weights, and a "never" panel. First version on the canvas.
2. **Expression sheet** and **pose sheet** (on the canvas).
3. **Hands sheet** (on the canvas).
4. **Silhouette rule:** poses are staged so arms and hands have space around them and read in solid silhouette, which is the classic test. Where a pose cannot avoid overlap (hands held in front), a thin light knockout line keeps the arm distinct.
5. **Size line-up** of the whole cast (on the canvas). Children share one head size; grown-ups are taller through longer bodies, not bigger heads. Nan wears pale blue reading glasses on her bill and a cardigan; Pop round glasses, a cardigan and a bucket hat; Mum a flower; Dad shorts.
6. **Props** sheet (on the canvas): bottle, nappy, potty, bowl and spoon, sippy cup, toothbrush, book, blanket, rubber duck, Puggle plush, wattle, balloon. Each has a grip point a ball hand can hold; hands sit in front of held props.
7. **Construction** sheet for drawing by hand (on the canvas): head oval 140 × 120; bill oval 108 × 50 overlapping the chin; eyes on the centre line 60 apart; cheeks at the ends of the bill's top edge; jumper body 64 wide at the neck, 120 at the hem.
8. **Palette and type** (on the canvas, below).

#### Accessories

Rules: few and signature (one per character, like Hello Kitty's bow or Paddington's hat); drawn like the character (flat colour, same outline, from the palette, no extra detail lines); never hide the eyes; must read in silhouette and at icon size; used to tell characters apart.

Glasses (options on the canvas: eye level or resting on the bill; rims only, pale blue lenses, or black lenses). Proposed: **Nan** wears pale blue reading glasses resting on the top of her bill, eyes peeking over; **Pop** wears round rims at eye level, with his bucket hat. Black lenses only as a sunny-day joke, since they hide the eyes.

#### Props v2 and Australiana (2026-11-10)

Props redrawn to one rule set: one outline weight, flat palette colours, one white highlight, no brands, logos or label text. Everyday: bottle, nappy, potty, bowl and spoon, sippy cup, toothbrush, book, blanket, rubber duck, balloon. Australian, in the spirit of Bluey's everyday Australiana: thongs, esky, Hills Hoist, meat pie, sausage in bread, fairy bread, lamington, pavlova, cricket bat and ball, zinc stick, letterbox, milk crate, surfboard. Generic forms only: no branded products or packaging (no recognisable spreads, biscuits or ice creams).

**Two prop styles (2026-11-10).** The full-colour props read as "funky" in the calm app (Tom). So: **line icons for the app** (one 3.5 line in Ink, rounded ends, one small accent, mostly Wattle; same optical size; lots of air; Gaia-like restraint) and **full-colour props for books, fabric, wallpapers and celebrations**. Both are drawn from the same shapes. The Today cards now use the line icons.

#### App icon foundation (2026-11-10)

Two tiers, confirmed by Tom: **line icons with one accent in the app; full-colour items in the universe and stories.**

- **System UI uses SF Symbols** (house, calendar, chart.bar, person.2, gearshape, plus, pencil, timer, square.and.arrow.up, line.3.horizontal.decrease). They are native, scale with Dynamic Type and match iOS. Apple's terms limit them to apps on Apple platforms and bar them from logos and app icons **[verify the current licence text]**.
- **Custom Puggle activity icons** for what SF Symbols does not cover: bottle, breastfeed, pump, solids, sleep, nappy, potty, bath, growth, weight, temperature, medicine, vaccine, teeth, milestone, tummy time, play, walk, note, photo.
- **Construction:** 24 pt canvas, 2 pt padding, keyshapes (circle 20, square 18, portrait 16 × 20, landscape 20 × 16); 1.4 pt stroke (reduced from 1.75 after review: details closed up at real size), round caps and joins; one accent fill under the line, up to about a third of the shape, Wattle by default; must read with the accent removed; no faces. Shipped as custom SF Symbols so they take weights and scale with Dynamic Type.
- **Second pass, one by one (2026-11-10).** First set was too small and some were hard to read. Each icon now has a stated idea: bottle (teat, collar, body, milk level, ticks); breastfeed (a parent cradling a baby: two heads, one arm); pump (round funnel into a small bottle); solids (food heaped above a bowl, spoon); sleep (crescent and twinkle); nappy (waistband, taper, leg openings, tabs); potty (side view with front guard); bath (tub on feet, bubbles); growth (height chart and arrow); weight (baby scale with readout); temperature (thermometer); medicine (dropper bottle); vaccine (syringe); teeth (tooth with shine); milestone (star); tummy time (baby on a mat, head up); play (rattle); walk (pram); note; photo. Checked at 24 and 17 pt. Weakest still: tummy time and potty.
- **Stroke weight (2026-11-10):** compared 1.75, 1.4 and 1.2 pt at 24 and 17 pt. **1.4 pt** chosen as the base. As custom SF Symbols, lighter and heavier weights can be drawn so the icons follow the system's weight and size; at 17 pt a lighter weight (around 1.2) keeps inner details open. Rule: keep at least 1.5 pt clear between parallel lines.
- **Third pass: rounded (2026-11-10).** Every corner rounded (about 1.2–1.8 pt radius) on top of round caps and joins; the star and twinkle have soft points. Breastfeed refined (parent's head and shoulder, arm cradling a swaddled baby, baby's head at the chest). Play changed from a rattle (read as a magnifying glass) to stacking blocks with a roof. Compared side by side with Lucide (ISC) and Phosphor duotone (MIT) at the same stroke and accent: Puggle's icons are more baby-specific (bottle, nappy, potty, pump, tummy time have no close match in either); Phosphor's duotone is the closest in spirit. Lucide is the better construction reference; Phosphor the better reference for the accent fill.
- **Fixes after review (2026-11-10):** potty redrawn as a child's potty in side view (tall backrest, wide seat, tapered bowl, front splash guard); Play is three identical blocks so they read as equal; the sleep twinkle is back to a small four-point sparkle, softly rounded; Breastfeed simplified to a parent holding a baby close (two heads, a shoulder, an arm under the baby). A heart with a milk drop was the runner-up for Breastfeed.
- **Potty, final direction (2026-11-10):** three-quarter view as in Tom's reference: rounded backrest sweeping down to a seat opening (accent), a front lip, and a wide base band. Drawn in the house line style. Stock icon sets Tom shared (watermarked) are used for ideas only, never traced.
- **References:** Phosphor (MIT; its duotone style is the model for line plus accent), Lucide (ISC; construction), Tabler (MIT; coverage checks), Material Symbols (Apache 2.0; keylines and optical sizes). Used as references only; Puggle's icons are drawn fresh. If any open-source icon is used directly, keep its licence notice.

#### Text in the world

Like the signs in Bluey, shop and street signs are real words rendered as soft blobs: the word set in the display face, thickened, blurred and merged, in a colour close to the sign so it reads as part of the scene. A legibility ladder sets when to use what: crisp (a word the story needs), soft (readable), blob (scenery), pills (pure shape). Example street on the canvas: milk bar, bakery, chemist, surf shop, café. In production this is a fixed filter in the illustration tool (or a pre-baked shape), not live text.

#### Hair and head accessories (2026-11-10)

No hair (Tom's preference). Characters are told apart by head accessories instead, drawn on the canvas: quatrefoil clip, bow, headband, fur bun, flower, beanie, bucket hat, sun hat.

Proposed assignments: **Puggle** wears a hair clip in the shape of the brand quatrefoil (ties her to the logo and avoids the Hello Kitty bow); **Mum** a flower; **Nan** reading glasses; **Pop** glasses and a bucket hat. Hats are seasonal and situational for everyone (beanie in winter, sun hat at the beach).

**Cast accessories (draft, applied to the line-up):**

| Character | Signature |
|---|---|
| Puggle | Red quatrefoil clip |
| Pebble | Kewpie curl |
| Quill | None: the spines are the signature |
| Kip | Blue bow |
| Digby | Red beanie |
| Sunny | Sun hat |
| Mum | Flower |
| Dad | None (shorts) |
| Nan | Fur bun and pale blue reading glasses |
| Pop | Round glasses and green bucket hat |

**Pebble's curl:** the current thin curl is lost at small sizes. Options drawn: Kewpie curl, three tufts, spiral, curl with a bow, forehead squiggle. Recommended: the **Kewpie curl**, a thick fur-coloured curl with an outline, after the single topknot of Rose O'Neill's Kewpie dolls (1909).

#### Motion and 3D

- **Rive:** the characters are a handful of flat shapes, so they suit Rive well. Duolingo uses Rive for its characters, with state machines for idle, talking and reacting states and lip sync driven by speech. Puggle needs no lip sync (no mouth); her states are eyes, marks, poses and squash and stretch, which keeps the rig small. One rig per species, with garments and accessories as swappable parts, matches the character builder.
- **3D:** Miffy moved to CGI in *Miffy's Adventures Big and Small* (2015, 3 seasons of 26 seven-minute episodes), and a new CGI series has been announced. A 3D Puggle is a later option for animation, AR or toys; the flat 2D drawing stays the master. Simple rounded volumes (head, bill, jumper) would translate well, and plush and vinyl toys are effectively 3D already.

#### Family and ages (Tom, 2026-11-10)

Like Bluey and Bingo, the lead has a younger sibling, so stories can cover topics for both ages. The family mirrors Tom's own: a 2½-year-old in potty training and a 6-month-old on bottles, which is also the app's first household.

| Age | Character | Topics for stories and app moments |
|---|---|---|
| 0–1 | Pebble | Bottles, first foods, sleep, teeth, rolling and crawling, bath time |
| 2–3 | Puggle | Potty training, moving to a big bed, a new baby in the family, sharing, big feelings, the dentist |
| 3–4 | Kip, Digby | Preschool, swimming lessons, making friends, fear of the dark |
| 4–5 | Sunny | Starting school, riding a bike |

Friends can have younger siblings of their own later. Mum, Dad, Nan and Pop complete the platypus family.

Drawn on the canvas: Puggle at 2½; the baby smaller, with a curl on top, a romper and a bottle; Puggle on the potty (the proud pose with sparkles); Puggle at bedtime.

#### Wallpapers, repeats and books

**Wallpapers and repeats** (Nintendo's character wallpapers are the reference). Mocked up: a half-drop grid of friends and shapes; a night repeat of tossed shapes with mono Puggle; Breton-style stripes with friends; a one-colour fabric repeat. Uses: free downloads, a reward for supporters (tip jar), app backgrounds, and fabric for the label.

**Books** (Miffy, Spot, Possum Magic as references). Square board books for 0–3; one short sentence per page; text on the left, one picture on the right; counting, colours, routines, weather; gentle humour for the parent reading aloud. Draft titles: *Puggle at the Beach*, *Koala and the Jacaranda*, *Night Night, Puggle*, *The Wattle Walk*, and a washing-line counting book. Stories can follow the app's moments: bath, bedtime, first steps, the potty, the light rail to the beach.

**Flora:** wattle, gum leaves, banksia, bottlebrush, waratah, jacaranda.
**Everyday places, not famous landmarks:** Hills Hoist, terrace house with iron lace, light rail, lighthouse, ocean pool, surf flags. Generic, Australian, and free to draw.

What to avoid:
- **Aboriginal art styles, motifs, stories and significant places.** Uluru is the clearest case: commercial use of its image requires a permit from Parks Australia, and Anangu ask that some views not be shown.
- **Trademarked landmarks.** The Sydney Opera House's shape is registered as a trade mark and its Trust requires approval for commercial use, so it stays out. Check any other named landmark before drawing it.

**Local context:** Dulwich Hill is within the Inner West Council area, whose traditional custodians are the Gadigal and Wangal peoples of the Eora Nation. Which of the two applies to Dulwich Hill specifically is not settled by the sources found; the Metropolitan Local Aboriginal Land Council is the place to ask. A respectful Acknowledgement of Country on the website and in the books is appropriate; Aboriginal content in the stories would need a proper collaboration.

#### Photos first, characters second

The app is for parents, and it has to earn a place in their day. What a parent wants to see is their own child.

- **Each child is represented by their photo**, with a ring in the child's colour. The colour still does the work of telling entries apart.
- **Easy to keep fresh:** prompt for a new photo on monthly birthdays and milestones, so the app quietly becomes a record of the child growing.
- **A character is the fallback** before a photo is added, and what stands in for the child inside the illustrated scene, widgets and Lock Screen, where a small photo reads poorly.
- Photos stay in the family's iCloud like everything else.

#### The living scene

The home screen header is a scene that changes with what is happening. Each child has a character in it (asleep on a cloud, awake on the hill, in a party hat on their birthday).

| Input | Examples | Source |
|---|---|---|
| Family state | Who is asleep, feeding, awake; how many children | The log |
| Time of day | Dawn, day, dusk, night | Device clock and sunrise/sunset |
| Season | Leaves, snow, blossom; flipped for the southern hemisphere | Date and region |
| Holidays | Opt-in sets per family, since holidays differ by country and belief | Settings |
| Child moments | Birthdays, monthly "birthdays", first tooth, first steps, last nappy | Milestones |

**Build it from layers, not finished pictures.** Sky, weather, ground, props and characters are separate layers combined at runtime. Five times of day, four seasons and a dozen moments would be hundreds of drawings as whole scenes; as layers it is a few dozen parts. This is the decision that keeps the illustration budget sane.

#### Motion (Rive)

- Characters and scene elements are **Rive** files with state machines: inputs such as `asleep`, `timeOfDay`, `celebrating` drive the animation, so one file covers many states.
- **Pull to refresh** is a signature moment: the sun spins, the awake character hops, the cloud bobs while the app syncs with the other phones.
- Other moments worth animating: saving a log (a small acknowledgement, under half a second), a timer starting, a sticker being earned, a milestone.
- Rive has a native iOS runtime. Widgets and Live Activities cannot run it, as far as I know, so those use still frames from the same artwork **[verify]**.
- Respect Reduce Motion: every animation needs a still fallback. Nothing animates at night beyond the minimum.
- Motion must never delay logging. Animation plays after the tap is recorded, not before.

Apps to study (from memory, **[verify]** details): Citymapper (voice, joke transport modes), Duolingo (character cast carried into widgets and icons), Headspace (soft shapes, animation), Gentler Streak (one elegant recurring character), Carrot Weather (personality as the product), Andy Works' (Not Boring) apps (skins as the paid layer), Finch (a companion that grows), How We Feel (quiet, elegant illustration), Pok Pok (hand-made feel for children).

### Brand

- Tone: calm, warm, non-judgemental about feeding and sleep choices, never guilt-inducing.
- Name must work across US/UK/EU/JP/AU/NZ, have an available `.com` or `.app`, and clear trademark search in classes 9 and 42.

### Brand architecture (proposed, 2026-11-10)

One name, used everywhere; the cast grows underneath it, as with Miffy, Bluey and Peppa Pig.

| Where | Name |
|---|---|
| Master brand, character, trademark | **Puggle** |
| App | **Puggle**, with an App Store subtitle that explains it (e.g. "Baby and family tracker") |
| Clothing label | **Puggle** on the tag |
| Books and any animation | **Puggle and Friends** as the series name (Miffy's TV series was *Miffy and Friends*) |
| Company | **Puggle & Co.** as the legal and trading name |

Rejected: Puggle Kids (sounds like a clothing size range and dates as children grow); Puggle & Kip (fixes the cast too early and splits attention). A single-word mark is also the simplest to register and protect.

### Logo variants and applications (2026-11-10)

On the canvas: A wordmark with a quatrefoil full stop; B stacked face over wordmark; C face in the blossom badge; D pill with face and wordmark; E scallop awning; F monogram "p" with quatrefoil; G line face in a roundel (stamps, embroidery); H woven label with line face and wordmark; I woven tab, face only (sleeves, socks). In one-colour versions the bill is filled solid so the face never reads as a frowning mouth.

Clothing mock-ups: tees (face and wordmark; friends repeat; Breton stripes with a woven tab), onesies (line-face repeat; shapes repeat), bucket hat in a shapes print, beanie with a woven tab, socks with the face at the ankle.

### Palette and type (draft, 2026-11-10)

| Group | Tokens |
|---|---|
| Base | Ink #3A2A20, Paper #FBF6E9, Sand #F2ECDD, Night #1B2440, Moon #F3E0B8 |
| Brights (fills) | Wattle #F4BE2C, Harbour #2A62B8, Waratah #E5553B, Gum #3C9A5F |
| Soft fields (child colours, backgrounds) | Sky #BFD9F5, Shell #F3D9C9, Mint #CFE5D2, Sun #F4E7B0 |
| Puggle | Fur #8A5A3C, Bill #6E7F8D, Blush #EE9C88, Stitch #C24A36 |

Rules: text is Ink on light colours, Paper or Moon on Night. Waratah, Gum, Bill and Stitch pass contrast only for large text, so they are fills, never small text. Each child takes one soft field as their colour. Contrast values are on the canvas sheet.

Type: Bricolage Grotesque ExtraBold for the logotype, display and titles; the iOS system font for headline, body and caption so Dynamic Type works. Components: chunky outlined buttons with a hard Ink shadow; soft rounded chips in the child's colour.

### Name shortlist (2026-11-10, resolved: Puggle)

Checked only with one App Store-oriented web search each. No trademark or domain search has been done.

| Name | Why | Against | Quick check |
|---|---|---|---|
| **Ducklings** | A row of ducklings behind a parent: several children, one adult keeping them together. "Ducks in a row" also means being organised. Affectionate, and gives the illustration a natural cast | More playful than premium; needs elegant execution | No app of this name found |
| **Goslings** | Goslings imprint on a parent and follow in a line. Slightly more grown-up than Ducklings | Many people will think of the actor first | No app of this name found |
| **Cygnet** | A baby swan. The most elegant option; fits the premium night look | Hard to spell and say for some | No app of this name found |
| **Fawn** | Gentle, short, elegant | Singular; "to fawn" means to flatter | No app of this name found |
| **Peapod** | "Peas in a pod": siblings and twins, snug together. Warm, character-friendly | A US grocery delivery brand uses the name (from memory, **[verify]**) | No baby app of this name found |
| **Poppet** | British term of endearment for a small child | Singular; little meaning outside the UK, AU and NZ | No app of this name found |
| **Small Hours** | The time parents are awake. Also "the hours of the small ones". Fits the premium night look | Suggests a night-only app. Same idiom as an existing app, Wee Hours | No app of this name found |
| **Brood** | A family of young. One syllable, distinctive | "Brooding" has a gloomy sense | No app of this name found |
| **Fledge** | Growing up through stages | Less warm; easily misheard | No app of this name found |
| ~~Handful~~ | | **Rejected by Tom:** used when children are being naughty; negative connotation | |
| ~~Little Wins~~ | | **Taken:** "Little Wins: Celebrate Today" and a "LittleWins" family routines app exist | Exists |
| ~~Joey~~ | | **Taken:** a baby tracker called Joey exists (possibly now archived), plus an older Joey baby journal | Exists |
| ~~Waddle~~ | | **Taken:** Waddle - Parenting Copilot | Exists |
| ~~Piglet, Owlet, Cub~~ | | Piglet is a well-known Disney character; Owlet is a baby monitor brand; Cub names are crowded (CubTrack, Cubtale) | From memory and earlier searches |
| ~~Wee Hours~~ | | **Taken:** "Wee Hours – Baby Tracker" is a free, native SwiftUI tracker with a dark night interface by a solo parent-developer. Worth studying as a direct competitor | Exists on the App Store |

### Future option: a shared brand with a childrenswear label

Tom's wife, a fashion designer, plans a kids' clothing range and was considering the name **Puggle** (a baby echidna or platypus). The app and the label could share one name and one illustrated world.

- **What links them:** the characters. The same cast appears in the app's scenes and as prints on clothes. Both sell to parents of 0–5s.
- **What the app could offer the label:** an audience; opt-in size prompts from the child's logged measurements; milestone moments (first birthday); a tag code on a garment that unlocks a matching theme or icon.
- **What the label could offer the app:** revenue beyond tips and themes, and a physical presence. Physical goods sold in an iOS app do not go through in-app purchase **[verify]**.
- **Guardrails:** no shop inside the family's data, no use of a child's data for marketing without explicit opt-in, and nothing leaves the device. One clearly marked place in the app, not banners.
- **Not in v1.** Keep the option open cheaply: choose one name that works for both, check trademarks in both software and clothing classes, and secure the domain and handles together.
- **Name check so far:** one web search each found no childrenswear brand and no App Store app called Puggle. Search results are dominated by the pug-beagle dog cross, which is what many people outside Australia will think of. No trademark search done.

#### Fashion references (Tom's wife)

Oliver Bonas, Gorman, Gorman Kids, Next Kids, JoJo Maman Bébé, Caramel. Characterised from memory, **[verify]** before quoting.

- **Themes as collections.** Fashion works in seasonal drops. A theme could launch with a clothing collection and share its print and palette.
- **Guest artists.** Gorman is known for artist collaborations; the equivalent is guest-illustrator themes, credited by name.
- **Print as identity.** A repeat pattern, not a logo, is what makes these brands recognisable. The app's scenes and backgrounds can be built from the same patterns that go on fabric.
- **Quiet base, one loud moment.** Caramel's muted palette for the app's structure; Gorman-level colour reserved for the scene and the child's photo.
- **Naming.** None of these names describes babies. They are personal names, a phrase and a soft noun, which age better than descriptive or cute names.

### Logotype (exploring, 2026-11-10)

Brief from Tom: bold, blocky, current. Six free Google Fonts tried on the mockup canvas: Bagel Fat One, Dela Gothic One, Rubik Mono One, Climate Crisis, Bricolage Grotesque ExtraBold, Gasoek One.

- **Chosen (Tom, 2026-11-10): E, Bricolage Grotesque ExtraBold, lowercase.** Legible, quirky, still sophisticated. Earlier shortlist was A Bagel Fat One, D Climate Crisis, E, F Gasoek One.
- Refinements on the canvas: E1 as set; E2 condensed (75% width, more fashion-label, suits the woven label); E3 the double g picked out in an accent colour.
- Type system: Bricolage Grotesque for the logotype and headlines; the iOS system font for interface text so Dynamic Type works.
- Whichever is chosen is a starting point: the final wordmark should be redrawn (spacing, the double g, perhaps a bill or tail detail) so it is ownable, and the font licence checked for logo and trademark use (Google Fonts are under the Open Font License **[verify for each]**).

### Website (Vercel)

Landing page, pricing, privacy promise, help centre, press kit, web view for invite links, status page.

### Support

In-app contact with diagnostics attached, searchable help centre, public roadmap/feedback board, TestFlight and Play beta channels. Apollo's lesson: a visible, responsive developer is a marketing asset.

### Localisation

English (US/UK/AU/NZ variants) at launch, then Japanese, German, French, Spanish. Metric/imperial and date formats per locale from day one.

## 11. Roadmap

Built for two people. Each step ends with something usable.

| Step | Outcome |
|---|---|
| 1. Teardown | Tom lists what annoyed him in the apps he tried; we test the top five with two child profiles and write down the specific failures |
| 2. Core flows | Tom designs the family timeline, log sheet and timers. Claude runs the CloudKit sharing spike in parallel |
| 3. Household build | Shaped by Tom's two children. **Baby (6 mo):** bottle feeds with volume, sleep, nappies, first solids. **Toddler (2.5 y):** potty attempts, successes and accidents, naps and night sleep. Both on one family timeline, with concurrent timers and partner sharing. Installed on the family's phones via TestFlight. No paywall, no polish |
| 4. Live with it | Two to four weeks of real use. Fix what grates. This is where the product gets good |
| 5. Native surfaces | Live Activities, widgets, Siri/Shortcuts, night mode |
| 6. Growth and stages | Measurements with WHO charts, milestones, breastfeeding timers, pumping, allergen checklist, health log |
| 7. Beta | 20–50 outside families (include twin parents). Add the tip jar. Decide what, if anything, goes in Pro. Illustration commissioned |
| 8. Launch | App Store, English-speaking regions first. Website live |
| Later | Apple Watch, region packs for UK/AU/NZ/US schedules, Japan and EU, Android |

I have left out durations. They depend on how many hours a week Tom has, and I would rather set them after step 3 shows our real pace.

## 12. Decisions

**Settled**
- Team is Tom and Claude; indie scale; start small.
- Free app with a tip jar; one-off Pro unlock for themes, icons and extras later; no subscription.
- iOS only for v1; Core Data with CloudKit; household is all-Apple; Tom has a Mac with Xcode.
- Name: Puggle (app, character, label); Puggle and Friends (stories); Puggle & Co. (company).
- App look: Refined Puggle (§6); line icons at 1.4 pt with one accent; app name only on splash, icon and Help.
- Characters, cast, expression and accessory rules as summarised at the top.
- Twins and several children are a design target; first build is driven by a bottle-fed 6-month-old and a potty-training 2½-year-old.

**Open**
1. **Apple Developer account** ($99/yr): needed for CloudKit and TestFlight.
2. **Pebble's name and sex**, and whether Quill stays a friend.
3. **Pro price** and contents (themes, icons, extras).
4. **Potty training method** (timed sits, child-led, a three-day method): changes what is worth logging and reminding.
5. **Today layout:** calm list or cards (both on the canvas).
6. **Trademark and domain checks** for Puggle in software, clothing, books and toys.

## 13. Not yet accounted for (2026-11-10)

**Product and app**
- Core screens redone in Refined Puggle (Today as list and as cards, bottle sheet, import, onboarding, splash). Still to do: potty, sleep timer, history, Lock Screen and widgets in the refined style.
- Palette and type drafted (§10); still to do: a design system file with spacing, radius and component specs.
- Onboarding: intro screens drafted (§6); setup steps still to design.
- Notifications and reminders: what, when, tone, and how they stay quiet at night.
- Empty states, errors, settings, export and account deletion screens.
- Accessibility pass: contrast of the palette, VoiceOver labels for characters, Reduce Motion fallbacks.
- How the characters age with the child, and how a family with three children or twins is shown.

**Characters and world**
- A character bible: personalities, likes, catchphrases, rules of what each will and won't do.
- Mum, Dad, Nan and Pop not drawn; Pebble's sex and name not confirmed.
- Family diversity: single parents, two mums or two dads, grandparents raising children, disability, different feeding choices.
- A prop library and a scene kit (backyard, beach, bedroom, bathroom) built from the flora and places.
- Production: master vector files, Rive rig, export sizes, animation principles.

**Business and legal**
- A company structure, and agreement between Tom and his wife on who owns the characters and brand (IP assignment).
- Trademark searches and filings for "Puggle" and the logotype in software, clothing, books and toys classes, in Australia first; domain and social handles.
- Apple Developer account as an organisation, not an individual, if a company is formed.
- Privacy policy and terms; children's health data rules for each launch region.
- Clothing: Australian mandatory standards for children's products (for example nightwear flammability labelling and small parts), sizing, manufacturing and sourcing.
- Books: self-publish or approach a publisher; board-book safety for under-threes.
- Budget and time: hours per week, and what is paid for (illustration help, legal, trademarks).

**Go to market**
- Website, App Store listing, screenshots and preview, launch plan, beta families (including twin parents).
- Support, feedback and roadmap channel.

## Sources

Competitors and pricing
- [Huckleberry Plus FAQ](https://huckleberrycare.com/huckleberry-plus-faq) · [SweetSpot membership announcement](https://huckleberrycare.com/huckleberry-plus-announcement)
- [Huckleberry review 2026, HealthAppInsider](https://www.healthappinsider.com/en/parenting/huckleberry-app-review) · [RootWise review](https://www.rootwise.app/en/huckleberry-review/) · [Pebbi pricing comparison](https://pebbi.co/blog/baby-tracker-pricing-comparison-2026)
- [Baby apps ranked 2026, Unstar](https://unstar.app/blog/huckleberry-baby-tracker-sprout-glow-baby-daybook-baby-tracker-apps-ranked-2026)
- [Nanit Insights plans](https://support.nanit.com/hc/en-us/articles/4406381421975-What-is-the-difference-between-the-different-Nanit-Insights-plans) · [Nanit pricing](https://www.nanit.com/pricing)
- Twin apps: [DoubleLoving](https://mwm.ai/apps/doubleloving/6761315506) · [Multibaby](https://mwm.ai/apps/multibaby-two-baby-tracker/6747767694) · [Twiniversity](https://apps.apple.com/app/id1572683514)

Official content
- [WHO weight-for-age standards](https://www.who.int/childgrowth/standards/weight_for_age/en/)
- [CDC Learn the Signs. Act Early. overview](https://www.cdc.gov/autism/media/pdfs/LTASE-program-one-pager-P.pdf)
- [NHS syndicated content APIs](https://api.gov.uk/nd/nhs-syndicated-content-rest-apis/) · [NHS content not licensed for reuse](https://www.nhs.uk/our-policies/terms-and-conditions/content-not-licensed-for-re-use/)
- [RCPCH Digital Growth Charts](https://www.rcpch.ac.uk/resources/growth-charts/digital/about) · [Growth references](https://growth.rcpch.ac.uk/clinician/growth-references/)
- [Raising Children Network content reuse FAQ](https://raisingchildren.net.au/about-us/media/FAQs-about-content-reuse)
- [NZ Well Child Tamariki Ora My Health Book](https://healthed.govt.nz/cdn/shop/files/he7012-well_child_full_jun_25_5.0_web_0.pdf)
- Japan electronic handbook: [MHLW material](https://www.mhlw.go.jp/content/10901000/001648075.pdf) · [Tokyo pilot](https://www.metro.tokyo.lg.jp/information/press/2026/01/2026011519)

Privacy and technical
- [FTC Health Breach Notification Rule](https://www.ftc.gov/system/files/ftc_gov/pdf/p205405healthbreachnotificationrule.pdf) · [Premom settlement summary](https://www.clym.io/regulations/ftc-settles-charges-for-misuse-of-health-information)
- [PowerSync and Supabase](https://supabase.com/partners/powersync)
