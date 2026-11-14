// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Stars rushing toward the viewer, each one a streak along its line of flight.
///
/// With Reduce Motion on, it shows a still field of dots.
struct StarfieldBackground: View {
    var color: Color = .white
    var count: Int = 320
    /// Depth covered per second, where 1 is the whole way from the horizon to the viewer.
    var speed: Double = 0.22

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let focalLength = max(size.width, size.height) * 0.12
                let trail = reduceMotion ? 0.004 : 0.04

                for index in 0..<count {
                    let cycle = noise(index, 3) + time
                    let depth = max(1 - (cycle - floor(cycle)), 0.02)
                    let angle = noise(index, 1) * 2 * .pi
                    let spread = (0.15 + noise(index, 2) * 1.25) * focalLength

                    func point(atDepth depth: Double) -> CGPoint {
                        CGPoint(
                            x: center.x + cos(angle) * spread / depth,
                            y: center.y + sin(angle) * spread / depth
                        )
                    }

                    var streak = Path()
                    streak.move(to: point(atDepth: min(depth + trail, 1)))
                    streak.addLine(to: point(atDepth: depth))

                    let closeness = 1 - depth
                    context.stroke(
                        streak,
                        with: .color(color.opacity(min(0.15 + closeness * 1.3, 1))),
                        style: StrokeStyle(lineWidth: 0.6 + closeness * 2.2, lineCap: .round)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A repeatable pseudo-random value in 0..<1 for one star and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct StarfieldBackgroundDemo: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.3), .black],
                center: .center,
                startRadius: 0,
                endRadius: 480
            )
            .ignoresSafeArea()

            StarfieldBackground()

            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Warp Speed")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.7), radius: 12)
        }
    }
}

#Preview {
    StarfieldBackgroundDemo()
}
