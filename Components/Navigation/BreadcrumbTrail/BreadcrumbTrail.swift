// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct BreadcrumbTrailItem: Identifiable, Hashable {
    let id: String
    let title: String
}

/// A breadcrumb path. When it is wider than its space, the middle crumbs move into a menu.
///
/// If even the shortest form does not fit, as at the largest text sizes, the row scrolls.
struct BreadcrumbTrail: View {
    let items: [BreadcrumbTrailItem]
    let onSelect: (BreadcrumbTrailItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullRow

            ForEach(BreadcrumbTrailMath.collapsedTails(count: items.count), id: \.self) { tail in
                collapsedRow(tail: tail)
            }

            ScrollView(.horizontal) {
                fullRow
            }
            .scrollIndicators(.hidden)
        }
        .font(.subheadline)
        .animation(reduceMotion ? nil : .snappy, value: items)
    }

    private var fullRow: some View {
        HStack(spacing: 6) {
            crumbs(items[...])
        }
    }

    private func collapsedRow(tail: Int) -> some View {
        let parts = BreadcrumbTrailMath.split(items, tail: tail)

        return HStack(spacing: 6) {
            crumbs(parts.head)
            separator
            Menu {
                ForEach(parts.hidden) { item in
                    Button(item.title) { onSelect(item) }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.large)
            }
            .accessibilityLabel("More")
            separator
            crumbs(parts.tail)
        }
    }

    @ViewBuilder
    private func crumbs(_ slice: ArraySlice<BreadcrumbTrailItem>) -> some View {
        ForEach(slice) { item in
            if item != slice.first {
                separator
            }

            if item == items.last {
                Text(item.title)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize()
                    .accessibilityAddTraits(.isSelected)
            } else {
                Button(item.title) { onSelect(item) }
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private var separator: some View {
        Image(systemName: "chevron.compact.forward")
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

enum BreadcrumbTrailMath {
    /// How many trailing crumbs each collapsed form keeps, from the widest form to the narrowest.
    static func collapsedTails(count: Int) -> [Int] {
        guard count > 2 else { return [] }
        return Array((1...min(count - 2, 3)).reversed())
    }

    /// Keeps the first crumb and the last `tail` crumbs. The rest go in the menu.
    static func split<Element>(
        _ items: [Element],
        tail: Int
    ) -> (head: ArraySlice<Element>, hidden: ArraySlice<Element>, tail: ArraySlice<Element>) {
        guard let first = items.indices.first else { return ([], [], []) }
        let tailStart = max(items.count - max(tail, 0), first + 1)
        return (items[first...first], items[(first + 1)..<tailStart], items[tailStart...])
    }
}

// MARK: - Demo

struct BreadcrumbTrailDemo: View {
    private let tree = ["Home", "Projects", "Mobile", "Catalog", "Components", "Navigation"]

    @State private var depth = 2

    private var trail: [BreadcrumbTrailItem] {
        tree.prefix(depth).map { BreadcrumbTrailItem(id: $0, title: $0) }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal.opacity(0.35), .indigo.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                BreadcrumbTrail(items: trail) { item in
                    if let index = tree.firstIndex(of: item.title) {
                        depth = index + 1
                    }
                }

                Image(systemName: "folder.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundStyle(.teal.gradient)
                    .accessibilityHidden(true)

                Button("Open", systemImage: "arrow.forward") {
                    depth = depth < tree.count ? depth + 1 : 1
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: .rect(cornerRadius: 24))
            .padding(16)
        }
    }
}

#Preview {
    BreadcrumbTrailDemo()
}
