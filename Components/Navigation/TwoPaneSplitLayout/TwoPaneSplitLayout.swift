// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A list and its detail, side by side when there is room and pushed on one stack when not.
///
/// Both forms share the same selection, so rotating an iPad or resizing a window keeps your place.
struct TwoPaneSplitLayout<Item: Identifiable & Hashable, Row: View, Detail: View>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Item?
    var listWidth: CGFloat = 320
    @ViewBuilder let row: (Item) -> Row
    @ViewBuilder let detail: (Item) -> Detail

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                NavigationStack { list }
                    .frame(width: max(listWidth, 0))

                Divider()
                    .ignoresSafeArea()

                NavigationStack { detailPane }
                    .frame(maxWidth: .infinity)
            }
        } else {
            NavigationStack {
                list.navigationDestination(item: $selection) { item in
                    detail(item)
                }
            }
        }
    }

    private var list: some View {
        List(items) { item in
            Button {
                selection = item
            } label: {
                row(item)
            }
            .listRowBackground(selection == item ? Color.accentColor.opacity(0.15) : nil)
            .accessibilityAddTraits(selection == item ? .isSelected : [])
        }
        .navigationTitle(title)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selection {
            detail(selection)
        } else {
            ContentUnavailableView("Nothing selected", systemImage: "sidebar.left")
        }
    }
}

// MARK: - Demo

private struct TwoPaneSplitLayoutDemoTrail: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let distance: Int
    let colors: [Color]
}

struct TwoPaneSplitLayoutDemo: View {
    private let trails = [
        TwoPaneSplitLayoutDemoTrail(name: "Alps", distance: 42, colors: [.blue, .teal]),
        TwoPaneSplitLayoutDemoTrail(name: "Dolomites", distance: 28, colors: [.orange, .pink]),
        TwoPaneSplitLayoutDemoTrail(name: "Pyrenees", distance: 65, colors: [.green, .mint]),
        TwoPaneSplitLayoutDemoTrail(name: "Rockies", distance: 110, colors: [.purple, .indigo]),
    ]

    @State private var selection: TwoPaneSplitLayoutDemoTrail?

    var body: some View {
        TwoPaneSplitLayout(title: "Trails", items: trails, selection: $selection) { trail in
            Label(trail.name, systemImage: "mountain.2.fill")
                .foregroundStyle(trail.colors[0])
        } detail: { trail in
            ZStack {
                LinearGradient(colors: trail.colors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(.largeTitle, design: .rounded))
                        .accessibilityHidden(true)

                    Text(trail.name)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("\(trail.distance) km")
                        .font(.title3.weight(.medium))

                    Button("Done") { selection = nil }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .padding(.top, 8)
                }
                .foregroundStyle(.white)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TwoPaneSplitLayoutDemo()
}
