// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct CatalogView: View {
    let entries: [ShowcaseEntry]

    @State private var query = ""

    private var sections: [ShowcaseSection] {
        ShowcaseSearch.sections(in: entries, matching: query)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Awesome SwiftUI Components")
                .searchable(text: $query, prompt: "Name or keyword")
        }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            ContentUnavailableView(
                "No components yet",
                systemImage: "square.stack.3d.up.slash",
                description: Text("Components added to the catalog appear here.")
            )
        } else if sections.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(sections) { section in
                Section(section.category) {
                    ForEach(section.entries) { entry in
                        NavigationLink {
                            ComponentDetailView(entry: entry)
                        } label: {
                            CatalogRow(entry: entry)
                        }
                    }
                }
            }
        }
    }
}

private struct CatalogRow: View {
    let entry: ShowcaseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.headline)
            Text(entry.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("iOS \(entry.minIOS)+")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview("Empty") {
    CatalogView(entries: [])
}

#Preview("With entries") {
    CatalogView(entries: [
        ShowcaseEntry(
            id: "sample",
            title: "Sample",
            category: "Buttons",
            summary: "A placeholder entry.",
            keywords: ["sample"],
            minIOS: "18.0",
            demo: { AnyView(Text("Demo")) }
        ),
    ])
}
