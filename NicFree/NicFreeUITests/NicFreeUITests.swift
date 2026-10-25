//
//  NicFreeUITests.swift
//  NicFreeUITests
//

import XCTest

/// Walks the whole first run as a nicotine pouch user, then the screens that follow.
/// Screenshots are attached to the result bundle so the design can be reviewed without
/// tapping through by hand.
final class NicFreeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // The launch tests rotate the device and leave it that way.
        XCUIDevice.shared.orientation = .portrait
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// iPhone shows tabs in a bottom tab bar; iPad shows them as buttons in a top bar.
    private func openTab(_ app: XCUIApplication, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let inTabBar = app.tabBars.buttons[name]
        let button = inTabBar.exists ? inTabBar : app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "No tab named \(name)", file: file, line: line)
        button.tap()
    }

    private func tap(_ app: XCUIApplication, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "No button labelled \(label)", file: file, line: line)
        button.tap()
    }

    /// A store that will not open must say so, not fall silently into onboarding.
    @MainActor
    func testDamagedStoreIsExplained() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStoreForUITests", "-simulateDamagedStore"]
        app.launch()

        XCTAssertTrue(app.staticTexts["We couldn’t open your saved history"].waitForExistence(timeout: 5))
        snap("00 damaged store")
        tap(app, "Carry on without saving")
        XCTAssertTrue(app.staticTexts["What do you use?"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPouchUserFirstRun() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStoreForUITests"]
        app.launch()
        try firstRun(app)
    }

    /// Back after three days away: the app asks about them once, and a picked day becomes
    /// a slip that the total reflects.
    @MainActor
    func testCatchUpAfterTimeAway() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seedScreenshotData", "-simulateAwayForUITests"]
        app.launch()

        let question = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Any nicotine since")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        snap("Catch-up 01 question")
        let total = app.descendants(matching: .any)["Free days, all time"]
        XCTAssertEqual(total.value as? String, "63")

        tap(app, "Yes, on some days")
        let firstDay = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "^[A-Za-z]{2,4}\\.? ?[0-9]{1,2}$")).firstMatch
        XCTAssertTrue(firstDay.waitForExistence(timeout: 3), "Expected day chips")
        firstDay.tap()
        snap("Catch-up 02 days")
        tap(app, "Save")

        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: question)
        wait(for: [gone], timeout: 5)
        XCTAssertEqual(total.value as? String, "62")
    }

    /// A finished free day is celebrated once, then Home is back.
    @MainActor
    func testFreeDayCelebration() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seedScreenshotData", "-celebrateForUITests"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Another free day!"].waitForExistence(timeout: 10))
        sleep(2)
        snap("Celebration 01 free day")
        tap(app, "Yay!")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "craving")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Another free day!"].exists)
    }

    @MainActor
    func testMilestoneCelebration() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seedScreenshotData", "-celebrateMilestoneForUITests"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Two months free!"].waitForExistence(timeout: 10))
        sleep(2)
        snap("Celebration 02 milestone")
        tap(app, "Yay!")
    }

    /// The unlocked History: the month grid, then the chart, which answers a drag with that day.
    @MainActor
    func testHistoryChartIsTouchable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seedScreenshotData", "-unlockForScreenshots"]
        app.launch()

        openTab(app, "History")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        snap("History 01 grid")

        let hint = app.staticTexts["So far. Touch the chart to look back."]
        for _ in 0..<6 where !hint.isHittable { app.swipeUp() }
        XCTAssertTrue(hint.exists)
        snap("History 02 chart")

        let chart = app.otherElements["Total days free over time"].firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 3))
        let from = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        let to = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5))
        from.press(forDuration: 0.3, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.5)
        XCTAssertTrue(app.buttons["Back to today"].waitForExistence(timeout: 3), "A picked day stays picked")
        XCTAssertFalse(hint.exists)
        snap("History 03 chart dragged")
        tap(app, "Back to today")
        XCTAssertTrue(hint.waitForExistence(timeout: 3))
    }

    /// The same walk in dark mode, where contrast problems hide.
    @MainActor
    func testFirstRunInDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStoreForUITests", "-forceDarkForUITests"]
        app.launch()
        try firstRun(app, prefix: "Dark ")
    }

    /// The same walk at the largest accessibility text size, where layouts break first.
    @MainActor
    func testFirstRunAtLargestText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStoreForUITests", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        try firstRun(app, prefix: "XXXL ")
    }

    @MainActor
    private func firstRun(_ app: XCUIApplication, prefix: String = "") throws {
        let snap: (String) -> Void = { self.snap(prefix + $0) }

        // Onboarding offers pouches, not only vaping.
        XCTAssertTrue(app.staticTexts["What do you use?"].waitForExistence(timeout: 5))
        snap("01 onboarding form")
        tap(app, "Nicotine pouches")
        tap(app, "Continue")

        XCTAssertTrue(app.staticTexts["Roughly how many pouches do you use in a day?"].waitForExistence(timeout: 5))
        let spend = app.textFields["Optional"]
        XCTAssertTrue(spend.waitForExistence(timeout: 5))
        spend.tap()
        spend.typeText("2000")
        app.staticTexts["Roughly how many pouches do you use in a day?"].tap()   // dismiss the keyboard
        snap("02 onboarding amount, pouches")
        tap(app, "Continue")   // when
        tap(app, "Continue")   // why
        tap(app, "Continue")   // ready
        snap("03 onboarding ready")
        tap(app, "Let’s go!")

        // Home.
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "craving")).firstMatch.waitForExistence(timeout: 5))
        snap("04 home")

        // A craving that passes.
        tap(app, "craving")
        sleep(2)
        snap("05 craving")
        tap(app, "It passed")
        snap("06 craving passed")
        // A reason the list misses, in their own words.
        tap(app, "Something else")
        let own = app.textFields["What was it?"]
        XCTAssertTrue(own.waitForExistence(timeout: 3))
        own.typeText("Work emails\n")
        XCTAssertTrue(app.buttons["Work emails"].waitForExistence(timeout: 3), "A typed reason becomes a chip")
        XCTAssertTrue(app.buttons["Work emails"].isSelected)
        snap("06a own reason")
        tap(app, "Done")
        if app.buttons["Not now"].waitForExistence(timeout: 5) {
            snap("06b notification primer")
            app.buttons["Not now"].tap()
        }

        // A slip, once Home is back in front.
        let slipLink = app.buttons["Log a slip"]
        XCTAssertTrue(slipLink.waitForExistence(timeout: 5))
        let hittable = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: slipLink)
        wait(for: [hittable], timeout: 5)
        slipLink.tap()
        tap(app, "Just a little")
        snap("07 slip sheet")
        let save = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Save")).firstMatch
        XCTAssertTrue(save.isHittable, "Save must be reachable without scrolling")
        save.tap()
        XCTAssertTrue(app.staticTexts["Every free day you’ve already had is still there."].waitForExistence(timeout: 3))
        snap("07b slip saved")
        // The confirmation stays until they tap Done; it never vanishes on its own.
        sleep(2)
        XCTAssertTrue(app.staticTexts["Every free day you’ve already had is still there."].exists)
        let done = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Done")).firstMatch
        done.tap()
        let sheetGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: done)
        wait(for: [sheetGone], timeout: 5)

        // Logged by mistake: it can be removed, and the day is free again.
        let total = app.descendants(matching: .any)["Free days, all time"]
        let before = Int(total.value as? String ?? "") ?? -1
        tap(app, "Edit today's slip")
        tap(app, "Remove this slip")
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        snap("07c remove slip")
        app.alerts.buttons["Remove it"].tap()
        XCTAssertTrue(app.staticTexts["That day counts as a free day again."].waitForExistence(timeout: 3))
        tap(app, "Done")
        XCTAssertTrue(app.buttons["Log a slip"].waitForExistence(timeout: 5))
        XCTAssertEqual(Int(total.value as? String ?? ""), before + 1)

        // Tabs, each checked by what is on screen rather than trusted.
        openTab(app, "Path")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Your path")).firstMatch.waitForExistence(timeout: 3))
        snap("08 path")
        openTab(app, "History")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        snap("09 history")

        // Insights is the paid screen: locked, it offers the paywall once.
        openTab(app, "Insights")
        tap(app, "See what unlocks")
        XCTAssertTrue(app.staticTexts["Unlock NicFree"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Restore purchase"].exists, "Restore must be visible on the paywall")
        sleep(2)
        snap("09b paywall")
        tap(app, "Close")
        openTab(app, "Home")
        sleep(1)
        snap("10 home after a craving and a slip")
    }
}
