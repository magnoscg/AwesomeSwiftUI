// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Large, soft colored orbs drifting slowly over a dark base.
///
/// With Reduce Motion on, the orbs hold still.
struct ColorOrbsBackground: View {
    /// One orb per color.
    var colors: [Color] = [.pink, .purple, .blue, .teal, .orange]
    var base: Color = Color(red: 0.05, green: 0.04, blue: 0.13)
    var speed: Double = 0.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas(opaque: true) { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base))
                context.blendMode = .screen

                for (index, color) in colors.enumerated() {
                    drawOrb(index: index, color: color, at: time, in: context, size: size)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// A radial falloff to clear looks like a heavy blur and costs far less to redraw each frame.
    private func drawOrb(index: Int, color: Color, at time: Double, in context: GraphicsContext, size: CGSize) {
        let center = CGPoint(
            x: (0.5 + 0.42 * sin(time * (0.5 + noise(index, 1) * 0.5) + noise(index, 2) * 2 * .pi)) * size.width,
            y: (0.5 + 0.42 * cos(time * (0.4 + noise(index, 3) * 0.5) + noise(index, 4) * 2 * .pi)) * size.height
        )
        let radius = max(size.width, size.height) * (0.34 + noise(index, 5) * 0.14)
        let falloff = Gradient(stops: [
            .init(color: color.opacity(0.9), location: 0),
            .init(color: color.opacity(0.45), location: 0.5),
            .init(color: color.opacity(0), location: 1),
        ])

        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(falloff, center: center, startRadius: 0, endRadius: radius)
        )
    }

    /// A repeatable pseudo-random value in 0..<1 for one orb and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct ColorOrbsBackgroundDemo: View {
    var body: some View {
        ZStack {
            ColorOrbsBackground()

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.title)
                    .accessibilityHidden(true)
                Text("Evening Focus")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Soft color moves behind your content without getting in its way.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
            .environment(\.colorScheme, .dark)
            .padding(24)
        }
    }
}

#Preview {
    ColorOrbsBackgroundDemo()
}
