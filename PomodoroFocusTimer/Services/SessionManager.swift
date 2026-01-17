//
//  SessionManager.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import Foundation
import SwiftData
import Combine
import SwiftUI

enum SessionState {
    case idle
    case active
    case paused
}

@MainActor
@Observable
class SessionManager {
    // Observable state
    private(set) var sessionState: SessionState = .idle
    private(set) var remainingSeconds: Int = 0
    private(set) var currentSession: Session?

    // Dependencies
    private let modelContext: ModelContext
    private let notificationService: NotificationServiceProtocol

    // Combine timer
    private var timerCancellable: AnyCancellable?
    private var scenePhaseObserver: AnyCancellable?

    // Constants
    private let sessionDuration: TimeInterval = 25 * 60 // 25 minutes

    init(modelContext: ModelContext, notificationService: NotificationServiceProtocol) {
        self.modelContext = modelContext
        self.notificationService = notificationService
    }

    // MARK: - T025: start() method

    func start() async {
        // Create new session
        let session = Session(
            startedAt: Date(),
            totalPausedDuration: 0,
            status: .inProgress
        )
        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            debugPrint("Error saving session: \(error)")
            return
        }

        currentSession = session
        sessionState = .active
        remainingSeconds = Int(sessionDuration)

        // T027: Add Combine timer
        startTimer()

        // Schedule notification for 25 minutes
        await notificationService.scheduleSessionCompletion(
            sessionID: session.id,
            timeInterval: sessionDuration
        )
    }

    // MARK: - T026: complete() method

    func complete() async {
        guard let session = currentSession else { return }

        session.status = .completed
        session.completedAt = Date()

        // Create CompletedTree
        let tree = CompletedTree(
            session: session,
            completedAt: session.completedAt!
        )
        modelContext.insert(tree)

        do {
            try modelContext.save()
        } catch {
            debugPrint("Error saving completed tree: \(error)")
            return
        }

        // Cancel notification (already completed)
        notificationService.cancelSessionNotification(sessionID: session.id)

        // T026: Transition to idle
        stopTimer()
        currentSession = nil
        sessionState = .idle
        remainingSeconds = 0
    }

    // MARK: - T047: pause() method

    func pause() async {
        guard let session = currentSession else { return }
        guard session.status == .inProgress else { return }

        // Transition to paused
        session.status = .paused
        session.pausedAt = Date()

        // Update state
        sessionState = .paused

        // Stop the UI timer
        stopTimer()

        // Cancel notification (will reschedule on resume)
        notificationService.cancelSessionNotification(sessionID: session.id)

        // Save session
        do {
            try modelContext.save()
        } catch {
            debugPrint("Error saving paused session: \(error)")
        }

        debugPrint("⏸️ Session paused at \(session.pausedAt!)")
    }

    // MARK: - T048: resume() method

    func resume() async {
        guard let session = currentSession else { return }
        guard session.status == .paused else { return }
        guard let pausedAt = session.pausedAt else { return }

        // Calculate how long we were paused
        let pauseDuration = Date().timeIntervalSince(pausedAt)
        session.totalPausedDuration += pauseDuration
        session.pausedAt = nil

        // Transition back to in progress
        session.status = .inProgress
        sessionState = .active

        // Restart the UI timer
        startTimer()

        // Recalculate remaining time
        await recalculateProgress()

        // Reschedule notification with remaining time
        await notificationService.rescheduleSessionNotification(
            sessionID: session.id,
            timeInterval: TimeInterval(remainingSeconds)
        )

        // Save session
        do {
            try modelContext.save()
        } catch {
            debugPrint("Error saving resumed session: \(error)")
        }

        debugPrint("▶️ Session resumed - Pause duration: \(pauseDuration)s, Total paused: \(session.totalPausedDuration)s")
    }

    // MARK: - T060: cancel() method

    func cancel() async {
        guard let session = currentSession else { return }

        // Mark session as abandoned
        session.status = .abandoned

        // Save the abandoned session (for records)
        do {
            try modelContext.save()
        } catch {
            debugPrint("Error saving abandoned session: \(error)")
        }

        // Cancel notification
        notificationService.cancelSessionNotification(sessionID: session.id)

        // Stop timer and transition to idle
        stopTimer()
        currentSession = nil
        sessionState = .idle
        remainingSeconds = 0

        debugPrint("🛑 Session abandoned")
    }

    // MARK: - T027: Combine timer

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.recalculateProgress()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - T028: recalculateProgress() - Timestamp-based timing

    func recalculateProgress() async {
        guard let session = currentSession else { return }

        // Don't update progress if paused
        if session.status == .paused {
            return
        }

        guard session.status == .inProgress else { return }

        // Calculate elapsed time from stored timestamp
        let elapsed = Date().timeIntervalSince(session.startedAt) - session.totalPausedDuration
        let remaining = sessionDuration - elapsed

        remainingSeconds = max(0, Int(remaining))

        // T017: Auto-complete when timer reaches 0
        if remainingSeconds <= 0 {
            await complete()
        }
    }

    // MARK: - T029: scenePhase observer

    func observeScenePhase(_ scenePhase: ScenePhase) async {
        switch scenePhase {
        case .active:
            await recalculateProgress()
        case .background, .inactive:
            break
        @unknown default:
            break
        }
    }

    // MARK: - T030: treeGrowthStage computed property

    var treeGrowthStage: Int {
        guard sessionState == .active || sessionState == .paused else { return 1 }
        guard let session = currentSession else { return 1 }

        let elapsed = Date().timeIntervalSince(session.startedAt) - session.totalPausedDuration
        let progress = elapsed / sessionDuration

        switch progress {
        case 0..<0.25:
            return 1
        case 0.25..<0.5:
            return 2
        case 0.5..<0.75:
            return 3
        case 0.75..<1.0:
            return 4
        default:
            return 5
        }
    }
}
