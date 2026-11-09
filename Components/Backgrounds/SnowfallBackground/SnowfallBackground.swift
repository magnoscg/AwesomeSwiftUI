// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Snow in three depths: small and slow far away, large, fast and slightly blurred up close.
///
/// With Reduce Motion on, the flakes hold still.
struct SnowfallBackground: View {
    var color: Color = .white
    /// Multiplies the number of flakes in every depth.
    var density: Double = 1
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Depth {
        let count: Int
        let radius: ClosedRange<Double>
        let fall: Double
        let sway: Double
        let opacity: Double
        let blur: Double
    }

    private static let depths = [
        Depth(count: 110, radius: 0.8...1.5, fall: 26, sway: 6, opacity: 0.45, blur: 0),
        Depth(count: 60, radius: 1.8...3, fall: 55, sway: 12, opacity: 0.7, blur: 0),
        Depth(count: 18, radius: 3.5...6, fall: 105, sway: 22, opacity: 0.9, blur: 1.5),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed

                for (layer, depth) in Self.depths.enumerated() {
                    context.drawLayer { layerContext in
                        if depth.blur > 0 {
                            layerContext.addFilter(.blur(radius: depth.blur))
                        }
                        layerContext.fill(
                            flakes(of: depth, layer: layer, at: time, in: size),
                            with: .color(color.opacity(depth.opacity))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One path holds every flake of a depth, so each depth is a single fill.
    private func flakes(of depth: Depth, layer: Int, at time: Double, in size: CGSize) -> Path {
        var path = Path()
        let margin = depth.radius.upperBound * 2
        let travel = size.height + margin * 2

        for index in 0..<Int(Double(depth.count) * density) {
            let seed = layer * 1000 + index
            let fallen = (noise(seed, 1) * travel + time * depth.fall).truncatingRemainder(dividingBy: travel)
            let sway = sin(time * (0.5 + noise(seed, 2)) + noise(seed, 3) * 2 * .pi) * depth.sway
            let radius = depth.radius.lowerBound + noise(seed, 4) * (depth.radius.upperBound - depth.radius.lowerBound)

            path.addEllipse(in: CGRect(
                x: noise(seed, 5) * size.width + sway - radius,
                y: fallen - margin - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
        return path
    }

    /// A repeatable pseudo-random value in 0..<1 for one flake and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct SnowfallBackgroundDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.11, blue: 0.27), Color(red: 0.3, green: 0.4, blue: 0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SnowfallBackground()

            VStack(spacing: 10) {
                Image(systemName: "snowflake")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("First Snow")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    SnowfallBackgroundDemo()
}
