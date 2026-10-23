# NicFree — working agreement

An iOS app for quitting vaping and nicotine pouches. Loaded at the start of every session.
This file holds only what changes behaviour; the reasoning lives in `docs/`.

**The product is NicFree**, everywhere: the Xcode project, targets, module, types and every
screen. It was called Cairn until 2026-10-22, which is why older commits say Cairn.

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

Code lives in `NicFree/`, an Xcode project. Tests in `NicFree/NicFreeTests/`.

## Product rules that are not preferences

Breaking any of these breaks the product, not just a screen.

1. **The hero number is cumulative lifetime free days and cannot decrease.** A slip adds a
   used day. It never removes a free one. Never introduce a streak as the primary figure.
   The one exception is today: it counts as free until a slip is logged for it, so a slip
   today lowers the total by one (`docs/DECISIONS.md`, 2026-10-22). Copy must not claim
   the total is unchanged.
2. **A `DayRecord` exists only for a day nicotine was used.** Absence means free. There is
   no required check in and no blank state to feel guilty about. On return after a day or
   more away, Home asks once about the missed days. The evening check-in is opt in and off
   by default (decided 2026-10-23).
3. **Never shame.** Banned from all copy: fail, failed, broke, lost, streak, start over,
   relapse as a verb. Loss aversion as a motivator is banned outright.
4. **Every user facing statistic must be acceptable on the day someone relapsed.** If a
   line would read as mockery that day, it does not ship. This kills all encouragement
   and keeps facts. The one place for cheer is the free day celebration, because it only
   ever follows a finished free day.
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
11. **Copy is simple and friendly**: grade 8 words, contractions everywhere, a little
    playful. Never at the cost of rules 3 and 4.

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
- **Run tests with `tools/test.sh <simulator-udid>`.** It runs three separate passes (unit,
  the purchase test alone, UI), because the UI tests' paywall leaves StoreKit state that
  breaks the purchase unit test when they share a run.
- **Screenshots with `tools/screenshots.sh <udid> <folder>`**: iPhone 17 Pro Max for
  `screenshots/iphone-6.9`, iPad Pro 13-inch for `screenshots/ipad-13`.
- DEBUG-only launch flags: `-freshStoreForUITests` (UI tests never see each other's data),
  `-simulateDamagedStore`, `-forceDarkForUITests`, `-seedScreenshotData`,
  `-unlockForScreenshots`, `-simulateAwayForUITests`, `-celebrateForUITests`,
  `-celebrateMilestoneForUITests` (the last two with `-seedScreenshotData`). Settings has
  DEBUG-only "Unlock everything" and celebration preview buttons.
- The project uses **file system synchronized groups**: folder location *is* target
  membership. Put a file in the right folder and it is in the right target. Never edit
  target membership by hand.

## Traps already hit, do not repeat

- **Never name a type `Observation`.** It shadows the standard library *module*, and
  SwiftData's `@Model` macro expands to `Observation.Observable`. Every `@Model` in the
  target fails, and the errors point at generated files rather than at the cause. Same
  applies to `Testing`, `Charts`, `Combine`, and to SwiftUI protocol names such as `Layout`
  (an `enum Layout` broke `FlowLayout` on 2026-10-22) and `State`.
- A `Layout` used as `FlowLayout { ... }` must have **no initialiser parameters**, or the
  call is ambiguous against `callAsFunction`.
- Presenting a sheet directly from a full screen cover's dismissal handler drops it. Raise
  it from the cover's `onDismiss` instead.
- A sheet that needs data uses `sheet(item:)`, never `sheet(isPresented:)` plus a separate
  `@State`. The catch-up sheet showed "Any nicotine since ?" until it was switched.
- Bordered chips and buttons inside a scroll view use `strokeBorder`, not `stroke`, or the
  scroll edge clips half the line.
- If UI tests start timing out ("Timed out while fetching snapshot from testmanagerd", tests
  taking many minutes), the simulator is wedged, not the app. Shut it down, boot it, rerun.
  Recording video with `simctl io` on the test simulator before a run caused this once.
- `SectionLabel` uppercases its text, and so does its accessibility label. UI tests match it
  with `BEGINSWITH` or `CONTAINS`, never an exact string.
