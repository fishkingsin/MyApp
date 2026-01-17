//
//  CompletedTree.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftData
import Foundation

@Model
final class CompletedTree {
    // Primary identifier
    var id: UUID

    // Reference to source session
    var session: Session

    // Completion timestamp (denormalized for query performance)
    var completedAt: Date

    // Computed properties
    var dayKey: String {
        // Format: "2026-01-14" for grouping by day
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: completedAt)
    }

    init(
        id: UUID = UUID(),
        session: Session,
        completedAt: Date
    ) {
        self.id = id
        self.session = session
        self.completedAt = completedAt
    }
}
