//
//  ForestView.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI
import SwiftData

struct ForestView: View {
    @Query(sort: \CompletedTree.completedAt, order: .reverse) private var completedTrees: [CompletedTree]
    @Environment(\.modelContext) private var modelContext

    // T082: LazyVGrid configuration
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if completedTrees.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "tree.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.green.opacity(0.3))

                        Text("尚未有樹木")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("完成你的第一次專注時段來種植樹木！")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // T083: Tree grid with completed trees at stage 5
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(completedTrees) { tree in
                            VStack(spacing: 8) {
                                // Show completed tree (stage 5)
                                Image(systemName: "tree.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                    .accessibilityLabel("完成的樹木，來自 \(tree.completedAt.formatted(date: .abbreviated, time: .omitted))")

                                Text(tree.completedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            #if os(iOS)
                            .background(Color(uiColor: .systemGray6))
                            #else
                            .background(Color.gray.opacity(0.1))
                            #endif
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("森林")
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ForestView")
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Session.self, CompletedTree.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Add some sample trees for preview
    let context = container.mainContext
    for i in 0..<10 {
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

    return ForestView()
        .modelContainer(container)
}
