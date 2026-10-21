# Nicfree — working agreement

An iOS app for quitting vaping and nicotine pouches. Loaded at the start of every session.
This file holds only what changes behaviour; the reasoning lives in `docs/`.

**The product is Nicfree.** `Cairn` is the code name and stays in the Xcode project, target,
module, file headers and docs. Never rename those. Anything a user can see says Nicfree.

**v1 scope and dates live in `LAUNCH.md`.** Read it first. Anything not in v1 goes on its
later list rather than into the code.

## Where things are

| Document | Contents |
|---|---|
| `docs/ARCHITECTURE.md` | Code structure, data model, the derived layer, conventions |
| `docs/FLOWS.md` | Every user flow, and what each one writes to the store |
| `docs/DECISIONS.md` | Every non obvious decision and why. **Read before changing behaviour** |
| `LAUNCH.md` | v1 scope, daily plan to submission, fix list, open decisions |
| `BLUEPRINT.md` | Market research, competitor findings, positioning |
| `PLAN.md` | Slice plan, dependencies, monetization, go to market |
| `VISUAL-DIRECTION.html` | The design system, rendered. Open in a browser |

Code lives in `Cairn/`, an Xcode project. Tests in `Cairn/CairnTests/`.

## Product rules that are not preferences

Breaking any of these breaks the product, not just a screen.

1. **The hero number is cumulative lifetime free days and cannot decrease.** A slip adds a
   used day. It never removes a free one. Never introduce a streak as the primary figure.
2. **A `DayRecord` exists only for a day nicotine was used.** Absence means free. There is
   no check in, no daily prompt, and no blank state to feel guilty about.
3. **Never shame.** Banned from all copy: fail, failed, broke, lost, streak, start over,
   relapse as a verb. Loss aversion as a motivator is banned outright.
4. **Every user facing statistic must be acceptable on the day someone relapsed.** If a
   line would read as mockery that day, it does not ship. This kills all encouragement
   and keeps facts.
5. **A slip is never red.** Red is alarm and alarm is shame. Used days are clay, and they
   differ in shape as well as tone so colour is never the only signal.
6. **No community, no chat, no social features.** Unmoderatable by one person, and the
   category's leading example is openly hostile to newcomers.
7. **No health claim without a source, at the conservative end of the range.** Cigarette
   recovery timelines do not transfer to vaping.
8. **No subscription.** Free core, one purchase for depth.
9. **No third party packages.** Apple frameworks only.
10. **Migrations are additive only.** Losing someone's history is the one unrecoverable
    failure, because you cannot give the months back.

## Code conventions

- SwiftUI over SwiftData. `@Query` to read, `modelContext` to mutate. **Not VIP**, and no
  view model per screen. `@Observable` only where state genuinely needs coordinating.
- **All derived numbers live in pure types** under `Core/`, with no SwiftUI or SwiftData
  import, so they are directly testable. `QuitStats` and `CravingInsights` are the pattern.
- Design tokens come from `Design/Theme.swift`. Never a literal colour, font size or
  spacing value in a feature file.
- Every user facing string is a `Text` literal or `String(localized:)`. Never a hardcoded
  display string. Arabic and RTL ship after launch, so the catalog is populated from day
  one rather than retrofitted.
- `os.Logger`, never `print`.
- Enums persist as raw strings with a typed accessor, never as `Codable` properties.

## Build

- **Claude builds and tests.** Since 2026-10-22 Zain wants Claude to compile, run tests and keep
  working through `LAUNCH.md`, and he evaluates at the end. Always pass `-derivedDataPath` pointing
  at the scratchpad so a build never fights an open Xcode window. Zain still owns the on-device
  check and every product call.
- The project uses **file system synchronized groups**: folder location *is* target
  membership. Put a file in the right folder and it is in the right target. Never edit
  target membership by hand.

## Traps already hit, do not repeat

- **Never name a type `Observation`.** It shadows the standard library *module*, and
  SwiftData's `@Model` macro expands to `Observation.Observable`. Every `@Model` in the
  target fails, and the errors point at generated files rather than at the cause. Same
  applies to `Testing`, `Charts`, `Combine`.
- A `Layout` used as `FlowLayout { ... }` must have **no initialiser parameters**, or the
  call is ambiguous against `callAsFunction`.
- Presenting a sheet directly from a full screen cover's dismissal handler drops it. Raise
  it from the cover's `onDismiss` instead.
