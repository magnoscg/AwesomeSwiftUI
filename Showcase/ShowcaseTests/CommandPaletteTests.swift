// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

@Suite struct CommandPaletteTests {
    private func command(_ title: String, section: String, keywords: [String] = []) -> CommandPaletteCommand {
        CommandPaletteCommand(id: title, title: title, section: section, systemImage: "star", keywords: keywords) {}
    }

    private var commands: [CommandPaletteCommand] {
        [
            command("New Note", section: "Create"),
            command("Share", section: "Actions", keywords: ["export"]),
            command("New Folder", section: "Create"),
        ]
    }

    @Test func anEmptyQueryKeepsEveryCommandGrouped() {
        let groups = CommandPaletteFilter.groups(commands, query: "")

        #expect(groups.map(\.title) == ["Create", "Actions"])
        #expect(groups.first?.commands.map(\.title) == ["New Note", "New Folder"])
    }

    @Test func filtersByTitleIgnoringCase() {
        let groups = CommandPaletteFilter.groups(commands, query: "FOLD")

        #expect(groups.flatMap(\.commands).map(\.title) == ["New Folder"])
    }

    @Test func findsCommandsByKeyword() {
        let groups = CommandPaletteFilter.groups(commands, query: "export")

        #expect(groups.flatMap(\.commands).map(\.title) == ["Share"])
    }

    @Test func findsCommandsBySectionName() {
        let groups = CommandPaletteFilter.groups(commands, query: "actions")

        #expect(groups.flatMap(\.commands).map(\.title) == ["Share"])
    }

    @Test func aBlankQueryCountsAsEmpty() {
        let groups = CommandPaletteFilter.groups(commands, query: "   ")

        #expect(groups.flatMap(\.commands).count == 3)
    }

    @Test func noMatchesGivesNoGroups() {
        #expect(CommandPaletteFilter.groups(commands, query: "zzz").isEmpty)
    }

    @Test func noCommandsGivesNoGroups() {
        #expect(CommandPaletteFilter.groups([], query: "").isEmpty)
    }

    @Test func returnRunsTheCommandAtTheTopOfTheList() {
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "folder")?.id == "New Folder")
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "new")?.id == "New Note")
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "export")?.id == "Share")
    }

    @Test func returnDoesNothingWithoutAQueryOrAMatch() {
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "") == nil)
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "   ") == nil)
        #expect(CommandPaletteFilter.firstMatch(in: commands, query: "zzz") == nil)
    }
}
