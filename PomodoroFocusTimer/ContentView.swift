//
//  ContentView.swift
//  PomodoroFocusTimer
//
//  Created by James Kong on 11/1/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            // Start Session / Active Timer View
            StartSessionView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            // T080: Forest View
            ForestView()
                .tabItem {
                    Label("Forest", systemImage: "leaf.fill")
                }

            // T081: Stats View
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, CompletedTree.self], inMemory: true)
}
