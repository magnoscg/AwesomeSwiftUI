// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A grid of tiles the user can drag into a new order.
@available(iOS 27, *)
struct ReorderableGrid<Item: Identifiable & Sendable, Tile: View>: View where Item.ID: Sendable {
    @Binding var items: [Item]
    var minimumTileWidth: CGFloat = 100
    var spacing: CGFloat = 14
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: spacing)], spacing: spacing) {
                ForEach(items) { item in
                    tile(item)
                }
                .reorderable()
            }
            .padding()
            .reorderContainer(for: Item.self) { difference in
                let destination: Item.ID? = switch difference.destination.position {
                case .before(let id): id
                case .end: nil
                }
                items = ReorderableGridReordering.moving(difference.sources, before: destination, in: items)
            }
        }
    }
}

@available(iOS 27, *)
enum ReorderableGridReordering {
    /// Moves `sources` in front of `destination`, or to the end when it is nil.
    ///
    /// When `destination` is itself being moved, the first unmoved item after it is the anchor.
    static func moving<Item: Identifiable>(
        _ sources: [Item.ID],
        before destination: Item.ID?,
        in items: [Item]
    ) -> [Item] {
        let moved = sources.compactMap { source in items.first { $0.id == source } }
        var remaining = items.filter { !sources.contains($0.id) }

        let start = items.firstIndex { $0.id == destination } ?? items.endIndex
        let anchor = items[start...].first { !sources.contains($0.id) }
        let index = remaining.firstIndex { $0.id == anchor?.id } ?? remaining.endIndex

        remaining.insert(contentsOf: moved, at: index)
        return remaining
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct ReorderableGridDemo: View {
    nonisolated private struct App: Identifiable, Sendable {
        let id: String
        let systemImage: String
        let color: Color
    }

    @State private var apps = [
        App(id: "Music", systemImage: "music.note", color: .pink),
        App(id: "Photos", systemImage: "photo.fill", color: .orange),
        App(id: "Maps", systemImage: "map.fill", color: .green),
        App(id: "Mail", systemImage: "envelope.fill", color: .blue),
        App(id: "Notes", systemImage: "note.text", color: .yellow),
        App(id: "Weather", systemImage: "cloud.sun.fill", color: .cyan),
        App(id: "Books", systemImage: "book.fill", color: .indigo),
        App(id: "Health", systemImage: "heart.fill", color: .red),
        App(id: "Files", systemImage: "folder.fill", color: .teal),
        App(id: "Clock", systemImage: "clock.fill", color: .purple),
        App(id: "Camera", systemImage: "camera.fill", color: .gray),
        App(id: "Wallet", systemImage: "wallet.bifold.fill", color: .mint),
    ]

    var body: some View {
        NavigationStack {
            ReorderableGrid(items: $apps) { app in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(app.color.gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: app.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                    Text(app.id)
                        .font(.subheadline.weight(.medium))
                }
            }
            .navigationTitle("Hold and drag")
        }
    }
}

@available(iOS 27, *)
#Preview {
    ReorderableGridDemo()
}
