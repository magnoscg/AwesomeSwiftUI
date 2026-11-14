// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Text with every match of a search query highlighted, ignoring case and accents.
struct HighlightedSearchText: View {
    let text: String
    let query: String
    var highlightColor: Color = .yellow
    var highlightedTextColor: Color = .black

    var body: some View {
        Text(HighlightedSearchTextMatcher.highlighted(
            text,
            query: query,
            background: highlightColor,
            foreground: highlightedTextColor
        ))
    }
}

enum HighlightedSearchTextMatcher {
    /// The non-overlapping matches of `query` in `text`, from first to last.
    static func matches(of query: String, in text: String) -> [Range<String.Index>] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }

        var found: [Range<String.Index>] = []
        var searchStart = text.startIndex

        while let match = text.range(
            of: needle,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchStart..<text.endIndex
        ), !match.isEmpty {
            found.append(match)
            searchStart = match.upperBound
        }
        return found
    }

    static func highlighted(_ text: String, query: String, background: Color, foreground: Color) -> AttributedString {
        var result = AttributedString(text)

        for match in matches(of: query, in: text) {
            guard let range = Range(match, in: result) else { continue }
            result[range].backgroundColor = background
            result[range].foregroundColor = foreground
        }
        return result
    }
}

// MARK: - Demo

struct HighlightedSearchTextDemo: View {
    @State private var query = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let queries = ["cafe", "MANANA", "nino"]
    private let passage = """
    El café de la mañana sabe mejor. Un CAFE largo, una cafetería pequeña \
    y un niño que pide más café. Mañana volverá el NIÑO a la misma cafeteria.
    """

    private var matchCount: Int {
        HighlightedSearchTextMatcher.matches(of: query, in: passage).count
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint, .teal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .accessibilityHidden(true)
                    Text(query.isEmpty ? "Search" : query)
                        .foregroundStyle(query.isEmpty ? .secondary : .primary)
                    Spacer()
                    Text("\(matchCount) found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .font(.title3)
                .padding(14)
                .background(.thinMaterial, in: .capsule)

                HighlightedSearchText(text: passage, query: query)
                    .font(.title2)
                    .lineSpacing(6)
            }
            .padding(24)
            .background(.regularMaterial, in: .rect(cornerRadius: 28))
            .padding(20)
        }
        .task { await typeQueries() }
    }

    /// Stands in for someone typing into a search field.
    private func typeQueries() async {
        guard !reduceMotion else {
            query = "cafe"
            return
        }

        while !Task.isCancelled {
            for word in queries {
                for count in 0...word.count {
                    query = String(word.prefix(count))
                    try? await Task.sleep(for: .seconds(0.11))
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

#Preview {
    HighlightedSearchTextDemo()
}
