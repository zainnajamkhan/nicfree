# Flows

What each path through the app does, and what it writes.

## Launch

`RootView` reads `@Query private var habits: [Habit]`. Empty means onboarding, otherwise
Home. There is no separate "has onboarded" flag, so nothing can drift out of sync with the
data.

## Onboarding

Five steps, defaults on every one, no account, no paywall, and deliberately no permission
prompt.

1. **What do you vape** — disposables, pods, or refillable by millilitre. Sets the unit.
2. **How much and what it costs** — per week, with steppers. Framed as "a rough number is
   fine", and it only shapes the money estimate, never the day count.
3. **When did you stop** — defaults to today, past dates allowed, future dates not.
4. **Why** — up to three reasons in their own words. The highest value screen in the app:
   these come back during a craving, which is the only time they matter.
5. **Ready** — teaches the core mechanic in one sentence: a day you do not open NicFree
   counts as a day free.

**Writes:** one `Habit` on finish. Nicotine content per unit is inferred from the unit type
rather than asked, and is editable later.

## Home

Reads everything, writes nothing.

Hero number, the daily observation line, three quiet rows, then the action pair. The
asymmetry is deliberate: riding out a craving is a full width primary button, logging a slip
is a small grey link. It must never be easier to record giving in than to sit with it, and
that belongs in the hierarchy rather than in a sentence telling someone off.

A toolbar button leads to History.

On any change to the free day count, the milestone schedule is rebuilt.

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
- **I vaped** → hands the held seconds to Home, which raises the slip sheet.
  Styled as an ordinary secondary action, never as a failure.
- **Primer.** On the first ride out, if notification permission is undetermined, an honest
  explanation of what we send and a plain statement that NicFree will never nudge you for not
  opening it. Asked here rather than at onboarding, because asking on first launch trades a
  permanent refusal for a moment of convenience.

## Slip

Reachable from Home directly, or from the craving screen's "I vaped".

Two questions. **How much** as four coarse options, never a count: asking a vaper how many
puffs they took produces either a blank field or an invented number. **What set it off**, as
optional chips.

Neither answer touches the hero number, which is binary on whether nicotine was used at all
that day.

**Writes** a `DayRecord` for today, and a `CravingEvent` with `resisted: false` carrying the
trigger and any seconds held out before using. Editing an existing slip updates the record
and does not create a second craving.

Then the confirmation, held for 1.8 seconds: **"Logged. Your total is unchanged."** A soft
haptic. Never the success haptic, because a system sound meaning "well done" at that moment
would be grotesque.

## History

Three readings of the same record.

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

There is deliberately no "you have not logged today" reminder. There is no check in to miss,
and a guilt prompt would contradict the entire product.
