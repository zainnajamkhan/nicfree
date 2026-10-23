# Flows

What each path through the app does, and what it writes.

## Launch

A launch screen (the sprout on the app's ground colour, from `NicFree-Info.plist`), then
`RootView`, which reads `@Query private var habits: [Habit]`. Empty means onboarding,
otherwise the four tabs: Home, Path, History, Insights. There is no separate "has onboarded"
flag, so nothing can drift out of sync with the data.

If the store could not be opened, the app runs on a temporary in-memory store and says so:
before onboarding as its own screen, and on Home as a notice. It never crashes on launch.

## Onboarding

Five steps, defaults on every one, a back button after the first, no account, no paywall,
and deliberately no permission prompt.

1. **What do you use** — vape (disposables, pods), nicotine pouches or cigarettes. Sets the
   unit. One product per person in v1; more than one is on the v1.1 list.
2. **How much** — the question names the product picked ("Roughly how many pouches do you
   use in a day?"). Per day for pouches and cigarettes, per week for vapes, plus an optional
   weekly spend in the local currency. Framed as "a rough number is fine", and it only shapes
   the money estimate, never the day count.
3. **When did you stop** — Today, Yesterday, or Another day, which opens a calendar. Future
   dates are not allowed.
4. **Why** — up to three reasons in their own words. The highest value screen in the app:
   these come back during a craving, which is the only time they matter.
5. **Ready** — teaches the core mechanic: every day counts as free unless you log a slip,
   and days away are asked about on return.

**Writes:** one `Habit` on finish. Nicotine content per unit is inferred from the unit type
rather than asked, and is editable later.

## Home

Reads everything. Writes only `lastCheckedThrough` and catch-up slips.

Stat chips (free days, cravings beaten, money not spent), the sprout card with the daily
observation and progress to the next milestone, the week row, then the action pair. The
asymmetry is deliberate: riding out a craving is a full width primary button, logging a slip
is a small grey link. It must never be easier to record giving in than to sit with it, and
that belongs in the hierarchy rather than in a sentence telling someone off.

A gear button opens Settings.

On any change to the free day count, the milestone schedule is rebuilt.

## Celebration

**Switched off for now** (`Celebration.isEnabled`, see `docs/DECISIONS.md`). When on: when Home opens on a new day, after any catch-up question: if one or more finished days since
the last celebration were free, a full screen celebration. The sprout pops in, leaves burst
out of it, and the total ticks up to today's number. "Another free day!", or the milestone
title when one was passed. One tap on "Yay!" closes it. Rules in `Celebration`.

**Writes** `lastCelebratedThrough`. Settings has preview buttons in debug builds.

## Catch-up

When Home becomes active after one or more full days away, it asks once: "Any nicotine
since Tuesday?" "All free" is one tap. "Yes, on some days" shows a chip per missed day
(at most 14), and the picked days are written as `DayRecord`s. Either way
`lastCheckedThrough` moves to today, so the same days are never asked about twice. The days
already counted as free; the question only lets someone correct that. Rules in
`CatchUp.daysToAsk`.

## Craving

The primary action. Opens **straight into the exercise** with no menu and nothing to read
first, because being on your phone is one of the most common vaping triggers and this screen
is competing with the thing that caused the craving.

- **Riding.** Breathing circle at four seconds in, four seconds out, driven by
  `PhaseAnimator` so the label and the circle stay in sync. Static under Reduce Motion. A
  live timer via `Text(timerInterval:)`, so no `Timer` object runs. One of the user's own
  reasons, chosen once per session, because rotating text at someone trying to calm down is
  noise.
- **It passed** → duration, optional trigger chips, Done.
  **Writes** a `CravingEvent` with `resisted: true` and the seconds held out.
- **I used** → hands the held seconds to Home, which raises the slip sheet.
  Styled as an ordinary secondary action, never as a failure.
- **Primer.** On the first ride out, if notification permission is undetermined, an honest
  explanation of what we send and a plain statement that NicFree will never nudge you for not
  opening it. The milestone status is fetched when the craving opens, so Done is instant. Asked here rather than at onboarding, because asking on first launch trades a
  permanent refusal for a moment of convenience.

## Slip

Reachable from Home directly, or from the craving screen's "I used".

Two questions. **How much** as four coarse options, never a count: asking a vaper how many
puffs they took produces either a blank field or an invented number. **What set it off**, as
optional chips.

Neither answer touches the hero number, which is binary on whether nicotine was used at all
that day. "What set it off" offers "+ Something else" for the person's own words.

Opened on an existing slip (from Home, or by tapping it in History), it edits it, or
**removes** it after a confirm. Removing deletes the `DayRecord` and the craving it wrote,
and the day counts as free again.

**Writes** a `DayRecord` for today, and a `CravingEvent` with `resisted: false` carrying the
trigger and any seconds held out before using. Editing an existing slip updates the record
and does not create a second craving.

Then the confirmation, which stays until Done: **"Logged. Every free day you’ve already had is still there."** A soft
haptic. Never the success haptic, because a system sound meaning "well done" at that moment
would be grotesque.

## History

Three readings of the same record. Free users see the last 7 days; the rest is behind
the unlock.

- **Year grid.** Every day since the quit date, weekday aligned. Free days are lichen
  squares, used days are clay circles: shape as well as tone, so the distinction survives
  colour blindness and greyscale. `LazyVGrid` mirrors itself under right to left.
- **Cumulative chart.** A single series, so the label names it and there is no legend. The
  line cannot fall; on a used day it holds flat. The thesis drawn rather than argued.
- **Events.** Slips from `DayRecord`, and only *resisted* cravings. A craving that ended in
  use already wrote a day record, so listing both would show the same moment twice.

Empty state reads "Nothing logged yet. That is the ideal outcome, not a gap."

## Milestones

At 1, 3, 7, 14, 30, 60, 90, 180 and 365 **free** days, at 10am local. Titles are flatly
factual with no exclamation marks: "A week free."

There is deliberately no "you have not logged today" reminder. Nothing is required, so
there is no check in to miss, and a guilt prompt would contradict the entire product.

The one exception is opt in: an **evening check-in** in Settings, off by default, at a time
the user picks. Its words are "How did today go? Nothing to do if it was a free day."

## Path, Insights, Paywall, Settings

- **Path** — the milestone trail, scrolled to the next one. Free.
- **Insights** — cravings, top triggers, hardest hour, weekly chart. Behind the unlock.
- **Paywall** — one non-consumable, `nicfree.unlock`, with Restore purchase.
- **Settings** — reasons, quit date, weekly spend, notifications, support and privacy links,
  and in debug builds only, "Unlock everything".