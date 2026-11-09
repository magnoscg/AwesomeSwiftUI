// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Particles that drift along a smooth field of angles.
///
/// Every frame is computed from the time alone, so there is no state to keep.
/// With Reduce Motion on, it draws one still frame. It looks best on a dark background.
struct FlowFieldParticles: View {
    var count = 260
    var colors: [Color] = [.cyan, .indigo, .pink]
    var speed = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = reduceMotion ? 8 : context.date.timeIntervalSinceReferenceDate * max(speed, 0)

            Canvas { canvas, size in
                canvas.blendMode = .plusLighter
                let palette = colors.isEmpty ? [Color.white] : colors
                for index in 0..<FlowFieldParticlesMath.clampedCount(count) {
                    let streak = FlowFieldParticlesMath.streak(index: index, time: time, size: size)
                    guard !streak.points.isEmpty else { continue }

                    var path = Path()
                    path.addLines(streak.points)
                    canvas.stroke(
                        path,
                        with: .color(palette[index % palette.count].opacity(streak.opacity)),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct FlowFieldParticlesStreak {
    var points: [CGPoint]
    var opacity: Double
}

enum FlowFieldParticlesMath {
    static func clampedCount(_ count: Int) -> Int {
        min(max(count, 0), 2_000)
    }

    /// The part of `value` after the decimal point, always in `0..<1`.
    static func fraction(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        let part = value - floor(value)
        return part < 1 ? part : 0
    }

    /// The direction of the flow, in radians, at a point of the canvas.
    static func angle(x: Double, y: Double, time: Double) -> Double {
        let across = sin(x * 0.007 + time * 0.13) + cos(y * 0.009 - time * 0.11)
        let diagonal = sin((x + y) * 0.004 + time * 0.07)
        return (across + diagonal) * .pi * 0.7
    }

    /// Follows the field from where a particle was born to where it is now, and keeps its tail.
    static func streak(
        index: Int,
        time: Double,
        size: CGSize,
        steps: Int = 24,
        trail: Int = 8
    ) -> FlowFieldParticlesStreak {
        guard size.width > 0, size.height > 0, steps > 0, trail > 0 else {
            return FlowFieldParticlesStreak(points: [], opacity: 0)
        }

        let seed = Double(index)
        let lifetime = 3 + fraction(seed * 0.317) * 3
        let clock = time / lifetime + fraction(seed * 0.131)
        let age = fraction(clock)
        let generation = clock.isFinite ? floor(clock) : 0

        let margin = 60.0
        var x = fraction(0.5 + seed * 0.754_877 + generation * 0.37) * (size.width + margin * 2) - margin
        var y = fraction(0.5 + seed * 0.569_840 + generation * 0.61) * (size.height + margin * 2) - margin
        let stepLength = age * 150 / Double(steps)

        var points: [CGPoint] = []
        points.reserveCapacity(min(trail, steps) + 1)
        for step in 0...steps {
            if step >= steps - trail {
                points.append(CGPoint(x: x, y: y))
            }
            let direction = angle(x: x, y: y, time: time)
            x += cos(direction) * stepLength
            y += sin(direction) * stepLength
        }
        return FlowFieldParticlesStreak(points: points, opacity: sin(age * .pi) * 0.9)
    }
}

// MARK: - Demo

struct FlowFieldParticlesDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.02, blue: 0.1), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            FlowFieldParticles(count: 420)
                .ignoresSafeArea()

            Text("Flow Field")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 12)
        }
    }
}

#Preview {
    FlowFieldParticlesDemo()
}
