# Decisions

Every non obvious call, and why. Read before changing behaviour: most of these look
arbitrary and are not.

## Product

**The hero is cumulative lifetime free days, not a streak.** Relapse is the normal path in
nicotine cessation and most people need several attempts. A streak resetting to zero turns
the app into a monument to failure at exactly the moment it is needed. Several 2026
competitors claim shame free relapse handling, but every one still resets a streak and keeps
consolation stats beside it. Nobody has moved the hero.

**A day record exists only for days nicotine was used.** Enforces the no check in promise in
the schema rather than the copy. A free day costs zero interactions and there is no blank
state to feel bad about.

**Intensity is coarse, never a count.** Cigarettes are discrete; vaping is continuous. Ask a
vaper how many puffs and you get a blank field or an invented number.

**Baseline is per week.** Vapers describe their use in devices or pods per week. Daily
figures are derived.

**Alcohol is excluded.** Withdrawal in physically dependent drinkers can be medically
dangerous, which is a duty of care an indie app should not take on. Nicotine carries no
equivalent risk.

**No body healing timelines.** Every "circulation improves at two weeks" figure derives from
cigarette cessation research. Applying it to vaping is unsourced, and it is precisely what
QuitNow is criticised for, being wrong by roughly fifteen years on lung cancer risk.

**No community or chat.** QuitNow's own users describe theirs as unmoderated and hostile,
nicknamed "nicotinder", with newcomers ignored. One developer cannot police that, and it is
a liability rather than a feature.

**Every statistic must survive the bad day test.** If a line would read as mockery on the
day someone relapsed, it does not ship. This is what separates evidence from encouragement,
and it is why the daily line is factual rather than cheerful.

## Design

**Calm, not Kwit.** The references given were Kwit and QuitNow, both competitors. Kwit's
look is gradients, mascots and badge animations. An app that celebrates loudly has nothing
decent to say when things go wrong, and that is the day the product exists for. A calm
interface is the differentiation made visible.

**A slip is never red.** Red is alarm and alarm is shame. Used days are weathered clay, and
they differ in shape as well as tone so colour is never the only signal.

**Palette from the object the app is named after**: wet slate, lichen, clay. Cold blue
biased neutrals so a single green accent reads as chosen rather than decorative.

**The craving button is large, the slip link is small.** It should never be easier to record
giving in than to sit with it. Expressed in hierarchy, never in a sentence telling someone
off.

**One animation in the entire app**, the breathing circle, which is a paced exercise rather
than an ornament. No confetti, ever.

**The success haptic is never used for logging a slip.**

**Sprout replaced the calm look (2026-10-22).** The app is now bright, rounded and playful,
in the spirit of Duolingo: chunky buttons, stat chips, a mascot, a milestone path. The earlier
"calm, not Kwit" and "one animation only" decisions are superseded. What did not change is
every product rule in CLAUDE.md. Playful is fine; shaming is not.

**The mascot never wilts, frowns or reacts to a slip.** It only gains leaves as free days add
up (1 leaf, 2 at 3 days, 3 at 7, 4 at 30). A mascot that looked sad on a slip day would be
shaming with a face, which is the same as red.

**Borrowed from Duolingo: the fun. Not borrowed: the streak.** No streak counter, no streak
freeze, no "don't break it" copy. Every number on Home only grows: free days, cravings beaten,
money not spent. Used days stay clay rounded squares, never red, and differ in shape from
free circles.

**Home's free-day number is now a chip, not a giant hero.** The hero rule (cumulative, cannot
decrease) still holds, and the chip is first and labelled for VoiceOver as "Free days, all
time". Revisit if the number should be larger.

**Palette tokens keep their old names.** `ground`, `ink`, `accent`, `clay` and the rest
stayed so every screen restyled from `Theme.swift` alone. New tokens: `accentDeep`,
`onAccent`, `leaf`, `sky*`, `sun*`, `calm*`, `pot*`.

## Technical

**No third party packages.** Avoids supply chain risk, keeps launch fast, removes third
party privacy manifest obligations, and earns a **Data Not Collected** badge on the listing
that almost nothing else in the category can show.

**Design tokens in Swift, not the asset catalog.** Version controlled, diffable, and both
themes are authored side by side rather than one being an inversion of the other.

**Pure types for every derived number.** Testable without a store. `QuitStats` and
`CravingInsights` are the pattern; feature code never does arithmetic.

**Enums persist as raw strings.** SwiftData stores `Codable` values as opaque blobs, unusable
in `#Predicate` and awkward to mirror through CloudKit.

**No `fatalError` on a failed model container.** The app's value is an accumulated record, so
a crash loop is the worst outcome: the user cannot even open the app to export. Falls back to
an in memory store.

**Migrations are additive only.** Kwit's angriest reviews are lost stats after sync and
version migrations. You cannot give someone their months back.

**Milestones rebuild rather than schedule once.** They count free days, not elapsed days, so
a slip moves the next one, and a local notification cannot re-evaluate itself on delivery.

**Notification permission asked after the first successful craving.** Asking at onboarding
trades a permanent refusal for a moment of convenience.

**A slip's trigger is stored as a `CravingEvent` with `resisted: false`**, not as a field on
`DayRecord`, so trigger analysis covers both outcomes rather than only the survived ones.

**The average hold excludes cravings that ended in use; the total hold includes them.**
Averaging in the failures drags the figure down exactly when it matters. Counting effort
regardless is what makes the total a second number that can only grow.

**One reason per craving session, not rotating.** Cycling text at someone trying to calm down
is noise.

**`DailyObservation`, not `Observation`.** `Observation` is a standard library module and
SwiftData's `@Model` macro expands to `Observation.Observable`. A type of that name anywhere
in the module breaks every `@Model` in the target, with errors pointing at generated files.

**`FlowLayout` has no initialiser parameters.** A `Layout` used as `FlowLayout { ... }`
becomes ambiguous against `callAsFunction` if it does.

**The slip sheet is raised from the craving cover's `onDismiss`.** Presenting a sheet while a
full screen cover is still animating away silently drops it.

## Commercial

**Free core with one purchase, no subscription.** The category is full of subscription traps
that reviewers openly resent, so honest pricing is a marketing position competitors cannot
copy without wrecking their own revenue. Recommended at 9.99 USD.

**The paywall never appears at launch, during onboarding, or after a slip.** The last would
be indefensible.

**Paid acquisition is closed.** Sunnyside and Reframe can outbid any keyword indefinitely.
The channels are organic long tail search and genuine community participation over months.
