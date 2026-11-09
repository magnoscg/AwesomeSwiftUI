// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct CoverFlowCarouselItem: Identifiable {
    let id: String
    let title: String
    let image: Image
}

/// A horizontal carousel where the centered item faces forward and its neighbours turn away in 3D.
///
/// With Reduce Motion on, items stay flat and only fade.
struct CoverFlowCarousel: View {
    let items: [CoverFlowCarouselItem]
    @Binding var selection: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let itemWidth = max(containerWidth * 0.62, 1)
            let tilts = !reduceMotion

            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        card(for: item, position: index + 1)
                            .frame(width: itemWidth, height: min(itemWidth * 1.4, geometry.size.height))
                            .frame(maxHeight: .infinity)
                            .visualEffect { content, proxy in
                                let position = CoverFlowCarouselMath.position(midX: proxy.frame(in: .scrollView).midX, width: containerWidth)
                                return content
                                    .scaleEffect(tilts ? 1 - abs(position) * 0.14 : 1)
                                    .rotation3DEffect(.degrees(tilts ? position * -52 : 0), axis: (0, 1, 0), perspective: 0.5)
                                    .opacity(1 - abs(position) * 0.4)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max((containerWidth - itemWidth) / 2, 0), for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selection, anchor: .center)
        }
    }

    private func card(for item: CoverFlowCarouselItem, position: Int) -> some View {
        Color.clear
            .overlay {
                item.image
                    .resizable()
                    .scaledToFill()
                    .accessibilityRepresentation { EmptyView() }
            }
            .overlay(alignment: .bottomLeading) {
                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom))
            }
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.title)
            .accessibilityValue("\(position) of \(items.count)")
    }
}

enum CoverFlowCarouselMath {
    /// How far an item is from the center of the carousel: 0 at the center, -1 or 1 one half width away.
    static func position(midX: Double, width: Double) -> Double {
        guard width > 0, midX.isFinite else { return 0 }
        let halfWidth = width / 2
        return min(max((midX - halfWidth) / halfWidth, -1), 1)
    }
}

// MARK: - Demo

struct CoverFlowCarouselDemo: View {
    @State private var selection: String? = "Midnight"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let items = [
        CoverFlowCarouselItem(id: "Sunset", title: "Sunset", image: artwork([.orange, .pink], symbol: "sun.horizon.fill")),
        CoverFlowCarouselItem(id: "Forest", title: "Forest", image: artwork([.green, .teal], symbol: "tree.fill")),
        CoverFlowCarouselItem(id: "Midnight", title: "Midnight", image: artwork([.indigo, .black], symbol: "moon.stars.fill")),
        CoverFlowCarouselItem(id: "Ocean", title: "Ocean", image: artwork([.cyan, .blue], symbol: "water.waves")),
        CoverFlowCarouselItem(id: "Bloom", title: "Bloom", image: artwork([.pink, .purple], symbol: "camera.macro")),
    ]

    var body: some View {
        VStack(spacing: 18) {
            Text("Albums")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            CoverFlowCarousel(items: items, selection: $selection)
                .frame(height: 400)

            Text(selection ?? "")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.75))
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            let order = [3, 4, 3, 2, 1, 0, 1, 2]
            var step = 3
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                step = (step + 1) % order.count
                withAnimation(.smooth(duration: 0.8)) { selection = items[order[step]].id }
            }
        }
    }

    private static func artwork(_ colors: [Color], symbol: String) -> Image {
        let size = CGSize(width: 300, height: 420)
        return Image(size: size, opaque: true) { context in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )

            var icon = context.resolve(Image(systemName: symbol))
            icon.shading = .color(.white.opacity(0.85))
            let scale = 110 / max(icon.size.width, icon.size.height, 1)
            let iconSize = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
            context.draw(icon, in: CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            ))
        }
    }
}

#Preview {
    CoverFlowCarouselDemo()
}
