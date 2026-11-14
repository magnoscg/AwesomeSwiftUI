// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Types its text one character at a time, followed by a blinking cursor.
///
/// It restarts when `text` changes. With Reduce Motion on, the text appears in full with no cursor.
struct TypewriterText: View {
    let text: String
    var charactersPerSecond: Double = 20
    var cursorColor: Color = .accentColor

    @State private var started: (text: String, date: Date)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            Text(typed(at: context.date))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .task(id: text) { started = (text, .now) }
    }

    /// The characters not typed yet stay in the string as clear text, so lines wrap once and never jump.
    private func typed(at date: Date) -> AttributedString {
        guard !reduceMotion else { return AttributedString(text) }

        let elapsed = started.flatMap { $0.text == text ? date.timeIntervalSince($0.date) : nil } ?? 0
        let count = TypewriterTextProgress.visibleCount(
            elapsed: elapsed,
            charactersPerSecond: charactersPerSecond,
            total: text.count
        )
        let isTyping = count < text.count

        var cursor = AttributedString("|")
        cursor.foregroundColor = isTyping || Int(elapsed * 2).isMultiple(of: 2) ? cursorColor : .clear

        var remaining = AttributedString(String(text.dropFirst(count)))
        remaining.foregroundColor = .clear

        return AttributedString(String(text.prefix(count))) + cursor + remaining
    }
}

enum TypewriterTextProgress {
    /// How many characters are visible after `elapsed` seconds, from 0 to `total`.
    static func visibleCount(elapsed: TimeInterval, charactersPerSecond: Double, total: Int) -> Int {
        guard total > 0 else { return 0 }
        guard charactersPerSecond > 0 else { return total }

        let typed = (elapsed * charactersPerSecond).rounded(.down)
        guard typed > 0 else { return 0 }
        return typed >= Double(total) ? total : Int(typed)
    }
}

// MARK: - Demo

struct TypewriterTextDemo: View {
    @State private var index = 0

    private let lines = [
        "$ swift build\nCompiling your ideas...",
        "$ swift test\nAll tests passed, no bugs today.",
        "$ git push\nShipped before lunch.",
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    ForEach([Color.red, .yellow, .green], id: \.self) { color in
                        Circle().fill(color).frame(width: 12, height: 12)
                    }
                }
                .accessibilityHidden(true)

                TypewriterText(text: lines[index], cursorColor: .green)
                    .font(.system(.title2, design: .monospaced, weight: .medium))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            }
            .padding(24)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 20))
            .padding(20)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.2))
                index = (index + 1) % lines.count
            }
        }
    }
}

#Preview {
    TypewriterTextDemo()
}
