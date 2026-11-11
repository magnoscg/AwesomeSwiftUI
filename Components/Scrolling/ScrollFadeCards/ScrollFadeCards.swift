// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A vertical scroll of cards that shrink and fade as they reach its edges.
///
/// With Reduce Motion on, the cards fade without scaling.
struct ScrollFadeCards<Item: Identifiable, Card: View>: View {
    let items: [Item]
    var spacing: CGFloat = 16
    var minimumScale: Double = 0.84
    var minimumOpacity: Double = 0.2
    @ViewBuilder var card: (Item) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // `scrollTransition` takes a `@Sendable` closure, so it works with local copies.
        let lowestScale = reduceMotion ? 1 : minimumScale
        let lowestOpacity = minimumOpacity

        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(items) { item in
                    card(item)
                        .scrollTransition(.interactive.threshold(.visible(0.9))) { content, phase in
                            let distance = abs(phase.value)
                            return content
                                .scaleEffect(1 - distance * (1 - lowestScale))
                                .opacity(1 - distance * (1 - lowestOpacity))
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Demo

private struct ScrollFadeDemoCard: Identifiable {
    let id: Int
    let title: String
    let systemImage: String
    let colors: [Color]
}

struct ScrollFadeCardsDemo: View {
    private let cards: [ScrollFadeDemoCard] = {
        let themes: [(String, String, [Color])] = [
            ("Ocean", "water.waves", [.blue, .cyan]),
            ("Sunrise", "sunrise.fill", [.orange, .pink]),
            ("Meadow", "leaf.fill", [.green, .mint]),
            ("Dusk", "moon.haze.fill", [.purple, .indigo]),
        ]
        return (0..<16).map { index in
            let theme = themes[index % themes.count]
            return ScrollFadeDemoCard(id: index, title: theme.0, systemImage: theme.1, colors: theme.2)
        }
    }()

    @ScaledMetric(relativeTo: .title) private var cardHeight = 170.0

    var body: some View {
        ScrollFadeCards(items: cards) { card in
            HStack(spacing: 16) {
                Image(systemName: card.systemImage)
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                Text(card.title)
                    .font(.system(.title, design: .rounded, weight: .bold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, minHeight: cardHeight)
            .background(
                LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 26)
            )
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    ScrollFadeCardsDemo()
}
