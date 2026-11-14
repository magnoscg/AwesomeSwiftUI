// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A band of light that sweeps across the letters, masked by the text itself.
///
/// With Reduce Motion on, the text is drawn plainly in the highlight color.
struct ShimmerText: View {
    let text: String
    var baseColor: Color = .secondary
    var highlightColor: Color = .primary
    /// Seconds for one sweep.
    var duration: Double = 2.2

    /// Half the width of the band of light, as a fraction of the text's width.
    private let bandWidth = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .foregroundStyle(reduceMotion ? highlightColor : baseColor)
            .overlay {
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                        band(at: context.date)
                    }
                    .mask { Text(text).foregroundStyle(.black) }
                    .accessibilityHidden(true)
                }
            }
    }

    /// Start and end points beyond 0...1 place the band off to the side, between sweeps.
    private func band(at date: Date) -> LinearGradient {
        let cycle = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
        let center = -bandWidth + (1 + 2 * bandWidth) * cycle

        return LinearGradient(
            colors: [.clear, highlightColor, .clear],
            startPoint: UnitPoint(x: center - bandWidth, y: 0.5),
            endPoint: UnitPoint(x: center + bandWidth, y: 0.5)
        )
    }
}

// MARK: - Demo

struct ShimmerTextDemo: View {
    private let dimmed = Color.white.opacity(0.35)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.16), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ShimmerText(text: "Shimmer", baseColor: dimmed, highlightColor: .white)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .scaleEffect(1.5)

                ShimmerText(text: "slide to unlock", baseColor: dimmed, highlightColor: .white, duration: 1.8)
                    .font(.title3.weight(.medium))

                Label {
                    ShimmerText(text: "Writing your summary...", baseColor: .purple.opacity(0.5), highlightColor: .white)
                } icon: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.white.opacity(0.08), in: .capsule)
            }
            .padding(24)
        }
    }
}

#Preview {
    ShimmerTextDemo()
}
