// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct SwipeActionRowAction: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let tint: Color
    let handler: () -> Void
}

enum SwipeActionRowPhysics {
    /// Where the row sits for a drag: it cannot move right of closed and resists past fully open.
    static func offset(resting: CGFloat, translation: CGFloat, revealWidth: CGFloat) -> CGFloat {
        let raw = resting + translation
        if raw > 0 { return 0 }
        if raw < -revealWidth { return -revealWidth + (raw + revealWidth) * 0.25 }
        return raw
    }

    static func settlesOpen(resting: CGFloat, predictedTranslation: CGFloat, revealWidth: CGFloat) -> Bool {
        revealWidth > 0 && resting + predictedTranslation < -revealWidth / 2
    }
}

/// A row that reveals action buttons under a horizontal swipe and snaps open or closed.
///
/// Vertical drags are left to the scroll view around it. VoiceOver reaches the same buttons as
/// custom actions, and with Reduce Motion on the row settles without animating.
struct SwipeActionRow<Content: View>: View {
    let actions: [SwipeActionRowAction]
    var buttonWidth: CGFloat = 80
    @ViewBuilder var content: () -> Content

    @State private var isOpen = false
    @GestureState private var translation: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var width: CGFloat { max(buttonWidth, 0) }
    private var revealWidth: CGFloat { CGFloat(actions.count) * width }
    private var resting: CGFloat { isOpen ? -revealWidth : 0 }

    private var animation: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.3)
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .accessibilityElement(children: .combine)
            .accessibilityActions {
                ForEach(actions) { action in
                    Button(action.title, action: action.handler)
                }
            }
            .overlay {
                if isOpen {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { close() }
                        .accessibilityHidden(true)
                }
            }
            .offset(x: SwipeActionRowPhysics.offset(resting: resting, translation: translation, revealWidth: revealWidth))
            .background(alignment: .trailing) { buttons }
            .clipped()
            .simultaneousGesture(swipe)
            .animation(animation, value: translation == 0)
    }

    private var buttons: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                Button {
                    close()
                    action.handler()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: action.systemImage)
                            .font(.title3)
                        Text(action.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .frame(width: width)
                    .frame(maxHeight: .infinity)
                    .background(action.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityHidden(true)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 14)
            .updating($translation) { value, state, _ in
                if state != 0 || abs(value.translation.width) > abs(value.translation.height) {
                    state = value.translation.width
                }
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let opens = SwipeActionRowPhysics.settlesOpen(
                    resting: resting,
                    predictedTranslation: value.predictedEndTranslation.width,
                    revealWidth: revealWidth
                )
                withAnimation(animation) { isOpen = opens }
            }
    }

    private func close() {
        withAnimation(animation) { isOpen = false }
    }
}

// MARK: - Demo

struct SwipeActionRowDemo: View {
    private struct Message: Identifiable {
        let id: String
        let preview: String
    }

    @State private var messages = [
        Message(id: "Weekly report", preview: "The numbers look great this week"),
        Message(id: "Flight update", preview: "Your gate has changed to B12"),
        Message(id: "Dinner on Friday?", preview: "I found a new place downtown"),
        Message(id: "Design review", preview: "Notes from this morning's session"),
    ]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Inbox")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                ForEach(messages) { message in
                    SwipeActionRow(actions: actions(for: message)) {
                        row(message)
                    }
                    .clipShape(.rect(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func row(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(message.id)
                .font(.headline)
            Text(message.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
    }

    private func actions(for message: Message) -> [SwipeActionRowAction] {
        [
            SwipeActionRowAction(id: "archive", title: "Archive", systemImage: "archivebox.fill", tint: .indigo) {
                remove(message)
            },
            SwipeActionRowAction(id: "delete", title: "Delete", systemImage: "trash.fill", tint: .red) {
                remove(message)
            },
        ]
    }

    private func remove(_ message: Message) {
        withAnimation(reduceMotion ? nil : .snappy) {
            messages.removeAll { $0.id == message.id }
        }
    }
}

#Preview {
    SwipeActionRowDemo()
}
