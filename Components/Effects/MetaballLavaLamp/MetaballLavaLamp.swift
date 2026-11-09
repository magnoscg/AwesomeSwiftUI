// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Round blobs that merge and separate like a lava lamp.
///
/// The blobs are blurred and then cut at half their opacity, so two blobs that
/// touch join with a smooth neck. With Reduce Motion on, it shows a still frame.
struct MetaballLavaLamp: View {
    var blobCount = 7
    var colors: [Color] = [.red, .orange, .yellow]
    var speed = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LinearGradient(colors: colors.isEmpty ? [.orange] : colors, startPoint: .bottom, endPoint: .top)
            .mask {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                    let time = reduceMotion ? 12 : context.date.timeIntervalSinceReferenceDate * max(speed, 0)

                    Canvas { canvas, size in
                        let side = min(size.width, size.height)
                        guard side > 0 else { return }

                        canvas.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        canvas.addFilter(.blur(radius: max(1, side * 0.05)))
                        canvas.drawLayer { layer in
                            for blob in MetaballLavaLampMath.blobs(count: blobCount, time: time, size: size) {
                                layer.fill(Path(ellipseIn: blob), with: .color(.white))
                            }
                        }
                    }
                }
            }
            .accessibilityHidden(true)
    }
}

enum MetaballLavaLampMath {
    /// The frames of the rising blobs, plus a pool of wax at the top and at the bottom.
    static func blobs(count: Int, time: Double, size: CGSize) -> [CGRect] {
        guard size.width > 0, size.height > 0 else { return [] }
        let width = size.width
        let height = size.height

        var frames = [
            CGRect(x: -width * 0.1, y: height * 0.9, width: width * 1.2, height: height * 0.25),
            CGRect(x: -width * 0.1, y: -height * 0.17, width: width * 1.2, height: height * 0.25),
        ]

        for index in 0..<min(max(count, 0), 48) {
            let seed = Double(index)
            let radius = width * (0.1 + 0.09 * unit(seed * 0.618 + 0.2))
            let rate = 0.28 + 0.2 * unit(seed * 0.37 + 0.5)
            let x = width * (0.5 + 0.32 * sin(time * 0.21 + seed * 1.7))
            let y = height * (0.5 + 0.47 * sin(time * rate + seed * 2.4))
            frames.append(CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
        return frames
    }

    /// A smooth value from 0 to 1 that differs from one blob to the next.
    private static func unit(_ value: Double) -> Double {
        (sin(value * 12.9) + 1) / 2
    }
}

// MARK: - Demo

struct MetaballLavaLampDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.03, blue: 0.3), Color(red: 0.07, green: 0.02, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )

            MetaballLavaLamp(blobCount: 9, colors: [.red, .orange, .pink], speed: 1.6)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MetaballLavaLampDemo()
}
