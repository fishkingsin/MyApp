//
//  StatsCalculationTests.swift
//  PomodoroFocusTimerTests
//
//  Created by Claude on 16/1/2026.
//

import Testing
import SwiftData
import Foundation
@testable import PomodoroFocusTimer

struct StatsCalculationTests {

    // Helper to create a completed tree at a specific date
    private func createCompletedTree(at date: Date, in context: ModelContext) {
        let session = Session(
            startedAt: date.addingTimeInterval(-25 * 60),
            totalPausedDuration: 0,
            status: .completed
        )
        session.completedAt = date
        context.insert(session)

        let tree = CompletedTree(session: session, completedAt: date)
        context.insert(tree)
    }

    // T067: Write unit test for stats calculation (verify totalTreesPlanted = count of CompletedTree)
    @Test("StatsCalculator calculates total trees planted correctly") @MainActor
    func testTotalTreesPlanted() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // Create 5 completed trees
        let now = Date()
        for i in 0..<5 {
            createCompletedTree(at: now.addingTimeInterval(TimeInterval(i * 60)), in: context)
        }
        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.totalTreesPlanted == 5)
    }

    // T068: Write unit test for total focus time calculation (verify totalFocusTimeMinutes = trees × 25)
    @Test("StatsCalculator calculates total focus time correctly") @MainActor
    func testTotalFocusTime() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // Create 3 completed trees (3 × 25 minutes = 75 minutes)
        let now = Date()
        for i in 0..<3 {
            createCompletedTree(at: now.addingTimeInterval(TimeInterval(i * 60)), in: context)
        }
        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.totalFocusTimeMinutes == 75)
        #expect(stats.totalFocusTimeFormatted == "1h 15m")
    }

    // T069: Write unit test for today's count (verify resets at midnight)
    @Test("StatsCalculator calculates today's count correctly") @MainActor
    func testTodaysCount() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Create 2 trees today and 3 trees yesterday
        createCompletedTree(at: today.addingTimeInterval(60), in: context)
        createCompletedTree(at: today.addingTimeInterval(120), in: context)
        createCompletedTree(at: yesterday.addingTimeInterval(60), in: context)
        createCompletedTree(at: yesterday.addingTimeInterval(120), in: context)
        createCompletedTree(at: yesterday.addingTimeInterval(180), in: context)
        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.todaysTreeCount == 2)
        #expect(stats.totalTreesPlanted == 5)
    }

    // T070: Write unit test for streak calculation (verify consecutive days from today backward)
    @Test("StatsCalculator calculates streak correctly for consecutive days") @MainActor
    func testStreakCalculation() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Create trees for today, yesterday, and 2 days ago (3-day streak)
        createCompletedTree(at: today.addingTimeInterval(3600), in: context)

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        createCompletedTree(at: yesterday.addingTimeInterval(3600), in: context)

        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        createCompletedTree(at: twoDaysAgo.addingTimeInterval(3600), in: context)

        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.currentStreak == 3)
        #expect(stats.streakDisplay == "3 days")
    }

    // T071: Write unit test for streak reset on skipped day
    @Test("StatsCalculator resets streak when a day is skipped") @MainActor
    func testStreakResetOnSkippedDay() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Create trees for today and 3 days ago (skipped yesterday and 2 days ago)
        createCompletedTree(at: today.addingTimeInterval(3600), in: context)

        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        createCompletedTree(at: threeDaysAgo.addingTimeInterval(3600), in: context)

        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        // Streak should only count today (1 day) because yesterday was skipped
        #expect(stats.currentStreak == 1)
        #expect(stats.streakDisplay == "1 day")
    }

    // T071a: Write unit test for 30+ day streak calculation (verify no off-by-one errors at day boundaries)
    @Test("StatsCalculator handles 30+ day streaks correctly") @MainActor
    func testLongStreakCalculation() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Create trees for 35 consecutive days
        for daysAgo in 0..<35 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            createCompletedTree(at: date.addingTimeInterval(3600), in: context)
        }

        try context.save()

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.currentStreak == 35)
        #expect(stats.totalTreesPlanted == 35)
    }

    // T072: Write unit test for empty forest (0 trees) (verify "Start your streak today!")
    @Test("StatsCalculator handles empty forest correctly") @MainActor
    func testEmptyForest() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Session.self, CompletedTree.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let calculator = StatsCalculator(modelContext: context)

        // Act
        let stats = try await calculator.calculateStats()

        // Assert
        #expect(stats.totalTreesPlanted == 0)
        #expect(stats.totalFocusTimeMinutes == 0)
        #expect(stats.todaysTreeCount == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.streakDisplay == "Start your streak today!")
    }
}
