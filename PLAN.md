# NicFree — implementation plan

> **Superseded for v1:** scope and dates now live in `LAUNCH.md`. This file stays the full
> product plan. The product was renamed from Cairn to NicFree on 2026-10-22.

Engineering companion to `BLUEPRINT.md`, which holds the research and the positioning.
Visual direction is a separate published document; this file is what we build from.

---

## 1. What we are building

An iOS app for quitting vaping, whose hero number is cumulative lifetime days free and
cannot decrease, which never asks for a daily check in, and whose accumulated history
cannot be lost. Free core, one purchase for depth, no subscription, no accounts, no
servers, no third party code.

## 2. How it wins, in order

Ranked by how hard each is for a competitor to copy.

**1. The phone is the trigger, so the app must work without opening the phone.**
NCI lists scrolling on your phone as a primary vaping trigger. Every competitor
requires you to unlock, find the app and tap through, which means the intervention
lives inside the trigger. We ship a Control Centre control, an interactive widget
button, an Action Button intent, a Siri phrase and a Watch complication, all of which
start a craving timer without the phone being unlocked or the app being opened. This is
the strongest idea in the product and it needs a full rewrite for a cross platform
competitor to match.

**2. The cumulative number.** The hero cannot decrease, structurally. Several 2026
competitors claim shame free relapse handling but all of them still reset a streak and
keep consolation stats beside it. Nobody has moved the hero.

**3. No check in.** A day record exists only for days nicotine was used, so a free day
costs zero interactions and there is no blank state to feel guilty about. Enforced by
the schema, not by copy.

**4. Personal evidence instead of generic reassurance.** Every quit app says cravings
pass. We say: your cravings last four minutes and twelve seconds on average, and you
rode out ten of your last twelve. Their own data, which no competitor has for them.

**5. Durability as a feature.** Kwit's angriest reviews are lost stats after sync and
version migrations. Local first, additive migrations only, export in the free tier, no
account to orphan anything. Stated on the listing.

**6. Calm.** An app that celebrates loudly has nothing decent to say on a bad day.

## 3. Dependencies

**Zero third party packages.** Not a purity stance: it avoids supply chain risk, keeps
launch fast, removes third party privacy manifest and signature obligations, and lets
the listing claim data is never collected, which is rare in this category.

Apple frameworks only:

| Framework | Used for |
|---|---|
| SwiftUI | All UI |
| SwiftData | Persistence, CloudKit mirror later |
| Swift Charts | Insights and history charts |
| WidgetKit | Home Screen, Lock Screen, StandBy widgets |
| ActivityKit | Live Activity craving timer |
| AppIntents | Shortcuts, Siri, Action Button, Control Centre, interactive widgets |
| UserNotifications | Local milestone notifications only |
| StoreKit 2 | The single unlock purchase |
| CloudKit | Via SwiftData, as a mirror. Needs the paid account |
| os.Logger | Logging. Never `print` |

**Submission detail that bites people:** the app needs a `PrivacyInfo.xcprivacy`
declaring no tracking, and a required reason for `UserDefaults` access, which is
`CA92.1`. Missing it is an automatic rejection.

## 4. Architecture

Plain SwiftUI over SwiftData. Views read with `@Query` and mutate through
`modelContext`. No view model per screen. `@Observable` classes exist only where state
genuinely needs coordinating: the craving timer session and the purchase store.

Because the project uses file system synchronized groups, folder location determines
target membership. Creating subfolders is free and needs no Xcode bookkeeping.

```
NicFree/NicFree/
  App/            NicFreeApp, ModelContainer, root navigation
  Models/         Habit, DayRecord, CravingEvent
  Core/
    Stats/        QuitStats            (pure, tested)
    Insights/     InsightsEngine       (pure, tested)
    Copy/         Tone rules and banned word list
    Store/        PurchaseStore
    Notifications/
    Formatting/
  Design/         Colours, type scale, spacing, reusable components
  Features/
    Onboarding/ Home/ Craving/ Slip/ History/ Insights/ Settings/ Paywall/
  Resources/      Assets, Localizable.xcstrings, PrivacyInfo.xcprivacy
NicFreeWidgets/     widget extension target
NicFreeTests/
```

All derived numbers live in pure types with no framework dependency, so they are
testable without a store. That rule is why `QuitStats` already has tests.

## 5. Data model and migration policy

`Habit`, `DayRecord`, `CravingEvent` as written. Three rules that do not change:

1. **A `DayRecord` exists only for a day nicotine was used.** Absence means free.
2. **Migrations are additive only.** New optional properties, new models. Never a
   rename, a type change or a deletion that could drop a user's history. If a change
   cannot be made additively, we version the schema and migrate forward with a backup
   written first.
3. **Export before anything risky.** Any destructive user action offers an export.

## 6. Screens

| Screen | Job | Gating |
|---|---|---|
| **Onboarding** | Get to a working home screen in under a minute, no account, no paywall | Free |
| **Home** | One glance answer: how am I doing. Hero number, current run, longest run, saved. One large primary action | Free |
| **Craving** | Get through the next four minutes. Instant, full screen, no menu | Free |
| **Slip log** | Record a slip in two taps without shame. Coarse intensity, trigger, optional note | Free |
| **History** | Last seven days free. The year grid and full browsing are the paid hook | Mixed |
| **Insights** | Trigger ranking, time of day pattern, craving duration evidence, run lengths | Paid |
| **Settings** | Habit, notifications, unlock, export, data, about | Free, export free |
| **Paywall** | One price, plainly. No countdown, no fake discount, restore prominent | — |

Deliberate asymmetry on Home: the craving button is large and primary; logging a slip
is a small secondary link. It should never be easier to record giving in than to ride
it out, and that difference is expressed in layout rather than in words.

## 7. Onboarding

Five steps, defaults on everything, no permission prompts, no paywall, no account.

1. **What do you vape.** Disposables, pods, or refillable by millilitre. Sets the unit.
2. **How much and what it costs.** Per week, because that is how vapers describe it.
3. **When did you stop.** Defaults to today, a past date is allowed.
4. **Why.** Up to three reasons in their own words, with real examples as placeholder
   text. Told plainly that these come back during a craving. Highest value screen in
   the app: their own words are the strongest intervention available.
5. **Done.** Straight to Home, showing day one.

Notification permission is asked later, at the first milestone, after a short honest
explanation of what we send and what we never send. Asking during onboarding trades a
permanent no for a moment of convenience.

## 8. Notifications

The category spams. Restraint is a feature.

- **Never** a "you have not logged today" reminder. There is no check in to miss, and a
  guilt prompt would contradict the whole product. Written rule.
- Milestones at 1, 3, 7, 14, 30, 60, 90, 180, 365 days.
- One optional daily line of encouragement, default **off**.
- One follow up when a craving timer completes.
- All local. No push server, no remote notifications, ever.

## 9. Native surfaces

This is differentiator one made concrete, and it is why slice 5 matters more than it
looks.

| Surface | Behaviour |
|---|---|
| Lock Screen widget | The cumulative number, glanceable |
| Home Screen widget, small | Number plus current run |
| Home Screen widget, medium | Number plus a miniature stone grid |
| Interactive widget button | Starts a craving timer via App Intent, app never opens |
| Live Activity | Craving timer on Lock Screen and Dynamic Island, so the phone can be put down |
| Control Centre control | One press to start a craving timer |
| Action Button | Same intent, assignable |
| Siri and Shortcuts | "I'm having a craving" |
| StandBy | Large number overnight |
| Apple Watch | Complication plus a craving button on the wrist. Post launch |

## 10. Monetization

One non consumable unlock. StoreKit 2 directly, `Transaction.currentEntitlements`
checked at launch and cached in an `@Observable` purchase store.

Paywall appears only from Insights, widget setup, the sync toggle, and one mention at
day seven. Never at launch, never during onboarding, never as a full screen
interruption after a slip, which would be indefensible.

Recommended price 9.99 USD with Apple's regional matrix. Above the junk tier,
comfortably below the annual subscriptions we are positioned against, and honest to
compare against Kwit's recurring cost. Restore purchase is a visible button, not a
buried link.

## 11. Privacy

No analytics, no account, no network access other than CloudKit. `PrivacyInfo.xcprivacy`
declares no tracking and no data collection. That produces a **Data Not Collected**
badge on the listing, which almost nothing else in this category can show, and which
belongs in the screenshots.

## 12. Accessibility and localization

- Dynamic Type throughout. The hero number scales but is bounded so it cannot break
  layout at the largest sizes.
- VoiceOver: the hero reads as a sentence, each grid day announces its date and state.
- Reduce Motion: the breathing animation becomes a static count.
- Colour is never the only signal. Used days differ in shape as well as tone, for
  colour blindness.
- String Catalog from day one, so Arabic is not a retrofit. English at launch, Arabic
  in the first update. The year grid must mirror correctly, verified with the RTL
  pseudolanguage.

## 13. Testing

- `QuitStats`: done, twelve tests, fixed UTC calendar so they cannot flake.
- `InsightsEngine`: pure, tested the same way.
- **A tone test.** A unit test that scans the String Catalog for banned words: fail,
  failed, broke, lost, streak, start over, relapse used as a verb. It fails the build
  if shaming language reaches the app. The product principle becomes a CI gate rather
  than a good intention.
- Manual matrix before each TestFlight: RTL pseudolanguage, Dynamic Type at maximum,
  Reduce Motion, both themes, fresh install, and restore purchase.

## 14. Slices

Each ends with something runnable and judgeable.

| Slice | Content | Done when |
|---|---|---|
| 1 | Design tokens, real Home, onboarding | Fresh install reaches Home showing day one. Harness deleted |
| 2 | Craving flow, slip log, milestone notifications | A craving can be ridden out and a slip logged; total visibly unchanged |
| 3 | History: year grid, event list, chart | Grid mirrors under RTL, VoiceOver reads each day |
| 4 | Insights, StoreKit unlock, paywall | Purchase and restore both work in sandbox |
| 5 | Widgets, Live Activity, Control Centre, App Intents | A craving timer starts from the Lock Screen without opening the app |
| 6 | Polish, accessibility, export, icon, empty states, damaged store message | Manual matrix passes clean |
| 7 | TestFlight with real users from a quit community | Ten external testers, two weeks, feedback logged |
| 8 | Listing, screenshots, keywords, submit | Submitted |
| 9 | Arabic and RTL, Apple Watch | Post launch |

## 15. Daily observations

One line on the Home screen beneath the hero number, changing once a day, computed
entirely from the user's own data. Also shown on the medium widget, and in the optional
daily notification for anyone who turns it on.

### The test

**Every observation must be acceptable on the day the user relapsed.** A fact survives
that test. Encouragement does not. This rule decides what gets built.

Passes: "Your longest run was 21 days. You have already done this once."
Fails: "Amazing work, keep it up!", "You are on fire", "Do not break your streak now."

Loss aversion is banned outright. Any line whose motivating force is fear of losing
something contradicts the entire product.

### Selection

Deterministic, seeded by the day number, so the line is stable for the whole day and
identical on the widget, in the app and in the notification. An observation that changes
on every launch reads as random and untrustworthy.

Each observation declares its own eligibility, so a user on day two never sees an empty
or absurd statistic. Recently shown observations are excluded before picking.

### Catalogue

Available from day one:

- `AED 1,890 has stayed in your account.`
- `You have not bought 27 disposables since you stopped.`
- `Your longest run was 21 days. You have already done this once.` (once it exceeds the current run)

Needs seven days of history:

- `63 of your last 67 days had no nicotine in them.`
- `You had 26 free days this month, against 19 last month.`

Needs five logged cravings:

- `Your cravings last 4m 12s on average.`
- `You rode out 10 of your last 12 cravings.`
- `You have waited out 3 hours and 40 minutes of cravings in total.`
- `The longest craving you have ridden out lasted 11 minutes.`

Needs fourteen days and eight cravings:

- `Your cravings have dropped from 14 in your first week to 4 last week.` **The single
  most motivating statistic available, because craving frequency genuinely decays and
  nobody argues with their own trend line.**
- `Being on your phone accounts for 8 of your cravings, more than any other trigger.`
- `Most of your cravings arrive between 9 and 11pm.`

### Two numbers that only ever grow

The hero is not the only monotonic figure. **Total time spent waiting out cravings**
also cannot decrease, and it represents effort rather than luck, which makes it the best
thing to show someone immediately after a slip. Both numbers are slip proof by
construction.

### No body healing timelines in version one

Every "your circulation improves at two weeks" figure in circulation derives from
cigarette cessation research. Applying those timelines to vaping is unsourced, and it is
the precise failure that QuitNow is criticised for. Nicotine withdrawal timing is better
established, so if we ship anything in this category it is withdrawal shaped, cited
inline, and phrased at the conservative end. Otherwise we omit it, and omitting it costs
us nothing.

### Implementation

`Core/Observations/ObservationEngine.swift`, pure, no framework dependency, taking
`QuitStats` plus craving data and returning an eligible ranked list. Tested like
`QuitStats`, including a test that every catalogue entry is renderable with a relapse
recorded today. Built in slice 3, since it needs craving history to be worth anything.

## 16. Open items

- Price confirmation at 9.99 USD.
- Bundle identifier and a domain for the required support URL.
- Reserve the name NicFree in App Store Connect as soon as enrollment clears.
- CloudKit is blocked until the paid account is active, which gates slice 5.
- Whether Arabic ships at launch or in the first update.
