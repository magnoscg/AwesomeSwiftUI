// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Translucent bubbles that rise and sway. Larger bubbles rise faster.
///
/// With Reduce Motion on, the bubbles hold still.
struct BubblesBackground: View {
    var color: Color = .white
    var count: Int = 36
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let margin = 40.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed
                let tint = Gradient(colors: [color.opacity(0.02), color.opacity(0.26)])

                for index in 0..<count {
                    let scale = noise(index, 1)
                    let radius = 6 + scale * scale * 28
                    let center = position(of: index, scale: scale, at: time, in: size)
                    let bubble = Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))

                    context.fill(
                        bubble,
                        with: .radialGradient(tint, center: center, startRadius: radius * 0.3, endRadius: radius)
                    )
                    context.stroke(bubble, with: .color(color.opacity(0.5)), lineWidth: 1)

                    let shine = radius * 0.22
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - radius * 0.55,
                            y: center.y - radius * 0.6,
                            width: shine,
                            height: shine
                        )),
                        with: .color(color.opacity(0.75))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func position(of index: Int, scale: Double, at time: Double, in size: CGSize) -> CGPoint {
        let travel = size.height + Self.margin * 2
        let rise = 35 + scale * 70
        let climbed = (noise(index, 2) * travel + time * rise).truncatingRemainder(dividingBy: travel)
        let sway = sin(time * (0.7 + noise(index, 3)) + noise(index, 4) * 2 * .pi) * (10 + noise(index, 5) * 18)

        return CGPoint(x: noise(index, 6) * size.width + sway, y: size.height + Self.margin - climbed)
    }

    /// A repeatable pseudo-random value in 0..<1 for one bubble and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct BubblesBackgroundDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.cyan, .blue, Color(red: 0.03, green: 0.12, blue: 0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            BubblesBackground()

            Text("Deep Blue")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    BubblesBackgroundDemo()
}
