# Architecture

## Shape

Plain SwiftUI over SwiftData. Views read with `@Query` and mutate through `modelContext`.
There is no view model per screen and no VIP layering: this is a single developer app with
seven screens, and the indirection would cost more than it returns.

The one structural rule that matters: **every derived number lives in a pure type with no
SwiftUI and no SwiftData import.** Those types are the only thing with real unit tests,
because a wrong hero number would destroy trust in everything else the app says.

```
Cairn/Cairn/
  App/          CairnApp (ModelContainer), RootView (onboarding vs home)
  Models/       Habit, DayRecord, CravingEvent, and the enums
  Core/
    Stats/      QuitStats, QuitStatsSeries        ← pure, tested
    Insights/   CravingInsights                   ← pure, tested
    Observations/ ObservationEngine               ← pure
    Notifications/ MilestoneScheduler
  Design/       Theme (tokens), Components, FlowLayout
  Features/     Onboarding, Home, Craving, Slip, History
  Resources/    Assets, Localizable.xcstrings
CairnTests/     QuitStatsTests, CravingInsightsTests
```

Folder location determines target membership, because the project uses file system
synchronized groups. Creating a subfolder needs no Xcode bookkeeping.

## Data model

Three models. All properties have defaults or are optional and there are no unique
constraints, which is what CloudKit mirroring requires.

**`Habit`** — one per install. What is being quit, the weekly baseline used to estimate
money and nicotine avoided, the quit date, and the user's reasons in their own words.
Baseline is per week because that is how vapers describe their use; daily figures are
derived, never entered.

**`DayRecord`** — **exists only for a day on which nicotine was used.** This is the most
important design decision in the schema. The absence of a record is what makes a day free,
so a free day costs zero interactions, there is nothing to check in to, and the no check in
promise is structural rather than a copy choice someone can later erode.

**`CravingEvent`** — every craving, resisted or not, with how long it was held out and what
set it off. A slip logged from the slip sheet also writes one of these with
`resisted: false`, so trigger analysis covers cravings that were survived *and* cravings
that were not.

Enums persist as raw strings with a typed accessor. SwiftData stores `Codable` values as
opaque blobs, which makes them unusable in `#Predicate` and awkward to mirror.

## The derived layer

Nothing is stored twice. Everything on screen is computed.

**`QuitStats`** takes the quit date and the set of used days and returns
`lifetimeFreeDays` (the hero, which cannot decrease), `currentRun`, `longestRun`,
`totalDaysTracked`, and the money and nicotine estimates. `QuitStatsSeries` adds
`series()`, the day by day spine that both the year grid and the cumulative chart read, so
there is exactly one definition of what happened on a given date.

**`CravingInsights`** takes a flat list of craving events and returns averages, totals, the
resisted ratio, the top trigger, the riskiest hour, and the week over week frequency trend.
Two deliberate asymmetries: the *average* hold counts only resisted cravings, because
averaging in the ones that ended in use drags the figure down exactly when it is needed;
the *total* hold counts every craving, because sitting with it for six minutes and then
vaping is still six minutes of effort. Like the hero number, that total can only grow.

**`ObservationEngine`** turns all of the above into one factual line for the home screen,
gated by eligibility so a user on day two never sees an absurd statistic, and seeded by the
day number so the line is stable for a whole day and identical wherever it appears.

## Notifications

Local only, no push, no server. Milestones count **free days**, not elapsed days, so a slip
moves the next one. A local notification cannot re-evaluate itself on delivery, so the
entire schedule is removed and rebuilt whenever the free day count changes, from a
`.task(id:)` on Home.

## Persistence and durability

Local first. The device is the source of truth; CloudKit is a mirror, added in slice 5 once
the paid developer account is active. No accounts, so there is no login state that can
orphan data.

`CairnApp.makeContainer()` deliberately does not `fatalError` on a failed store. The app's
entire value is an accumulated record, so a crash loop is the worst available outcome: the
user cannot even open the app to export what they have. It falls back to an in memory
container so the app still launches.

## Testing

Only the pure types are unit tested, and thoroughly. Both suites use a fixed UTC calendar
and a fixed instant so they cannot flake on a timezone change or a DST boundary.

Planned for slice 6: a test that scans the String Catalog for banned words, so shaming
language fails the build rather than relying on good intentions.
