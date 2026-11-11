// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum KaraokeLyricsTextMath {
    /// How much of each line has been sung, from 0 to 1, when `progress` of the whole text has.
    ///
    /// Lines fill in order and a wider line takes longer, so the light moves at one speed.
    static func fills(widths: [Double], progress: Double) -> [Double] {
        let lengths = widths.map { $0.isFinite ? max($0, 0) : 0 }
        let total = lengths.reduce(0, +)
        guard total > 0, progress.isFinite else { return Array(repeating: 0, count: widths.count) }

        var remaining = min(max(progress, 0), 1) * total
        return lengths.map { length in
            guard length > 0 else { return 0 }
            let sung = min(remaining, length)
            remaining -= sung
            return sung / length
        }
    }

    /// The same fills without the sweep: a line lights up whole as soon as it starts.
    static func wholeLines(_ fills: [Double]) -> [Double] {
        fills.map { $0 > 0 ? 1 : 0 }
    }
}

/// Lyrics that light up as they are sung: the text starts dim and a brighter copy sweeps over it.
///
/// Set `progress` from 0 to 1 and animate it over the time the line takes. The text keeps its font,
/// color and alignment, wraps like any other, and follows the direction of its language.
/// With Reduce Motion on, each line lights up at once instead of filling.
struct KaraokeLyricsText: View {
    let text: String
    /// How much of the text has been sung, from 0 to 1.
    var progress: Double
    /// The opacity of the part that has not been sung yet.
    var restOpacity: Double = 0.35

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .textRenderer(KaraokeLyricsTextRenderer(progress: progress, restOpacity: restOpacity, sweeps: !reduceMotion))
    }
}

struct KaraokeLyricsTextRenderer: TextRenderer {
    var progress: Double
    var restOpacity: Double
    var sweeps: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lines = Array(layout)
        let filled = KaraokeLyricsTextMath.fills(widths: lines.map { Double($0.typographicBounds.rect.width) }, progress: progress)
        let fills = sweeps ? filled : KaraokeLyricsTextMath.wholeLines(filled)

        for (line, fill) in zip(lines, fills) {
            var rest = context
            rest.opacity = min(max(restOpacity, 0), 1)
            rest.draw(line)

            guard fill > 0 else { continue }

            // The sung part starts where the line starts to be read, which is the right edge in a right-to-left script.
            let bounds = line.typographicBounds.rect
            let width = bounds.width * fill
            let startsAtRight = line.first?.layoutDirection == .rightToLeft
            let sung = CGRect(x: startsAtRight ? bounds.maxX - width : bounds.minX, y: bounds.minY, width: width, height: bounds.height)

            var bright = context
            bright.clip(to: Path(sung))
            bright.draw(line)
        }
    }
}

// MARK: - Demo

struct KaraokeLyricsTextDemo: View {
    private let lines = [
        "City lights are calling",
        "We run where the night begins",
        "Hold on to the echo",
        "Until the morning sings",
    ]
    private let secondsPerLine = 2.2

    @State private var current = 0
    @State private var progress = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Night Run", systemImage: "music.mic")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 8)

            ForEach(lines.indices, id: \.self) { index in
                KaraokeLyricsText(text: lines[index], progress: index < current ? 1 : (index == current ? progress : 0))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .task { await sing() }
    }

    private func sing() async {
        while !Task.isCancelled {
            for index in lines.indices {
                current = index
                progress = 0
                withAnimation(.linear(duration: secondsPerLine)) { progress = 1 }
                try? await Task.sleep(for: .seconds(secondsPerLine + 0.25))
                guard !Task.isCancelled else { return }
            }
            try? await Task.sleep(for: .seconds(0.8))
            current = 0
            progress = 0
        }
    }
}

#Preview {
    KaraokeLyricsTextDemo()
}
