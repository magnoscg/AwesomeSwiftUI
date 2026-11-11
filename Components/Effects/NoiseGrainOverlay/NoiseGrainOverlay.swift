// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A subtle film grain over any view: tiny light and dark specks redrawn a few times a second.
///
/// With Reduce Motion on, the grain is still.
struct NoiseGrainOverlay: ViewModifier {
    var intensity: Double = 0.16
    var grainSize: Double = 1.25
    var framesPerSecond: Double = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A tiny seeded generator: the same frame number always gives the same grain.
    private struct Generator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1 / framesPerSecond, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    let frame = reduceMotion ? 0 : UInt64(timeline.date.timeIntervalSinceReferenceDate * framesPerSecond)
                    drawGrain(frame: frame, in: context, size: size)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Every speck goes into one of two paths, so a frame is only two fills.
    private func drawGrain(frame: UInt64, in context: GraphicsContext, size: CGSize) {
        var generator = Generator(state: (frame &+ 1) &* 0x9E37_79B9_7F4A_7C15)
        var light = Path()
        var dark = Path()

        for index in 0..<min(Int(size.width * size.height / 18), 20_000) {
            let speck = CGRect(
                x: Double.random(in: 0..<max(size.width, 1), using: &generator),
                y: Double.random(in: 0..<max(size.height, 1), using: &generator),
                width: grainSize,
                height: grainSize
            )
            if index.isMultiple(of: 2) {
                light.addRect(speck)
            } else {
                dark.addRect(speck)
            }
        }

        context.fill(light, with: .color(.white.opacity(intensity)))
        context.fill(dark, with: .color(.black.opacity(intensity)))
    }
}

extension View {
    /// Adds a subtle animated film grain on top of this view.
    func noiseGrainOverlay(intensity: Double = 0.16, grainSize: Double = 1.25) -> some View {
        modifier(NoiseGrainOverlay(intensity: intensity, grainSize: grainSize))
    }
}

// MARK: - Demo

struct NoiseGrainOverlayDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .noiseGrainOverlay(intensity: 0.22)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "film")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Golden Hour")
                    .font(.system(.title, design: .serif, weight: .bold))
                Text("Grain takes the digital edge off flat color.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 260, alignment: .bottomLeading)
            .background(Color(red: 0.16, green: 0.12, blue: 0.3))
            .noiseGrainOverlay(intensity: 0.15)
            .clipShape(.rect(cornerRadius: 28))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
            .padding(28)
        }
    }
}

#Preview {
    NoiseGrainOverlayDemo()
}
