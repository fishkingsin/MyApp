//
//  TreeVisualization.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI

struct TreeVisualization: View {
    let stage: Int

    private var treeSFSymbol: String {
        switch stage {
        case 1:
            return "leaf"
        case 2:
            return "leaf.fill"
        case 3:
            return "tree"
        case 4:
            return "tree.fill"
        case 5:
            return "tree.circle.fill"
        default:
            return "tree.fill"
        }
    }

    var body: some View {
        Image(systemName: treeSFSymbol)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(.green)
            .animation(.easeInOut(duration: 0.8), value: stage)
            .accessibilityIdentifier("TreeVisualization")
            .accessibilityLabel("樹木生長階段 \(stage) / 5")
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(1...5, id: \.self) { stage in
            TreeVisualization(stage: stage)
        }
    }
}
