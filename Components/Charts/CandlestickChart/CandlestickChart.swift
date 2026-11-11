// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Charts
import SwiftUI

nonisolated struct CandlestickChartCandle: Identifiable, Hashable, Sendable {
    var date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double

    var id: Date { date }
    var isRising: Bool { close >= open }
}

nonisolated enum CandlestickChartMath {
    /// The prices the chart shows: from the lowest low to the highest high, with some room at
    /// both ends so no candle touches the edge.
    static func domain(of candles: [CandlestickChartCandle], padding: Double = 0.08) -> ClosedRange<Double> {
        guard let low = candles.map(\.low).min(), let high = candles.map(\.high).max(), high >= low else { return 0...1 }
        let room = max(high - low, abs(high) * 0.01, 0.01) * max(padding, 0)
        return (low - room)...(high + room)
    }

    /// The two ends of the body of a candle. A day that closed where it opened still gets a body
    /// `minimum` tall, so it shows as a line instead of vanishing.
    static func body(of candle: CandlestickChartCandle, minimum: Double) -> ClosedRange<Double> {
        let low = min(candle.open, candle.close)
        let high = max(candle.open, candle.close)
        let missing = max(minimum - (high - low), 0)
        return (low - missing / 2)...(high + missing / 2)
    }

    /// How much the price moved from open to close, as a share of the open.
    static func change(of candle: CandlestickChartCandle) -> Double {
        candle.open != 0 ? (candle.close - candle.open) / candle.open : 0
    }

    /// The candle of the day closest to a date, which is how a touch between two days picks one.
    static func nearest(to date: Date, in candles: [CandlestickChartCandle]) -> CandlestickChartCandle? {
        candles.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}

/// A candlestick chart: each day is a thin line from its low to its high and a body from its
/// open to its close, in one color when the price rose and another when it fell.
///
/// Drag over it to read a day: a rule follows the finger and `selection` gets its candle.
/// VoiceOver reads the four prices of each day. With Differentiate Without Color on, the days
/// that fell are drawn lighter, so the two kinds do not depend on the color alone.
struct CandlestickChart: View {
    let candles: [CandlestickChartCandle]
    @Binding var selection: CandlestickChartCandle?
    var risingColor = Color.green
    var fallingColor = Color.red

    @State private var selectedDate: Date?
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        let domain = CandlestickChartMath.domain(of: candles)
        let minimumBody = (domain.upperBound - domain.lowerBound) * 0.004

        Chart {
            ForEach(candles) { candle in
                let color = candle.isRising ? risingColor : fallingColor
                let prices = CandlestickChartMath.body(of: candle, minimum: minimumBody)

                RuleMark(
                    x: .value("Day", candle.date, unit: .day),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .foregroundStyle(color)
                .accessibilityHidden(true)

                RectangleMark(
                    x: .value("Day", candle.date, unit: .day),
                    yStart: .value("Open", prices.lowerBound),
                    yEnd: .value("Close", prices.upperBound),
                    width: .ratio(0.62)
                )
                .foregroundStyle(color.opacity(!candle.isRising && differentiateWithoutColor ? 0.45 : 1))
                .clipShape(.rect(cornerRadius: 1.5))
                .accessibilityLabel(candle.date.formatted(date: .abbreviated, time: .omitted))
                .accessibilityValue(description(of: candle))
            }

            if let selection {
                RuleMark(x: .value("Selected", selection.date, unit: .day))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .chartYScale(domain: domain)
        .chartXAxis {
            AxisMarks(preset: .aligned)
        }
        .chartXSelection(value: $selectedDate)
        .onChange(of: selectedDate) { _, date in
            selection = date.flatMap { CandlestickChartMath.nearest(to: $0, in: candles) }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func description(of candle: CandlestickChartCandle) -> String {
        let prices = [("Open", candle.open), ("high", candle.high), ("low", candle.low), ("close", candle.close)]
        return prices.map { "\($0.0) \($0.1.formatted(.number.precision(.fractionLength(2))))" }.joined(separator: ", ")
    }
}

// MARK: - Demo

struct CandlestickChartDemo: View {
    @State private var selection: CandlestickChartCandle?

    /// A month of made-up prices, the same on every run.
    private let candles: [CandlestickChartCandle] = {
        var seed: UInt64 = 42
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 33) / Double(1 << 31)
        }
        let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
        var price = 182.0
        return (0..<30).map { day in
            let open = price
            let close = open + (next() - 0.47) * 9
            let high = max(open, close) + next() * 4
            let low = min(open, close) - next() * 4
            price = close
            return CandlestickChartCandle(date: start.addingTimeInterval(Double(day) * 86_400), open: open, high: high, low: low, close: close)
        }
    }()

    private var shown: CandlestickChartCandle? { selection ?? candles.last }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let shown {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACME")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(shown.close, format: .currency(code: "USD"))
                            .font(.largeTitle.bold())
                        Text(CandlestickChartMath.change(of: shown), format: .percent.precision(.fractionLength(1)).sign(strategy: .always()))
                            .font(.headline)
                            .foregroundStyle(shown.isRising ? .green : .red)
                    }
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    Text(selection == nil ? "Last close · drag to read a day" : shown.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                CandlestickChart(candles: candles, selection: $selection)
                    .frame(height: 280)

                HStack {
                    price("Open", shown.open)
                    price("High", shown.high)
                    price("Low", shown.low)
                    price("Close", shown.close)
                }
            }
        }
        .padding(20)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func price(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CandlestickChartDemo()
}
