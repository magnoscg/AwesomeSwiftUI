// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// The placement math, with no views, so it can be tested.
nonisolated enum MasonryLayoutMath {
    struct Placement: Equatable {
        let column: Int
        let y: CGFloat
    }

    static func columnWidth(totalWidth: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        guard columns > 0, totalWidth.isFinite else { return 0 }
        return max(0, (totalWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns))
    }

    /// Puts each item in the shortest column so far, the leftmost one on a tie.
    /// Returns one placement per height, and the height of the tallest column.
    static func place(heights: [CGFloat], columns: Int, spacing: CGFloat) -> (placements: [Placement], totalHeight: CGFloat) {
        var tops = Array(repeating: CGFloat.zero, count: max(1, columns))
        var placements: [Placement] = []

        for height in heights {
            let column = tops.indices.min { tops[$0] < tops[$1] } ?? 0
            placements.append(Placement(column: column, y: tops[column]))
            tops[column] += max(0, height) + spacing
        }

        return (placements, heights.isEmpty ? 0 : max(0, (tops.max() ?? spacing) - spacing))
    }
}

/// A layout that places items of different heights into the shortest of several
/// columns, like a Pinterest board. Put it inside a `ScrollView` when it can grow.
struct MasonryLayout: Layout {
    var columns = 2
    var spacing: CGFloat = 12

    /// More columns than this makes no sense on any screen.
    private var columnCount: Int { min(max(1, columns), 64) }
    private var gap: CGFloat { spacing.isFinite ? max(0, spacing) : 0 }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = totalWidth(for: proposal, subviews: subviews)
        let columnWidth = MasonryLayoutMath.columnWidth(totalWidth: width, columns: columnCount, spacing: gap)
        let result = MasonryLayoutMath.place(heights: heights(of: subviews, columnWidth: columnWidth), columns: columnCount, spacing: gap)
        return CGSize(width: width, height: result.totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let columnWidth = MasonryLayoutMath.columnWidth(totalWidth: bounds.width, columns: columnCount, spacing: gap)
        let result = MasonryLayoutMath.place(heights: heights(of: subviews, columnWidth: columnWidth), columns: columnCount, spacing: gap)

        for (subview, placement) in zip(subviews, result.placements) {
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(placement.column) * (columnWidth + gap), y: bounds.minY + placement.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: nil)
            )
        }
    }

    private func heights(of subviews: Subviews, columnWidth: CGFloat) -> [CGFloat] {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height }
    }

    /// With no width to fill, for example in a horizontal scroll view, uses the widest item.
    private func totalWidth(for proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let width = proposal.width, width.isFinite { return max(0, width) }
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return widest * CGFloat(columnCount) + gap * CGFloat(columnCount - 1)
    }
}

// MARK: - Demo

struct MasonryLayoutDemo: View {
    private static let notes: [(title: String, height: CGFloat, color: Color)] = [
        ("Sunrise", 150, .orange), ("Moss", 96, .green), ("Tide", 190, .teal), ("Ember", 120, .red),
        ("Dusk", 170, .purple), ("Fern", 110, .mint), ("Harbor", 140, .blue), ("Clay", 200, .brown),
        ("Lilac", 104, .indigo), ("Peach", 160, .pink), ("Sage", 130, .cyan), ("Slate", 118, .gray),
    ]

    @State private var columns = 2
    @State private var autoPlays = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columnsBinding: Binding<Int> {
        Binding(get: { columns }, set: { newValue in
            autoPlays = false
            columns = newValue
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Columns", selection: columnsBinding) {
                    ForEach(2...3, id: \.self) { Text("\($0) columns").tag($0) }
                }
                .pickerStyle(.segmented)

                MasonryLayout(columns: columns, spacing: 10) {
                    ForEach(Self.notes, id: \.title) { note in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(note.color.gradient)
                            .frame(height: note.height)
                            .overlay(alignment: .bottomLeading) {
                                Text(note.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(12)
                            }
                    }
                }
            }
            .padding(20)
        }
        .task(id: autoPlays && !reduceMotion) {
            guard autoPlays, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.5)) { columns = columns == 2 ? 3 : 2 }
            }
        }
    }
}

#Preview {
    MasonryLayoutDemo()
}
