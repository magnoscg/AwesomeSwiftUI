// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Keeps one navigation path per tab outside the tabs, so each can be read, reset or restored.
@MainActor
@Observable
final class TabNavigationStatePreserveStore<TabID: Hashable> {
    private(set) var selection: TabID
    private var paths: [TabID: NavigationPath] = [:]

    init(selection: TabID) {
        self.selection = selection
    }

    func path(for tab: TabID) -> NavigationPath {
        paths[tab] ?? NavigationPath()
    }

    func setPath(_ path: NavigationPath, for tab: TabID) {
        paths[tab] = path
    }

    func depth(of tab: TabID) -> Int {
        path(for: tab).count
    }

    func popToRoot(_ tab: TabID) {
        paths[tab] = NavigationPath()
    }

    /// Switches tab. Choosing the tab you are already on takes it back to its root.
    func select(_ tab: TabID) {
        if tab == selection {
            popToRoot(tab)
        } else {
            selection = tab
        }
    }
}

struct TabNavigationStatePreserveItem<TabID: Hashable>: Identifiable {
    let title: LocalizedStringResource
    let systemImage: String
    let tab: TabID

    var id: TabID { tab }
}

/// A tab bar where every tab keeps its own navigation stack.
///
/// Switching away and back restores the screen you left. Tapping the current tab pops
/// it to the root, on the iOS versions where `TabView` reports a repeated selection.
struct TabNavigationStatePreserve<TabID: Hashable, Route: Hashable, Root: View, Screen: View>: View {
    let store: TabNavigationStatePreserveStore<TabID>
    let tabs: [TabNavigationStatePreserveItem<TabID>]
    @ViewBuilder let root: (TabID) -> Root
    @ViewBuilder let screen: (Route) -> Screen

    var body: some View {
        TabView(selection: selection) {
            ForEach(tabs) { item in
                // The initializer that takes the title needs iOS 26 for a localizable one.
                Tab(value: item.tab) {
                    NavigationStack(path: path(for: item.tab)) {
                        root(item.tab)
                            .navigationDestination(for: Route.self, destination: screen)
                    }
                } label: {
                    Label { Text(item.title) } icon: { Image(systemName: item.systemImage) }
                }
            }
        }
    }

    private var selection: Binding<TabID> {
        Binding(get: { store.selection }, set: { store.select($0) })
    }

    private func path(for tab: TabID) -> Binding<NavigationPath> {
        Binding(get: { store.path(for: tab) }, set: { store.setPath($0, for: tab) })
    }
}

// MARK: - Demo

private enum TabNavigationStatePreserveDemoTab: Hashable {
    case home, library
}

private struct TabNavigationStatePreserveDemoPage: View {
    let title: LocalizedStringResource
    let link: String
    let route: Int
    let colors: [Color]
    let depth: Int

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Level \(depth)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                NavigationLink(link, value: route)
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
            }
            .foregroundStyle(.white)
        }
        .navigationTitle(title)
        // Before iOS 26 the bar is clear over a page that does not scroll, and its items take the page's color.
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct TabNavigationStatePreserveDemo: View {
    @State private var store = TabNavigationStatePreserveStore(selection: TabNavigationStatePreserveDemoTab.home)

    private let tabs = [
        TabNavigationStatePreserveItem(title: "Home", systemImage: "house.fill", tab: TabNavigationStatePreserveDemoTab.home),
        TabNavigationStatePreserveItem(title: "Library", systemImage: "books.vertical.fill", tab: .library),
    ]

    private func colors(for tab: TabNavigationStatePreserveDemoTab) -> [Color] {
        tab == .home ? [.orange, .pink] : [.teal, .indigo]
    }

    var body: some View {
        TabNavigationStatePreserve(store: store, tabs: tabs) { tab in
            TabNavigationStatePreserveDemoPage(
                title: tab == .home ? "Kitchen" : "Shelves",
                link: tab == .home ? "Recipes" : "Albums",
                route: 1,
                colors: colors(for: tab),
                depth: 0
            )
        } screen: { (level: Int) in
            TabNavigationStatePreserveDemoPage(
                title: "Page \(level)",
                link: "Deeper",
                route: level + 1,
                colors: colors(for: store.selection),
                depth: level
            )
        }
    }
}

#Preview {
    TabNavigationStatePreserveDemo()
}
