// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A horizontal carousel whose card artwork moves slower than the card, for a parallax effect.
///
/// With Reduce Motion on, the artwork stays still inside the card.
struct ParallaxCardsRow<Item: Identifiable, Artwork: View, Overlay: View>: View {
    let items: [Item]
    var height: CGFloat = 460
    var strength: CGFloat = 70
    @ViewBuilder var artwork: (Item) -> Artwork
    @ViewBuilder var overlay: (Item) -> Overlay

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // `visualEffect` takes a `@Sendable` closure, so it works with a local copy.
        let shift = reduceMotion ? 0 : strength

        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(items) { item in
                    artwork(item)
                        .padding(.horizontal, -strength)
                        .visualEffect { content, proxy in
                            content.offset(x: parallaxOffset(in: proxy, shift: shift))
                        }
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.85 }
                        .frame(height: height)
                        .clipShape(.rect(cornerRadius: 30))
                        .overlay(alignment: .bottomLeading) { overlay(item) }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 40, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}

// Moves against the scroll in proportion to the card's distance from the middle of the
// scroll view. It is clamped so the oversized artwork never exposes its edges.
private nonisolated func parallaxOffset(in proxy: GeometryProxy, shift: CGFloat) -> CGFloat {
    // `bounds(of:)` is converted to the card's own coordinate space.
    guard let bounds = proxy.bounds(of: .scrollView(axis: .horizontal)), bounds.width > 0 else { return 0 }
    let distance = (proxy.size.width / 2 - bounds.midX) / bounds.width
    return -min(max(distance, -1), 1) * shift
}

// MARK: - Demo

private struct ParallaxDemoCard: Identifiable {
    let id: String
    let systemImage: String
    let colors: [Color]
}

struct ParallaxCardsRowDemo: View {
    private let cards = [
        ParallaxDemoCard(id: "Alps", systemImage: "mountain.2.fill", colors: [.blue, .indigo]),
        ParallaxDemoCard(id: "Sahara", systemImage: "sun.max.fill", colors: [.orange, .red]),
        ParallaxDemoCard(id: "Amazon", systemImage: "leaf.fill", colors: [.green, .teal]),
        ParallaxDemoCard(id: "Arctic", systemImage: "snowflake", colors: [.cyan, .purple]),
        ParallaxDemoCard(id: "Pacific", systemImage: "water.waves", colors: [.teal, .blue]),
    ]

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 180.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ParallaxCardsRow(items: cards) { card in
                LinearGradient(colors: card.colors, startPoint: .leading, endPoint: .trailing)
                    .overlay {
                        Image(systemName: card.systemImage)
                            .font(.system(size: symbolSize))
                            .foregroundStyle(.white.opacity(0.35))
                            .accessibilityHidden(true)
                    }
            } overlay: { card in
                Text(card.id)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(28)
            }
        }
    }
}

#Preview {
    ParallaxCardsRowDemo()
}
