// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A line chart whose line draws in from left to right while a dot follows its tip.
///
/// It draws again whenever the values change. With Reduce Motion on, the finished chart appears.
struct LineChartDrawIn: View {
    let values: [Double]
    var tint: Color = .indigo
    var duration: Double = 1.6

    @State private var progress = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let inset = 12.0
    private var shownProgress: Double { reduceMotion ? 1 : progress }

    var body: some View {
        ZStack {
            LineChartDrawInArea(values: values, inset: inset, progress: shownProgress)
                .fill(.linearGradient(colors: [tint.opacity(0.28), tint.opacity(0)], startPoint: .top, endPoint: .bottom))

            LineChartDrawInLine(values: values, inset: inset)
                .trim(from: 0, to: shownProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

            LineChartDrawInDot(values: values, inset: inset, radius: 12, progress: shownProgress)
                .fill(tint.opacity(0.25))

            LineChartDrawInDot(values: values, inset: inset, radius: 6, progress: shownProgress)
                .fill(tint)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Line chart")
        .accessibilityValue(LineChartDrawInLogic.summary(of: values))
        .task(id: values) {
            guard !reduceMotion else {
                progress = 1
                return
            }
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { progress = 0 }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: max(duration, 0))) { progress = 1 }
        }
    }
}

nonisolated private struct LineChartDrawInLine: Shape {
    let values: [Double]
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(LineChartDrawInLogic.points(for: values, in: rect.insetBy(dx: inset, dy: inset)))
        return path
    }
}

/// The fill under the line, up to its tip, so it never runs ahead of the line being drawn.
nonisolated private struct LineChartDrawInArea: Shape {
    let values: [Double]
    let inset: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let points = LineChartDrawInLogic.points(for: values, in: rect.insetBy(dx: inset, dy: inset))
        guard let first = points.first, let last = LineChartDrawInLogic.point(at: progress, along: points) else { return Path() }

        var path = Path()
        path.addLines(points.filter { $0.x < last.x } + [last])
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A circle that re-computes its position for every animation frame, so it stays on the tip.
nonisolated private struct LineChartDrawInDot: Shape {
    let values: [Double]
    let inset: CGFloat
    let radius: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let points = LineChartDrawInLogic.points(for: values, in: rect.insetBy(dx: inset, dy: inset))
        guard let center = LineChartDrawInLogic.point(at: progress, along: points) else { return Path() }
        return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

/// The geometry of the chart, apart from the view so it can be tested.
nonisolated enum LineChartDrawInLogic {
    static func points(for values: [Double], in rect: CGRect) -> [CGPoint] {
        let values = values.filter(\.isFinite)
        guard !rect.isNull, rect.width > 0, rect.height > 0,
              let low = values.min(), let high = values.max() else { return [] }

        let span = high - low
        let step = values.count > 1 ? rect.width / CGFloat(values.count - 1) : 0
        return values.enumerated().map { index, value in
            let ratio = span > 0 && span.isFinite ? (value - low) / span : 0.5
            return CGPoint(x: rect.minX + CGFloat(index) * step, y: rect.maxY - CGFloat(ratio) * rect.height)
        }
    }

    /// The point at a fraction of the line's length, which is how `trim` measures it too.
    static func point(at progress: Double, along points: [CGPoint]) -> CGPoint? {
        guard let first = points.first else { return nil }
        let lengths = zip(points, points.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        let total = lengths.reduce(0, +)
        guard total > 0 else { return first }

        var remaining = total * CGFloat(min(max(progress, 0), 1))
        for (index, length) in lengths.enumerated() where length > 0 {
            if remaining <= length {
                let fraction = remaining / length
                let start = points[index]
                let end = points[index + 1]
                return CGPoint(x: start.x + (end.x - start.x) * fraction, y: start.y + (end.y - start.y) * fraction)
            }
            remaining -= length
        }
        return points.last
    }

    static func summary(of values: [Double]) -> String {
        let values = values.filter(\.isFinite)
        guard let first = values.first, let last = values.last,
              let low = values.min(), let high = values.max() else { return "No data" }
        return "From \(first.formatted()) to \(last.formatted()). Lowest \(low.formatted()), highest \(high.formatted())."
    }
}

// MARK: - Demo

struct LineChartDrawInDemo: View {
    @State private var isAlternate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var values: [Double] {
        isAlternate
            ? [62, 58, 70, 64, 80, 76, 66, 72, 88, 84, 96, 90]
            : [20, 34, 28, 46, 40, 58, 52, 74, 66, 82, 78, 96]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active users")
                .font(.largeTitle.bold())
            Text(isAlternate ? "Europe" : "Americas")
                .font(.title3)
                .foregroundStyle(.secondary)

            LineChartDrawIn(values: values)
                .padding(.vertical, 24)
        }
        .padding(24)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.8))
                guard !Task.isCancelled else { return }
                isAlternate.toggle()
            }
        }
    }
}

#Preview {
    LineChartDrawInDemo()
}
