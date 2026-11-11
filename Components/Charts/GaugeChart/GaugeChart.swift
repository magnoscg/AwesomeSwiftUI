// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated struct GaugeChartZone: Identifiable, Sendable {
    var name: String
    /// Where the zone ends. It starts where the one before it ends, or at the start of the range.
    var upTo: Double
    var color: Color

    var id: String { name }
}

nonisolated enum GaugeChartMath {
    /// How far along the dial a value is, from 0 at its start to 1 at its end.
    static func share(of value: Double, in range: ClosedRange<Double>) -> Double {
        let length = range.upperBound - range.lowerBound
        guard length > 0, value.isFinite else { return 0 }
        return min(max((value - range.lowerBound) / length, 0), 1)
    }

    /// The turn of the needle in degrees: -90 at the start of the dial, 0 straight up, 90 at its end.
    static func needleAngle(share: Double) -> Double {
        -90 + 180 * min(max(share, 0), 1)
    }

    /// The zone a value falls in: the first one that ends at or after it, or the last one for a
    /// value beyond them all.
    static func zone(for value: Double, in zones: [GaugeChartZone]) -> GaugeChartZone? {
        let sorted = zones.sorted { $0.upTo < $1.upTo }
        return sorted.first { value <= $0.upTo } ?? sorted.last
    }

    /// Where each zone starts and ends along the dial, as shares from 0 to 1.
    static func spans(of zones: [GaugeChartZone], in range: ClosedRange<Double>) -> [(zone: GaugeChartZone, start: Double, end: Double)] {
        var start = 0.0
        return zones.sorted { $0.upTo < $1.upTo }.compactMap { zone in
            let end = share(of: zone.upTo, in: range)
            defer { start = max(start, end) }
            return end > start ? (zone, start, end) : nil
        }
    }
}

/// A half-moon gauge for a panel: a dial split into colored zones and a needle that swings to
/// the value. For a small control inside a row, SwiftUI's own `Gauge` is the one to use.
///
/// VoiceOver reads the value and the name of its zone, so the reading does not depend on the
/// color. With Reduce Motion on, the needle goes to its place without swinging.
struct GaugeChart: View {
    var value: Double
    var range: ClosedRange<Double> = 0...100
    let zones: [GaugeChartZone]
    var label = "Gauge"
    var valueText: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0))) }

    private let lineWidth: CGFloat = 26
    private let gap = 0.004

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let share = GaugeChartMath.share(of: value, in: range)
        let zone = GaugeChartMath.zone(for: value, in: zones)

        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .bottom) {
                ZStack {
                    ForEach(GaugeChartMath.spans(of: zones, in: range), id: \.zone.id) { span in
                        // A circle starts at three o'clock. Half a turn makes it start at nine, where the dial does.
                        Circle()
                            .inset(by: lineWidth / 2)
                            .trim(from: span.start / 2 + gap, to: span.end / 2 - gap)
                            .stroke(span.zone.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                            .rotationEffect(.degrees(180))
                    }
                }
                .frame(width: width, height: width)
                .frame(height: width / 2, alignment: .top)
                .clipped()

                Capsule()
                    .fill(.primary)
                    .frame(width: 5, height: width / 2 - lineWidth - 10)
                    .rotationEffect(.degrees(GaugeChartMath.needleAngle(share: share)), anchor: .bottom)
                    .animation(reduceMotion ? nil : .spring(duration: 0.9, bounce: 0.35), value: share)

                Circle()
                    .fill(.primary)
                    .frame(width: 18, height: 18)
                    .offset(y: 9)
            }
        }
        .aspectRatio(2, contentMode: .fit)
        // A dial reads from left to right in every language, like a speedometer.
        .environment(\.layoutDirection, .leftToRight)
        .padding(.bottom, 9)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue([valueText(value), zone?.name].compactMap { $0 }.joined(separator: ", "))
    }
}

// MARK: - Demo

struct GaugeChartDemo: View {
    private let zones = [
        GaugeChartZone(name: "Good", upTo: 50, color: .green),
        GaugeChartZone(name: "Moderate", upTo: 100, color: .yellow),
        GaugeChartZone(name: "Unhealthy", upTo: 150, color: .orange),
        GaugeChartZone(name: "Hazardous", upTo: 200, color: .red),
    ]
    private let readings: [(place: String, value: Double)] = [("Harbor", 32), ("Old Town", 118), ("Ring Road", 171), ("Hillside", 74)]

    @State private var index = 0

    var body: some View {
        let reading = readings[index]
        let zone = GaugeChartMath.zone(for: reading.value, in: zones)

        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("Air Quality")
                    .font(.title2.bold())
                Text(reading.place)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }

            GaugeChart(value: reading.value, range: 0...200, zones: zones, label: "Air quality index")
                .padding(.horizontal, 12)

            VStack(spacing: 2) {
                Text(reading.value, format: .number)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(zone?.name ?? "")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)

            Button("Next Station", systemImage: "arrow.right") {
                withAnimation(.snappy) { index = (index + 1) % readings.count }
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    GaugeChartDemo()
}
