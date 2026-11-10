// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct ImageDerivedGradientBackgroundSample: Equatable {
    let red: Double
    let green: Double
    let blue: Double
}

enum ImageDerivedGradientBackgroundMath {
    static let bytesPerPixel = 4

    /// Averages horizontal bands of premultiplied RGBA pixels, from top to bottom.
    ///
    /// Saturated pixels count for more, so a photo gives vivid colors instead of grey.
    /// Fully transparent bands are left out.
    static func bands(pixels: [UInt8], width: Int, height: Int, count: Int) -> [ImageDerivedGradientBackgroundSample] {
        guard width > 0, height > 0, count > 0, pixels.count / bytesPerPixel / width >= height else { return [] }
        let bandCount = min(count, height)

        return (0..<bandCount).compactMap { band in
            var red: Double = 0, green: Double = 0, blue: Double = 0, total: Double = 0

            for row in (band * height / bandCount)..<((band + 1) * height / bandCount) {
                for column in 0..<width {
                    let offset = (row * width + column) * bytesPerPixel
                    let alpha = Double(pixels[offset + 3])
                    guard alpha > 0 else { continue }

                    let r = Double(pixels[offset]) / alpha
                    let g = Double(pixels[offset + 1]) / alpha
                    let b = Double(pixels[offset + 2]) / alpha
                    let weight = alpha / 255 * (0.15 + max(r, g, b) - min(r, g, b))
                    red += r * weight
                    green += g * weight
                    blue += b * weight
                    total += weight
                }
            }

            guard total > 0 else { return nil }
            return ImageDerivedGradientBackgroundSample(red: red / total, green: green / total, blue: blue / total)
        }
    }
}

/// A full-screen gradient whose colors are sampled from an image and cross-fade when it changes.
///
/// Keep passing the same `Image` value while the picture is the same, or it is sampled again.
/// With Reduce Motion on, the colors change without fading.
struct ImageDerivedGradientBackground: View {
    private struct Request: Equatable {
        let image: Image
        let bands: Int
    }

    let image: Image
    var bands = 3
    var fallback: [Color] = [.indigo, .black]

    @State private var colors: [Color]?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shown = colors ?? fallback

        ZStack {
            Color.black

            LinearGradient(colors: shown, startPoint: .top, endPoint: .bottom)
                .id(shown)
                .transition(.opacity)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .task(id: Request(image: image, bands: bands)) {
            let sampled = sampledColors()
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) { colors = sampled }
        }
    }

    /// Draws the image small and reads its pixels. Returns nil when it cannot be rendered.
    private func sampledColors() -> [Color]? {
        let renderer = ImageRenderer(content: image.resizable().scaledToFill().frame(width: 24, height: 24).clipped())
        renderer.scale = 1

        guard let cgImage = renderer.cgImage,
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * ImageDerivedGradientBackgroundMath.bytesPerPixel)
        let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * ImageDerivedGradientBackgroundMath.bytesPerPixel,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw else { return nil }

        let samples = ImageDerivedGradientBackgroundMath.bands(pixels: pixels, width: width, height: height, count: max(bands, 1))
        return samples.isEmpty ? nil : samples.map { Color(.sRGB, red: $0.red, green: $0.green, blue: $0.blue) }
    }
}

// MARK: - Demo

struct ImageDerivedGradientBackgroundDemo: View {
    @State private var photos = Self.makePhotos()
    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let photo = photos.isEmpty ? nil : photos[index % photos.count] {
                ImageDerivedGradientBackground(image: photo)

                photo
                    .resizable()
                    .scaledToFill()
                    .frame(width: 240, height: 240)
                    .clipShape(.rect(cornerRadius: 36, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 28, y: 16)
                    .id(index)
                    .transition(.opacity)
                    .accessibilityLabel("Placeholder photo")
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.8)) { index += 1 }
            }
        }
    }

    /// Stands in for real photos: gradients and symbols rendered into images.
    private static func makePhotos() -> [Image] {
        let scenes: [(colors: [Color], symbol: String)] = [
            ([.orange, .pink, .purple], "sun.horizon.fill"),
            ([.teal, .blue, .indigo], "water.waves"),
            ([.mint, .green, .teal], "leaf.fill"),
        ]

        return scenes.compactMap { scene in
            let content = ZStack {
                LinearGradient(colors: scene.colors, startPoint: .top, endPoint: .bottom)
                Image(systemName: scene.symbol)
                    .font(.system(size: 120))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 240, height: 240)

            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            return renderer.cgImage.map { Image(decorative: $0, scale: 2) }
        }
    }
}

#Preview {
    ImageDerivedGradientBackgroundDemo()
}
