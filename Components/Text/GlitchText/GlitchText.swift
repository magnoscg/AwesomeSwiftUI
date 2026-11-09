// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Colored copies of the text that jump and flicker in short bursts.
///
/// With Reduce Motion on, the copies rest in a still, slightly split position.
struct GlitchText: View {
    let text: String
    var firstColor: Color = .cyan
    var secondColor: Color = .pink

    /// Ticks per second while flickering, one burst lasts `burstTicks` out of every `cycleTicks`.
    private let ticksPerSecond = 12.0
    private let burstTicks = 10
    private let cycleTicks = 30

    @ScaledMetric(relativeTo: .largeTitle) private var maxOffset = 7.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / ticksPerSecond, paused: reduceMotion)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate * ticksPerSecond)
            let isBursting = !reduceMotion && tick % cycleTicks < burstTicks

            ZStack {
                layer(color: firstColor, tick: tick, seed: 1, restingOffset: -0.3, isBursting: isBursting)
                layer(color: secondColor, tick: tick, seed: 2, restingOffset: 0.3, isBursting: isBursting)
                Text(text)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func layer(color: Color, tick: Int, seed: Double, restingOffset: Double, isBursting: Bool) -> some View {
        let x = isBursting ? (noise(tick, seed: seed) - 0.5) * 2 : restingOffset
        let y = isBursting ? (noise(tick, seed: seed + 10) - 0.5) * 0.8 : 0
        let isVisible = !isBursting || noise(tick, seed: seed + 20) > 0.2

        return Text(text)
            .foregroundStyle(color)
            .offset(x: x * maxOffset, y: y * maxOffset)
            .opacity(isVisible ? 1 : 0)
    }

    /// A repeatable pseudo-random value in 0..<1.
    private func noise(_ tick: Int, seed: Double) -> Double {
        let value = sin(Double(tick) * 12.9898 + seed * 78.233) * 43_758.5453
        return value - value.rounded(.down)
    }
}

// MARK: - Demo

struct GlitchTextDemo: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                GlitchText(text: "GLITCH")
                    .font(.system(.largeTitle, design: .monospaced, weight: .black))
                    .scaleEffect(1.6)

                GlitchText(text: "SIGNAL LOST", firstColor: .green, secondColor: .purple)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .padding(.top, 36)
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    GlitchTextDemo()
}
