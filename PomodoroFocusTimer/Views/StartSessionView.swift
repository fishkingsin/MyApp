//
//  StartSessionView.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI
import SwiftData

struct StartSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager: SessionManager?

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App title or logo area
            VStack(spacing: 12) {
                Image(systemName: "tree.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.green)

                Text("森林專注")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("培育你的專注森林")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Start Session button
            Button {
                startSession()
            } label: {
                Text("開始專注")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .accessibilityLabel("開始 25 分鐘專注時段")

            Spacer()
        }
        .padding()
        #if os(iOS)
        .fullScreenCover(item: $sessionManager) { manager in
            ActiveTimerView(sessionManager: manager)
        }
        #else
        .sheet(item: $sessionManager) { manager in
            ActiveTimerView(sessionManager: manager)
        }
        #endif
    }

    private func startSession() {
        print("🚀 Starting session...")

        // Create new session manager
        let manager = SessionManager(modelContext: modelContext, notificationService: NotificationService.shared)

        // Start the session
        Task {
            print("⏱️ Calling manager.start()...")
            await manager.start()
            print("✅ Session started - State: \(manager.sessionState), Remaining: \(manager.remainingSeconds)")

            // Show the timer view by setting the manager (triggers fullScreenCover)
            await MainActor.run {
                self.sessionManager = manager
            }
        }
    }
}

// Make SessionManager Identifiable so it can be used with fullScreenCover(item:)
extension SessionManager: Identifiable {
    nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

#Preview {
    StartSessionView()
        .modelContainer(for: [Session.self, CompletedTree.self], inMemory: true)
}
