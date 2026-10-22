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

        XCTAssertTrue(app.staticTexts["Your saved history could not be opened"].waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.staticTexts["Roughly how many, in a day?"].waitForExistence(timeout: 5))
        let spend = app.textFields["Optional"]
        XCTAssertTrue(spend.waitForExistence(timeout: 5))
        spend.tap()
        spend.typeText("2000")
        app.staticTexts["Roughly how many, in a day?"].tap()   // dismiss the keyboard
        snap("02 onboarding amount, pouches")
        tap(app, "Continue")   // when
        tap(app, "Continue")   // why
        tap(app, "Continue")   // ready
        snap("03 onboarding ready")
        tap(app, "Start")

        // Home.
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "craving")).firstMatch.waitForExistence(timeout: 5))
        snap("04 home")

        // A craving that passes.
        tap(app, "craving")
        sleep(2)
        snap("05 craving")
        tap(app, "It passed")
        snap("06 craving passed")
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
        let sheetGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: save)
        wait(for: [sheetGone], timeout: 5)

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
