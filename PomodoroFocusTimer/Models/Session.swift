//
//  Session.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftData
import Foundation

enum SessionStatus: String, Codable {
    case inProgress   // Currently running
    case paused       // Temporarily paused by user
    case completed    // Successfully reached 25:00
    case abandoned    // Cancelled/quit before completion
}

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
