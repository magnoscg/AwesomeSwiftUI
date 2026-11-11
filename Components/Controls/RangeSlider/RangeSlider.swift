// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum RangeSliderThumb: Equatable, Sendable {
    case lower, upper
}

nonisolated enum RangeSliderMath {
    /// Where `value` is along `bounds`, from 0 to 1.
    static func fraction(of value: Double, in bounds: ClosedRange<Double>) -> Double {
        let length = bounds.upperBound - bounds.lowerBound
        guard length > 0, value.isFinite else { return 0 }
        return min(max((value - bounds.lowerBound) / length, 0), 1)
    }

    /// `value` moved to the nearest multiple of `step`, counted from the start of `bounds`.
    static func snapped(_ value: Double, in bounds: ClosedRange<Double>, step: Double) -> Double {
        guard step > 0 else { return value }
        return bounds.lowerBound + ((value - bounds.lowerBound) / step).rounded() * step
    }

    /// The lower end a drag asks for, kept inside `bounds` and `minimumSpan` below the upper end.
    static func lower(_ value: Double, upper: Double, in bounds: ClosedRange<Double>, step: Double = 0, minimumSpan: Double = 0) -> Double {
        guard value.isFinite else { return min(bounds.lowerBound, upper) }
        let highest = max(upper - max(minimumSpan, 0), bounds.lowerBound)
        return min(min(max(snapped(value, in: bounds, step: step), bounds.lowerBound), highest), upper)
    }

    /// The upper end a drag asks for, kept inside `bounds` and `minimumSpan` above the lower end.
    static func upper(_ value: Double, lower: Double, in bounds: ClosedRange<Double>, step: Double = 0, minimumSpan: Double = 0) -> Double {
        guard value.isFinite else { return max(bounds.upperBound, lower) }
        let lowest = min(lower + max(minimumSpan, 0), bounds.upperBound)
        return max(max(min(snapped(value, in: bounds, step: step), bounds.upperBound), lowest), lower)
    }

    /// The thumb a touch takes, with every position as a fraction of the track.
    ///
    /// It is the nearest one. When both sit on the same spot it is the one that can still move
    /// toward the touch, so two thumbs at one end never get stuck.
    static func thumb(nearest touch: Double, lower: Double, upper: Double) -> RangeSliderThumb {
        let toLower = abs(touch - lower)
        let toUpper = abs(touch - upper)
        if toLower != toUpper { return toLower < toUpper ? .lower : .upper }
        if touch != lower { return touch < lower ? .lower : .upper }
        return lower > 0.5 ? .lower : .upper
    }
}

/// A slider with two thumbs that picks a range, like a price filter.
///
/// Drag a thumb, or the track near it: the nearest thumb moves with the finger without jumping
/// to it. Set the color with `tint`. VoiceOver reads each thumb as an adjustable value, described
/// by `valueText`, and the slider follows the layout direction.
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    var bounds: ClosedRange<Double> = 0...1
    /// The thumbs stop at multiples of it. Zero lets them stop anywhere.
    var step = 0.0
    /// The shortest distance the thumbs keep between them.
    var minimumSpan = 0.0
    var lowerLabel = "Minimum"
    var upperLabel = "Maximum"
    var valueText: (Double) -> String = { $0.formatted() }

    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 4
    private let touchHeight: CGFloat = 44

    @State private var width: CGFloat = 0
    @State private var grab: RangeSliderGrab?
    @GestureState private var isDragging = false
    @Environment(\.layoutDirection) private var layoutDirection

    /// How far the center of a thumb travels from one end of the track to the other.
    private var travel: CGFloat { max(width - thumbSize, 0) }

    var body: some View {
        let lower = RangeSliderMath.fraction(of: range.lowerBound, in: bounds)
        let upper = RangeSliderMath.fraction(of: range.upperBound, in: bounds)

        ZStack(alignment: .leading) {
            Capsule()
                .fill(.fill.tertiary)
                .frame(height: trackHeight)

            Capsule()
                .fill(.tint)
                .frame(width: CGFloat(upper - lower) * travel + thumbSize, height: trackHeight)
                .offset(x: CGFloat(lower) * travel)

            thumb(.lower, at: lower)
            thumb(.upper, at: upper)
        }
        .frame(height: touchHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(.rect)
        .gesture(drag(lower: lower, upper: upper))
        .sensoryFeedback(trigger: range) { _, _ in step > 0 ? .selection : nil }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { grab = nil }
        }
    }

    private func thumb(_ thumb: RangeSliderThumb, at fraction: Double) -> some View {
        let value = thumb == .lower ? range.lowerBound : range.upperBound

        return Circle()
            .fill(.white)
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            .frame(width: thumbSize, height: thumbSize)
            .offset(x: CGFloat(fraction) * travel)
            .accessibilityElement()
            .accessibilityLabel(thumb == .lower ? lowerLabel : upperLabel)
            .accessibilityValue(valueText(value))
            .accessibilityAdjustableAction { direction in
                let stride = step > 0 ? step : (bounds.upperBound - bounds.lowerBound) / 20
                switch direction {
                case .increment: set(thumb, to: value + stride)
                case .decrement: set(thumb, to: value - stride)
                @unknown default: break
                }
            }
    }

    private func drag(lower: Double, upper: Double) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                guard travel > 0 else { return }
                // The track is mirrored in a right-to-left layout and the gesture is not.
                let isMirrored = layoutDirection == .rightToLeft

                if grab == nil {
                    let x = isMirrored ? width - value.startLocation.x : value.startLocation.x
                    let thumb = RangeSliderMath.thumb(nearest: Double((x - thumbSize / 2) / travel), lower: lower, upper: upper)
                    grab = RangeSliderGrab(thumb: thumb, value: thumb == .lower ? range.lowerBound : range.upperBound)
                }
                guard let grab else { return }

                let moved = Double((isMirrored ? -value.translation.width : value.translation.width) / travel)
                set(grab.thumb, to: grab.value + moved * (bounds.upperBound - bounds.lowerBound))
            }
            .onEnded { _ in grab = nil }
    }

    private func set(_ thumb: RangeSliderThumb, to value: Double) {
        let new = thumb == .lower
            ? RangeSliderMath.lower(value, upper: range.upperBound, in: bounds, step: step, minimumSpan: minimumSpan)...range.upperBound
            : range.lowerBound...RangeSliderMath.upper(value, lower: range.lowerBound, in: bounds, step: step, minimumSpan: minimumSpan)
        if new != range { range = new }
    }
}

private struct RangeSliderGrab {
    var thumb: RangeSliderThumb
    /// The value the thumb had when the drag began.
    var value: Double
}

// MARK: - Demo

struct RangeSliderDemo: View {
    private let bounds = 20.0...300.0
    /// How many stays there are in each slice of the price range, from the cheapest.
    private let stays = [2, 5, 9, 14, 22, 30, 34, 29, 24, 18, 15, 11, 8, 6, 4, 3, 2, 2, 1, 1]

    @State private var price = 60.0...180.0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Price range")
                    .font(.title2.bold())
                Text("Nightly prices before fees and taxes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                histogram

                RangeSlider(range: $price, bounds: bounds, step: 5, minimumSpan: 30, lowerLabel: "Minimum price", upperLabel: "Maximum price", valueText: dollars)
            }

            HStack {
                amount("Minimum", price.lowerBound)
                Spacer()
                amount("Maximum", price.upperBound)
            }

            Text("^[\(matches) stay](inflect: true)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(.tint, in: .capsule)
                .contentTransition(.numericText())
                .animation(.snappy, value: matches)
        }
        .padding(24)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .tint(.pink)
    }

    private var histogram: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(stays.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected(index) ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary))
                    .frame(height: CGFloat(stays[index]) * 3)
            }
        }
        .padding(.horizontal, 14)
        .accessibilityHidden(true)
    }

    private var matches: Int {
        stays.indices.filter(isSelected).map { stays[$0] }.reduce(0, +)
    }

    /// Whether the middle of a slice of the price range is inside the chosen prices.
    private func isSelected(_ index: Int) -> Bool {
        let slice = (bounds.upperBound - bounds.lowerBound) / Double(stays.count)
        return price.contains(bounds.lowerBound + (Double(index) + 0.5) * slice)
    }

    private func amount(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(dollars(value))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.fill.quaternary, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func dollars(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#Preview {
    RangeSliderDemo()
}
