//
//  FurnitureFinderUITestsLaunchTests.swift
//  FurnitureFinderUITests
//
//  Created by Daniel Shin on 6/23/25.
//

import XCTest

final class FurnitureFinderUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        // Mark this run so the app can skip non-essential work during UI tests
        app.launchArguments += ["-UITests"]

        // Measure cold launch time explicitly
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }

        // Take a screenshot after launch
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
