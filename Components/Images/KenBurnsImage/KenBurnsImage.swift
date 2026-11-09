// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A still picture that slowly zooms and pans so that it appears to move.
///
/// It fills the space it is given and never shows an edge, because it only scales up around a
/// point inside the image. With Reduce Motion on, the picture stays still.
struct KenBurnsImage: View {
    let image: Image
    let label: String
    var duration: Double = 12
    var zoom: CGFloat = 1.3
    var from: UnitPoint = .topLeading
    var to: UnitPoint = .bottomTrailing

    @State private var isAtEnd = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: max(duration, 0.1)).repeatForever(autoreverses: true)
    }

    var body: some View {
        Color.clear
            .overlay {
                image
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(isAtEnd ? max(zoom, 1) : 1.02, anchor: isAtEnd ? to : from)
            }
            .clipped()
            .animation(animation, value: isAtEnd)
            .task(id: reduceMotion) { isAtEnd = !reduceMotion }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Demo

struct KenBurnsImageDemo: View {
    private let photo = demoPhoto()

    var body: some View {
        KenBurnsImage(image: photo, label: "Mountains at sunset", duration: 4, zoom: 1.6)
            .ignoresSafeArea()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sunset Ridge")
                        .font(.largeTitle.bold())
                    Text("Golden hour in the valley")
                        .font(.headline)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
                .padding(24)
            }
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 900, height: 1600)
    return Image(size: size, label: Text("Mountains at sunset")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [.indigo, .pink, .orange, .yellow]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: 1150)
            )
        )
        context.fill(Path(ellipseIn: CGRect(x: 280, y: 600, width: 340, height: 340)), with: .color(.white.opacity(0.8)))

        let ridges: [(base: CGFloat, color: Color)] = [
            (980, Color(red: 0.42, green: 0.2, blue: 0.5)),
            (1140, Color(red: 0.26, green: 0.14, blue: 0.42)),
            (1320, Color(red: 0.12, green: 0.08, blue: 0.26)),
        ]
        for (index, ridge) in ridges.enumerated() {
            let flip: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: ridge.base))
            path.addCurve(
                to: CGPoint(x: size.width, y: ridge.base - 40 * flip),
                control1: CGPoint(x: 300, y: ridge.base - 220 * flip),
                control2: CGPoint(x: 620, y: ridge.base + 200 * flip)
            )
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(ridge.color))
        }
    }
}

#Preview {
    KenBurnsImageDemo()
}
