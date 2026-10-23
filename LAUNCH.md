# NicFree v1 launch plan

**Finish line: submitted to App Store review by Tue Nov 3, 2026.** Wed Nov 4 is buffer.
Downloads, revenue and reviews are not the goal of these two weeks. Shipping is.

This file overrides the slice plan in `PLAN.md` for v1 scope and dates. `PLAN.md` stays the
full product plan.

## The rules

1. **Scope is frozen.** Anything not in "In v1" below goes on the later list. New app ideas
   go there too.
2. **No judging the idea until 60 days after launch.** Competitor research is closed. The
   decision gets made on the numbers in "After launch", not on a bad evening.
3. **Minimum day: 20 minutes on that day's task.** Never skip two days in a row.
4. **Slipping a date is allowed. Abandoning is not.** If a day overruns, the plan moves
   back a day. If week 1 overruns by more than 3 days, move the finish line one week.

## Who does what

Since Oct 22, Claude writes the code and listing copy, builds, and runs the tests
(`tools/test.sh`). Zain runs it on a device, judges it, and makes every product call. Anything
that needs his Apple account (App Store Connect, signing) stays with him.

## Where things stand (audit, Oct 22)

**Built:** onboarding, Home, craving flow, slip log, History with year grid, milestone
notifications, `QuitStats`, `CravingInsights`, `ObservationEngine`, string catalog, unit tests.

**Progress (Oct 22, Claude building and testing):**
- [x] Sprout redesign: tokens, chunky buttons, mascot, Home, Path tab, Craving
- [x] Pouch path in onboarding; vape-only wording made neutral ("I used", "Just a little")
- [x] Weekly spend replaces cost per unit (works in any currency, optional)
- [x] Settings screen: reasons, quit date, weekly spend, notifications, privacy line
- [x] Insights screen (paid), trigger ranking added to `CravingInsights` with a test
- [x] StoreKit 2 unlock, paywall, restore, History gating; local `NicFree.storekit` + shared scheme
- [x] `PrivacyInfo.xcprivacy`: no tracking, nothing collected
- [x] Tone test that fails on banned words
- [x] Plural fixes ("1 free day", not "1 free days")
- [x] UI test that walks a pouch user through first run, a craving, a slip, every tab and the paywall
- [x] Damaged store message, on Home and before onboarding, with a UI test
- [x] App icon: light, dark, tinted (`tools/render_icon.swift`)
- [x] Largest Dynamic Type: UI test runs the whole first run at AccessibilityXXXL
- [x] Dark mode: UI test runs the whole first run in dark; two contrast fixes
- [ ] VoiceOver by ear on a real device (labels are in place; needs a human listen)
- [x] Listing copy and privacy policy drafted (`docs/LISTING.md`, `docs/PRIVACY.md`)
- [x] Rename project to NicFree
- [x] Bundle ID `com.zainnajamkhan.nicfree`; iOS 26.0 minimum; iPhone (portrait) and iPad
- [x] App Store screenshots: `screenshots/iphone-6.9` and `screenshots/ipad-13`, six each (`tools/screenshots.sh`)
- [x] Support and privacy pages live: https://zainnajamkhan.github.io/nicfree-site/ and /privacy.html (public repo `nicfree-site`), linked from Settings
- [x] Zain's first test (Oct 23): all items in "Fix list" below handled
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO`, so uploads skip the encryption question

- [x] Zain's second round (Oct 23): friendly copy, cigarettes, per-product amount question,
  custom triggers, remove a slip, free day celebration (built, then switched off for now)

## To submit

In order. Nothing else blocks submission.

| # | Step | Who |
|---|---|---|
| 1 | USPTO check on "NicFree" (live marks in software or health) | Zain |
| 2 | App Store Connect: new app, bundle ID `com.zainnajamkhan.nicfree`, name from `docs/LISTING.md`. This reserves the name | Zain |
| 3 | In-app purchase: non-consumable `nicfree.unlock`, $9.99, display name and description from `docs/LISTING.md`, review screenshot of the paywall | Zain |
| 4 | Xcode → NicFree target → Signing & Capabilities: pick the paid "Zain Najam" team (individual membership) | Zain |
| 5 | Archive and upload to TestFlight | Claude, once step 4 is done |
| 6 | Install from TestFlight on your phone. Buy the unlock with a sandbox account, then restore | Zain |
| 7 | VoiceOver pass on the phone | Zain |
| 8 | Listing: paste from `docs/LISTING.md`, upload `screenshots/`, support and privacy URLs, App Privacy = "Data Not Collected", age rating questionnaire, attach the IAP to version 1.0 | Zain |
| 9 | Submit for review | Zain |

## In v1

Everything built, plus everything in the list above.

## Later (v1.1 and after)

Widgets, Live Activity, Control Centre, Action Button, Siri, CloudKit sync, export,
more than one product per person (pick-all-that-apply onboarding, "what did you use?" on a
slip; decided Oct 23), cigarettes and shisha in onboarding, Arabic and RTL, Apple Watch, the two-week external
tester round.

Exception: one Lock Screen widget on Mon Nov 2, **only** if every other v1 item is done.

## Decisions Zain owns, with deadlines

| Decision | Deadline | Recommendation |
|---|---|---|
| ~~Bundle ID~~ | Done Oct 22 | `com.zainnajamkhan.nicfree` |
| ~~Support URL~~ | Done Oct 22 | https://zainnajamkhan.github.io/nicfree-site/ |
| Price | Mon Oct 26 | $9.99 one-time, as planned |
| Trademark check on "NicFree" | Fri Oct 23 | Search USPTO for live marks in apps/health before reserving the name |

Done: renamed to **NicFree** everywhere, project included.

## Daily plan

Weekdays are about 2 hours, weekends 4 to 5.

| Day | Task | Done when |
|---|---|---|
| **Thu Oct 22** | ✅ Enrolled. ✅ Name chosen. ✅ First commit. ✅ Display name set. Run the app end to end on your phone and list the 10 worst UI/UX problems in "Fix list" below | Fix list has 10 items |
| **Fri Oct 23** | Decide bundle ID. USPTO check. Create the app in App Store Connect, which reserves the name. Join the App Store Small Business Program. Add the pouch path to onboarding | Name reserved; a pouch user can onboard |
| **Sat Oct 24** | Fix list: onboarding and Home items | Those items ticked |
| **Sun Oct 25** | Fix list: craving, slip and History items | All 10 ticked |
| **Mon Oct 26** | StoreKit 2 purchase store, the $9.99 product in App Store Connect, a local StoreKit config file | Sandbox purchase works |
| **Tue Oct 27** | Paywall, restore button, gating on History's full grid | Purchase and restore both work |
| **Wed Oct 28** | Insights screen on top of `CravingInsights`, behind the unlock | Insights shows real data after purchase |
| **Thu Oct 29** | Settings (notifications, unlock and restore, support link, privacy, about). Damaged store message. Privacy manifest. Tone test | No automatic-rejection risks left |
| **Fri Oct 30** | App icon. VoiceOver and largest Dynamic Type pass. Upload the first build to TestFlight, invite 3 to 5 people. External testers need a short Beta App Review, so upload early | Build uploaded, testers invited |
| **Sat Oct 31** | Fix tester bugs. Screenshots | Screenshots done |
| **Sun Nov 1** | Listing: name, subtitle, keywords, description, privacy label, age rating questionnaire, support page live | Listing complete in App Store Connect |
| **Mon Nov 2** | Buffer: bug fixes. Lock Screen widget only if everything else is done | No known crashes |
| **Tue Nov 3** | Final build, archive, **submit** | Status reads "Waiting for Review" |
| **Wed Nov 4** | Buffer, or answer a rejection | Submitted |

## Listing (draft, finalised Sun Nov 1)

- **Name:** NicFree: Quit Vape & Pouches
- **Keyword targets** (from the Oct 21 App Store check): "nicotine pouch" and "quit zyn"
  have no established app (the biggest real pouch app has 420 ratings). "vape tracker" is
  winnable. "quit vaping" and "quit smoking" are crowded, so don't lead with them.
- "Zyn" is a trademark. Keep it out of the name and subtitle.

## Fix list

From Zain's first run on Oct 23. Details in `docs/DECISIONS.md`.

1. ✅ No launch screen: white or dark ground with the sprout (`NicFree-Info.plist`)
2. ✅ No way back in onboarding: back button on every step after the first
3. ✅ "A day you don't open the app counts as free" felt wrong: the catch-up question on
   return plus an optional evening check-in (off by default)
4. ➡️ More than one product per person (for example cigarettes to vape): v1.1
5. ✅ See the paid screens while developing: Settings → "Unlock everything" (debug builds only)
6. ✅ Chips clipped on the left edge in the slip sheet: borders drawn inside
7. ✅ Native-looking date pill: Today / Yesterday / Another day, with a styled calendar
8. ✅ "Logged" sheet vanished by itself: it now waits for Done

## After launch

Check App Store Connect weekly: impressions, product page views, conversion rate, downloads,
purchases. At **day 60** decide: keep going, change the listing, or stop.

**Set your bar before launch, not after.** Suggested starting bar, adjust it now:
at least 300 downloads and 10 purchases in the first 60 days means the listing works and
v1.1 is worth building.
