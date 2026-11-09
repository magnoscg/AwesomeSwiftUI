// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct AnimatedBarChartEntry: Hashable {
    let label: String
    let value: Double
}

/// Bars that grow from the baseline one after another, and again whenever the data changes.
///
/// With Reduce Motion on, the bars are drawn at their final height.
struct AnimatedBarChart: View {
    let entries: [AnimatedBarChartEntry]
    var tint: Color = .indigo
    var stagger: Double = 0.09

    @State private var isRevealed = false
    @ScaledMetric(relativeTo: .caption2) private var valueHeight = 22.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                HStack(spacing: 10) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                        column(entry, index: index, plotHeight: max(0, proxy.size.height - valueHeight))
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    Text(entry.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
        }
        .task(id: entries) {
            guard !reduceMotion else {
                isRevealed = true
                return
            }
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { isRevealed = false }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            isRevealed = true
        }
    }

    private func column(_ entry: AnimatedBarChartEntry, index: Int, plotHeight: CGFloat) -> some View {
        let isShown = isRevealed || reduceMotion
        let ratio = AnimatedBarChartLogic.ratio(of: entry.value, in: entries.map(\.value))
        let valueText = entry.value.formatted()

        return VStack(spacing: 4) {
            Text(valueText)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(isShown ? 1 : 0)

            UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                .fill(tint.gradient)
                .frame(height: isShown ? plotHeight * ratio : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(
            reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.3).delay(Double(index) * max(0, stagger)),
            value: isRevealed
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.label)
        .accessibilityValue(valueText)
    }
}

enum AnimatedBarChartLogic {
    /// How tall a bar is compared with the tallest, from 0 to 1.
    static func ratio(of value: Double, in values: [Double]) -> Double {
        guard value.isFinite, value > 0,
              let highest = values.filter(\.isFinite).max(), highest > 0 else { return 0 }
        return min(value / highest, 1)
    }
}

// MARK: - Demo

struct AnimatedBarChartDemo: View {
    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let weeks: [(title: String, values: [Double])] = [
        ("This week", [12, 19, 8, 24, 16, 30, 22]),
        ("Last week", [20, 11, 27, 14, 29, 9, 17]),
    ]

    private var week: (title: String, values: [Double]) {
        weeks[index % weeks.count]
    }

    private var entries: [AnimatedBarChartEntry] {
        zip(["M", "T", "W", "T", "F", "S", "S"], week.values).map { AnimatedBarChartEntry(label: $0, value: $1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workouts")
                .font(.largeTitle.bold())
            Text(week.title)
                .font(.title3)
                .foregroundStyle(.secondary)

            AnimatedBarChart(entries: entries)
                .padding(.top, 24)
        }
        .padding(24)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.6))
                guard !Task.isCancelled else { return }
                index = (index + 1) % weeks.count
            }
        }
    }
}

#Preview {
    AnimatedBarChartDemo()
}
