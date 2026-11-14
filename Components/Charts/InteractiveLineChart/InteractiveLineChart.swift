// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Charts
import SwiftUI

struct InteractiveLineChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double

    var id: Date { date }
}

/// A line chart that shows a rule and a value tooltip under the finger as it scrubs.
///
/// The tooltip only exists during the touch, and nothing animates on its own.
struct InteractiveLineChart: View {
    let points: [InteractiveLineChartPoint]
    var tint: Color = .indigo
    var format: (Double) -> String = { $0.formatted() }

    @State private var touchedDate: Date?
    @State private var tooltipWidth: CGFloat = 0
    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric(relativeTo: .caption) private var tooltipHeadroom = 60.0

    private var selected: InteractiveLineChartPoint? {
        touchedDate.flatMap { InteractiveLineChartLogic.nearest(to: $0, in: points) }
    }

    var body: some View {
        let domain = InteractiveLineChartLogic.domain(for: points)

        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Baseline", domain.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(.linearGradient(colors: [tint.opacity(0.3), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
                .accessibilityHidden(true)

                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                    .accessibilityValue(format(point.value))
            }

            if let selected {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .accessibilityHidden(true)

                PointMark(x: .value("Selected", selected.date), y: .value("Value", selected.value))
                    .symbolSize(140)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
        }
        .chartYScale(domain: domain, range: .plotDimension(endPadding: tooltipHeadroom))
        // Keeps the last date inside the plot. Before iOS 26 it is drawn half cut at the trailing edge.
        .chartXAxis { AxisMarks(preset: .aligned) }
        .chartXSelection(value: $touchedDate)
        // Drawn over the chart and not as an annotation of the rule: on iOS 27 that
        // annotation is not drawn at all.
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selected, let plotFrame = proxy.plotFrame, let x = proxy.position(forX: selected.date) {
                    let plot = geometry[plotFrame]
                    tooltip(for: selected)
                        .environment(\.layoutDirection, layoutDirection)
                        .fixedSize()
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { tooltipWidth = $0 }
                        .position(
                            x: InteractiveLineChartLogic.tooltipX(at: plot.minX + x, width: tooltipWidth, in: plot.minX...plot.maxX),
                            y: plot.minY + tooltipHeadroom / 2
                        )
                        .allowsHitTesting(false)
                }
            }
            // The chart reports screen points, and a position is mirrored in a right-to-left
            // layout. Left to right here keeps the tooltip over the rule.
            .environment(\.layoutDirection, .leftToRight)
        }
        .sensoryFeedback(.selection, trigger: selected?.id)
    }

    private func tooltip(for point: InteractiveLineChartPoint) -> some View {
        VStack(spacing: 2) {
            Text(format(point.value))
                .font(.headline)
            Text(point.date, format: .dateTime.day().month())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        // A material does not draw inside a chart annotation: it comes out black, or not at all.
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.separator) }
    }
}

enum InteractiveLineChartLogic {
    static func nearest(to date: Date, in points: [InteractiveLineChartPoint]) -> InteractiveLineChartPoint? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    /// The center of the tooltip: over the point, but never past either end of the plot.
    static func tooltipX(at x: CGFloat, width: CGFloat, in plot: ClosedRange<CGFloat>) -> CGFloat {
        let half = max(width, 0) / 2
        guard plot.upperBound - plot.lowerBound > half * 2 else { return (plot.lowerBound + plot.upperBound) / 2 }
        return min(max(x, plot.lowerBound + half), plot.upperBound - half)
    }

    /// The vertical range with some breathing room. A flat or empty series still gets a valid range.
    static func domain(for points: [InteractiveLineChartPoint]) -> ClosedRange<Double> {
        let values = points.map(\.value).filter(\.isFinite)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        guard high - low > 0, (high - low).isFinite else { return (low - 1)...(high + 1) }
        let padding = (high - low) * 0.15
        return (low - padding)...(high + padding)
    }
}

// MARK: - Demo

struct InteractiveLineChartDemo: View {
    @State private var points: [InteractiveLineChartPoint] = {
        let start = Calendar.current.startOfDay(for: .now)
        return (0..<36).compactMap { day in
            guard let date = Calendar.current.date(byAdding: .day, value: day - 35, to: start) else { return nil }
            let value = 1_200 + Double(day) * 14 + sin(Double(day) * 0.55) * 120 + cos(Double(day) * 1.7) * 40
            return InteractiveLineChartPoint(date: date, value: value.rounded())
        }
    }()

    private func euros(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Savings")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(euros(points.last?.value ?? 0))
                .font(.largeTitle.bold())
            Text("Drag along the chart")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            InteractiveLineChart(points: points, format: euros)
                .padding(.vertical, 12)
        }
        .padding(24)
    }
}

#Preview {
    InteractiveLineChartDemo()
}
