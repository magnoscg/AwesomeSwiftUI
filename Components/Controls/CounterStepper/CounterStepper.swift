// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum CounterStepperValue {
    /// The result of adding `step` to `value`, kept inside `range`.
    static func stepped(_ value: Int, by step: Int, in range: ClosedRange<Int>) -> Int {
        let (sum, overflowed) = value.addingReportingOverflow(step)
        if overflowed {
            return step > 0 ? range.upperBound : range.lowerBound
        }
        return min(max(sum, range.lowerBound), range.upperBound)
    }

    static func canStep(_ value: Int, by step: Int, in range: ClosedRange<Int>) -> Bool {
        stepped(value, by: step, in: range) != value
    }
}

/// Minus and plus buttons around a number that rolls as it changes.
///
/// With Reduce Motion on, the number changes without rolling.
struct CounterStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...99
    var step: Int = 1
    var title: LocalizedStringResource = "Value"
    var tint: Color = .indigo

    @ScaledMetric(relativeTo: .title) private var buttonSize = 56.0
    @ScaledMetric(relativeTo: .largeTitle) private var numberWidth = 76.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            stepButton(systemImage: "minus", label: "Decrease", delta: -step)

            Text(value, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
                .frame(minWidth: numberWidth)
                .accessibilityLabel(title)
                .accessibilityValue(value.formatted())

            stepButton(systemImage: "plus", label: "Increase", delta: step)
        }
        .padding(6)
        .background(.quaternary, in: .capsule)
        .sensoryFeedback(.selection, trigger: value)
    }

    private func stepButton(systemImage: String, label: String, delta: Int) -> some View {
        let isEnabled = CounterStepperValue.canStep(value, by: delta, in: range)

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                value = CounterStepperValue.stepped(value, by: delta, in: range)
            }
        } label: {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(isEnabled ? Color.white : Color.secondary)
                .frame(width: buttonSize, height: buttonSize)
                .background(isEnabled ? tint : Color.gray.opacity(0.2), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

// MARK: - Demo

struct CounterStepperDemo: View {
    @State private var tickets = 3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var total: Int { tickets * 24 }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 6) {
                Text("Tickets")
                    .font(.largeTitle.bold())
                Text(total, format: .currency(code: "EUR").precision(.fractionLength(0)))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(total)))
            }
            .accessibilityElement(children: .combine)

            CounterStepper(value: $tickets, range: 0...5, title: "Tickets")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CounterStepperDemo()
}
