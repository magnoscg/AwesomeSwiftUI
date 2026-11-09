// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A soft blob that keeps changing shape, drawn in a canvas.
///
/// With Reduce Motion on, it shows one still blob.
struct BlobMorphLoader: View {
    var colors: [Color] = [.pink, .purple, .indigo]
    var size: CGFloat = 96
    var speed: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * speed

            Canvas { canvas, canvasSize in
                let blob = BlobMorphOutline.path(in: canvasSize, time: time)
                let shading = BlobMorphOutline.shading(colors: colors, in: canvasSize, time: time)

                var glow = canvas
                glow.addFilter(.blur(radius: canvasSize.width * 0.08))
                glow.opacity = 0.55
                glow.fill(blob, with: shading)

                canvas.fill(blob, with: shading)
            }
            .frame(width: size, height: size)
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

private enum BlobMorphOutline {
    static let pointCount = 16

    /// A closed curve through points whose distance from the center is a sum of moving sine waves.
    static func path(in size: CGSize, time: Double) -> Path {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let base = min(size.width, size.height) * 0.31

        let points = (0..<pointCount).map { index -> CGPoint in
            let angle = Double(index) / Double(pointCount) * 2 * .pi
            let swell = 0.16 * sin(2 * angle + time * 1.4)
                + 0.10 * sin(3 * angle - time * 1.1)
                + 0.06 * sin(5 * angle + time * 0.7)
            let radius = base * (1 + swell)
            return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }

        var path = Path()
        path.move(to: midpoint(points[pointCount - 1], points[0]))
        for index in 0..<pointCount {
            let next = points[(index + 1) % pointCount]
            path.addQuadCurve(to: midpoint(points[index], next), control: points[index])
        }
        path.closeSubpath()
        return path
    }

    /// A gradient whose direction turns slowly, so the color drifts across the blob.
    static func shading(colors: [Color], in size: CGSize, time: Double) -> GraphicsContext.Shading {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let reach = size.width * 0.4
        let offset = CGSize(width: cos(time * 0.6) * reach, height: sin(time * 0.6) * reach)

        return .linearGradient(
            Gradient(colors: colors),
            startPoint: CGPoint(x: center.x - offset.width, y: center.y - offset.height),
            endPoint: CGPoint(x: center.x + offset.width, y: center.y + offset.height)
        )
    }

    private static func midpoint(_ first: CGPoint, _ second: CGPoint) -> CGPoint {
        CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
    }
}

// MARK: - Demo

struct BlobMorphLoaderDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                BlobMorphLoader(size: 300)

                Text("Thinking")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your summary is almost ready")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(24)
        }
    }
}

#Preview {
    BlobMorphLoaderDemo()
}
