//
//  StatsCalculator.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import Foundation
import SwiftData

@MainActor
class StatsCalculator {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // T076: Calculate stats from CompletedTree data
    func calculateStats() async throws -> DailyStats {
        // Fetch all completed trees
        let descriptor = FetchDescriptor<CompletedTree>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let trees = try modelContext.fetch(descriptor)

        // Total trees planted
        let totalTreesPlanted = trees.count

        // Total focus time (each tree = 25 minutes)
        let totalFocusTimeMinutes = totalTreesPlanted * 25

        // Today's count
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaysTreeCount = trees.filter { tree in
            calendar.isDate(tree.completedAt, inSameDayAs: today)
        }.count

        // Current streak
        let currentStreak = calculateStreak(from: trees)

        return DailyStats(
            totalTreesPlanted: totalTreesPlanted,
            totalFocusTimeMinutes: totalFocusTimeMinutes,
            todaysTreeCount: todaysTreeCount,
            currentStreak: currentStreak
        )
    }

    // T077: Calculate streak (consecutive days from today backward)
    private func calculateStreak(from trees: [CompletedTree]) -> Int {
        guard !trees.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group trees by day
        var treeDays = Set<Date>()
        for tree in trees {
            let day = calendar.startOfDay(for: tree.completedAt)
            treeDays.insert(day)
        }

        // Check if there's a tree today
        guard treeDays.contains(today) else {
            return 0
        }

        // Count consecutive days from today backward
        var streak = 0
        var currentDay = today

        while treeDays.contains(currentDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }
            currentDay = previousDay
        }

        return streak
    }
}
