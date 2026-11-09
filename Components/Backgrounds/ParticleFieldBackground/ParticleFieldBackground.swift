// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Drifting points joined by faint lines when they come close.
///
/// With Reduce Motion on, the field holds still.
struct ParticleFieldBackground: View {
    var color: Color = .white
    var count: Int = 70
    var linkDistance: Double = 105
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed
                let points = (0..<count).map { position(of: $0, at: time, in: size) }

                drawLinks(between: points, in: context)

                for (index, point) in points.enumerated() {
                    let radius = 1.2 + noise(index, 5) * 1.6
                    let dot = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: dot), with: .color(color.opacity(0.85)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Links are grouped into a few opacity levels, so a frame strokes four paths and not hundreds.
    private func drawLinks(between points: [CGPoint], in context: GraphicsContext) {
        var levels = Array(repeating: Path(), count: 4)

        for first in points.indices {
            for second in points.indices where second > first {
                let distance = hypot(points[first].x - points[second].x, points[first].y - points[second].y)
                guard distance < linkDistance else { continue }

                let closeness = 1 - distance / linkDistance
                let level = min(Int(closeness * Double(levels.count)), levels.count - 1)
                levels[level].move(to: points[first])
                levels[level].addLine(to: points[second])
            }
        }

        for (level, path) in levels.enumerated() {
            context.stroke(path, with: .color(color.opacity(0.1 * Double(level + 1))), lineWidth: 0.8)
        }
    }

    private func position(of index: Int, at time: Double, in size: CGSize) -> CGPoint {
        CGPoint(
            x: bounce(noise(index, 1) + time * (noise(index, 2) - 0.5) * 0.08) * size.width,
            y: bounce(noise(index, 3) + time * (noise(index, 4) - 0.5) * 0.04) * size.height
        )
    }

    /// A triangle wave from 0 to 1, so a point turns around at the edge instead of jumping and snapping its links.
    private func bounce(_ value: Double) -> Double {
        abs((value - floor(value)) * 2 - 1)
    }

    /// A repeatable pseudo-random value in 0..<1 for one point and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct ParticleFieldBackgroundDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.22), Color(red: 0.16, green: 0.06, blue: 0.34)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ParticleFieldBackground()

            VStack(spacing: 6) {
                Text("Particle Field")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Points that find each other")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    ParticleFieldBackgroundDemo()
}
