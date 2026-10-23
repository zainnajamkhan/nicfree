# NicFree

An iPhone and iPad app for quitting vaping and nicotine pouches. It counts your free days
in total, not as a streak, so a slip never wipes them out.

- No account, no tracking, nothing leaves the device
- Free core app, one $9.99 purchase for Insights and full History, no subscription
- SwiftUI, SwiftData and StoreKit 2. Apple frameworks only

Support and privacy: https://zainnajamkhan.github.io/nicfree-site/

## Run it

Needs Xcode 27 or later. The app targets iOS 26.0.

1. Open `NicFree/NicFree.xcodeproj`
2. Pick the NicFree scheme and a simulator, then ⌘R

The scheme uses `NicFree/NicFree.storekit`, so the purchase works locally without App Store
Connect. In debug builds, Settings has an "Unlock everything" switch.

## Test it

```sh
tools/test.sh <simulator-udid>       # unit, purchase and UI tests, as three passes
tools/screenshots.sh <udid> <folder> # App Store screenshots
```

`xcrun simctl list devices` gives the UDIDs.

## Docs

| File | What's in it |
|---|---|
| `LAUNCH.md` | v1 scope, what's left before submission, the later list |
| `docs/FLOWS.md` | Every user flow and what it writes |
| `docs/ARCHITECTURE.md` | Code structure and data model |
| `docs/DECISIONS.md` | Non obvious decisions and why |
| `docs/LISTING.md` | App Store listing, in-app purchase and review notes |
| `docs/PRIVACY.md` | Privacy policy source |
| `CLAUDE.md` | Product rules and conventions for working on the code |
| `PLAN.md`, `BLUEPRINT.md` | Original product plan and market research |
