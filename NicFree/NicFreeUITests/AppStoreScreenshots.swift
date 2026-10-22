//
//  AppStoreScreenshots.swift
//  NicFreeUITests
//

import XCTest

/// Captures the App Store screenshots in listing order, on believable data, unlocked, in
/// US English. Skipped in normal runs; `tools/screenshots.sh` turns it on.
final class AppStoreScreenshots: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SCREENSHOTS"] == "1",
            "Run through tools/screenshots.sh"
        )
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func button(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
    }

    private func openTab(_ app: XCUIApplication, _ name: String) {
        let inTabBar = app.tabBars.buttons[name]
        (inTabBar.exists ? inTabBar : app.buttons[name].firstMatch).tap()
    }

    @MainActor
    func testCaptureListingScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-seedScreenshotData", "-unlockForScreenshots",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()

        // 1. Home: the free days, the sprout, the next milestone.
        XCTAssertTrue(button(app, "craving").waitForExistence(timeout: 10))
        sleep(1)
        shot("01-home")

        // 2. A craving: breathing, the timer, their own reason.
        button(app, "craving").tap()
        sleep(5)
        shot("02-craving")
        button(app, "It passed").tap()
        XCTAssertTrue(button(app, "Done").waitForExistence(timeout: 5))
        button(app, "Done").tap()
        if app.buttons["Not now"].waitForExistence(timeout: 5) { app.buttons["Not now"].tap() }

        // 3. The milestone path.
        XCTAssertTrue(button(app, "Log a slip").waitForExistence(timeout: 5))
        openTab(app, "Path")
        sleep(2)
        shot("03-path")

        // 4. Insights, unlocked.
        openTab(app, "Insights")
        sleep(2)
        shot("04-insights")

        // 5. History, unlocked: the year grid and the total over time.
        openTab(app, "History")
        sleep(2)
        shot("05-history")

        // 6. A slip, without shame: every free day already had is still there.
        openTab(app, "Home")
        XCTAssertTrue(button(app, "Log a slip").waitForExistence(timeout: 5))
        button(app, "Log a slip").tap()
        button(app, "Just a little").tap()
        button(app, "Save").tap()
        XCTAssertTrue(app.staticTexts["Every free day you’ve already had is still there."].waitForExistence(timeout: 3))
        shot("06-slip-unchanged")
    }
}
