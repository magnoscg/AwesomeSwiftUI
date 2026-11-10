// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A grid where a drag selects every tile from the first to the one under the finger.
///
/// Tiles are square, and a tap toggles one. Starting on a selected tile deselects
/// instead. Keep it out of a `ScrollView`, or the scroll will take the drag.
struct DragSelectGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    @Binding var selection: Set<Item.ID>
    var columns = 4
    var spacing: CGFloat = 4
    @ViewBuilder var tile: (Item, Bool) -> Tile

    private struct Stroke {
        var base: Set<Item.ID>
        var start: Int
        var selecting: Bool
    }

    @State private var stroke: Stroke?
    @State private var gridWidth: CGFloat = 0
    @GestureState private var isDragging = false
    @Environment(\.layoutDirection) private var layoutDirection

    private var columnCount: Int { DragSelectGridMath.clampedColumns(columns) }
    private var gap: CGFloat { max(spacing, 0) }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: columnCount), spacing: gap) {
            ForEach(items) { item in
                let isSelected = selection.contains(item.id)

                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay { tile(item, isSelected) }
                    .contentShape(.rect)
                    .onTapGesture { toggle(item) }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction { toggle(item) }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { gridWidth = $0 }
        .simultaneousGesture(drag)
        .onChange(of: isDragging) { _, dragging in
            if !dragging { stroke = nil }
        }
        .sensoryFeedback(.selection, trigger: selection.count)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if stroke == nil, let start = index(at: value.startLocation) {
                    stroke = Stroke(base: selection, start: start, selecting: !selection.contains(items[start].id))
                }
                guard let stroke, let current = index(at: value.location) else { return }
                selection = DragSelectGridMath.selection(
                    base: stroke.base,
                    ids: items.map(\.id),
                    from: stroke.start,
                    to: current,
                    selecting: stroke.selecting
                )
            }
    }

    private func toggle(_ item: Item) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    private func index(at point: CGPoint) -> Int? {
        // Gestures report screen points, but the grid mirrors in right-to-left layouts.
        let x = layoutDirection == .rightToLeft ? gridWidth - point.x : point.x
        return DragSelectGridMath.index(at: CGPoint(x: x, y: point.y), width: gridWidth, columns: columnCount, spacing: gap, count: items.count)
    }
}

enum DragSelectGridMath {
    static func clampedColumns(_ columns: Int) -> Int {
        min(max(columns, 1), 24)
    }

    /// The tile under a point, or the nearest one when the point is outside the grid.
    static func index(at point: CGPoint, width: CGFloat, columns: Int, spacing: CGFloat, count: Int) -> Int? {
        guard count > 0, width > 0, point.x.isFinite, point.y.isFinite else { return nil }

        let columns = clampedColumns(columns)
        let gap = max(spacing, 0)
        let side = (width - gap * CGFloat(columns - 1)) / CGFloat(columns)
        guard side > 0 else { return nil }

        let rows = (count - 1) / columns + 1
        let column = Int(min(max(point.x / (side + gap), 0), CGFloat(columns - 1)))
        let row = Int(min(max(point.y / (side + gap), 0), CGFloat(rows - 1)))
        return min(row * columns + column, count - 1)
    }

    /// The selection during a stroke: what was selected before, plus or minus the tiles it covers.
    static func selection<ID: Hashable>(
        base: Set<ID>,
        ids: [ID],
        from start: Int,
        to current: Int,
        selecting: Bool
    ) -> Set<ID> {
        guard !ids.isEmpty else { return base }

        let first = min(max(min(start, current), 0), ids.count - 1)
        let last = min(max(max(start, current), 0), ids.count - 1)
        let covered = Set(ids[first...last])
        return selecting ? base.union(covered) : base.subtracting(covered)
    }
}

// MARK: - Demo

private struct DragSelectGridDemoPhoto: Identifiable {
    let id: Int
    let hue: Double
    let systemImage: String
}

struct DragSelectGridDemo: View {
    private let photos: [DragSelectGridDemoPhoto] = {
        let symbols = ["sun.max.fill", "leaf.fill", "moon.stars.fill", "flame.fill", "cloud.fill", "drop.fill"]
        return (0..<20).map { index in
            DragSelectGridDemoPhoto(id: index, hue: Double(index) / 20, systemImage: symbols[index % symbols.count])
        }
    }()

    @State private var selection: Set<Int> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(selection.isEmpty ? "Drag to select" : "\(selection.count) selected")
                    .font(.title2.bold())
                    .contentTransition(reduceMotion ? .identity : .numericText())
                Spacer()
                Button("Clear") { selection = [] }
                    .disabled(selection.isEmpty)
            }
            .animation(reduceMotion ? nil : .snappy, value: selection.count)
            .padding(.horizontal, 16)

            DragSelectGrid(items: photos, selection: $selection) { photo, isSelected in
                tile(photo, isSelected: isSelected)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }

    private func tile(_ photo: DragSelectGridDemoPhoto, isSelected: Bool) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hue: photo.hue, saturation: 0.55, brightness: 0.95), Color(hue: photo.hue, saturation: 0.85, brightness: 0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Image(systemName: photo.systemImage)
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .padding(5)
                }
            }
            .scaleEffect(isSelected && !reduceMotion ? 0.9 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0.3), value: isSelected)
            .accessibilityElement()
            .accessibilityLabel("Photo \(photo.id + 1)")
    }
}

#Preview {
    DragSelectGridDemo()
}
