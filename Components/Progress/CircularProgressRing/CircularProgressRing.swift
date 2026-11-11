// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// The clamping and the text of the ring, apart from the view so they can be tested.
enum CircularProgressRingMath {
    static func clamped(_ value: Double) -> Double {
        value.isNaN ? 0 : min(max(value, 0), 1)
    }

    /// Only a finished ring reads 100: 99.6% rounds down to 99.
    static func wholePercent(_ value: Double) -> Int {
        let fraction = clamped(value)
        let percent = Int((fraction * 100).rounded())
        return percent == 100 && fraction < 1 ? 99 : percent
    }

    static func percentText(_ value: Double, locale: Locale = .autoupdatingCurrent) -> String {
        wholePercent(value).formatted(.percent.locale(locale))
    }
}

/// An animated ring with a gradient and the percentage in the middle. Give it a frame to size it.
///
/// With Reduce Motion on, the ring and the number change without animating.
struct CircularProgressRing: View {
    var progress: Double
    var colors: [Color] = [.cyan, .blue, .purple]
    var lineWidth: CGFloat = 18
    var font: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    var label: LocalizedStringKey = "Progress"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var value: Double { CircularProgressRingMath.clamped(progress) }
    private var percentText: String { CircularProgressRingMath.percentText(progress) }
    private var strokeStyle: StrokeStyle { StrokeStyle(lineWidth: lineWidth, lineCap: .round) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            ZStack {
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(AngularGradient(colors: colors, center: .center), style: strokeStyle)

                // The round cap at the start falls on the gradient's seam, so paint it with the first color.
                Circle()
                    .trim(from: 0, to: value > 0 ? 0.001 : 0)
                    .stroke(colors.first ?? .blue, style: strokeStyle)
            }
            // A round cap draws a dot even on a line with no length.
            .opacity(value > 0 ? 1 : 0)
            .rotationEffect(.degrees(-90))

            Text(percentText)
                .font(font)
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(lineWidth + 4)
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
        .animation(reduceMotion ? nil : .smooth(duration: 0.7), value: value)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(percentText)
    }
}

// MARK: - Demo

struct CircularProgressRingDemo: View {
    @State private var progress = 0.0
    @ScaledMetric(relativeTo: .largeTitle) private var percentSize = 60

    var body: some View {
        VStack(spacing: 40) {
            Text("Uploading photos")
                .font(.system(.title, design: .rounded, weight: .bold))

            CircularProgressRing(
                progress: progress,
                lineWidth: 26,
                font: .system(size: percentSize, weight: .bold, design: .rounded),
                label: "Upload"
            )
            .frame(width: 280)

            HStack(spacing: 28) {
                CircularProgressRing(progress: 0.32, colors: [.pink, .orange], lineWidth: 8, font: .headline, label: "Move")
                CircularProgressRing(progress: 0.68, colors: [.green, .mint], lineWidth: 8, font: .headline, label: "Exercise")
                CircularProgressRing(progress: 0.91, colors: [.teal, .blue], lineWidth: 8, font: .headline, label: "Stand")
            }
            .frame(height: 88)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            let values = [0.25, 0.6, 0.85, 1, 0]
            var index = 0
            while !Task.isCancelled {
                progress = values[index]
                index = (index + 1) % values.count
                try? await Task.sleep(for: .seconds(0.9))
            }
        }
    }
}

#Preview {
    CircularProgressRingDemo()
}
