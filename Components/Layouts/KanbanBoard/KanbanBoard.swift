// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct KanbanBoardCard: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
}

struct KanbanBoardColumn: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var cards: [KanbanBoardCard]
}

enum KanbanBoardMove {
    /// Moves a card to the end of another column. Returns `false`, changing nothing,
    /// when the card or the column does not exist or the card is already there.
    static func apply(cardID: String, toColumn columnID: String, in columns: inout [KanbanBoardColumn]) -> Bool {
        guard let target = columns.firstIndex(where: { $0.id == columnID }),
              let source = columns.firstIndex(where: { $0.cards.contains { $0.id == cardID } }),
              source != target,
              let position = columns[source].cards.firstIndex(where: { $0.id == cardID })
        else { return false }

        let card = columns[source].cards.remove(at: position)
        columns[target].cards.append(card)
        return true
    }
}

/// Columns of cards that move from one column to another by dragging, with a
/// context menu and VoiceOver actions for anyone who cannot drag.
///
/// The drag payload is the card's `id` as plain text, so a copied file does not
/// need a custom type in Info.plist. Text that matches no card is ignored.
struct KanbanBoard: View {
    @Binding var columns: [KanbanBoardColumn]

    @ScaledMetric private var columnWidth: CGFloat
    @State private var targetedColumnID: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cardCornerRadius: CGFloat = 12

    init(columns: Binding<[KanbanBoardColumn]>, columnWidth: CGFloat = 220) {
        _columns = columns
        _columnWidth = ScaledMetric(wrappedValue: columnWidth, relativeTo: .body)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(columns) { column in
                    columnView(column)
                }
            }
            .padding()
        }
    }

    private func columnView(_ column: KanbanBoardColumn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(column.title).font(.headline)
                Spacer()
                Text("\(column.cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(column.cards.count) cards")
            }
            .accessibilityElement(children: .combine)

            ForEach(column.cards) { card in
                cardView(card, in: column)
            }

            if column.cards.isEmpty {
                Text("Drop cards here")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
        .padding(12)
        .frame(width: max(120, columnWidth), alignment: .topLeading)
        .background(
            targetedColumnID == column.id ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.quaternary.opacity(0.5)),
            in: .rect(cornerRadius: 18, style: .continuous)
        )
        .dropDestination(for: String.self) { cardIDs, _ in
            var didMove = false
            withAnimation(moveAnimation) {
                for cardID in cardIDs {
                    if KanbanBoardMove.apply(cardID: cardID, toColumn: column.id, in: &columns) { didMove = true }
                }
            }
            return didMove
        } isTargeted: { isTargeted in
            if isTargeted {
                targetedColumnID = column.id
            } else if targetedColumnID == column.id {
                targetedColumnID = nil
            }
        }
    }

    private func cardView(_ card: KanbanBoardCard, in column: KanbanBoardColumn) -> some View {
        cardLabel(card)
            .draggable(card.id) { cardLabel(card).frame(width: max(120, columnWidth) - 24) }
            .contextMenu { moveButtons(card, from: column) }
            .accessibilityActions { moveButtons(card, from: column) }
    }

    private func cardLabel(_ card: KanbanBoardCard) -> some View {
        Text(card.title)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: .rect(cornerRadius: cardCornerRadius, style: .continuous))
            .contentShape(.dragPreview, .rect(cornerRadius: cardCornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func moveButtons(_ card: KanbanBoardCard, from source: KanbanBoardColumn) -> some View {
        ForEach(columns.filter { $0.id != source.id }) { destination in
            Button("Move to \(destination.title)") {
                withAnimation(moveAnimation) {
                    _ = KanbanBoardMove.apply(cardID: card.id, toColumn: destination.id, in: &columns)
                }
            }
        }
    }

    private var moveAnimation: Animation? { reduceMotion ? nil : .snappy(duration: 0.3) }
}

// MARK: - Demo

struct KanbanBoardDemo: View {
    @State private var columns = [
        KanbanBoardColumn(id: "todo", title: "To do", cards: [
            KanbanBoardCard(id: "1", title: "Sketch the onboarding"),
            KanbanBoardCard(id: "2", title: "Write release notes"),
            KanbanBoardCard(id: "3", title: "Fix the login crash"),
        ]),
        KanbanBoardColumn(id: "doing", title: "Doing", cards: [
            KanbanBoardCard(id: "4", title: "Record the previews"),
        ]),
        KanbanBoardColumn(id: "done", title: "Done", cards: []),
    ]

    var body: some View {
        KanbanBoard(columns: $columns, columnWidth: 180)
            .tint(.indigo)
            .background(LinearGradient(colors: [.indigo.opacity(0.14), .teal.opacity(0.1)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    KanbanBoardDemo()
}
