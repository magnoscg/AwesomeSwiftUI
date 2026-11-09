// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Reveals text line by line: each line fades in, comes into focus and slides up.
///
/// Animate `progress` from 0 to 1 with `withAnimation`. With Reduce Motion on, the text is shown in full.
struct TextBlurReveal: View {
    let text: String
    var progress: Double = 1

    @ScaledMetric(relativeTo: .title) private var blurRadius = 12.0
    @ScaledMetric(relativeTo: .title) private var rise = 18.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .textRenderer(TextBlurRevealRenderer(
                progress: reduceMotion ? 1 : progress,
                blurRadius: blurRadius,
                rise: rise
            ))
    }
}

struct TextBlurRevealRenderer: TextRenderer {
    var progress: Double
    var blurRadius: Double
    var rise: Double

    /// How much of each line's animation overlaps with the next one.
    private let overlap = 0.55

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Room for the blur and the slide, which draw outside the text's own frame.
    var displayPadding: EdgeInsets {
        let margin = blurRadius * 2
        return EdgeInsets(top: margin, leading: margin, bottom: margin + rise, trailing: margin)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for (index, line) in layout.enumerated() {
            let reveal = lineProgress(index: index, count: layout.count)

            var lineContext = context
            lineContext.opacity = reveal
            lineContext.addFilter(.blur(radius: (1 - reveal) * blurRadius))
            lineContext.translateBy(x: 0, y: (1 - reveal) * rise)
            lineContext.draw(line)
        }
    }

    private func lineProgress(index: Int, count: Int) -> Double {
        let step = 1 - overlap
        let lineDuration = 1 / (Double(count - 1) * step + 1)
        let lineStart = Double(index) * step * lineDuration
        return min(max((progress - lineStart) / lineDuration, 0), 1)
    }
}

// MARK: - Demo

struct TextBlurRevealDemo: View {
    @State private var progress = 0.0

    private let poem = """
    The morning arrives
    without asking anyone,
    one quiet line
    after another,
    until the page is full.
    """

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TextBlurReveal(text: poem, progress: progress)
                .font(.system(.title, design: .serif, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(32)
        }
        .task {
            while !Task.isCancelled {
                withAnimation(.easeOut(duration: 2.2)) { progress = 1 }
                try? await Task.sleep(for: .seconds(3.4))
                progress = 0
                try? await Task.sleep(for: .seconds(0.2))
            }
        }
    }
}

#Preview {
    TextBlurRevealDemo()
}
