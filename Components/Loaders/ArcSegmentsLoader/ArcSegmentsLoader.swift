// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Two rings of arcs with different lengths, turning in opposite directions.
///
/// With Reduce Motion on, the arcs stay still.
struct ArcSegmentsLoader: View {
    var colors: [Color] = [.pink, .orange, .purple, .pink]
    /// The length of each arc, as a fraction of the ring.
    var lengths: [Double] = [0.32, 0.16, 0.07]
    var size: CGFloat = 64
    var period: TimeInterval = 1.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lineWidth: CGFloat { size * 0.075 }

    private var arcs: [ClosedRange<Double>] {
        let gap = max(0, 1 - lengths.reduce(0, +)) / Double(max(lengths.count, 1))
        var start = 0.0
        return lengths.map { length in
            defer { start += length + gap }
            return start...(start + length)
        }
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let turns = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate / period

            ZStack {
                ring(inset: 0)
                    .rotationEffect(.degrees(turns * 360))

                ring(inset: size * 0.2)
                    .rotationEffect(.degrees(-turns * 360 * 1.4 + 90))
                    .opacity(0.7)
            }
            .frame(width: size, height: size)
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func ring(inset: CGFloat) -> some View {
        ZStack {
            ForEach(arcs, id: \.lowerBound) { arc in
                Circle()
                    .trim(from: arc.lowerBound, to: arc.upperBound)
                    .stroke(
                        AngularGradient(colors: colors, center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
            }
        }
        .padding(lineWidth / 2 + inset)
    }
}

// MARK: - Demo

struct ArcSegmentsLoaderDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .purple.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                ArcSegmentsLoader(size: 260)

                VStack(spacing: 6) {
                    Text("Preparing your trip")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Comparing the best routes")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}

#Preview {
    ArcSegmentsLoaderDemo()
}
