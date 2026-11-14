// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum IntelligenceGlowBorderMath {
    /// The mesh is 3 by 3: four corners, four edge points and a center.
    static let side = 3

    /// The points on the border in the order the colors travel, as indices into the mesh.
    static let perimeter = [0, 1, 2, 5, 8, 7, 6, 3]

    /// How far around the border the colors have travelled, from 0 up to 1.
    static func phase(time: Double, period: Double) -> Double {
        guard period > 0, time.isFinite else { return 0 }
        return wrapped(time / period)
    }

    /// The two colors of a palette of `count` that meet at `position`, and how much of the second one shows.
    /// The palette is a loop, so the last color blends back into the first.
    static func blend(at position: Double, count: Int) -> (lower: Int, upper: Int, fraction: Double) {
        guard count > 1, position.isFinite else { return (0, 0, 0) }

        let scaled = wrapped(position) * Double(count)
        let lower = min(Int(scaled), count - 1)
        return (lower, (lower + 1) % count, scaled - Double(lower))
    }

    /// Corners stay put and edge points slide along their edge, so the mesh always covers the border.
    static func points(phase: Double) -> [SIMD2<Float>] {
        func slide(_ offset: Double) -> Double {
            0.5 + sin((phase + offset) * 2 * .pi) * 0.16
        }

        let positions: [(Double, Double)] = [
            (0, 0), (slide(0), 0), (1, 0),
            (0, slide(0.75)), (0.5, 0.5), (1, slide(0.25)),
            (0, 1), (slide(0.5), 1), (1, 1),
        ]
        return positions.map { SIMD2(Float($0.0), Float($0.1)) }
    }

    private static func wrapped(_ value: Double) -> Double {
        value - floor(value)
    }
}

/// A soft band of moving color around the edge of a view, like the glow of an assistant that is listening.
///
/// The colors travel around the border and the light spreads inward. With Reduce Motion on, the
/// glow is still.
struct IntelligenceGlowBorder: ViewModifier {
    var isActive = true
    var cornerRadius: CGFloat = 28
    var lineWidth: CGFloat = 3
    var colors: [Color] = [.purple, .pink, .orange, .yellow, .cyan, .blue]
    /// Seconds for the colors to travel once around the border.
    var period: Double = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                        let time = context.date.timeIntervalSinceReferenceDate
                        glow(phase: reduceMotion ? 0 : IntelligenceGlowBorderMath.phase(time: time, period: period))
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: isActive)
    }

    private func glow(phase: Double) -> some View {
        let width = max(lineWidth, 0)
        let shape = RoundedRectangle(cornerRadius: max(cornerRadius, 0), style: .continuous)

        return MeshGradient(
            width: IntelligenceGlowBorderMath.side,
            height: IntelligenceGlowBorderMath.side,
            points: IntelligenceGlowBorderMath.points(phase: phase),
            colors: meshColors(phase: phase)
        )
        .mask {
            // A crisp line at the edge, and two wider and softer ones that carry the light inward.
            ZStack {
                shape.strokeBorder(lineWidth: width)
                shape.strokeBorder(lineWidth: width * 3).blur(radius: width * 2)
                shape.strokeBorder(lineWidth: width * 7).blur(radius: width * 5).opacity(0.7)
            }
        }
        // The blur also spreads outward, where the view's square frame would cut it in a straight line.
        .clipShape(shape)
    }

    /// The palette laid around the border, moved on by `phase`.
    private func meshColors(phase: Double) -> [Color] {
        let palette = colors.isEmpty ? [Color.accentColor] : colors
        let perimeter = IntelligenceGlowBorderMath.perimeter
        var mesh = Array(repeating: palette[0], count: IntelligenceGlowBorderMath.side * IntelligenceGlowBorderMath.side)

        for (step, index) in perimeter.enumerated() {
            let position = Double(step) / Double(perimeter.count) - phase
            let blend = IntelligenceGlowBorderMath.blend(at: position, count: palette.count)
            mesh[index] = palette[blend.lower].mix(with: palette[blend.upper], by: blend.fraction)
        }
        return mesh
    }
}

extension View {
    /// Draws a moving glow around this view's edge while `isActive` is true. Match `cornerRadius` to the view's shape.
    func intelligenceGlowBorder(isActive: Bool = true, cornerRadius: CGFloat = 28, lineWidth: CGFloat = 3) -> some View {
        modifier(IntelligenceGlowBorder(isActive: isActive, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}

// MARK: - Demo

struct IntelligenceGlowBorderDemo: View {
    @State private var isListening = true

    var body: some View {
        VStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 14) {
                Label(isListening ? "Listening" : "Ask anything", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                Text("Plan a weekend in Lisbon with two museums and somewhere good for dinner.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 32, style: .continuous))
            .intelligenceGlowBorder(isActive: isListening, cornerRadius: 32)

            Button(isListening ? "Stop" : "Start listening", systemImage: isListening ? "stop.fill" : "mic.fill") {
                isListening.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.18))
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.09).ignoresSafeArea())
    }
}

#Preview {
    IntelligenceGlowBorderDemo()
}
