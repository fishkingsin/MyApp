//
//  PomodoroFocusTimerApp.swift
//  PomodoroFocusTimer
//
//  Created by James Kong on 11/1/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PomodoroFocusTimerApp: App {
    // SwiftData ModelContainer configuration
    let modelContainer: ModelContainer

    init() {
        // Configure SwiftData container with models
        do {
            modelContainer = try ModelContainer(
                for: Session.self, CompletedTree.self,
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        // Request notification permissions (fire and forget - will run in background)
        Task.detached {
            await PomodoroFocusTimerApp.requestNotificationPermissions()
            await PomodoroFocusTimerApp.registerNotificationCategories()
        }

        // T099: Handle edge case - mark any active/paused sessions as abandoned on launch
        let container = modelContainer
        Task.detached { @MainActor in
            await PomodoroFocusTimerApp.cleanupAbandonedSessions(modelContext: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Notification Setup

    private static func requestNotificationPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                debugPrint("Notification permissions granted")
            } else {
                debugPrint("Notification permissions denied")
            }
        } catch {
            debugPrint("Error requesting notification permissions: \(error)")
        }
    }

    private static func registerNotificationCategories() async {
        let completeCategory = UNNotificationCategory(
            identifier: "SESSION_COMPLETE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([completeCategory])
    }

    // MARK: - T099: Edge Case Handling

    @MainActor
    private static func cleanupAbandonedSessions(modelContext: ModelContext) async {
        // Fetch all sessions and filter in Swift (Predicate macro doesn't support enum comparisons)
        let descriptor = FetchDescriptor<Session>()

        do {
            let allSessions = try modelContext.fetch(descriptor)
            let abandonedSessions = allSessions.filter { session in
                session.status == .inProgress || session.status == .paused
            }

            for session in abandonedSessions {
                session.status = .abandoned
                debugPrint("⚠️ Marked session as abandoned on app launch: \(session.id)")
            }

            if !abandonedSessions.isEmpty {
                try modelContext.save()
            }
        } catch {
            debugPrint("Error cleaning up abandoned sessions: \(error)")
        }
    }
}
