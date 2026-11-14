// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import CoreGraphics
import Testing
@testable import Showcase

struct DrawingPadUndoRedoTests {
    private let first = DrawingPadUndoRedoStroke(points: [CGPoint(x: 1, y: 1)])
    private let second = DrawingPadUndoRedoStroke(points: [CGPoint(x: 2, y: 2)])

    @Test func undoRemovesTheLastStroke() {
        var history = DrawingPadUndoRedoHistory(strokes: [first, second])

        history.undo()

        #expect(history.strokes == [first])
        #expect(history.canRedo)
    }

    @Test func redoRestoresInReverseOrder() {
        var history = DrawingPadUndoRedoHistory(strokes: [first, second])
        history.undo()
        history.undo()

        history.redo()

        #expect(history.strokes == [first])
        #expect(history.undone == [second])
    }

    @Test func aNewStrokeDiscardsTheRedoStack() {
        var history = DrawingPadUndoRedoHistory(strokes: [first])
        history.undo()

        history.add(second)

        #expect(history.strokes == [second])
        #expect(!history.canRedo)
    }

    @Test func anEmptyStrokeChangesNothing() {
        var history = DrawingPadUndoRedoHistory(strokes: [first])
        history.undo()

        history.add(DrawingPadUndoRedoStroke(points: []))

        #expect(history.strokes.isEmpty)
        #expect(history.canRedo)
    }

    @Test func undoAndRedoOnAnEmptyHistoryDoNothing() {
        var history = DrawingPadUndoRedoHistory()

        history.undo()
        history.redo()

        #expect(history == DrawingPadUndoRedoHistory())
    }

    @Test func clearEmptiesBothStacks() {
        var history = DrawingPadUndoRedoHistory(strokes: [first, second])
        history.undo()

        history.clear()

        #expect(!history.canUndo)
        #expect(!history.canRedo)
    }
}
