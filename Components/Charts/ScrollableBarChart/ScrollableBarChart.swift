// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Charts
import SwiftUI

nonisolated struct ScrollableBarChartEntry: Identifiable, Hashable, Sendable {
    var date: Date
    var value: Double

    var id: Date { date }
}

nonisolated enum ScrollableBarChartMath {
    static let secondsPerDay = 86_400.0

    /// The entries of the days in sight: those from `start` up to `days` later.
    static func visible(_ entries: [ScrollableBarChartEntry], from start: Date, days: Int) -> [ScrollableBarChartEntry] {
        let end = start.addingTimeInterval(Double(max(days, 0)) * secondsPerDay)
        return entries.filter { $0.date >= start && $0.date < end }
    }

    /// The mean of the values, or `nil` when there are none.
    static func average(of entries: [ScrollableBarChartEntry]) -> Double? {
        entries.isEmpty ? nil : entries.map(\.value).reduce(0, +) / Double(entries.count)
    }

    /// Where the chart starts so that its last `days` are the ones in sight.
    static func lastStart(of entries: [ScrollableBarChartEntry], days: Int) -> Date? {
        guard let last = entries.map(\.date).max() else { return nil }
        return last.addingTimeInterval(-Double(max(days, 1) - 1) * secondsPerDay)
    }

    /// The top of the value axis: the highest value of all, with some room, so the bars keep
    /// their scale while the chart scrolls.
    static func ceiling(of entries: [ScrollableBarChartEntry]) -> Double {
        max((entries.map(\.value).max() ?? 0) * 1.12, 1)
    }
}

/// A bar chart with more days than fit, which scrolls sideways and settles on whole days, a
/// week at a time. A line marks the average of the days in sight and `visible` reports them.
///
/// It starts on the latest days. Swift Charts gives VoiceOver every bar and an audio graph.
struct ScrollableBarChart: View {
    let entries: [ScrollableBarChartEntry]
    /// The entries of the days in sight, kept up to date as the chart scrolls.
    @Binding var visible: [ScrollableBarChartEntry]
    var visibleDays = 7

    @State private var position = Date.now

    var body: some View {
        let average = ScrollableBarChartMath.average(of: visible)

        Chart {
            ForEach(entries) { entry in
                BarMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Value", entry.value)
                )
                .foregroundStyle(.tint)
                .clipShape(.rect(cornerRadius: 5))
            }

            if let average {
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Average of the days in sight")
            }
        }
        .chartYScale(domain: 0...ScrollableBarChartMath.ceiling(of: entries))
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: Double(visibleDays) * ScrollableBarChartMath.secondsPerDay)
        .chartScrollPosition(x: $position)
        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0), majorAlignment: .matching(DateComponents(weekday: Calendar.current.firstWeekday))))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .onAppear {
            if let start = ScrollableBarChartMath.lastStart(of: entries, days: visibleDays) { position = start }
        }
        .onChange(of: position, initial: true) { _, start in
            let shown = ScrollableBarChartMath.visible(entries, from: start, days: visibleDays)
            if shown != visible { visible = shown }
        }
    }
}

// MARK: - Demo

struct ScrollableBarChartDemo: View {
    @State private var visible: [ScrollableBarChartEntry] = []

    /// Eight weeks of made-up step counts, the same on every run.
    private let entries: [ScrollableBarChartEntry] = {
        var seed: UInt64 = 7
        let start = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: 815_000_000))
        return (0..<56).map { day in
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = Double(seed >> 33) / Double(1 << 31)
            let weekend = day % 7 >= 5 ? 0.7 : 1
            return ScrollableBarChartEntry(date: start.addingTimeInterval(Double(day) * 86_400), value: (4_500 + noise * 7_500) * weekend)
        }
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Steps")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(ScrollableBarChartMath.average(of: visible) ?? 0, format: .number.precision(.fractionLength(0)))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("a day")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(range)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .animation(.snappy, value: visible)
            .accessibilityElement(children: .combine)

            ScrollableBarChart(entries: entries, visible: $visible)
                .frame(height: 260)
        }
        .padding(20)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .tint(.orange)
    }

    private var range: String {
        guard let first = visible.first?.date, let last = visible.last?.date else { return " " }
        return (first..<last).formatted(.interval.month(.abbreviated).day())
    }
}

#Preview {
    ScrollableBarChartDemo()
}
