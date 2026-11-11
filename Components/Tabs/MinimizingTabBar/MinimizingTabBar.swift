// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A tab view whose tab bar shrinks into a compact capsule while the content scrolls.
///
/// The system draws and animates the bar, and honours Reduce Motion. Each tab needs a
/// scroll view for the bar to react.
@available(iOS 26, *)
struct MinimizingTabBar<Selection: Hashable, Tabs: TabContent>: View where Tabs.TabValue == Selection {
    @Binding var selection: Selection
    var behavior: TabBarMinimizeBehavior = .onScrollDown
    @TabContentBuilder<Selection> var tabs: () -> Tabs

    var body: some View {
        TabView(selection: $selection) {
            tabs()
        }
        .tabBarMinimizeBehavior(behavior)
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct MinimizingTabBarDemo: View {
    private enum Screen: Hashable {
        case listen, browse, library
    }

    @State private var selection = Screen.listen

    var body: some View {
        MinimizingTabBar(selection: $selection) {
            Tab("Listen", systemImage: "play.circle.fill", value: Screen.listen) {
                screen(title: "Listen now", symbol: "music.note", colors: [.pink, .orange])
            }

            Tab("Browse", systemImage: "square.grid.2x2.fill", value: Screen.browse) {
                screen(title: "New releases", symbol: "sparkles", colors: [.purple, .indigo])
            }

            Tab("Library", systemImage: "books.vertical.fill", value: Screen.library) {
                screen(title: "Your songs", symbol: "heart.fill", colors: [.teal, .blue])
            }
        }
    }

    private func screen(title: String, symbol: String, colors: [Color]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.largeTitle.bold())

                ForEach(1...24, id: \.self) { number in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: symbol)
                                    .foregroundStyle(.white)
                            }
                            .accessibilityHidden(true)

                        Text("Track \(number)")
                            .font(.headline)

                        Spacer()
                    }
                }
            }
            .padding(20)
        }
    }
}

@available(iOS 26, *)
#Preview {
    MinimizingTabBarDemo()
}
