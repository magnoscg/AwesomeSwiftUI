// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A grid of dots with a pulse of light spreading from the center.
///
/// With Reduce Motion on, it shows one still ring.
struct GridPulseBackground: View {
    var color: Color = .cyan
    var spacing: Double = 26
    /// Seconds for the pulse to travel from the center to the corners.
    var period: Double = 2.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let dotRadius = 2.0
    private static let restingOpacity = 0.32
    private static let bandWidth = 80.0

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let cycle = timeline.date.timeIntervalSinceReferenceDate / period
                let progress = reduceMotion ? 0.4 : cycle - floor(cycle)
                draw(progress: progress, in: context, size: size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(progress: Double, in context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let front = progress * (hypot(size.width, size.height) / 2 + Self.bandWidth)
        let columns = Int(size.width / 2 / spacing) + 1
        let rows = Int(size.height / 2 / spacing) + 1
        var resting = Path()

        for row in -rows...rows {
            for column in -columns...columns {
                let dot = CGPoint(x: center.x + Double(column) * spacing, y: center.y + Double(row) * spacing)
                let gap = (hypot(dot.x - center.x, dot.y - center.y) - front) / Self.bandWidth
                let glow = exp(-gap * gap) * (1 - pow(progress, 4))

                if glow < 0.02 {
                    resting.addEllipse(in: circle(at: dot, radius: Self.dotRadius))
                } else {
                    context.fill(
                        Path(ellipseIn: circle(at: dot, radius: Self.dotRadius * (1 + glow * 1.6))),
                        with: .color(color.opacity(Self.restingOpacity + glow * (1 - Self.restingOpacity)))
                    )
                }
            }
        }

        context.fill(resting, with: .color(color.opacity(Self.restingOpacity)))
    }

    private func circle(at center: CGPoint, radius: Double) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

// MARK: - Demo

struct GridPulseBackgroundDemo: View {
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.1)
                .ignoresSafeArea()

            GridPulseBackground()

            VStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Signal")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        }
    }
}

#Preview {
    GridPulseBackgroundDemo()
}
