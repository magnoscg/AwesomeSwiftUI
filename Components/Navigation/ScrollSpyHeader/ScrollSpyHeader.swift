// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A bar of chips that follows a scroll view: the chip of the section at the top is highlighted,
/// and tapping a chip jumps to its section.
///
/// With Reduce Motion on, jumps and the highlight happen without animation.
struct ScrollSpyHeader<Element: Identifiable, Content: View>: View {
    let sections: [Element]
    let title: (Element) -> String
    @ViewBuilder let content: (Element) -> Content

    @State private var activeID: Element.ID?
    @State private var visibleIDs: Set<Element.ID> = []
    @State private var isAtEnd = false
    @State private var jumpTarget: Element.ID?
    @Namespace private var chipNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A jump in progress wins, so the highlight does not flicker across the sections it passes.
    private var highlightedID: Element.ID? {
        jumpTarget ?? activeID ?? sections.first?.id
    }

    var body: some View {
        ScrollViewReader { contentProxy in
            VStack(spacing: 0) {
                chipBar(contentProxy: contentProxy)
                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        ForEach(sections) { section in
                            content(section)
                                .id(section.id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding()
                }
                .onScrollTargetVisibilityChange(idType: Element.ID.self, threshold: 0.01) { ids in
                    visibleIDs = Set(ids)
                    refreshActiveID()
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    ScrollSpyHeaderMath.isAtEnd(
                        visibleMaxY: geometry.visibleRect.maxY,
                        contentHeight: geometry.contentSize.height,
                        containerHeight: geometry.containerSize.height
                    )
                } action: { _, newValue in
                    isAtEnd = newValue
                    refreshActiveID()
                }
            }
        }
    }

    private func chipBar(contentProxy: ScrollViewProxy) -> some View {
        ScrollViewReader { chipProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(sections) { section in
                        chip(for: section, contentProxy: contentProxy)
                            .id(section.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .scrollIndicators(.hidden)
            .onChange(of: highlightedID) { _, newValue in
                guard let newValue else { return }
                withAnimation(reduceMotion ? nil : .smooth) {
                    chipProxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func chip(for section: Element, contentProxy: ScrollViewProxy) -> some View {
        let isActive = section.id == highlightedID

        return Button {
            jump(to: section.id, contentProxy: contentProxy)
        } label: {
            Text(title(section))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isActive {
                        Capsule()
                            .fill(.tint)
                            .matchedGeometryEffect(id: "active", in: chipNamespace)
                    } else {
                        Capsule()
                            .fill(.quaternary)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .animation(reduceMotion ? nil : .snappy, value: highlightedID)
    }

    private func jump(to id: Element.ID, contentProxy: ScrollViewProxy) {
        jumpTarget = id
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.45), completionCriteria: .logicallyComplete) {
            contentProxy.scrollTo(id, anchor: .top)
        } completion: {
            jumpTarget = nil
            refreshActiveID()
        }
    }

    private func refreshActiveID() {
        activeID = ScrollSpyHeaderMath.activeID(
            order: sections.map(\.id),
            visible: visibleIDs,
            isAtEnd: isAtEnd,
            previous: activeID
        )
    }
}

enum ScrollSpyHeaderMath {
    /// The first section still on screen, or the last one once the end is reached,
    /// because a short final section can never scroll to the top.
    static func activeID<ID: Hashable>(order: [ID], visible: Set<ID>, isAtEnd: Bool, previous: ID?) -> ID? {
        if isAtEnd, let last = order.last { return last }
        return order.first(where: visible.contains) ?? previous
    }

    static func isAtEnd(visibleMaxY: CGFloat, contentHeight: CGFloat, containerHeight: CGFloat) -> Bool {
        contentHeight > containerHeight && visibleMaxY >= contentHeight - 1
    }
}

// MARK: - Demo

private struct ScrollSpyHeaderDemoSection: Identifiable {
    var id: String { chip }
    let chip: String
    let heading: String
    let color: Color
    let dishes: [String]
}

struct ScrollSpyHeaderDemo: View {
    private let sections = [
        ScrollSpyHeaderDemoSection(chip: "Starters", heading: "To begin", color: .green, dishes: ["Garden salad", "Tomato bruschetta", "Crispy calamari", "Grilled halloumi", "Olive plate"]),
        ScrollSpyHeaderDemoSection(chip: "Mains", heading: "From the kitchen", color: .orange, dishes: ["Wood-fired pizza", "Pumpkin risotto", "Roast chicken", "Seared tuna", "Mushroom pasta"]),
        ScrollSpyHeaderDemoSection(chip: "Sides", heading: "On the side", color: .teal, dishes: ["Rosemary fries", "Charred greens", "Warm flatbread", "Slaw"]),
        ScrollSpyHeaderDemoSection(chip: "Desserts", heading: "Something sweet", color: .pink, dishes: ["Lemon tart", "Dark chocolate mousse", "Vanilla panna cotta", "Fig ice cream"]),
        ScrollSpyHeaderDemoSection(chip: "Drinks", heading: "To sip", color: .indigo, dishes: ["Sparkling water", "Iced tea", "Espresso"]),
    ]

    var body: some View {
        ScrollSpyHeader(sections: sections, title: \.chip) { section in
            VStack(alignment: .leading, spacing: 12) {
                Text(section.heading)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                ForEach(section.dishes, id: \.self) { dish in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(section.color.gradient)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(.white)
                            }
                            .accessibilityHidden(true)

                        Text(dish)
                            .font(.body.weight(.medium))
                    }
                }
            }
        }
        .tint(.indigo)
    }
}

#Preview {
    ScrollSpyHeaderDemo()
}
