// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A list and its detail, side by side when there is room and pushed on one stack when not,
/// on the system's `NavigationSplitView`.
///
/// The system keeps the selection when an iPad rotates or a window is resized, and adds what a
/// split view is expected to have: the button that hides the list, the swipe back on iPhone
/// and the keyboard. The list selects with its own selection, so VoiceOver reads the selected row.
struct TwoPaneSplitLayout<Item: Identifiable & Hashable, Row: View, Detail: View>: View {
    let title: LocalizedStringResource
    let items: [Item]
    @Binding var selection: Item?
    var listWidth: CGFloat = 320
    @ViewBuilder let row: (Item) -> Row
    @ViewBuilder let detail: (Item) -> Detail

    var body: some View {
        NavigationSplitView {
            List(items, selection: $selection) { item in
                NavigationLink(value: item) {
                    row(item)
                }
            }
            .navigationTitle(title)
            .navigationSplitViewColumnWidth(ideal: max(listWidth, 0))
        } detail: {
            if let selection {
                detail(selection)
            } else {
                ContentUnavailableView("Nothing selected", systemImage: "sidebar.left")
            }
        }
        .navigationSplitViewStyle(.balanced)
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
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
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
