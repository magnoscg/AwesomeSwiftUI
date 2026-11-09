// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct AnimatedTabBarItem<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    let systemImage: String

    var id: Value { value }
}

/// A custom tab bar whose indicator slides to the selected tab while its icon bounces.
///
/// With Reduce Motion on, the indicator jumps and the icons stay still.
struct AnimatedTabBar<Value: Hashable>: View {
    let items: [AnimatedTabBarItem<Value>]
    @Binding var selection: Value
    var tint: Color = .indigo

    @State private var bounces: [Value: Int] = [:]
    @Namespace private var indicator
    @ScaledMetric(relativeTo: .title3) private var iconHeight = 26.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        .symbolEffectsRemoved(reduceMotion)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: selection)
        .onChange(of: selection) { _, newValue in
            bounces[newValue, default: 0] += 1
        }
    }

    private func tabButton(_ item: AnimatedTabBarItem<Value>) -> some View {
        let isSelected = item.value == selection

        return Button {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                selection = item.value
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage)
                    .font(.title3.weight(.semibold))
                    .symbolEffect(.bounce, value: bounces[item.value, default: 0])
                    .frame(height: iconHeight)

                Text(item.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? tint : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(tint.opacity(0.18))
                        .matchedGeometryEffect(id: "indicator", in: indicator)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct AnimatedTabBarDemo: View {
    private enum Destination: Hashable {
        case home, search, saved, profile
    }

    private let items: [AnimatedTabBarItem<Destination>] = [
        AnimatedTabBarItem(value: .home, title: "Home", systemImage: "house.fill"),
        AnimatedTabBarItem(value: .search, title: "Search", systemImage: "magnifyingglass"),
        AnimatedTabBarItem(value: .saved, title: "Saved", systemImage: "bookmark.fill"),
        AnimatedTabBarItem(value: .profile, title: "Profile", systemImage: "person.fill"),
    ]

    @State private var selection = Destination.home

    private var page: (headline: String, colors: [Color]) {
        switch selection {
        case .home: ("Your day at a glance", [.indigo, .purple])
        case .search: ("Find anything", [.teal, .blue])
        case .saved: ("Kept for later", [.orange, .pink])
        case .profile: ("All about you", [.green, .teal])
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: selection)

            Text(page.headline)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            AnimatedTabBar(items: items, selection: $selection)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    AnimatedTabBarDemo()
}
