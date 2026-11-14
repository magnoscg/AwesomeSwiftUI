// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct StickySectionHeadersGroup<Element: Identifiable>: Identifiable {
    let title: String
    let elements: [Element]

    /// Titles identify the groups, so keep them unique.
    var id: String { title }
}

/// A scrolling list whose section headers pin to the top until the next one pushes them off.
struct StickySectionHeaders<Element: Identifiable, Row: View>: View {
    let groups: [StickySectionHeadersGroup<Element>]
    var tint: Color = .accentColor
    @ViewBuilder var row: (Element) -> Row

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.elements, content: row)
                    } header: {
                        header(group.title)
                    }
                }
            }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(tint)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Demo

private struct StickySectionHeadersDemoContact: Identifiable {
    let name: String
    var id: String { name }
}

struct StickySectionHeadersDemo: View {
    @ScaledMetric(relativeTo: .body) private var avatarSize = 42.0

    private let groups: [StickySectionHeadersGroup<StickySectionHeadersDemoContact>] = [
        ("A", ["Ada Byron", "Alan Turing", "Alice Ball", "Amelia Earhart", "Anita Borg"]),
        ("B", ["Barbara Liskov", "Blaise Pascal", "Bob Kahn", "Brian Kernighan", "Bjarne Stroustrup"]),
        ("C", ["Carl Sagan", "Charles Babbage", "Chien-Shiung Wu", "Claude Shannon", "Cecilia Payne"]),
        ("D", ["Dennis Ritchie", "Donald Knuth", "Dorothy Vaughan", "Douglas Engelbart", "Dian Fossey"]),
        ("E", ["Edsger Dijkstra", "Emmy Noether", "Enrico Fermi", "Erwin Schrodinger", "Euclid"]),
    ].map { title, names in
        StickySectionHeadersGroup(title: title, elements: names.map(StickySectionHeadersDemoContact.init))
    }

    var body: some View {
        NavigationStack {
            StickySectionHeaders(groups: groups, tint: .indigo) { contact in
                HStack(spacing: 14) {
                    Text(String(contact.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .background(.indigo.gradient, in: .circle)
                        .accessibilityHidden(true)

                    Text(contact.name).font(.body)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StickySectionHeadersDemo()
}
