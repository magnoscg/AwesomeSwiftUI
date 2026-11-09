// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Random characters that settle, left to right, into the final text.
///
/// It plays again when `text` changes. With Reduce Motion on, the text appears directly.
struct ScrambleText: View {
    let text: String
    var duration: Double = 1.2
    var characters: [Character] = ScrambleTextScrambler.defaultCharacters

    @State private var displayed: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(displayed ?? text)
            .monospaced()
            .opacity(displayed == nil ? 0 : 1)
            .accessibilityLabel(text)
            .task(id: text) { await play() }
    }

    private func play() async {
        guard !reduceMotion else {
            displayed = text
            return
        }

        var generator = SystemRandomNumberGenerator()
        let steps = max(Int(duration * 30), 1)

        for step in 0...steps {
            guard !Task.isCancelled else { return }
            displayed = ScrambleTextScrambler.scrambled(
                text,
                progress: Double(step) / Double(steps),
                characters: characters,
                using: &generator
            )
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
        }
    }
}

enum ScrambleTextScrambler {
    static let defaultCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&*@")

    /// Keeps the first `progress` share of `text` and replaces the rest with random
    /// characters. Whitespace is kept, so words hold their shape and lines wrap the same.
    static func scrambled(
        _ text: String,
        progress: Double,
        characters: [Character] = defaultCharacters,
        using generator: inout some RandomNumberGenerator
    ) -> String {
        let letters = Array(text)
        let clamped = progress > 0 ? min(progress, 1) : 0
        let settled = Int(clamped * Double(letters.count))

        var result = ""
        for (index, letter) in letters.enumerated() {
            let isSettled = index < settled || letter.isWhitespace
            result.append(isSettled ? letter : characters.randomElement(using: &generator) ?? letter)
        }
        return result
    }
}

// MARK: - Demo

struct ScrambleTextDemo: View {
    @State private var index = 0

    private let phrases = ["ACCESS GRANTED", "DECRYPTING DATA", "SIGNAL ACQUIRED"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0, green: 0.16, blue: 0.12), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.open.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                ScrambleText(text: phrases[index])
                    .font(.largeTitle.bold())
            }
            .foregroundStyle(.mint)
            .multilineTextAlignment(.center)
            .padding(24)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                index = (index + 1) % phrases.count
            }
        }
    }
}

#Preview {
    ScrambleTextDemo()
}
