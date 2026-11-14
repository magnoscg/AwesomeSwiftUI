// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum SwipeActionCardsLogic {
    /// The items left after one is removed, in their order.
    static func removing<Item: Identifiable>(_ id: Item.ID, from items: [Item]) -> [Item] {
        items.filter { $0.id != id }
    }

    /// The items with one moved to the front, which is what pinning does. An unknown one changes nothing.
    static func pinning<Item: Identifiable>(_ id: Item.ID, in items: [Item]) -> [Item] {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return items }
        var items = items
        items.insert(items.remove(at: index), at: 0)
        return items
    }
}

/// A column of cards with the system's swipe actions, outside a `List`: swipe a card to the
/// side to show its buttons, or all the way to run the first one.
///
/// Until iOS 27, `swipeActions` only worked on the rows of a `List`. `swipeActionsContainer`
/// brings it to any stack, so the cards can look however you want and keep the system's
/// gesture, haptics and VoiceOver actions.
@available(iOS 27, *)
struct SwipeActionCards<Item: Identifiable, Card: View, Actions: View>: View {
    let items: [Item]
    var spacing: CGFloat = 12
    @ViewBuilder var card: (Item) -> Card
    /// The buttons a card shows when it is swiped from its trailing edge, the first one outermost.
    @ViewBuilder var actions: (Item) -> Actions

    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(items) { item in
                    card(item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            actions(item)
                        }
                }
            }
            .padding(16)
            .swipeActionsContainer()
        }
    }
}

// MARK: - Demo

@available(iOS 27, *)
private struct SwipeActionCardsDemoTask: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
    let color: Color
}

@available(iOS 27, *)
struct SwipeActionCardsDemo: View {
    private static let allTasks = [
        SwipeActionCardsDemoTask(id: 0, title: "Water the plants", detail: "Balcony and kitchen", symbol: "leaf.fill", color: .green),
        SwipeActionCardsDemoTask(id: 1, title: "Call the dentist", detail: "Before five", symbol: "phone.fill", color: .blue),
        SwipeActionCardsDemoTask(id: 2, title: "Renew the bike pass", detail: "Ends on Friday", symbol: "bicycle", color: .orange),
        SwipeActionCardsDemoTask(id: 3, title: "Pick up the parcel", detail: "Locker 12", symbol: "shippingbox.fill", color: .purple),
    ]
    @State private var tasks = allTasks

    var body: some View {
        SwipeActionCards(items: tasks) { task in
            HStack(spacing: 14) {
                Image(systemName: task.symbol)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(task.color.gradient, in: .rect(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                    Text(task.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(.background, in: .rect(cornerRadius: 18))
            .accessibilityElement(children: .combine)
        } actions: { task in
            Button("Delete", systemImage: "trash", role: .destructive) {
                withAnimation { tasks = SwipeActionCardsLogic.removing(task.id, from: tasks) }
            }

            Button("Pin", systemImage: "pin.fill") {
                withAnimation { tasks = SwipeActionCardsLogic.pinning(task.id, in: tasks) }
            }
            .tint(.orange)
        }
        // Only for this demo: a way back once every card is gone.
        .overlay {
            if tasks.isEmpty {
                ContentUnavailableView {
                    Label("All done", systemImage: "checkmark.circle")
                } actions: {
                    Button("Start over") {
                        withAnimation { tasks = Self.allTasks }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

@available(iOS 27, *)
#Preview {
    SwipeActionCardsDemo()
}
