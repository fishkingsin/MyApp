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
- **Memory Management**: Use LazyVGrid with lightweight data types (Data/UUID references, not Image objects) to maintain <50MB memory with 100+ trees. Elevate state management to top-level views. (Resolved via research.md)
- **Timer Architecture**: Timestamp-based elapsed time calculation + scheduled local notifications. Combine timer for UI updates only (cosmetic). Recalculate progress on app foreground to ensure ±5s accuracy over 25 minutes. (Resolved via research.md)

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

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

| Metric              | Target | Status                                         |
| ------------------- | ------ | ---------------------------------------------- |
| Cold Start          | <2s    | To be measured with Instruments                |
| Animation Framerate | 60fps  | To be profiled for tree growth and forest grid |
| View Render Time    | <16ms  | To be profiled for active timer view           |
| Memory Usage (Idle) | <50MB  | To be measured with Instruments Allocations    |
| Battery Impact      | Low    | To be measured with Xcode Energy Gauge         |

**Verdict**: PASS with post-implementation validation required for performance metrics. No constitution violations. All principles are satisfied by the planned architecture.

---

### Post-Design Re-Evaluation

_Re-checked after completing Phase 1 design artifacts (data-model.md, contracts/, quickstart.md)_

#### Principle I: Radical Simplicity & Offline-First

**Status**: ✅ PASS (Confirmed)

**Design Validation**:

- Architecture uses 3 SwiftData models (Session, CompletedTree, DailyStats computed), 3 services (SessionManager, TimerService, NotificationService), and 4 main views (Start, ActiveTimer, Forest, Stats)
- No additional complexity introduced during design phase
- All NEEDS CLARIFICATION items resolved without adding external dependencies
- Timestamp-based timing approach avoids complex background task infrastructure
- LazyVGrid approach requires no custom collection types or pagination logic for 100 trees (may need for 200+, but deferred)

**Complexity Tracking**: No violations. Design remains radically simple with minimal abstractions.

#### Principle II: Test-First Development (TDD)

**Status**: ✅ PASS (Confirmed)

**Design Validation**:

- Contracts define clear interfaces for SessionManager state machine and NotificationService
- All state transitions documented with preconditions/postconditions (testable)
- Test cases specified in data-model.md validation section
- UI test scenarios mapped to acceptance criteria in spec.md
- SessionManager is @Observable with observable state (easy to test in isolation)

**TDD Readiness**: 100%. All components have well-defined contracts and test cases ready to write.

#### Principle III: 60fps Performance

**Status**: ✅ PASS (Design Mitigates Risks)

**Design Validation**:

- Tree growth uses 5 discrete image stages (not custom drawing) → minimal rendering overhead
- SwiftUI `.animation()` for stage transitions (native, optimized)
- LazyVGrid confirmed for forest view → only renders visible trees
- Data model stores lightweight references (UUID, Date) not Image objects → <50MB memory feasible
- Combine timer runs on main thread but only updates Int counter every 1s → <1ms per update (well under 16ms budget)
- No heavy computation in view bodies (all calculations in SessionManager)

**Risk Mitigation**:

- Research.md documents best practices: store Data/UUID not Image, use LazyVGrid, elevate state management
- Performance profiling required post-implementation, but design choices minimize risk

**Updated Assessment**: Low risk of 60fps violations. Design follows performance best practices.

#### Principle IV: Cold Start Performance (<2s)

**Status**: ✅ PASS (Design Mitigates Risks)

**Design Validation**:

- SwiftData initialization: Lightweight models (3 entities, minimal relationships)
- @main app: Only configures ModelContainer and NotificationService → <100ms
- Forest view uses LazyVGrid → trees loaded on-demand, not at app launch
- No preloading of historical data (DailyStats computed on-demand when stats view displayed)
- ContentView is minimal navigation coordinator → fast initial render

**Startup Sequence**:

1. App launch → ModelContainer setup (<50ms)
2. ContentView render → Shows StartSessionView (static UI, no data loading)
3. User taps "Start Session" → SessionManager.start() (creates single Session record)

**Risk Mitigation**:

- Forest data not loaded until user navigates to ForestView (deferred)
- No queries executed at launch (all via @Query in views, lazy)

**Updated Assessment**: Very low risk of exceeding 2s. App launches to static StartSessionView with no data dependencies.

#### Principle V: Accessibility (VoiceOver & Dynamic Type)

**Status**: ✅ PASS (Design Supports)

**Design Validation**:

- All views use native SwiftUI components (Button, Text, LazyVGrid) with built-in accessibility
- Countdown display will use `.accessibilityLabel("\(minutes) minutes \(seconds) seconds remaining")`
- Tree growth stages use SF Symbols or images with `.accessibilityLabel("Tree growth stage \(stage) of 5")`
- Forest grid items will have `.accessibilityLabel("Completed tree from \(formattedDate)")`
- All text uses Dynamic Type (.body, .title, .caption) per design

**Test Plan**:

- VoiceOver navigation test script in contracts/session-state-contract.md
- Dynamic Type test cases in quickstart.md

**Updated Assessment**: Design fully supports accessibility. Native SwiftUI components handle most requirements automatically.

#### Performance Benchmarks Gate

**Status**: ✅ DESIGN READY (Measurement Post-Implementation)

**Design Confidence Levels**:

| Metric              | Target | Design Confidence | Justification                                                |
| ------------------- | ------ | ----------------- | ------------------------------------------------------------ |
| Cold Start          | <2s    | HIGH              | No data loading at launch; static StartSessionView           |
| Animation Framerate | 60fps  | HIGH              | Discrete image stages, no custom drawing, LazyVGrid          |
| View Render Time    | <16ms  | HIGH              | Minimal view hierarchy, no heavy computation in bodies       |
| Memory Usage (Idle) | <50MB  | MEDIUM            | LazyVGrid + lightweight data types, but needs profiling      |
| Battery Impact      | Low    | HIGH              | No continuous background work, timer only runs in foreground |

**Measurement Plan**:

- Instruments profiling required post-implementation for actual metrics
- Design choices maximize likelihood of meeting all targets

#### Final Verdict

**Status**: ✅ PASS (Post-Design)

**Summary**:

- All 5 constitution principles satisfied by design
- NEEDS CLARIFICATION items from Technical Context resolved via research.md
- No complexity violations introduced during design phase
- Architecture remains simple, testable, performant, and accessible
- Performance risks mitigated through design choices (LazyVGrid, discrete image stages, deferred loading)
- Ready to proceed to Phase 2 (task generation) and implementation

**Compliance Notes**:

- Memory management clarified: Use LazyVGrid, store lightweight data types, elevate state
- Timer architecture clarified: Timestamp-based calculations + local notifications, Combine timer for UI only
- No new dependencies added (remains Apple frameworks only)
- No feature creep (fixed 25-minute sessions, single tree type, offline-only)

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
PomodoroFocusTimer/
├── PomodoroFocusTimer/                           # Main application target
│   ├── PomodoroFocusTimerApp.swift              # App entry point (@main) - SwiftData container setup
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
├── PomodoroFocusTimerTests/                     # Unit tests (Swift Testing framework)
│   ├── TimerServiceTests.swift     # Timer logic, background accuracy
│   ├── SessionManagerTests.swift   # State machine transitions
│   ├── StatsCalculationTests.swift # Streak, total time, today's count
│   └── ModelTests.swift            # SwiftData model validation
│
└── PomodoroFocusTimerUITests/                   # UI tests (XCTest/XCUITest)
    ├── SessionFlowTests.swift      # Complete session end-to-end
    ├── PauseResumeTests.swift      # Pause/resume interactions
    ├── AbandonSessionTests.swift   # Cancel confirmation dialog
    └── ForestViewTests.swift       # Forest grid rendering, stats display
```

**Structure Decision**: iOS mobile app structure selected. The existing PomodoroFocusTimer Xcode project will be extended with new Models, Services, and Views directories. SwiftData models will be added to a Models/ directory, business logic services (timer, notifications, session management) to Services/, and SwiftUI views to Views/. The app follows standard iOS MVVM-like architecture with SwiftUI + SwiftData. Tests are organized into unit tests (Swift Testing for logic) and UI tests (XCTest for end-to-end flows).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |
