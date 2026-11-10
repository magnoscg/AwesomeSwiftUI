// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum CircularRangeSliderPart: Equatable, Sendable {
    case start, end, both
}

nonisolated enum CircularRangeSliderMath {
    static let touchTarget = 44.0

    /// How far around the dial a point is: 0 at twelve o'clock, growing clockwise up to 1.
    static func turn(at point: CGPoint, in size: CGSize) -> Double {
        let x = point.x - size.width / 2
        let y = point.y - size.height / 2
        guard x != 0 || y != 0 else { return 0 }
        let turn = atan2(x, -y) / (2 * .pi)
        return turn < 0 ? turn + 1 : turn
    }

    /// The center of a handle that is `turn` around a dial drawn with a line `lineWidth` thick.
    static func point(atTurn turn: Double, in size: CGSize, lineWidth: Double) -> CGPoint {
        let radius = (min(size.width, size.height) - lineWidth) / 2
        let angle = turn * 2 * .pi
        return CGPoint(x: size.width / 2 + sin(angle) * radius, y: size.height / 2 - cos(angle) * radius)
    }

    /// `value` snapped to `step` and brought into `0..<total`, since the dial has no end.
    static func wrapped(_ value: Double, total: Double, step: Double = 0) -> Double {
        guard total > 0, value.isFinite else { return 0 }
        let snapped = step > 0 ? (value / step).rounded() * step : value
        let rest = snapped.truncatingRemainder(dividingBy: total)
        return rest < 0 ? rest + total : rest
    }

    /// How long the range is, going clockwise from `start` to `end`.
    static func span(from start: Double, to end: Double, total: Double) -> Double {
        wrapped(end - start, total: total)
    }

    /// Whether a handle may move so that the range becomes `new` long.
    ///
    /// The range keeps `minimumSpan` and leaves as much free, and a handle cannot jump over the
    /// other one, which would turn a short range into a long one at once.
    static func allows(span new: Double, from old: Double, total: Double, minimumSpan: Double) -> Bool {
        let least = min(max(minimumSpan, 0), total / 2)
        return new >= least && new <= total - least && abs(new - old) <= total / 2
    }

    /// What a touch at `point` takes hold of: a handle, the range between them, or nothing.
    static func part(at point: CGPoint, in size: CGSize, startTurn: Double, endTurn: Double, lineWidth: Double) -> CircularRangeSliderPart? {
        let reach = max(lineWidth, touchTarget) / 2
        let start = self.point(atTurn: startTurn, in: size, lineWidth: lineWidth)
        let end = self.point(atTurn: endTurn, in: size, lineWidth: lineWidth)
        let toStart = hypot(point.x - start.x, point.y - start.y)
        let toEnd = hypot(point.x - end.x, point.y - end.y)
        if min(toStart, toEnd) <= reach { return toEnd <= toStart ? .end : .start }

        let radius = (min(size.width, size.height) - lineWidth) / 2
        let fromCenter = hypot(point.x - size.width / 2, point.y - size.height / 2)
        guard abs(fromCenter - radius) <= reach else { return nil }

        let here = span(from: startTurn, to: turn(at: point, in: size), total: 1)
        return here <= span(from: startTurn, to: endTurn, total: 1) ? .both : nil
    }
}

/// A dial with a range on it: drag either handle to move one end, or the band between them to
/// move both. The range can cross twelve o'clock, like a night from 23:00 to 7:00.
///
/// `start` and `end` go from 0 up to `total`, which is one full turn. Set the color with `tint`.
/// VoiceOver reads each handle as an adjustable value, described by `valueText`.
struct CircularRangeSlider<Center: View>: View {
    @Binding var start: Double
    @Binding var end: Double
    /// The value of a full turn.
    var total = 24.0
    /// The handles stop at multiples of it. Zero lets them stop anywhere.
    var step = 0.25
    /// The shortest range, which is also the shortest gap left outside it.
    var minimumSpan = 0.0
    var lineWidth: CGFloat = 40
    var startSymbol: String?
    var endSymbol: String?
    var startLabel = "Start"
    var endLabel = "End"
    var valueText: (Double) -> String = { $0.formatted() }
    @ViewBuilder var center: () -> Center

    private let handleInset: CGFloat = 4
    private let centerPadding: CGFloat = 12

    @State private var grab: CircularRangeSliderGrab?
    @GestureState private var isDragging = false

    private var startValue: Double { CircularRangeSliderMath.wrapped(start, total: total) }
    private var endValue: Double { CircularRangeSliderMath.wrapped(end, total: total) }
    private var span: Double { CircularRangeSliderMath.span(from: startValue, to: endValue, total: total) }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                dial(in: proxy.size)
            }
            // A dial turns clockwise in every language, like a clock, and a gesture is not mirrored either.
            .environment(\.layoutDirection, .leftToRight)

            center()
                .padding(lineWidth + centerPadding)
        }
        .aspectRatio(1, contentMode: .fit)
        .sensoryFeedback(trigger: [start, end]) { _, _ in step > 0 ? .selection : nil }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { grab = nil }
        }
    }

    private func dial(in size: CGSize) -> some View {
        let startTurn = turn(of: startValue)
        let endTurn = turn(of: endValue)

        return ZStack {
            Circle()
                .strokeBorder(.fill.tertiary, lineWidth: lineWidth)

            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: turn(of: span))
                .stroke(.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startTurn * 360 - 90))

            handle(.start, symbol: startSymbol, label: startLabel, value: startValue, in: size)
            handle(.end, symbol: endSymbol, label: endLabel, value: endValue, in: size)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Circle().inset(by: lineWidth / 2).stroke(lineWidth: max(lineWidth, CircularRangeSliderMath.touchTarget)))
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged { value in
                    if grab == nil {
                        let part = CircularRangeSliderMath.part(at: value.startLocation, in: size, startTurn: startTurn, endTurn: endTurn, lineWidth: lineWidth)
                        grab = CircularRangeSliderGrab(part: part, turn: CircularRangeSliderMath.turn(at: value.startLocation, in: size), start: startValue, span: span)
                    }
                    if let grab, let part = grab.part {
                        move(part, to: CircularRangeSliderMath.turn(at: value.location, in: size), grab: grab)
                    }
                }
                .onEnded { _ in grab = nil }
        )
    }

    private func handle(_ part: CircularRangeSliderPart, symbol: String?, label: String, value: Double, in size: CGSize) -> some View {
        Circle()
            .fill(.white)
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: lineWidth * 0.4, weight: .semibold))
                        .foregroundStyle(.tint)
                }
            }
            .frame(width: lineWidth - handleInset * 2, height: lineWidth - handleInset * 2)
            .position(CircularRangeSliderMath.point(atTurn: turn(of: value), in: size, lineWidth: lineWidth))
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(valueText(value))
            .accessibilityAdjustableAction { direction in
                let stride = step > 0 ? step : total / 100
                switch direction {
                case .increment: set(part, to: value + stride)
                case .decrement: set(part, to: value - stride)
                @unknown default: break
                }
            }
    }

    private func turn(of value: Double) -> Double {
        total > 0 ? value / total : 0
    }

    private func move(_ part: CircularRangeSliderPart, to turn: Double, grab: CircularRangeSliderGrab) {
        guard part == .both else { return set(part, to: turn * total) }

        let moved = CircularRangeSliderMath.wrapped(grab.start + (turn - grab.turn) * total, total: total, step: step)
        guard moved != startValue else { return }
        start = moved
        end = CircularRangeSliderMath.wrapped(moved + grab.span, total: total)
    }

    private func set(_ part: CircularRangeSliderPart, to value: Double) {
        let value = CircularRangeSliderMath.wrapped(value, total: total, step: step)
        let new = part == .start
            ? CircularRangeSliderMath.span(from: value, to: endValue, total: total)
            : CircularRangeSliderMath.span(from: startValue, to: value, total: total)
        guard CircularRangeSliderMath.allows(span: new, from: span, total: total, minimumSpan: minimumSpan) else { return }

        if part == .start, value != startValue { start = value }
        if part == .end, value != endValue { end = value }
    }
}

private struct CircularRangeSliderGrab: Equatable {
    /// `nil` when the touch began outside the handles and the range, and so moves nothing.
    var part: CircularRangeSliderPart?
    var turn: Double
    var start: Double
    var span: Double
}

// MARK: - Demo

struct CircularRangeSliderDemo: View {
    @State private var bedtime = 23.0
    @State private var wake = 7.0

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Sleep")
                .font(.largeTitle.bold())

            CircularRangeSlider(start: $bedtime, end: $wake, minimumSpan: 1, startSymbol: "bed.double.fill", endSymbol: "alarm.fill", startLabel: "Bedtime", endLabel: "Wake up", valueText: clock) {
                ZStack {
                    hours

                    VStack(spacing: 4) {
                        Text(Duration.seconds(asleep * 3600), format: .units(allowed: [.hours, .minutes], width: .narrow))
                            .font(.title.bold())
                            .monospacedDigit()
                        Text("of sleep")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .tint(.indigo)
            .padding(.horizontal, 20)

            HStack {
                time("Bedtime", bedtime, symbol: "bed.double.fill")
                Spacer()
                time("Wake up", wake, symbol: "alarm.fill")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
    }

    /// The face of a 24-hour clock, with a mark every hour and a number every six.
    private var hours: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { hour in
                let isMajor = hour % 6 == 0

                VStack(spacing: 4) {
                    Capsule()
                        .fill(isMajor ? HierarchicalShapeStyle.secondary : .tertiary)
                        .frame(width: 2, height: isMajor ? 10 : 5)
                    if isMajor {
                        Text(hour.formatted())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(Double(-hour) * 15))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .rotationEffect(.degrees(Double(hour) * 15))
            }
        }
        // The numbers of a clock stay where they are in a right-to-left layout.
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private var asleep: Double {
        CircularRangeSliderMath.span(from: bedtime, to: wake, total: 24)
    }

    private func time(_ title: String, _ value: Double, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(clock(value))
                .font(.title2.bold())
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func clock(_ value: Double) -> String {
        let minutes = Int((value * 60).rounded())
        let twoDigits = IntegerFormatStyle<Int>.number.precision(.integerLength(2))
        return "\((minutes / 60 % 24).formatted(twoDigits)):\((minutes % 60).formatted(twoDigits))"
    }
}

#Preview {
    CircularRangeSliderDemo()
}
