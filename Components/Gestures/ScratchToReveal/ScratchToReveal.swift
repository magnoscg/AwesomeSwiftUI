// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Tracks how much of a scratch card is uncovered, on a coarse grid of cells.
struct ScratchToRevealCoverage: Equatable {
    let columns: Int
    let rows: Int
    private(set) var cleared: Set<Int> = []

    init(columns: Int = 24, rows: Int = 24) {
        self.columns = min(max(columns, 1), 256)
        self.rows = min(max(rows, 1), 256)
    }

    var fraction: Double {
        Double(cleared.count) / Double(columns * rows)
    }

    /// Clears the cells under a brush line. The points are in a view of the given size.
    mutating func scratch(from start: CGPoint, to end: CGPoint, brushWidth: CGFloat, in size: CGSize) {
        guard size.width > 0, size.height > 0, brushWidth > 0 else { return }
        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance.isFinite else { return }

        let steps = Int(min(distance / (brushWidth / 2), 256)) + 1
        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: start.x + (end.x - start.x) * progress, y: start.y + (end.y - start.y) * progress)
            clear(around: point, radius: brushWidth / 2, in: size)
        }
    }

    private mutating func clear(around point: CGPoint, radius: CGFloat, in size: CGSize) {
        let cell = CGSize(width: size.width / CGFloat(columns), height: size.height / CGFloat(rows))
        let reach = max(radius, hypot(cell.width, cell.height) / 2)

        for row in index((point.y - reach) / cell.height, limit: rows)...index((point.y + reach) / cell.height, limit: rows) {
            for column in index((point.x - reach) / cell.width, limit: columns)...index((point.x + reach) / cell.width, limit: columns) {
                let center = CGPoint(x: (CGFloat(column) + 0.5) * cell.width, y: (CGFloat(row) + 0.5) * cell.height)
                if hypot(center.x - point.x, center.y - point.y) <= reach {
                    cleared.insert(row * columns + column)
                }
            }
        }
    }

    private func index(_ value: CGFloat, limit: Int) -> Int {
        Int(min(max(value.rounded(.down), 0), CGFloat(limit - 1)))
    }
}

/// A cover you scratch with a finger to uncover the content beneath it.
///
/// The rest falls away once `revealThreshold` of the cover is gone. To start over, change the
/// view's `id`. VoiceOver users double tap to reveal, and Reduce Motion removes the final fade.
struct ScratchToReveal<Content: View, Cover: View>: View {
    var brushWidth: CGFloat = 44
    var revealThreshold: Double = 0.6
    var onReveal: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var cover: () -> Cover

    @State private var strokes: [[CGPoint]] = []
    @State private var strokeStart: CGPoint?
    @State private var coverage = ScratchToRevealCoverage()
    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var brush: CGFloat { max(brushWidth, 1) }

    var body: some View {
        content()
            .accessibilityHidden(!isRevealed)
            .overlay {
                if !isRevealed {
                    GeometryReader { geometry in
                        cover()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .mask { scratchMask }
                            .contentShape(.rect)
                            .gesture(scratch(in: geometry.size))
                    }
                    .transition(.opacity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Scratch card")
                    .accessibilityHint("Double tap to reveal what is underneath")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { reveal() }
                }
            }
    }

    private var scratchMask: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            context.blendMode = .destinationOut
            let style = StrokeStyle(lineWidth: brush, lineCap: .round, lineJoin: .round)
            for stroke in strokes {
                var path = Path()
                path.addLines(stroke)
                context.stroke(path, with: .color(.black), style: style)
            }
        }
    }

    private func scratch(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if strokeStart != value.startLocation {
                    strokeStart = value.startLocation
                    strokes.append([value.startLocation])
                }
                guard let last = strokes.indices.last, !isRevealed else { return }

                let previous = strokes[last].last ?? value.location
                strokes[last].append(value.location)
                coverage.scratch(from: previous, to: value.location, brushWidth: brush, in: size)
                if coverage.fraction >= min(max(revealThreshold, 0.01), 1) { reveal() }
            }
            .onEnded { _ in strokeStart = nil }
    }

    private func reveal() {
        guard !isRevealed else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { isRevealed = true }
        onReveal?()
    }
}

// MARK: - Demo

struct ScratchToRevealDemo: View {
    @State private var round = 0
    @State private var didWin = false

    var body: some View {
        VStack(spacing: 24) {
            Text(didWin ? "You found it!" : "Scratch the card")
                .font(.title.bold())

            ScratchToReveal(brushWidth: 56, revealThreshold: 0.7, onReveal: { didWin = true }) {
                prize
            } cover: {
                cover
            }
            .id(round)
            .frame(height: 240)
            .clipShape(.rect(cornerRadius: 28))
            .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
            .padding(.horizontal, 28)

            Button("Try again", systemImage: "arrow.counterclockwise") {
                round += 1
                didWin = false
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prize: some View {
        VStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text("50% off")
                .font(.largeTitle.bold())
            Text("on your next order")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        .accessibilityElement(children: .combine)
    }

    private var cover: some View {
        LinearGradient(
            colors: [Color(white: 0.82), Color(white: 0.62), Color(white: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Label("Scratch here", systemImage: "hand.draw.fill")
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ScratchToRevealDemo()
}
