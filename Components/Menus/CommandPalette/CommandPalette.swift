// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct CommandPaletteCommand: Identifiable {
    let id: String
    let title: String
    let section: String
    let systemImage: String
    /// A hint only, such as "⌘N".
    var shortcut: String?
    /// Extra words that find this command, such as synonyms.
    var keywords: [String] = []
    let action: () -> Void
}

struct CommandPaletteGroup: Identifiable {
    let title: String
    let commands: [CommandPaletteCommand]

    var id: String { title }
}

enum CommandPaletteFilter {
    /// Commands matching the query, grouped by section in the order they first appear.
    static func groups(_ commands: [CommandPaletteCommand], query: String) -> [CommandPaletteGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = commands.filter { command in
            trimmed.isEmpty || ([command.title, command.section] + command.keywords)
                .contains { $0.localizedStandardContains(trimmed) }
        }

        var titles: [String] = []
        var bySection: [String: [CommandPaletteCommand]] = [:]
        for command in matches {
            if bySection[command.section] == nil { titles.append(command.section) }
            bySection[command.section, default: []].append(command)
        }
        return titles.map { CommandPaletteGroup(title: $0, commands: bySection[$0] ?? []) }
    }

    /// The command at the top of the list for a query, which Return runs. Nothing for an empty query.
    static func firstMatch(in commands: [CommandPaletteCommand], query: String) -> CommandPaletteCommand? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return groups(commands, query: query).first?.commands.first
    }
}

/// A searchable list of commands, filtered as you type. Show it in a sheet.
///
/// The search field takes focus when it appears, and Return runs the first match.
/// Running a command closes the sheet first.
struct CommandPalette: View {
    let commands: [CommandPaletteCommand]

    @State private var query = ""
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var iconSize = 32.0

    private var groups: [CommandPaletteGroup] {
        CommandPaletteFilter.groups(commands, query: query)
    }

    var body: some View {
        NavigationStack {
            List(groups) { group in
                Section(group.title) {
                    ForEach(group.commands, content: row)
                }
            }
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Commands")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Type a command"
            )
            // Return runs the first match, as in a command palette on a keyboard.
            .onSubmit(of: .search) {
                if let first = CommandPaletteFilter.firstMatch(in: commands, query: query) { run(first) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { isSearching = true }
    }

    private func row(_ command: CommandPaletteCommand) -> some View {
        Button {
            run(command)
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    titleLabel(command)
                    Spacer(minLength: 12)
                    shortcutChip(command.shortcut)
                }
                titleLabel(command)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(command.title)
    }

    private func run(_ command: CommandPaletteCommand) {
        dismiss()
        command.action()
    }

    private func titleLabel(_ command: CommandPaletteCommand) -> some View {
        HStack(spacing: 12) {
            Image(systemName: command.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: iconSize, height: iconSize)
                .background(.tint.opacity(0.14), in: .rect(cornerRadius: 8))
                .accessibilityHidden(true)

            Text(command.title).font(.body)
        }
    }

    @ViewBuilder
    private func shortcutChip(_ shortcut: String?) -> some View {
        if let shortcut {
            Text(shortcut)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.fill.tertiary, in: .rect(cornerRadius: 6))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Demo

struct CommandPaletteDemo: View {
    @State private var isOpen = false
    @State private var lastCommand = "Nothing yet"

    private var commands: [CommandPaletteCommand] {
        [
            command("New Note", section: "Create", image: "square.and.pencil", shortcut: "⌘N"),
            command("New Folder", section: "Create", image: "folder.badge.plus", shortcut: "⇧⌘N"),
            command("Share Note", section: "Actions", image: "square.and.arrow.up", shortcut: "⌘S"),
            command("Duplicate", section: "Actions", image: "plus.square.on.square", shortcut: "⌘D"),
            command("Delete", section: "Actions", image: "trash", shortcut: "⌫"),
            command("Settings", section: "Go to", image: "gearshape", shortcut: "⌘,"),
            command("Trash", section: "Go to", image: "trash.circle"),
            command("Help", section: "Go to", image: "questionmark.circle", shortcut: "⌘?"),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text(lastCommand)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button {
                    isOpen = true
                } label: {
                    Label("Open commands", systemImage: "command")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.white, in: .capsule)
                        .foregroundStyle(.indigo)
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isOpen) {
            CommandPalette(commands: commands)
        }
    }

    private func command(_ title: String, section: String, image: String, shortcut: String? = nil) -> CommandPaletteCommand {
        CommandPaletteCommand(id: title, title: title, section: section, systemImage: image, shortcut: shortcut) {
            lastCommand = title
        }
    }
}

#Preview {
    CommandPaletteDemo()
}
