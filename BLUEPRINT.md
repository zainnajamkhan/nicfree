# Nicotine cessation app — blueprint

Working document. Decisions here are settled unless marked OPEN.

## The one sentence

A vape quitting tracker that never punishes you for slipping, never asks you to check in, and cannot lose your history.

## Positioning

The category leader (Kwit, 4.5M users, WHO validated) is built on levels, badges and a streak. Streaks are its retention hook, so it cannot abandon them.

**Update from review research:** shame free relapse handling is no longer an unclaimed position. QuitSmoke Coach, QuitMate and Streaks: Sober Day Tracker all launched in the last year advertising it. Read their descriptions closely though: in every case *the streak still resets*, they just preserve badges and money saved alongside it. None of them removed the streak as the hero, and none of them removed the daily check in. So the position is contested but not taken, and the fact that several developers reached for it independently confirms the pain is real.

Differentiation therefore rests on three things, in order:

1. **The hero number is cumulative and cannot decrease.** Not a streak with consolation prizes next to it.
2. **No daily check in.** An unlogged day is a free day. You open the app when something happens, never out of obligation.
3. **Execution and native depth.** Widgets, Live Activity, Watch, App Intents, offline. The recent wave of competitors are cross platform quick builds.

## What the incumbents are hated for

Taken from App Store review analysis. Each one becomes a rule.

| Complaint | Target | Our rule |
|---|---|---|
| Everything paywalled, three insights per category then locked, "more effort went into getting me to subscribe than to quit" | Kwit | The free tier must be independently useful. It is what earns reviews |
| Three day trial converting to an annual charge, called "very shady" by reviewers | Kwit | No subscription at all. One purchase |
| **Stats reset and history lost after cloud sync and version migrations** | Kwit | See data durability below. This is the most damaging complaint in the category |
| Health claims that are simply wrong (lung cancer risk framed as 5 years to normal when the figure is closer to 20) | QuitNow | No health claim ships without a source, and always the conservative end of the range. Prefer omitting a claim to guessing |
| Community chat unmoderated, described as "nicotinder", harassment, new users ignored | QuitNow | **No chat, no community, no social features.** A solo developer cannot moderate this, and it is a liability, not a feature |

### Data durability is a product feature, not an implementation detail

The app's entire value is an accumulated record. If it is lost, the app is worse than useless because the user cannot get those months back. Kwit's angriest reviews are exactly this. So:

- Local first. The device is the source of truth, CloudKit is a mirror.
- No destructive migrations, ever. Schema changes are additive.
- Export to CSV and PDF always available, including in the free tier.
- No account required, so no login state that can orphan data.

This is worth saying out loud on the store listing.

## Decisions locked

| Decision | Choice |
|---|---|
| Substance and form | **Vape.** Nicotine only. Alcohol is out, because withdrawal in dependent drinkers is medically dangerous |
| Home screen | Cumulative lifetime free days as hero. Current run and longest run secondary |
| Pricing | Free core, one purchase unlocks depth. No subscription |
| Check in | None. Absence of a record means a free day |
| Community features | None |
| Platform | iOS 18 minimum, SwiftUI, current SDK |
| Persistence | SwiftData, local first, CloudKit mirror. No accounts, no backend |
| Purchases | StoreKit 2 directly |
| Architecture | Plain SwiftUI over SwiftData. Not VIP |
| Dependencies | None in version one. No analytics SDK |

OPEN: visual direction (see below), app name, bundle identifier.

## Vaping is not smoking, and the data model has to reflect that

Cigarettes are discrete and countable. Vaping is continuous. A vaper does not know how many puffs they took today, and asking is a question they cannot answer, so a counter would either go unfilled or be invented.

Two consequences:

**Baseline is per week, not per day.** Vapers think in devices, pods or millilitres per week. Daily cost is derived from that, not entered.

**A slip is logged as coarse intensity, not a count.** Four options: a couple of puffs, several times, my usual amount, more than usual. Two seconds to answer honestly. The intensity never affects the hero number, which is binary on whether nicotine was used at all that day. It exists only for the user's own pattern recognition.

## Data model

The schema itself enforces the philosophy: **a DayRecord exists only for days nicotine was used.** There is no "free day" record to create, so there is nothing to check in to, and a free day costs the user zero interactions.

See `Sources/Models.swift` and `Sources/QuitStats.swift`.

Derived values live in pure functions with no SwiftData dependency, in `QuitStats`, and are the only part of the app with real unit tests. The hero number being wrong once would destroy trust in everything else.

## Craving triggers

Taken from NCI and NSW Health vaping cessation material rather than invented. Vape specific ones are marked.

Stress or anxiety · scrolling on your phone (vape specific, and the most interesting one) · after a meal · coffee · alcohol · a social situation · seeing someone else vape (vape specific) · driving · waiting around · boredom · loneliness · plain routine

The phone one matters more than it looks. For vaping, the trigger and the intervention live on the same device. Opening the app is the moment of risk, which means the craving screen has to load instantly and do something immediately, not present a menu.

## Craving interventions, evidence based

Rotate rather than repeat, and lead with the user's own reasons, written by them during onboarding:

1. **Their own reasons for quitting**, in their own words. Strongest single intervention available.
2. Interrupt the routine: stop what you are doing and change activity.
3. Move: a short walk, or stairs.
4. Paced breathing: in through the nose, out through the mouth, ten times. This is the default timer content.

## Screens

1. **Onboarding.** What do you vape, roughly how much per week, what it costs, when you started, and your reasons in your own words. Defaults on everything so it can be rushed.
2. **Home.** Hero cumulative number, current run, longest run, money saved, one large craving button.
3. **Craving flow.** Instant, no menu. Timer with breathing, their reasons on screen, then trigger and outcome.
4. **Slip log.** Coarse intensity, trigger, optional note. Copy here matters more than anywhere else in the app.
5. **History.** Year grid, event list, chart over time.
6. **Insights (paid).** Trigger breakdown, time of day pattern, run lengths over time.
7. **Settings.** Habit config, notifications, unlock, export, about.

## Free versus paid

**Free forever:** cumulative counter, current and longest run, slip logging, craving timer with their reasons, money saved, milestone notifications, **and export**.

**One purchase unlocks:** widgets and Lock Screen, Live Activity craving timer, insights and charts, the year grid and full history browsing, CloudKit sync across devices, Apple Watch app when it exists.

## Visual direction

User references are Kwit and QuitNow, both competitors rather than aesthetic references. Two cautions.

Guideline 4.1 covers copycat design, so take the polish level rather than the visual identity.

More importantly, there is a philosophical mismatch. Kwit's design celebrates: gradients, illustrated characters, badge animations. An app that shouts when things go well has nothing appropriate to say when they go badly, and our entire promise concerns what happens when they go badly. **A calm interface is the differentiation made visible.** High contrast, one enormous number, restrained colour, real typography, no mascot, no confetti. Closer to Apple's own Health and Fitness apps, or to Things, than to Kwit.

## Slices

| Slice | Content | Owner |
|---|---|---|
| 0 | Apple Developer enrolment, Agreements Tax and Banking, Xcode project created | user, start immediately |
| 1 | Models, stats functions with tests, onboarding, home with real numbers | Claude |
| 2 | Craving flow, slip logging, local notifications | Claude |
| 3 | History, year grid, charts | Claude |
| 4 | Insights, StoreKit 2 unlock, paywall | Claude |
| 5 | Widgets, Lock Screen, Live Activity | Claude |
| 6 | Polish, empty states, accessibility, app icon, export | Claude |
| 7 | TestFlight with real users from a quit community, iterate | both |
| 8 | Screenshots, listing copy, keywords, submit | both |

## Go to market

Sunnyside and Reframe can outbid any paid keyword indefinitely, so paid acquisition is closed. Channels are organic long tail App Store search and genuine participation in quit communities over months. r/stopsmoking has 193,000 members, r/stopdrinking over 900,000 and is heavily moderated, so a promotional post is removed on sight. Participate for weeks before ever mentioning the app.

## Risks

- **Apple health scrutiny.** No medical or treatment claims. Tracking and support only.
- **The category is full of paywall traps**, so Apple reviews it with suspicion. A generous free tier helps here as well as commercially.
- **A wave of competitors launched this year**, several claiming the same shame free angle. Execution and native depth are the defence, not the idea.
