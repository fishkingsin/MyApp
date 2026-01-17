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
                            Label("暫停", systemImage: "pause.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("暫停專注時段")
                    } else if sessionManager.sessionState == .paused {
                        // T051: Resume button (visible when paused)
                        Button {
                            Task {
                                await sessionManager.resume()
                            }
                        } label: {
                            Label("繼續", systemImage: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .accessibilityLabel("繼續專注時段")
                    }

                    // T061: Cancel button (visible when active or paused)
                    if sessionManager.sessionState == .active || sessionManager.sessionState == .paused {
                        Button {
                            showingCancelConfirmation = true
                        } label: {
                            Label("取消", systemImage: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("取消專注時段")
                    }
                }
                .padding()

                // T052: Visual indicator when paused
                if sessionManager.sessionState == .paused {
                    VStack(spacing: 8) {
                        Text("已暫停")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("計時器已凍結")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("專注進行中...")
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
        .alert("放棄將會摧毀你的樹木。確定嗎？", isPresented: $showingCancelConfirmation) {
            Button("是，放棄", role: .destructive) {
                Task {
                    await sessionManager.cancel()
                    // T064: Dismiss the view
                    dismiss()
                }
            }
            .accessibilityLabel("是，放棄並摧毀樹木")

            Button("否，繼續", role: .cancel) {
                // Dialog dismisses automatically
            }
            .accessibilityLabel("否，繼續專注時段")
        } message: {
            Text("你的進度將不會被儲存。")
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
