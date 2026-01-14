# Feature Specification: Forest-Style Pomodoro Timer

**Feature Branch**: `001-pomodoro-forest-timer`
**Created**: 2026-01-13
**Status**: Draft
**Input**: User description: "Build a Forest-style Pomodoro app for ios: start a 25-minute session to "plant" a tree that grows through 5 stages; cancel/quit kills the tree; completion saves it to a personal forest. Show countdown, pause/resume, local notification, and background-accurate timing. Store completed/abandoned sessions locally; show a forest grid and stats (total trees, total focus time, today's count, daily streak). Out of scope: custom durations, species, sync, sharing, watch, widgets."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Focus Session (Priority: P1)

A user wants to focus on work for 25 minutes. They open the app, start a session, and see a tree begin to grow on screen. The countdown timer shows remaining time. When 25 minutes elapse, the app notifies them of completion, saves the tree to their forest, and shows their updated stats.

**Why this priority**: This is the core value proposition—the ability to complete a focus session and be rewarded with a tree. Without this, there is no app.

**Independent Test**: Can be fully tested by starting a session, waiting 25 minutes (or fast-forwarding in test mode), and verifying the tree is saved and stats increment.

**Acceptance Scenarios**:

1. **Given** the app is open on the start screen, **When** the user taps "Start Session", **Then** a countdown timer displays 25:00 and a small tree appears on screen
2. **Given** a session is running with 10:00 remaining, **When** time elapses naturally, **Then** the countdown decrements second-by-second and the tree grows through visible stages
3. **Given** a session reaches 00:00, **When** the timer completes, **Then** a local notification fires, the tree is saved to the forest, and stats (total trees, total focus time, today's count) increment by 1 tree and 25 minutes
4. **Given** a completed session, **When** the user views their forest, **Then** the newly saved tree appears in the forest grid

---

### User Story 2 - Pause and Resume Session (Priority: P2)

A user is in the middle of a focus session when they need to briefly step away. They pause the timer, handle an urgent matter, then return and resume the session. The timer picks up exactly where it left off, and the tree continues growing upon resume.

**Why this priority**: Real-world focus sessions often require brief interruptions. Without pause/resume, users would be forced to abandon sessions unnecessarily, reducing engagement.

**Independent Test**: Can be fully tested by starting a session, pausing after 5 minutes, waiting 10 seconds, resuming, and verifying the countdown continues from the paused time (not from the original start time).

**Acceptance Scenarios**:

1. **Given** a session is running with 15:00 remaining, **When** the user taps "Pause", **Then** the countdown stops and the pause button changes to "Resume"
2. **Given** a session is paused with 15:00 remaining, **When** the user waits 5 real-world minutes, **Then** the countdown remains at 15:00 (does not elapse while paused)
3. **Given** a session is paused, **When** the user taps "Resume", **Then** the countdown continues from the paused time and the tree resumes growing
4. **Given** a session is paused and resumed multiple times, **When** the session completes, **Then** only the actual focus time (excluding paused duration) counts toward the 25-minute goal

---

### User Story 3 - Abandon Session (Priority: P2)

A user starts a focus session but realizes they need to stop before completion. They choose to quit or cancel the session. The app warns them that quitting will "kill" the tree, and if they confirm, the session is recorded as abandoned (not saved to the forest), and stats do not increment.

**Why this priority**: Users need the ability to exit sessions, and the "killed tree" consequence reinforces focus commitment. This creates accountability without being punitive (no negative stats).

**Independent Test**: Can be fully tested by starting a session, canceling after 10 minutes, confirming the kill action, and verifying the tree does not appear in the forest and stats do not change.

**Acceptance Scenarios**:

1. **Given** a session is running, **When** the user taps "Cancel" or closes the app, **Then** a confirmation dialog appears warning "Quitting will kill your tree. Are you sure?"
2. **Given** the kill confirmation dialog is shown, **When** the user taps "Yes, Quit", **Then** the session ends, no tree is saved to the forest, and stats remain unchanged
3. **Given** the kill confirmation dialog is shown, **When** the user taps "No, Keep Going", **Then** the dialog dismisses and the session continues running
4. **Given** a session was abandoned, **When** the user views session history, **Then** the abandoned session is recorded with timestamp but marked as "abandoned" (not counted in stats)

---

### User Story 4 - Background Timing Accuracy (Priority: P1)

A user starts a focus session, then switches to another app or locks their device. The timer continues counting down accurately in the background. When they return to the app, the countdown reflects the correct elapsed time, and the tree has grown appropriately. If the session completes while in the background, a local notification fires.

**Why this priority**: Mobile focus apps must work while the device is locked or the user is in another app. Without accurate background timing, the app is unusable for real focus work.

**Independent Test**: Can be fully tested by starting a session, backgrounding the app for 10 minutes, returning, and verifying the countdown has decremented by 10 minutes (not frozen).

**Acceptance Scenarios**:

1. **Given** a session is running with 20:00 remaining, **When** the user backgrounds the app for 5 minutes, **Then** upon returning, the countdown shows 15:00 (accurate elapsed time)
2. **Given** a session is running in the background with 5:00 remaining, **When** the countdown reaches 00:00, **Then** a local notification fires with message "Your tree is complete!" even if the app is not open
3. **Given** a session completes in the background, **When** the user opens the app, **Then** the completed session is saved to the forest and stats are updated
4. **Given** a session is paused, **When** the app is backgrounded, **Then** the countdown remains paused (does not elapse while paused in background)

---

### User Story 5 - View Forest and Stats (Priority: P3)

A user wants to see their progress over time. They navigate to the forest view and see a grid of all their completed trees. They view stats showing total trees planted, total focus time, today's tree count, and their current daily streak (consecutive days with at least one completed session).

**Why this priority**: Visual progress and stats provide motivation and satisfaction. This is a secondary feature that enhances the core experience but isn't required for basic functionality.

**Independent Test**: Can be fully tested by completing 3 sessions across 2 days, then viewing the forest and stats to verify correct counts and streak calculation.

**Acceptance Scenarios**:

1. **Given** the user has completed 10 sessions, **When** they navigate to the forest view, **Then** a grid displays 10 trees
2. **Given** the user is viewing the forest, **When** the screen loads, **Then** stats display: "Total Trees: 10", "Total Focus Time: 4h 10m", "Today: 2 trees", "Streak: 5 days"
3. **Given** the user completed sessions on Jan 1, Jan 2, and Jan 3, **When** viewing stats on Jan 3, **Then** the streak shows "3 days"
4. **Given** the user completed sessions on Jan 1 and Jan 3 (skipped Jan 2), **When** viewing stats on Jan 3, **Then** the streak shows "1 day" (streak resets when a day is missed)
5. **Given** the user has completed 50+ trees, **When** viewing the forest grid, **Then** the grid scrolls to accommodate all trees without performance degradation

---

### Edge Cases

- What happens when the app is force-quit during an active session? (Treat as abandoned—no tree saved, no stats increment)
- What happens when the device runs out of battery during a session? (Treat as abandoned—session is not saved)
- What happens when the user changes device time/date during a session? (Timer should rely on elapsed time intervals, not wall-clock time, to prevent cheating/bugs)
- What happens when a user denies notification permissions? (Session still works, but completion notification won't fire—show in-app message instead)
- What happens when the app is killed by the OS for memory reasons? (Treat as abandoned—no tree saved)
- What happens at the day boundary (midnight)? ("Today's count" resets to 0; streak increments if at least one tree was planted the previous day)
- What happens when the user reaches 0 days streak? (Display "Streak: 0 days" or "Start your streak today!")
- What happens if the user starts multiple sessions in rapid succession? (Each session is independent; completing one does not affect another)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to start a 25-minute focus session with a single tap
- **FR-002**: System MUST display a countdown timer showing minutes and seconds remaining (format: MM:SS)
- **FR-003**: System MUST display a tree visualization that grows through exactly 5 distinct visual stages during the session (stages at 0%, 25%, 50%, 75%, 100% completion)
- **FR-004**: System MUST allow users to pause an active session, freezing the countdown and tree growth
- **FR-005**: System MUST allow users to resume a paused session, continuing the countdown from the paused time
- **FR-006**: System MUST allow users to cancel/quit an active session with a confirmation dialog warning that the tree will be "killed"
- **FR-007**: System MUST save completed sessions (25:00 elapsed) to local storage as "completed trees" in the user's forest
- **FR-008**: System MUST NOT save abandoned sessions (quit before 25:00) to the forest
- **FR-009**: System MUST record abandoned sessions in local storage for history tracking (but not count them in stats)
- **FR-010**: System MUST continue countdown accurately when the app is backgrounded, locked, or user switches to another app
- **FR-011**: System MUST fire a local notification when a session completes while the app is in the background
- **FR-012**: System MUST display a forest grid view showing all completed trees
- **FR-013**: System MUST display four statistics: total trees planted, total focus time (in hours and minutes), today's tree count, and current daily streak
- **FR-014**: System MUST calculate total focus time as (number of completed sessions × 25 minutes)
- **FR-015**: System MUST calculate "today's count" as the number of sessions completed since midnight local time
- **FR-016**: System MUST calculate daily streak as consecutive days (from today backward) where at least one session was completed
- **FR-017**: System MUST reset streak to 0 if a day is skipped (no sessions completed on a given day)
- **FR-018**: System MUST persist all session data locally (no network/cloud sync)
- **FR-019**: System MUST NOT allow users to customize session duration (fixed at 25 minutes)
- **FR-020**: System MUST NOT support multiple tree species or visual variations (single tree type)
- **FR-021**: System MUST NOT include Apple Watch companion app or widgets (out of scope)
- **FR-022**: System MUST NOT include sharing features (out of scope)

### Key Entities

- **Session**: Represents a single focus attempt. Attributes: start time, end time, status (completed/abandoned), duration (always 25 minutes if completed), timestamp of completion.
- **Completed Tree**: Represents a successful session saved to the forest. Attributes: completion timestamp, associated session reference. No visual variations or species.
- **Daily Stats**: Derived data calculated from completed sessions. Attributes: total tree count, total focus time (minutes), today's tree count (resets at midnight), current streak (consecutive days).
- **Forest**: Collection of all completed trees, displayed as a grid. No organizational structure (chronological or spatial grouping).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can start a focus session and see the countdown begin within 1 second of tapping "Start"
- **SC-002**: Users can complete a 25-minute session and have the tree saved to their forest with 100% reliability (no data loss)
- **SC-003**: Background timing is accurate to within ±5 seconds over a 25-minute period (no drift)
- **SC-004**: Forest view can display 100+ trees without frame rate dropping below 60fps
- **SC-005**: App cold start (launch to interactive state) completes in under 2 seconds
- **SC-006**: Local notifications fire within 2 seconds of session completion when app is backgrounded
- **SC-007**: Tree growth animations remain smooth (60fps) throughout all 5 stages
- **SC-008**: Pause/resume actions take effect within 0.5 seconds (no lag)
- **SC-009**: Stats (total trees, focus time, streak) update instantly (within 0.5 seconds) after session completion
- **SC-010**: Users can complete 20 sessions per day without performance degradation
- **SC-011**: All session data persists across app restarts (100% local data reliability)
- **SC-012**: Streak calculation is accurate for 30+ consecutive days (no off-by-one errors at day boundaries)

## Assumptions

- Users understand the Pomodoro Technique (25-minute focused work intervals)
- Users have granted notification permissions (if denied, in-app completion message suffices)
- Device is iOS 15+ (target minimum iOS version aligned with SwiftUI best practices)
- Users' device clocks are reasonably accurate (not intentionally manipulated)
- "Today" is defined by device local timezone (midnight-to-midnight in user's location)
- Tree growth stages are evenly distributed (0%, 25%, 50%, 75%, 100% = stages 1-5)
- Abandoned sessions are recorded for potential future analytics but not displayed prominently to users
- Session duration is always exactly 25 minutes (no rounding, no custom durations)
- Forest grid displays trees in reverse chronological order (newest first)

## Out of Scope

The following features are explicitly excluded from this specification:

- Custom session durations (only 25 minutes supported)
- Multiple tree species or visual variations
- Cloud sync or multi-device support
- Social features (sharing, leaderboards, friends)
- Apple Watch companion app
- Home screen or lock screen widgets
- Background sounds or ambient audio during sessions
- Pomodoro break timers (5-minute short breaks, 15-minute long breaks)
- Session tagging or categorization (e.g., "work", "study")
- Export or analytics beyond the four core stats
- In-app purchases, ads, or monetization
