// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum TickMarkSliderMath {
    /// The tick closest to a value, which is where the slider settles when it is let go.
    static func nearestTick(to value: Double, in ticks: [Double]) -> Double? {
        ticks.min { abs($0 - value) < abs($1 - value) }
    }

    /// The ticks that fall inside the range, in order and without repeats.
    static func ticks(_ ticks: [Double], in range: ClosedRange<Double>) -> [Double] {
        Array(Set(ticks.filter { $0.isFinite && range.contains($0) })).sorted()
    }
}

/// The system slider with a mark at the values that matter, using the tick marks that iOS 26
/// added to `Slider`. Let go and it settles on the nearest mark. The system draws the marks as
/// dots and keeps their labels for assistive technologies.
///
/// `neutralValue` is where the tinted part of the track starts, for a value that goes both ways,
/// such as a balance or an offset. It is a system `Slider`, so VoiceOver and Dynamic Type are the system's.
@available(iOS 26, *)
struct TickMarkSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let ticks: [Double]
    var neutralValue: Double?
    var label = "Value"
    /// Whether the slider moves to the nearest mark when it is let go.
    var snapsToTicks = true
    var tickLabel: (Double) -> String = { $0.formatted() }

    var body: some View {
        let marks = TickMarkSliderMath.ticks(ticks, in: range)

        Slider(value: $value, in: range, neutralValue: neutralValue) {
            Text(label)
        } currentValueLabel: {
            Text(tickLabel(value))
        } ticks: {
            SliderTickContentForEach(marks, id: \.self) { mark in
                SliderTick(mark) {
                    Text(tickLabel(mark))
                }
            }
        } onEditingChanged: { isEditing in
            guard !isEditing, snapsToTicks, let mark = TickMarkSliderMath.nearestTick(to: value, in: marks) else { return }
            withAnimation(.snappy) { value = mark }
        }
        .sensoryFeedback(.selection, trigger: TickMarkSliderMath.nearestTick(to: value, in: marks))
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct TickMarkSliderDemo: View {
    @State private var speed = 1.0
    @State private var balance = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Playback")
                .font(.title2.bold())

            setting("Speed", detail: "\(speed.formatted(.number.precision(.fractionLength(0...2))))×") {
                TickMarkSlider(value: $speed, range: 0.5...2, ticks: [0.5, 1, 1.5, 2], label: "Speed") {
                    "\($0.formatted())×"
                }
            }

            setting("Balance", detail: balance == 0 ? "Center" : (balance < 0 ? "Left" : "Right")) {
                TickMarkSlider(value: $balance, range: -1...1, ticks: [-1, 0, 1], neutralValue: 0, label: "Balance") { mark in
                    mark == 0 ? "C" : (mark < 0 ? "L" : "R")
                }
            }
        }
        .padding(24)
        .background(.background, in: .rect(cornerRadius: 24))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func setting(_ title: String, detail: String, @ViewBuilder slider: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(detail)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .accessibilityHidden(true)

            slider()
        }
    }
}

@available(iOS 26, *)
#Preview {
    TickMarkSliderDemo()
}
