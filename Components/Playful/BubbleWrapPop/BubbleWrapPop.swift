// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A sheet of bubbles that pop with a quick shrink and stay flat until `popped` is cleared.
struct BubbleWrapPop: View {
    @Binding var popped: Set<Int>
    var columns: Int = 6
    var count: Int = 48
    var tint: Color = .cyan

    var body: some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(max(columns, 1), 16))

        LazyVGrid(columns: grid, spacing: 8) {
            ForEach(0..<min(max(count, 0), 600), id: \.self) { index in
                BubbleWrapPopBubble(index: index, tint: tint, isPopped: popped.contains(index)) {
                    popped.insert(index)
                }
            }
        }
        .sensoryFeedback(trigger: popped.count) { old, new in
            new > old ? .impact(flexibility: .soft, intensity: 0.8) : nil
        }
    }
}

private struct BubbleWrapPopBubble: View {
    let index: Int
    let tint: Color
    let isPopped: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: isPopped ? [tint.opacity(0.12), tint.opacity(0.2)] : [.white.opacity(0.9), tint.opacity(0.55), tint.opacity(0.85)],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: 44
                    )
                )
                .overlay {
                    Circle().strokeBorder(.white.opacity(isPopped ? 0.15 : 0.5), lineWidth: 1)
                }
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(isPopped ? 0.78 : 1)
                .shadow(color: tint.opacity(isPopped ? 0 : 0.35), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isPopped)
        .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.45), value: isPopped)
        .accessibilityLabel("Bubble \(index + 1)")
        .accessibilityValue(isPopped ? "Popped" : "Not popped")
    }
}

// MARK: - Demo

struct BubbleWrapPopDemo: View {
    @State private var popped: Set<Int> = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Bubble Wrap")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("\(popped.count) of 48 popped")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                BubbleWrapPop(popped: $popped)

                Button("Reset") {
                    withAnimation(reduceMotion ? nil : .smooth) { popped = [] }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(popped.isEmpty)
            }
            .padding(20)
        }
    }
}

#Preview {
    BubbleWrapPopDemo()
}
