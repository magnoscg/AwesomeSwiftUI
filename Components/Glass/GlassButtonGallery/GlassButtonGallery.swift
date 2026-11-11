// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A tidy reference sheet of the system Liquid Glass button styles.
///
/// The styles draw their own press response, which the system adapts to Reduce Motion.
@available(iOS 26, *)
struct GlassButtonGallery: View {
    var tints: [(name: String, color: Color)] = [
        ("Blue", .blue), ("Pink", .pink), ("Orange", .orange), ("Green", .green),
    ]
    var onPress: (String) -> Void = { _ in }

    private let sizes: [(name: String, size: ControlSize)] = [
        ("Mini", .mini), ("Small", .small), ("Regular", .regular), ("Large", .large), ("Extra Large", .extraLarge),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            section("Sizes") {
                Grid(horizontalSpacing: 16, verticalSpacing: 10) {
                    ForEach(sizes, id: \.name) { item in
                        GridRow {
                            glassButton(item.name, label: "\(item.name) glass").controlSize(item.size)
                            prominentButton(item.name, label: "\(item.name) prominent").controlSize(item.size)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            section("Shapes") {
                HStack(spacing: 12) {
                    glassButton("Capsule", label: "Capsule").buttonBorderShape(.capsule)
                    prominentButton("Rounded", label: "Rounded").buttonBorderShape(.roundedRectangle(radius: 10))
                    iconButton("star.fill", label: "Circle", prominent: false)
                    iconButton("heart.fill", label: "Filled circle", prominent: true)
                }
                .frame(maxWidth: .infinity)
            }

            section("Tints") {
                HStack(spacing: 12) {
                    ForEach(tints, id: \.name) { tint in
                        iconButton("drop.fill", label: "\(tint.name) glass", prominent: false).tint(tint.color)
                        iconButton("drop.fill", label: "\(tint.name) prominent", prominent: true).tint(tint.color)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            content()
        }
    }

    private func glassButton(_ title: String, label: String) -> some View {
        Button(title) { onPress(label) }
            .buttonStyle(.glass)
            .accessibilityLabel(label)
    }

    private func prominentButton(_ title: String, label: String) -> some View {
        Button(title) { onPress(label) }
            .buttonStyle(.glassProminent)
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private func iconButton(_ systemImage: String, label: String, prominent: Bool) -> some View {
        let button = Button(label, systemImage: systemImage) { onPress(label) }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassButtonGalleryDemo: View {
    @State private var lastPressed = "Tap any button"

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint, .cyan, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(lastPressed)
                        .font(.title.bold())
                        .contentTransition(.opacity)
                        .animation(.easeInOut, value: lastPressed)

                    GlassButtonGallery { lastPressed = $0 }
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassButtonGalleryDemo()
}
