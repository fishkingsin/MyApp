//
//  ActiveTimerView.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI
import SwiftData

struct ActiveTimerView: View {
    @Bindable var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    // T062: Confirmation dialog state
    @State private var showingCancelConfirmation = false

    var body: some View {
        ZStack {
            // Background
            #if os(iOS)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            #else
            Color.white
                .ignoresSafeArea()
            #endif

            VStack(spacing: 40) {
                Spacer()

                // Tree visualization
                TreeVisualization(stage: sessionManager.treeGrowthStage)
                    .padding()

                // Countdown display
                CountdownDisplay(remainingSeconds: sessionManager.remainingSeconds)
                    .padding()

                Spacer()

                // T050-T052: Pause/Resume buttons
                HStack(spacing: 20) {
                    if sessionManager.sessionState == .active {
                        // T050: Pause button (visible when active)
                        Button {
                            Task {
                                await sessionManager.pause()
                            }
                        } label: {
                            Label("Pause", systemImage: "pause.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("Pause session")
                    } else if sessionManager.sessionState == .paused {
                        // T051: Resume button (visible when paused)
                        Button {
                            Task {
                                await sessionManager.resume()
                            }
                        } label: {
                            Label("Resume", systemImage: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .accessibilityLabel("Resume session")
                    }

                    // T061: Cancel button (visible when active or paused)
                    if sessionManager.sessionState == .active || sessionManager.sessionState == .paused {
                        Button {
                            showingCancelConfirmation = true
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Cancel session")
                    }
                }
                .padding()

                // T052: Visual indicator when paused
                if sessionManager.sessionState == .paused {
                    VStack(spacing: 8) {
                        Text("Paused")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("Timer is frozen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Session in progress...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Debug info (temporary)
                Text("Stage: \(sessionManager.treeGrowthStage) | Time: \(sessionManager.remainingSeconds)s | State: \(stateDescription)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                Spacer()
            }
            .padding()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            Task {
                await sessionManager.observeScenePhase(newPhase)
            }
        }
        .onChange(of: sessionManager.sessionState) { oldState, newState in
            // T036 & T064: Auto-dismiss when session completes or is abandoned
            if newState == .idle && (oldState == .active || oldState == .paused) {
                dismiss()
            }
        }
        .onAppear {
            debugPrint("ActiveTimerView appeared - State: \(sessionManager.sessionState), Remaining: \(sessionManager.remainingSeconds), Stage: \(sessionManager.treeGrowthStage)")
        }
        // T062-T063: Confirmation dialog
        .alert("Quitting will kill your tree. Are you sure?", isPresented: $showingCancelConfirmation) {
            Button("Yes, Quit", role: .destructive) {
                Task {
                    await sessionManager.cancel()
                    // T064: Dismiss the view
                    dismiss()
                }
            }
            .accessibilityLabel("Yes, quit and kill tree")

            Button("No, Keep Going", role: .cancel) {
                // Dialog dismisses automatically
            }
            .accessibilityLabel("No, keep going with session")
        } message: {
            Text("Your progress will not be saved.")
        }
    }

    private var stateDescription: String {
        switch sessionManager.sessionState {
        case .idle: return "Idle"
        case .active: return "Active"
        case .paused: return "Paused"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Session.self, CompletedTree.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let manager = SessionManager(modelContext: container.mainContext, notificationService: NotificationService.shared)

    ActiveTimerView(sessionManager: manager)
}
