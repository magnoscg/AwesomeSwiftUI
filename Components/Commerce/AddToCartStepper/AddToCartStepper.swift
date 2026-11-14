// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum AddToCartStepperMath {
    /// The highest quantity allowed. Zero is valid, and means nothing can be added.
    static func limit(maximum: Int) -> Int {
        min(max(maximum, 0), 1_000_000)
    }
}

/// An add button that morphs into a quantity stepper, and back again at zero.
///
/// The capsule is one background around content that changes, so it resizes by itself
/// and nothing has to match geometry. VoiceOver can also adjust the count directly.
struct AddToCartStepper: View {
    @Binding var quantity: Int
    var maximum: Int = 99
    var title: LocalizedStringResource = "Add"
    var tint: Color = .indigo

    @ScaledMetric(relativeTo: .headline) private var buttonSize = 44.0
    @ScaledMetric(relativeTo: .headline) private var countWidth = 34.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var limit: Int { AddToCartStepperMath.limit(maximum: maximum) }
    private var current: Int { min(max(quantity, 0), limit) }
    private var animation: Animation? { reduceMotion ? nil : .bouncy(duration: 0.35) }

    var body: some View {
        HStack(spacing: 0) {
            if quantity <= 0 {
                addButton.transition(.opacity)
            } else {
                stepButton(systemImage: quantity == 1 ? "trash" : "minus", label: "Decrease quantity", change: -1)
                    .transition(.opacity)
                countLabel.transition(.opacity)
                stepButton(systemImage: "plus", label: "Increase quantity", change: 1)
                    .disabled(quantity >= limit)
                    .transition(.opacity)
            }
        }
        .foregroundStyle(AddToCartStepperContrastingForeground(background: tint))
        .background(tint.gradient, in: .capsule)
        .sensoryFeedback(.selection, trigger: quantity)
    }

    private var addButton: some View {
        Button {
            set(1)
        } label: {
            Label(title, systemImage: "plus")
                .font(.headline)
                .padding(.horizontal, 22)
                .frame(minHeight: buttonSize)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(limit == 0)
        .accessibilityLabel("\(title) to cart")
    }

    private func stepButton(systemImage: String, label: String, change: Int) -> some View {
        Button {
            set(current + change)
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: buttonSize, height: buttonSize)
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var countLabel: some View {
        Text(quantity, format: .number)
            .font(.headline.monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(quantity)))
            .frame(minWidth: countWidth)
            .accessibilityLabel("Quantity")
            .accessibilityValue(quantity.formatted())
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: set(current + 1)
                case .decrement: set(current - 1)
                @unknown default: break
                }
            }
    }

    private func set(_ newValue: Int) {
        withAnimation(animation) { quantity = min(max(newValue, 0), limit) }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct AddToCartStepperContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct AddToCartStepperDemo: View {
    @State private var quantity = 0

    private var subtotal: String {
        (Double(quantity) * 3.5).formatted(.currency(code: "EUR"))
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.orange.opacity(0.16), .indigo.opacity(0.12)], startPoint: .top, endPoint: .bottom))
    }

    private var content: some View {
        VStack(spacing: 24) {
            Image(systemName: "cup.and.saucer.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 110)
                .foregroundStyle(.linearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom))
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("Flat white")
                    .font(.largeTitle.bold())
                Text("Double shot, velvety milk")
                    .foregroundStyle(.secondary)
            }

            AddToCartStepper(quantity: $quantity)
                .frame(minHeight: 44)

            Text("Subtotal \(subtotal)")
                .font(.title3.weight(.semibold))
                .opacity(quantity > 0 ? 1 : 0)
        }
        .padding(24)
    }
}

#Preview {
    AddToCartStepperDemo()
}
