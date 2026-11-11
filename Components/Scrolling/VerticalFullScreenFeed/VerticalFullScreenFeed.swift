// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct VerticalFullScreenFeedItem: Identifiable {
    let id: String
    let image: Image
    let title: String
    let subtitle: String
    /// What the image shows, for VoiceOver. Leave it nil when the image is decoration.
    var imageLabel: String?
}

/// A vertical feed where each item fills the screen and snaps into place.
///
/// The paging is driven by the finger, so Reduce Motion does not change it.
struct VerticalFullScreenFeed: View {
    let items: [VerticalFullScreenFeedItem]
    var selection: Binding<String?> = .constant(nil)

    var body: some View {
        GeometryReader { outer in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        page(item, bottomInset: outer.safeAreaInsets.bottom)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: selection)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
        }
        .background(.black)
    }

    private func page(_ item: VerticalFullScreenFeedItem, bottomInset: CGFloat) -> some View {
        // The clear base takes the page size, so a large image cannot change the layout.
        Color.clear
            .overlay { pageImage(item) }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 320)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title.bold())

                    Text(item.subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.bottom, bottomInset + 20)
                .accessibilityElement(children: .combine)
            }
    }

    @ViewBuilder
    private func pageImage(_ item: VerticalFullScreenFeedItem) -> some View {
        let image = item.image.resizable().scaledToFill()

        if let label = item.imageLabel {
            image.accessibilityLabel(label)
        } else {
            image.accessibilityRepresentation { EmptyView() }
        }
    }
}

// MARK: - Demo

struct VerticalFullScreenFeedDemo: View {
    @State private var items = [
        VerticalFullScreenFeedDemo.item("Mountains at dawn", symbol: "mountain.2.fill", colors: [.orange, .pink, .indigo], imageLabel: "Two mountain peaks on a pink sky"),
        VerticalFullScreenFeedDemo.item("A walk in the forest", symbol: "tree.fill", colors: [.mint, .green, .teal], imageLabel: "A tree on a green background"),
        VerticalFullScreenFeedDemo.item("Deep blue water", symbol: "water.waves", colors: [.cyan, .blue, .indigo], imageLabel: "Waves on a blue background"),
        VerticalFullScreenFeedDemo.item("Under the stars", symbol: "moon.stars.fill", colors: [.purple, .indigo, .black], imageLabel: "A moon and stars on a dark sky"),
    ]
    @State private var selection: String?
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VerticalFullScreenFeed(items: items, selection: $selection)
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                await autoAdvance()
            }
    }

    // Only the demo advances by itself. In an app the user swipes between pages.
    private func autoAdvance() async {
        var index = 0
        while isAutoPlaying {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled, isAutoPlaying, !items.isEmpty else { return }
            index = (index + 1) % items.count
            withAnimation(.smooth(duration: 0.6)) {
                selection = items[index].id
            }
        }
    }

    // Draws a placeholder poster, so the demo needs no image files or network.
    private static func item(_ title: String, symbol: String, colors: [Color], imageLabel: String) -> VerticalFullScreenFeedItem {
        let poster = ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)

            Image(systemName: symbol)
                .font(.system(size: 170))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 402, height: 874)

        let renderer = ImageRenderer(content: poster)
        renderer.scale = 2
        let image = renderer.uiImage.map(Image.init(uiImage:)) ?? Image(systemName: symbol)
        return VerticalFullScreenFeedItem(id: title, image: image, title: title, subtitle: "A placeholder drawn with a gradient and a symbol.", imageLabel: imageLabel)
    }
}

#Preview {
    VerticalFullScreenFeedDemo()
}
