# Quick Start Guide: Forest-Style Pomodoro Timer

**Feature**: Forest-Style Pomodoro Timer
**Branch**: `001-pomodoro-forest-timer`
**Date**: 2026-01-14

This guide provides a rapid overview of the architecture, key files, and implementation approach for the Forest-Style Pomodoro Timer feature.

---

## 🎯 Feature Overview

A native iOS app that gamifies focus sessions using a growing tree metaphor. Users start a 25-minute Pomodoro session, watch a tree grow through 5 stages, and save completed trees to their personal forest. Background timing ensures accuracy when app is locked/backgrounded. Stats track total trees, focus time, daily progress, and streaks.

**Tech Stack**: SwiftUI + SwiftData + Combine + UNUserNotificationCenter (iOS 17+)

---

## 🏗️ Architecture at a Glance

```
┌─────────────────────────────────────────────────────┐
│                   SwiftUI Views                      │
│  StartSessionView | ActiveTimerView | ForestView    │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              SessionManager (@Observable)            │
│  State Machine: idle → active ⇄ paused → idle       │
│  Coordinates: Timer | Notifications | Persistence    │
└─────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ TimerService │  │NotificationSvc│  │  SwiftData   │
│   (Combine)  │  │  (UNUserNot) │  │   Models     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 📁 Key Files and Responsibilities

### Models (SwiftData)

| File                  | Purpose                                       | Key Attributes                                      |
| --------------------- | --------------------------------------------- | --------------------------------------------------- |
| `Session.swift`       | Tracks focus sessions (completed & abandoned) | startedAt, completedAt, status, totalPausedDuration |
| `CompletedTree.swift` | Saved trees for completed sessions            | session (reference), completedAt                    |
| `DailyStats.swift`    | Computed stats (not persisted)                | totalTrees, focusTime, todayCount, streak           |

### Services (Business Logic)

| File                        | Purpose                             | Key Methods                                  |
| --------------------------- | ----------------------------------- | -------------------------------------------- |
| `SessionManager.swift`      | Session state machine & coordinator | start(), pause(), resume(), cancel()         |
| `TimerService.swift`        | Combine timer for UI updates        | Not directly exposed; used by SessionManager |
| `NotificationService.swift` | Local notification scheduling       | schedule(), cancel(), reschedule()           |

### Views (SwiftUI)

| File                                 | Purpose               | User Actions                                     |
| ------------------------------------ | --------------------- | ------------------------------------------------ |
| `StartSessionView.swift`             | Initial screen        | Tap "Start Session" button                       |
| `ActiveTimerView.swift`              | Active timer screen   | View countdown, tree growth, pause/resume/cancel |
| `ForestView.swift`                   | Completed trees grid  | Scroll through LazyVGrid of trees                |
| `StatsView.swift`                    | Statistics display    | View total trees, focus time, streak             |
| `Components/TreeVisualization.swift` | Tree growth animation | Displays 1 of 5 tree stages based on progress    |
| `Components/CountdownDisplay.swift`  | MM:SS timer display   | Shows remaining time                             |

### Tests

| File                          | Purpose                                  |
| ----------------------------- | ---------------------------------------- |
| `SessionManagerTests.swift`   | Unit tests for state machine transitions |
| `StatsCalculationTests.swift` | Unit tests for streak and stats logic    |
| `SessionFlowTests.swift`      | UI tests for complete session end-to-end |
| `PauseResumeTests.swift`      | UI tests for pause/resume interactions   |

---

## 🔑 Key Design Decisions

### 1. Timestamp-Based Timing (Not Continuous Background Timer)

**Why**: iOS suspends apps in background, breaking traditional timers.

**How**:

- Store `sessionStartDate` when session starts
- On app resume: `elapsed = Date() - sessionStartDate - totalPausedDuration`
- Combine timer updates UI every 1 second, but elapsed time is recalculated from timestamps

**Implementation**:

```swift
// Timer is cosmetic (UI only)
let elapsed = Date().timeIntervalSince(session.startedAt) - session.totalPausedDuration
let remaining = (25 * 60) - elapsed
```

### 2. Local Notifications for Background Completion

**Why**: App can't run continuous timers in background; notifications are Apple's recommended approach.

**How**:

- Schedule `UNTimeIntervalNotificationTrigger` for 25 minutes when session starts
- Cancel notification if session is abandoned or completed in foreground
- Reschedule with remaining time when paused/resumed

**Implementation**:

```swift
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 25 * 60, repeats: false)
let request = UNNotificationRequest(identifier: "session-complete-\(sessionID)", ...)
UNUserNotificationCenter.current().add(request)
```

### 3. SwiftData with @Observable for Reactive UI

**Why**: iOS 17+ @Observable macro provides cleaner reactive updates than @StateObject/@ObservedObject.

**How**:

- `SessionManager` is `@Observable`
- SwiftUI views observe `sessionState` and `remainingSeconds`
- SwiftData `@Query` provides reactive access to CompletedTree and Session data

**Implementation**:

```swift
@Observable
final class SessionManager {
    private(set) var sessionState: SessionState = .idle
    private(set) var remainingSeconds: Int = 0
}
```

### 4. LazyVGrid for Performant Forest Display

**Why**: 100+ trees would cause memory issues with standard VStack/Grid.

**How**:

- Use `LazyVGrid` to render only visible trees
- Store lightweight data (UUID references), not Image objects
- Load images on-demand in view rendering

**Implementation**:

```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
    ForEach(completedTrees) { tree in
        TreeVisualization(stage: 5) // Completed tree always stage 5
    }
}
```

### 5. Tree Growth via Discrete Stages (Not Custom Drawing)

**Why**: 5 pre-rendered images perform better than custom Shape drawing at 60fps.

**How**:

- Calculate stage from progress: `Int(progress / 0.25) + 1`
- Display corresponding SF Symbol or asset catalog image
- SwiftUI `.animation()` handles smooth transitions

**Implementation**:

```swift
var treeGrowthStage: Int {
    let progress = elapsed / totalDuration
    switch progress {
    case 0..<0.25: return 1
    case 0.25..<0.5: return 2
    case 0.5..<0.75: return 3
    case 0.75..<1.0: return 4
    default: return 5
    }
}
```

---

## 🚀 Implementation Workflow (TDD)

### Phase 1: Models and State Machine

**Test-First Approach**:

1. **Write Tests**:

   - `SessionManagerTests`: Test state transitions (idle → active → paused → active → completed)
   - `ModelTests`: Validate Session status transitions and CompletedTree creation

2. **Implement**:

   - `Session.swift` with SwiftData @Model
   - `CompletedTree.swift` with relationship to Session
   - `SessionManager.swift` with state machine logic

3. **Verify**:
   - All tests pass (green phase)
   - Profile with Instruments to ensure <50MB memory during active session

### Phase 2: Timer and Notifications

**Test-First Approach**:

1. **Write Tests**:

   - `TimerServiceTests`: Test background timing accuracy (±5 seconds over 25 minutes)
   - `NotificationServiceTests`: Test notification scheduling, cancellation, rescheduling

2. **Implement**:

   - `TimerService.swift` with Combine timer
   - `NotificationService.swift` with UNUserNotificationCenter
   - Integrate into SessionManager

3. **Verify**:
   - All tests pass
   - Manual test: Start session, background app for 10 minutes, return and verify countdown is accurate

### Phase 3: UI Views

**Test-First Approach**:

1. **Write Tests**:

   - `SessionFlowTests.swift` (XCUITest): End-to-end test starting and completing a session
   - `PauseResumeTests.swift` (XCUITest): Test pause/resume interactions

2. **Implement**:

   - `StartSessionView.swift`, `ActiveTimerView.swift`, `ForestView.swift`
   - `TreeVisualization.swift` and `CountdownDisplay.swift` components

3. **Verify**:
   - All UI tests pass
   - VoiceOver navigation works correctly
   - Dynamic Type scales text at Extra Large size
   - Profile with Instruments: 60fps animations, <2s cold start

### Phase 4: Stats and Forest Grid

**Test-First Approach**:

1. **Write Tests**:

   - `StatsCalculationTests.swift`: Test streak calculation, today's count, total focus time
   - `ForestViewTests.swift` (XCUITest): Test grid scrolling with 100+ trees

2. **Implement**:

   - `DailyStats.swift` and `StatsCalculator`
   - `StatsView.swift` with stats display
   - Optimize `ForestView.swift` with LazyVGrid

3. **Verify**:
   - All tests pass
   - Performance test: Create 100 trees, verify grid scrolls at 60fps

---

## ⚡ Performance Checklist

| Metric                     | Target         | How to Measure             | Mitigation if Failed                       |
| -------------------------- | -------------- | -------------------------- | ------------------------------------------ |
| Cold Start                 | <2s            | Instruments App Launch     | Defer SwiftData loading, lazy-load forest  |
| Animation Framerate        | 60fps          | Instruments Core Animation | Reduce tree complexity, use simpler images |
| Memory (Active Session)    | <50MB          | Instruments Allocations    | Store Data instead of Image objects        |
| Forest Grid Scrolling      | 60fps          | Instruments Core Animation | Ensure LazyVGrid used, not VStack          |
| Background Timing Accuracy | ±5s over 25min | Manual test with stopwatch | Verify timestamp-based calculations        |

---

## 🧪 Testing Strategy

### Unit Tests (Swift Testing)

- **Models**: Validate SwiftData model relationships and state transitions
- **SessionManager**: Test state machine transitions (start, pause, resume, cancel, complete)
- **Stats**: Test streak calculation, today's count reset at midnight
- **Timer**: Test background timing accuracy with fast-forward simulation

### UI Tests (XCTest)

- **Happy Path**: Start session → wait 25 minutes → verify tree saved to forest
- **Pause/Resume**: Start → pause → resume → complete
- **Abandon**: Start → cancel → confirm dialog → verify no tree saved
- **Background Completion**: Start → background app → notification fires → tree saved
- **Forest Grid**: Scroll through 100+ trees without frame drops

### Accessibility Tests

- **VoiceOver**: Navigate all screens with VoiceOver enabled
- **Dynamic Type**: Test UI at Extra Large text size
- **Contrast**: Verify color contrast meets WCAG AA standards

---

## 📦 Dependencies

**Apple Frameworks Only** (per constitution):

- SwiftUI (UI framework)
- SwiftData (persistence)
- Combine (timer updates)
- UserNotifications (UNUserNotificationCenter for local notifications)
- Foundation (Date, Calendar, UUID)

**No Third-Party Dependencies** ✅

---

## 🔄 Git Workflow

**Branch**: `001-pomodoro-forest-timer`

**Commit Strategy**:

1. Commit after each TDD cycle (test → implement → refactor)
2. Use descriptive commit messages referencing spec requirements (e.g., "Implement FR-004: Pause session state transition")
3. Run all tests before each commit
4. Profile performance before final PR

**Pull Request**:

- Title: "Feature: Forest-Style Pomodoro Timer"
- Description: Link to spec.md, summarize implementation approach, include test results and performance metrics

---

## 🎓 Developer Onboarding

**New to Project? Start Here**:

1. Read `spec.md` for full requirements and acceptance criteria
2. Read `plan.md` (this is Phase 1 output, including Technical Context and Constitution Check)
3. Read `research.md` for technical decisions and alternatives considered
4. Read `data-model.md` for entity relationships and validation rules
5. Read `contracts/` for NotificationService and SessionManager interfaces
6. Read `CLAUDE.md` (project root) for build/test commands and project structure

**Run Your First Session**:

1. Build: `xcodebuild -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer build`
2. Test: `xcodebuild test -project PomodoroFocusTimer.xcodeproj -scheme PomodoroFocusTimer -destination 'platform=iOS Simulator,name=iPhone 15'`
3. Launch Xcode: Open `PomodoroFocusTimer.xcodeproj` and run on simulator (Cmd+R)
4. Start a session, background the app for 25 minutes (or fast-forward in debug mode), verify notification and tree save

---

## 🐛 Common Pitfalls

| Issue                            | Cause                                  | Solution                                                  |
| -------------------------------- | -------------------------------------- | --------------------------------------------------------- |
| Timer drifts when backgrounded   | Using Combine timer as source of truth | Recalculate from timestamps on scenePhase change          |
| Notification doesn't fire        | Permission denied                      | Check authorization status, handle denial gracefully      |
| Forest grid lags with 100+ trees | Using VStack instead of LazyVGrid      | Use LazyVGrid for lazy rendering                          |
| Cold start exceeds 2s            | Loading all SwiftData models at launch | Defer forest loading until ForestView is displayed        |
| Streak calculation off by one    | Time zone or day boundary bug          | Use Calendar.startOfDay(for:) for consistent day grouping |
| Tree growth animation janky      | Complex custom drawing or large images | Use small SF Symbols or optimized PNG assets              |

---

## 📚 Additional Resources

**Design Artifacts** (this feature):

- `spec.md`: Full feature specification with acceptance criteria
- `plan.md`: Technical context and constitution compliance check
- `research.md`: Research findings for technical unknowns
- `data-model.md`: Entity definitions, relationships, validation rules
- `contracts/`: Notification and session state machine contracts

**Project Documentation** (repository root):

- `CLAUDE.md`: Build commands, testing, project structure
- `.specify/memory/constitution.md`: Project principles (simplicity, TDD, 60fps, <2s launch, accessibility)

**Apple Documentation**:

- [SwiftData Overview](https://developer.apple.com/documentation/swiftdata)
- [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [SwiftUI Performance](https://developer.apple.com/documentation/swiftui/performance)

---

## ✅ Ready to Implement

You now have:

- ✅ Clear architecture and file structure
- ✅ Timestamp-based timing strategy for background accuracy
- ✅ Local notification approach for background completion
- ✅ SwiftData models with validation rules
- ✅ SessionManager state machine contract
- ✅ TDD workflow with unit and UI test targets
- ✅ Performance targets and measurement approach
- ✅ Constitution compliance (simplicity, offline-first, 60fps, <2s launch, accessibility)

**Next Step**: Run `/speckit.tasks` to generate actionable tasks from this plan, or begin implementation with TDD (tests first, then code).
