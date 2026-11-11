// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A card that lifts a richer preview above its menu when long pressed.
///
/// The system animates the lift and simplifies it for Reduce Motion. VoiceOver
/// users find the menu items in the actions rotor. Give the preview a fixed size.
struct ContextMenuPreviewCard<Card: View, Preview: View, MenuItems: View>: View {
    var cornerRadius: CGFloat = 22
    @ViewBuilder var card: () -> Card
    @ViewBuilder var preview: () -> Preview
    @ViewBuilder var menuItems: () -> MenuItems

    var body: some View {
        card()
            .clipShape(.rect(cornerRadius: cornerRadius))
            .contentShape(.contextMenuPreview, .rect(cornerRadius: cornerRadius))
            .contextMenu(menuItems: menuItems, preview: preview)
    }
}

// MARK: - Demo

private struct ContextMenuPreviewCardDemoTrip: Identifiable {
    let id: String
    let subtitle: String
    let systemImage: String
    let colors: [Color]
}

struct ContextMenuPreviewCardDemo: View {
    private let trips = [
        ContextMenuPreviewCardDemoTrip(id: "Alps", subtitle: "Six days above the clouds", systemImage: "mountain.2.fill", colors: [.teal, .blue]),
        ContextMenuPreviewCardDemoTrip(id: "Coast", subtitle: "A slow week by the sea", systemImage: "sailboat.fill", colors: [.cyan, .indigo]),
        ContextMenuPreviewCardDemoTrip(id: "Desert", subtitle: "Stars and quiet nights", systemImage: "sun.max.fill", colors: [.orange, .pink]),
        ContextMenuPreviewCardDemoTrip(id: "Forest", subtitle: "Trails and cabins", systemImage: "tree.fill", colors: [.green, .mint]),
    ]

    @State private var lastAction = "Press and hold a card"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(lastAction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                        ForEach(trips) { trip in
                            ContextMenuPreviewCard {
                                compactCard(trip)
                            } preview: {
                                richPreview(trip)
                            } menuItems: {
                                Button("Share", systemImage: "square.and.arrow.up") { lastAction = "Shared \(trip.id)" }
                                Button("Save", systemImage: "bookmark") { lastAction = "Saved \(trip.id)" }
                                Button("Remove", systemImage: "trash", role: .destructive) { lastAction = "Removed \(trip.id)" }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Trips")
        }
    }

    private func compactCard(_ trip: ContextMenuPreviewCardDemoTrip) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: trip.systemImage)
                .font(.title)
                .accessibilityHidden(true)

            Spacer(minLength: 24)

            Text(trip.id).font(.headline)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(LinearGradient(colors: trip.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .accessibilityElement(children: .combine)
    }

    private func richPreview(_ trip: ContextMenuPreviewCardDemoTrip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LinearGradient(colors: trip.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: trip.systemImage)
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.white)
                }
                .frame(height: 190)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.id).font(.title2.bold())
                Text(trip.subtitle).font(.body).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .frame(width: 300, height: 300, alignment: .top)
    }
}

#Preview {
    ContextMenuPreviewCardDemo()
}
