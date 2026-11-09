// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A rounded bar whose gradient fill glows more strongly as it advances.
///
/// With Reduce Motion on, the fill changes without animating.
struct GradientProgressBar: View {
    var progress: Double
    var colors: [Color] = [.cyan, .blue, .purple]
    var height: CGFloat = 12
    var label: LocalizedStringKey = "Progress"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var value: Double {
        progress.isNaN ? 0 : min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: value > 0 ? max(height, proxy.size.width * value) : 0)
                    .shadow(color: (colors.last ?? .blue).opacity(0.25 + 0.55 * value), radius: 3 + 12 * value)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: value)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}

// MARK: - Demo

struct GradientProgressBarDemo: View {
    @State private var progress = 0.08

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 44) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Downloading")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: progress))

                    GradientProgressBar(progress: progress, height: 22, label: "Download")
                }

                row("Maps", value: progress * 0.7, colors: [.mint, .green])
                row("Music", value: progress * 0.45, colors: [.orange, .pink])
            }
            .padding(28)
        }
        .environment(\.colorScheme, .dark)
        .task {
            let values = [0.08, 0.34, 0.62, 1, 0.08]
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.9))
                index = (index + 1) % values.count
                withAnimation(.smooth(duration: 0.3)) { progress = values[index] }
            }
        }
    }

    private func row(_ title: LocalizedStringKey, value: Double, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            GradientProgressBar(progress: value, colors: colors, label: title)
        }
    }
}

#Preview {
    GradientProgressBarDemo()
}
