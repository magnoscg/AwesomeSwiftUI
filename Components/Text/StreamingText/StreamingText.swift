// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum StreamingTextMath {
    /// How opaque a character is when `visible` of them have arrived: whole once the front has
    /// passed it by `fade` characters, clear ahead of the front and in between on the way.
    static func opacity(of index: Double, visible: Double, fade: Double) -> Double {
        guard fade > 0 else { return index < visible ? 1 : 0 }
        return min(max((visible - index) / fade, 0), 1)
    }

    /// How long the front takes to cross `characters`: short for a word, capped for a long
    /// chunk, so a burst of text never keeps the reader waiting.
    static func duration(for characters: Double, charactersPerSecond: Double, limit: ClosedRange<Double> = 0.15...1.5) -> Double {
        guard characters > 0, charactersPerSecond > 0 else { return limit.lowerBound }
        return min(max(characters / charactersPerSecond, limit.lowerBound), limit.upperBound)
    }

    /// How many characters two texts have in common at their start.
    static func sharedPrefix(_ first: String, _ second: String) -> Int {
        zip(first, second).prefix { $0 == $1 }.count
    }
}

/// Text that arrives in chunks, like the answer of a language model: every time `text` grows,
/// the new part fades in from its first letter to its last instead of popping in.
///
/// The speed evens out the chunks, so a burst of words reads as smoothly as a single one.
/// Text that is replaced rather than extended starts again from where the two differ.
/// With Reduce Motion on, new text shows at once.
struct StreamingText: View {
    let text: String
    var charactersPerSecond = 80.0
    /// How many characters the soft edge of the new text spans.
    var fade = 10.0

    @State private var visible = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .textRenderer(StreamingTextRenderer(visible: visible, characters: text.count, fade: fade, isInstant: reduceMotion))
            .onChange(of: text, initial: true) { old, new in
                let kept = Double(StreamingTextMath.sharedPrefix(old, new))
                if kept < Double(old.count) { visible = min(visible, kept) }

                // The front ends past the last character, so that one becomes whole too.
                let target = Double(new.count) + fade
                let duration = StreamingTextMath.duration(for: target - visible, charactersPerSecond: charactersPerSecond)
                withAnimation(.linear(duration: duration)) { visible = target }
            }
    }
}

struct StreamingTextRenderer: TextRenderer {
    var visible: Double
    var characters: Int
    var fade: Double
    var isInstant: Bool

    var animatableData: Double {
        get { visible }
        set { visible = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { line in line.flatMap { run in Array(run) } }
        // A character can be more than one glyph, or share one, so the glyphs are spread over the characters.
        let charactersPerSlice = slices.isEmpty ? 1 : Double(max(characters, 1)) / Double(slices.count)

        for (index, slice) in slices.enumerated() {
            let opacity = isInstant ? 1 : StreamingTextMath.opacity(of: Double(index) * charactersPerSlice, visible: visible, fade: fade)
            guard opacity > 0 else { continue }

            var copy = context
            copy.opacity = opacity
            copy.draw(slice)
        }
    }
}

// MARK: - Demo

struct StreamingTextDemo: View {
    private let answer = "Sourdough needs time more than effort. Mix flour, water, salt and a spoonful of starter in the evening, fold the dough a few times before bed, and let it rise overnight. In the morning, shape it, rest it for an hour and bake it in a hot pot with the lid on. The crust comes out crisp and the crumb stays open and soft."

    @State private var text = ""
    @State private var run = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How do I bake sourdough?")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(.blue, in: .rect(cornerRadius: 20))
                .frame(maxWidth: .infinity, alignment: .trailing)

            StreamingText(text: text)
                .font(.body)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Ask Again", systemImage: "arrow.clockwise") {
                run += 1
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .task(id: run) {
            // Stands in for a model that sends a few words at a time, at an uneven pace.
            text = ""
            var words = answer.split(separator: " ")[...]
            while !words.isEmpty, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 120...380)))
                let chunk = words.prefix(Int.random(in: 2...6))
                words = words.dropFirst(chunk.count)
                if !Task.isCancelled { text += (text.isEmpty ? "" : " ") + chunk.joined(separator: " ") }
            }
        }
    }
}

#Preview {
    StreamingTextDemo()
}
