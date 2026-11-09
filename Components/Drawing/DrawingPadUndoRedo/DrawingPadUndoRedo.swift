// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct DrawingPadUndoRedoStroke: Equatable {
    var points: [CGPoint]
}

/// The strokes on the pad plus the ones that can be brought back.
struct DrawingPadUndoRedoHistory: Equatable {
    private(set) var strokes: [DrawingPadUndoRedoStroke]
    private(set) var undone: [DrawingPadUndoRedoStroke] = []

    init(strokes: [DrawingPadUndoRedoStroke] = []) {
        self.strokes = strokes
    }

    var canUndo: Bool { !strokes.isEmpty }
    var canRedo: Bool { !undone.isEmpty }

    /// A new stroke starts a new future, so what was undone can no longer be redone.
    mutating func add(_ stroke: DrawingPadUndoRedoStroke) {
        guard !stroke.points.isEmpty else { return }
        strokes.append(stroke)
        undone.removeAll()
    }

    mutating func undo() {
        guard let stroke = strokes.popLast() else { return }
        undone.append(stroke)
    }

    mutating func redo() {
        guard let stroke = undone.popLast() else { return }
        strokes.append(stroke)
    }

    mutating func clear() {
        strokes.removeAll()
        undone.removeAll()
    }
}

/// A drawing pad that keeps its strokes in a history, with undo, redo and clear buttons.
///
/// A stroke the system interrupts is kept up to the point where it stopped.
struct DrawingPadUndoRedo: View {
    @Binding var history: DrawingPadUndoRedoHistory
    var color: Color = .primary
    var lineWidth: CGFloat = 6

    @State private var currentPoints: [CGPoint] = []
    @GestureState private var isDrawing = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 14) {
            pad
            toolbar
        }
    }

    private var pad: some View {
        Canvas { context, _ in
            let shading = GraphicsContext.Shading.color(color)
            let width = max(lineWidth, 0.5)
            for stroke in history.strokes {
                Self.draw(stroke.points, width: width, shading: shading, in: context)
            }
            Self.draw(currentPoints, width: width, shading: shading, in: context)
        }
        .clipped()
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDrawing) { _, state, _ in state = true }
                .onChanged { currentPoints.append($0.location) }
        )
        .onChange(of: isDrawing) { _, drawing in
            guard !drawing else { return }
            history.add(DrawingPadUndoRedoStroke(points: currentPoints))
            currentPoints = []
        }
        .accessibilityElement()
        .accessibilityLabel("Drawing pad")
        .accessibilityValue("\(history.strokes.count) strokes")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    @ViewBuilder
    private var toolbar: some View {
        if dynamicTypeSize.isAccessibilitySize {
            toolbarButtons.labelStyle(.iconOnly)
        } else {
            toolbarButtons.labelStyle(.titleAndIcon)
        }
    }

    private var toolbarButtons: some View {
        HStack(spacing: 10) {
            Button("Undo", systemImage: "arrow.uturn.backward") { history.undo() }
                .disabled(!history.canUndo)

            Button("Redo", systemImage: "arrow.uturn.forward") { history.redo() }
                .disabled(!history.canRedo)

            Spacer(minLength: 0)

            Button("Clear", systemImage: "trash", role: .destructive) { history.clear() }
                .disabled(!history.canUndo && !history.canRedo)
        }
        .buttonStyle(.bordered)
    }

    private static func draw(_ points: [CGPoint], width: CGFloat, shading: GraphicsContext.Shading, in context: GraphicsContext) {
        guard let first = points.first else { return }

        guard points.count > 1 else {
            let dot = CGRect(x: first.x - width / 2, y: first.y - width / 2, width: width, height: width)
            context.fill(Path(ellipseIn: dot), with: shading)
            return
        }

        var path = Path()
        path.move(to: first)
        for index in 1..<points.count {
            let control = points[index]
            let end = index + 1 < points.count
                ? CGPoint(x: (control.x + points[index + 1].x) / 2, y: (control.y + points[index + 1].y) / 2)
                : control
            path.addQuadCurve(to: end, control: control)
        }
        context.stroke(path, with: shading, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Demo

struct DrawingPadUndoRedoDemo: View {
    @State private var history = DrawingPadUndoRedoHistory(
        strokes: [90.0, 200.0, 310.0].enumerated().map { index, height in
            DrawingPadUndoRedoStroke(
                points: stride(from: 24.0, through: 330.0, by: 6.0).map { x in
                    CGPoint(x: x, y: height + sin(x / 32 + Double(index) * 1.4) * 42)
                }
            )
        }
    )

    var body: some View {
        VStack(spacing: 16) {
            Text("Sketch")
                .font(.system(.title, design: .rounded, weight: .bold))

            DrawingPadUndoRedo(history: $history, color: .teal)
                .padding(14)
                .background(.regularMaterial, in: .rect(cornerRadius: 28))
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.teal.opacity(0.22), .indigo.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    DrawingPadUndoRedoDemo()
}
