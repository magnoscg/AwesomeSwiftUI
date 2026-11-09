// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum ContentSwapTransitionStyle {
    case numeric(Double)
    case interpolate
    case opacity
}

/// Text that swaps its value with a content transition: rolling digits, a morph or a fade.
/// Change the text inside an animation.
///
/// With Reduce Motion on, numbers fade instead of rolling.
struct ContentSwapTransition: View {
    let text: String
    var style: ContentSwapTransitionStyle = .opacity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transition: ContentTransition {
        switch style {
        case .numeric(let value): reduceMotion ? .opacity : .numericText(value: value)
        case .interpolate: .interpolate
        case .opacity: .opacity
        }
    }

    var body: some View {
        Text(text)
            .contentTransition(transition)
    }
}

// MARK: - Demo

struct ContentSwapTransitionDemo: View {
    @State private var step = 0

    private let amounts: [Double] = [1284, 1317, 2096, 1905]
    private let greetings = ["Hello", "Hola", "Bonjour", "Ciao"]

    private var amount: Double { amounts[step % amounts.count] }
    private var isHeavy: Bool { step.isMultiple(of: 2) }

    var body: some View {
        VStack(spacing: 16) {
            card("numericText", systemImage: "number", tint: .blue) {
                ContentSwapTransition(text: amount.formatted(.currency(code: "EUR")), style: .numeric(amount))
            }

            card("interpolate", systemImage: "textformat", tint: .pink) {
                ContentSwapTransition(text: "Weight", style: .interpolate)
                    .fontWeight(isHeavy ? .black : .ultraLight)
                    .foregroundStyle(isHeavy ? .pink : .orange)
            }

            card("opacity", systemImage: "circle.lefthalf.filled", tint: .teal) {
                ContentSwapTransition(text: greetings[step % greetings.count], style: .opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            while (try? await Task.sleep(for: .seconds(1.2))) != nil {
                withAnimation(.smooth(duration: 0.6)) { step += 1 }
            }
        }
    }

    private func card(
        _ title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            content()
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
    }
}

#Preview {
    ContentSwapTransitionDemo()
}
