// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A round magnifying glass button that opens into a search field.
/// Closing it clears the text and dismisses the keyboard.
///
/// With Reduce Motion on, the field appears without animating.
struct ExpandingSearchButton: View {
    @Binding var text: String
    var prompt: LocalizedStringResource = "Search"
    var onSubmit: () -> Void = {}

    @State private var isExpanded = false
    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var height = 54.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.25)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                open()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.headline)
                    .frame(width: height, height: height)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")

            if isExpanded {
                TextField(text: $text) { Text(prompt) }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                    .onAppear { isFocused = true }
                    .transition(.opacity)

                Button {
                    close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: height, height: height)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .transition(.opacity)
            }
        }
        .frame(maxWidth: isExpanded ? .infinity : height)
        .background(.regularMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(.quaternary))
    }

    private func open() {
        if isExpanded {
            isFocused = true
        } else {
            withAnimation(animation) { isExpanded = true }
        }
    }

    private func close() {
        text = ""
        isFocused = false
        withAnimation(animation) { isExpanded = false }
    }
}

// MARK: - Demo

struct ExpandingSearchButtonDemo: View {
    private struct Row: Identifiable {
        let id: String
        let systemImage: String
    }

    @State private var text = ""

    private let rows = [
        Row(id: "Albums", systemImage: "square.stack.fill"),
        Row(id: "Artists", systemImage: "music.mic"),
        Row(id: "Playlists", systemImage: "music.note.list"),
        Row(id: "Podcasts", systemImage: "antenna.radiowaves.left.and.right"),
        Row(id: "Radio", systemImage: "dot.radiowaves.left.and.right"),
    ]

    private var visibleRows: [Row] {
        text.isEmpty ? rows : rows.filter { $0.id.localizedStandardContains(text) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 16) {
                Text("Library")
                    .font(.largeTitle.bold())
                    .fixedSize()
                ExpandingSearchButton(text: $text)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 22) {
                ForEach(visibleRows) { row in
                    Label(row.id, systemImage: row.systemImage)
                        .font(.title3)
                }
            }

            if visibleRows.isEmpty {
                ContentUnavailableView.search(text: text)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ExpandingSearchButtonDemo()
}
