//
//  PauseResumeTests.swift
//  PomodoroFocusTimerUITests
//
//  Created by Claude on 16/1/2026.
//

import XCTest

final class PauseResumeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // T046: Write UI test for pause/resume flow
    func testPauseResumeFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Focus tab
        app.tabBars.buttons["Focus"].tap()

        // Start a session
        let startButton = app.buttons["Start Session"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Verify timer is running
        let timerDisplay = app.staticTexts.matching(identifier: "CountdownDisplay").firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2))

        // Tap Pause button
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        pauseButton.tap()

        // Verify Resume button appears
        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 2))

        // Verify timer is frozen (not counting down)
        let pausedTime = timerDisplay.label
        sleep(2) // Wait 2 seconds
        XCTAssertEqual(timerDisplay.label, pausedTime, "Timer should be frozen when paused")

        // Tap Resume button
        resumeButton.tap()

        // Verify Pause button reappears
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))

        // Verify timer is counting down again
        let resumedTime = timerDisplay.label
        sleep(2) // Wait 2 seconds
        XCTAssertNotEqual(timerDisplay.label, resumedTime, "Timer should be counting down after resume")
    }
}
