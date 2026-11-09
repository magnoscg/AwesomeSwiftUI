// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Text filled with a gradient that drifts endlessly through the letters.
///
/// With Reduce Motion on, the gradient stays still.
struct AnimatedGradientText: View {
    let text: String
    var colors: [Color] = [.pink, .orange, .yellow, .mint, .cyan, .purple]
    /// Seconds for the colors to drift one full cycle.
    var duration: Double = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
            Text(text)
                .foregroundStyle(gradient(at: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate))
        }
    }

    /// The gradient holds two copies of the colors and spans two text widths. Sliding it
    /// left by one width lands on an identical picture, so the loop has no visible seam.
    private func gradient(at time: TimeInterval) -> LinearGradient {
        let shift = time.truncatingRemainder(dividingBy: duration) / duration

        return LinearGradient(
            colors: colors + colors + colors.prefix(1),
            startPoint: UnitPoint(x: -shift, y: 0.5),
            endPoint: UnitPoint(x: 2 - shift, y: 0.5)
        )
    }
}

// MARK: - Demo

struct AnimatedGradientTextDemo: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                AnimatedGradientText(text: "Colors that\nnever stand\nstill")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .multilineTextAlignment(.center)
                    .scaleEffect(1.3)

                AnimatedGradientText(text: "Drifting through every letter", colors: [.mint, .cyan, .indigo], duration: 3)
                    .font(.headline)
                    .padding(.top, 48)
            }
            .padding(24)
        }
    }
}

#Preview {
    AnimatedGradientTextDemo()
}
