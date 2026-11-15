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
| Characters | Puggle (platypus, 2½, potty training) and Pebble (baby platypus, Kewpie curl); friends Quill, Kip, Digby, Sunny; Mum, Dad, Nan, Pop. Flat colour, each outline a darker shade of its own colour, dot eyes, soft oval cheeks, no mouth; eyebrows only with a feeling; emotion through eyes, eyebrows, cheeks, marks and body; hands always visible; quatrefoil clip |
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
- Never a mouth, no dark patches on the face. Eyebrows are off at rest and appear only with a feeling (changed 2026-11-12, below); never angry, sad or worried.
- **Hands and feet (decided 2026-11-10):** round ball hands in fur brown (not slate), slightly larger; a thin cuff line where sleeve meets hand; feet stay slate and are a little larger and more paddle-like. Applied across the current canvas sheets (expressions, family, hands, builder, wallpapers, books); earlier exploration sheets are left as they were. Hands do things: wave (with motion arcs), clap (with clap marks), hands to cheeks for "oh!", peekaboo (the only time hands cover the face; arms tuck behind the head), and holding props. Next: a prop library (bottle, nappy, potty, toothbrush, book, wattle, balloon).
- **Arms and hands always visible** (Tom, 2026-11-10). Arms sit in front of the garment and behind the head. Raised arms go up and out at about 45 degrees, hands clear of the head; never straight up behind it. Lowered hands stick out past the garment's edge. Hands held in front rest on the garment, never over the face or bill. Every pose is checked as a solid silhouette: if a hand disappears in the silhouette, redraw the pose.
- Never a mouth, no dark patches on the face. Eyebrows are off at rest and appear only with a feeling (changed 2026-11-12, below); never angry, sad or worried.

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
**Face and legs refresh (2026-11-10, adopted).** Bill smaller, flatter and a touch lower (94 x 38 at 240 wide, was 108 x 50), nostrils reduced to pin dots so they stop reading as eyes. Eyes lower and slightly larger, on the head's centre line, 54 apart (was 60); blush drops with them. Legs shorter-looking and thicker (28 wide, was 20). Dress shape, tail, colours, clip, stitched blush and the no-mouth rule unchanged. **Small version** for under about 100 pt tall: plain blush, no nostrils or pocket, line a quarter heavier. Applied across the live canvas: all character sheets, the character builder, logo variants, clothing mock-ups, books, wallpapers, brand architecture, splash, onboarding and the refined app screens. The friends (Quill, Kip, Digby, Sunny) share the thicker legs. Glasses moved with the eyes (eye level 108, resting on the bill 134). Archive boards keep the old face.

**As built in the app (Tom, 2026-11-12, adopted).** Decided while the app's own drawing of her was made; the app's file of her parts (`app/Puggle/Resources/Rigs/puggle.rig.json`) is now the reference, and the model sheet on the canvas is drawn from it (`design/canvas/gen/model2.py`). These replace the matching points above:

- **Coloured outlines.** Each line is a darker shade of the colour it goes round: fur `#5E3A24`, bill and feet `#465668`, dress `#1B4387`, clip `#B23A26`. Same weights as before. Cheeks and other inside shapes have no line. Dark brown `#3A2A20` is kept for eyes and nostrils. The single dark line stays available for the app icon and small marks if they need the contrast. Reasoning is in `docs/animation-plan.md`.
- **Eyes** lower, wider apart and a little smaller: centres at (88, 117) and (152, 117), radius 6.8, at 240 wide (were 93 and 147 at 108, radius 7.6).
- **Cheeks** are soft ovals with no marks (24 by 15 at (70, 132) and (170, 132), `#C27C66`). The stitch marks are no longer always there: three short marks appear on each cheek when she is pleased (a nod, proud). This replaces "blush with stitches" as her resting face.
- **Eyebrows, only with a feeling.** Off at rest. Raised for delight, soft for content and sleepy. Never angry, sad or worried. This replaces "no brows". Still no mouth, and the bill never changes.
- **Eyes squeezed shut** (> <) at the top of a hop and in a stretch.
- **Pocket** light blue (`#8FB4E3`), quieter than the yellow that was tried.
- **Clip** has a yellow centre and two small highlights.
- **Feet** are webbed, with toes, each on its own ankle. **Tail** has markings.
- **Dressed for the weather:** coat and boots for rain, scarf and beanie for cold, straw hat and zinc for heat.
- **Night:** she keeps her colours, seen by moonlight (cooler, leaning violet).

Applied (13 November): the app, the model sheet, and the canvas boards for expressions, hands, family, cast line-up, glasses, marks, heads, construction, the three app scenes, the twelve scenes, wallpapers, books, onboarding and the refined app screens. The coloured line is applied to the whole cast on those boards. Not yet: the flows, the motion studies, logos and the icon and sticker boards (the dark line may stay for logos and small marks), and the friends' cheeks, which still have stitches.

**Side view (2026-11-10).** In profile the bill is the same rounded ellipse as the front view (80 x 36, tilted up 4 degrees), overlapping the front of the face by about half, not a flat slab stuck on the side. Eye and blush sit just behind it. Applied to the model sheet and the walk poses.

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
- **Refinements from the reference sets:** the bottle has a slight waist mid-body so it reads as a baby bottle faster; the nappy has clear curved leg cut-outs; the pram hood is split into segments, with one panel in the accent.
- **The Puggle style** (canvas: "The Puggle style", "Shapes and Australiana, in the Puggle style", "Holographic stickers"). One drawing, three finishes:
  - *Line* (the app, SF Symbols): 1.4 pt Ink line, all corners rounded, and **colour by activity** from the brand palette, filling one main part inside the line: feeding and milestones Wattle, sleep Sky, nappy, potty and bath Mint, play and outings Blush, health and growth Shell. In single-colour contexts the fills drop out. (The "slipped" off-register colour was tried for the app and dropped.)
  - *Sticker* (celebrations, widgets, potty chart): palette fills, gentle two-tone (right half a touch deeper), Wattle sparkle, a paper die-cut edge and soft shadow.
  - *Holographic sticker* (rare): pastel foil fill and die-cut edge, sliding glare, quatrefoil glints. On iPhone the tilt (Core Motion) drives a SwiftUI Metal shader; Reduce Motion gives a still sheen. Earned only for big moments (milestones, a dry week) plus an occasional surprise Puggle's-clip sticker.
  - *Print* (clothing, wallpapers, books): flat colour, no outline; the ink line slips up and left, like a real two-screen print. The slip lives only here.
  - Rules: chubby toddler proportions; soft everything; colour by activity; sparkles use Puggle's **quatrefoil** (from her hair clip), never a plain star; no faces on objects in the app; draw once.
  - Soft shapes (quatrefoil, pill, scallop, soft square, soft hexagon, pebble, half pill, blossom) and Australiana props (thong, esky, Hills Hoist, lamington, fairy bread, pavlova, surfboard, zinc stick) are redrawn on the same grid in all finishes.
  - Nappy redrawn: waistband with side tabs (filled), round body, curved leg cut-outs. Bottle collar wider than the body; pivot dot on the pram hood.
- **Set pieces and backgrounds** (canvas, Brand page): Beach, Bush walk, Sydney Harbour, Backyard, The park, Rainy day, The pool, Grandma's house, The café, The farm, The shops, Night street, plus a kit of parts (cloud, sun, gum tree, Norfolk pine, ferry, sailboat, umbrella, surf flags, sandcastle, bucket and spade, Hills Hoist, lemon tree, kite, terrace, street lamp, moon, slide, shell). House style, brand palette plus soft Sky/Harbour tints for water and distance; lower middle kept clear for the cast. For books, wallpapers and Today headers. Deliberately generic places: no named rock formations or sacred sites, and **no Sydney Opera House** (its image is a registered trade mark); the Harbour uses a generic arch bridge and ferry.
- **Scene rules** (second pass): two horizons (open places at 40%, enclosed at 70%); a stage in the lower middle kept clear for the cast; one scale (Puggle 70 units tall in a 390 x 300 scene, props sized to her); line weight by distance (far 1.2 softened, middle 1.8, front 2.2; big flat areas unoutlined); light and weather per scene, three cloud shapes, one hero object plus two or three supporting ones; nothing awkwardly cut at the frame edge.
- **Illustration references** (canvas: "Illustration references", Brand page). On the wall: Dick Bruna/Miffy (the look), Alison Lester (the world), Miroslav Šašek's *This is Sydney* (the place), 1930s Australian travel posters (the light). Also Taro Gomi, Charley Harper, Owen Davey, the Provensens, Mary Blair, Bob Graham, Pamela Allen, Marc Martin, May Gibbs, Ken Done, Bluey backgrounds and Animal Crossing, each with what we take and what we avoid. The board is words only; an image mood board stays private (Figma or Are.na) and is never published.
- **Scene approach, v2** (canvas: "Three scenes for the app", App page; test on "Night street, a different approach"). The world is flat shapes with **no outline**; only the cast keeps the Ink line. Each scene has a three-colour key, one big shape, real light (shade tones, cast shadows) and a moment for the cast. First three, for the Today header and milestones: **Morning** (sun rising behind the back fence, Puggle stretching, Pebble beside her), **Bedtime** (moon behind the terrace roofs, Puggle under the street lamp, the cat on the wall), **Celebration** (giant Wattle quatrefoil, bunting, balloons, confetti, Puggle with Quill and Kip). The whole young cast has small-size versions (Puggle, Pebble, Quill, Kip, Digby, Sunny), shown on the cast line-up. Morning, second pass: sun with a glow over the neighbours' roofs, paling tops catching the light, a scalloped fence shadow, sunlight pooling on the lawn, dew, a magpie on the fence and a ball. All twelve places are now redrawn this way (canvas: "Set pieces and backgrounds", Brand page): Beach, Bush walk, Sydney Harbour, Backyard (the morning scene), The park, Rainy day, The pool, Grandma's house, The café, The farm, The shops, Night street (the bedtime scene). Each lists its colour key and its moment. At night the terraces keep a whisper of their daytime colours (about a quarter of the pastel mixed into the night blue). A new flat kit of parts (26 pieces, from sun and glow to the quatrefoil star) sits under the scenes. Rain is drawn in two depths with gusts and gaps, never as an even grid. The shops use one wall colour family and one awning colour, told apart by picture signs. The first outlined version and its kit are on the Archive page; the earlier "scene rules" (two horizons, stage, line weight by distance) are superseded by the five rules above, except scale.
- **Indoors after tea, and friends that change (2026-11-13, built).** Puggle is two and a half, so she is not left outside after dark. On Today: 18:00 the tea table, 19:00 the living room or the play room (alternate days), 20:00 to 06:00 her bedroom, in pyjamas. With the dark or night look on by day she is in the living room or play room. Rooms follow the scene rules: flat shapes, no outline, the floor in the page colour; only the cast (her, the cat, her toy rabbit) has a line. Blocks, cushions, pictures and wallpaper use the soft shapes in brand colours. The window shows the real evening, moon or rain. Pulling down shows more wall and what hangs on it. Outdoors, each scene has its own three things in the pulled-down sky by day and three after dark. Friends change with the time of day, season and weather: the bird sings at dawn, preens at dusk and sleeps at night; the crab digs into the sand until only her eyes show, and stays dug in after dark, in the wet and the cold; the snail comes out at night and in rain and shuts herself in when it is hot or cold; the kookaburra laughs at dawn and dusk with his beak open; butterflies in spring and summer, falling leaves in autumn. In rain Puggle wears a yellow rain hat with her coat. Sheets: `docs/previews/scenes-pulled.png`, `docs/previews/rooms-pulled.png`.
- **The cast in the scenes (2026-11-13, first pass built).** Nan, Mum, Dad, Pop, Pebble, Quill, Kip, Digby and Sunny are in the app, cut from the canvas's "The cast, to scale" into rigs by `app/tools/make_cast_rigs.py` (run it again when the drawings change). They share Puggle's part names, so they breathe, blink and tilt their heads as she does, and borrow her nod, wave and hop. On Today, some days she is alone and others someone is with her, changing each time a place comes round: Sunny, Mum or Quill on the hills; Digby (digging), Pop or Dad at the beach; Dad, Quill or Nan in the backyard; Kip (dozing; a tap on Puggle wakes her for a moment), Nan or Sunny in the bush; a grown-up at tea every evening; Nan, Pop or Pebble in the living room; a friend or Pebble in the play room; Mum or Dad at bedtime most nights. They wave when Today opens, nod now and then, and answer when Puggle is tapped. While a child sleeps the children in the cast sleep too; grown-ups stay up. Not yet: anything two characters do together (holding hands, passing a ball, a cuddle, reading), seated poses, or Pebble's own moves. Sheets: `docs/previews/cast.png`, `company-outdoors.png`, `company-indoors.png`.
- **The cast, second pass (2026-11-13, built).** The cast takes Puggle's 12 November refinements, applied in `app/tools/make_cast_rigs.py` so the canvas drawings stay the source: soft oval cheeks with no marks, her eye size, a pocket filled a lighter shade of the garment, her arms (sleeve with a dark edge, cuff line, ball hand) in place of the friends' plain blocks, tail markings on the grown-ups, each leg on its own ankle. **Feet are bare for everyone, as hers are; shoes appear only as weather clothes.** The platypus family has her webbed feet. Kip has round paws with three short dark claws; Digby broad paws with four stout pale claws; Quill three long curved claws; Sunny long hind feet with small dark claws. Digby's beanie sits higher, clear of his eyes. Pop's hat has a real brim. Mum's flower is a small daisy, so it reads as a flower and is not mistaken for Puggle's clip. Pebble has dot eyes at rest, so he blinks. **Names:** the cast is offered by name as avatar pictures ("Choose a character", beside Take a photo and Choose a photo, for any grown-up in the family). The portrait is saved as their photo, so nothing new syncs. Children have no picture yet, only a colour and initial; giving them one needs a new synced field. Sheets: `docs/previews/cast.png`, `cast-portraits.png`.
- **The cast, third pass (2026-11-13, built).** **Proportions:** grown-ups are drawn at Puggle's own scale, so they share her head size, and their bodies are shortened to about one and a quarter times her height (the canvas's two and a half times read as stretched beside her). **Noses nearer the animals:** Kip a tall, rounded, leathery koala nose; Digby a broad flat pad with two nostrils; Sunny a small dark nose on a pale rounded muzzle; Quill a slimmer snout with a small dark tip. **Feet in Puggle's hand:** one shape with a flat ankle, rounded sides and a row of toes with a nick between each, turned out as hers are, with that animal's claws showing past the toes (koala short and dark on dark pads, wombat stout and pale, echidna long and curved, quokka small and dark on long feet). **Accessories:** Nan's reading glasses rest on her bill with her eyes over them; Pop's round glasses sit on his eyes and his bucket hat has a deep crown and sits on his head; Mum's daisy sits on her head; Kip's bow is on top of her head; Sunny's hat sits higher so her ears show. All in `app/tools/make_cast_rigs.py`.
- **The cast's wardrobe (2026-11-13, built).** Each character keeps what makes them who they are (species, nose, signature accessory) and changes only the garment, as Miffy does. **Garments** come from the canvas's character builder: Quill, Kip and Digby each have three of jumper, dungarees, dress, and tee with shorts; the grown-ups, Pebble and Sunny keep one garment. **Colours:** every garment comes in four brand colours (three for Digby), as a swap of the garment's colour, outline and pocket. **Weather**, when they are outdoors with Puggle: the garment turns raincoat yellow in rain; everyone has her scarf in the cold; Mum and Dad, who have bare heads, also get her rain hat, beanie and sun hat. What each wears is picked by the day and stays all day. Pop's glasses now sit round his eyes (they were set for the older, closer eyes), and Digby has a short line under his nose, as Sunny has, so the nose is not read as a mouth. Not done: a wardrobe for Puggle herself beyond her weather clothes and pyjamas; choosing an outfit by hand. Sheet: `docs/previews/cast-wardrobe.png`.
- **The friends' feet, softened (Tom, 2026-11-13).** Pointed claws read as fierce beside Puggle. **No claws on anyone:** each friend's foot is one soft toed shape, like hers, with a small rounded nail on each toe, a shade lighter than the foot. The animals differ by the number of toes, how broad the foot is, and how long the nails are (Quill's a little longer, for digging).
- **Weather accessories and nights out (Tom, 2026-11-13, built).** Each character's weather clothes carry their own signature: accessories are in their colour (Nan red, Mum wattle, Dad and Pop green, Quill and Kip blue, Digby, Sunny and Pebble red). **Cold:** a scarf and mittens for everyone; a beanie for Mum and Dad; Digby keeps his own beanie; Sunny's sun hat becomes a beanie in its colours; Kip has ear warmers over her ears. **Wet:** Mum, Dad, Pop, Digby and Pebble wear a yellow raincoat (Mum, Dad and Digby with a rain hat; Pop keeps his bucket hat); Nan, Kip, Quill and Sunny, who cannot wear a rain hat, keep their clothes and carry an umbrella. **Hot:** a straw hat with their colour as the band for Mum, Dad, Digby and Kip; Nan's umbrella is her parasol; zinc on the nose for Quill and Pebble. Digby does not wear the A-line "jumper", which reads as a dress: tee and shorts, or dungarees. **Nights out:** one evening in three Puggle is outdoors after dark, from 18:00 to 22:00, in the night scenes, and always with a grown-up (Mum, Dad, Nan or Pop in turn); bed is still bed from 22:00. Sheets: `docs/previews/cast-wardrobe.png`, `night-out-with-grown-up.png`.
- **Checked against the brand book (2026-11-14).** The canvas as a 40-page PDF is at `docs/brand/Puggle-brand-2026-11-14.pdf`; read it before stating a rule. **The brand book predates the animation research of 14 November, and two newer directions from Tom replace what it says:** (1) **Views: front only.** She always faces the viewer. The brand book's three-quarter, side and back views, its "acting view" and its side-on walk proposal are superseded; their poses (potty dance, flop-sit, tippy-toe reach) are still wanted, redrawn from the front. (2) **Hair: a lick of hair,** part of her head in the same fur and line. The brand book's "No hair" board is superseded for Puggle; the rest of the cast keep accessories and Pebble keeps a curl. Which shape is not yet chosen (the single leaning lick is the front-runner). Everything else below is from the brand book and stands, and corrects things said or drawn on 13 and 14 November: (3) **Hands.** Always visible and clear of the head and body in silhouette; raised arms go up and out at about 45 degrees; hands held in front sit on the garment, never over the face or bill; "Oh!" is hands to the cheeks; peekaboo is the only time hands cover the face. (4) **The tail shows the feeling**, one position each: calm (resting, slightly raised), happy (up and wagging), proud (straight up), surprised (stiff, straight out), sad (drooping; only for her own stories), shy (tucked in), sleepy (curled round her feet). None of the 14 November mock-ups used it. (5) **Reactions are snappy** (decided): hold each pose and pop to the next; breathing, sleeping and scenes stay smooth. The refined moves keep this. (6) **Proportions:** about two and a half heads tall, head 1, body three-quarters, legs a third. (7) **One thing at a time:** when she moves, the scene behind her goes still. Not yet true in the app. (8) **Small sizes** under 100 pt: no nostrils or pocket, line a quarter heavier. Not yet in the app (avatars would use it). (9) **Sparkles are quatrefoils, never plain stars.** (10) Her dress is never recoloured; a patterned dress (quatrefoil, gum leaf or wattle print) is an open proposal, and is the route to more outfits for her. Not yet taken from the canvas into the app: her full expression list (laughing, sad, shy, cheeky, proud), the comic-style marks (sweat drop, dizzy, hearts, gloom lines, puffed cheeks), the twelve places and the moment in each (for example Puggle and Quill on the bush walk, Pop at the harbour, Nan at her house).
- **One head, one outline (Tom, 2026-11-14, built).** Whatever grows from a head is part of the head: the head's own fur and the head's own line, joined to it with no line between, so it changes the head's outline instead of sitting on it or behind it. This applies to hair, ears and spines alike. **Puggle** has one small leaning lick, left of centre and clear of her clip; it is hidden under her beanie, sun hat and rain hat. **Pebble** keeps a round curl in the centre, now a filled lock like the lick (a stem that rolls over into a round end, with a small spiral mark), not the old wire; the round curl is Pebble's and the pointed lick is Puggle's. **Kip, Digby and Sunny:** ears run into the head with no line across them. **Quill:** spines are the head's brown with its line, joined to the head; the cream spines are gone. **Nan:** her bun is joined to her head, with the red tie across it. Mum, Dad and Pop have nothing growing from their heads and are unchanged. **Each is still a part of its own in the rig**, with its own pivot at its base and its own spring, so it can be posed and animated by itself: `lick` (Puggle), `curl` (Pebble), `ear-left` and `ear-right` (Kip, Digby, Sunny), `spine-1` to `spine-8` (Quill), `bun` (Nan). Each ear, spine and bun has a child part ending `-top` that lays its fur over the seam; move the parent and the child follows. Nothing animates them yet. Done in `join_to_head` in `app/tools/make_cast_rigs.py`. Sheets: `docs/previews/cast.png`, `cast-portraits.png`, `head-parts.png` (each part moved alone).
- **Ears, spines and hair show feeling; quick eyes smear (Tom, 2026-11-14, test only).** Two proposals, both in the animation test (`-debugAnimTest 1`) and neither switched on in the app. (1) **Feelings:** ears, spines, the lick and the curl each take a held position for a feeling, as her tail does: happy (ears perk, spines fan a little, hair stands taller), surprised (ears up and out, spines bristle wide, hair straight up), shy (ears fold down, spines flatten, hair droops), sleepy (a smaller droop), curious (one ear and the spines on that side lift, hair leans). Set through `RigRuntime.held`; the numbers are `AnimationTestView.feelings`. (2) **Eye smear, after Bluey:** when her eyes move 3 points or more in one go, they are drawn for about 65 ms as one shape stretched along the way, then round again at the new place. Behind `RigRuntime.refined`. Her lick and Pebble's curl also arrive late on a head tilt, with her clip. **Mum and Dad's hair** is a sheet of options, not built: Mum a side sweep, two curls, a bob that flicks out, or sweep and flicks; Dad a scruffy crest, a flat brush, cheek tufts, or crest and tufts. Sheets: `docs/previews/feelings.png`, `parent-hair.png`; video `docs/previews/refinements/animation-test-eyes-and-feelings.mp4`.
- **Hair for the grown-ups (Tom, 2026-11-14, built).** So each has an outline of their own, as Bandit and Chilli do. **Mum:** a side sweep on top and a bob that flicks out at each side, with her daisy. **Dad:** a scruffy three-point crest and small cheek tufts. **Nan:** soft round curls at each side, under her bun. **Pop:** bushy cheek tufts under his bucket hat. All in the head's fur and line, each lock a part of its own (`sweep`, `flick-left/right`, `crest`, `tuft-left/right`, `curl-left/right`, each with a `-top` child), from `grow_hair` in `app/tools/make_cast_rigs.py`. Mum's sweep and Dad's crest are hidden under a beanie, rain hat or sun hat; the side pieces always show. The family likeness: Pebble's curl from Mum's sweep, Puggle's lick from Dad's crest. Sheets: `docs/previews/grown-ups-hair.png`, `cast.png`, `cast-portraits.png`, `cast-wardrobe.png`.
- **Under the hats (Tom, 2026-11-14, built).** Digby and Sunny have hair under their hats, for when the hats come off: Digby a coarse, stubby three-point tuft between his ears, Sunny two small pointed wisps, kept small and pointed so they are not read as a third ear beside her round ones. Each is the part `tuft` (with `tuft-top`), from `grow_hair`. There is a new outfit value, **`bare`: hats off**. Their own hats now also come off in pyjamas (`night`). The tufts show for `night` and `bare`; Puggle's lick, Mum's sweep and Dad's crest show for `none`, `night` and `bare`. Nothing in the app sets `bare` yet (no scene takes hats off by day); it is there for indoor scenes, stories and close-ups. Kip (a bow) and Quill (spines) have no hat to take off. Sheet: `docs/previews/hats-off.png`.
- **Hats, finished (Tom, 2026-11-14, built).** **Pompoms are wool:** the pompom on Digby's beanie, and on the beanie Puggle, Mum, Dad and Sunny wear in the cold, is a third bigger than it was, with a tufted edge of short uneven points and a finer line, not a smooth ball (`fuzzy` in `app/tools/make_cast_rigs.py`; Puggle's own is in `puggle.rig.json`). **Sunny's ears come up through the brim of her sun hat:** the ears are drawn again over the hat and the front half of the brim goes back over them (`ear-left-through`, `ear-right-through`, `brim-front`), and they still move with her ears. Sheet: `docs/previews/hats-off.png`.
- **Pebble is a boy (Tom, 2026-11-14).** Puggle's baby brother, about six months. Two sisters was too close to Bluey. Say "he" and "little brother" everywhere; anything earlier in this document that calls Pebble a sister or "she" is superseded. His look is unchanged: the round curl, the romper, the bottle. The app never states his sex, so no screen text changed.
- **Clothes for the grown-ups (Tom, 2026-11-14, built).** Each of Mum, Dad, Nan and Pop has three outfits, and every outfit is two colours: the garment's own and a trim that contrasts with it, as their weather things do. **Mum:** a dress with a collar and a band at the hem; a top and a skirt; a top tucked into trousers. **Dad:** a shirt and shorts; a striped jumper over trousers; a tee under overalls. **Nan:** her cardigan with a collar and pockets; a dress under an apron; a jumper and a skirt. **Pop:** his cardigan with a collar and a breast pocket; a shirt under a waistcoat; a jumper with diamonds. Each outfit comes in four colour pairs (for example Mum: gum with wattle, waratah with sky, wattle with harbour, harbour with shell), so twelve looks each. Drawn in `dressed` in `app/tools/make_cast_rigs.py`; the pairs are `PAIRS`; rigs are `mum-skirt`, `mum-trousers`, `dad-jumper`, `dad-overalls`, `nan-apron`, `nan-skirt`, `pop-waistcoat`, `pop-jumper`. Which they wear is picked by the day, as for the friends. Trousers are drawn with the body, so they do not swing with the legs in a walk. Sheets: `docs/previews/grown-ups-wardrobe.png`, `cast-wardrobe.png`.
- **Umbrellas and rain hats (Tom, 2026-11-14, built).** **An umbrella's canopy is the last thing drawn**, in front of hair, ears, spines, bows and hats, at its full shape: it covers their tops and is not flattened to clear them (`umbrella-top`, a child of `umbrella`, whose shaft still passes behind the head). The umbrella has a slim metal shaft and a wooden handle that hooks round below the hand, and the hand is drawn again over the shaft so it is held. **Pop wears the same yellow rain hat as everyone else in a raincoat**; his bucket hat is now its own part (`hat`) and comes off in the rain. **Raincoats and rain hats stay yellow for everyone:** yellow is what says rain at a glance, and it matches Puggle's. Umbrellas stay in each character's own colour. **Nan's hair** is a sheet of options, not built: the bun (now), a set of curls, a soft roll, a wave to one side, a plait round her head. Sheets: `docs/previews/weather-clothes.png`, `nan-hair.png`.
- **How an umbrella is held (Tom, 2026-11-14, built).** The umbrella stands straight up, at one height and one size for everyone, and **all of it is in front of the character**: shaft, handle and canopy are the last things drawn, over the head, ears, spines, bows and hats. So the shaft does not cross the face, it stands beside it, and the arm changes: with the umbrella up, a second right arm (`arm-right-hold`) is shown, raised with the fist up beside the cheek, so only a short length of shaft shows below the canopy, and the usual arm is hidden. Heads sit at one height in every drawing, so the fist is at the same height against the face for grown-ups and children. The wooden handle is short and hooks round just below the fist. The canopy is full size and centred on the shaft, so it reaches past the character's side; these four rigs carry `sideroom`, and `CastView` draws them on a wider surface without changing where they stand or how much room they take. The canopy has three ribs, fine lines in a darker shade of its own colour from the tip to each point where two scallops meet. They cannot wave with that arm while holding it.
- **The platypus tail, redrawn (Tom, 2026-11-14, built).** The tail was an oval lying beside the legs with a line down its middle and two across: it read as a leaf, and on the grown-ups it floated clear of the body (Dad's hung beside his knees). It is now a **paddle**: narrow where it leaves the body, broad and round at the end, with two short ridges across and no midline. Its base is tucked in behind the body, so it always grows out of them. It leaves the body at the hip, level with the hand, not down by the knees; a sitting baby's is at his hip too, clear of the ground. The same shape for Puggle, Pebble, Mum, Dad, Nan and Pop (`paddle` and `regrow_tail` in `app/tools/make_cast_rigs.py`; Puggle's is in `puggle.rig.json`). Its pivot moved to the new base. Sheet: `docs/previews/platypus-tails.png`.
- **Decided 14 November 2026 (Tom).** (1) **Nan has a set of curls**, not a bun: built (`curls`, with her side curls). (2) **Quill's spines stay the brown of her head.** (3) **Pebble's dummy** is a mock-up only, as an occasional prop for sleepy moments: a shield and ring resting on the front of his closed bill, which does not change (`docs/previews/pebble-dummy.png`); not built. (4) **The tested movement is switched on in the app** (`RigRuntime.refined` now defaults to on): the blink that shuts fast and opens slowly; eyes leading a head tilt; the hop with weight (`play` picks a move's `-refined` version where there is one); the eye smear (checked frame by frame: stretched at 16 and 50 ms, round again by 100 ms; `docs/previews/eye-smear.png`); and ears, spines and hair taking a position for a feeling (`RigFeeling` in `Rig.swift`): sleepy while asleep, happy during a wave or a hooray, a smaller happy for a nod, surprised on waking, curious while the eyes follow a finger. At night the positions are halved with everything else. Shy is defined but nothing triggers it yet. The tail does not yet take part.
- **Pebble's babygro (Tom, 2026-11-14, built).** The canvas drew his garment as a flared triangle, which read as a dress. It is now a babygro: a rounded suit close to the body, a leg each side with a cuff, poppers round the inside of the legs, a seam down the front, a neckband, and feet. He sits with his legs out towards us, so each foot shows as a rounded sole in the suit's colour with a paler pad; his own webbed feet are inside it (`babygro` in `app/tools/make_cast_rigs.py`). It comes in wattle (as drawn), sky, mint, shell, waratah and gum. **A bottle or a dummy, never both (Tom):** with a dummy he has no bottle and his hands rest together. **Open:** which colour is his own (wattle is now the rain colour), and whether he has a dummy; the mock-up dummy is larger than the first, with a pale ring, in a colour that contrasts with the babygro (`docs/previews/pebble-dummy.png`).
- **Pebble, settled (Tom, 2026-11-14, built).** His babygro is **mint** (gum was tried first; it is Mum's colour); it also comes in sky, shell, gum and waratah, and wattle is dropped because yellow is the rain colour. His legs are a thigh each side with a fold where it meets the body and a large sole towards us; his hair is one wave swept to the side with three little flicks along its top (chosen from `docs/previews/pebble-curl.png` over the round curl; the part is still called `curl`). **Awake he has his bottle; asleep he has a wattle-yellow dummy** and his hands rest together: one or the other, never both. The dummy is the part `dummy`, shown when his eyes are closed; the bottle (`held`) is shown when they are open. This closes the two open points in the babygro note above. Sheet: `docs/previews/pebble-dummy.png`.
- **Checked running, 14 November 2026.** Rainy scenes with each umbrella holder: the canopy ran under the profile button and off the edge of the screen when they stood to Puggle's right, so **someone holding an umbrella to her right is turned round** (`CompanyView`), which puts it on the side nearer her (`docs/previews/rain-with-umbrellas.png`). The new tails in a hooray and a wave, frame by frame: they stay joined and lift as before (`docs/previews/tail-motion.png`). The eye smear was seen in the running animation test. Not seen running: Pebble falling asleep (his dummy was checked on a sheet with his eyes closed), and the ears, spines and hair reacting to real logging.
- **Four loose ends closed (Tom, 2026-11-14, built).** (1) **The tail shows the feeling**, with the ears, spines and hair (`RigFeeling.tail`): up and wagging when happy, as high as it can go and still be seen when proud (straight up is hidden behind her from the front), stiff and straight out when surprised, tucked in when shy, drooping when sleepy, a little raised when curious. A move that places the tail itself keeps it. Proud is its own feeling now, played with the potty-success move. (2) **Shy has a trigger:** the first tap on her in ten minutes takes her by surprise, and she is shy for about a second (cheeks, lick and tail) before she is herself; later taps get the giggle as before (`RigRuntime.feel`). (3) **Pebble's legs:** the thigh's edge sits inside the sole, so there is one line at the outer edge. (4) **Trousers walk:** the hips stay with the body and each trouser leg is part of its own leg, so it swings in a walk (`trouser_legs`, parts `trouser-left/right`). Sheet: `docs/previews/tail-feelings-and-trousers.png`.
- **Wallpapers and books, second version** (Brand page). Wallpapers: two lock-screen scenes (Morning, Bedtime) with the sky left clear for the clock, plus three repeats: round sticker badges of the cast over a gum-leaf and quatrefoil line pattern, a one-colour line repeat (prints as one screen), and a single-character brick repeat with a soft shadow. Books: covers are the scenes (Puggle at the Beach; Night Night, Puggle; Puggle and the Big Puddle; Puggle Goes to Nan's), title in the scene's sky colour, series name at the foot, Ink spine; spreads are words left, picture right. First versions are on the Archive page.
- **Animal Crossing wallpaper references (Tom, 2026-11-10).** Ideas taken: sticker heads with a coloured edge over a house-motif line pattern; one-colour line repeats; one character tiled with a soft shadow; a quiet screen with a small scene at the bottom; soft star sprinkles. Not taken: any Nintendo character, the leaf mark, or their colours. Our motifs are the gum leaf and the quatrefoil. A second batch (Mario, Pikmin and Animal Crossing wallpapers) added three more: **tone on tone** (the activity icons as a one-colour pattern with the cast in front), **the parade** (everyone in a row along the bottom, a faint motif grid above, bushes in front) and **night lines** (the activity icons as line drawings on night blue). Lessons: leave room; tone on tone; one motif family (gum leaf, quatrefoil, activity icons); the same drawings work as line or as flat shapes.
- **Motion studies for Rive** (canvas: Characters page; sources in `design/canvas/gen/motion.py`). Looping SVG sketches, to be rebuilt in the Rive editor. Puggle: **Idle** (breath, blink every 4 s on its own layer, tail drift), **Wave** (greet), **Hooray** (squash, jump, land, quatrefoils pop), **Sleepy** (slow breath, nodding head, floating z), **Walk** (two key poses). State machine "Mood": triggers `greet` and `celebrate` return to Idle; booleans `asleep` and `walking`. Scenes get slow ambient loops (rising sun, twinkling stars, falling rain, falling confetti) with Puggle nested; Reduce Motion shows the still scene. Second pass added anticipation, squash and stretch about the feet, follow-through (tail, clip and head a beat late), idle one-offs (a glance, a tail flick), a falling-asleep transition and a four-key walk (contact, down, passing, up). Parts for import, with named groups: `design/rive/puggle-parts.svg`. The contract between the Rive file and the app (file, artboard, state machine and input names, timings, order of work) is `design/rive/README.md`; the app side is `PuggleView` and `PuggleController`.
- **Motion direction** (canvas: Characters page; `design/canvas/gen/motion2.py`). Drawn from how Bluey and Duolingo move, not from their designs. (1) **Reaction map:** wave once a day on first open; a 0.4 s nod for everyday logs; yawn and fall asleep when a sleep starts, stretch when it ends; proud ta-da for a potty success; the full hooray only for milestones; she walks during pull to refresh; her eyes follow a finger. (2) **Rules:** never in the way; **no guilt** (she is never sad about what a parent did or didn't log); quiet at night; silent by default; one thing moves at a time. (3) **The tail shows the feeling:** calm, happy, proud, surprised, sad, shy, sleepy each have a tail position. (4) **Timing (decided 2026-11-11):** snappy pose-to-pose for reactions, smooth for ambient. The snappy wave, hooray and a new 0.4 s nod were refined against captured frames. The walk was rebuilt as one continuous rig (a 0.84 s toddler waddle with a forward lean, arms opposite the legs, head and clip late); its four key poses are taken from the same motion. (5) **Toddler moves** in a three-quarter acting view: potty dance, flop-sit, tippy-toe reach. The Rive contract carries the new inputs (`nod`, `proud`, `wake`, `energy`, `lookX`, `lookY`).
- **Flows and journeys** (canvas page "Flows"; text in `docs/flows.md`; source `design/canvas/gen/flows.py`). An app map and seventeen journeys as numbered wireframe screens, 94 in all (ten original, revised after the persona walkthroughs, plus health, setup that fits the child, helpers, twins and pumping, calm and private, large text with VoiceOver and night, and outside the app). The original ten: first run, everyday logging, sleep, potty training, history and insights, family and sharing, children and characters, milestones and growth, settings with Pro and Help, and what happens when things go wrong. Structure: four tabs (Today, History, Insights, Family); everything else is a sheet over Today. New product decisions proposed in the flows and still to confirm: Parent and Carer roles; a "same bottle?" check when two people log within five minutes; a "still asleep?" question after 14 hours; invites that expire after seven days; notifications asked for only when a reminder is first switched on; child-chosen stickers after a potty success.
- **Persona walkthroughs (2026-11-11)** in `docs/persona-testing.md`: eight simulated personas walked the ten journeys. Not user testing. The findings are ranked in three tiers. Tier 1 is applied to the flows and Tier 2 is drawn as journeys 11 to 17; Tier 3 is a list of open decisions. Nothing is in the app code yet. Largest gaps: logging a breastfeed, health logging, entries going to the wrong child, the short undo, the thin Carer role, iPhone-only sharing, and accessibility (tap sizes, selection by colour alone, large text).
- **iOS craft review (2026-11-11)** in `docs/ios-craft-review.md`: Apollo and nine other apps, with ten recommendations. Most sources could only be seen as search summaries; see the note at the top of that file.
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

- **Rive:** the characters are a handful of flat shapes, so they suit Rive well. Duolingo uses Rive for its characters, with state machines for idle, talking and reacting states and lip sync driven by speech. Puggle needs no lip sync (no mouth); her states are eyes, eyebrows, cheeks, marks, poses and squash and stretch, which keeps the rig small. One rig per species, with garments and accessories as swappable parts, matches the character builder.
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
2. **Pebble's name** (he is a boy: decided 14 November 2026), and whether Quill stays a friend.
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
- Mum, Dad, Nan and Pop not drawn; Pebble's name not confirmed (he is a boy: decided 14 November 2026).
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

### App Store launch checklist (added 2026-11-11)

What sits under the headings above, written while getting the first build running on the Mac. Items marked **[verify]** have not been checked against current rules.

**Decide early (most likely to cause rework)**
- **Health data in iCloud.** App Review guideline 5.1.3 says apps may not store personal health information in iCloud. Many baby trackers sync through CloudKit, so it appears to be tolerated, but how Apple applies it to feed and nappy logs is unchecked **[verify]**. Settle this before the design rests on CloudKit.
- **Individual or organisation developer account.** The seller name on the listing is Tom's personal name unless we enrol as a company, which needs a legal entity and a D-U-N-S number. Switching later is slow.
- **CloudKit production schema.** The schema is deployed to Production before release; after that fields can be added but never removed or renamed. The data model must be settled by beta.
- **Reserve the name.** Creating the app record in App Store Connect holds "Puggle" on the store. Needs the developer account.

**Apple's required paperwork**
- Privacy policy URL and support URL, both live before review.
- Privacy labels, age rating questionnaire, privacy manifest file (`PrivacyInfo.xcprivacy`), export-compliance flag (`ITSAppUsesNonExemptEncryption`).
- For the tip jar and Pro: Paid Apps agreement, bank and tax forms, a Restore Purchases button, and the Small Business Program (15% commission instead of 30%).
- If we sell in the EU, trader contact details are shown publicly on the listing **[verify]**.
- A real app icon, and screenshots at the required sizes.

**Emailing people**
- With no accounts we hold no user email addresses. That is the privacy story, and it means we cannot announce anything to users directly.
- A `support@` mailbox on our own domain, with SPF, DKIM and DMARC set up.
- An opt-in newsletter on the website for launch and update news. Australia's Spam Act requires consent and an unsubscribe link.
- In-app "Contact us" that opens a pre-filled email with app version and diagnostics. No server needed.

**Security**
- CloudKit data is encrypted, but not end-to-end by default; sensitive fields can be marked for it **[verify which fields]**.
- Share links: invitations should work only for the invited person, not anyone holding the link. Add a way to remove a caregiver.
- Data loss is the realistic risk, more than theft: export, soft deletes, and migration tests.
- A "delete everything" option, and optionally a Face ID lock.
- Crash reports from Apple's own tools, so the "no third-party SDKs" promise holds.

**Help**
- A sync status screen ("last synced", iCloud signed in or not). "My partner can't see the data" will be the top support request.
- A short FAQ on the website, linked from the in-app Help screen.
- A "not medical advice" line wherever insights or growth charts appear (see §7, the regulatory line).

**Website**
- Domain, landing page, privacy policy, terms (Apple's standard licence can stand in), support page, press kit.
- The web view for invite links listed in §10 may not be needed: CloudKit share links are Apple's own.

**Legal (an hour with a lawyer)**
- Children's and health data rules in each launch country. Australia's children's privacy code was still being finalised at the time of writing **[verify]**.
- The trade mark search and the IP agreement already listed above.

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

**Family heap: Puggle stays put (2026-11-14).** On the last first-run screen she used to follow whichever shape was highest, including one being dragged or thrown, so she was flicked about the screen. Now she stands only on a shape at rest, the shape she is on cannot be picked up, she keeps her shape unless another is clearly higher, and a change of shape is a soft step across. Her feet sit on the shape's real top edge, so she no longer hovers over a pill or a scallop.

**Backyard sky: bubbles and leaves (2026-11-14).** Pulled down, the bubbles used to fade out at the top of a small box, so they stopped part-way up the sky. A second set now carries on from there at a steady pace and leaves by the top of the screen, about one for every 60 points of sky. Dandelion seeds are for spring and summer only; in autumn and winter the third surprise is leaves on the wind, flat and in the brand's warm colours.

**Start sleep for both: removed (2026-11-14).** Tom: both children sleeping at the same time is rare, and pressing two Start sleep buttons is not hard. The pill under the child cards, and its "Both woke up" twin, are gone from Today. Five placements were mocked up first (`docs/previews/sleep-for-both/`) and none was taken up.

**Arms that bend at the elbow (2026-11-14, built for the whole cast).** Every arm is cut in two at the middle of its curve, so the forearm turns about an elbow. At rest it draws exactly as before. One arm, one outline: four parts per arm in this order: `arm-left` (upper arm's outline, turns at the shoulder), `forearm-left` (forearm's outline, turns at the elbow, carried by the arm), `arm-left-top` (upper arm's colour), `forearm-left-top` (forearm's colour, cuff and hand). Mittens, the raincoat's sleeve and the pyjamas' sleeve go with the forearm. A second copy of each forearm is drawn after the head and shown only while a move sets `arms=front`; that is the one way hands come in front of a face. A part's `when` can now need two things: `outfit=rain&arms=front`. Made by `app/tools/bend_arms.py` (run it for Puggle; `make_cast_rigs.py` calls it for everyone else).
- **Moves, worked out for each character's own shoulders and arm length:** `greet` is now a wave from the elbow (upper arm up and held, forearm waving; a grown-up's hand ends beside the head, clear of it). `oh`: a small start, hands to cheeks, clear of the bill, eyes wide. `read`: a book held open at the chest, eyes down, a page turned every seven seconds, round until `stop("read")`; everyone but Pebble. `hug`: her rabbit, a squeeze and a sway; Puggle only.
- These three have `exact: true`, so the night's half-size movement does not leave hands short of the cheeks or the book.
- **Not yet wired in:** nothing in the app plays `oh`, `read` or `hug` yet. Only the new wave is live. To decide: when each happens (reading in the living room or at bedtime, the rabbit at bedtime, "oh" for a surprise).
- Sheet: `docs/previews/bending-arms.png`. In motion: `docs/previews/refinements/bending-arms.mp4` (the first part of "-debugAnimTest 1").

**Switches: back to the standard iOS one (Tom, 2026-11-14).** The app's own switch (ink track, paper knob with a tick) is removed. Every switch is now the system one in its usual green; the green is set explicitly because the app's ink tint would otherwise turn it brown. Known cost: in the night look the green track and white knob are brighter than everything else on the screen.

**Bubbles are not for the sky (Tom, 2026-11-14).** The bubbles in the pulled-down backyard sky are removed: loose bubbles with nobody making them looked random, and the set that rose off the top moved oddly as the page scrolled. Bubbles are kept for when Puggle or a friend is making them (not built). In their place in the backyard sky: a red balloon that got away, drifting with its string. `docs/previews/backyard-sky.png`.

**Grown-ups hold a book lower (Tom, 2026-11-14).** With the book at the chest a grown-up's long arms stuck out wide at the elbows. The book is now held where the hands rest at about four fifths of the arm's reach below the shoulder: at the tummy for Mum, Dad, Nan and Pop, elbows in; unchanged for the children (`book_drop` in `app/tools/bend_arms.py`).

**Puggle makes bubbles (2026-11-14, built).** A bubble wand in her right hand (part `wand`, on the forearm, under the hand), swept slowly up and down with her eyes on it; move `bubbles`, round until stopped. No blowing, so no mouth is needed: the bubbles come off the wand as it moves. Kip, Quill, Digby and Sunny have the wand and the move too; the grown-ups and Pebble do not.
- **When:** on Today, in the backyard, outdoors by day, in fine weather (no coat or scarf), with no child asleep and Reduce Motion off. She starts 7 seconds after the scene appears, makes bubbles for 10 seconds, then again every 35 to 60 seconds. A tap, a log, a walk or falling asleep puts the wand away at once.
- **The bubbles** rise from above the wand only while she is making them (`controller.makingBubbles`), and fade in and out.
- A rig with something held out to the side has `sideroom`, and `RigView` now draws it on a wider surface so the wand is not cut off at her edge. Whether a companion has an umbrella up is now read from the `umbrella` part, not from `sideroom`.
- For checking: `-uitest 1 -debugScene 2 -debugHour 13 -debugWeather clear -debugBubbles 1` (bubbles after 2.5 seconds; wake Ollie first, as a sleeping child keeps her indoors).
- Not built: a friend making bubbles on Today (they have the move; nothing plays it).
- `docs/previews/puggle-making-bubbles.png`; poses on `docs/previews/bending-arms.png`.

**Grey for Nan and Pop (2026-11-14, open).** Tom asked whether Nan's curls and Pop's tufts should have grey streaks. Four options on `docs/previews/grey-hair.png`: A as now, B a few streaks, C salt and pepper, D all grey. Nothing built. Tom chose salt and pepper and asked how to blend it in better; four ways on `docs/previews/grey-blend.png`: 1 a softer colour, 2 tapered locks in two tones that follow the curls (suggested), 3 swept up from the brow (Pop: grey at the tips), 4 faded hair with lighter locks. Tom then asked for short dashes, as Bandit's and Chilli's speckled patches are drawn in Bluey (reference looked at on bluey.tv/characters/bandit; studied, not copied). Three dash versions on `docs/previews/grey-dashes.png`: 5 grey-brown, 6 silver, 7 two tones thinning down from the crown (Pop: onto his temples). Tom was unsure and asked for other references. Seen on bluey.tv/characters/nana: Bluey's Nana is her son's colouring made paler and greyer all over, with the same dashes and half-moon glasses; her age is in the whole coat, not in streaks. Four more on `docs/previews/grey-others.png`, with a row beside Mum and Dad at app size: 8 greyer fur all over, 9 greyer fur with dashes (suggested), 10 pale round the bill, 11 pale round the bill with dashes. Tom liked 8 and 9 but not so pale ("we don't want them to look sickly"), and asked for the edge line to be lightened with the fur. Two warmer steps on `docs/previews/grey-warm.png`, each plain and with dashes: A fur `#8F644A` with line `#6B4833`; B fur `#946E56` with line `#73523E` (the family's are `#8A5A3C` and `#5E3A24`).

**Nan and Pop are going grey (Tom, 2026-11-14, built).** Chosen after the option sheets (`grey-hair`, `grey-blend`, `grey-dashes`, `grey-others`, `grey-warm` in `docs/previews/`):
- **Fur:** the family's brown a little lighter and softer but still warm, so they look older and not unwell: `#946E56`, with its edge line lightened to match, `#73523E` (the family's are `#8A5A3C` and `#5E3A24`). Everywhere they have fur: head, hair, hands, tail and legs.
- **Dashes:** short grey marks through the hair in two tones, grey-brown `#B79F8A` and silver `#D6CDBE`, fanned out from the middle of the head and thinning as they go down. On Nan they are evenly spaced in staggered rows and all much the same length, as a speckled coat is drawn; only the way each one leans is varied (a fixed seed, so she is the same every time). Tom: "They could still be evenly spaced, like in Bluey, but I think the directions could be randomised a bit more." An unevenly scattered version was tried first and was not what he meant. On Pop: three along each cheek tuft and three on each temple, under the brim.
- Only the grandparents have them. Made by `older` in `app/tools/make_cast_rigs.py`. Sheet: `docs/previews/going-grey.png`.

**Glasses and sunglasses (2026-11-14, open).** Tom: Nan's glasses could have no glass in them (Bluey's Nana has none), in red, with Pop's in green; try other shapes; and sunglasses that anyone could wear in summer or hot scenes and in the books. Mocked up, nothing built:
- `docs/previews/glasses-frames.png`: Nan in red with no glass (A round, B half-moon, C oval, D cat-eye, E soft square) and Pop in green (A round, B half-moon, C oval, E soft square, and A with a thicker frame). Thin frames nearly vanish at app size.
- `docs/previews/sunglasses.png`: three ways, because the rule is that glasses never hide the eyes and the eyes carry the feeling: 1 dark lenses (eyes hidden), 2 tinted lenses with the eyes showing through (drawn under the eyes), 3 pushed up on the forehead. Frames in each character's own accent colour.

**Nan's and Pop's glasses (Tom, 2026-11-14, built).** Nan's are red half-moons, flat across the top and round below, resting on her bill so her eyes look over them; the bridge sits above her nostrils. Pop's are green and round, round his eyes. Neither has glass in it, and the frame is thick enough to read when small (6.5). The colours are one step off the brand's (`#E5543B`, `#3C9B5F`) so that a garment's colour swap never repaints the glasses. `spectacles` in `app/tools/make_cast_rigs.py`. (Round red frames were built on Nan first by mistake: Tom's "I like A with the dark lenses" was about the sunglasses.) Options sheet: `docs/previews/glasses-frames.png`.

**Sunglasses styles (2026-11-14, open).** Tom prefers round frames with dark lenses to tinted ("I like A I think with the dark lenses. The tinted is a bit odd") and asked for other styles, such as aviators with a mirror finish. Six on `docs/previews/sunglasses-styles.png`, across eight of the cast: round dark, aviator mirror (thin metal frame, flat silver lens with two glints), aviator dark, round mirror, soft square dark, hearts dark. Nothing built. Dark and mirrored lenses both hide the eyes, which sets aside "glasses never hide the eyes" for sunglasses; to settle: when they are worn and whether she takes them off to react. Tom then showed a reference (a sticker of Bingo from Bluey in oversized sunglasses): far too big for the face, a heavy bar across the brow with no rim below, and lenses in two flat bands, darker above and lighter below. Five of our own in that spirit on `docs/previews/sunglasses-big.png`: sunset lenses with the bar in each character's own colour, night lenses, mirror lenses with a silver bar, big mirrored aviators, and sea lenses with a wattle bar.

**Pop's everyday outfit: a shirt and chinos (Tom, 2026-11-14, built).** His long cardigan read as a dress. It is replaced by a button-up shirt tucked into chinos with a belt: the shirt in the garment's colour with its own collar, breast pocket, placket and three buttons; the belt in the trim colour; the chinos always sand (`#D3BE97`), which no colour swap touches. Four colour pairs as before (shirt and belt change, chinos stay). The trouser legs swing with his legs like the other trousers. His other two outfits (waistcoat, diamond jumper) are unchanged. Nan keeps her cardigan.

**Trousers: a rounded seat (Tom, 2026-11-14, built).** The hips were a box wider than the legs, which left a sharp corner sticking out each side at the bottom of the bum. The seat now curves in to meet the legs. All trousers: Pop's chinos, waistcoat and jumper outfits, Dad's jumper outfit and overalls, Mum's trousers. `docs/previews/trousers-rounded-seat.png`.

**Glasses colours (2026-11-14, open).** Tom wondered whether Nan's and Pop's frames should contrast with their own colours, or swap (Pop red, Nan green). Four options against every colour their clothes come in, on `docs/previews/glasses-colours.png`: A as built (Nan red, Pop green), B swapped, C Nan wattle and Pop red (suggested), D Nan harbour blue and Pop wattle. Nothing changed in the rigs.

**Glasses colours: decided (Tom, 2026-11-14, built).** Nan's half-moons are wattle yellow, Pop's round frames are red (option C). Yellow reads best on brown fur at small size and is none of her coat colours; red is the opposite of his green hat. In the rigs as `#F4BD2C` and `#E5543B`.

**Keep every variant: a Character Builder may come to Play (Tom, 2026-11-14).** Tom: "it's good to keep all the variants and options, as we may also add a Character Builder into the play section, so they could select different outfits and accessories". So options that were not chosen are kept, not deleted, and new work should be made as parts that can be switched, not baked into one drawing. What exists today, and where:
- **Outfits, built and switchable:** three per grown-up and up to three per friend, each in four colour pairs (`dressed`, `PAIRS` and the `-variant` rigs from `app/tools/make_cast_rigs.py`; `Rig.wardrobe.looks`). Weather things by `outfit`: scarf, beanie or earmuffs and mittens; raincoat, rain hat or umbrella; sun hat, parasol, zinc; pyjamas; `bare` for hats off.
- **Things held, built:** book, bubble wand, Puggle's rabbit, Pebble's bottle and dummy, umbrellas (`holding=…` and `outfit`).
- **Hair, drawn as options only:** the parents' and grandparents' hair sheets, Nan's other hair, Pebble's curl variants, Puggle's tuft options (`RefinementSheets.swift`; `docs/previews/parent-hair.png`, `nan-hair.png`, `pebble-curl.png`, `refinements/refine-9-tuft-options.png`).
- **Glasses, drawn as options only:** frame shapes round, half-moon, oval, cat-eye, soft square; any frame colour; with or without glass (`glassesOptions`, `glassesColours`; `docs/previews/glasses-frames.png`, `glasses-colours.png`).
- **Sunglasses, drawn as options only:** round, aviator, soft square and hearts with dark or mirror lenses; tinted; pushed up; and the big two-tone pairs with a brow bar in five colourings (`docs/previews/sunglasses.png`, `sunglasses-styles.png`, `sunglasses-big.png`).
- **Grey, drawn as options only:** streaks, locks, dashes, greyer fur in three steps, a pale muzzle (`greyHair`; `docs/previews/grey-*.png`).
The options that are only on sheets live in debug code. Before a builder, each needs to become a part in the rig files with a `when` of its own.

**Sunglasses (Tom, 2026-11-14, built for the whole cast).** Thirteen styles, each a part of its own in every rig, shown while the face has `shades=<style>` (`none` for no sunglasses). Made by `app/tools/sunglasses.py` (run it for Puggle; `make_cast_rigs.py` calls it for everyone else).
- **Ordinary size**, a little bigger than a pair of spectacles (Tom: "slightly bigger, but not as big as page 3"): `round-dark` (the default), `aviator-mirror`, `aviator-dark`, `round-mirror`, `square-dark`, `hearts-dark`, `flowers-dark` (five petals in the frame's colour round a dark lens; added at Tom's request), `round-tinted` (amber, eyes showing through).
- **Big**, after the reference Tom showed: `big-sunset`, `big-night`, `big-mirror`, `big-aviator`, `big-sea`. A heavy bar across the brow, no rim below, lenses in two flat bands.
- **Colours:** frames in each character's accent colour unless the style has its own (metal, gold, wattle). Every colour is one step off the brand's so a garment's colour swap never repaints them.
- **Eyes come first.** Dark and mirrored lenses hide the eyes, which sets aside "glasses never hide the eyes" for sunglasses only. So each pair has a `lift`: it slides up onto the forehead (44 for ordinary pairs, 52 for big ones, far enough to clear raised eyebrows) whenever her eyes have something to say: a reaction, a feeling (shy), following a finger, or sleep. A move that goes round (walking, reading, bubbles) leaves them down. They are drawn over the whole face, so eyes, eyebrows and shy cheeks all stay behind the glasses (Tom: "Let's make sure facial features stay behind the glasses"), and under hats. In the friends' and family's drawings the closed eyes are brought forward to sit with the eyes for this. The one exception is `round-tinted`, which is under the eyes by design.
- **When:** on Today, anyone dressed for the heat (`outfit == "sun"`) wears `round-dark`, Puggle and whoever is with her, along with their sun hat, zinc or parasol. `Shades.forOutfit` in `Weather.swift`; passed down as `\.shades`. Nan's and Pop's own glasses come off when a pair goes on.
- **For checking:** `-debugShades big-sunset` puts any pair on whatever the weather; `-debugWeather hot` for a hot day.
- Not built: choosing a pair (the Character Builder), and sunglasses in the books.
- Sheets: `docs/previews/sunglasses-built.png` (every style on everyone, in the heat, and pushed up), `sunglasses-on-today.png`.

**First-run demo: no banner (Tom, 2026-11-14).** The yellow "Demo. Nothing here is kept." banner is removed from the first-run demo while the flow is being refined; Tom found it distracting. A small faint cross in the bottom-left corner, below the main button, closes the demo. The current flow as built is on `docs/previews/onboarding/current-flow-1.png` and `current-flow-2.png`.

**First run, revised (2026-11-14, mock-up, open).** Tom asked to revisit the flow and to show more of the features, before setup. `docs/previews/onboarding/revised.html` and `revised.png`, made from real screenshots of the build. Proposal: welcome (plus "Takes a minute. No account." and the invite route always visible); five feature pages before any question, each with a different scene and companion and a real piece of the app (logging, every child on one screen, everyone who helps, the week at a glance, quiet at night and private); then setup as now with a strip of scene over each question and short questions as headings; the heap as the finish. One progress bar for the pages and one for setup; Skip on every page. Left for later tips on Today: Siri and widgets, medicine reminders, Play. Nothing built. Tom then said the headings and text were jumping all over the place between pages. Reworked on one skeleton for every page, feature and setup alike: scene, progress, heading (always two lines, from the same height), text (two lines of room), the piece of the app or the fields (always below the words), button. Only the welcome and the heap have their own layout. Reference looked at: Duolingo's first run (in a UXCam round-up), which keeps mascot, question and button in the same spots on every screen. Tom then: no profile button in first run, so Skip goes top right in its place and the progress bar runs the full width; headings in SF Rounded (heavy). The mock-up shows both. To settle when built: whether SF Rounded is for first-run headings only or replaces the display font everywhere. Tom then asked for the copy to follow the tone of voice, with no widows or orphans and no AI tells. Rewritten to `docs/writing-guide.md`: one message a page, no "we", no "should", buttons start with a verb ("Continue", not "Next"), no slogans or paired opposites. Headings are two lines broken by hand; body text keeps its last words together.

| Page | Heading | Text |
|---|---|---|
| 1 | Log the day / in a tap or two | Feeds, sleeps, nappies and the potty, with one hand. |
| 2 | Every child / on one screen | A baby and a toddler side by side, each with their own sleep timer. |
| 3 | Share the day / with your family | Invite a partner, a grandparent or a carer. You choose what each can do. |
| 4 | Look back / over the week | Totals and patterns for each child, whenever you want them. |
| 5 | Your entries / stay private | Kept on this iPhone and in your iCloud. (Below: No account, no email or password to set up. No ads, nothing is sold or shared. See how your data is kept.) |
| 6 | Who's logging / on this iPhone? | Your name shows beside what you log. |
| 7 | Add your / first child | Their age sets what shows on Today. |
| 8 | Anyone else / to add? | Twins and siblings share one Today. |

Welcome: "It takes about a minute." with "Join with an invite" and "Look around first". When built in SwiftUI the line breaks need the same care: a hand break in each heading and non-breaking spaces before the last words of the text, checked at the larger text sizes.

**First run: scenes or patterns (2026-11-14, mock-up, open).** Tom: the pages cram a scene and a piece of the app into the same space; scenes could be backgrounds, or the repeat patterns could go behind the pieces. `docs/previews/onboarding/backgrounds.html` and `backgrounds.png`: one page five ways (A scene and piece as before, B tone-on-tone soft shapes, C the same with the cast as round portrait badges, D bright shapes, E the scene as a background), then all five pages as C, which is the suggestion: a soft field per page (Sun, Sky, Shell, Mint, Night) with a repeat of the brand's soft shapes, the piece of the app as the one picture, portrait badges on the panel's lower edge, then progress, heading, text and button. Scenes stay for the welcome and for Today. Nothing built.

**Repeat patterns (Tom, 2026-11-14, first solid pass).** Tom chose shapes only (option B) for the first-run pages and asked for a proper pass on the repeats. Seven patterns made from the brand's eight soft shapes by `docs/tools/make_patterns.py`, each one seamless tile, tone on tone (a soft field, shapes a little darker, darker again, or lighter), in six colourways (Sun, Sky, Shell, Mint, Night, Sand): **Toss** (pebbles and quatrefoils in three sizes, turned every way), **Pills** (pills and half pills in a brick repeat with dots), **Bloom** (blossoms in a half-drop with small quatrefoils), **Comb** (hexagons as honeycomb), **Sparkle** (quatrefoils large and small, the brand's stars), **Scales** (scallops in overlapping rows), **Check** (soft squares in two tones). Tiles as SVG in `docs/previews/patterns/tiles/`; sheet `docs/previews/patterns/repeats.png`. On the first-run pages: `docs/previews/onboarding/patterned.png` (Pills on Sun, Toss on Sky, Bloom on Shell, Comb on Mint, Sparkle on Night; setup has a short band, Check on Sand and Scales in the child's own colour). Not in the app yet. **Second pass (Tom, same day):** "more evenly spaced, maybe slightly larger elements", and to go back to the references. The reference images themselves (Amigável by Latinotype; the Nintendo wallpapers) were shared in an earlier session and were not to hand, so this pass follows what was recorded from them and the repeats already on the brand canvas (`design/canvas/gen/shapes.py`, `merch.py`): shapes all one size on an even grid, one in the middle of every square, tone on tone, room left between. Now eight repeats on that one rule: **Mix** (all eight shapes in turn), **Pair** (quatrefoil and blossom, as on the clothing boards), **Pills** (lying and standing in turn), **Bloom** (blossom and pebble), **Comb**, **Sparkle** (large and small quatrefoils in turn), **Scales**, **Check**. The scattered Toss is dropped. Shapes are about a third larger. **Third pass (Tom, same day):**
- **No dark pattern in light mode.** Sparkle on night blue was too dark beside the others, so it is now on Lilac (`#E0D3EE`, already a child colour), and Night is no longer a colourway. Every pattern instead has a **dark-mode version** in each of the six colours: a deep, muted field with shapes a little lighter or deeper (`DARK` in `make_patterns.py`; tiles `*-dark.svg`).
- **Comb:** smaller hexagons on the same spacing, so the gaps are clear.
- **Four outline patterns**, at Tom's suggestion, on the same even grid in one line colour: **Faces** (eight of the cast's heads, taken from the app's own rigs by `head()`, never redrawn), **Things** (the app's line icons: bottle, sleep, nappy, bath, solids, potty, play, a first), **Friends** (heads and things in turn), **Lines** (the eight soft shapes as outlines). Twelve patterns, six colours, light and dark: 144 tiles.
- `docs/previews/onboarding/patterned.png` now shows the five feature pages in light and in dark mode.
- **Polish pass and motion (Tom, same day).** Puggle was missing from the line heads: her head shape sits on the `head` part itself where the others have it on a child, so only her face was drawn; fixed. Outlines are a quarter heavier, heads a touch larger, and the Faces set is Puggle, Kip, Quill, Digby, Sunny, Dad, Mum and Pop (Nan's glasses and curls were a tangle in line; Pebble was too like Mum). **The repeats drift slowly on the diagonal**, down and to the right, about 6 points a second, moving exactly one tile per loop so there is no jump; stopped under Reduce Motion (`css(..., drift=True)` and `DRIFT` in `make_patterns.py`). Clip: `docs/previews/patterns/pattern-drift.mp4` (10 seconds, three pages). In the app this would be a tiled image offset over time, paused with Reduce Motion and at night.
- **Line heads, corrected (Tom, same day).** Sunny's and Digby's mouths were missing: the short line under a friend's nose is drawn in the fur's own dark shade, not Ink, and the line version had dropped every non-Ink stroke. Now every line is kept except grey hair dashes and shines, and noses are solid like eyes. The Faces pattern has nine heads again (everyone but Pebble).
- **Nan's glasses are a fifth larger** (Tom: they read too small): each half-moon lens is 36 wide, where Pop's round ones are 30. In the rig, so in the app too.
- **Outline-only tweaks (Tom, same day): "We can make tweaks to ensure the features are legible."** The line version may differ a little from the character where that helps it read; the characters themselves are untouched. So far, in `OUTLINE` and `head()` in `make_patterns.py`: Nan's lenses are filled so her bill does not show through them, and her glasses sit a little lower so her eyes are clear; everyone's eyes are a fifth larger; nostril dots are twice the size (they were left out at first, but without them a bill reads as an open mouth). Per character and part: `solid`, `down`, `drop`. Added the same day: Pop's frames in a fine line (`thin`), so his eyes inside them do not read as double circles; Dad's cheek tufts were left out, then put back at Tom's request; Quill a sixth smaller (`_size`), as her spines made her far bigger than the rest; Digby's and Sunny's mouths longer and a little heavier (`_mouth`).
- **The pieces of the app, redrawn (Tom, same day): "refine the UI elements used in the flow".** They were crops of screenshots, each a different width with cut edges. Now each is drawn for the page by `docs/tools/make_first_run_mockup.py`, all on one rule: 270 wide, corner 20, one shadow, SF Rounded numbers, the app's own line icons. Logging: four tiles (Feed, Sleep, Nappy, Potty) with Feed chosen, over a bottle stepper. Every child: two cards, Bea awake and Ollie asleep on night blue with "Woke up", so the sleep timer is in the picture. Share: three entries by three people in one card. Look back: one whole chart, "Sleep this week", 91h, seven bars with their days. Private: two ticked rows and a link. Controls: Skip is a 36-high pill top right; progress is five 5-point segments full width; the button is 52 high; fields are 52 high. Privacy text shortened to "Kept on this iPhone and in iCloud." and "No email or password." so nothing wraps to a single word. Light and dark share the same drawing.

**First run: where Skip goes, and what Apple says (2026-11-14).** Tom asked for Skip higher in the top right and what Apple suggests. Apple's Human Interface Guidelines page on onboarding (read 14 November 2026) gives no position for a Skip button. What it does say: make onboarding fast, fun and optional; teach by letting people try things; prefer tips in context over one long flow; keep it brief; if people skip it, do not show it again but make it easy to find later (Help or Settings); postpone setup that is not essential and give good defaults; ask for a permission in the flow only if the app cannot work without it; ask for ratings or purchases only after people have used the app. On position, the limit is the system's: nothing of the app's can sit in the status bar, so the highest Skip can go is directly under it, in the top-right corner where a navigation bar's trailing button sits. The mock-up now draws the status bar to scale and puts Skip there. Follow-ups this suggests: a way to replay first run from Help, and tips on Today for Siri, widgets, reminders and Play (already the plan).

**Example names (Tom, 2026-11-14).** Mock-ups and example screens never use Tom's children's names. Use the sample family: Bea (2½) and Ollie (5 months), with Alex, Robin and Nan as the grown-ups. The first-run mock-ups, the animated prototype and the sleep-for-both sheet were changed to match.

**First run: the feature pages act out their headings (2026-11-14, prototype).** Each page plays once when it appears, two to four seconds, then rests; one thing moves at a time; Continue and Skip never wait for it; with Reduce Motion each page shows its finished state. The pattern behind rests while a page is acting and drifts on afterwards. **A circle shows where a finger taps** (Tom): it arrives, presses and rings out, on every tap of a button or tile.
1. Log the day: a tap on plus (150 to 160 ml), a tap on "Save bottle" (it turns green, "Saved"), then a tap on the Nappy tile, which opens Wet, Dirty, Both.
2. Every child: a tap on Bea's "Start sleep"; her card turns night blue beside Ollie's, and both timers count on.
3. Share the day: entries arrive one at a time, the newest last with a brief wattle glow, as if someone else has just logged it.
4. Look back: the bars grow from Monday to Sunday and the total counts up to 91h.
5. Private: the two ticks draw themselves. Nothing else moves.
Prototype: `docs/previews/onboarding/animated.html` (open with `#2.5` to freeze it 2.5 seconds in; it loops every 7 seconds only so it can be watched). Clip: `first-run-animated.mp4`. Made by `animated()` in `docs/tools/make_first_run_mockup.py`.

**Gaia: more reference screens (Tom, 2026-11-14).** Fifteen screenshots of Gaia in its dark look: Activity (home), History, Trends, Routine, Food, Account, Family and Settings. Not saved in the repo, as they show real names. What they show:
- **Home:** one wide Feed card, then a two-column grid of cards (Sleep, Diaper, Pump, Tummy time, Growth, Health, Baby firsts, Play, Bath), each a line icon with one yellow accent, a title, the last entry and a plus button. A dismissible news card at the top. A small dog peeking over a card. One line at the foot: "Everything here is shared with your family the moment it is logged."
- **Tab bar:** a floating pill with five tabs (Activity, History, Trends, Routine, Food); the chosen tab is ringed with a hand-drawn yellow scribble.
- **History:** a week strip of dates, Today or Last 24 h, filter chips, an empty state. **Trends:** Activity or Growth, a range menu, "Not enough logged yet".
- **Routine:** a shared plan for the day, with "Help me build a routine". **Food (beta):** meal plans and recipes, with a repeat of line-drawn foods behind the set-up card.
- **Account:** a striped, scalloped awning over the list. Import from Nara, Huckleberry or any CSV; export as CSV or a PDF for the doctor; "Connect your AI"; delete account.
- **Settings:** units as two-way pills (ml or oz), switches of their own design, and a paragraph under most settings saying why. Apple Health: the parent's own nursing and pumping go to their Health record; nothing about the baby does.
- **Worth taking:** a line pattern behind a card (it supports our outline repeats); the one-line sharing promise on Today; import from other trackers and a PDF for the doctor (check against ours); Apple Health for the parent's own feeding, which is a real use of Health that needs nothing from a monitor.
- **Not for us:** faces on objects (moon, star, bowl), which our brand rules out; an account and sign-in; em dashes and long paragraphs of explanation (one runs off the screen); nine cards and five tabs on the home screen.

**Gaia: a second batch of reference screens (Tom, 2026-11-14).** Sixteen more: the foot of Settings, the privacy policy on its website, Language, Import, Export, "Connect your AI", Report a problem, the share sheet, the review prompt and two App Store screenshots. Not saved in the repo (real names and contacts). What they show, against what Puggle has today (checked in the code):

| | Gaia | Puggle today |
|---|---|---|
| Import | Nara, Huckleberry (recognised) and any CSV, with columns shown to correct before anything is written; safe to run twice | One source: the "Baby Tracker" app's CSV export. A preview, a backup first, undo, and repeats are skipped |
| Export | CSV of the whole log; a PDF for the doctor over 7, 14 or 30 days with feeds, sleep, nappies by day, growth with WHO percentiles, medicines and temperatures | Export exists; a summary PDF exists (`SummaryView.swift`). Not checked: whether it has a choice of days or percentiles |
| Report a problem | An email with the version, device and the last few screens opened | An email with version, iOS and device. No recent activity |
| Languages | Eight | English only |
| Connect an AI | A read-only connection (MCP) so an AI app can answer from the log | None. It needs a server and an account, which Puggle does not have |
| Privacy | A policy on a website; an account with email and password; optional analytics and marketing email | No account, no analytics, nothing leaves iCloud |
| App Store | A headline over a phone, with a small line drawing: "Who fed her last? Everyone knows." | Not made yet |

Worth taking: import from the trackers people are most likely leaving (Huckleberry, Nara), and a column-matching step for any CSV; a choice of 7, 14 or 30 days on the doctor's PDF; the last few screens in a problem report; App Store screenshots as one plain claim over one screen. Not for us: an account, analytics, marketing email. The AI connection is interesting but only possible with a server.

**Gaia: a third batch of reference screens (Tom, 2026-11-14).** Fourteen more: five App Store screenshots, two reviews, and the Food section (recipes, a recipe, allergen history, Learn). Not saved in the repo.
- **App Store screenshots:** a two-line claim, a small line drawing, then one screen in a phone frame, on alternating pale and dark green cards. The claims: "Her first foods, week by week." "Her own rhythm. Her next nap." "The 3am shift, remembered." "Her progress, from day one." "Bring your history. Keep every entry." One feature each.
- **Features shown that Puggle lacks:** a nap prediction (today's window from recent wake windows, with "Did this timing feel right? Earlier, About right, Later"); a growth chart with WHO percentile bands and "not targets" beside it; History as a day's totals by kind (bottles 3, 450 ml) where ours lists entries.
- **Reviews:** one says they left Nara when it went behind a paywall and found Huckleberry too busy and pushy about paid features. That is the opening for a calm, free, family tracker, and it confirms Nara and Huckleberry as the two imports to add first.
- **Food:** recipe collections, a recipe page (age, iron-rich, freezes well, makes, keeps, allergens, ingredients, method, "Log as eaten", "Add to plan", "Add to freezer"), an allergen history, and guides (gagging and choking, combining foods, batch cooking, stopping breastfeeding). Photos are labelled "AI-generated serving examples", and every page says "Draft, awaiting review by a registered dietitian".
- **Worth taking:** the App Store format; growth percentiles shown as reference bands with "not targets"; a day's totals at the top of History; an allergen log that only records what was tried and any reaction ("can't tell whether she is allergic").
- **Caution:** recipes and feeding guidance are health content. Gaia has shipped them unreviewed, with a disclaimer. Puggle's rule is plainest of all for health, never advice; anything like this would wait for the GP review already on our list, or link to official sources. A nap prediction is also a judgement about a child, so it would need the same care and wording ("due", never "late").

**First run, rebuilt (2026-11-14, built).** The flow in the app now follows the mock-ups.
- **Pages about the app, before any question** (`OnboardingStep.pages`): Log the day, Every child, Share the day (left out of a build without iCloud), Look back, Private. Each is a `FirstRunPage`: a field of repeat pattern with a piece of the app on it, a full-width progress bar, a two-line SF Rounded heading broken by hand, a line or two of text with its last words kept together, and the button. Back and Skip are pills in the top corners, over the pattern.
- **The pieces act out their headings once** (`FirstRunPages.swift`: `LogPiece`, `KidsPiece`, `SharePiece`, `WeekPiece`, `PrivatePiece`), driven by one clock per page (`PageClock`), with `TapDot` showing each finger tap. The bottle's plus and minus are real and can be tried. With Reduce Motion each shows its finished state.
- **Repeat patterns in the app** (`Design/RepeatPatterns.swift`): `PatternTile` (mix, pills, bloom, comb, sparkle, check, scales), `PatternColour` (eight soft fields, each with a dark version) and `PatternField`, which tiles one picture per pattern and drifts it about six points a second. It rests while a page's piece is acting, with Reduce Motion, and in the night look.
- **Setup on the same skeleton:** a short band of pattern, then the question. "Who's logging on this iPhone?" on Check; the child form under Scales in the colour chosen for that child, changing as it is picked; "Anyone else to add?"; "Who else looks after them?". Joining and "Welcome back" use it too.
- **Example names** are the sample family's: Bea and Ollie, with Nan, Alex and Robin.
- **For checking:** `-debugFirstRun 1 -debugFirstRunAll 1 -firstRunStep 3` (3 to 7 are the five pages, 8 the first setup page). Pictures: `docs/previews/onboarding/built-light.png`, `built-dark.png`, `built-setup-light.png`, `built-setup-dark.png`; the logging page playing: `built-logging.mp4`.
- **Not done:** a way to replay first run from Help; the welcome and the family heap are unchanged; the outline patterns (faces, things) are not in the app; larger text sizes drop the piece and were not checked on screen.

**App Store screenshots (2026-11-14, mock-up).** Five cards in `docs/previews/app-store/` (`index.html`, `app-store.png`), each a two-line claim in SF Rounded, one line under it, and one real screen in a phone frame, on that page's repeat pattern: Every child on one screen (Today), Log the day in a tap or two (the bottle sheet), Share the day with your family (History, with who logged what), Look back over the week (Insights), Easy on the eyes at night (Today in the bedroom). The claims are the first-run headings. To fix before real ones: the screens show the yellow "Sample family" banner; the night card is the indoor bedroom in the light look, not the night look; sizes are not yet Apple's (1290 by 2796).

**Activity icons: a refinement pass (Tom, 2026-11-14, redrawn, not yet in the app).** Tom asked for a solid pass on the icon library, guided by how SF Symbols, Fluent System Icons and Lucide are made.
- **What those say** (read 14 November 2026). *Lucide:* a 24 canvas with a 1-point safe zone; one 2-point centred stroke; round caps and joins; corner radius 2 on shapes 8 or more across and 1 on smaller; at least 2 points between elements, inside shapes too; the same visual weight as a plain circle or square (blur test); low density; simple curves; everything on the pixel grid; reuse shapes across related icons. *Fluent:* two themes, Regular for finding things and Filled for the chosen state or small sizes; named for the object, not the job (shield, not security); modifiers filled and bottom right; one solid colour at most, used with care; draw for a size, do not just scale. *SF Symbols:* nine weights and three scales so a symbol matches the text beside it; designed at regular weight first; margins and optical centring to the text's cap height; layers for one-colour, hierarchical and palette rendering.
- **What was wrong with ours** (`docs/previews/icons/audit.png`): a 1.4 line that thins out at 17 points; details closer than a line apart (bottle ticks, ruler marks, pram spokes, three bubbles); uneven sizes (weight and tummy time small, nappy short); points off the grid (7.7, 16.3); a second colour on tummy time; accents that were sometimes a fill, sometimes a dot, sometimes a line; the medicine dropper looked like the feeding bottle.
- **Puggle's rules now** (in `docs/tools/make_icons.py`): a 24 canvas with nothing nearer the edge than 1 point; one 1.5 line, centred, round caps and joins; every point on the half-point grid; keylines (20 circle, 18 square, 16 by 20 upright, 20 by 16 landscape); at least 1.5 clear between lines, or the detail goes; one Wattle accent, a single filled shape; five strokes at most; named for the object; no faces.
- **All twenty redrawn** to those rules: `docs/previews/icons/refined.png` (was and now, on the grid, at 32, 24 and 17 points, in light and dark), SVGs in `docs/previews/icons/after/`. Changes of idea, not only of drawing: medicine is a capsule, not a dropper bottle; milestone is one filled star. `python3 docs/tools/make_icons.py --install` writes them into the app's asset catalogue (light, dark and plain); not run yet.
- **Not done:** a Filled theme for chosen states; the tab bar and other system symbols, which are SF Symbols and unchanged; the weakest redraws are pump and potty.

**Activity icons, second pass (Tom, 2026-11-14, redrawn, not yet in the app).** Tom wanted the first pass refined further: the nappy read as pants; "we shouldn't shy away from having a breast for breast feeding"; and he shared icon ideas ChatGPT had drawn (fuller, sticker-like shapes; a bottle with teat, collar and measure marks; a padded nappy with tabs; poo and wee; a potty with a seat ring; a 2-point line, 20 by 20 safe area; colour, one-colour and selected states). Not to be copied, but to inform. The first pass is kept (`docs/tools/make_icons_v1.py`, `docs/previews/icons/v1/`, `refined-v1.png`).
- **Taken from them:** a 2-point line; fuller, rounder shapes drawn as the whole object; a second fill (Sky) beside Wattle; the padded nappy with tabs; a breast; poo and wee as icons of their own; sparkles for a milestone.
- **Not taken:** blue-violet outlines (ours stay Ink); cream body fills (invisible on our paper cards); three measure marks (they close up at 24 points); faces on the breastfeeding parent.
- **The rules now** (`docs/tools/make_icons.py`): 24 canvas, nothing within 1 point of the edge; one 2-point line with round ends; half-point grid; keylines; at least 1 point clear between lines; Wattle for what the icon is about and Sky for what holds it, Ink for a small solid mark; no faces.
- **Nappy:** one closed, padded shape; flat tabs sitting right above large leg openings, all inside the outline. **Breastfeed:** a breast, in Shell with a darker areola (a brand colour, though one skin tone; a version with no skin colour is on the sheet and reads worse). **Potty:** a small backrest, a wide seat with its opening, a Sky base. **Pump:** a cupped funnel tilted up on its bottle. **Milestone:** a four-point sparkle, the brand's star. **Growth:** a height chart alone. **New:** poo (the one icon with a colour of its own, `#C99668`) and wee, for the kinds of nappy; not wired to anything.
- Sheet: `docs/previews/icons/refined.png` (each on the grid; in the app, first pass and now at 32, 24 and 17 points; in light, dark and one colour; on Today's tiles and a History list). SVGs in `docs/previews/icons/v2/`. `--install` writes them into the app; not run. **A further pass (Tom: "the crescent moon could be slightly thicker"):** the moon's inner curve is shallower, so the crescent is thick through the middle; the scale is now seen from above with its dial, as the tray on a stand read as an hourglass; the bottle's teat has a bigger tip, so its colour shows.

### Breastfeeding icon: a choice of five (14 November 2026)

Tom: the app may be offered anywhere, so breastfeeding needs a few ways to be drawn. Five are drawn, none in the app yet: Breast (as now), Breast and baby (latched, nipple covered), Parent and baby (no breast, no skin colour), Milk drop (a baby tucked inside a drop) and Heart. The two with a breast come in five skin tones. Sheet: `docs/previews/icons/breastfeeding.png`; files in `docs/previews/icons/v2/breastfeeding/`; drawn by `docs/tools/make_icons.py`. Still to decide: which is the default, and where the choice lives (suggested: Settings, with the icon and the tone together). All five are kept.

Second pass on the breastfeeding choices (14 November 2026), after Tom: "we lost way too much detail". The four with a baby are now drawn on a 32 canvas with the same 2 point line, which leaves room for a closed eye (a 1.5 point line, the one place it is used), the parent's fringe and bun, a little areola, and a blanket with a fold. So "no faces" no longer holds for these four. On a tile their line is a quarter lighter than the other icons'.

Third pass on the breastfeeding choices (14 November 2026). The baby in Milk drop and Heart is now a head with a swaddled body. Each of the four has two drawings: a detailed one for tiles (32 canvas, 2.2 line) and a simpler one for lists (no eye or fold, 2.67 line, the set's weight). In Breast and baby the head overlaps the breast. Tried and taken out: a nose on the outline (read as a beak on the baby and a jaw on the parent) and an ear (crowded the eye). Which way a head faces is shown by where the eye sits. Files: `docs/previews/icons/v2/breastfeeding/`, with `-small` for the list drawings.

Fourth pass on the breastfeeding choices (14 November 2026): the parent has an arm around the baby and a smaller bun; one colour rule (skin where there is a breast, otherwise the baby's head is Wattle); the breast alone is redrawn on the 32 canvas; Heart is a baby resting in a cupped hand. The sheet also shows each on a Today tile at 34 points (as now) and at 40. Suggested and not yet decided: three drawings per icon across the whole library (small for lists on 24, regular for tiles on 32, large on 48 for places an icon stands alone), and tile icons at 40 points.

### Icons: three drawings of each (14 November 2026)

Tom agreed to three sizes for every icon. Small (24 canvas, 2 point line) is the second-pass drawing, for lists and anything under 24 points. Regular (the proportions of a 32 canvas, a 2.2 line, details in a 1.5 line) is for tiles, and every icon now has one with a little more detail: `DETAIL` in `docs/tools/make_icons.py`, files in `docs/previews/icons/v2/regular/`, sheet `docs/previews/icons/sizes.png`. Large (48 canvas, for where an icon stands alone) is not drawn yet. Tile icons in the app are already 40 points (`Tiles.swift`); the earlier mock sheets showed 34 by mistake. None of the new drawings is in the app.

Icons, the large drawing (14 November 2026). All 22 icons now have the third size: a 48 canvas, a 2.4 line, details in 1.6, drawn by `docs/tools/make_icons_large.py` into `docs/previews/icons/v2/large/`, sheet `docs/previews/icons/large.png`. Seven are drawn afresh after two more sheets of ChatGPT's ideas that Tom sent: potty (backrest, seat ring, feet), poo (a sleepy face), weight (a baby scale with a tray), solids (a mound, a spoon, steam), bath (foam and a duck), pump (funnel, lever, bottle) and tummy time (a baby with a foot kicked up). The rest are the regular drawing at twice the size. Faces are allowed at this size. Closed eyes in all sizes are now half circles, wider than before: short ones drew as beans. Not in the app.

Potty, large drawing (14 November 2026): Tom asked for the raised bit at the front. The splash guard is drawn as part of the body, coming up in front of the seat ring and its opening. Two earlier tries (a bump inside the ring, then a bump breaking the ring's front edge) read as a ball sitting in the seat. Close-up: `docs/previews/icons/potty-guard.png`. The regular and small potty do not have it yet.

Potty guard, again (14 November 2026). Tom: the raised bit is part of the blue, not the yellow. It is now the blue body itself swelling up into the seat, with no edges of its own, so the yellow seat is a horseshoe open at the front.

Icon colour, under question (14 November 2026). Tom is not sure the icons need two colours. `docs/previews/icons/tones.png` shows the regular set four ways: two colours (as now), yellow only, yellow in two strengths, and line only. Claude's suggestion: yellow only, with the yellow part re-chosen for the icons that lose all their colour (nappy, potty, bath, note). Not decided. Coverage check the same day: all 13 kinds the app logs have an icon, and so do the 7 other assets in the catalogue; poo and wee are extra.

Icon colour from the child's colour (14 November 2026). Tom's idea: the fill in an icon takes the colour chosen for that child. Mocked in `docs/previews/icons/child-colour.png`: one fill per icon, in the child's colour, with Wattle for anything that is not one child's (pump, first run, Settings). Claude's view: yes, and it needs each icon to have one good-sized fill, since the child colours are pale and several icons (nappy, potty, bath) have no fill at all once the blue goes. Not decided.

Play, large drawing (14 November 2026): Tom asked for the blocks to follow ChatGPT's sheet. They now have depth: each shows its front, top and right side, the top block sits across the two below, and the faces carry a sparkle, a triangle and a circle. Close-up: `docs/previews/icons/play-blocks.png`. The regular and small drawings are still flat. Also settled the same day: wee stays yellow whatever the child's colour, like brown for poo and skin for the breast.

### Icon colour: yellow by default, yours to change (14 November 2026)

Tom decided: yellow is the default; Settings can change it to a colour of your choosing, or to each child's colour; the fixed colours stay. Built:

- **One fill each.** The Sky fills are gone from all three sizes. The nappy's tabs, the potty's base and the bath's tub, which had no yellow, carry the fill. Fixed colours: skin on the breast, brown for poo, yellow for wee.
- **In the app.** `make_icons.py --install` now writes each icon as parts the app tints (`icon-x-line`, `icon-x-fill`, `icon-x-fixed`), for the small drawing and the regular one (`-reg`, used from 32 points up). `ActivityIcon` puts them together. So the second-pass drawings are now in the app. The large drawings are not: nothing in the app shows an icon above 44 points yet.
- **The setting.** Settings, Appearance and night, Icons: Yellow, Your own colour (the iOS colour picker) or Each child's colour, with a row of icons that shows the choice. Keys `iconColour` and `iconColourOwn`.
- **Each child's colour** applies where an icon belongs to one child: a Today tile when one child uses it, and the log buttons in a child's panel. Anything else stays yellow, and so does pumping, which is the parent's. Lists keep the one-colour drawing.
- For checking: `-debugAppearance 1` opens the screen; `-iconColour own -iconColourOwn <number>` or `-iconColour child` sets the choice.
- Not done: the breastfeeding choices still use blue for blankets and are not in the app; poo and wee are not in the app; the seven new large designs have not been carried down to the smaller sizes.

Potty, all three sizes (14 November 2026). Tom pointed out the full sheets still showed the potty without its raised front. The small and regular drawings now have it too: the front of the seat swells up in the middle, in front of the opening. The large one's yellow seat no longer shows under the raised bit. Sheets re-rendered: `sizes.png`, `large.png`, `refined.png`. The app has the new small and regular potty.

Tooth and poo, large (14 November 2026): Tom took the eyes and smile off both. The tooth is back to its highlight and yellow dot; the poo keeps its folds and shine marks. The only faces left in the library are closed eyes on babies and parents.

Breast and tooth (14 November 2026). Tom: the yellow dot on the tooth could be a cavity, and should the breast be flat down the left? Both changed, in every size and in the app. The tooth's dot is now a four-point sparkle. The breast is drawn in profile: flat down the left where it meets the chest, a gentle slope above, full below and to the right. The teardrop it replaces is kept in git (commit 15cbaad, `BREAST` in `docs/tools/make_icons.py`), as every unchosen variant is. Close-up: `docs/previews/icons/breast-tooth.png`.

Second pass on four icons (14 November 2026), after Tom: the flat-sided breast lost its shape, and ChatGPT's bath, solids and scales were better than ours.

- **Breast:** the teardrop of the second pass again, with only its left side made flat. The wedge with a sloped top is in git (commit 3cea5e2).
- **Solids:** a deeper bowl with a rim and a foot, a lumpier mound, a spoon with a drawn handle standing in it, and steam in the main line.
- **Bath:** round feet, no ripple, and a bigger duck that faces the foam, with a beak, an eye, a wing and a tail.
- **Weight:** the tray has its dish underneath, then a short neck, and a taller base with a bigger dial and three marks.
- **All sizes:** the small and regular drawings of these three now follow the same designs (a bowl with a mound and spoon; a tub with a bubble and a duck's head; a tray, base and dial), so they are in the app too. Before this they were the older designs: a plain bowl, a tub with bubbles, a scale seen from above.

Close-up: `docs/previews/icons/second-pass-four.png`. Still to carry down to the smaller sizes: pump, tummy time, play and poo.

The last four carried down, and a second pass on two (14 November 2026).

- **Carried down** to the small and regular sizes, and so into the app: the pump has its lever; play is three stacked blocks, with depth and a shape on each at the regular size; poo has shine at the regular size. Every icon is now one design at three levels of detail.
- **Tummy time, second pass.** Tom: the ear was odd, and only the hair should be yellow. The ear is gone, the face is plain, and the hair above the fringe carries the fill. The body is the baby's back and bottom as two soft humps with an arm out in front; the kicked-up foot read as a tail and is in git (commit 14a14f2).
- **Pump, second pass.** The lever is a handle with its own thickness, arcing over and hanging down, and the bottle has three marks.

Close-up: `docs/previews/icons/second-pass-four-more.png`. 51 tests pass.

Tummy time's eye (14 November 2026). Tom asked for one eye, as in the reference, then said the closed-eye arc looked like a mouth. It is now a dot, high under the fringe, in all three sizes. Close-up: `docs/previews/icons/tummy-time-eye.png`.

### App icon: Puggle's current face (14 November 2026)

The icon was still the old face. It is now made from her rig by `app/tools/make_app_icon.py`, so it has the lick of hair, eyebrows, oval cheeks, the smaller bill and the flower clip. It stays an Icon Composer document (`app/Puggle/Resources/AppIcon.icon`), in four layers front to back (clip, features, bill, head) so each part still reads in the clear and tinted looks.

- Glass is on for the head, bill and clip, and off for the eyes, brows and cheeks.
- Dark has its own ground (deep brown) and a darker outline.
- Two things learned about Icon Composer: it cuts an outline off at the edge of its shape unless the layer is made as big as the picture (two near-invisible specks in the corners do this); and a property that changes with the look is a list with the plain value first (`fill-specializations`, `image-name-specializations`), not a plain key plus a list.
- Rendered with Apple's `ictool` (Icon Composer 1.5, in Xcode 26.5), which draws iOS 26's glass. iOS 27's sharper rendering cannot be previewed here.
- Tom asked whether the ground should be Puggle's blue. `docs/previews/app-icon/four-versions.png` shows yellow with glass, yellow flat, Sky and her dress blue, each in all six looks. The app has yellow with glass until he decides; `--ground sky` or `--ground blue` writes the others, and `--flat` turns the glass off.

App icon, softer lines (14 November 2026). Tom: keep yellow, but the lines look too dark. The icon was using the rig's ink outline; the app itself draws Puggle with the coloured outline (each shape edged in a darker shade of itself, about three-quarters as heavy). The icon now does the same, in light and dark, so it matches her in the app. `--line ink` in `app/tools/make_app_icon.py` gives the old outline. Comparison, with glass and flat, in all six looks: `docs/previews/app-icon/softer-lines.png`. The app has the glass version; flat (`--flat`) is not chosen yet.

App icon, settled (14 November 2026): Tom chose yellow and flat. No glass on Puggle: it washed her outline out and gave the bill a raised rim. The app has this icon; `docs/previews/app-icon/` holds its six looks as Apple's tool draws them. The glass version is kept behind `--glass` in `app/tools/make_app_icon.py`, and the blue grounds behind `--ground sky` and `--ground blue`.

### A sweep for old artwork (14 November 2026)

Tom found the lock screen still had Puggle's old face, and asked for a pass through the whole app for anything else like it.

**Fixed.** `PuggleMark` (lock screen, splash, launch screen, Help), `PuggleFace` (on stamps) and `PuggleStill` (her standing: the empty Today, milestones, the play pad) were all the old drawing. `app/tools/make_app_icon.py` now writes all three from her rig, with the app icon, so they cannot drift again. Two stale lines in `app/README.md` are corrected.

**Found, not changed:**
- Widgets, the Live Activity and the Dynamic Island use Apple's symbols (a moon, a heart, a clock), not Puggle's icons. The widget target has no artwork of its own.
- Two menus use Apple's symbols for activities: the choice on a Today tile with more than one kind (Feeding), and the kind filter in History.
- Stamps that carry an activity icon (first food, first steps, the potty) use the flat yellow drawing, so they ignore the icon colour setting.
- The launch picture iOS shows before the app starts is cached by the system. In the simulator it kept the old face after a reinstall. A phone may need a restart to pick up the new one.
- The mark sits a little higher on the launch picture than on the app's own splash, so it moves slightly as one hands over to the other.
- The icon and mark show Puggle with her eyebrows. In the app she only has them when she is feeling something; her resting face has none. Tom approved the icon with them, so they stay until he says otherwise.
- The breastfeeding choices, poo and wee, and the large icon drawings are still outside the app.

Icons in dark (14 November 2026). Tom, from the TestFlight build: the icon lines look too thick in dark mode. A pale line on a dark ground reads heavier than a dark line of the same width, and the breast's skin was nearly the line's colour, so it had no visible outline. Each tinted icon now has a second drawing for dark with the line a fifth thinner (`DARK_LINE` in `docs/tools/make_icons.py`), and fixed colours a fifth dimmer (`DARK_FIXED`). The catalogue picks the drawing by appearance. The one-colour list icons are unchanged. Comparison: `docs/previews/icons/in-app/dark-lines.png`.

Icons finished in three more places (14 November 2026), from the sweep:

- **Stamps.** A stamp that carries an activity icon (first food, first steps, the potty) now draws it with `ActivityIcon`, so it takes the icon colour from Settings. `docs/previews/icons/in-app/stamp-icon-colour.png`.
- **Menus.** The choice on a Today tile with more than one kind, and the kind filter in History, show Puggle's one-colour icons in place of Apple's symbols.
- **Widgets, the Live Activity and the Dynamic Island.** The widget target has its own small catalogue (`app/PuggleWidgets/Glyphs.xcassets`: sleep, bottle, nappy), written by `make_icons.py --install`, and a `Glyph` view. Sleep shows Puggle's moon, a feed shows the bottle (it was a heart), and the nappy button shows the nappy (it was a drop).
- **Still Apple's symbols, on purpose:** the clock for a glance at the day, the sun on "Woke", the undo arrow, and the moon on the Control Centre button, which only accepts Apple's symbols.
- Checked: the app and widgets build, 51 tests pass, and a stamp was seen in the simulator in yellow and in a chosen colour. Not seen: the two menus, the widgets, the Live Activity and the Dynamic Island.

Invite failures say why, in test builds (14 November 2026). Tom, on the first TestFlight build: "It says I can't share a link." The app had two places where an invite could fail and neither kept what iCloud said: starting the invite showed one fixed sentence, and the sharing sheet failing to save showed nothing. Both now show a message, and in builds from Xcode or TestFlight it ends with iCloud's own error (`TesterDetail` in `PeopleViews.swift`). App Store builds do not show it. Suspected cause, not confirmed: Tom's phone moved from an Xcode build (iCloud Development) to TestFlight (Production) with the same local data, so the family or an earlier invite may still be tied to the Development side.

Sharing fails on the first TestFlight build (14 November 2026). Tom's screenshot: Apple's sharing sheet opens, shows him as owner, then "Couldn't Add People. A link couldn't be created for you to share. Couldn't communicate with a helper application." This is Apple's sheet failing, not Puggle's message, and it is the first time sharing has been tried on a real phone. Cause not known. Two suspects: the phone's data moved from an Xcode build (iCloud Development) to TestFlight (Production), so the family or its invite may not exist on the Production side; or the sheet itself, which has had bugs of this kind.

To tell them apart, test builds now have Settings, iCloud check (`CloudCheckView.swift`): the account, whether Core Data believes the family has been sent, the zones iCloud really holds, and whether the invite on the phone exists in iCloud. It changes nothing and reports counts and codes only, with a button to copy it.

Sharing failure, found (14 November 2026). Tom's iCloud check from build 2: his iCloud holds the family's zone, and the phone holds an invite with a link, but iCloud has no such invite ("Record not found" for `cloudkit.zoneshare`). The invite was made while the phone ran an Xcode build, on iCloud's Development side. The TestFlight build uses Production, where Core Data made the zone again but not the invite, because the phone believed it already existed. Apple's sharing sheet then failed trying to change an invite that was not there.

Fix: before showing the sheet, `Persistence.share` asks iCloud for the invite the phone holds. If iCloud has none, it makes a new invite for the same zone and gives Core Data the new one. The family's entries stay where they are; people are invited afresh. Offline, it carries on as before. The iCloud check also counts the family's records in iCloud, by kind, to confirm the entries themselves reached Production. Not yet run on a phone.

### Import with two parents (15 November 2026)

Both parents may bring entries in from the same app, so three things were looked at.

- **Built: one copy after sync.** If two phones import the same file before they have caught up with each other, iCloud keeps both copies of each entry. When entries arrive, copies with the same identity are merged to one. Every phone keeps the same one (the copy made first), so two phones never remove each other's.
- **Built: deleted stays deleted.** Deleting an imported entry leaves an empty mark with only its identity, in the family's iCloud. Importing the same file again, on any phone, leaves that row out and says how many. Bringing the entry back from Recently deleted removes the mark, and so does undoing the import. No change to the iCloud schema was needed: the mark is an entry with no child, no family and the kind "removed".
- **Mocked up, not built:** holding the import while someone who has just joined is still catching up, and showing sleeps and feeds in the file that overlap ones already here, left out unless chosen. See `docs/previews/import/overlaps.png` (`docs/tools/make_import_mockup.py`).
- **Who can import:** parents only. Someone who joins starts as a Helper unless the invite said Parent; whoever holds the family changes this on the person's row in Family.
- **Not tested:** the merge and the marks have unit tests but have not run across two phones.
- **Built later the same day: the three screens from the mock-up.** While someone in another person's family is still receiving entries from iCloud, the import screen says "Catching up with the family" and holds the file button, with "Import now" to go ahead anyway. It never holds for whoever holds the family, with iCloud off, or in the sample family. Once a file is read, sleeps and breastfeeds whose times overlap one already here for the same child, and bottles within ten minutes of one, are counted under "Possibly already here" and left out unless "Bring them in" is chosen. "Look at the N" lists each pair with "Leave out" or "Keep both". The entry already here is never changed. For screenshots: `-uitest 1 -hasOnboarded YES -debugImport overlaps` (or `list`, `catching`).
- **Not tested on the built screens:** two phones; the catching-up signal on a real joined phone (it listens for iCloud finishing a fetch of the shared family, which cannot run in the simulator); choosing a real file with overlaps. The finder has unit tests and the three screens were checked in the simulator in light and dark.

### Brand book brought up to date (15 November 2026)

The brand book is the design canvas's "Characters" and "Brand and world" pages; the PDF in `docs/brand/` is an export of them from 14 November and is now behind the canvas.

- **Model sheet:** rebuilt from the app's current file of her parts. Front only (the three-quarter, side and back views are gone), the lick of hair, pyjamas, the rain hat, and the moves Oh!, hug, read and bubbles.
- **Hair board:** retitled, with a note that Puggle has a lick of hair and the rest of the cast do not.
- **New board, App icon:** light and dark, how clear and tinted are made, small sizes.
- **New board, Activity icons:** the 22 drawings, the three sizes, the colour rule (Wattle by default, a colour of your own, the child's colour, fixed colours), dark, and the breastfeeding choices. The older icon board on the App page is marked superseded.
- **Still behind the app:** boards drawn by the older scripts show Puggle without her lick of hair (expressions, hands, family, the cast line-up, glasses, scenes, wallpapers, books, logos, merchandise, onboarding). "Puggle: three additions" and the motion boards still show the side-on walk. The palette board does not show the icon colour setting.
- Sources: `design/canvas/gen/model2.py`, `brand15.py`, `rig.py` (now reads the rig's newer conditions).

### Wordmark B1 (15 November 2026)

**Decided (Tom, 15 November): v4 is the wordmark.** It has its own board on the brand page of the canvas and opens section 1 of the brand book PDF, which also carries it on the cover. Not done: the app (splash and Help still use the earlier wordmark), the logo variant and clothing boards, and a proof on a label or a cover. The mark that goes with it is still open.

Tom drew a rounded lowercase wordmark with ChatGPT ("B1", v3). A v4 with four fixes is beside it in `docs/previews/logo/wordmark-B1/` (`docs/tools/make_wordmark_v4.py`): each g has a plain round-topped stem in place of a bulge that tapered back in; the e has a taller counter with round corners and a bar of one thickness, keeping its slant; the g tails end lower and further in, so they no longer crowd the bowl; and the gaps are even (7 units between a straight side and a round one, 11 between g and l). The p, u and l are not redrawn. The colour is the palette's Ink.
