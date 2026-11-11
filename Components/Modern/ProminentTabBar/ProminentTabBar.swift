// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

@available(iOS 27, *)
struct ProminentTabBarItem<Value: Hashable>: Identifiable {
    let title: String
    let systemImage: String
    let value: Value

    var id: Value { value }
}

/// A tab view whose main action gets the system's prominent tab treatment.
@available(iOS 27, *)
struct ProminentTabBar<Value: Hashable, Content: View>: View {
    let tabs: [ProminentTabBarItem<Value>]
    let prominent: ProminentTabBarItem<Value>
    @Binding var selection: Value
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab.value) {
                    content(tab.value)
                }
            }

            Tab(prominent.title, systemImage: prominent.systemImage, value: prominent.value, role: .prominent) {
                content(prominent.value)
            }
        }
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct ProminentTabBarDemo: View {
    private enum Screen: Hashable {
        case feed, explore, inbox, compose
    }

    @State private var selection = Screen.feed

    var body: some View {
        ProminentTabBar(
            tabs: [
                ProminentTabBarItem(title: "Feed", systemImage: "house.fill", value: .feed),
                ProminentTabBarItem(title: "Explore", systemImage: "safari.fill", value: .explore),
                ProminentTabBarItem(title: "Inbox", systemImage: "tray.fill", value: .inbox),
            ],
            prominent: ProminentTabBarItem(title: "Compose", systemImage: "plus", value: .compose),
            selection: $selection
        ) { screen in
            switch screen {
            case .feed: page("Good morning", icon: "sun.max.fill", colors: [.orange, .pink])
            case .explore: page("Find something new", icon: "binoculars.fill", colors: [.teal, .blue])
            case .inbox: page("All caught up", icon: "checkmark.seal.fill", colors: [.green, .mint])
            case .compose: page("Start writing", icon: "square.and.pencil", colors: [.purple, .indigo])
            }
        }
    }

    private func page(_ title: String, icon: String, colors: [Color]) -> some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.largeTitle.bold())
            }
            .foregroundStyle(.white)
        }
    }
}

@available(iOS 27, *)
#Preview {
    ProminentTabBarDemo()
}
