// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Picks the suggestions to show for what has been typed so far.
enum SearchFieldWithSuggestionsFilter {
    /// Ignores case and accents, lists prefix matches first and drops duplicates.
    /// Returns nothing for an empty query, or once the text is already a full suggestion.
    static func matches(for query: String, in suggestions: [String], limit: Int = 6) -> [String] {
        let needle = normalized(query)
        guard !needle.isEmpty, limit > 0 else { return [] }
        guard !suggestions.contains(where: { normalized($0) == needle }) else { return [] }

        var seen = Set<String>()
        let unique = suggestions.filter { seen.insert(normalized($0)).inserted }
        let prefix = unique.filter { normalized($0).hasPrefix(needle) }
        let inside = unique.filter { normalized($0).contains(needle) && !normalized($0).hasPrefix(needle) }
        return Array((prefix + inside).prefix(limit))
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// Lists matching suggestions under a search field as the person types.
/// Choosing one fills the field.
struct SearchFieldWithSuggestions: ViewModifier {
    @Binding var text: String
    let suggestions: [String]
    var placement: SearchFieldPlacement = .automatic
    var prompt = "Search"
    var limit = 6

    func body(content: Content) -> some View {
        content
            .searchable(text: $text, placement: placement, prompt: prompt)
            .searchSuggestions {
                ForEach(SearchFieldWithSuggestionsFilter.matches(for: text, in: suggestions, limit: limit), id: \.self) { suggestion in
                    Label(suggestion, systemImage: "magnifyingglass")
                        .searchCompletion(suggestion)
                }
            }
    }
}

extension View {
    /// Needs a navigation container, such as `NavigationStack`, to show the field.
    func searchFieldWithSuggestions(
        text: Binding<String>,
        suggestions: [String],
        placement: SearchFieldPlacement = .automatic,
        prompt: String = "Search",
        limit: Int = 6
    ) -> some View {
        modifier(SearchFieldWithSuggestions(text: text, suggestions: suggestions, placement: placement, prompt: prompt, limit: limit))
    }
}

// MARK: - Demo

struct SearchFieldWithSuggestionsDemo: View {
    private static let cities = ["Madrid", "Málaga", "Marseille", "Melbourne", "Lisbon", "London", "Seoul", "Oslo", "Kyoto"]

    @State private var text = ""
    @FocusState private var isSearching: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.teal.gradient)
                    .accessibilityHidden(true)
                Text(text.isEmpty ? "Where to?" : "Results for \(text)")
                    .font(.title2.bold())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(colors: [.teal.opacity(0.14), .blue.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("Cities")
            .searchFieldWithSuggestions(
                text: $text,
                suggestions: Self.cities,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search cities"
            )
            .searchFocused($isSearching)
            .task {
                // The field must be on screen before it can take focus.
                try? await Task.sleep(for: .seconds(0.4))
                guard !Task.isCancelled else { return }
                isSearching = true
            }
        }
    }
}

#Preview {
    SearchFieldWithSuggestionsDemo()
}
