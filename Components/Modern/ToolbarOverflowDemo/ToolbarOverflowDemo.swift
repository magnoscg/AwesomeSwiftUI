// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

@available(iOS 27, *)
struct ToolbarOverflowDemoAction: Identifiable {
    let title: String
    let systemImage: String
    var priority: ToolbarItemVisibilityPriority = .automatic
    let perform: () -> Void

    var id: String { title }
}

/// A navigation screen that ranks which toolbar actions survive when space runs out.
///
/// `barActions` leave the bar lowest priority first. `overflowActions` always live in the menu.
/// The title is large, under the bar, where the actions cannot push it out.
@available(iOS 27, *)
struct ToolbarOverflowDemo<Content: View>: View {
    let title: LocalizedStringResource
    let barActions: [ToolbarOverflowDemoAction]
    let overflowActions: [ToolbarOverflowDemoAction]
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .toolbarTitleDisplayMode(.large)
                .toolbar {
                    ForEach(barActions) { action in
                        ToolbarItem(placement: .primaryAction) {
                            button(for: action)
                        }
                        .visibilityPriority(action.priority)
                    }

                    ToolbarOverflowMenu {
                        ForEach(overflowActions, content: button(for:))
                    }
                }
        }
    }

    private func button(for action: ToolbarOverflowDemoAction) -> some View {
        Button(action.title, systemImage: action.systemImage, action: action.perform)
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct ToolbarOverflowDemoDemo: View {
    @State private var lastAction = "Pick an action"

    private func action(
        _ title: String,
        _ systemImage: String,
        _ priority: ToolbarItemVisibilityPriority = .automatic
    ) -> ToolbarOverflowDemoAction {
        ToolbarOverflowDemoAction(title: title, systemImage: systemImage, priority: priority) { lastAction = title }
    }

    var body: some View {
        ToolbarOverflowDemo(
            title: "Draft",
            barActions: [
                action("Share", "square.and.arrow.up", .high),
                action("Flag", "flag", .low),
                action("Comment", "text.bubble"),
                action("Tag", "tag"),
                action("Archive", "archivebox", .low),
                action("Bookmark", "bookmark", .high),
                action("Pin", "pin", .high),
            ],
            overflowActions: [
                action("Duplicate", "plus.square.on.square"),
                action("Export as PDF", "doc.richtext"),
                action("Print", "printer"),
            ]
        ) {
            ZStack {
                LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .toolbarColorScheme(.dark, for: .navigationBar)

                Text(lastAction)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: lastAction)
            }
        }
    }
}

@available(iOS 27, *)
#Preview {
    ToolbarOverflowDemoDemo()
}
