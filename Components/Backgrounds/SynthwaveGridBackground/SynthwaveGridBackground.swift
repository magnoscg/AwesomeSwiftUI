// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum SynthwaveGridBackgroundMath {
    /// Where the horizontal lines sit, from 0 at the horizon to 1 at the bottom edge.
    ///
    /// Each line reaches the next one's place as `phase` goes from 0 to 1, so the motion loops.
    static func horizontalLines(phase: Double, count: Int) -> [Double] {
        guard count > 0, phase.isFinite else { return [] }
        let lines = min(count, 128)
        let wrapped = phase - phase.rounded(.down)
        return (0..<lines).map { pow((Double($0) + wrapped) / Double(lines), 2.4) }
    }
}

/// A retro perspective grid scrolling under a gradient sky with a striped sun.
///
/// With Reduce Motion on, the grid stops moving.
struct SynthwaveGridBackground: View {
    var lineColor: Color = .cyan
    var skyColors: [Color] = [
        Color(red: 0.07, green: 0.03, blue: 0.2),
        Color(red: 0.42, green: 0.08, blue: 0.5),
        Color(red: 0.95, green: 0.25, blue: 0.5),
    ]
    var lineCount = 14
    var speed = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, phase: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, phase: Double) {
        guard size.width > 0, size.height > 0 else { return }
        let horizon = size.height * 0.58
        let center = size.width / 2

        context.fill(
            Path(CGRect(origin: .zero, size: CGSize(width: size.width, height: horizon))),
            with: .linearGradient(Gradient(colors: skyColors), startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon))
        )
        drawSun(in: context, center: CGPoint(x: center, y: horizon - size.width * 0.14), radius: size.width * 0.3, horizon: horizon)

        let ground = CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)
        context.fill(Path(ground), with: .color(Color(red: 0.05, green: 0.02, blue: 0.14)))

        var grid = Path()
        let spacing = size.width / 4
        for column in -12...12 {
            grid.move(to: CGPoint(x: center + Double(column) * spacing * 0.14, y: horizon))
            grid.addLine(to: CGPoint(x: center + Double(column) * spacing, y: size.height))
        }
        for line in SynthwaveGridBackgroundMath.horizontalLines(phase: phase, count: lineCount) {
            let y = horizon + ground.height * line
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
        }

        context.stroke(grid, with: .color(lineColor.opacity(0.25)), lineWidth: 5)
        context.stroke(grid, with: .color(lineColor), lineWidth: 1.5)
    }

    private func drawSun(in context: GraphicsContext, center: CGPoint, radius: Double, horizon: Double) {
        var bands = Path()
        var y = center.y - radius
        var gap = 0.0
        // The stripes open up toward the bottom of the sun.
        while y < horizon, radius > 0 {
            let height = max(radius * 0.22 - gap * 0.7, radius * 0.05)
            bands.addRect(CGRect(x: center.x - radius, y: y, width: radius * 2, height: height))
            gap = radius * 0.03 + max(0, y - center.y) * 0.1
            y += height + gap
        }

        var clipped = context
        clipped.clip(to: bands)
        clipped.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .linearGradient(
                Gradient(colors: [.yellow, .orange, .pink]),
                startPoint: CGPoint(x: center.x, y: center.y - radius),
                endPoint: CGPoint(x: center.x, y: center.y + radius)
            )
        )
    }
}

// MARK: - Demo

struct SynthwaveGridBackgroundDemo: View {
    var body: some View {
        ZStack {
            SynthwaveGridBackground()

            Text("NIGHT DRIVE")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .pink, radius: 12)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 72)
        }
    }
}

#Preview {
    SynthwaveGridBackgroundDemo()
}
