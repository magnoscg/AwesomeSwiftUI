// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A stack of cards the user can drag into a new order, without using `List`.
@available(iOS 27, *)
struct ReorderableCardList<Item: Identifiable & Sendable, Card: View>: View where Item.ID: Sendable {
    @Binding var items: [Item]
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    card(item)
                }
                .reorderable()
            }
            .padding()
            .reorderContainer(for: Item.self) { difference in
                let destination: Item.ID? = switch difference.destination.position {
                case .before(let id): id
                case .end: nil
                }
                items = CardReordering.moving(difference.sources, before: destination, in: items)
            }
        }
    }
}

@available(iOS 27, *)
enum CardReordering {
    /// Moves `sources` in front of `destination`, or to the end when it is nil.
    static func moving<Item: Identifiable>(
        _ sources: [Item.ID],
        before destination: Item.ID?,
        in items: [Item]
    ) -> [Item] {
        if let destination, sources.contains(destination) { return items }

        let moved = sources.compactMap { source in items.first { $0.id == source } }
        var remaining = items.filter { !sources.contains($0.id) }
        let index = remaining.firstIndex { $0.id == destination } ?? remaining.endIndex
        remaining.insert(contentsOf: moved, at: index)
        return remaining
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct ReorderableCardListDemo: View {
    private struct Step: Identifiable, Sendable {
        let id: String
        let systemImage: String
        let color: Color
    }

    @State private var steps = [
        Step(id: "Design", systemImage: "paintbrush.fill", color: .pink),
        Step(id: "Build", systemImage: "hammer.fill", color: .orange),
        Step(id: "Test", systemImage: "checkmark.seal.fill", color: .green),
        Step(id: "Ship", systemImage: "paperplane.fill", color: .blue),
    ]

    var body: some View {
        ReorderableCardList(items: $steps) { step in
            HStack(spacing: 16) {
                Image(systemName: step.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(step.color.gradient, in: .rect(cornerRadius: 14))
                    .accessibilityHidden(true)

                Text(step.id)
                    .font(.title3.bold())

                Spacer()

                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.background.secondary, in: .rect(cornerRadius: 20))
        }
    }
}

@available(iOS 27, *)
#Preview {
    ReorderableCardListDemo()
}
