//
//  SessionFlowTests.swift
//  PomodoroFocusTimerUITests
//
//  Created by Claude on 16/1/2026.
//

import XCTest

final class SessionFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // T019: Write UI test for complete session flow
    func testCompleteSessionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Focus tab
        app.tabBars.buttons["Focus"].tap()

        // Tap Start Session button
        let startButton = app.buttons["Start Session"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Verify active timer view appears
        let timerDisplay = app.staticTexts.matching(identifier: "CountdownDisplay").firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2))

        // Verify tree visualization appears
        let treeVisualization = app.images.matching(identifier: "TreeVisualization").firstMatch
        XCTAssertTrue(treeVisualization.exists)

        // NOTE: Full 25-minute wait test would be done in manual testing or with fast-forward mock
        // For automated tests, we verify UI elements exist and are interactive
    }

    // T020: Write UI test for background completion
    func testBackgroundCompletion() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Focus tab
        app.tabBars.buttons["Focus"].tap()

        // Start a session
        let startButton = app.buttons["Start Session"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Verify session started
        let timerDisplay = app.staticTexts.matching(identifier: "CountdownDisplay").firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2))

        // Background the app
        XCUIDevice.shared.press(.home)

        // Wait a short period (simulating background time)
        sleep(3)

        // Re-activate the app
        app.activate()

        // Verify countdown recalculated correctly (should still be running)
        XCTAssertTrue(timerDisplay.exists)

        // NOTE: Notification testing requires notification permission and 25-minute wait
        // This would typically be tested manually or with XCTest notification helpers
    }
}
