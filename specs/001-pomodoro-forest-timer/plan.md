# Implementation Plan: Forest-Style Pomodoro Timer

**Branch**: `001-pomodoro-forest-timer` | **Date**: 2026-01-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-pomodoro-forest-timer/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a Forest-style Pomodoro focus app for iOS that allows users to plant virtual trees during 25-minute focus sessions. The app will use SwiftUI for UI, SwiftData for local persistence (iOS 17+), Combine for timer management, and UNUserNotificationCenter for local notifications. Sessions that complete successfully save a tree to the user's forest; abandoned sessions "kill" the tree. The app includes pause/resume functionality, background-accurate timing, a forest grid view, and statistics (total trees, total focus time, today's count, daily streak). All features are offline-first with no network dependencies.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 17.0+ required for SwiftData)
**Primary Dependencies**: SwiftUI, SwiftData, Combine, UNUserNotificationCenter (all Apple frameworks)
**Storage**: SwiftData (iOS 17+ native persistence layer built on CoreData)
**Testing**: Swift Testing framework (`import Testing`) for unit tests, XCTest/XCUITest for UI tests
**Target Platform**: iOS 17.0+ (iPhone and iPad)
**Project Type**: Mobile (native iOS app)
**Performance Goals**: 60fps smooth animations for tree growth; <2s cold start; ~50MB memory during active sessions
**Constraints**: Offline-only (no network), background-accurate timing (±5s over 25min), 100+ trees in forest grid without frame drops
**Scale/Scope**: Single-user local app; ~5-10 screens (start session, active timer, forest view, stats); 20+ sessions/day supported without degradation

**Key Technical Decisions**:
- **SwiftData vs CoreData**: SwiftData chosen for modern Swift-native API and reduced boilerplate (iOS 17+ only)
- **Combine Timer**: Use Combine's `Timer.publish(every:)` for precise timer updates; recalculate elapsed time from stored start timestamp on app resume to ensure background accuracy
- **Notification Permissions**: Handle denial gracefully (show in-app completion message if notifications unavailable)
- **Memory Management**: NEEDS CLARIFICATION - Best practices for keeping forest grid performant with 100+ trees in LazyVGrid
- **Timer Architecture**: NEEDS CLARIFICATION - How to ensure timer continues accurately when app is backgrounded/killed (background task? scheduled local notification?)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Radical Simplicity & Offline-First
**Status**: ✅ PASS

- No network requests or external services (offline-only requirement met)
- No user accounts or cloud sync (local SwiftData storage only)
- Uses only Apple frameworks (SwiftUI, SwiftData, Combine, UNUserNotificationCenter)
- Minimal UI with native SwiftUI components (no custom chrome)
- Fixed 25-minute sessions (no configuration complexity)
- Single tree type (no customization creep)

### Principle II: Test-First Development (TDD)
**Status**: ✅ PASS (Workflow Gate)

- Plan includes Swift Testing for unit tests and XCTest for UI tests
- TDD workflow will be enforced during implementation (tests written before code)
- All acceptance scenarios in spec are testable
- Coverage targets: timer logic, session state transitions, stats calculations, background timing accuracy

### Principle III: 60fps Performance
**Status**: ⚠️ NEEDS VALIDATION (Post-Implementation)

- Tree growth animations must profile at 60fps (5 stages, smooth transitions)
- Forest grid must use LazyVGrid for 100+ trees
- Main thread must not block during timer updates
- **Action Required**: Profile with Instruments Core Animation after animation implementation
- **Risk**: Complex tree growth animations or heavy forest grid rendering could drop frames

### Principle IV: Cold Start Performance (<2s)
**Status**: ⚠️ NEEDS VALIDATION (Post-Implementation)

- SwiftData model loading must be deferred or optimized
- Lazy loading for forest grid (only render visible trees)
- Minimal work in @main app initialization
- **Action Required**: Measure with Instruments App Launch on iPhone 12 or equivalent
- **Risk**: SwiftData initialization or large forest data loading could exceed 2s

### Principle V: Accessibility (VoiceOver & Dynamic Type)
**Status**: ✅ PASS (Workflow Gate)

- All interactive elements (Start, Pause, Resume, Cancel buttons) will have accessibility labels
- Timer countdown will be announced by VoiceOver
- Forest grid and stats will be navigable via VoiceOver
- All text will use Dynamic Type (.body, .title, etc.)
- **Action Required**: Validate with VoiceOver and Accessibility Inspector during implementation

### Performance Benchmarks Gate
**Status**: ⚠️ DEFERRED (Post-Implementation)

| Metric | Target | Status |
|--------|--------|--------|
| Cold Start | <2s | To be measured with Instruments |
| Animation Framerate | 60fps | To be profiled for tree growth and forest grid |
| View Render Time | <16ms | To be profiled for active timer view |
| Memory Usage (Idle) | <50MB | To be measured with Instruments Allocations |
| Battery Impact | Low | To be measured with Xcode Energy Gauge |

**Verdict**: PASS with post-implementation validation required for performance metrics. No constitution violations. All principles are satisfied by the planned architecture.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
MyApp/
├── MyApp/                           # Main application target
│   ├── MyAppApp.swift              # App entry point (@main) - SwiftData container setup
│   ├── ContentView.swift           # Root view - navigation coordinator
│   ├── Models/                     # SwiftData models
│   │   ├── Session.swift           # @Model for focus sessions (completed/abandoned)
│   │   ├── CompletedTree.swift     # @Model for saved trees in forest
│   │   └── DailyStats.swift        # Computed stats (derived from sessions)
│   ├── Services/                   # Business logic services
│   │   ├── TimerService.swift      # Combine-based timer, background timing logic
│   │   ├── NotificationService.swift # UNUserNotificationCenter wrapper
│   │   └── SessionManager.swift    # Session state machine (start/pause/resume/cancel/complete)
│   ├── Views/                      # SwiftUI views
│   │   ├── StartSessionView.swift  # Initial screen (start button)
│   │   ├── ActiveTimerView.swift   # Timer countdown + tree growth animation
│   │   ├── ForestView.swift        # Forest grid (LazyVGrid of completed trees)
│   │   ├── StatsView.swift         # Statistics display
│   │   └── Components/             # Reusable UI components
│   │       ├── TreeVisualization.swift # Tree growth stages (5 stages)
│   │       └── CountdownDisplay.swift  # MM:SS timer display
│   └── Assets.xcassets/            # Tree stage images, app icon
│
├── MyAppTests/                     # Unit tests (Swift Testing framework)
│   ├── TimerServiceTests.swift     # Timer logic, background accuracy
│   ├── SessionManagerTests.swift   # State machine transitions
│   ├── StatsCalculationTests.swift # Streak, total time, today's count
│   └── ModelTests.swift            # SwiftData model validation
│
└── MyAppUITests/                   # UI tests (XCTest/XCUITest)
    ├── SessionFlowTests.swift      # Complete session end-to-end
    ├── PauseResumeTests.swift      # Pause/resume interactions
    ├── AbandonSessionTests.swift   # Cancel confirmation dialog
    └── ForestViewTests.swift       # Forest grid rendering, stats display
```

**Structure Decision**: iOS mobile app structure selected. The existing MyApp Xcode project will be extended with new Models, Services, and Views directories. SwiftData models will be added to a Models/ directory, business logic services (timer, notifications, session management) to Services/, and SwiftUI views to Views/. The app follows standard iOS MVVM-like architecture with SwiftUI + SwiftData. Tests are organized into unit tests (Swift Testing for logic) and UI tests (XCTest for end-to-end flows).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
