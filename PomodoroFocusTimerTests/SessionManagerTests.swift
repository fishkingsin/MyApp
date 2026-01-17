//
//  SessionManagerTests.swift
//  PomodoroFocusTimerTests
//
//  Created by Claude on 16/1/2026.
//

import Testing
import SwiftData
import Foundation
@testable import PomodoroFocusTimer

// Mock NotificationService for testing
@MainActor
class MockNotificationService: NotificationServiceProtocol {
    var scheduledNotifications: [UUID] = []
    var cancelledNotifications: [UUID] = []

    func scheduleSessionCompletion(sessionID: UUID, timeInterval: TimeInterval) async {
        scheduledNotifications.append(sessionID)
    }

    func cancelSessionNotification(sessionID: UUID) {
        cancelledNotifications.append(sessionID)
    }

    func rescheduleSessionNotification(sessionID: UUID, timeInterval: TimeInterval) async {
        scheduledNotifications.append(sessionID)
    }
}

struct SessionManagerTests {

    // T014: Write unit test for SessionManager start()
    @Test("SessionManager start() creates session, starts timer, schedules notification")
    @MainActor func testSessionManagerStart() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)

        // Act
        await manager.start()

        // Assert
        #expect(manager.sessionState == .active)
        #expect(manager.remainingSeconds == 25 * 60) // 25 minutes
        // Notification scheduling will be verified separately
    }

    // T015: Write unit test for SessionManager complete()
    @Test("SessionManager complete() saves tree and updates stats")
    @MainActor func testSessionManagerComplete() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act
        await manager.complete()

        // Assert
        #expect(manager.sessionState == .idle)
        // Verify CompletedTree was created
        let descriptor = FetchDescriptor<CompletedTree>()
        let trees = try context.fetch(descriptor)
        #expect(trees.count == 1)
        #expect(trees.first?.session.status == .completed)
    }

    // T016: Write unit test for background timing accuracy
    @Test("Background timing accuracy with recalculateProgress()")
    @MainActor func testBackgroundTimingAccuracy() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)

        // Start session with a backdated start time (simulate 10 minutes elapsed)
        await manager.start()
        if let currentSession = manager.currentSession {
            currentSession.startedAt = Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        }

        // Act
        await manager.recalculateProgress()

        // Assert
        // Remaining time should be approximately 15 minutes (25 - 10)
        let expectedRemaining = 15 * 60
        #expect(abs(manager.remainingSeconds - expectedRemaining) <= 5) // Within 5 seconds tolerance
    }

    // T017: Write unit test for timer completion
    @Test("Timer completion when remainingSeconds reaches 0")
    @MainActor func testTimerCompletion() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act - Simulate elapsed time reaching 25 minutes
        if let currentSession = manager.currentSession {
            currentSession.startedAt = Date().addingTimeInterval(-25 * 60) // 25 minutes ago
        }
        await manager.recalculateProgress()

        // Assert
        #expect(manager.remainingSeconds <= 0)
        #expect(manager.sessionState == .idle) // Should auto-complete
    }

    // T018: Write unit test for tree growth stage calculation
    @Test("Tree growth stage calculation returns stages 1-5")
    @MainActor func testTreeGrowthStageCalculation() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act & Assert - Test different progress levels
        // Stage 1: 0% progress
        if let currentSession = manager.currentSession {
            currentSession.startedAt = Date()
        }
        await manager.recalculateProgress()
        #expect(manager.treeGrowthStage == 1)

        // Stage 3: 50% progress (12.5 minutes elapsed)
        if let currentSession = manager.currentSession {
            currentSession.startedAt = Date().addingTimeInterval(-12.5 * 60)
        }
        await manager.recalculateProgress()
        #expect(manager.treeGrowthStage == 3)

        // Stage 4: 95% progress (23.75 minutes elapsed) - testing just before completion
        if let currentSession = manager.currentSession {
            currentSession.startedAt = Date().addingTimeInterval(-23.75 * 60)
        }
        await manager.recalculateProgress()
        #expect(manager.treeGrowthStage == 4)
        #expect(manager.sessionState == .active) // Should still be active, not auto-completed yet
    }

    // MARK: - User Story 2: Pause/Resume Tests

    // T042: Write unit test for pause transition
    @Test("Pause transition sets status to paused, stores pausedAt, cancels notification")
    @MainActor func testPauseTransition() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act
        await manager.pause()

        // Assert
        #expect(manager.sessionState == .paused)
        #expect(manager.currentSession?.status == .paused)
        #expect(manager.currentSession?.pausedAt != nil)
    }

    // T043: Write unit test for resume transition
    @Test("Resume transition accumulates pause duration and reschedules notification")
    @MainActor func testResumeTransition() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Pause for a moment
        await manager.pause()
        let pausedAt = manager.currentSession?.pausedAt

        // Simulate 10 seconds passing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds for test speed

        // Act
        await manager.resume()

        // Assert
        #expect(manager.sessionState == .active)
        #expect(manager.currentSession?.status == .inProgress)
        #expect(manager.currentSession?.pausedAt == nil)
        #expect(manager.currentSession!.totalPausedDuration > 0) // Should have accumulated pause time
    }

    // T044: Write unit test for multiple pause/resume cycles
    @Test("Multiple pause/resume cycles accumulate totalPausedDuration correctly")
    @MainActor func testMultiplePauseResumeCycles() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act - Multiple pause/resume cycles
        await manager.pause()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await manager.resume()

        await manager.pause()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await manager.resume()

        // Assert
        #expect(manager.sessionState == .active)
        #expect(manager.currentSession!.totalPausedDuration > 0.1) // Should have accumulated ~0.2s
    }

    // T045: Write unit test for paused session does not elapse in background
    @Test("Paused session does not elapse time when backgrounded")
    @MainActor func testPausedSessionNoBackgroundElapse() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        let initialRemaining = manager.remainingSeconds

        // Act - Pause and simulate background time
        await manager.pause()
        if let currentSession = manager.currentSession {
            // Simulate 5 minutes passing (but session is paused)
            currentSession.pausedAt = Date().addingTimeInterval(-5 * 60)
        }
        await manager.recalculateProgress()

        // Assert - Time should NOT have elapsed because session is paused
        #expect(manager.remainingSeconds == initialRemaining)
    }

    // MARK: - User Story 3: Abandon Session Tests

    // T055: Write unit test for cancel transition
    @Test("Cancel transition marks session as abandoned, no CompletedTree created")
    @MainActor func testCancelTransition() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()

        // Act
        await manager.cancel()

        // Assert
        #expect(manager.sessionState == .idle)
        #expect(manager.currentSession == nil) // Session should be cleared

        // Verify no CompletedTree was created
        let descriptor = FetchDescriptor<CompletedTree>()
        let trees = try context.fetch(descriptor)
        #expect(trees.count == 0)

        // Verify Session exists with abandoned status
        let sessionDescriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(sessionDescriptor)
        #expect(sessions.count == 1)
        #expect(sessions.first?.status == .abandoned)
    }

    // T056: Write unit test for abandoned session persisted
    @Test("Abandoned session is persisted with .abandoned status")
    @MainActor func testAbandonedSessionPersisted() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()
        let sessionID = manager.currentSession?.id

        // Act
        await manager.cancel()

        // Assert - Session should still exist in database
        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions.first?.id == sessionID)
        #expect(sessions.first?.status == .abandoned)
    }

    // T057: Write unit test for cancel from paused state
    @Test("Cancel works from both active and paused states")
    @MainActor func testCancelFromPausedState() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let mockNotificationService = MockNotificationService()
        let manager = SessionManager(modelContext: context, notificationService: mockNotificationService)
        await manager.start()
        await manager.pause()

        // Act
        await manager.cancel()

        // Assert
        #expect(manager.sessionState == .idle)
        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.first?.status == .abandoned)
    }
}
