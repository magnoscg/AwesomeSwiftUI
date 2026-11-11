// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A paging carousel that shows the edges of the neighbouring cards.
///
/// `peek` is how much of each neighbour stays visible. Give the cards a height.
/// With Reduce Motion on, side cards keep their size and only dim.
struct PeekCarousel<Item: Identifiable, Card: View>: View {
    let items: [Item]
    var peek: CGFloat = 28
    var spacing: CGFloat = 12
    @ViewBuilder var card: (Item) -> Card

    @State private var currentID: Item.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            carousel
            dots
        }
    }

    private var carousel: some View {
        let scalesSideCards = !reduceMotion

        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(items) { item in
                    card(item)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(scalesSideCards && !phase.isIdentity ? 0.92 : 1)
                                .opacity(phase.isIdentity ? 1 : 0.7)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $currentID)
        .safeAreaPadding(.horizontal, peek + spacing)
    }

    private var dots: some View {
        let activeID = currentID ?? items.first?.id

        return HStack(spacing: 8) {
            ForEach(items) { item in
                Circle()
                    .fill(item.id == activeID ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: 8, height: 8)
                    .scaleEffect(item.id == activeID ? 1.25 : 1)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: currentID)
        .accessibilityHidden(true)
    }
}

// MARK: - Demo

private struct DemoSlide: Identifiable {
    let id: String
    let symbol: String
    let colors: [Color]
}

struct PeekCarouselDemo: View {
    private let slides = [
        DemoSlide(id: "Sunrise", symbol: "sunrise.fill", colors: [.orange, .pink]),
        DemoSlide(id: "Forest", symbol: "tree.fill", colors: [.green, .teal]),
        DemoSlide(id: "Ocean", symbol: "water.waves", colors: [.cyan, .blue]),
        DemoSlide(id: "Night", symbol: "moon.stars.fill", colors: [.indigo, .purple]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Explore")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .padding(.horizontal, 40)

            PeekCarousel(items: slides) { slide in
                VStack(spacing: 14) {
                    Image(systemName: slide.symbol)
                        .font(.largeTitle)
                        .imageScale(.large)
                        .accessibilityHidden(true)
                    Text(slide.id)
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .background(LinearGradient(colors: slide.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 32))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.indigo.opacity(0.15), .pink.opacity(0.1)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    PeekCarouselDemo()
}
