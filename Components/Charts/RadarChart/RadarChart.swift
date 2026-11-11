// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated struct RadarChartSeries: Identifiable, Sendable {
    var name: String
    /// One value per axis, in the order of the axes.
    var values: [Double]
    var color: Color

    var id: String { name }
}

nonisolated enum RadarChartMath {
    /// The direction of an axis in radians, with the first one pointing up and the rest going clockwise.
    static func angle(of axis: Int, count: Int) -> Double {
        guard count > 0 else { return -.pi / 2 }
        return Double(axis) / Double(count) * 2 * .pi - .pi / 2
    }

    /// How far along its axis a value is, from 0 at the center to 1 at the edge.
    static func share(of value: Double, maximum: Double) -> Double {
        guard maximum > 0, value.isFinite else { return 0 }
        return min(max(value / maximum, 0), 1)
    }

    /// The point `share` of the way along an axis, in a circle of `radius` around `center`.
    static func point(axis: Int, count: Int, share: Double, center: CGPoint, radius: Double) -> CGPoint {
        let angle = angle(of: axis, count: count)
        return CGPoint(x: center.x + cos(angle) * radius * share, y: center.y + sin(angle) * radius * share)
    }

    /// The corners of the shape of a series: one per axis. A series with fewer values than axes
    /// is at the center on the rest.
    static func corners(values: [Double], axes: Int, maximum: Double, center: CGPoint, radius: Double) -> [CGPoint] {
        (0..<max(axes, 0)).map { axis in
            let value = axis < values.count ? values[axis] : 0
            return point(axis: axis, count: axes, share: share(of: value, maximum: maximum), center: center, radius: radius)
        }
    }
}

/// A radar chart: one axis per quality, spread around a center, and a shape per series that
/// reaches further along an axis the higher its value. It compares two or three profiles at a glance.
///
/// The shapes grow from the center when they appear. VoiceOver reads each axis with the value
/// of every series. With Reduce Motion on, the shapes are there from the start.
struct RadarChart: View {
    let axes: [String]
    let series: [RadarChartSeries]
    var maximum = 100.0
    /// How many rings the grid has, the outer one included.
    var rings = 4

    private let labelRoom: CGFloat = 34

    @State private var growth = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = max(min(proxy.size.width, proxy.size.height) / 2 - labelRoom, 0)

            ZStack {
                RadarChartGrid(axes: axes.count, rings: rings)
                    .stroke(.quaternary, lineWidth: 1)
                    .padding(labelRoom)

                ForEach(series) { series in
                    let shape = RadarChartShape(values: series.values, axes: axes.count, maximum: maximum, growth: reduceMotion ? 1 : growth)

                    shape
                        .fill(series.color.opacity(0.22))
                        .padding(labelRoom)
                    shape
                        .stroke(series.color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                        .padding(labelRoom)
                }

                ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                    Text(axis)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .position(RadarChartMath.point(axis: index, count: axes.count, share: 1, center: center, radius: radius + labelRoom * 0.55))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        // The axes go clockwise from the top in every language, like the hours of a clock.
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.25)) { growth = 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Radar chart")
        .accessibilityChildren {
            ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                Text(axis)
                    .accessibilityValue(description(ofAxis: index))
            }
        }
    }

    private func description(ofAxis axis: Int) -> String {
        series
            .map { "\($0.name) \((axis < $0.values.count ? $0.values[axis] : 0).formatted())" }
            .joined(separator: ", ")
    }
}

/// The grid behind the shapes: a polygon per ring and a spoke per axis.
nonisolated struct RadarChartGrid: Shape {
    var axes: Int
    var rings: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        guard axes > 2 else { return path }

        for ring in 1...max(rings, 1) {
            let share = Double(ring) / Double(max(rings, 1))
            path.addLines((0..<axes).map { RadarChartMath.point(axis: $0, count: axes, share: share, center: center, radius: radius) })
            path.closeSubpath()
        }
        for axis in 0..<axes {
            path.move(to: center)
            path.addLine(to: RadarChartMath.point(axis: axis, count: axes, share: 1, center: center, radius: radius))
        }
        return path
    }
}

/// The shape of one series. `growth` animates it out from the center.
nonisolated struct RadarChartShape: Shape {
    var values: [Double]
    var axes: Int
    var maximum: Double
    var growth: Double

    var animatableData: Double {
        get { growth }
        set { growth = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard axes > 2 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.addLines(RadarChartMath.corners(values: values, axes: axes, maximum: maximum, center: center, radius: min(rect.width, rect.height) / 2 * growth))
        path.closeSubpath()
        return path
    }
}

// MARK: - Demo

struct RadarChartDemo: View {
    private let axes = ["Speed", "Power", "Range", "Comfort", "Price", "Design"]
    private let bikes = [
        RadarChartSeries(name: "City", values: [55, 40, 62, 90, 85, 70], color: .teal),
        RadarChartSeries(name: "Trail", values: [80, 92, 78, 50, 45, 82], color: .orange),
    ]

    @State private var run = 0

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Which e-bike?")
                    .font(.title2.bold())
                Text("Two models, six things that matter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            RadarChart(axes: axes, series: bikes)
                .id(run)

            HStack(spacing: 20) {
                ForEach(bikes) { bike in
                    Label {
                        Text(bike.name)
                    } icon: {
                        Circle()
                            .fill(bike.color)
                            .frame(width: 10, height: 10)
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            .accessibilityHidden(true)

            Button("Replay", systemImage: "arrow.clockwise") {
                run += 1
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    RadarChartDemo()
}
