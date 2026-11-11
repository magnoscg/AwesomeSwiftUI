// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Testing
@testable import Showcase

struct KanbanBoardTests {
    private func board() -> [KanbanBoardColumn] {
        [
            KanbanBoardColumn(id: "todo", title: "To do", cards: [
                KanbanBoardCard(id: "a", title: "A"),
                KanbanBoardCard(id: "b", title: "B"),
            ]),
            KanbanBoardColumn(id: "done", title: "Done", cards: [KanbanBoardCard(id: "c", title: "C")]),
        ]
    }

    @Test func moveAppendsToTheTargetColumn() {
        var columns = board()

        let didMove = KanbanBoardMove.apply(cardID: "a", toColumn: "done", in: &columns)

        #expect(didMove)
        #expect(columns[0].cards.map(\.id) == ["b"])
        #expect(columns[1].cards.map(\.id) == ["c", "a"])
    }

    @Test func droppingInTheSameColumnChangesNothing() {
        var columns = board()

        let didMove = KanbanBoardMove.apply(cardID: "a", toColumn: "todo", in: &columns)

        #expect(!didMove)
        #expect(columns == board())
    }

    @Test(arguments: [("missing", "done"), ("a", "missing")])
    func unknownIdsChangeNothing(cardID: String, columnID: String) {
        var columns = board()

        let didMove = KanbanBoardMove.apply(cardID: cardID, toColumn: columnID, in: &columns)

        #expect(!didMove)
        #expect(columns == board())
    }

    @Test func aColumnCanBeEmptied() {
        var columns = board()

        _ = KanbanBoardMove.apply(cardID: "c", toColumn: "todo", in: &columns)

        #expect(columns[1].cards.isEmpty)
    }
}
