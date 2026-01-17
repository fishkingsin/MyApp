//
//  StatsView.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: DailyStats?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("載入統計資料...")
                } else if let stats = stats {
                    ScrollView {
                        VStack(spacing: 24) {
                            // T085: Formatted stats display

                            // Total Trees
                            StatCard(
                                title: "總共樹木",
                                value: "\(stats.totalTreesPlanted)",
                                icon: "tree.fill",
                                color: .green
                            )
                            .accessibilityLabel("總共樹木：\(stats.totalTreesPlanted)")

                            // Total Focus Time
                            StatCard(
                                title: "總專注時間",
                                value: stats.totalFocusTimeFormatted,
                                icon: "clock.fill",
                                color: .blue
                            )
                            .accessibilityLabel("總專注時間：\(stats.totalFocusTimeFormatted)")

                            // Today's Count
                            StatCard(
                                title: "今天",
                                value: "\(stats.todaysTreeCount) 棵樹\(stats.todaysTreeCount == 1 ? "" : "")",
                                icon: "calendar",
                                color: .orange
                            )
                            .accessibilityLabel("今天：\(stats.todaysTreeCount) 棵樹")

                            // Streak
                            StatCard(
                                title: "連續天數",
                                value: stats.streakDisplay,
                                icon: "flame.fill",
                                color: stats.currentStreak > 0 ? .red : .gray
                            )
                            .accessibilityLabel("連續天數：\(stats.streakDisplay)")

                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Text("無法載入統計資料")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("統計")
            .task {
                await loadStats()
            }
        }
    }

    // T084: Connect StatsCalculator to StatsView
    private func loadStats() async {
        isLoading = true
        let calculator = StatsCalculator(modelContext: modelContext)

        do {
            stats = try await calculator.calculateStats()
        } catch {
            debugPrint("Error loading stats: \(error)")
        }

        isLoading = false
    }
}

// Helper view for stat cards
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .padding()
            #if os(iOS)
            .background(Color(uiColor: .systemGray6))
            #else
            .background(Color.gray.opacity(0.1))
            #endif
            .cornerRadius(16)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Session.self, CompletedTree.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Add sample data
    let context = container.mainContext
    for i in 0..<5 {
        let session = Session(
            startedAt: Date().addingTimeInterval(TimeInterval(-i * 86400 - 25 * 60)),
            totalPausedDuration: 0,
            status: .completed
        )
        session.completedAt = Date().addingTimeInterval(TimeInterval(-i * 86400))
        context.insert(session)

        let tree = CompletedTree(session: session, completedAt: session.completedAt!)
        context.insert(tree)
    }

    return StatsView()
        .modelContainer(container)
}
