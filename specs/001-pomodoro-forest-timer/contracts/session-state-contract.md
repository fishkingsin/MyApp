# Session State Machine Contract

**Feature**: Forest-Style Pomodoro Timer
**Service**: SessionManager
**Date**: 2026-01-14

This contract defines the state machine for focus sessions, including state transitions, timing calculations, and business logic for session lifecycle management.

## Overview

SessionManager is the single source of truth for active session state. It orchestrates:
- Session lifecycle (start, pause, resume, cancel, complete)
- Timer updates via Combine
- Background timing accuracy via timestamp-based calculations
- Integration with SwiftData persistence
- Coordination with NotificationService

---

## State Machine Definition

### States

```swift
enum SessionState: Equatable {
    case idle              // No active session
    case active(Session)   // Session in progress
    case paused(Session)   // Session temporarily paused
}
```

**Visual State Machine**:

```
        ┌──────┐
   ┌───→│ idle │←───────────────┐
   │    └──────┘                │
   │       │                    │
   │ start │                    │ cancel/complete
   │       │                    │
   │       ▼                    │
   │  ┌────────┐                │
   │  │ active │←──────┐        │
   │  └────────┘       │        │
   │       │           │ resume │
   │ pause │           │        │
   │       │           │        │
   │       ▼           │        │
   │  ┌────────┐       │        │
   └──│ paused │───────┴────────┘
      └────────┘
```

### State Transitions

| From | Action | To | Side Effects |
|------|--------|-----|--------------|
| idle | `start()` | active | Create Session, schedule notification, start Combine timer |
| active | `pause()` | paused | Store pausedAt timestamp, cancel notification, stop timer |
| paused | `resume()` | active | Accumulate pause duration, reschedule notification, restart timer |
| active | `cancel()` | idle | Mark session as abandoned, cancel notification, save to SwiftData |
| paused | `cancel()` | idle | Mark session as abandoned, cancel notification, save to SwiftData |
| active | `complete()` | idle | Mark session as completed, create CompletedTree, cancel notification, save to SwiftData |

**Invariants**:
- Only one active or paused session at a time (no concurrent sessions)
- Timer runs ONLY in active state
- Notification scheduled ONLY in active state
- Pause duration accumulates across multiple pause/resume cycles

---

## Interface Contract

### SessionManager Protocol

```swift
@MainActor
@Observable
final class SessionManager {
    // MARK: - Published State

    /// Current session state (observable by SwiftUI views)
    private(set) var sessionState: SessionState = .idle

    /// Remaining time in seconds (updates every second during active sessions)
    private(set) var remainingSeconds: Int = 0

    /// Current tree growth stage (0-5, derived from progress)
    var treeGrowthStage: Int {
        let totalDuration: TimeInterval = 25 * 60
        let elapsed = totalDuration - TimeInterval(remainingSeconds)
        let progress = elapsed / totalDuration

        // 5 stages: 0%, 25%, 50%, 75%, 100%
        switch progress {
        case 0..<0.25: return 1
        case 0.25..<0.5: return 2
        case 0.5..<0.75: return 3
        case 0.75..<1.0: return 4
        default: return 5
        }
    }

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let notificationService: NotificationService
    private var timerCancellable: AnyCancellable?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        notificationService: NotificationService = NotificationService()
    ) {
        self.modelContext = modelContext
        self.notificationService = notificationService
    }

    // MARK: - Public Interface

    /// Start a new 25-minute focus session
    func start() throws -> Session

    /// Pause the current active session
    func pause() throws

    /// Resume a paused session
    func resume() throws

    /// Cancel the current session (marks as abandoned)
    func cancel() throws

    /// Manually complete the session (called when timer reaches 0)
    private func complete(session: Session) throws

    /// Recalculate progress when app returns to foreground
    func recalculateProgress()
}
```

---

## Method Specifications

### 1. start()

**Preconditions**:
- `sessionState == .idle`

**Behavior**:
1. Create new Session with `startedAt = Date()`, `status = .inProgress`
2. Insert Session into modelContext
3. Schedule notification for 25 minutes
4. Start Combine timer (updates every 1 second)
5. Set `sessionState = .active(session)`
6. Set `remainingSeconds = 1500` (25 minutes)

**Postconditions**:
- Session persisted to SwiftData
- Notification scheduled
- Timer running
- `sessionState == .active`

**Error Conditions**:
- Throws `SessionError.sessionAlreadyActive` if called while session is active or paused

**Implementation**:

```swift
func start() throws -> Session {
    guard case .idle = sessionState else {
        throw SessionError.sessionAlreadyActive
    }

    let session = Session(
        startedAt: Date(),
        status: .inProgress
    )

    modelContext.insert(session)
    try modelContext.save()

    notificationService.scheduleSessionCompletionNotification(for: session)

    startTimer(for: session)

    sessionState = .active(session)
    remainingSeconds = 25 * 60

    return session
}
```

---

### 2. pause()

**Preconditions**:
- `sessionState == .active(session)`

**Behavior**:
1. Extract session from active state
2. Set `session.pausedAt = Date()`
3. Set `session.status = .paused`
4. Save to modelContext
5. Cancel notification
6. Stop Combine timer
7. Set `sessionState = .paused(session)`
8. Keep `remainingSeconds` unchanged (frozen)

**Postconditions**:
- Session status = .paused
- pausedAt timestamp stored
- Timer stopped
- Notification cancelled
- `sessionState == .paused`

**Error Conditions**:
- Throws `SessionError.noActiveSession` if called while idle
- Throws `SessionError.sessionAlreadyPaused` if already paused

**Implementation**:

```swift
func pause() throws {
    guard case .active(let session) = sessionState else {
        throw SessionError.noActiveSession
    }

    session.pausedAt = Date()
    session.status = .paused

    try modelContext.save()

    notificationService.cancelSessionNotification(for: session)
    timerCancellable?.cancel()

    sessionState = .paused(session)
    // remainingSeconds stays frozen
}
```

---

### 3. resume()

**Preconditions**:
- `sessionState == .paused(session)`

**Behavior**:
1. Extract session from paused state
2. Calculate pause duration: `Date() - session.pausedAt`
3. Accumulate: `session.totalPausedDuration += pauseDuration`
4. Set `session.pausedAt = nil`
5. Set `session.status = .inProgress`
6. Save to modelContext
7. Reschedule notification with remaining time
8. Restart Combine timer
9. Set `sessionState = .active(session)`

**Postconditions**:
- Session status = .inProgress
- totalPausedDuration updated
- pausedAt = nil
- Notification rescheduled with correct remaining time
- Timer running
- `sessionState == .active`

**Error Conditions**:
- Throws `SessionError.sessionNotPaused` if called while not paused

**Implementation**:

```swift
func resume() throws {
    guard case .paused(let session) = sessionState else {
        throw SessionError.sessionNotPaused
    }

    guard let pausedAt = session.pausedAt else {
        throw SessionError.invalidSessionState
    }

    let pauseDuration = Date().timeIntervalSince(pausedAt)
    session.totalPausedDuration += pauseDuration
    session.pausedAt = nil
    session.status = .inProgress

    try modelContext.save()

    notificationService.rescheduleAfterResume(for: session)
    startTimer(for: session)

    sessionState = .active(session)
}
```

---

### 4. cancel()

**Preconditions**:
- `sessionState == .active(session)` OR `sessionState == .paused(session)`

**Behavior**:
1. Extract session from current state
2. Set `session.status = .abandoned`
3. Save to modelContext (no CompletedTree created)
4. Cancel notification
5. Stop timer (if active)
6. Set `sessionState = .idle`
7. Reset `remainingSeconds = 0`

**Postconditions**:
- Session status = .abandoned
- Session persisted (for history tracking)
- No CompletedTree created
- Notification cancelled
- Timer stopped
- `sessionState == .idle`

**Error Conditions**:
- Throws `SessionError.noActiveSession` if called while idle

**Implementation**:

```swift
func cancel() throws {
    let session: Session

    switch sessionState {
    case .active(let s), .paused(let s):
        session = s
    case .idle:
        throw SessionError.noActiveSession
    }

    session.status = .abandoned
    try modelContext.save()

    notificationService.cancelSessionNotification(for: session)
    timerCancellable?.cancel()

    sessionState = .idle
    remainingSeconds = 0
}
```

---

### 5. complete(session:) [Private]

**Preconditions**:
- `sessionState == .active(session)`
- Remaining time reached 0

**Behavior**:
1. Set `session.completedAt = Date()`
2. Set `session.status = .completed`
3. Create CompletedTree referencing session
4. Insert CompletedTree into modelContext
5. Save to modelContext
6. Cancel notification (user already saw completion in-app)
7. Stop timer
8. Set `sessionState = .idle`

**Postconditions**:
- Session status = .completed
- CompletedTree created and persisted
- Stats updated (reactive to SwiftData changes)
- Notification cancelled
- Timer stopped
- `sessionState == .idle`

**Error Conditions**:
- Throws `SessionError.invalidSessionState` if session already completed or abandoned

**Implementation**:

```swift
private func complete(session: Session) throws {
    guard session.status == .inProgress else {
        throw SessionError.invalidSessionState
    }

    session.completedAt = Date()
    session.status = .completed

    let tree = CompletedTree(
        session: session,
        completedAt: session.completedAt!
    )

    modelContext.insert(tree)
    try modelContext.save()

    notificationService.cancelSessionNotification(for: session)
    timerCancellable?.cancel()

    sessionState = .idle
    remainingSeconds = 0
}
```

---

### 6. recalculateProgress()

**Purpose**: Handle background timing accuracy when app returns to foreground

**Preconditions**:
- Called in `scenePhase` onChange when transitioning to `.active`
- May be called in any session state

**Behavior**:

```swift
func recalculateProgress() {
    switch sessionState {
    case .active(let session):
        let elapsed = Date().timeIntervalSince(session.startedAt) - session.totalPausedDuration
        let remaining = (25 * 60) - elapsed

        if remaining <= 0 {
            // Session completed while app was backgrounded
            try? complete(session: session)
        } else {
            // Update remaining time
            remainingSeconds = Int(remaining)
            // Timer will sync to new remaining time
        }

    case .paused(let session):
        // Session was paused, no recalculation needed
        // (elapsed time frozen at pause)
        break

    case .idle:
        // No active session
        break
    }
}
```

**Postconditions**:
- If session completed in background: session marked as completed, tree saved
- If session still active: remainingSeconds updated to reflect actual elapsed time
- Timer synchronized with accurate remaining time

---

## Timer Implementation

### Combine Timer

```swift
private func startTimer(for session: Session) {
    timerCancellable?.cancel()

    timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.updateTimer(for: session)
        }
}

private func updateTimer(for session: Session) {
    let elapsed = Date().timeIntervalSince(session.startedAt) - session.totalPausedDuration
    let remaining = (25 * 60) - elapsed

    if remaining <= 0 {
        try? complete(session: session)
    } else {
        remainingSeconds = Int(remaining)
    }
}
```

**Key Principles**:
- Timer is cosmetic (UI updates only)
- Elapsed time calculated from timestamps, not timer ticks
- Ensures accuracy even if timer misses ticks due to background/performance

---

## Error Types

```swift
enum SessionError: Error {
    case sessionAlreadyActive
    case sessionAlreadyPaused
    case noActiveSession
    case sessionNotPaused
    case invalidSessionState
    case persistenceFailed
}
```

---

## Testing Contract

### Unit Tests (Swift Testing)

**SessionManagerTests.swift**:

```swift
@Test("Start session creates Session with correct initial state")
func testStartSession() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()

    #expect(session.status == .inProgress)
    #expect(manager.sessionState == .active(session))
    #expect(manager.remainingSeconds == 1500)
}

@Test("Pause transitions to paused state and stores pausedAt")
func testPauseSession() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()
    try manager.pause()

    #expect(session.status == .paused)
    #expect(session.pausedAt != nil)
    #expect(manager.sessionState == .paused(session))
}

@Test("Resume accumulates pause duration correctly")
func testResumePauseDuration() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()

    // Simulate 5-second pause
    try manager.pause()
    Thread.sleep(forTimeInterval: 5.0)
    try manager.resume()

    #expect(session.totalPausedDuration >= 5.0)
    #expect(session.totalPausedDuration < 6.0) // ±1s tolerance
    #expect(session.pausedAt == nil)
}

@Test("Complete creates CompletedTree and transitions to idle")
func testCompleteSession() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()
    session.startedAt = Date().addingTimeInterval(-25 * 60) // Simulate 25 minutes elapsed

    manager.recalculateProgress()

    #expect(session.status == .completed)
    #expect(manager.sessionState == .idle)

    let trees = try context.fetch(FetchDescriptor<CompletedTree>())
    #expect(trees.count == 1)
    #expect(trees.first?.session.id == session.id)
}

@Test("Cancel marks session as abandoned without creating tree")
func testCancelSession() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()
    try manager.cancel()

    #expect(session.status == .abandoned)
    #expect(manager.sessionState == .idle)

    let trees = try context.fetch(FetchDescriptor<CompletedTree>())
    #expect(trees.isEmpty)
}

@Test("Background timing recalculates accurately")
func testBackgroundTimingAccuracy() throws {
    let context = ModelContext(testContainer)
    let manager = SessionManager(modelContext: context)

    let session = try manager.start()

    // Simulate 10 minutes passing
    session.startedAt = Date().addingTimeInterval(-10 * 60)

    manager.recalculateProgress()

    let expectedRemaining = 15 * 60 // 15 minutes
    #expect(abs(manager.remainingSeconds - expectedRemaining) <= 1)
}
```

---

## Concurrency and Thread Safety

**Thread Model**: `@MainActor`

All SessionManager methods run on the main thread for SwiftUI integration. SwiftData operations are also main-thread by default when using `@Query` and `ModelContext` from SwiftUI views.

**Concurrency Notes**:
- Combine timer publishes on `.main` RunLoop
- No background threading for session logic (simplicity over premature optimization)
- If performance profiling shows main-thread blocking, defer heavy operations to background queues

---

## Summary

This contract ensures SessionManager:
1. Enforces a clean state machine with well-defined transitions
2. Uses timestamp-based calculations for background timing accuracy
3. Coordinates with NotificationService for background alerts
4. Persists sessions to SwiftData at all state transitions
5. Provides observable state for SwiftUI reactive UI
6. Handles edge cases (force quit, background completion, multiple pauses)
