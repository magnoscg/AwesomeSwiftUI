// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct EmojiPickerCategory: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let tabLabel: String
    let systemImage: String
    let emoji: [String]

    init(title: String, tabLabel: String, systemImage: String, emoji: String) {
        id = tabLabel
        self.title = title
        self.tabLabel = tabLabel
        self.systemImage = systemImage
        self.emoji = emoji.map(String.init)
    }

    static let standard = [
        EmojiPickerCategory(title: "Smileys & People", tabLabel: "Smileys", systemImage: "face.smiling", emoji: "😀😃😄😁😆😅😂🤣😊😇🙂😉😍🥰😘😋😜🤪😎🤩🥳😏😔😢😭😤😡🤯😱🤔🤗😴👍👎👏🙌🙏💪👋✌️"),
        EmojiPickerCategory(title: "Animals & Nature", tabLabel: "Animals", systemImage: "pawprint", emoji: "🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐸🐵🐔🐧🐦🦆🦉🦋🐝🐢🐙🐬🐳🌸🌻🌳🌵🍀🍁🌈⭐️🔥💧"),
        EmojiPickerCategory(title: "Food & Drink", tabLabel: "Food", systemImage: "fork.knife", emoji: "🍎🍊🍋🍌🍉🍇🍓🍒🍑🥭🍍🥥🥑🍅🌽🥕🥐🥖🧀🍳🍔🍟🍕🌮🍣🍜🍰🧁🍫🍩🍪☕️🍵🍺🍷🥂"),
        EmojiPickerCategory(title: "Travel & Places", tabLabel: "Travel", systemImage: "airplane", emoji: "🚗🚕🚌🏎️🚓🚑🚒🚲🛵🚂✈️🚀🛸🚁⛵️🚢🗺️🏖️🏝️🏔️⛺️🏠🏰🗼🗽🎡🌋🌅🌃"),
        EmojiPickerCategory(title: "Everyday Objects", tabLabel: "Objects", systemImage: "lightbulb", emoji: "⌚️📱💻⌨️🖥️📷🎥📺📻⏰🔦💡📚✏️📎✂️🔑🔒🔨🧰🎁🎈🎉🎨🎸🎧🎮⚽️🏀🎾"),
        EmojiPickerCategory(title: "Signs & Symbols", tabLabel: "Symbols", systemImage: "heart", emoji: "❤️🧡💛💚💙💜🖤🤍💔💕💯✅❌⭕️❗️❓⚠️♻️🔔🎵➕➖➡️⬅️⬆️⬇️🔁"),
        EmojiPickerCategory(title: "World Flags", tabLabel: "Flags", systemImage: "flag", emoji: "🏁🚩🏳️🏴🏳️‍🌈🇪🇸🇫🇷🇩🇪🇮🇹🇵🇹🇬🇧🇮🇪🇺🇸🇨🇦🇲🇽🇧🇷🇦🇷🇯🇵🇰🇷🇨🇳🇮🇳🇦🇺🇿🇦"),
    ]
}

/// A grid of emoji grouped by category, with tabs and a row of the ones used last.
///
/// With Reduce Motion on, tabs jump to their section without animating.
struct EmojiPicker: View {
    @Binding var recents: [String]
    var categories: [EmojiPickerCategory] = EmojiPickerCategory.standard
    var recentLimit = 12
    let onSelect: (String) -> Void

    @State private var activeID: String?
    @ScaledMetric(relativeTo: .title) private var cellSize = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let edgePadding: CGFloat = 12

    private var animation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.35)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !recents.isEmpty {
                recentRow
            }

            ScrollViewReader { proxy in
                tabBar(proxy: proxy)
                Divider()
                grid
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: recents)
    }

    private var recentRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(recents, id: \.self, content: emojiButton)
            }
            .padding(.horizontal, edgePadding)
        }
        .scrollIndicators(.hidden)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recent")
    }

    private func tabBar(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 2) {
                ForEach(categories) { category in
                    let isActive = category.id == (activeID ?? categories.first?.id)

                    Button {
                        activeID = category.id
                        withAnimation(animation) { proxy.scrollTo(category.id, anchor: .top) }
                    } label: {
                        Image(systemName: category.systemImage)
                            .font(.title3)
                            .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                            .frame(minWidth: cellSize, minHeight: cellSize)
                            .background(isActive ? Color.accentColor.opacity(0.15) : .clear, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(category.tabLabel)
                    .accessibilityAddTraits(isActive ? .isSelected : [])
                }
            }
            .padding(.horizontal, edgePadding)
            .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
    }

    private var grid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: max(cellSize, 1)), spacing: 4)], spacing: 4) {
                            ForEach(category.emoji, id: \.self, content: emojiButton)
                        }
                    }
                    .id(category.id)
                }
            }
            .scrollTargetLayout()
            .padding(edgePadding)
        }
        .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.01) { ids in
            if let first = categories.first(where: { ids.contains($0.id) }) {
                activeID = first.id
            }
        }
    }

    private func emojiButton(_ emoji: String) -> some View {
        Button {
            recents = EmojiPickerRecents.adding(emoji, to: recents, limit: recentLimit)
            onSelect(emoji)
        } label: {
            Text(emoji)
                .font(.title)
                .frame(minWidth: cellSize, minHeight: cellSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

enum EmojiPickerRecents {
    /// Puts the emoji first, without repeating it, and keeps at most `limit` of them.
    static func adding(_ emoji: String, to recents: [String], limit: Int) -> [String] {
        Array(([emoji] + recents.filter { $0 != emoji }).prefix(max(limit, 0)))
    }
}

// MARK: - Demo

struct EmojiPickerDemo: View {
    @State private var recents: [String] = []
    @State private var chosen = "😀"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [.yellow, .orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)

                Text(chosen)
                    .font(.system(.largeTitle, design: .rounded))
                    .scaleEffect(2.4)
                    .contentTransition(.opacity)
                    .id(chosen)
                    .transition(reduceMotion ? .identity : .scale(scale: 0.6).combined(with: .opacity))
            }
            .frame(height: 170)
            .accessibilityHidden(true)

            EmojiPicker(recents: $recents) { emoji in
                withAnimation(reduceMotion ? nil : .bouncy) { chosen = emoji }
            }
        }
    }
}

#Preview {
    EmojiPickerDemo()
}
