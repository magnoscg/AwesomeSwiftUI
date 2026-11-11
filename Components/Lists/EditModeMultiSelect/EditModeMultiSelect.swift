// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A list with a Select mode: selection circles on each row and a bottom bar of bulk actions.
///
/// Place it inside a `NavigationStack`, because Select and Done go in the toolbar.
/// With Reduce Motion on, the bar appears without sliding.
struct EditModeMultiSelect<Row: Identifiable, RowContent: View, Actions: View>: View {
    let rows: [Row]
    @Binding var selection: Set<Row.ID>
    @ViewBuilder var rowContent: (Row) -> RowContent
    /// The bulk actions. They are disabled while nothing is selected.
    @ViewBuilder var actions: () -> Actions

    @State private var editMode: EditMode = .inactive
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isEditing: Bool { editMode.isEditing }
    private var allSelected: Bool { !rows.isEmpty && selection.count >= rows.count }

    var body: some View {
        List(rows, selection: $selection) { row in
            rowContent(row)
        }
        .environment(\.editMode, $editMode)
        .overlay {
            if rows.isEmpty {
                ContentUnavailableView("Nothing here", systemImage: "tray")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isEditing {
                bulkBar.transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Select") { setEditing(!isEditing) }
                    .disabled(rows.isEmpty && !isEditing)
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button(allSelected ? "Deselect All" : "Select All", action: toggleAll)
                }
            }
        }
        .onChange(of: rows.map(\.id)) { _, ids in
            selection.formIntersection(ids)
            if ids.isEmpty { setEditing(false) }
        }
    }

    private var bulkBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                selectedCount
                Spacer(minLength: 0)
                actionRow
            }
            VStack(spacing: 10) {
                selectedCount
                actionRow
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var selectedCount: some View {
        Text("\(selection.count) selected")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
    }

    private var actionRow: some View {
        HStack(spacing: 20) { actions() }
            .disabled(selection.isEmpty)
    }

    private func setEditing(_ editing: Bool) {
        withAnimation(reduceMotion ? nil : .snappy) {
            editMode = editing ? .active : .inactive
            if !editing { selection.removeAll() }
        }
    }

    private func toggleAll() {
        selection = allSelected ? [] : Set(rows.map(\.id))
    }
}

// MARK: - Demo

private struct EditModeMultiSelectDemoMail: Identifiable {
    let id: String
    let subtitle: String
    let systemImage: String
    let tint: Color
}

struct EditModeMultiSelectDemo: View {
    @State private var mails = [
        EditModeMultiSelectDemoMail(id: "Flights", subtitle: "Your boarding pass is ready", systemImage: "airplane", tint: .blue),
        EditModeMultiSelectDemoMail(id: "Receipts", subtitle: "Thanks for your order", systemImage: "cart.fill", tint: .green),
        EditModeMultiSelectDemoMail(id: "Newsletter", subtitle: "Five things to read this week", systemImage: "newspaper.fill", tint: .orange),
        EditModeMultiSelectDemoMail(id: "Calendar", subtitle: "Design review moved to 10:30", systemImage: "calendar", tint: .red),
        EditModeMultiSelectDemoMail(id: "Photos", subtitle: "12 new shared photos", systemImage: "photo.fill", tint: .purple),
        EditModeMultiSelectDemoMail(id: "Banking", subtitle: "Your statement is available", systemImage: "creditcard.fill", tint: .teal),
        EditModeMultiSelectDemoMail(id: "Podcasts", subtitle: "A new episode just landed", systemImage: "mic.fill", tint: .pink),
        EditModeMultiSelectDemoMail(id: "Fitness", subtitle: "You closed all your rings", systemImage: "figure.run", tint: .mint),
    ]
    @State private var selection = Set<String>()
    @ScaledMetric(relativeTo: .headline) private var iconSize = 40.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            EditModeMultiSelect(rows: mails, selection: $selection) { mail in
                HStack(spacing: 14) {
                    Image(systemName: mail.systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: iconSize, height: iconSize)
                        .background(mail.tint.gradient, in: .rect(cornerRadius: 11))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mail.id).font(.headline)
                        Text(mail.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .accessibilityElement(children: .combine)
            } actions: {
                Button("Archive", systemImage: "archivebox", action: removeSelected)
                Button("Delete", systemImage: "trash", role: .destructive, action: removeSelected)
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func removeSelected() {
        withAnimation(reduceMotion ? nil : .default) {
            mails.removeAll { selection.contains($0.id) }
        }
    }
}

#Preview {
    EditModeMultiSelectDemo()
}
