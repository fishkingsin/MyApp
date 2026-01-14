# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyApp is a native iOS application built with SwiftUI. This is a standard Xcode-based project with a clean SwiftUI architecture.

## Project Structure

```
MyApp/
├── MyApp/                    # Main application source
│   ├── MyAppApp.swift       # App entry point (@main)
│   ├── ContentView.swift    # Root view
│   └── Assets.xcassets/     # Image and color assets
├── MyAppTests/              # Unit tests (Swift Testing framework)
└── MyAppUITests/            # UI tests (XCTest framework)
```

## Building and Running

This is an Xcode project. Use Xcode or xcodebuild for all operations:

```bash
# Build the project
xcodebuild -project MyApp.xcodeproj -scheme MyApp -configuration Debug build

# Run on simulator
# Open in Xcode and use Cmd+R, or:
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project MyApp.xcodeproj -scheme MyApp clean
```

## Testing

The project uses two testing frameworks:
- **Swift Testing** (`import Testing`) for unit tests in `MyAppTests/`
- **XCTest** for UI tests in `MyAppUITests/`

```bash
# Run all tests
xcodebuild test -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MyAppTests

# Run only UI tests
xcodebuild test -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MyAppUITests

# Run a specific test
xcodebuild test -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MyAppTests/MyAppTests/example
```

## Architecture

- **Entry Point**: `MyAppApp.swift` contains the `@main` app struct with a WindowGroup scene
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
