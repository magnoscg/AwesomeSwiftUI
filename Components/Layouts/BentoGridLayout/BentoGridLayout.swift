// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct BentoGridLayoutSpan: Equatable, Sendable {
    var columns = 1
    var rows = 1
}

enum BentoGridLayoutMath {
    /// Packs each tile, in order, into the first free slot, reading the grid top to bottom and left to right.
    static func frames(
        spans: [BentoGridLayoutSpan],
        columns: Int,
        width: CGFloat,
        rowHeight: CGFloat,
        spacing: CGFloat
    ) -> [CGRect] {
        guard columns > 0 else { return [] }
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var taken = Set<SIMD2<Int>>()

        func cells(column: Int, row: Int, span: BentoGridLayoutSpan) -> [SIMD2<Int>] {
            (column..<column + span.columns).flatMap { x in
                (row..<row + span.rows).map { y in SIMD2(x, y) }
            }
        }

        func firstFreeSlot(for span: BentoGridLayoutSpan) -> (column: Int, row: Int) {
            var row = 0
            while true {
                for column in 0...(columns - span.columns) where taken.isDisjoint(with: cells(column: column, row: row, span: span)) {
                    return (column, row)
                }
                row += 1
            }
        }

        return spans.map { requested in
            let span = BentoGridLayoutSpan(columns: min(max(requested.columns, 1), columns), rows: max(requested.rows, 1))
            let slot = firstFreeSlot(for: span)
            taken.formUnion(cells(column: slot.column, row: slot.row, span: span))
            return CGRect(
                x: CGFloat(slot.column) * (columnWidth + spacing),
                y: CGFloat(slot.row) * (rowHeight + spacing),
                width: CGFloat(span.columns) * columnWidth + CGFloat(span.columns - 1) * spacing,
                height: CGFloat(span.rows) * rowHeight + CGFloat(span.rows - 1) * spacing
            )
        }
    }
}

private struct BentoGridLayoutSpanKey: LayoutValueKey {
    static let defaultValue = BentoGridLayoutSpan()
}

extension View {
    /// How many columns and rows this tile takes inside a `BentoGridLayout`.
    func bentoGridSpan(columns: Int = 1, rows: Int = 1) -> some View {
        layoutValue(key: BentoGridLayoutSpanKey.self, value: BentoGridLayoutSpan(columns: columns, rows: rows))
    }
}

/// A grid that packs tiles of varied spans, leaving as few holes as it can.
struct BentoGridLayout: Layout {
    var columns = 4
    var rowHeight: CGFloat = 110
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? CGFloat(columns) * (rowHeight + spacing) - spacing
        let height = frames(for: subviews, width: width).map(\.maxY).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(for: subviews, width: bounds.width)) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func frames(for subviews: Subviews, width: CGFloat) -> [CGRect] {
        BentoGridLayoutMath.frames(
            spans: subviews.map { $0[BentoGridLayoutSpanKey.self] },
            columns: columns,
            width: width,
            rowHeight: rowHeight,
            spacing: spacing
        )
    }
}

// MARK: - Demo

private struct DemoTile: Identifiable {
    let id: String
    let symbol: String
    let colors: [Color]
}

struct BentoGridLayoutDemo: View {
    private let tiles = [
        DemoTile(id: "Sleep", symbol: "moon.fill", colors: [.indigo, .purple]),
        DemoTile(id: "Steps", symbol: "figure.walk", colors: [.green, .teal]),
        DemoTile(id: "Heart", symbol: "heart.fill", colors: [.pink, .red]),
        DemoTile(id: "Water", symbol: "drop.fill", colors: [.cyan, .blue]),
        DemoTile(id: "Sun", symbol: "sun.max.fill", colors: [.yellow, .orange]),
        DemoTile(id: "Focus", symbol: "brain.head.profile", colors: [.purple, .pink]),
        DemoTile(id: "Rest", symbol: "bed.double.fill", colors: [.teal, .indigo]),
    ]

    private let arrangements: [[(columns: Int, rows: Int)]] = [
        [(2, 2), (2, 1), (1, 1), (1, 1), (4, 1), (2, 2), (2, 2)],
        [(4, 1), (1, 2), (3, 2), (2, 1), (2, 1), (2, 1), (2, 1)],
        [(1, 2), (3, 1), (2, 1), (1, 1), (2, 2), (2, 1), (2, 1)],
    ]

    @State private var arrangement = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Text("Today")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            BentoGridLayout(rowHeight: 104) {
                ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                    let span = arrangements[arrangement][index]
                    tileView(tile)
                        .bentoGridSpan(columns: span.columns, rows: span.rows)
                }
            }

            Spacer(minLength: 0)

            Button("Shuffle", systemImage: "shuffle") {
                withAnimation(reduceMotion ? nil : .bouncy(duration: 0.55)) {
                    arrangement = (arrangement + 1) % arrangements.count
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .background(LinearGradient(colors: [.indigo.opacity(0.1), .pink.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }

    private func tileView(_ tile: DemoTile) -> some View {
        VStack(alignment: .leading) {
            Image(systemName: tile.symbol)
                .font(.title2)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            Text(tile.id)
                .font(.system(.headline, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LinearGradient(colors: tile.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 22))
    }
}

#Preview {
    BentoGridLayoutDemo()
}
