# Data Model: Forest-Style Pomodoro Timer

**Feature**: Forest-Style Pomodoro Timer
**Branch**: `001-pomodoro-forest-timer`
**Date**: 2026-01-14
**Persistence**: SwiftData (iOS 17+)

This document defines the data entities, their attributes, relationships, validation rules, and state transitions for the Forest-Style Pomodoro Timer app.

## Entity Overview

```
┌─────────────┐
│   Session   │ 1──────* relationship (optional)
│  @Model     │────────────────┐
└─────────────┘                │
       │                       │
       │ 1:1 (completed only)  │
       │                       ▼
       ▼                ┌──────────────┐
┌─────────────┐         │              │
│CompletedTree│         │  DailyStats  │
│  @Model     │         │  (computed)  │
└─────────────┘         └──────────────┘
```

**Cardinality**:
- One Session can have zero or one CompletedTree (only if status == .completed)
- CompletedTree has one Session (required reference)
- DailyStats is computed from all Sessions (not persisted)

---

## Entity Definitions

### 1. Session

**Description**: Represents a single focus session attempt (25 minutes). Tracks both completed and abandoned sessions. Acts as the source of truth for timing and status.

**SwiftData Model**:

```swift
import SwiftData
import Foundation

@Model
final class Session {
    // Primary identifier
    var id: UUID

    // Timing attributes
    var startedAt: Date
    var completedAt: Date?
    var totalPausedDuration: TimeInterval  // Accumulated pause time in seconds

    // Status
    var status: SessionStatus

    // Pause tracking
    var pausedAt: Date?  // Timestamp when currently paused (nil if not paused)

    // Computed properties (not persisted)
    var duration: TimeInterval {
        guard status == .completed, let completedAt else { return 0 }
        return completedAt.timeIntervalSince(startedAt) - totalPausedDuration
    }

    var isActive: Bool {
        status == .inProgress
    }

    var isPaused: Bool {
        status == .paused
    }

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        totalPausedDuration: TimeInterval = 0,
        status: SessionStatus = .inProgress
    ) {
        self.id = id
        self.startedAt = startedAt
        self.totalPausedDuration = totalPausedDuration
        self.status = status
    }
}

enum SessionStatus: String, Codable {
    case inProgress   // Currently running
    case paused       // Temporarily paused by user
    case completed    // Successfully reached 25:00
    case abandoned    // Cancelled/quit before completion
}
```

**Validation Rules**:
- `startedAt` must be <= current time (cannot create future sessions)
- `completedAt` must be > `startedAt` if present
- `totalPausedDuration` must be >= 0
- `status == .completed` requires `completedAt` to be non-nil
- `status == .abandoned` requires `completedAt` to be nil
- Duration (completedAt - startedAt - totalPausedDuration) should be ~1500 seconds (25 minutes) for completed sessions (±5s tolerance)

**State Transitions**:

```
     ┌─────────────┐
     │ inProgress  │
     └─────────────┘
        │       │
 pause  │       │ complete (25:00 elapsed)
        │       │
        ▼       ▼
  ┌─────────┐  ┌───────────┐
  │ paused  │  │ completed │
  └─────────┘  └───────────┘
        │
 resume │
        │
        ▼
  ┌─────────────┐
  │ inProgress  │
  └─────────────┘

  ANY state ──cancel──> abandoned
```

**Lifecycle**:
1. Created with `status = .inProgress` when user taps "Start Session"
2. Transitions to `.paused` when user taps "Pause"
3. Returns to `.inProgress` when user taps "Resume" (accumulates pause time)
4. Transitions to `.completed` when elapsed time reaches 25:00 (triggers tree save)
5. Transitions to `.abandoned` if user cancels or app is force-quit during session

---

### 2. CompletedTree

**Description**: Represents a successfully completed session saved to the user's forest. Only created when a session reaches 25:00. Displayed in the forest grid view.

**SwiftData Model**:

```swift
import SwiftData
import Foundation

@Model
final class CompletedTree {
    // Primary identifier
    var id: UUID

    // Reference to source session
    var session: Session

    // Completion timestamp (denormalized for query performance)
    var completedAt: Date

    // Computed properties
    var dayKey: String {
        // Format: "2026-01-14" for grouping by day
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: completedAt)
    }

    init(
        id: UUID = UUID(),
        session: Session,
        completedAt: Date
    ) {
        self.id = id
        self.session = session
        self.completedAt = completedAt
    }
}
```

**Validation Rules**:
- `session` must have `status == .completed`
- `completedAt` must equal `session.completedAt` (denormalized for performance)
- Cannot create CompletedTree for abandoned sessions
- Each Session can have at most one CompletedTree (1:1 relationship)

**Lifecycle**:
1. Created immediately after Session transitions to `.completed`
2. Never deleted (permanent record in forest)
3. Used for forest grid display and stats calculations

---

### 3. DailyStats (Computed, Not Persisted)

**Description**: Derived statistics calculated on-demand from Session and CompletedTree data. Not a SwiftData @Model; computed in memory from queries.

**Swift Struct** (not persisted):

```swift
import Foundation

struct DailyStats {
    // Core metrics
    let totalTreesPlanted: Int
    let totalFocusTimeMinutes: Int
    let todaysTreeCount: Int
    let currentStreak: Int

    // Computed display properties
    var totalFocusTimeFormatted: String {
        let hours = totalFocusTimeMinutes / 60
        let minutes = totalFocusTimeMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var streakDisplay: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else {
            return "\(currentStreak) day\(currentStreak == 1 ? "" : "s")"
        }
    }
}
```

**Calculation Logic**:

```swift
@MainActor
class StatsCalculator {
    let modelContext: ModelContext

    func calculateStats() -> DailyStats {
        // Query all completed trees
        let descriptor = FetchDescriptor<CompletedTree>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let allTrees = try? modelContext.fetch(descriptor) ?? []

        // Total trees planted
        let totalTreesPlanted = allTrees.count

        // Total focus time (trees * 25 minutes)
        let totalFocusTimeMinutes = totalTreesPlanted * 25

        // Today's tree count
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaysTreeCount = allTrees.filter { tree in
            calendar.isDate(tree.completedAt, inSameDayAs: today)
        }.count

        // Current streak calculation
        let currentStreak = calculateStreak(from: allTrees, calendar: calendar)

        return DailyStats(
            totalTreesPlanted: totalTreesPlanted,
            totalFocusTimeMinutes: totalFocusTimeMinutes,
            todaysTreeCount: todaysTreeCount,
            currentStreak: currentStreak
        )
    }

    private func calculateStreak(from trees: [CompletedTree], calendar: Calendar) -> Int {
        guard !trees.isEmpty else { return 0 }

        // Group trees by day
        let dayGroups = Dictionary(grouping: trees) { tree in
            calendar.startOfDay(for: tree.completedAt)
        }

        // Sort unique days descending (most recent first)
        let uniqueDays = dayGroups.keys.sorted(by: >)

        // Calculate consecutive days from today backward
        let today = calendar.startOfDay(for: Date())
        var streakCount = 0
        var checkDate = today

        for day in uniqueDays {
            if calendar.isDate(day, inSameDayAs: checkDate) {
                streakCount += 1
                // Move to previous day
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                // Gap detected, streak broken
                break
            }
        }

        return streakCount
    }
}
```

**Validation Rules**:
- `totalTreesPlanted` equals count of all CompletedTree records
- `totalFocusTimeMinutes` equals `totalTreesPlanted × 25` (fixed session duration)
- `todaysTreeCount` resets at midnight (local timezone)
- `currentStreak` increments only if at least one tree was planted yesterday (no gaps allowed)

**Business Rules**:
- Stats update immediately after session completion (reactive to SwiftData changes)
- Streak resets to 0 if any day is skipped (no sessions completed)
- "Today" is defined by device local timezone (midnight-to-midnight)
- Streak counts consecutive days from today backward (not forward)
- Abandoned sessions do NOT contribute to any stats

---

## Indexes and Query Optimization

**Recommended Indexes** (SwiftData/CoreData):

```swift
// CompletedTree: Index on completedAt for date-based queries
@Attribute(.index) var completedAt: Date

// Session: Index on status for filtering active/completed sessions
@Attribute(.index) var status: SessionStatus
```

**Common Queries**:

1. **Fetch all completed trees for forest grid** (sorted newest first):
   ```swift
   @Query(sort: \CompletedTree.completedAt, order: .reverse)
   var completedTrees: [CompletedTree]
   ```

2. **Fetch current active session** (if any):
   ```swift
   let descriptor = FetchDescriptor<Session>(
       predicate: #Predicate { $0.status == .inProgress || $0.status == .paused }
   )
   let activeSessions = try? modelContext.fetch(descriptor)
   ```

3. **Fetch today's trees**:
   ```swift
   let today = Calendar.current.startOfDay(for: Date())
   let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

   let descriptor = FetchDescriptor<CompletedTree>(
       predicate: #Predicate { tree in
           tree.completedAt >= today && tree.completedAt < tomorrow
       }
   )
   ```

---

## Schema Migration Strategy

**Initial Schema** (v1): As defined above

**Future Considerations**:
- If tree species are added in future (currently out of scope), add `treeType: String` to CompletedTree
- If custom durations are added (currently out of scope), add `durationMinutes: Int` to Session
- SwiftData handles lightweight migrations automatically for additive changes

**Migration Workflow**:
- SwiftData automatic migration for adding optional fields
- Manual migration required only if removing fields or changing relationships
- Test migration with Instruments to ensure <2s app launch performance maintained

---

## Data Lifecycle Summary

| Entity | Creation Trigger | Deletion Policy | Retention |
|--------|------------------|-----------------|-----------|
| Session | User taps "Start Session" | Never deleted | Permanent (includes abandoned sessions) |
| CompletedTree | Session reaches 25:00 (status = .completed) | Never deleted | Permanent (forest record) |
| DailyStats | Computed on-demand (not persisted) | N/A (ephemeral) | Recalculated every view load |

**Disk Space Estimate**:
- Session: ~100 bytes/record
- CompletedTree: ~120 bytes/record
- 1000 sessions (1 year @ 3 sessions/day) ≈ 220 KB
- Negligible storage impact; SwiftData compression reduces further

---

## Validation Test Cases

**Session State Machine**:
- ✅ Session starts in `.inProgress` status
- ✅ Pause transitions to `.paused` and stores `pausedAt`
- ✅ Resume transitions back to `.inProgress` and accumulates `totalPausedDuration`
- ✅ Completion transitions to `.completed` and sets `completedAt`
- ✅ Cancel from any state transitions to `.abandoned`

**CompletedTree Creation**:
- ✅ CompletedTree created only when Session status == `.completed`
- ✅ CompletedTree.completedAt matches Session.completedAt
- ✅ Abandoned sessions do NOT create CompletedTree

**DailyStats Calculation**:
- ✅ Total trees equals count of CompletedTree records
- ✅ Total focus time equals trees × 25 minutes
- ✅ Today's count resets at midnight
- ✅ Streak increments for consecutive days
- ✅ Streak resets when day is skipped

**Edge Cases**:
- ✅ Multiple pause/resume cycles correctly accumulate paused time
- ✅ App restart during active session allows resume (or marks abandoned if force-quit)
- ✅ Streak calculation handles day boundary correctly (midnight transitions)
- ✅ Empty forest (0 trees) shows "Start your streak today!" message
