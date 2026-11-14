// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A card that grows in place to fill its parent. Its icon, title and subtitle travel to their
/// new places with `matchedGeometryEffect`.
///
/// With Reduce Motion on, the card changes state without animating.
struct MatchedHeroCard<Detail: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var colors: [Color] = [.indigo, .purple]
    @ViewBuilder var detail: () -> Detail

    @State private var isExpanded = false
    @Namespace private var namespace
    @ScaledMetric(relativeTo: .largeTitle) private var collapsedHeight = 220.0
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 52.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.5, extraBounce: 0.08)
    }

    var body: some View {
        // One background for both states, so the card is never see-through while it changes,
        // and it clips the detail, so the text never runs over what is below the card.
        ZStack(alignment: .top) {
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .frame(maxWidth: .infinity, minHeight: collapsedHeight, maxHeight: isExpanded ? .infinity : collapsedHeight)
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(.white)
    }

    private var collapsedContent: some View {
        Button {
            withAnimation(animation) { isExpanded = true }
        } label: {
            header
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Expands the card")
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            detail()

            Spacer(minLength: 0)
        }
        .padding(24)
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(animation) { isExpanded = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(12)
                    .background(.white.opacity(0.2), in: .circle)
                    // A little bigger for a touch than it looks, up to the size of a touch target.
                    .padding(2)
                    .contentShape(.rect)
                    .padding(-2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .padding(16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .matchedGeometryEffect(id: "icon", in: namespace)
                .accessibilityHidden(true)

            Text(title)
                .font(.largeTitle.bold())
                .matchedGeometryEffect(id: "title", in: namespace)

            Text(subtitle)
                .font(.subheadline)
                .opacity(0.85)
                .matchedGeometryEffect(id: "subtitle", in: namespace)
        }
    }
}

// MARK: - Demo

struct MatchedHeroCardDemo: View {
    @ScaledMetric(relativeTo: .largeTitle) private var rowsOffset = 240.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.largeTitle.bold())

            ZStack(alignment: .top) {
                VStack(spacing: 12) {
                    row("Harbor walk", systemImage: "sailboat.fill")
                    row("Lunch at the market", systemImage: "fork.knife")
                    row("Sunset viewpoint", systemImage: "sun.horizon.fill")
                }
                .padding(.top, rowsOffset)

                MatchedHeroCard(
                    title: "Lisbon",
                    subtitle: "Three days by the river",
                    systemImage: "tram.fill",
                    colors: [.orange, .pink, .purple]
                ) {
                    Text("Tiled streets, yellow trams and the best custard tarts you will ever taste. The card grew from where it was and goes back there when you close it.")
                        .font(.body)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private func row(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}

#Preview {
    MatchedHeroCardDemo()
}
