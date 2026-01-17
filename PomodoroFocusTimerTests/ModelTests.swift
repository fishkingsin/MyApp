//
//  ModelTests.swift
//  PomodoroFocusTimerTests
//
//  Created by Claude on 16/1/2026.
//

import Testing
import SwiftData
import Foundation
@testable import PomodoroFocusTimer

struct ModelTests {

    // T011: Write unit test for Session model creation
    @Test("Session model creation with initial state")
    @MainActor func testSessionCreation() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // Act
        let session = Session(
            startedAt: Date(),
            totalPausedDuration: 0,
            status: .inProgress
        )
        context.insert(session)

        // Assert
        #expect(session.status == .inProgress)
        #expect(session.totalPausedDuration == 0)
        #expect(session.completedAt == nil)
        #expect(session.startedAt <= Date())
    }

    // T012: Write unit test for Session completion transition
    @Test("Session completion transition sets completedAt and status")
    @MainActor func testSessionCompletion() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let session = Session(startedAt: Date(), status: .inProgress)
        context.insert(session)

        // Act
        session.status = .completed
        session.completedAt = Date()

        // Assert
        #expect(session.status == .completed)
        #expect(session.completedAt != nil)
        #expect(session.completedAt! > session.startedAt)
    }

    // T013: Write unit test for CompletedTree creation
    @Test("CompletedTree creation with 1:1 relationship to Session")
    @MainActor func testCompletedTreeCreation() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let session = Session(startedAt: Date(), status: .completed)
        session.completedAt = Date()
        context.insert(session)

        // Act
        let tree = CompletedTree(session: session, completedAt: session.completedAt!)
        context.insert(tree)

        // Assert
        #expect(tree.session.id == session.id)
        #expect(tree.completedAt == session.completedAt)
        #expect(tree.session.status == .completed)
    }
}
