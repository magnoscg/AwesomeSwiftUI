// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Charts
import SwiftUI

/// A stat tile with a small trend line behind its value.
///
/// VoiceOver reads the title, the value and the change as one element. With Reduce Motion
/// on, new values appear without animating the line.
struct SparklineStatTile: View {
    let title: LocalizedStringResource
    let value: String
    let trend: [Double]
    var systemImage: String = "chart.line.uptrend.xyaxis"
    var tint: Color = .indigo
    /// Set it to false for a figure that is good news when it falls, like churn. A fall is then green.
    var higherIsBetter = true

    @ScaledMetric(relativeTo: .largeTitle) private var minimumHeight = 150.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var change: Double? { SparklineStatTileLogic.change(in: trend) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title.bold())
                .minimumScaleFactor(0.7)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .smooth, value: value)

            if let change {
                changeLabel(change)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
        .background(alignment: .bottom) { sparkline }
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }

    private func changeLabel(_ change: Double) -> some View {
        Label(percent(change), systemImage: change >= 0 ? "arrow.up.right" : "arrow.down.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle((change >= 0) == higherIsBetter ? .green : .red)
    }

    @ViewBuilder
    private var sparkline: some View {
        let values = trend.filter(\.isFinite)
        if values.count > 1 {
            let domain = SparklineStatTileLogic.domain(for: values)

            Chart(Array(values.enumerated()), id: \.offset) { index, value in
                AreaMark(x: .value("Index", index), yStart: .value("Low", domain.lowerBound), yEnd: .value("Value", value))
                    .foregroundStyle(.linearGradient(colors: [tint.opacity(0.3), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Index", index), y: .value("Value", value))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXScale(domain: 0...(values.count - 1))
            .chartYScale(domain: domain)
            .frame(height: minimumHeight * 0.55)
            .animation(reduceMotion ? nil : .smooth, value: values)
            .accessibilityHidden(true)
        }
    }

    private var accessibilityValue: String {
        guard let change else { return value }
        return "\(value), \(change >= 0 ? "up" : "down") \(abs(change).formatted(.percent.precision(.fractionLength(1))))"
    }

    private func percent(_ change: Double) -> String {
        change.formatted(.percent.precision(.fractionLength(1)).sign(strategy: .always()))
    }
}

enum SparklineStatTileLogic {
    /// The change from the first value to the last, or `nil` when it cannot be computed.
    static func change(in values: [Double]) -> Double? {
        let values = values.filter(\.isFinite)
        guard values.count > 1, let first = values.first, let last = values.last, first != 0 else { return nil }
        let change = (last - first) / abs(first)
        return change.isFinite ? change : nil
    }

    /// A valid vertical range, also for a flat series, with room so the line is not cut off.
    static func domain(for values: [Double]) -> ClosedRange<Double> {
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        guard high - low > 0, (high - low).isFinite else { return (low - 1)...(high + 1) }
        return (low - (high - low) * 0.1)...(high + (high - low) * 0.5)
    }
}

// MARK: - Demo

struct SparklineStatTileDemo: View {
    @State private var tick = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private func series(base: Double, swing: Double, slope: Double, phase: Double) -> [Double] {
        (0..<14).map { index in
            let position = Double(index + tick)
            return (base + position * slope + sin(position * 0.8 + phase) * swing).rounded()
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    private func tile(_ title: LocalizedStringResource, _ systemImage: String, _ tint: Color, _ trend: [Double], suffix: String = "", higherIsBetter: Bool = true) -> some View {
        SparklineStatTile(
            title: title,
            value: (trend.last ?? 0).formatted() + suffix,
            trend: trend,
            systemImage: systemImage,
            tint: tint,
            higherIsBetter: higherIsBetter
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Overview")
                    .font(.largeTitle.bold())

                LazyVGrid(columns: columns, spacing: 14) {
                    tile("Revenue", "eurosign.circle", .indigo, series(base: 4_200, swing: 320, slope: 60, phase: 0))
                    tile("Signups", "person.badge.plus", .teal, series(base: 310, swing: 40, slope: 8, phase: 1.4))
                    tile("Churn", "arrow.uturn.left.circle", .pink, series(base: 60, swing: 7, slope: -1.5, phase: 2.2), suffix: " users", higherIsBetter: false)
                    tile("Sessions", "waveform.path.ecg", .orange, series(base: 1_900, swing: 240, slope: 18, phase: 3.1))
                    tile("Orders", "shippingbox", .green, series(base: 840, swing: 90, slope: 12, phase: 4.3))
                    tile("Tickets", "lifepreserver", .purple, series(base: 120, swing: 22, slope: -2, phase: 5), higherIsBetter: false)
                }
            }
            .padding(20)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.18), .teal.opacity(0.12)], startPoint: .top, endPoint: .bottom))
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                tick = (tick + 1) % 1_000
            }
        }
    }
}

#Preview {
    SparklineStatTileDemo()
}
