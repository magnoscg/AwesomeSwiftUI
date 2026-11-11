// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A circle filled by a moving liquid wave, with the percentage in the middle.
///
/// With Reduce Motion on, the surface stands still and the level changes without animating.
struct LiquidFillProgress: View {
    var progress: Double
    var color: Color = .blue
    var font: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    var label: LocalizedStringKey = "Progress"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var level: Double {
        progress.isNaN ? 0 : min(max(progress, 0), 1)
    }

    private var percentText: Text {
        Text(level, format: .percent.precision(.fractionLength(0)))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let phase = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * 2.4
            let frontWave = LiquidFillWave(level: level, phase: phase)

            ZStack {
                Circle()
                    .fill(color.opacity(0.14))

                LiquidFillWave(level: level, phase: -phase * 0.8 + 1.4)
                    .fill(color.opacity(0.45))

                frontWave
                    .fill(color.gradient)

                percentLabel
                    .foregroundStyle(color)

                percentLabel
                    .foregroundStyle(LiquidFillProgressContrastingForeground(background: color))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(frontWave)
            }
            .clipShape(.circle)
            .overlay {
                Circle()
                    .strokeBorder(color.opacity(0.6), lineWidth: 3)
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.9), value: level)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(percentText)
    }

    private var percentLabel: some View {
        percentText
            .font(font)
            .monospacedDigit()
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .padding(12)
            .accessibilityRepresentation { EmptyView() }
    }
}

/// The liquid: only `level` is animatable, so a level change eases while `phase` keeps following the clock.
nonisolated private struct LiquidFillWave: Shape {
    var level: Double
    var phase: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard !rect.isEmpty else { return Path() }

        let surface = rect.maxY - rect.height * level
        let swell = rect.height * 0.05 * min(1, min(level, 1 - level) * 6)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let angle = (x - rect.minX) / rect.width * 3 * .pi + phase
            path.addLine(to: CGPoint(x: x, y: surface + sin(angle) * swell))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct LiquidFillProgressContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct LiquidFillProgressDemo: View {
    @State private var progress = 0.15
    @ScaledMetric(relativeTo: .largeTitle) private var percentSize = 64

    var body: some View {
        VStack(spacing: 28) {
            Text("Daily water")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            LiquidFillProgress(
                progress: progress,
                color: .cyan,
                font: .system(size: percentSize, weight: .bold, design: .rounded),
                label: "Daily water"
            )
            .frame(width: 280)

            Text("Keep going, one more glass")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            let levels = [0.15, 0.45, 0.8, 1, 0.5]
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.9))
                index = (index + 1) % levels.count
                progress = levels[index]
            }
        }
    }
}

#Preview {
    LiquidFillProgressDemo()
}
