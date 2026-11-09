// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum AnimatedGradientBackgroundMath {
    /// The palette index for a position, also when a negative speed runs time backwards.
    static func index(at position: Double, count: Int) -> Int {
        (Int(floor(position)) % count + count) % count
    }
}

/// A linear gradient whose colors drift along it while its direction slowly turns.
///
/// With Reduce Motion on, it shows a still gradient.
struct AnimatedGradientBackground: View {
    var colors: [Color] = [.indigo, .purple, .pink, .orange]
    /// How many color steps pass each second.
    var speed: Double = 0.2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed
            let angle = time * 0.5
            let reach = CGSize(width: cos(angle) * 0.75, height: sin(angle) * 0.75)

            LinearGradient(
                colors: driftedColors(at: time),
                startPoint: UnitPoint(x: 0.5 - reach.width, y: 0.5 - reach.height),
                endPoint: UnitPoint(x: 0.5 + reach.width, y: 0.5 + reach.height)
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// Each stop blends from one palette color to the next, wrapping around so the drift never ends.
    private func driftedColors(at time: Double) -> [Color] {
        guard colors.count > 1 else { return colors + colors }

        return colors.indices.map { index in
            let position = time + Double(index)
            let lower = AnimatedGradientBackgroundMath.index(at: position, count: colors.count)
            let upper = (lower + 1) % colors.count
            return colors[lower].mix(with: colors[upper], by: position - floor(position))
        }
    }
}

// MARK: - Demo

struct AnimatedGradientBackgroundDemo: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 6) {
                Text("Good Evening")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Colors that never sit still")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    AnimatedGradientBackgroundDemo()
}
