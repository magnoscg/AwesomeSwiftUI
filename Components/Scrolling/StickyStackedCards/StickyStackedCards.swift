// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum StickyStackedCardsMath {
    /// How far down the card must move to stay pinned, 0 while it has not reached its pin.
    static func pinOffset(cardTop: CGFloat, pinY: CGFloat) -> CGFloat {
        max(pinY - cardTop, 0)
    }

    /// Where a card pins. The first few step down, so the edges of the pile stay visible.
    static func pinY(index: Int, top: CGFloat, peek: CGFloat, maxPeeking: Int) -> CGFloat {
        top + CGFloat(min(max(index, 0), max(maxPeeking, 0))) * max(peek, 0)
    }

    /// How much smaller a card gets as the next ones cover it.
    static func scale(pinOffset: CGFloat, cardHeight: CGFloat, spacing: CGFloat, step: CGFloat) -> CGFloat {
        let travel = cardHeight + max(spacing, 0)
        guard travel > 0 else { return 1 }
        return max(1 - min(pinOffset / travel, 4) * max(step, 0), 0.6)
    }
}

/// Cards that pile up at the top of the screen as the next card scrolls over them.
///
/// Place it inside a vertical `ScrollView`. With Reduce Motion on, the cards still pin in
/// place but do not shrink.
struct StickyStackedCards<Data: RandomAccessCollection, Card: View>: View where Data.Element: Identifiable {
    let data: Data
    var spacing: CGFloat = 20
    var top: CGFloat = 12
    var peek: CGFloat = 12
    var maxPeeking = 3
    @ViewBuilder var card: (Data.Element) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // `visualEffect` takes a `@Sendable` closure, so it works with local copies.
        let spacing = spacing
        let top = top
        let peek = peek
        let maxPeeking = maxPeeking
        let step: CGFloat = reduceMotion ? 0 : 0.05

        VStack(spacing: spacing) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                card(element)
                    .visualEffect { content, proxy in
                        let pin = StickyStackedCardsMath.pinOffset(
                            cardTop: proxy.frame(in: .scrollView).minY,
                            pinY: StickyStackedCardsMath.pinY(index: index, top: top, peek: peek, maxPeeking: maxPeeking)
                        )
                        let scale = StickyStackedCardsMath.scale(pinOffset: pin, cardHeight: proxy.size.height, spacing: spacing, step: step)
                        return content
                            .scaleEffect(scale, anchor: .top)
                            .offset(y: pin)
                    }
            }
        }
    }
}

// MARK: - Demo

struct StickyStackedCardsDemo: View {
    private struct Plan: Identifiable {
        let id: String
        let symbol: String
        let colors: [Color]
    }

    private let plans = [
        Plan(id: "Design", symbol: "paintpalette.fill", colors: [.pink, .orange]),
        Plan(id: "Build", symbol: "hammer.fill", colors: [.indigo, .blue]),
        Plan(id: "Test", symbol: "checkmark.seal.fill", colors: [.teal, .green]),
        Plan(id: "Ship", symbol: "paperplane.fill", colors: [.purple, .pink]),
        Plan(id: "Learn", symbol: "lightbulb.fill", colors: [.orange, .yellow]),
    ]

    @State private var position = ScrollPosition(y: 0)
    @State private var maxOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            StickyStackedCards(data: plans) { plan in
                card(plan)
            }
            .padding(.horizontal, 20)
            // Matches the default `top`, so the first card starts exactly at its pin.
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height, 0)
        } action: { _, newValue in
            maxOffset = newValue
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await autoScroll()
        }
    }

    private func card(_ plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: plan.symbol)
                .font(.largeTitle)
                .accessibilityHidden(true)

            Spacer(minLength: 24)

            Text(plan.id)
                .font(.largeTitle.bold())

            Text("Each step stacks on the last one as you scroll.")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .leading)
        .padding(24)
        .background(LinearGradient(colors: plan.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 32))
    }

    // Only the demo scrolls by itself: slowly down, then quickly back to the top.
    private func autoScroll() async {
        var time = 0.0
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            time = (time + 0.016).truncatingRemainder(dividingBy: 5)
            let fraction = time < 4 ? time / 4 : 5 - time
            position.scrollTo(y: maxOffset * fraction)
        }
    }
}

#Preview {
    StickyStackedCardsDemo()
}
