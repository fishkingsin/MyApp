//
//  CountdownDisplay.swift
//  PomodoroFocusTimer
//
//  Created by Claude on 16/1/2026.
//

import SwiftUI

struct CountdownDisplay: View {
    let remainingSeconds: Int

    private var minutes: Int {
        remainingSeconds / 60
    }

    private var seconds: Int {
        remainingSeconds % 60
    }

    private var timeString: String {
        String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .accessibilityIdentifier("CountdownDisplay")
            .accessibilityLabel("\(minutes) 分 \(seconds) 秒剩餘")
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownDisplay(remainingSeconds: 25 * 60)
        CountdownDisplay(remainingSeconds: 10 * 60 + 30)
        CountdownDisplay(remainingSeconds: 60)
    }
}
