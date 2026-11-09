// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum CountingNumberTextMath {
    /// The number at `progress`, from 0 to 1. Works in `Double`, so extreme values cannot overflow.
    static func value(from: Int, to: Int, progress: Double) -> Int {
        guard progress < 1 else { return to }
        let exact = (Double(from) + (Double(to) - Double(from)) * progress).rounded()
        let sample = Int(exactly: exact) ?? (exact > 0 ? .max : .min)
        return min(max(sample, min(from, to)), max(from, to))
    }
}

/// A number that counts to its new value, with its digits rolling into place.
///
/// With Reduce Motion on, it jumps straight to the value.
struct CountingNumberText: View {
    let value: Int
    var duration: Double = 1.2
    var format: IntegerFormatStyle<Int> = .number

    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(shown, format: format)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(shown)))
            .accessibilityLabel(Text(value, format: format))
            .task(id: value) { await count() }
    }

    /// Passes through intermediate values, slowing down as it gets close.
    private func count() async {
        guard !reduceMotion else {
            shown = value
            return
        }

        let from = shown
        let steps = max(Int(duration * 24), 1)

        for step in 1...steps {
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
            guard !Task.isCancelled else { return }

            let eased = 1 - pow(1 - Double(step) / Double(steps), 3)
            withAnimation(.snappy(duration: 0.2)) {
                shown = CountingNumberTextMath.value(from: from, to: value, progress: eased)
            }
        }
    }
}

// MARK: - Demo

struct CountingNumberTextDemo: View {
    @State private var steps = 0
    @State private var calories = 0
    @State private var minutes = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                statistic("Steps", systemImage: "figure.walk", value: steps)
                statistic("Calories", systemImage: "flame.fill", value: calories)
                statistic("Minutes", systemImage: "timer", value: minutes)
            }
            .padding(24)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.3))
                steps += 12_480
                calories += 2_347
                minutes += 86
                try? await Task.sleep(for: .seconds(1.9))
            }
        }
    }

    private func statistic(_ title: String, systemImage: String, value: Int) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Spacer()

            CountingNumberText(value: value)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(.white.opacity(0.16), in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CountingNumberTextDemo()
}
