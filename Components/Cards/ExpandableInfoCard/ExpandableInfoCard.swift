// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A card that expands to show more, with a chevron that turns.
///
/// With Reduce Motion on, the details fade in place.
struct ExpandableInfoCard<Details: View>: View {
    let title: LocalizedStringResource
    var subtitle: LocalizedStringResource?
    var systemImage = "info.circle.fill"
    var tint: Color = .blue
    @ViewBuilder var details: () -> Details

    @State private var isExpanded = false
    @ScaledMetric(relativeTo: .body) private var iconSize = 40.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                header
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(subtitle ?? "")

            if isExpanded {
                details()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .bottom], 16)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background, in: .rect(cornerRadius: 22))
        .clipShape(.rect(cornerRadius: 22))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(ExpandableInfoCardContrastingForeground(background: tint))
                .frame(width: iconSize, height: iconSize)
                .background(tint.gradient, in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.down")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .accessibilityHidden(true)
        }
        .padding(16)
        .contentShape(.rect)
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct ExpandableInfoCardContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct ExpandableInfoCardDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your order")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .padding(.bottom, 8)

                ExpandableInfoCard(title: "Shipping", subtitle: "Arrives on Thursday", systemImage: "shippingbox.fill", tint: .orange) {
                    Text("Your parcel left the warehouse this morning. You will get a message when the courier is one stop away.")
                }
                ExpandableInfoCard(title: "Warranty", subtitle: "Covered for two years", systemImage: "checkmark.shield.fill", tint: .green) {
                    Text("Repairs and replacements are free for two years. Keep your order number handy if you need to contact us.")
                }
                ExpandableInfoCard(title: "Returns", subtitle: "Free within 30 days", systemImage: "arrow.uturn.left.circle.fill", tint: .pink) {
                    Text("Print the label from your account, pack the item in its box and drop it at any collection point.")
                }
            }
            .padding(24)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.22), .teal.opacity(0.16)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    ExpandableInfoCardDemo()
}
