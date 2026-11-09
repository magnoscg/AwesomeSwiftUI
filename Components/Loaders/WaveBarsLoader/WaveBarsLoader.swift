// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Bars that rise and fall like an equalizer.
///
/// With Reduce Motion on, the bars hold one uneven, still shape.
struct WaveBarsLoader: View {
    var colors: [Color] = [.blue, .cyan, .mint]
    var barCount: Int = 5
    var barWidth: CGFloat = 8
    var height: CGFloat = 44
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * speed

            HStack(alignment: .bottom, spacing: barWidth * 0.6) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top))
                        .frame(width: barWidth, height: barHeight(index: index, time: time))
                }
            }
            .frame(height: height, alignment: .bottom)
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    /// Two sine waves at different speeds keep the bars from looking like a plain wave.
    private func barHeight(index: Int, time: Double) -> CGFloat {
        let position = Double(index)
        let level = 0.55 + 0.3 * sin(time * 5 + position * 0.8) + 0.15 * sin(time * 9 + position * 1.7)
        return max(barWidth, height * level)
    }
}

// MARK: - Demo

struct WaveBarsLoaderDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                WaveBarsLoader(barCount: 9, barWidth: 20, height: 220)

                VStack(spacing: 6) {
                    Text("Tuning in")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Buffering your station")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    WaveBarsLoaderDemo()
}
