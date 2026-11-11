// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A message list that stays on the newest message, and stops following when you scroll up.
///
/// While you read older messages, a button brings you back to the latest. With Reduce
/// Motion on, the list jumps instead of scrolling.
struct ChatAutoScrollList<Item: Identifiable, Row: View>: View where Item.ID: Sendable {
    let items: [Item]
    var spacing: CGFloat
    @ViewBuilder let row: (Item) -> Row

    @State private var position = ScrollPosition(idType: Item.ID.self)
    @State private var follow = ChatAutoScrollListFollowState()
    @State private var isUserScrolling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(items: [Item], spacing: CGFloat = 8, @ViewBuilder row: @escaping (Item) -> Row) {
        self.items = items
        self.spacing = spacing
        self.row = row
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: max(spacing, 0)) {
                ForEach(items) { row($0) }
            }
            .scrollTargetLayout()
            .padding()
        }
        .scrollPosition($position)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .onScrollPhaseChange { _, phase in
            isUserScrolling = phase == .tracking || phase == .interacting || phase == .decelerating
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            ChatAutoScrollListLogic.isAtBottom(
                visibleMaxY: geometry.visibleRect.maxY,
                contentHeight: geometry.contentSize.height
            )
        } action: { _, isAtBottom in
            follow.scrolled(isAtBottom: isAtBottom, isUserDriven: isUserScrolling)
        }
        .onChange(of: items.last?.id) { _, newID in
            guard let newID else { return }
            follow.messageArrived()
            if follow.isFollowing { scroll(to: newID) }
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if !follow.isFollowing {
                    jumpButton.transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: follow)
        }
    }

    private var jumpButton: some View {
        Button {
            follow.jumpedToLatest()
            if let id = items.last?.id { scroll(to: id) }
        } label: {
            Label(follow.hasNewMessages ? "New messages" : "Latest", systemImage: "arrow.down")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: .capsule)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12)
    }

    private func scroll(to id: Item.ID) {
        withAnimation(reduceMotion ? nil : .snappy) {
            position.scrollTo(id: id, anchor: .bottom)
        }
    }
}

/// Whether the list follows new messages.
///
/// Only the user can stop following. Otherwise the moment a new message makes the list
/// taller, or an animated scroll is on its way down, would count as having left the bottom.
struct ChatAutoScrollListFollowState: Equatable {
    private(set) var isFollowing = true
    private(set) var hasNewMessages = false

    mutating func messageArrived() {
        if !isFollowing { hasNewMessages = true }
    }

    mutating func scrolled(isAtBottom: Bool, isUserDriven: Bool) {
        if isAtBottom {
            jumpedToLatest()
        } else if isUserDriven {
            isFollowing = false
        }
    }

    mutating func jumpedToLatest() {
        isFollowing = true
        hasNewMessages = false
    }
}

enum ChatAutoScrollListLogic {
    static func isAtBottom(visibleMaxY: CGFloat, contentHeight: CGFloat, tolerance: CGFloat = 32) -> Bool {
        visibleMaxY >= contentHeight - max(tolerance, 0)
    }
}

// MARK: - Demo

private struct ChatAutoScrollListDemoMessage: Identifiable {
    let id: Int
    let text: String
    var isMine: Bool { id.isMultiple(of: 3) }
}

struct ChatAutoScrollListDemo: View {
    private static let initialCount = 12
    private static let lines = [
        "Did the build finish?",
        "Almost, the last tests are running now.",
        "Great. Scroll up and the list stops following.",
        "And when you come back to the bottom?",
        "It starts following the new messages again, without you doing anything.",
        "Nice.",
    ]

    @State private var messages = (0..<initialCount).map { ChatAutoScrollListDemoMessage(id: $0, text: lines[$0 % lines.count]) }
    @State private var nextID = initialCount
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ChatAutoScrollList(items: messages) { message in
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .foregroundStyle(message.isMine ? Color.white : Color.primary)
                    .background(message.isMine ? AnyShapeStyle(.indigo) : AnyShapeStyle(.thinMaterial), in: .rect(cornerRadius: 18))
                    .frame(maxWidth: .infinity, alignment: message.isMine ? .trailing : .leading)
            }

            Button("Add message", systemImage: "plus.bubble") { addMessage() }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .padding()
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .teal.opacity(0.1)], startPoint: .top, endPoint: .bottom))
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }
                addMessage()
            }
        }
    }

    private func addMessage() {
        messages.append(.init(id: nextID, text: Self.lines[nextID % Self.lines.count]))
        nextID += 1
        if messages.count > 60 { messages.removeFirst(30) }
    }
}

#Preview {
    ChatAutoScrollListDemo()
}
