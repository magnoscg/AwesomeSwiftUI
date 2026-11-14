// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

private struct BlurUpImageFocus: Transition {
    let radius: CGFloat

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .blur(radius: phase.isIdentity ? 0 : radius)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

/// Shows a blurred preview until the full image arrives, then brings it into focus.
///
/// It fills the space it is given. With Reduce Motion on, the full image fades in without the
/// focus pull. Use `BlurUpImageRemote` to load the full image from a URL.
struct BlurUpImage: View {
    let preview: Image
    let image: Image?
    let label: LocalizedStringResource
    var blurRadius: CGFloat = 24
    var isLoading = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var radius: CGFloat { max(blurRadius, 0) }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(BlurUpImageFocus(radius: radius))
    }

    var body: some View {
        Color.clear
            .overlay {
                preview
                    .resizable()
                    .scaledToFill()
                    .blur(radius: radius, opaque: true)
            }
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(transition)
                }
            }
            .overlay {
                if image == nil, isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .clipped()
            .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.8), value: image != nil)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(image == nil && isLoading ? "Loading" : "")
            .accessibilityAddTraits(.isImage)
    }
}

/// Loads the full image from a URL. The preview stays on screen if the download fails.
struct BlurUpImageRemote: View {
    let url: URL?
    let preview: Image
    let label: LocalizedStringResource

    var body: some View {
        AsyncImage(url: url) { phase in
            BlurUpImage(preview: preview, image: phase.image, label: label, isLoading: url != nil && phase.error == nil)
        }
    }
}

// MARK: - Demo

struct BlurUpImageDemo: View {
    @State private var isLoaded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let preview = demoPhoto(size: CGSize(width: 18, height: 24))
    private let full = demoPhoto(size: CGSize(width: 900, height: 1200))

    var body: some View {
        VStack(spacing: 20) {
            BlurUpImage(preview: preview, image: isLoaded ? full : nil, label: "Mountains at dusk")
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 24))

            Text(isLoaded ? "Full image loaded" : "Loading the full image")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                isLoaded = true
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                isLoaded = true
                try? await Task.sleep(for: .seconds(2.3))
                guard !Task.isCancelled else { return }
                isLoaded = false
            }
        }
    }
}

private func demoPhoto(size: CGSize) -> Image {
    Image(size: size, label: Text("Mountains at dusk")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [.indigo, .purple, .orange]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        let sun = size.width * 0.22
        context.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.6, y: size.height * 0.18, width: sun, height: sun)),
            with: .color(.white.opacity(0.85))
        )

        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: size.height))
        ridge.addLine(to: CGPoint(x: 0, y: size.height * 0.63))
        ridge.addCurve(
            to: CGPoint(x: size.width, y: size.height * 0.55),
            control1: CGPoint(x: size.width / 3, y: size.height * 0.4),
            control2: CGPoint(x: size.width * 0.66, y: size.height * 0.85)
        )
        ridge.addLine(to: CGPoint(x: size.width, y: size.height))
        ridge.closeSubpath()
        context.fill(ridge, with: .color(Color(red: 0.12, green: 0.12, blue: 0.32)))
    }
}

#Preview {
    BlurUpImageDemo()
}
