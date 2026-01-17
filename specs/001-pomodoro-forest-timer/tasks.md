# Tasks: Forest-Style Pomodoro Timer

**Input**: Design documents from `/specs/001-pomodoro-forest-timer/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included (TDD approach per constitution Principle II)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is an iOS mobile app using Xcode project structure:

- **Models**: `PomodoroFocusTimer/PomodoroFocusTimer/Models/`
- **Services**: `PomodoroFocusTimer/PomodoroFocusTimer/Services/`
- **Views**: `PomodoroFocusTimer/PomodoroFocusTimer/Views/`
- **Components**: `PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/`
- **Unit Tests**: `PomodoroFocusTimer/PomodoroFocusTimerTests/`
- **UI Tests**: `PomodoroFocusTimer/PomodoroFocusTimerUITests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create Models directory structure in PomodoroFocusTimer/PomodoroFocusTimer/Models/
- [x] T002 Create Services directory structure in PomodoroFocusTimer/PomodoroFocusTimer/Services/
- [x] T003 Create Views directory structure in PomodoroFocusTimer/PomodoroFocusTimer/Views/
- [x] T004 Create Components directory structure in PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/
- [x] T005 Add tree growth stage assets (5 SF Symbols or images) to PomodoroFocusTimer/PomodoroFocusTimer/Assets.xcassets/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Configure SwiftData ModelContainer in PomodoroFocusTimer/PomodoroFocusTimer/PomodoroFocusTimerApp.swift with Session and CompletedTree models
- [x] T007 [P] Request notification permissions in PomodoroFocusTimer/PomodoroFocusTimer/PomodoroFocusTimerApp.swift (UNUserNotificationCenter authorization)
- [x] T008 [P] Register notification categories in PomodoroFocusTimer/PomodoroFocusTimer/PomodoroFocusTimerApp.swift (SESSION_COMPLETE category)
- [x] T009 Update ContentView in PomodoroFocusTimer/PomodoroFocusTimer/ContentView.swift to be a navigation coordinator (TabView or NavigationStack)
- [x] T010 [P] Create SessionStatus enum in PomodoroFocusTimer/PomodoroFocusTimer/Models/Session.swift (inProgress, paused, completed, abandoned)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Complete Focus Session (Priority: P1) 🎯 MVP

**Goal**: Enable users to start a 25-minute focus session, watch a tree grow through 5 stages, and save completed trees to their forest with accurate background timing.

**Independent Test**: Start a session, wait 25 minutes (or fast-forward in test mode), verify tree is saved to forest and stats increment.

**Combines with**: User Story 4 (Background Timing) - implemented together as they are both P1 and tightly coupled

### Tests for User Story 1 & 4 (TDD - Write First)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T011 [P] [US1] Write unit test for Session model creation in PomodoroFocusTimerTests/ModelTests.swift (verify initial state, startedAt, status)
- [x] T012 [P] [US1] Write unit test for Session completion transition in PomodoroFocusTimerTests/ModelTests.swift (verify completedAt set, status = .completed)
- [x] T013 [P] [US1] Write unit test for CompletedTree creation in PomodoroFocusTimerTests/ModelTests.swift (verify 1:1 relationship with Session)
- [x] T014 [P] [US1] Write unit test for SessionManager start() in PomodoroFocusTimerTests/SessionManagerTests.swift (verify session created, timer started, notification scheduled)
- [x] T015 [P] [US1] Write unit test for SessionManager complete() in PomodoroFocusTimerTests/SessionManagerTests.swift (verify tree saved, stats updated)
- [x] T016 [P] [US1] Write unit test for background timing accuracy in PomodoroFocusTimerTests/SessionManagerTests.swift (simulate 10-minute background, verify recalculateProgress())
- [x] T017 [P] [US1] Write unit test for timer completion in PomodoroFocusTimerTests/SessionManagerTests.swift (verify session completes when remainingSeconds reaches 0)
- [x] T018 [P] [US1] Write unit test for tree growth stage calculation in PomodoroFocusTimerTests/SessionManagerTests.swift (verify stages 1-5 at 0%, 25%, 50%, 75%, 100%)
- [x] T019 [US1] Write UI test for complete session flow in PomodoroFocusTimerUITests/SessionFlowTests.swift (start → wait 25min → verify completion)
- [x] T020 [US1] Write UI test for background completion in PomodoroFocusTimerUITests/SessionFlowTests.swift (start → background → notification fires → tree saved)

### Implementation for User Story 1 & 4

**Models**:

- [x] T021 [P] [US1] Create Session model in PomodoroFocusTimer/PomodoroFocusTimer/Models/Session.swift with @Model, SwiftData attributes, SessionStatus enum
- [x] T022 [P] [US1] Create CompletedTree model in PomodoroFocusTimer/PomodoroFocusTimer/Models/CompletedTree.swift with @Model, session reference, completedAt
- [x] T023 [P] [US1] Create DailyStats struct in PomodoroFocusTimer/PomodoroFocusTimer/Models/DailyStats.swift (computed stats, not persisted)

**Services**:

- [x] T024 [US1] Implement NotificationService in PomodoroFocusTimer/PomodoroFocusTimer/Services/NotificationService.swift (schedule, cancel, reschedule methods)
- [x] T025 [US1] Implement SessionManager in PomodoroFocusTimer/PomodoroFocusTimer/Services/SessionManager.swift with @Observable, state machine (idle/active/paused), start() method
- [x] T026 [US1] Add complete() method to SessionManager (marks session completed, creates CompletedTree, cancels notification, transitions to idle)
- [x] T027 [US1] Add Combine timer to SessionManager (Timer.publish every 1 second, updates remainingSeconds)
- [x] T028 [US1] Add timestamp-based recalculateProgress() to SessionManager (handles background timing accuracy)
- [x] T029 [US1] Add scenePhase observer to SessionManager (calls recalculateProgress when app returns to foreground)
- [x] T030 [US1] Add treeGrowthStage computed property to SessionManager (returns 1-5 based on progress)

**Views & Components**:

- [x] T031 [P] [US1] Create TreeVisualization component in PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/TreeVisualization.swift (displays 1 of 5 tree stages with animation)
- [x] T032 [P] [US1] Create CountdownDisplay component in PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/CountdownDisplay.swift (formats remainingSeconds as MM:SS)
- [x] T033 [US1] Create StartSessionView in PomodoroFocusTimer/PomodoroFocusTimer/Views/StartSessionView.swift (Start Session button, calls SessionManager.start())
- [x] T034 [US1] Create ActiveTimerView in PomodoroFocusTimer/PomodoroFocusTimer/Views/ActiveTimerView.swift (shows CountdownDisplay, TreeVisualization, timer updates)
- [x] T035 [US1] Add navigation from StartSessionView to ActiveTimerView in ContentView when session starts
- [x] T036 [US1] Add session completion logic to ActiveTimerView (auto-navigate to forest when session completes)

**Accessibility**:

- [x] T037 [P] [US1] Add accessibility labels to StartSessionView button (.accessibilityLabel("Start 25-minute focus session"))
- [x] T038 [P] [US1] Add accessibility labels to CountdownDisplay (.accessibilityLabel for minutes/seconds remaining)
- [x] T039 [P] [US1] Add accessibility labels to TreeVisualization (.accessibilityLabel for growth stage)
- [x] T040 [P] [US1] Test VoiceOver navigation through StartSessionView and ActiveTimerView
- [x] T041 [P] [US1] Test Dynamic Type scaling at Extra Large size for all text in US1 views

**Checkpoint**: At this point, User Story 1 & 4 should be fully functional - users can start sessions, see tree growth, complete sessions with background accuracy, and trees are saved

---

## Phase 4: User Story 2 - Pause and Resume Session (Priority: P2)

**Goal**: Allow users to pause an active session, freezing the countdown and tree growth, then resume from the exact paused time while accumulating pause duration correctly.

**Independent Test**: Start a session, pause after 5 minutes, wait 10 seconds, resume, verify countdown continues from paused time (15:00 remaining) and pause duration is accumulated.

### Tests for User Story 2 (TDD - Write First)

- [x] T042 [P] [US2] Write unit test for pause transition in PomodoroFocusTimerTests/SessionManagerTests.swift (verify status = .paused, pausedAt set, notification cancelled)
- [x] T043 [P] [US2] Write unit test for resume transition in PomodoroFocusTimerTests/SessionManagerTests.swift (verify status = .inProgress, totalPausedDuration accumulated, notification rescheduled)
- [x] T044 [P] [US2] Write unit test for multiple pause/resume cycles in PomodoroFocusTimerTests/SessionManagerTests.swift (verify totalPausedDuration accumulates correctly)
- [x] T045 [P] [US2] Write unit test for paused session does not elapse in background in PomodoroFocusTimerTests/SessionManagerTests.swift
- [x] T046 [US2] Write UI test for pause/resume flow in PomodoroFocusTimerUITests/PauseResumeTests.swift (start → pause → verify frozen → resume → complete)

### Implementation for User Story 2

- [x] T047 [US2] Add pause() method to SessionManager in PomodoroFocusTimer/PomodoroFocusTimer/Services/SessionManager.swift (transitions to .paused, stores pausedAt, cancels timer and notification)
- [x] T048 [US2] Add resume() method to SessionManager in PomodoroFocusTimer/PomodoroFocusTimer/Services/SessionManager.swift (accumulates pause duration, transitions to .inProgress, reschedules notification)
- [x] T049 [US2] Add rescheduleAfterResume() method to NotificationService in PomodoroFocusTimer/PomodoroFocusTimer/Services/NotificationService.swift (calculates remaining time, schedules new notification)
- [x] T050 [US2] Add Pause button to ActiveTimerView in PomodoroFocusTimer/PomodoroFocusTimer/Views/ActiveTimerView.swift (visible when session is active)
- [x] T051 [US2] Add Resume button to ActiveTimerView in PomodoroFocusTimer/PomodoroFocusTimer/Views/ActiveTimerView.swift (visible when session is paused, replaces Pause button)
- [x] T052 [US2] Add visual indicator to ActiveTimerView when session is paused (e.g., "Paused" text, dimmed tree)
- [x] T053 [P] [US2] Add accessibility label to Pause button (.accessibilityLabel("Pause session"))
- [x] T054 [P] [US2] Add accessibility label to Resume button (.accessibilityLabel("Resume session"))

**Checkpoint**: At this point, User Stories 1, 2, and 4 should work independently - users can start, pause, resume, and complete sessions with accurate timing

---

## Phase 5: User Story 3 - Abandon Session (Priority: P2)

**Goal**: Allow users to cancel/quit an active or paused session with a confirmation dialog, marking the session as abandoned (not saved to forest), with no stats increment.

**Independent Test**: Start a session, cancel after 10 minutes, confirm the kill action, verify tree does not appear in forest and stats do not change.

### Tests for User Story 3 (TDD - Write First)

- [x] T055 [P] [US3] Write unit test for cancel transition in PomodoroFocusTimerTests/SessionManagerTests.swift (verify status = .abandoned, no CompletedTree created)
- [x] T056 [P] [US3] Write unit test for abandoned session persisted in PomodoroFocusTimerTests/SessionManagerTests.swift (verify Session record exists with .abandoned status)
- [x] T057 [P] [US3] Write unit test for cancel from paused state in PomodoroFocusTimerTests/SessionManagerTests.swift (verify works from both active and paused)
- [x] T058 [US3] Write UI test for abandon session flow in PomodoroFocusTimerUITests/AbandonSessionTests.swift (start → cancel → confirm → verify no tree saved)
- [x] T059 [US3] Write UI test for cancel dialog dismissal in PomodoroFocusTimerUITests/AbandonSessionTests.swift (start → cancel → "No, Keep Going" → session continues)

### Implementation for User Story 3

- [x] T060 [US3] Add cancel() method to SessionManager in PomodoroFocusTimer/PomodoroFocusTimer/Services/SessionManager.swift (transitions to .abandoned, saves session, cancels notification, transitions to idle)
- [x] T061 [US3] Add Cancel button to ActiveTimerView in PomodoroFocusTimer/PomodoroFocusTimer/Views/ActiveTimerView.swift (visible when session is active or paused)
- [x] T062 [US3] Add confirmation dialog to ActiveTimerView (shows "Quitting will kill your tree. Are you sure?" with "Yes, Quit" and "No, Keep Going" buttons)
- [x] T063 [US3] Wire Cancel button to show confirmation dialog, then call SessionManager.cancel() if confirmed
- [x] T064 [US3] Add navigation back to StartSessionView when session is abandoned (Fixed: Now dismisses from both active and paused states)
- [x] T065 [P] [US3] Add accessibility label to Cancel button (.accessibilityLabel("Cancel session"))
- [x] T066 [P] [US3] Add accessibility labels to confirmation dialog buttons

**Checkpoint**: At this point, User Stories 1-4 should work independently - users can start, pause, resume, complete, or abandon sessions

---

## Phase 6: User Story 5 - View Forest and Stats (Priority: P3)

**Goal**: Allow users to view a grid of all their completed trees and see statistics (total trees, total focus time, today's count, daily streak).

**Independent Test**: Complete 3 sessions across 2 days, then view the forest and stats to verify correct counts and streak calculation.

### Tests for User Story 5 (TDD - Write First)

- [x] T067 [P] [US5] Write unit test for stats calculation in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify totalTreesPlanted = count of CompletedTree)
- [x] T068 [P] [US5] Write unit test for total focus time calculation in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify totalFocusTimeMinutes = trees × 25)
- [x] T069 [P] [US5] Write unit test for today's count in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify resets at midnight)
- [x] T070 [P] [US5] Write unit test for streak calculation in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify consecutive days from today backward)
- [x] T071 [P] [US5] Write unit test for streak reset on skipped day in PomodoroFocusTimerTests/StatsCalculationTests.swift
- [x] T071a [P] [US5] Write unit test for 30+ day streak calculation in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify no off-by-one errors at day boundaries per SC-012)
- [x] T072 [P] [US5] Write unit test for empty forest (0 trees) in PomodoroFocusTimerTests/StatsCalculationTests.swift (verify "Start your streak today!")
- [x] T073 [US5] Write UI test for forest grid rendering in PomodoroFocusTimerUITests/ForestViewTests.swift (verify 10 trees displayed after completing 10 sessions)
- [x] T074 [US5] Write UI test for stats display in PomodoroFocusTimerUITests/ForestViewTests.swift (verify stats update after session completion)
- [x] T075 [US5] Write UI test for forest grid performance in PomodoroFocusTimerUITests/ForestViewTests.swift (verify 100+ trees scroll at 60fps)

### Implementation for User Story 5

**Services**:

- [x] T076 [US5] Create StatsCalculator class in PomodoroFocusTimer/PomodoroFocusTimer/Services/StatsCalculator.swift with calculateStats() method (queries CompletedTree, returns DailyStats)
- [x] T077 [US5] Implement calculateStreak() private method in StatsCalculator (groups by day, calculates consecutive days from today backward)

**Views**:

- [x] T078 [P] [US5] Create ForestView in PomodoroFocusTimer/PomodoroFocusTimer/Views/ForestView.swift with LazyVGrid for CompletedTree (@Query sorted by completedAt descending)
- [x] T079 [P] [US5] Create StatsView in PomodoroFocusTimer/PomodoroFocusTimer/Views/StatsView.swift (displays total trees, focus time, today's count, streak)
- [x] T080 [US5] Add ForestView to ContentView navigation in PomodoroFocusTimer/PomodoroFocusTimer/ContentView.swift (TabView or NavigationStack item)
- [x] T081 [US5] Add StatsView to ContentView navigation in PomodoroFocusTimer/PomodoroFocusTimer/ContentView.swift (TabView or NavigationStack item)
- [x] T082 [US5] Add LazyVGrid configuration to ForestView (columns: .adaptive(minimum: 80), spacing: 16)
- [x] T083 [US5] Add tree grid item to ForestView (shows completed tree at stage 5, tappable for details if desired)
- [x] T084 [US5] Connect StatsCalculator to StatsView (calculate stats on appear, observe CompletedTree changes)
- [x] T085 [US5] Add formatted stats display to StatsView (Total Trees: N, Total Focus Time: Xh Ym, Today: N trees, Streak: N days)

**Accessibility**:

- [x] T086 [P] [US5] Add accessibility labels to forest grid items (.accessibilityLabel("Completed tree from {date}"))
- [x] T087 [P] [US5] Add accessibility labels to stats text in StatsView
- [x] T088 [P] [US5] Test VoiceOver navigation through ForestView and StatsView
- [x] T089 [P] [US5] Test Dynamic Type scaling for stats text

**Performance**:

- [ ] T090 [US5] Profile forest grid with 100+ trees using Instruments Core Animation (verify 60fps scrolling)
- [ ] T091 [US5] Verify memory usage stays <50MB with 100+ trees using Instruments Allocations

**Checkpoint**: All user stories should now be independently functional - full app experience is complete

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T092 [P] Profile cold start with Instruments App Launch (verify <2s on iPhone 12, mark as FAIL if exceeded per SC-005)
- [ ] T093 [P] Profile tree growth animations with Instruments Core Animation (verify 60fps)
- [ ] T094 [P] Profile active timer view render time (verify <16ms per frame)
- [ ] T095 [P] Test app with 20 sessions per day (verify no performance degradation)
- [ ] T096 [P] Test notification fires within 2 seconds of session completion when backgrounded
- [ ] T097 [P] Test session data persists across app restarts (verify 100% reliability)
- [ ] T098 [P] Test streak calculation accuracy for 30+ consecutive days
- [x] T099 Handle edge case: app force-quit during active session (mark as abandoned on next launch)
- [ ] T100 Handle edge case: notification permission denied (show in-app completion message instead)
- [x] T101 Handle edge case: device time/date change during session (rely on elapsed intervals, not wall-clock time)
- [ ] T102 [P] Add app icon to Assets.xcassets
- [ ] T103 [P] Update app display name in Info.plist (if needed)
- [ ] T104 Code cleanup: Remove unused imports, format code per Swift style guide
- [ ] T105 Code cleanup: Add inline comments for complex logic (streak calculation, background timing)
- [x] T106 Run all unit tests and verify 100% pass rate
- [ ] T107 Run all UI tests and verify 100% pass rate
- [x] T108 Build app in Release configuration and verify no warnings or errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 & 4 (Phase 3): Can start after Foundational - No dependencies on other stories (COMBINED as both are P1 and tightly coupled)
  - User Story 2 (Phase 4): Can start after Foundational - Depends on SessionManager from US1 but independently testable
  - User Story 3 (Phase 5): Can start after Foundational - Depends on SessionManager from US1 but independently testable
  - User Story 5 (Phase 6): Can start after Foundational - Depends on CompletedTree from US1 but independently testable
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 & 4 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories. These are combined because background timing is integral to completing a session.
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends SessionManager from US1 with pause/resume methods
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Extends SessionManager from US1 with cancel method
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Reads CompletedTree data created by US1, but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD per constitution)
- Models before services
- Services before views
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1: Setup**

- T001-T005 can all run in parallel (different directories)

**Phase 2: Foundational**

- T007, T008, T010 can run in parallel (different concerns)

**Phase 3: User Story 1 & 4 Tests**

- T011-T018 can all run in parallel (different test files)

**Phase 3: User Story 1 & 4 Models**

- T021, T022, T023 can all run in parallel (different model files)

**Phase 3: User Story 1 & 4 Components**

- T031, T032 can run in parallel (different component files)

**Phase 3: User Story 1 & 4 Accessibility**

- T037-T041 can all run in parallel (independent accessibility tasks)

**Phase 4: User Story 2 Tests**

- T042-T045 can all run in parallel (different test cases)

**Phase 4: User Story 2 Accessibility**

- T053, T054 can run in parallel

**Phase 5: User Story 3 Tests**

- T055-T057 can all run in parallel (different test cases)

**Phase 5: User Story 3 Accessibility**

- T065, T066 can run in parallel

**Phase 6: User Story 5 Tests**

- T067-T072 can all run in parallel (different test cases)

**Phase 6: User Story 5 Views**

- T078, T079 can run in parallel (different view files)

**Phase 6: User Story 5 Accessibility**

- T086-T089 can all run in parallel

**Phase 7: Polish**

- T092-T098, T100-T103 can all run in parallel (independent validation tasks)

---

## Parallel Example: User Story 1 & 4

```bash
# Launch all tests for User Story 1 & 4 together (TDD - write these first):
Task: "Write unit test for Session model creation in PomodoroFocusTimerTests/ModelTests.swift"
Task: "Write unit test for Session completion transition in PomodoroFocusTimerTests/ModelTests.swift"
Task: "Write unit test for CompletedTree creation in PomodoroFocusTimerTests/ModelTests.swift"
Task: "Write unit test for SessionManager start() in PomodoroFocusTimerTests/SessionManagerTests.swift"
Task: "Write unit test for SessionManager complete() in PomodoroFocusTimerTests/SessionManagerTests.swift"
Task: "Write unit test for background timing accuracy in PomodoroFocusTimerTests/SessionManagerTests.swift"
Task: "Write unit test for timer completion in PomodoroFocusTimerTests/SessionManagerTests.swift"
Task: "Write unit test for tree growth stage calculation in PomodoroFocusTimerTests/SessionManagerTests.swift"

# Launch all models for User Story 1 & 4 together (after tests fail):
Task: "Create Session model in PomodoroFocusTimer/PomodoroFocusTimer/Models/Session.swift"
Task: "Create CompletedTree model in PomodoroFocusTimer/PomodoroFocusTimer/Models/CompletedTree.swift"
Task: "Create DailyStats struct in PomodoroFocusTimer/PomodoroFocusTimer/Models/DailyStats.swift"

# Launch all components for User Story 1 & 4 together:
Task: "Create TreeVisualization component in PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/TreeVisualization.swift"
Task: "Create CountdownDisplay component in PomodoroFocusTimer/PomodoroFocusTimer/Views/Components/CountdownDisplay.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 & 4 (Combined P1 stories)
4. **STOP and VALIDATE**: Test User Story 1 & 4 independently
   - Start a session
   - Background the app for 10 minutes
   - Return and verify countdown is accurate
   - Wait for completion
   - Verify tree saved to forest
   - Verify notification fired
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 & 4 → Test independently → Deploy/Demo (MVP! Core focus session experience)
3. Add User Story 2 → Test independently → Deploy/Demo (Enhanced with pause/resume)
4. Add User Story 3 → Test independently → Deploy/Demo (Enhanced with abandon option)
5. Add User Story 5 → Test independently → Deploy/Demo (Full experience with forest and stats)
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 & 4 (MVP - highest priority)
   - Developer B: User Story 2 (can start in parallel if A completes SessionManager interface early)
   - Developer C: User Story 5 (can start in parallel, reads data created by US1)
3. User Story 3 can be added by any developer after SessionManager exists
4. Stories complete and integrate independently

---

## Summary

**Total Tasks**: 109

**Task Count by User Story**:

- Setup (Phase 1): 5 tasks
- Foundational (Phase 2): 5 tasks
- User Story 1 & 4 (Phase 3): 41 tasks (10 tests + 31 implementation)
- User Story 2 (Phase 4): 13 tasks (5 tests + 8 implementation)
- User Story 3 (Phase 5): 12 tasks (5 tests + 7 implementation)
- User Story 5 (Phase 6): 26 tasks (10 tests + 16 implementation)
- Polish (Phase 7): 17 tasks

**Parallel Opportunities**: 48 tasks marked [P] can run in parallel within their phases

**Independent Test Criteria**:

- **US1 & 4**: Start session → background 10 min → return → verify countdown accurate → complete → verify tree saved + notification
- **US2**: Start → pause → wait → resume → verify countdown continues from paused time → complete
- **US3**: Start → cancel → confirm → verify no tree saved, stats unchanged
- **US5**: Complete 3 sessions across 2 days → view forest → verify 3 trees + correct stats + streak

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Stories 1 & 4 only) = 51 tasks

**TDD Workflow**: All test tasks are included per constitution Principle II. Tests must be written FIRST and FAIL before implementation begins.

**Format Validation**: ✅ All 109 tasks follow the checklist format with checkbox, task ID, [P] marker (where applicable), [Story] label (for US tasks), and file paths.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD workflow per constitution)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- User Stories 1 & 4 are combined in Phase 3 because background timing (US4) is integral to completing a session (US1), and both are P1 priority
- LazyVGrid for forest grid ensures 60fps performance with 100+ trees
- Timestamp-based timing ensures ±5s accuracy over 25 minutes when backgrounded
- SwiftData handles persistence; @Observable handles reactive UI updates
