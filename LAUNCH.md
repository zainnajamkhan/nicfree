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

Claude writes the code and the listing copy. Zain builds, runs on device, judges, and makes
every product call. Claude never compiles (see `CLAUDE.md`).

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
- [ ] App Store Connect: app record, `nicfree.unlock` IAP at $9.99, listing, age rating (Zain)
- [ ] Signing team in Xcode, then archive and TestFlight upload
- [x] Support and privacy pages live: https://zainnajamkhan.github.io/nicfree-site/ and /privacy.html (public repo `nicfree-site`), linked from Settings

## In v1

Everything built, plus everything in the list above.

## Later (v1.1 and after)

Widgets, Live Activity, Control Centre, Action Button, Siri, CloudKit sync, export,
cigarettes and shisha in onboarding, Arabic and RTL, Apple Watch, the two-week external
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

Fill this in on Oct 22 after using the app end to end.

1.
2.
3.
4.
5.
6.
7.
8.
9.
10.

## After launch

Check App Store Connect weekly: impressions, product page views, conversion rate, downloads,
purchases. At **day 60** decide: keep going, change the listing, or stop.

**Set your bar before launch, not after.** Suggested starting bar, adjust it now:
at least 300 downloads and 10 purchases in the first 60 days means the listing works and
v1.1 is worth building.
