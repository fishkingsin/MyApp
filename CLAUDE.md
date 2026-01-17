# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PomodoroFocusTimer is a native iOS application built with SwiftUI. This is a standard Xcode-based project with a clean SwiftUI architecture.

## Project Structure

```
PomodoroFocusTimer/
├── PomodoroFocusTimer/                    # Main application source
│   ├── PomodoroFocusTimerApp.swift       # App entry point (@main)
│   ├── ContentView.swift    # Root view
│   └── Assets.xcassets/     # Image and color assets
├── PomodoroFocusTimerTests/              # Unit tests (Swift Testing framework)
└── PomodoroFocusTimerUITests/            # UI tests (XCTest framework)
```

## Building and Running

This is an Xcode project. Use Xcode or xcodebuild for all operations:

```bash
# Build the project
xcodebuild -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -configuration Debug build

# Run on simulator
# Open in Xcode and use Cmd+R, or:
xcodebuild -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer clean
```

## Testing

The project uses two testing frameworks:

- **Swift Testing** (`import Testing`) for unit tests in `PomodoroFocusTimerTests/`
- **XCTest** for UI tests in `PomodoroFocusTimerUITests/`

```bash
# Run all tests
xcodebuild test -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PomodoroFocusTimerTests

# Run only UI tests
xcodebuild test -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PomodoroFocusTimerUITests

# Run a specific test
xcodebuild test -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PomodoroFocusTimerTests/PomodoroFocusTimerTests/example
```

## Architecture

- **Entry Point**: `PomodoroFocusTimerApp.swift` contains the `@main` app struct with a WindowGroup scene
- **Root View**: `ContentView.swift` is the primary view loaded by the app
- **UI Framework**: SwiftUI is used throughout for declarative UI
- **Testing Strategy**:
  - Unit tests use the modern Swift Testing framework with `@Test` macros
  - UI tests use XCTest with `XCUIApplication` for end-to-end testing

## Development Notes

- This is a standard Xcode project (not Swift Package Manager)
- When adding new Swift files, ensure they're added to the correct target in Xcode
- SwiftUI Previews are available using `#Preview` macros
- The project uses standard SwiftUI lifecycle (no UIKit AppDelegate/SceneDelegate)

## Active Technologies

- Swift 5.9+ (iOS 17.0+ required for SwiftData) + SwiftUI, SwiftData, Combine, UNUserNotificationCenter (all Apple frameworks) (001-pomodoro-forest-timer)
- SwiftData (iOS 17+ native persistence layer built on CoreData) (001-pomodoro-forest-timer)

## Recent Changes

- 001-pomodoro-forest-timer: Added Swift 5.9+ (iOS 17.0+ required for SwiftData) + SwiftUI, SwiftData, Combine, UNUserNotificationCenter (all Apple frameworks)
