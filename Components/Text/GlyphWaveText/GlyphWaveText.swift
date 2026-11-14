// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Text whose glyphs ride a travelling sine wave.
///
/// With Reduce Motion on, the text sits still on its baseline.
struct GlyphWaveText: View {
    let text: String
    /// Full waves per second.
    var speed: Double = 0.8

    @ScaledMetric(relativeTo: .largeTitle) private var amplitude = 12.0
    @ScaledMetric(relativeTo: .largeTitle) private var wavelength = 170.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
            Text(text)
                .textRenderer(GlyphWaveTextRenderer(
                    phase: context.date.timeIntervalSinceReferenceDate * speed * 2 * .pi,
                    amplitude: reduceMotion ? 0 : amplitude,
                    wavelength: wavelength
                ))
        }
    }
}

struct GlyphWaveTextRenderer: TextRenderer {
    var phase: Double
    var amplitude: Double
    var wavelength: Double

    /// Room for the glyphs that rise or fall outside the text's own frame.
    var displayPadding: EdgeInsets {
        EdgeInsets(top: amplitude, leading: 0, bottom: amplitude, trailing: 0)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for glyph in run {
                    let position = glyph.typographicBounds.rect.midX / wavelength * 2 * .pi

                    var glyphContext = context
                    glyphContext.translateBy(x: 0, y: sin(position - phase) * amplitude)
                    glyphContext.draw(glyph)
                }
            }
        }
    }
}

// MARK: - Demo

struct GlyphWaveTextDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            Image(systemName: "water.waves")
                .resizable()
                .scaledToFit()
                .fontWeight(.ultraLight)
                .padding(40)
                .foregroundStyle(.white.opacity(0.14))
                .accessibilityHidden(true)

            GlyphWaveText(text: "Riding the\nsine wave")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(18)
        }
    }
}

#Preview {
    GlyphWaveTextDemo()
}
