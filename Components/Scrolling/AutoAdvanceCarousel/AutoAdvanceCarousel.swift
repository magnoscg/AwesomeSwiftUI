// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A paged carousel that advances on a timer and pauses while the user is dragging it.
///
/// It stays still with Reduce Motion or VoiceOver on, and can always be swiped by hand.
struct AutoAdvanceCarousel<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var interval: TimeInterval = 3
    @ViewBuilder var content: (Item) -> Content

    @State private var currentID: Item.ID?
    @State private var isUserScrolling = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var currentIndex: Int? { items.firstIndex { $0.id == currentID } }

    private var schedule: AutoAdvanceCarouselSchedule<Item.ID> {
        AutoAdvanceCarouselSchedule(
            isRunning: !isUserScrolling && !reduceMotion && !voiceOverEnabled && items.count > 1,
            interval: max(interval, 0.5),
            itemIDs: items.map(\.id)
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
            .onScrollPhaseChange { _, phase in
                isUserScrolling = phase == .tracking || phase == .interacting || phase == .decelerating
            }

            pageIndicator
        }
        .task(id: schedule) {
            guard schedule.isRunning else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(schedule.interval))
                guard !Task.isCancelled else { return }
                move(to: AutoAdvanceCarouselMath.nextIndex(after: currentIndex, count: items.count))
            }
        }
    }

    private var pageIndicator: some View {
        let position = (currentIndex ?? 0) + 1

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) {
                ForEach(items.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == position - 1 ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                        .frame(width: index == position - 1 ? 22 : 7, height: 7)
                }
            }
            Text("\(position) / \(items.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .animation(reduceMotion ? nil : .snappy, value: position)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(position) of \(items.count)")
        .accessibilityAdjustableAction { direction in
            let index = currentIndex ?? 0
            let target = direction == .increment ? index + 1 : index - 1
            move(to: items.indices.contains(target) ? target : nil)
        }
    }

    private func move(to index: Int?) {
        guard let index, items.indices.contains(index) else { return }
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.5)) {
            currentID = items[index].id
        }
    }
}

/// The timer restarts when any of this changes. The ids matter because it holds on to the items.
private struct AutoAdvanceCarouselSchedule<ID: Hashable>: Equatable {
    let isRunning: Bool
    let interval: TimeInterval
    let itemIDs: [ID]
}

enum AutoAdvanceCarouselMath {
    /// The next page, wrapping to the first. Nil when there is nowhere to go.
    static func nextIndex(after current: Int?, count: Int) -> Int? {
        guard count > 1 else { return nil }
        return ((current ?? 0) + 1) % count
    }
}

// MARK: - Demo

struct AutoAdvanceCarouselDemo: View {
    private struct Slide: Identifiable {
        let id: String
        let symbol: String
        let colors: [Color]
    }

    private let slides = [
        Slide(id: "Summer Sale", symbol: "sun.max.fill", colors: [.orange, .pink]),
        Slide(id: "New Arrivals", symbol: "sparkles", colors: [.indigo, .purple]),
        Slide(id: "Free Shipping", symbol: "shippingbox.fill", colors: [.teal, .blue]),
        Slide(id: "Gift Cards", symbol: "gift.fill", colors: [.green, .mint]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Discover")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .padding(.horizontal, 20)

            AutoAdvanceCarousel(items: slides, interval: 1.5) { slide in
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: slide.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: slide.symbol)
                        .font(.system(.largeTitle))
                        .imageScale(.large)
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityHidden(true)
                    Text(slide.id)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(20)
                }
                .clipShape(.rect(cornerRadius: 26, style: .continuous))
                .padding(.horizontal, 20)
            }
            .frame(height: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AutoAdvanceCarouselDemo()
}
