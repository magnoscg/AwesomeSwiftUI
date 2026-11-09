// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Adds a search field with scope buttons and suggestion rows. Apply it inside a `NavigationStack`.
///
/// Tapping a suggestion fills in the field. The suggestions narrow as the person types.
struct SearchScopesAndSuggestions<Scope: Hashable>: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool
    @Binding var scope: Scope
    let scopes: [Scope]
    let scopeTitle: (Scope) -> String
    let suggestions: [String]
    var prompt: String = "Search"

    func body(content: Content) -> some View {
        content
            .searchable(text: $text, isPresented: $isPresented, prompt: prompt)
            .searchScopes($scope, activation: .onSearchPresentation) {
                ForEach(scopes, id: \.self) { scope in
                    Text(scopeTitle(scope)).tag(scope)
                }
            }
            .searchSuggestions {
                ForEach(SearchScopesAndSuggestionsMath.matches(in: suggestions, for: text), id: \.self) { suggestion in
                    Label(suggestion, systemImage: "magnifyingglass")
                        .searchCompletion(suggestion)
                }
            }
    }
}

enum SearchScopesAndSuggestionsMath {
    /// The suggestions worth showing: unique, containing the text, and not what is already typed.
    static func matches(in suggestions: [String], for text: String, limit: Int = 5) -> [String] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let unique = suggestions.filter { seen.insert($0).inserted }

        let matching = query.isEmpty
            ? unique
            : unique.filter { $0.localizedStandardContains(query) && $0.localizedCaseInsensitiveCompare(query) != .orderedSame }
        return Array(matching.prefix(max(limit, 0)))
    }
}

// MARK: - Demo

private enum SearchScopesAndSuggestionsDemoScope: String, CaseIterable {
    case all = "All"
    case fruit = "Fruit"
    case vegetable = "Vegetables"
}

private struct SearchScopesAndSuggestionsDemoProduce: Identifiable {
    var id: String { name }
    let name: String
    let symbol: String
    let scope: SearchScopesAndSuggestionsDemoScope
}

struct SearchScopesAndSuggestionsDemo: View {
    private let produce = [
        SearchScopesAndSuggestionsDemoProduce(name: "Apple", symbol: "apple.logo", scope: .fruit),
        SearchScopesAndSuggestionsDemoProduce(name: "Apricot", symbol: "leaf.fill", scope: .fruit),
        SearchScopesAndSuggestionsDemoProduce(name: "Grape", symbol: "circle.grid.3x3.fill", scope: .fruit),
        SearchScopesAndSuggestionsDemoProduce(name: "Papaya", symbol: "sun.max.fill", scope: .fruit),
        SearchScopesAndSuggestionsDemoProduce(name: "Asparagus", symbol: "leaf", scope: .vegetable),
        SearchScopesAndSuggestionsDemoProduce(name: "Bell pepper", symbol: "flame.fill", scope: .vegetable),
        SearchScopesAndSuggestionsDemoProduce(name: "Carrot", symbol: "carrot.fill", scope: .vegetable),
        SearchScopesAndSuggestionsDemoProduce(name: "Spinach", symbol: "leaf.circle.fill", scope: .vegetable),
    ]

    @State private var text = ""
    @State private var isSearching = false
    @State private var scope = SearchScopesAndSuggestionsDemoScope.all
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var results: [SearchScopesAndSuggestionsDemoProduce] {
        produce.filter { item in
            (scope == .all || item.scope == scope) && (text.isEmpty || item.name.localizedStandardContains(text))
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { item in
                Label(item.name, systemImage: item.symbol)
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: text)
                }
            }
            .navigationTitle("Market")
            .modifier(
                SearchScopesAndSuggestions(
                    text: $text,
                    isPresented: $isSearching,
                    scope: $scope,
                    scopes: SearchScopesAndSuggestionsDemoScope.allCases,
                    scopeTitle: \.rawValue,
                    suggestions: produce.map(\.name)
                )
            )
        }
        .task(id: reduceMotion) { await playDemo() }
    }

    /// Only for this demo: runs a few rounds so the search field is seen working, then leaves it to you.
    private func playDemo() async {
        guard !reduceMotion else { return }

        for _ in 0..<3 {
            let steps: [(seconds: Double, change: () -> Void)] = [
                (0.5, { isSearching = true }),
                (0.7, { text = "a" }),
                (0.7, { text = "ap" }),
                (0.8, { scope = .fruit }),
                (0.8, { text = ""; scope = .all; isSearching = false }),
            ]
            for step in steps {
                try? await Task.sleep(for: .seconds(step.seconds))
                guard !Task.isCancelled else { return }
                step.change()
            }
        }
    }
}

#Preview {
    SearchScopesAndSuggestionsDemo()
}
