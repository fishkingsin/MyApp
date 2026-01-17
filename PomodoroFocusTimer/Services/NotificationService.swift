//
//  NotificationService.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import Foundation
import UserNotifications

// Protocol for notification service to allow mocking in tests
@MainActor
protocol NotificationServiceProtocol {
    func scheduleSessionCompletion(sessionID: UUID, timeInterval: TimeInterval) async
    func cancelSessionNotification(sessionID: UUID)
    func rescheduleSessionNotification(sessionID: UUID, timeInterval: TimeInterval) async
}

@MainActor
class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()

    init() {}

    // T024: Schedule notification for session completion
    func scheduleSessionCompletion(sessionID: UUID, timeInterval: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "你的樹木完成了！"
        content.body = "做得好！你的樹木已儲存到森林。"
        content.sound = .default
        content.categoryIdentifier = "SESSION_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "session-complete-\(sessionID.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            debugPrint("Scheduled notification for session \(sessionID) in \(timeInterval) seconds")
        } catch {
            debugPrint("Error scheduling notification: \(error)")
        }
    }

    // Cancel notification for a specific session
    func cancelSessionNotification(sessionID: UUID) {
        let identifier = "session-complete-\(sessionID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        debugPrint("Cancelled notification for session \(sessionID)")
    }

    // Reschedule notification with new time interval (for pause/resume)
    func rescheduleSessionNotification(sessionID: UUID, timeInterval: TimeInterval) async {
        cancelSessionNotification(sessionID: sessionID)
        await scheduleSessionCompletion(sessionID: sessionID, timeInterval: timeInterval)
    }
}
