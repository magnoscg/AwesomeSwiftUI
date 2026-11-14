// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct PricingTierCardsTier: Identifiable, Hashable {
    let name: String
    var price: String
    var period: String
    var features: [String]
    var isRecommended = false

    var id: String { name }
}

/// Horizontal pricing cards that snap into place, with the recommended plan highlighted and larger.
///
/// It opens centered on the recommended plan. Place it in a vertical `ScrollView`
/// so tall cards stay reachable at the largest text sizes.
struct PricingTierCards: View {
    let tiers: [PricingTierCardsTier]
    @Binding var selection: PricingTierCardsTier.ID?
    var tint: Color = .indigo

    @State private var centeredID: PricingTierCardsTier.ID?
    @State private var containerWidth: CGFloat = 0

    private var cardWidth: CGFloat {
        min(max(containerWidth - 72, 220), 300)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(tiers) { tier in
                    card(for: tier)
                        .frame(width: cardWidth)
                        .scaleEffect(tier.isRecommended ? 1 : 0.92)
                        .zIndex(tier.isRecommended ? 1 : 0)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .scrollTargetLayout()
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        // The shadow of the recommended plan reaches past the row.
        .scrollClipDisabled()
        .contentMargins(.horizontal, max((containerWidth - cardWidth) / 2, 16), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $centeredID)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .task(id: containerWidth) {
            guard containerWidth > 0, centeredID == nil else { return }
            centeredID = (tiers.first(where: \.isRecommended) ?? tiers.first)?.id
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func card(for tier: PricingTierCardsTier) -> some View {
        let isSelected = selection == tier.id
        let secondary = tier.isRecommended ? Color.white.opacity(0.85) : Color.secondary

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(tier.name)
                    .font(.title3.bold())

                Spacer(minLength: 8)

                if tier.isRecommended {
                    Text("Popular")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.22), in: .capsule)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.price)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text(tier.period)
                    .font(.subheadline)
                    .foregroundStyle(secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(tier.features.enumerated()), id: \.offset) { _, feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                }
            }

            Spacer(minLength: 0)

            Button {
                selection = tier.id
            } label: {
                Text(isSelected ? "\(tier.name) selected" : "Choose \(tier.name)")
                    .font(.headline)
                    .foregroundStyle(tier.isRecommended ? tint : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(tier.isRecommended ? Color.white : tint, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .foregroundStyle(tier.isRecommended ? Color.white : Color.primary)
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            tier.isRecommended ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(.regularMaterial),
            in: .rect(cornerRadius: 28)
        )
        .shadow(color: tier.isRecommended ? tint.opacity(0.4) : .clear, radius: 18, y: 10)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Demo

struct PricingTierCardsDemo: View {
    @State private var selection: PricingTierCardsTier.ID?

    private let tiers = [
        PricingTierCardsTier(name: "Free", price: "$0", period: "forever", features: ["3 projects", "Community help"]),
        PricingTierCardsTier(
            name: "Pro",
            price: "$12",
            period: "per month",
            features: ["Unlimited projects", "Sync across devices", "Priority support"],
            isRecommended: true
        ),
        PricingTierCardsTier(name: "Team", price: "$29", period: "per seat", features: ["Everything in Pro", "Shared spaces", "Admin tools"]),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Pick your plan")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Swipe to compare")
                    .font(.body)
                    .foregroundStyle(.secondary)

                PricingTierCards(tiers: tiers, selection: $selection)
            }
            .padding(.vertical, 24)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .background(
            LinearGradient(colors: [.indigo.opacity(0.2), .cyan.opacity(0.14)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    PricingTierCardsDemo()
}
