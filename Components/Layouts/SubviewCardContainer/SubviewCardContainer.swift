// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

extension ContainerValues {
    @Entry var subviewCardTint: Color = .accentColor
}

extension View {
    /// The color of the card this view gets inside a `SubviewCardContainer`.
    func subviewCardTint(_ color: Color) -> some View {
        containerValue(\.subviewCardTint, color)
    }
}

/// A container that turns every child of its `@ViewBuilder` into a tinted card.
///
/// `ForEach(subviews:)` sees each resolved child, so it works the same for
/// static views and for children that come from a `ForEach` or an `if`.
struct SubviewCardContainer<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(subviews: content) { subview in
                let tint = subview.containerValues.subviewCardTint

                subview
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .padding(.leading, 6)
                    .background(tint.opacity(0.16), in: .rect(cornerRadius: 18))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(tint.gradient)
                            .frame(width: 5)
                            .padding(.vertical, 12)
                            .padding(.leading, 8)
                            .accessibilityHidden(true)
                    }
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Demo

struct SubviewCardContainerDemo: View {
    private static let colors: [Color] = [.pink, .orange, .teal, .purple, .green]

    @State private var reminders = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Today")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    SubviewCardContainer {
                        Label("A static child", systemImage: "square.fill")
                            .font(.headline)
                            .subviewCardTint(.indigo)

                        Text("Plain text becomes a card too, with no wrapper around it.")
                            .subviewCardTint(.blue)

                        ForEach(0..<reminders, id: \.self) { index in
                            Label("Child \(index + 1) from a ForEach", systemImage: "bell.fill")
                                .subviewCardTint(Self.colors[index])
                        }
                    }
                }
                .padding(20)
            }

            HStack(spacing: 14) {
                Button("Remove", systemImage: "minus") { change(by: -1) }
                    .disabled(reminders == 0)
                Button("Add", systemImage: "plus") { change(by: 1) }
                    .disabled(reminders == Self.colors.count)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.1), .teal.opacity(0.1)], startPoint: .top, endPoint: .bottom))
    }

    private func change(by amount: Int) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.35)) { reminders += amount }
    }
}

#Preview {
    SubviewCardContainerDemo()
}
