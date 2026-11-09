// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A full-screen backdrop made from a blurred image with a tint on top, for placing content over it.
///
/// It is decorative, so VoiceOver skips it.
struct BlurredImageBackdrop: View {
    let image: Image
    var blurRadius: CGFloat = 40
    var tint: Color = .black
    var tintOpacity: Double = 0.35

    var body: some View {
        Color.clear
            .overlay {
                image
                    .resizable()
                    .scaledToFill()
                    .blur(radius: max(blurRadius, 0), opaque: true)
            }
            .overlay(tint.opacity(min(max(tintOpacity, 0), 1)))
            .clipped()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// MARK: - Demo

struct BlurredImageBackdropDemo: View {
    private struct Album {
        let title: String
        let artist: String
        let symbol: String
        let colors: [Color]

        var artwork: Image {
            Image(size: CGSize(width: 600, height: 600)) { context in
                let bounds = CGRect(x: 0, y: 0, width: 600, height: 600)
                context.fill(
                    Path(bounds),
                    with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 600, y: 600))
                )

                var symbolImage = context.resolve(Image(systemName: symbol).resizable())
                symbolImage.shading = .color(.white.opacity(0.9))
                context.draw(symbolImage, in: bounds.insetBy(dx: 170, dy: 170))
            }
        }
    }

    private let albums = [
        Album(title: "Solar Tide", artist: "The Longwaves", symbol: "sun.haze.fill", colors: [.orange, .pink]),
        Album(title: "Night Forest", artist: "Moss & Ember", symbol: "leaf.fill", colors: [.teal, .indigo]),
        Album(title: "Violet Hours", artist: "Paper Planes", symbol: "moon.stars.fill", colors: [.purple, .blue]),
    ]

    @State private var index = 0
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var album: Album { albums[index] }

    var body: some View {
        ZStack {
            BlurredImageBackdrop(image: album.artwork)
                .id(index)
                .transition(.opacity)

            ScrollView {
                VStack(spacing: 24) {
                    album.artwork
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                        .clipShape(.rect(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
                        .id(index)
                        .transition(.opacity)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text(album.title)
                            .font(.system(.title, design: .rounded, weight: .bold))

                        Text(album.artist)
                            .font(.body)
                            .opacity(0.85)
                    }
                    .multilineTextAlignment(.center)

                    Button("Next album", systemImage: "forward.fill") {
                        isAutoPlaying = false
                        index = (index + 1) % albums.count
                    }
                    .buttonStyle(.bordered)
                }
                .foregroundStyle(.white)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .tint(.white)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: index)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled, isAutoPlaying else { return }
                index = (index + 1) % albums.count
            }
        }
    }
}

#Preview {
    BlurredImageBackdropDemo()
}
