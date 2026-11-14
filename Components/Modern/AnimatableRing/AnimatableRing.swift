// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// An arc from `start` to `end` degrees. `@Animatable` writes its `animatableData`.
@available(iOS 26, *)
@Animatable
nonisolated struct AnimatableRingArc: Shape {
    var start: Double
    var end: Double
    @AnimatableIgnored var clockwise = false

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: min(rect.width, rect.height) / 2,
                startAngle: .degrees(start - 90),
                endAngle: .degrees(end - 90),
                clockwise: clockwise
            )
        }
    }
}

/// A progress ring whose arc animates through the shape's own `animatableData`.
///
/// With Reduce Motion on, the ring jumps to the new value.
@available(iOS 26, *)
struct AnimatableRing: View {
    let progress: Double
    var title: LocalizedStringKey = "Progress"
    var colors: [Color] = [.mint, .cyan, .blue, .mint]

    @ScaledMetric(relativeTo: .largeTitle) private var lineWidth = 26.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            AnimatableRingArc(start: 0, end: clamped * 360)
                .stroke(
                    AngularGradient(colors: colors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Text(clamped, format: .percent.precision(.fractionLength(0)))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText(value: clamped))
        }
        .padding(lineWidth / 2)
        .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct AnimatableRingDemo: View {
    @State private var progress = 0.72
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            AnimatableRing(progress: progress, title: "Daily goal")
                .frame(width: 260, height: 260)

            Text("Daily goal")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard !reduceMotion else { return }
            let values = [0.28, 0.91, 0.55, 0.72]
            while !Task.isCancelled {
                for value in values where !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    progress = value
                }
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    AnimatableRingDemo()
}
