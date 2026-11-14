// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Shows the same items as a list or as a grid. One grid changes its number of
/// columns, so every item glides to its new place and keeps its state.
///
/// `content` also receives `isGrid`, so a cell can change its own design.
struct MorphingLayoutSwitch<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let isGrid: Bool
    var columns = 2
    var spacing: CGFloat = 12
    @ViewBuilder let content: (Data.Element, Bool) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: isGrid ? min(max(1, columns), 64) : 1)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(data) { element in
                content(element, isGrid)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.5), value: isGrid)
    }
}

// MARK: - Demo

struct MorphingLayoutSwitchDemo: View {
    private struct Album: Identifiable {
        let id: String
        let systemImage: String
        let color: Color
    }

    private static let albums = [
        Album(id: "Skyline", systemImage: "building.2.fill", color: .indigo),
        Album(id: "Forest", systemImage: "tree.fill", color: .green),
        Album(id: "Coast", systemImage: "water.waves", color: .teal),
        Album(id: "Desert", systemImage: "sun.max.fill", color: .orange),
        Album(id: "Night", systemImage: "moon.stars.fill", color: .purple),
        Album(id: "Snow", systemImage: "snowflake", color: .cyan),
    ]

    @State private var isGrid = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Button(isGrid ? "Show list" : "Show grid", systemImage: isGrid ? "list.bullet" : "square.grid.2x2") {
                    isGrid.toggle()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)

                MorphingLayoutSwitch(data: Self.albums, isGrid: isGrid) { album, isGrid in
                    cell(album, isGrid: isGrid)
                }
            }
            .padding(20)
        }
        .tint(.indigo)
    }

    private func cell(_ album: Album, isGrid: Bool) -> some View {
        let layout = isGrid ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 14))

        return layout {
            Image(systemName: album.systemImage)
                .font(isGrid ? .largeTitle : .title2)
                .accessibilityHidden(true)
            Text(album.id)
                .font(.headline)
            if !isGrid { Spacer(minLength: 0) }
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: isGrid ? 140 : 70)
        .background(album.color.gradient, in: .rect(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    MorphingLayoutSwitchDemo()
}
