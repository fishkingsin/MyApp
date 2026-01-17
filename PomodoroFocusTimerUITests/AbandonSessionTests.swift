//
//  AbandonSessionTests.swift
//  PomodoroFocusTimerUITests
//
//  Created by Claude on 16/1/2026.
//

import XCTest

final class AbandonSessionTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // T058: Write UI test for abandon session flow
    func testAbandonSessionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Start a session
        app.tabBars.buttons["Focus"].tap()
        let startButton = app.buttons["Start Session"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Wait for timer to appear
        let timerDisplay = app.staticTexts.matching(identifier: "CountdownDisplay").firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2))

        // Tap Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))
        cancelButton.tap()

        // Verify confirmation dialog appears
        let confirmDialog = app.alerts.firstMatch
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 2))

        // Tap "Yes, Quit"
        let quitButton = app.buttons["Yes, Quit"]
        XCTAssertTrue(quitButton.exists)
        quitButton.tap()

        // Verify back to start screen
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
    }

    // T059: Write UI test for cancel dialog dismissal
    func testCancelDialogDismissal() throws {
        let app = XCUIApplication()
        app.launch()

        // Start a session
        app.tabBars.buttons["Focus"].tap()
        let startButton = app.buttons["Start Session"]
        startButton.tap()

        // Wait for timer
        let timerDisplay = app.staticTexts.matching(identifier: "CountdownDisplay").firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2))

        // Tap Cancel
        app.buttons["Cancel"].tap()

        // Verify confirmation dialog
        let confirmDialog = app.alerts.firstMatch
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 2))

        // Tap "No, Keep Going"
        let keepGoingButton = app.buttons["No, Keep Going"]
        XCTAssertTrue(keepGoingButton.exists)
        keepGoingButton.tap()

        // Verify session continues (timer still visible)
        XCTAssertTrue(timerDisplay.exists)
    }
}
