// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Words that take turns in the same spot, each one pushing the last out of the way.
///
/// It reserves the width of the longest word, so nothing around it moves.
/// With Reduce Motion on, the words crossfade.
struct RotatingWordsText: View {
    let words: [String]
    /// Seconds each word stays on screen.
    var interval: Double = 1.6

    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .push(from: .bottom)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(words.indices, id: \.self) { position in
                Text(words[position]).hidden()
            }

            if !words.isEmpty {
                Text(words[index % words.count])
                    .id(index)
                    .transition(transition)
            }
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(words.joined(separator: ", "))
        .task(id: words) { await rotate() }
    }

    private func rotate() async {
        guard words.count > 1 else { return }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }

            withAnimation(.snappy(duration: 0.45)) {
                index = (index + 1) % words.count
            }
        }
    }
}

// MARK: - Demo

struct RotatingWordsTextDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.12), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 4) {
                Text("Made for")
                    .foregroundStyle(.white)

                RotatingWordsText(words: ["designers", "developers", "dreamers", "everyone"], interval: 1.2)
                    .foregroundStyle(.linearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
            }
            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            .padding(32)
        }
    }
}

#Preview {
    RotatingWordsTextDemo()
}
