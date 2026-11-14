// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum StaggeredAppearListTiming {
    /// How long a row waits before it enters. The cap keeps long lists from stalling.
    static func delay(
        forIndex index: Int,
        step: Double = 0.07,
        maximum: Double = 0.6,
        reduceMotion: Bool = false
    ) -> Double {
        guard !reduceMotion else { return 0 }
        return min(max(Double(index), 0) * step, maximum)
    }
}

/// Rows that enter one after another when the list appears.
///
/// With Reduce Motion on, every row fades in at once without moving.
struct StaggeredAppearList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var spacing: CGFloat = 12
    var travel: CGFloat = 28
    @ViewBuilder var row: (Item) -> Row

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible || reduceMotion ? 0 : travel)
                    .animation(
                        .smooth(duration: 0.45)
                            .delay(StaggeredAppearListTiming.delay(forIndex: index, reduceMotion: reduceMotion)),
                        value: isVisible
                    )
            }
        }
        .onAppear { isVisible = true }
    }
}

// MARK: - Demo

private struct StaggeredAppearDemoRow: Identifiable {
    let id: String
    let detail: String
    let systemImage: String
    let tint: Color
}

struct StaggeredAppearListDemo: View {
    @State private var replay = 0

    private let rows = [
        StaggeredAppearDemoRow(id: "Inbox", detail: "12 new messages", systemImage: "tray.fill", tint: .blue),
        StaggeredAppearDemoRow(id: "Calendar", detail: "Standup at 9:30", systemImage: "calendar", tint: .red),
        StaggeredAppearDemoRow(id: "Music", detail: "Your weekly mix", systemImage: "music.note", tint: .pink),
        StaggeredAppearDemoRow(id: "Photos", detail: "48 added today", systemImage: "photo.fill", tint: .orange),
        StaggeredAppearDemoRow(id: "Health", detail: "6,204 steps", systemImage: "heart.fill", tint: .green),
        StaggeredAppearDemoRow(id: "Files", detail: "2 shared with you", systemImage: "folder.fill", tint: .teal),
        StaggeredAppearDemoRow(id: "Notes", detail: "Groceries, ideas", systemImage: "note.text", tint: .yellow),
    ]

    var body: some View {
        ScrollView {
            StaggeredAppearList(items: rows) { row in
                HStack(spacing: 14) {
                    Image(systemName: row.systemImage)
                        .font(.title3)
                        .foregroundStyle(row.tint)
                        .frame(width: 36)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.id)
                            .font(.headline)
                        Text(row.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            }
            .id(replay)
            .padding(20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            while (try? await Task.sleep(for: .seconds(2.4))) != nil {
                replay += 1
            }
        }
    }
}

#Preview {
    StaggeredAppearListDemo()
}
