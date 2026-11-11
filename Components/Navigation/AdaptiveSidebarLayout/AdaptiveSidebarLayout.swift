// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A split layout driven by one Boolean: the sidebar is either showing or it is not.
///
/// On iPad the toolbar button collapses the view to the detail alone. On iPhone the same
/// value decides whether the sidebar or the detail is on top of the stack.
struct AdaptiveSidebarLayout<Sidebar: View, Detail: View>: View {
    @Binding var showsSidebar: Bool
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let detail: () -> Detail

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationSplitView(
            columnVisibility: columnVisibility,
            preferredCompactColumn: compactColumn
        ) {
            sidebar()
                .toolbar(removing: .sidebarToggle)
        } detail: {
            detail()
                .toolbar {
                    // On iPhone the system back button already does this job.
                    if horizontalSizeClass == .regular {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(showsSidebar ? "Hide sidebar" : "Show sidebar", systemImage: "sidebar.left") {
                                withAnimation(reduceMotion ? nil : .default) { showsSidebar.toggle() }
                            }
                        }
                    }
                }
        }
    }

    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        let binding = $showsSidebar
        return Binding(
            get: { binding.wrappedValue ? .all : .detailOnly },
            set: { binding.wrappedValue = $0 != .detailOnly }
        )
    }

    private var compactColumn: Binding<NavigationSplitViewColumn> {
        let binding = $showsSidebar
        return Binding(
            get: { binding.wrappedValue ? .sidebar : .detail },
            set: { binding.wrappedValue = $0 == .sidebar }
        )
    }
}

// MARK: - Demo

private struct AdaptiveSidebarLayoutDemoFolder: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let systemImage: String
    let color: Color
    let count: Int
}

struct AdaptiveSidebarLayoutDemo: View {
    private let folders = [
        AdaptiveSidebarLayoutDemoFolder(title: "Inbox", systemImage: "tray.fill", color: .blue, count: 12),
        AdaptiveSidebarLayoutDemoFolder(title: "Starred", systemImage: "star.fill", color: .orange, count: 3),
        AdaptiveSidebarLayoutDemoFolder(title: "Drafts", systemImage: "doc.fill", color: .purple, count: 5),
        AdaptiveSidebarLayoutDemoFolder(title: "Archive", systemImage: "archivebox.fill", color: .teal, count: 248),
    ]

    @State private var showsSidebar = true
    @State private var selected: AdaptiveSidebarLayoutDemoFolder?

    var body: some View {
        AdaptiveSidebarLayout(showsSidebar: $showsSidebar) {
            List(folders) { folder in
                Button {
                    selected = folder
                    showsSidebar = false
                } label: {
                    Label(folder.title, systemImage: folder.systemImage)
                        .foregroundStyle(folder.color)
                }
                .listRowBackground(selected == folder ? folder.color.opacity(0.15) : nil)
            }
            .navigationTitle("Mail")
        } detail: {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selected {
            ZStack {
                LinearGradient(colors: [selected.color, selected.color.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    Image(systemName: selected.systemImage)
                        .font(.system(.largeTitle, design: .rounded))
                        .accessibilityHidden(true)

                    Text(selected.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("^[\(selected.count) message](inflect: true)")
                        .font(.headline)

                    Button("Folders", systemImage: "sidebar.left") {
                        showsSidebar = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    .padding(.top, 10)
                }
                .foregroundStyle(.white)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Choose a folder", systemImage: "folder")
        }
    }
}

#Preview {
    AdaptiveSidebarLayoutDemo()
}
