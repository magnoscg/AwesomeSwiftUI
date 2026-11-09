// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum ColorRevealImageMath {
    /// Full color near the middle of the scroll view, fading to none toward its edges.
    static func saturation(distanceFromCenter distance: CGFloat, viewportHeight: CGFloat) -> Double {
        guard viewportHeight > 0, distance.isFinite else { return 0 }

        let clearZone = viewportHeight * 0.12
        let fade = viewportHeight * 0.3
        return Double(min(max(1 - (abs(distance) - clearZone) / fade, 0), 1))
    }
}

/// A black and white image that gains its color as it nears the middle of a scroll view.
/// Tapping it shows the full color until tapped again.
///
/// Outside a scroll view it stays black and white until tapped. With Reduce Motion
/// on, a tap changes it at once. Scrolling still fades the color, which adds no movement.
struct ColorRevealImage: View {
    let image: Image
    let title: String
    var aspectRatio: CGFloat = 4.0 / 3.0
    var cornerRadius: CGFloat = 24

    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) {
                isRevealed.toggle()
            }
        } label: {
            Color.clear
                .aspectRatio(aspectRatio > 0 ? aspectRatio : 1, contentMode: .fit)
                .overlay {
                    ZStack {
                        image
                            .resizable()
                            .scaledToFill()
                            .visualEffect { effect, proxy in
                                let viewport = proxy.bounds(of: .scrollView(axis: .vertical))
                                let distance = (viewport?.midY ?? 0) - proxy.size.height / 2

                                return effect.saturation(
                                    ColorRevealImageMath.saturation(
                                        distanceFromCenter: distance,
                                        viewportHeight: viewport?.height ?? 0
                                    )
                                )
                            }

                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(isRevealed ? 1 : 0)
                    }
                    // The button already reads the title, so the images add nothing to VoiceOver.
                    .accessibilityRepresentation { EmptyView() }
                }
                .clipShape(.rect(cornerRadius: max(cornerRadius, 0), style: .continuous))
                .contentShape(.rect(cornerRadius: max(cornerRadius, 0), style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isRevealed ? "In full color" : "Color follows scrolling")
    }
}

// MARK: - Demo

struct ColorRevealImageDemo: View {
    private struct Photo: Identifiable {
        let title: String
        let symbol: String
        let colors: [Color]

        var id: String { title }

        var image: Image {
            Image(size: CGSize(width: 800, height: 600)) { context in
                let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
                context.fill(
                    Path(bounds),
                    with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 800, y: 600))
                )

                var symbolImage = context.resolve(Image(systemName: symbol).resizable())
                symbolImage.shading = .color(.white.opacity(0.85))
                context.draw(symbolImage, in: bounds.insetBy(dx: 290, dy: 190))
            }
        }
    }

    private let photos = [
        Photo(title: "Dunes", symbol: "sun.max.fill", colors: [.orange, .red]),
        Photo(title: "Forest", symbol: "tree.fill", colors: [.green, .teal]),
        Photo(title: "Lagoon", symbol: "water.waves", colors: [.cyan, .blue]),
        Photo(title: "Harbor", symbol: "sailboat.fill", colors: [.indigo, .pink]),
        Photo(title: "Meadow", symbol: "camera.macro", colors: [.yellow, .green]),
        Photo(title: "Canyon", symbol: "mountain.2.fill", colors: [.pink, .orange]),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Gallery")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(photos) { photo in
                    ColorRevealImage(image: photo.image, title: photo.title)
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    ColorRevealImageDemo()
}
