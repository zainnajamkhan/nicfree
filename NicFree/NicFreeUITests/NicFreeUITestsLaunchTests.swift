//
//  NicFreeUITestsLaunchTests.swift
//  NicFreeUITests
//
//  Created by Zain Najam Khan on 14/08/2026.
//

import XCTest

final class NicFreeUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Runs once per appearance, light and dark, and keeps a screenshot of each.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshStoreForUITests"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
