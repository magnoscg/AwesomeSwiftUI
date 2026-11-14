// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Numbered steps joined by a line that fills as the current step advances.
///
/// `currentStep` starts at 0. Passing `steps.count` marks every step as done.
/// With Reduce Motion on, the steps change without animating.
struct StepProgressIndicator: View {
    let steps: [String]
    var currentStep: Int
    var tint: Color = .indigo

    @ScaledMetric(relativeTo: .subheadline) private var markerSize = 36
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let lineHeight: CGFloat = 4

    private var current: Int { min(max(currentStep, 0), steps.count) }

    private var lineFraction: CGFloat {
        guard steps.count > 1 else { return 0 }
        return CGFloat(min(current, steps.count - 1)) / CGFloat(steps.count - 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                VStack(spacing: 8) {
                    marker(index)

                    Text(steps[index])
                        .font(.caption)
                        .foregroundStyle(index <= current ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(alignment: .topLeading) { line }
        .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: current)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(accessibilityText)
    }

    private var line: some View {
        GeometryReader { proxy in
            let inset = proxy.size.width / CGFloat(max(steps.count, 1) * 2)
            let length = proxy.size.width - inset * 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(tint)
                    .frame(width: length * lineFraction)
            }
            .frame(width: length, height: lineHeight)
            .offset(x: inset, y: (markerSize - lineHeight) / 2)
        }
    }

    private func marker(_ index: Int) -> some View {
        let isDone = index < current
        let isCurrent = index == current

        return ZStack {
            Circle()
                .fill(isDone || isCurrent ? tint : Color(.systemGray5))

            if isDone {
                Image(systemName: "checkmark")
                    .fontWeight(.bold)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("\(index + 1)")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isDone || isCurrent ? Color.white : Color.primary)
        .frame(width: markerSize, height: markerSize)
        .background {
            Circle()
                .fill(tint.opacity(0.25))
                .padding(-5)
                .opacity(isCurrent ? 1 : 0)
        }
    }

    private var accessibilityText: String {
        guard current < steps.count else { return "All \(steps.count) steps done" }
        return "Step \(current + 1) of \(steps.count), \(steps[current])"
    }
}

// MARK: - Demo

struct StepProgressIndicatorDemo: View {
    @State private var step = 0

    private let steps = ["Cart", "Address", "Payment", "Review"]
    private let symbols = ["cart.fill", "house.fill", "creditcard.fill", "checkmark.seal.fill"]

    var body: some View {
        VStack(spacing: 44) {
            Image(systemName: symbols[min(step, symbols.count - 1)])
                .font(.system(.largeTitle))
                .imageScale(.large)
                .foregroundStyle(.indigo.gradient)
                .contentTransition(.symbolEffect(.replace))
                // The symbols are not equally tall. One height keeps what is below in place.
                .frame(height: 56)
                .accessibilityHidden(true)

            Text("Checkout")
                .font(.system(.title, design: .rounded, weight: .bold))

            StepProgressIndicator(steps: steps, currentStep: step)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.9))
                step = (step + 1) % (steps.count + 1)
            }
        }
    }
}

#Preview {
    StepProgressIndicatorDemo()
}
