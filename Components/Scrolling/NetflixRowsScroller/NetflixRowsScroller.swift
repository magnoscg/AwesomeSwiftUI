// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct NetflixRowsScrollerTitle: Identifiable {
    let id: String
    let name: String
    let image: Image
}

struct NetflixRowsScrollerRow: Identifiable {
    let id: String
    let title: String
    let items: [NetflixRowsScrollerTitle]
}

/// A vertical stack of titled horizontal rows where each row scrolls on its own.
struct NetflixRowsScroller: View {
    let rows: [NetflixRowsScrollerRow]
    var onSelect: (NetflixRowsScrollerTitle) -> Void = { _ in }

    private let posterSpacing: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(row.title)
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 16)
                            .accessibilityAddTraits(.isHeader)

                        ScrollView(.horizontal) {
                            LazyHStack(spacing: posterSpacing) {
                                ForEach(row.items) { item in
                                    poster(for: item)
                                        .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: posterSpacing)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .contentMargins(.horizontal, 16, for: .scrollContent)
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func poster(for item: NetflixRowsScrollerTitle) -> some View {
        Button {
            onSelect(item)
        } label: {
            Color.clear
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .overlay {
                    item.image
                        .resizable()
                        .scaledToFill()
                        .accessibilityRepresentation { EmptyView() }
                }
                .clipShape(.rect(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(NetflixRowsScrollerPosterStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(item.name)
    }
}

/// A poster dims and shrinks a little while it is pressed.
private struct NetflixRowsScrollerPosterStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Demo

struct NetflixRowsScrollerDemo: View {
    private static let palettes: [[Color]] = [
        [.red, .orange], [.indigo, .purple], [.teal, .blue], [.pink, .purple], [.green, .teal], [.orange, .yellow],
    ]

    private static let symbols = ["film.fill", "sparkles", "flame.fill", "bolt.fill", "moon.fill", "star.fill", "theatermasks.fill", "globe.americas.fill"]

    private let rows: [NetflixRowsScrollerRow] = ["Trending Now", "New Releases", "Because You Watched", "Top Picks"].enumerated().map { rowIndex, title in
        NetflixRowsScrollerRow(id: title, title: title, items: (0..<8).map { index in
            let seed = rowIndex * 3 + index
            return NetflixRowsScrollerTitle(
                id: "\(title)-\(index)",
                name: "\(title) \(index + 1)",
                image: poster(palettes[seed % palettes.count], symbol: symbols[seed % symbols.count])
            )
        })
    }

    @State private var selected: String?

    var body: some View {
        NetflixRowsScroller(rows: rows) { title in
            selected = title.name
        }
        .foregroundStyle(.white)
        .background(.black)
        .safeAreaInset(edge: .bottom) {
            if let selected {
                Label(selected, systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: .capsule)
                    .environment(\.colorScheme, .dark)
                    .padding(.bottom, 8)
            }
        }
    }

    private static func poster(_ colors: [Color], symbol: String) -> Image {
        let size = CGSize(width: 200, height: 300)
        return Image(size: size, opaque: true) { context in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )

            var icon = context.resolve(Image(systemName: symbol))
            icon.shading = .color(.white.opacity(0.9))
            let scale = 80 / max(icon.size.width, icon.size.height, 1)
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
    NetflixRowsScrollerDemo()
}
