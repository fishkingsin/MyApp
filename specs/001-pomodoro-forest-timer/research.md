# Research: Forest-Style Pomodoro Timer

**Feature**: Forest-Style Pomodoro Timer
**Branch**: `001-pomodoro-forest-timer`
**Date**: 2026-01-14

This document consolidates research findings for technical decisions identified during planning.

## Research Questions

### 1. Memory Management for LazyVGrid with 100+ Trees

**Question**: What are the best practices for keeping a SwiftUI LazyVGrid performant when displaying 100+ tree items while maintaining 60fps and ~50MB memory target?

**Decision**: Use LazyVGrid with lightweight data model references, avoid storing Image objects in state, and implement proper state management patterns.

**Rationale**:
- LazyVGrid only renders items as they appear on screen, providing 80-90% memory reduction compared to VStack for large datasets
- The lazy loading mechanism maintains 60fps scrolling even with hundreds of items when properly implemented
- Memory issues arise when heavyweight objects (UIImage, Image) are stored in view state rather than lightweight data types

**Implementation Recommendations**:

1. **Store Lightweight Data Types**
   - Store `Data` or `UUID` references instead of `Image` objects in SwiftData models
   - Load images on-demand in view rendering using `Image(systemName:)` or asset catalog lookups
   - This allows iOS to reclaim memory when views scroll out of the visible area

2. **State Management Pattern**
   - Elevate all persistent state to top-level views using `@Binding` patterns
   - SwiftUI only retains state of top-level views in lazy containers; nested child view states reset when recycled
   - Use `@Observable` macro (iOS 17+) for centralized state management rather than per-item `@State`

3. **Avoid Common Pitfalls**
   - Never use `.id()` modifier on items within a `List` (breaks lazy loading by instantiating all views)
   - For LazyVGrid/LazyVStack outside of List, `.id()` is safe
   - Don't wrap ForEach items in `if`/`switch` inside `List` (causes `_ConditionalContent` issue that prevents lazy loading)

4. **Custom Collection for Pagination** (if needed for 200+ trees in future)
   - Implement custom `RandomAccessCollection` wrapper for threshold-based loading
   - Embed dynamic fetching logic directly in collection rather than view layer
   - Avoids unnecessary array conversions for efficient indexing

5. **Performance Validation**
   - Profile with Instruments Allocations to verify memory stays <50MB
   - Use SwiftUI View Body profiling to ensure <16ms render time per grid item
   - Test scrolling performance with 100+ items on minimum device (iPhone 12 equivalent)

**Alternatives Considered**:
- **Custom UICollectionView wrapper**: Rejected due to increased complexity and loss of SwiftUI declarative benefits. LazyVGrid provides sufficient performance for 100+ items.
- **Pagination/windowing**: Deferred as optimization for future if users exceed 200+ trees. Current LazyVGrid performance is adequate for stated requirements.

**Sources**:
- [Tips and Considerations for Using Lazy Containers in SwiftUI](https://fatbobman.com/en/posts/tips-and-considerations-for-using-lazy-containers-in-swiftui/)
- [Tuning Lazy Stacks and Grids in SwiftUI: A Performance Guide](https://medium.com/@wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a)
- [24 SwiftUI Performance Tips Every iOS Developer Should Know (2025 Edition)](https://medium.com/@ravisolankice12/24-swiftui-performance-tips-every-ios-developer-should-know-2025-edition-723340d9bd79)

---

### 2. Background Timing Architecture for Accurate 25-Minute Countdown

**Question**: How should the timer architecture ensure accurate countdown (±5 seconds over 25 minutes) when the app is backgrounded, locked, or killed by iOS?

**Decision**: Use timestamp-based elapsed time calculation with scheduled local notifications, not continuous background timers.

**Rationale**:
- iOS suspends apps shortly after backgrounding (typically 30 seconds), with strict limits on background execution to preserve battery
- Timer objects (including Combine's Timer.publish) are based on Mach absolute time, which stops when CPU sleeps
- iOS 10.3+ shows significant timer drift when device is locked (up to 1 minute drift on a 30-second timer)
- iOS has no general-purpose "run-me-every-N-minutes" background execution mechanism
- Local notifications are Apple's recommended approach for timer expiration alerts

**Implementation Architecture**:

1. **Timestamp-Based Elapsed Time**
   ```swift
   // Store session start timestamp when timer begins
   let sessionStartDate = Date()

   // On app resume, recalculate elapsed time
   let elapsedTime = Date().timeIntervalSince(sessionStartDate)
   let remainingTime = totalDuration - elapsedTime
   ```
   - Store `sessionStartDate` in SwiftData when session starts
   - Store `pausedAt` timestamp when paused (if paused)
   - Calculate `totalPausedDuration` by accumulating pause intervals
   - On foreground return: `actualElapsed = Date() - sessionStartDate - totalPausedDuration`

2. **Combine Timer for UI Updates Only**
   - Use `Timer.publish(every: 1.0, on: .main, in: .common)` for UI countdown display
   - Timer is purely cosmetic for updating the MM:SS display
   - On `scenePhase` change to `.active`, cancel old timer and recalculate from timestamps
   - Timer does NOT track session progress; it only drives UI updates

3. **Local Notification for Completion**
   ```swift
   // Schedule notification when session starts
   let content = UNMutableNotificationContent()
   content.title = "Your tree is complete!"
   content.body = "Great work! Your tree has been saved to your forest."

   let trigger = UNTimeIntervalNotificationTrigger(
       timeInterval: 25 * 60, // 25 minutes
       repeats: false
   )

   let request = UNNotificationRequest(
       identifier: "session-complete-\(sessionID)",
       content: content,
       trigger: trigger
   )
   ```
   - Schedule notification immediately when session starts (fires in 25 minutes)
   - If user completes session in foreground before notification, cancel the notification
   - If app is backgrounded and notification fires, it marks session as complete in `UNUserNotificationCenterDelegate`

4. **Scene Phase Lifecycle Handling**
   ```swift
   @Environment(\.scenePhase) var scenePhase

   .onChange(of: scenePhase) { oldPhase, newPhase in
       switch newPhase {
       case .active:
           // Recalculate elapsed time from stored timestamp
           sessionManager.recalculateProgress()
       case .background:
           // Timer will stop, but timestamp is saved
           // Local notification will fire if session completes
       case .inactive:
           break
       @unknown default:
           break
       }
   }
   ```

5. **Handling App Termination**
   - If iOS kills the app for memory reasons, the stored `sessionStartDate` in SwiftData persists
   - On app relaunch, check for any in-progress sessions:
     - If elapsed time >= 25 minutes: mark as completed, save tree
     - If elapsed time < 25 minutes: treat as abandoned (per spec edge case: "force-quit during session = abandoned")
   - Scheduled local notification still fires if session completes while app is killed

**Edge Case Handling**:
- **User changes device time**: Use `Date()` which is based on system time. Accept this as an edge case (spec assumes "device clocks are reasonably accurate")
- **Notification permission denied**: Session still completes silently; show in-app completion message when user returns
- **Multiple simultaneous sessions**: Each session has unique notification identifier (`session-complete-{UUID}`)

**Alternatives Considered**:
- **Background Tasks API (BGTaskScheduler)**: Rejected because minimum interval is ~15 minutes and timing is controlled by iOS, not suitable for precise 25-minute countdown
- **Audio session background mode**: Rejected as complexity violation (would require silent audio playback) and inappropriate use of background modes
- **Continuous background timer**: Not possible due to iOS suspension behavior; would drain battery and violate App Store guidelines

**Sources**:
- [How to run timer in background for… | Apple Developer Forums](https://developer.apple.com/forums/thread/114859)
- [Overcoming iOS Background Limits: A Time Tracker App in Swift UI](https://medium.com/deuk/overcoming-ios-background-limits-a-time-tracker-app-in-swift-ui-5d157a58df68)
- [Best practice: iOS background processing - Background App Refresh Task](https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/)
- [iOS Background Execution Limits | Apple Developer Forums](https://developer.apple.com/forums/thread/685525)

---

## Additional Technical Decisions

### SwiftData vs CoreData

**Decision**: Use SwiftData for local persistence (iOS 17+ required)

**Rationale**:
- User input specified "SwiftData on iOS 17+"
- SwiftData provides modern Swift-native API with reduced boilerplate compared to CoreData
- `@Model` macro and `@Observable` macro integrate seamlessly with SwiftUI
- Automatic schema migration and type-safe queries
- Built on CoreData, inheriting its performance and stability

**Implementation Notes**:
- Define models with `@Model` macro: Session, CompletedTree
- Use `@Query` in SwiftUI views for reactive data binding
- ModelContainer configured in `@main` app struct for dependency injection
- No need for NSManagedObject subclasses or Core Data stack boilerplate

---

### Tree Growth Animation Strategy

**Decision**: Use SwiftUI's native animation system with discrete tree stages rendered as SF Symbols or asset catalog images

**Rationale**:
- 5 discrete stages (0%, 25%, 50%, 75%, 100%) map to 5 different tree images
- SwiftUI `.animation(.easeInOut(duration: 1.0), value: treeStage)` provides smooth transitions
- Pre-rendered images (SF Symbols or asset catalog) are more performant than custom drawing
- Keeps memory footprint low (5 small PNG assets or SF Symbols)

**Implementation**:
```swift
Image(systemName: treeImageName(for: growthStage))
    .resizable()
    .frame(width: 100, height: 100)
    .animation(.easeInOut(duration: 0.8), value: growthStage)
```

**Alternatives Considered**:
- **Custom Shape drawing**: Rejected due to complexity and potential frame rate issues
- **Lottie animations**: Rejected as third-party dependency (violates constitution)
- **SpriteKit integration**: Rejected as unnecessary complexity for 5 discrete stages

---

## Summary of Resolved Clarifications

| Original Unknown | Resolution |
|-----------------|------------|
| Memory management for 100+ trees in LazyVGrid | Use LazyVGrid with lightweight data types (Data/UUID), elevate state management, avoid Image objects in state |
| Timer accuracy when backgrounded | Timestamp-based elapsed time calculation + scheduled local notifications; Combine timer for UI updates only |
| SwiftData best practices | Use `@Model`, `@Query`, ModelContainer injection; leverage iOS 17+ @Observable macro |
| Animation performance | 5 discrete image stages with SwiftUI native animation; use SF Symbols or asset catalog |

All NEEDS CLARIFICATION items from Technical Context have been resolved with concrete implementation patterns.
