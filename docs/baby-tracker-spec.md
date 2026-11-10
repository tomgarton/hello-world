# Baby Tracking App — Plan & Spec (Draft 0.3)

_Status: first draft for discussion. Working title: **TBD** (see §11)._
_Last updated: 2026-11-10._

**How to read this:** §1–3 are the market assessment and where the opening is. §4–7 are the product. §8–10 are how we build and run it. §12 lists the decisions we need to make together.

Claims marked **[verify]** come from third-party roundups or from memory, not from a primary source, and must be checked before we rely on them.

---

## 0. Working assumptions (agreed 2026-11-10)

- **Team:** Tom (product design) and Claude (engineering). No hired engineers.
- **Shape:** an indie product born from Tom's own two-kid friction, in the Apollo/Crouton mould. Start small, ship, grow from use.
- **Money:** free app with a tip jar, as Apollo did, and a one-off Pro unlock for a handful of extras later. No subscription planned.
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
| **Baby Tracker (Nighp)** | Fast, comprehensive logging; long-time category staple. | Dated UI, ads in the free tier **[verify]**. | Free with paid upgrade **[verify]**. |
| **Nara Baby** | Clean, free, multi-child and caregiver sync. Often named the best free option. | Shallow insights, few platform integrations **[verify]**. | Free **[verify business model]**. |
| **Glow Baby** | Multi-user sync, community. | Sits inside a fertility/pregnancy bundle; upsell-heavy **[verify]**. | Sources conflict: $4.99 one-time vs $59.99/yr bundle. |
| **Baby Daybook / BabyConnect** | Breadth of things you can log; cross-platform. | Utilitarian design **[verify]**. | Freemium **[verify]**. |
| **Napper** | Sleep schedules, warmer design. | Sleep only **[verify]**. | Subscription **[verify]**. |
| **Nanit** | Camera-driven sleep analytics, polished design. | Needs the hardware. Analytics, video history and milestone features need an Insights plan after the trial. | About $120/yr and $300/yr tiers (Nanit support page). |
| **Piyolog (Japan)** | Dominant in Japan; voice logging, daily summary **[verify]**. | Japan-centric. | Freemium **[verify]**. |
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

_Your message cut off at "especially if someone was to hav…". I have assumed the end was "have twins" or "have a second child while the first is still being tracked". Tell me if you meant something else._

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

Principle: **never charge for the family's own data, or per child, or per caregiver.** Quality first; money follows goodwill.

Modelled on Apollo, which combined a free app, a tip jar and a one-off Pro unlock (it added a subscription later, for features with ongoing server costs).

| Layer | Contents | When |
|---|---|---|
| **Free** | All tracking, unlimited children and caregivers, sync, full history, export, growth charts, widgets, Live Activities | Launch |
| **Tip jar** | Three or four tip sizes. A thank-you only: a supporter badge and perhaps an extra app icon | Launch |
| **Pro (one-off)** | Extras, not essentials: themes and icon set, paediatrician PDF report, nap/feed predictions, illustrated milestone cards | After beta, once we know what people value |
| Subscription | Only if we add something that costs us money every month (e.g. a cross-platform backend or photo hosting) | Not planned |

Why this works here: with CloudKit our running costs are the Apple Developer fee ($99/yr), a domain and the Vercel free tier. Apollo was ended by a third party's API bill; we have no equivalent dependency.

What to expect: tip jars alone usually bring in little. They will cover running costs, but probably not illustration, which is the one real spend. The Pro unlock is what would pay that back. Prices to test later: tips around $1.99 / $4.99 / $9.99, Pro around $14.99–24.99 one-off. These are starting numbers, not researched price points.

## 10. Design, brand and operations

### Illustration

- A consistent illustrated world (characters for each stage, empty states, milestone cards, monthly recap art) is what makes the app feel premium and is something users will pay for.
- **Commission one illustrator** for a system, not a pack of stock art: about 40–60 spot illustrations, a set of animated moments (Rive or Lottie), app icon variants. Budget is a real line item; get quotes early.
- Illustrations must be inclusive across skin tones, family structures and feeding choices.

### Brand

- Tone: calm, warm, non-judgemental about feeding and sleep choices, never guilt-inducing.
- Name must work across US/UK/EU/JP/AU/NZ, have an available `.com` or `.app`, and clear trademark search in classes 9 and 42.

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
| 3. Household build | Feeds, sleep, nappies, two or more children, concurrent timers, partner sharing. Installed on Tom's family's phones via TestFlight. No paywall, no polish |
| 4. Live with it | Two to four weeks of real use. Fix what grates. This is where the product gets good |
| 5. Native surfaces | Live Activities, widgets, Siri/Shortcuts, night mode |
| 6. Growth and stages | Measurements with WHO charts, milestones, solids, potty training |
| 7. Beta | 20–50 outside families (include twin parents). Add the tip jar. Decide what, if anything, goes in Pro. Illustration commissioned |
| 8. Launch | App Store, English-speaking regions first. Website live |
| Later | Apple Watch, region packs for UK/AU/NZ/US schedules, Japan and EU, Android |

I have left out durations. They depend on how many hours a week Tom has, and I would rather set them after step 3 shows our real pace.

## 12. Decisions

**Settled**
- Team is Tom and Claude; indie scale; start small.
- Free app with a tip jar; one-off Pro unlock later; no subscription.
- iOS first.

**Open**
1. **Is your household all-Apple?** Partner and anyone else who would log. This decides CloudKit versus a cross-platform backend (§8.1).
2. **Do you have a Mac with Xcode and an Apple Developer account?** Needed before step 3.
3. **How did your sentence end?** "…especially if someone was to hav…"
4. **Which apps did you try, and what specifically annoyed you?** This is step 1.
5. **Is a one-off Pro unlock alongside the tip jar acceptable**, or do you want tips only?
6. **Illustration:** any illustrators or styles you already like? As a designer you may want to set the direction yourself.
7. **Name.** Candidates welcome; I will check domains and obvious conflicts.

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
