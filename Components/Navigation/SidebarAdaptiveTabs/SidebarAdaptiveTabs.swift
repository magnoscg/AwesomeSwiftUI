// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct SidebarAdaptiveTabsItem<Value: Hashable>: Identifiable {
    let title: String
    let systemImage: String
    let value: Value

    var id: Value { value }
}

/// The same tabs as a bottom tab bar on iPhone and as a sidebar people can show on iPad.
struct SidebarAdaptiveTabs<Value: Hashable, Content: View>: View {
    @Binding var selection: Value
    let tabs: [SidebarAdaptiveTabsItem<Value>]
    @ViewBuilder let content: (SidebarAdaptiveTabsItem<Value>) -> Content

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { item in
                Tab(item.title, systemImage: item.systemImage, value: item.value) {
                    content(item)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

// MARK: - Demo

private enum SidebarAdaptiveTabsDemoPage: Hashable {
    case home, explore, library, profile

    var headline: String {
        switch self {
        case .home: "Today's picks"
        case .explore: "New places"
        case .library: "Saved stories"
        case .profile: "Your account"
        }
    }

    var colors: [Color] {
        switch self {
        case .home: [.orange, .pink]
        case .explore: [.teal, .blue]
        case .library: [.purple, .indigo]
        case .profile: [.mint, .green]
        }
    }
}

struct SidebarAdaptiveTabsDemo: View {
    @State private var selection = SidebarAdaptiveTabsDemoPage.home

    private let tabs = [
        SidebarAdaptiveTabsItem(title: "Home", systemImage: "house.fill", value: SidebarAdaptiveTabsDemoPage.home),
        SidebarAdaptiveTabsItem(title: "Explore", systemImage: "safari.fill", value: .explore),
        SidebarAdaptiveTabsItem(title: "Library", systemImage: "books.vertical.fill", value: .library),
        SidebarAdaptiveTabsItem(title: "Profile", systemImage: "person.crop.circle.fill", value: .profile),
    ]

    var body: some View {
        SidebarAdaptiveTabs(selection: $selection, tabs: tabs) { item in
            ZStack {
                LinearGradient(colors: item.value.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: item.systemImage)
                        .font(.system(.largeTitle, design: .rounded))
                        .accessibilityHidden(true)

                    Text(item.value.headline)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding()
            }
            // Before iOS 26 the bar is clear over a page that does not scroll, and its items take the page's color.
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

#Preview {
    SidebarAdaptiveTabsDemo()
}
