// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Layered waves, each one an animatable `Shape` driven by a single phase.
///
/// With Reduce Motion on, the waves hold still.
struct WavesBackground: View {
    /// One wave per color, from back to front.
    var colors: [Color] = [.teal, .cyan, .blue, .indigo]
    var amplitude: Double = 26
    /// Seconds for the slowest wave to complete one cycle.
    var period: Double = 7

    @State private var phase = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated private struct WaveLayer: Shape {
        var phase: Double
        var baseline: Double
        var amplitude: Double
        var waves: Double

        var animatableData: Double {
            get { phase }
            set { phase = newValue }
        }

        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))

            for x in stride(from: rect.minX, through: rect.maxX + 4, by: 4) {
                let angle = x / max(rect.width, 1) * waves * 2 * .pi
                let swell = sin(angle + phase) + 0.35 * sin(angle * 2 + phase * 2)
                path.addLine(to: CGPoint(x: x, y: rect.minY + rect.height * baseline + swell * amplitude))
            }

            path.addLine(to: CGPoint(x: rect.maxX + 4, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    var body: some View {
        ZStack {
            ForEach(colors.indices, id: \.self) { index in
                // A whole number of cycles per loop, so the repeat has no visible seam.
                let cycles = Double(index % 3 + 1) * (index.isMultiple(of: 2) ? 1 : -1)

                WaveLayer(
                    phase: phase * cycles + Double(index),
                    baseline: 0.45 + 0.12 * Double(index),
                    amplitude: amplitude * (1 - 0.1 * Double(index)),
                    waves: 1 + 0.5 * Double(index % 2 + 1)
                )
                .fill(colors[index].opacity(0.85))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: reduceMotion) { updateMotion() }
    }

    private func updateMotion() {
        if reduceMotion {
            withTransaction(\.disablesAnimations, true) { phase = 0 }
        } else {
            withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

// MARK: - Demo

struct WavesBackgroundDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink, .purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            WavesBackground()

            VStack(spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("High Tide")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 150)
        }
    }
}

#Preview {
    WavesBackgroundDemo()
}
