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
            return "\(hours)小時 \(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var streakDisplay: String {
        if currentStreak == 0 {
            return "今天開始你的連續紀錄！"
        } else {
            return "\(currentStreak) 天"
        }
    }
}
