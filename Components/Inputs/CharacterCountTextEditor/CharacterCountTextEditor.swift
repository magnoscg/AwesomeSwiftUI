// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum CharacterCountTextEditorLevel: Equatable {
    case normal, warning, over

    /// Warns from `warningFraction` of the limit, and is over only past it.
    init(count: Int, limit: Int, warningFraction: Double = 0.9) {
        if count > limit {
            self = .over
        } else if Double(count) >= Double(limit) * warningFraction {
            self = .warning
        } else {
            self = .normal
        }
    }

    /// Characters as people see them: an emoji or an accented letter counts once.
    static func count(of text: String) -> Int {
        text.count
    }
}

/// A multiline text field with a placeholder, a ring that fills toward the
/// limit and a count that turns orange near it and red past it.
///
/// It counts characters as people see them, so an emoji counts once, and it
/// never cuts the text: cutting it as it changes breaks typing in Japanese or
/// Chinese and pasting, so the caller disables sending instead. The ring and
/// the count change without motion, so Reduce Motion needs nothing different.
struct CharacterCountTextEditor: View {
    let title: LocalizedStringResource
    @Binding var text: String
    var limit = 280
    var lineLimit: ClosedRange<Int> = 3...8

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .footnote) private var ringSize = 18.0

    private var count: Int { CharacterCountTextEditorLevel.count(of: text) }
    private var level: CharacterCountTextEditorLevel { CharacterCountTextEditorLevel(count: count, limit: limit) }

    private var levelColor: Color {
        switch level {
        case .normal: .accentColor
        case .warning: .orange
        case .over: .red
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextField(text: $text, axis: .vertical) { Text(title) }
                .lineLimit(lineLimit)
                .focused($isFocused)
                .accessibilityLabel(Text(title))
                .accessibilityHint(Text("\(count) of \(limit) characters"))
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(level == .over ? AnyShapeStyle(.red) : isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), lineWidth: 1.5)
                }

            HStack(spacing: 8) {
                Text("\(count)/\(limit)")
                    .font(.footnote.weight(level == .normal ? .regular : .semibold))
                    .monospacedDigit()
                    .foregroundStyle(level == .normal ? AnyShapeStyle(.secondary) : AnyShapeStyle(levelColor))
                    .contentTransition(.numericText(value: Double(count)))

                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: ringSize / 6)
                    Circle()
                        .trim(from: 0, to: min(Double(count) / Double(max(limit, 1)), 1))
                        .stroke(levelColor, style: StrokeStyle(lineWidth: ringSize / 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: ringSize, height: ringSize)
            }
            .accessibilityHidden(true)
            .animation(.easeOut(duration: 0.15), value: count)
        }
        .onChange(of: level) { old, new in
            if new == .over, old != .over {
                AccessibilityNotification.Announcement(String(localized: "Over the character limit")).post()
            }
        }
    }
}

// MARK: - Demo

struct CharacterCountTextEditorDemo: View {
    @State private var status = ""
    @State private var bio = "Coffee, trains and old maps."
    @State private var postedStatus: String?

    private var canPost: Bool {
        !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && status.count <= 80
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.headline)
                    CharacterCountTextEditor(title: "What's on your mind?", text: $status, limit: 80)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.headline)
                    CharacterCountTextEditor(title: "Tell people about yourself", text: $bio, limit: 160, lineLimit: 2...4)
                }

                Button {
                    postedStatus = status
                    status = ""
                } label: {
                    Text("Post Status").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canPost)

                if let postedStatus {
                    Text(verbatim: postedStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    CharacterCountTextEditorDemo()
}
