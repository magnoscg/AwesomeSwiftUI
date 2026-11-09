// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Dots that orbit a glowing center, bunching up and spreading out as they go.
///
/// With Reduce Motion on, the dots stay still, evenly spaced around the center.
struct OrbitLoader: View {
    var color: Color = .indigo
    var dotCount: Int = 3
    var size: CGFloat = 64
    var period: TimeInterval = 1.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let turns = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate / period

            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: size * 0.02)
                    .padding(size * 0.1)

                Circle()
                    .fill(color.gradient)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .shadow(color: color.opacity(0.6), radius: size * 0.1)

                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(color.gradient)
                        .frame(width: size * 0.16, height: size * 0.16)
                        .offset(dotOffset(index: index, turns: turns))
                }
            }
            .frame(width: size, height: size)
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func dotOffset(index: Int, turns: Double) -> CGSize {
        let position = turns + Double(index) / Double(max(dotCount, 1))
        let angle = (position + 0.1 * sin(position * 2 * .pi)) * 2 * .pi
        let radius = size * 0.4
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}

// MARK: - Demo

struct OrbitLoaderDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                OrbitLoader(color: .cyan, size: 240)

                VStack(spacing: 6) {
                    Text("Connecting")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Looking for nearby devices")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.75))
                }

                HStack(spacing: 32) {
                    OrbitLoader(color: .pink, dotCount: 2, size: 56)
                    OrbitLoader(color: .mint, dotCount: 4, size: 56, period: 2.4)
                    OrbitLoader(color: .orange, dotCount: 5, size: 56, period: 1.2)
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    OrbitLoaderDemo()
}
