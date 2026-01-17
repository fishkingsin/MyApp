//
//  DailyStats.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

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
