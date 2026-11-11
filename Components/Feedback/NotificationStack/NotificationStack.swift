// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Where each card sits, apart from the views so it can be tested.
nonisolated enum NotificationStackMath {
    /// How many cards show their edge under the first one while the stack is collapsed.
    static let visibleBehind = 2

    /// The top of every card. Collapsed, each card behind the first lines its bottom edge up
    /// `peek` points under the one before it. Expanded, they follow one another.
    static func tops(heights: [CGFloat], spacing: CGFloat, peek: CGFloat, progress: Double) -> [CGFloat] {
        guard let front = heights.first else { return [] }
        let progress = CGFloat(min(max(progress, 0), 1))
        var expanded: CGFloat = 0

        return heights.enumerated().map { index, height in
            let collapsed = front + peek * CGFloat(min(index, visibleBehind)) - height
            let top = collapsed + (expanded - collapsed) * progress
            expanded += height + spacing
            return top
        }
    }

    static func height(heights: [CGFloat], spacing: CGFloat, peek: CGFloat, progress: Double) -> CGFloat {
        guard let front = heights.first else { return 0 }
        let progress = CGFloat(min(max(progress, 0), 1))
        let collapsed = front + peek * CGFloat(min(heights.count - 1, visibleBehind))
        let expanded = heights.reduce(0, +) + spacing * CGFloat(heights.count - 1)
        return collapsed + (expanded - collapsed) * progress
    }

    /// How much smaller a card is drawn while it waits behind the first one.
    static func scale(depth: Int, progress: Double) -> Double {
        1 - 0.06 * Double(min(max(depth, 0), visibleBehind)) * (1 - min(max(progress, 0), 1))
    }
}

/// A pile that opens into a column. `progress` animates, so the cards travel between the two.
nonisolated private struct NotificationStackLayout: Layout {
    var progress: Double
    var spacing: CGFloat
    var peek: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private func heights(of subviews: Subviews, width: CGFloat) -> [CGFloat] {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        let height = NotificationStackMath.height(heights: heights(of: subviews, width: width), spacing: spacing, peek: peek, progress: progress)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let heights = heights(of: subviews, width: bounds.width)
        let tops = NotificationStackMath.tops(heights: heights, spacing: spacing, peek: peek, progress: progress)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + tops[index]),
                proposal: ProposedViewSize(width: bounds.width, height: heights[index])
            )
        }
    }
}

/// Notifications piled under the newest one, like a lock screen. A tap opens the pile into a
/// column, and there each card can be swiped away.
///
/// Give the cards a similar height: a card taller than the first shows over it while the pile
/// is closed. With Reduce Motion on, the pile opens and closes without moving.
struct NotificationStack<Item: Identifiable, Card: View>: View {
    let items: [Item]
    @Binding var isExpanded: Bool
    var title: LocalizedStringResource = "Notifications"
    var spacing: CGFloat = 10
    var peek: CGFloat = 10
    var onDismiss: ((Item) -> Void)?
    @ViewBuilder var card: (Item) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minimumTarget: CGFloat = 44

    private var isOpen: Bool { isExpanded || items.count < 2 }
    private var progress: Double { isOpen ? 1 : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if isExpanded, items.count > 1 {
                header
                    .transition(.opacity)
            }

            NotificationStackLayout(progress: progress, spacing: spacing, peek: peek) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    NotificationStackRow(isSwipeable: isOpen && onDismiss != nil, onDismiss: { onDismiss?(item) }) {
                        card(item)
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(NotificationStackMath.scale(depth: index, progress: progress), anchor: .bottom)
                    .opacity(isOpen || index <= NotificationStackMath.visibleBehind ? 1 : 0)
                    .zIndex(Double(items.count - index))
                    .accessibilityHidden(!isOpen && index > 0)
                }
            }
            .allowsHitTesting(isOpen)
            .contentShape(.rect)
            .onTapGesture { isExpanded = true }
            .accessibilityElement(children: isOpen ? .contain : .combine)
            .accessibilityAddTraits(isOpen ? [] : .isButton)
            .accessibilityValue(isOpen ? Text(verbatim: "") : Text("^[\(items.count) notification](inflect: true)"))
            .accessibilityHint(isOpen ? Text(verbatim: "") : Text("Shows them all"))
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2), value: isExpanded)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.15), value: items.map(\.id).count)
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
            Button("Show less") { isExpanded = false }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: minimumTarget)
                .contentShape(.rect)
        }
    }
}

/// A card that follows the finger towards the leading edge and leaves when it is let go far enough.
private struct NotificationStackRow<Content: View>: View {
    let isSwipeable: Bool
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let threshold: CGFloat = 110

    var body: some View {
        content()
            .offset(x: offset)
            .opacity(1 - min(abs(offset) / (threshold * 2.5), 0.6))
            .gesture(swipe, isEnabled: isSwipeable)
            .accessibilityAction(named: "Clear") { if isSwipeable { onDismiss() } }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // A gesture reports screen points. Offsets are mirrored in a right-to-left layout.
                let towardsLeading = layoutDirection == .rightToLeft ? -value.translation.width : value.translation.width
                offset = min(towardsLeading, 0)
            }
            .onEnded { _ in
                if offset < -threshold {
                    onDismiss()
                } else {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.25)) { offset = 0 }
                }
            }
    }
}

// MARK: - Demo

private struct NotificationStackDemoNote: Identifiable {
    let id: String
    let app: String
    let symbol: String
    let color: Color
    let title: String
    let message: String
    let time: String
}

struct NotificationStackDemo: View {
    private static let all = [
        NotificationStackDemoNote(id: "messages", app: "Messages", symbol: "message.fill", color: .green, title: "Maya", message: "Are you coming tonight?", time: "now"),
        NotificationStackDemoNote(id: "calendar", app: "Calendar", symbol: "calendar", color: .red, title: "Design review", message: "Starts in 15 minutes, room 4", time: "5m"),
        NotificationStackDemoNote(id: "mail", app: "Mail", symbol: "envelope.fill", color: .blue, title: "Your order has shipped", message: "It arrives on Thursday", time: "22m"),
        NotificationStackDemoNote(id: "fitness", app: "Fitness", symbol: "figure.run", color: .orange, title: "Almost there", message: "A 10 minute walk closes your ring", time: "1h"),
    ]

    @State private var notes = all
    @State private var isExpanded = false

    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 0) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.title3.weight(.medium))
                    Text(Date.now, format: .dateTime.hour().minute())
                        .font(.system(size: 84, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.top, 36)

                NotificationStack(items: notes, isExpanded: $isExpanded, onDismiss: { note in
                    notes.removeAll { $0.id == note.id }
                }) { note in
                    card(note)
                }
                .foregroundStyle(.white)

                // Only for this demo: a way back once every notification is cleared.
                if notes.isEmpty {
                    Button("Start over") {
                        isExpanded = false
                        notes = Self.all
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
                }
            }
            .padding(.horizontal, 16)
        }
        .background(LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled, isAutoPlaying else { return }
                isExpanded.toggle()
            }
        }
    }

    private func card(_ note: NotificationStackDemoNote) -> some View {
        HStack(spacing: 12) {
            Image(systemName: note.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(note.color.gradient, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(note.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(note.time)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                Text(note.message)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .padding(14)
        // `Color.primary`, not `.primary`: the white set around the stack would make it white too.
        .foregroundStyle(Color.primary)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.app), \(note.title), \(note.message)")
    }
}

#Preview {
    NotificationStackDemo()
}
