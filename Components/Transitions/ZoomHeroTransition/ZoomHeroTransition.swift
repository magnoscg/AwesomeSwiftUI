// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A grid of cards that zoom into their detail screen. Place it inside a `NavigationStack`.
///
/// With Reduce Motion on, the detail opens with the standard navigation transition.
struct ZoomHeroTransition<Item: Identifiable & Hashable, Card: View, Detail: View>: View {
    let items: [Item]
    var columns: Int = 2
    var cornerRadius: CGFloat = 24
    @ViewBuilder var card: (Item) -> Card
    @ViewBuilder var detail: (Item) -> Detail

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns), spacing: 14) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        card(item)
                            .clipShape(.rect(cornerRadius: cornerRadius))
                            .matchedTransitionSource(id: item.id, in: namespace) { source in
                                source.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationDestination(for: Item.self) { item in
            destination(for: item)
        }
    }

    // `.zoom` and `.automatic` are different types, so a ternary cannot choose between them on iOS 18.
    @ViewBuilder
    private func destination(for item: Item) -> some View {
        if reduceMotion {
            detail(item)
        } else {
            detail(item).navigationTransition(.zoom(sourceID: item.id, in: namespace))
        }
    }
}

// MARK: - Demo

private struct ZoomHeroDemoPlace: Identifiable, Hashable {
    let id: String
    let systemImage: String
    let colors: [Color]
}

struct ZoomHeroTransitionDemo: View {
    private let places = [
        ZoomHeroDemoPlace(id: "Aurora", systemImage: "sparkles", colors: [.indigo, .teal]),
        ZoomHeroDemoPlace(id: "Dunes", systemImage: "sun.max.fill", colors: [.orange, .pink]),
        ZoomHeroDemoPlace(id: "Forest", systemImage: "leaf.fill", colors: [.green, .mint]),
        ZoomHeroDemoPlace(id: "Glacier", systemImage: "snowflake", colors: [.cyan, .blue]),
        ZoomHeroDemoPlace(id: "Volcano", systemImage: "flame.fill", colors: [.red, .orange]),
        ZoomHeroDemoPlace(id: "Night", systemImage: "moon.stars.fill", colors: [.purple, .indigo]),
    ]

    var body: some View {
        NavigationStack {
            ZoomHeroTransition(items: places) { place in
                LinearGradient(colors: place.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .aspectRatio(0.78, contentMode: .fit)
                    .overlay {
                        Image(systemName: place.systemImage)
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.white.opacity(0.9))
                            .accessibilityHidden(true)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(place.id)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(14)
                    }
            } detail: { place in
                ZoomHeroDemoDetail(place: place)
            }
            .navigationTitle("Places")
        }
    }
}

private struct ZoomHeroDemoDetail: View {
    let place: ZoomHeroDemoPlace

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: place.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: place.systemImage)
                    .font(.system(.largeTitle, weight: .semibold))
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text(place.id)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("The card grew into this screen. Swipe down or tap Close to send it back.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
                    .tint(.white)
            }
            .foregroundStyle(.white)
            .padding(32)
        }
    }
}

#Preview {
    ZoomHeroTransitionDemo()
}
