// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A node of the tree. Ids must be unique across the whole tree.
struct DisclosureTreeViewNode: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var systemImage = "doc"
    var children: [DisclosureTreeViewNode] = []
}

/// The rows on screen: every node whose ancestors are all expanded, in order.
enum DisclosureTreeViewRows {
    struct Row: Identifiable, Equatable {
        let node: DisclosureTreeViewNode
        let depth: Int

        var id: String { node.id }
    }

    static func visible(in nodes: [DisclosureTreeViewNode], expanded: Set<String>, depth: Int = 0) -> [Row] {
        nodes.flatMap { node -> [Row] in
            let row = Row(node: node, depth: depth)
            guard expanded.contains(node.id) else { return [row] }
            return [row] + visible(in: node.children, expanded: expanded, depth: depth + 1)
        }
    }

    /// The indent of a row. Very deep rows and very large text stop adding to it, so the title has room.
    static func indent(depth: Int, step: Double) -> Double {
        Double(min(depth, 6)) * min(step, 24)
    }
}

/// A nested tree of rows that expand and collapse, indenting each level.
struct DisclosureTreeView: View {
    let nodes: [DisclosureTreeViewNode]
    @Binding var expandedIDs: Set<String>

    @ScaledMetric(relativeTo: .body) private var indent = 20.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 2) {
            ForEach(DisclosureTreeViewRows.visible(in: nodes, expanded: expandedIDs)) { row in
                rowView(row)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: DisclosureTreeViewRows.Row) -> some View {
        if row.node.children.isEmpty {
            rowLabel(row, isExpanded: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.node.title)
                .accessibilityValue("Level \(row.depth + 1)")
        } else {
            let isExpanded = expandedIDs.contains(row.id)

            Button {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
                    if isExpanded {
                        expandedIDs.remove(row.id)
                    } else {
                        expandedIDs.insert(row.id)
                    }
                }
            } label: {
                rowLabel(row, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(row.node.title)
            .accessibilityValue("\(isExpanded ? "Expanded" : "Collapsed"), level \(row.depth + 1)")
        }
    }

    private func rowLabel(_ row: DisclosureTreeViewRows.Row, isExpanded: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .opacity(row.node.children.isEmpty ? 0 : 1)
                .accessibilityHidden(true)

            Image(systemName: row.node.systemImage)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(row.node.title)
                .font(.body)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .padding(.leading, DisclosureTreeViewRows.indent(depth: row.depth, step: indent))
        .contentShape(.rect)
    }
}

// MARK: - Demo

struct DisclosureTreeViewDemo: View {
    private static let tree = [
        DisclosureTreeViewNode(id: "sources", title: "Sources", systemImage: "folder.fill", children: [
            DisclosureTreeViewNode(id: "components", title: "Components", systemImage: "folder.fill", children: [
                DisclosureTreeViewNode(id: "button", title: "Button.swift", systemImage: "swift"),
                DisclosureTreeViewNode(id: "card", title: "Card.swift", systemImage: "swift"),
            ]),
            DisclosureTreeViewNode(id: "app", title: "App.swift", systemImage: "swift"),
        ]),
        DisclosureTreeViewNode(id: "tests", title: "Tests", systemImage: "folder.fill", children: [
            DisclosureTreeViewNode(id: "buttontests", title: "ButtonTests.swift", systemImage: "checkmark.seal"),
        ]),
        DisclosureTreeViewNode(id: "readme", title: "README.md", systemImage: "doc.text"),
    ]

    @State private var expandedIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Project")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 12)

                DisclosureTreeView(nodes: Self.tree, expandedIDs: $expandedIDs)
                    .padding(.vertical, 8)
                    .background(.background, in: .rect(cornerRadius: 18, style: .continuous))
            }
            .padding(20)
        }
        .tint(.indigo)
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .blue.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    DisclosureTreeViewDemo()
}
