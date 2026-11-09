// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct EmojiReactionPickerOption: Identifiable, Equatable, Sendable {
    let emoji: String
    let name: String

    var id: String { name }

    static let defaults = [
        EmojiReactionPickerOption(emoji: "👍", name: "Like"),
        EmojiReactionPickerOption(emoji: "❤️", name: "Love"),
        EmojiReactionPickerOption(emoji: "😂", name: "Haha"),
        EmojiReactionPickerOption(emoji: "😮", name: "Wow"),
        EmojiReactionPickerOption(emoji: "😢", name: "Sad"),
    ]
}

enum EmojiReactionPickerMath {
    /// The cell under a horizontal position, clamped to the row. Nil when there is no row to hit.
    static func index(atX x: CGFloat, cellWidth: CGFloat, spacing: CGFloat, count: Int) -> Int? {
        guard count > 0, cellWidth > 0, x.isFinite else { return nil }
        let position = x / (cellWidth + max(spacing, 0))
        return Int(min(max(position, 0), CGFloat(count - 1)))
    }
}

/// A button that toggles the first reaction on tap and reveals every reaction on long press.
/// Slide along the row to magnify one and lift the finger to pick it.
///
/// The row opens above the button's leading edge. Reduce Motion replaces the magnification
/// with a highlight, and VoiceOver offers each reaction as an action.
struct EmojiReactionPicker: View {
    private enum Press: Equatable {
        case idle
        case active(location: CGPoint?)
    }

    @Binding var selection: EmojiReactionPickerOption?
    var options = EmojiReactionPickerOption.defaults
    var onSelect: (EmojiReactionPickerOption?) -> Void = { _ in }

    @GestureState private var press = Press.idle
    @ScaledMetric(relativeTo: .title) private var cellSize = 46.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let spacing = 6.0
    private let padding = 8.0
    private let gap = 12.0
    /// How far from the row the finger can drift before lifting it cancels.
    private let tolerance = 70.0

    private var isOpen: Bool { press != .idle && !options.isEmpty }

    private var highlighted: Int? {
        guard case .active(let location?) = press else { return nil }
        return index(at: location)
    }

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.28, bounce: 0.35)
    }

    var body: some View {
        trigger
            .contentShape(.capsule)
            .onTapGesture(perform: toggle)
            .gesture(longPressAndSlide)
            .overlay(alignment: .topLeading) {
                if isOpen {
                    row
                        .alignmentGuide(.top) { $0.height + gap }
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.5, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
            .animation(animation, value: isOpen)
            .animation(animation, value: highlighted)
            .sensoryFeedback(.selection, trigger: highlighted)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Reaction")
            .accessibilityValue(selection?.name ?? "None")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, toggle)
            .accessibilityActions {
                ForEach(options) { option in
                    Button(option.name) { choose(option) }
                }
            }
    }

    private var trigger: some View {
        HStack(spacing: 8) {
            if let selection {
                Text(selection.emoji)
                Text(selection.name)
            } else {
                Image(systemName: "hand.thumbsup")
                Text("React")
            }
        }
        .font(.headline)
        .foregroundStyle(selection == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.quaternary, in: Capsule())
    }

    private var row: some View {
        HStack(spacing: spacing) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isHighlighted = index == highlighted

                Text(option.emoji)
                    .font(.title)
                    .frame(width: cellSize, height: cellSize)
                    .background {
                        if isHighlighted && reduceMotion { Circle().fill(.tint.opacity(0.3)) }
                    }
                    .scaleEffect(isHighlighted && !reduceMotion ? 1.55 : 1, anchor: .bottom)
                    .zIndex(isHighlighted ? 1 : 0)
            }
        }
        .padding(padding)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        // The row cannot wrap under the finger, so it stops growing.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .fixedSize()
    }

    private var longPressAndSlide: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($press) { value, state, _ in
                switch value {
                case .first(true): state = .active(location: nil)
                case .second(true, let drag): state = .active(location: drag?.location)
                default: state = .idle
                }
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value,
                      let index = index(at: drag.location),
                      options.indices.contains(index) else { return }
                choose(options[index])
            }
    }

    /// Positions are relative to the button, and the row's first cell starts at its leading edge.
    private func index(at location: CGPoint) -> Int? {
        let rowHeight = cellSize + padding * 2
        guard location.y > -(gap + rowHeight + tolerance), location.y < cellSize + tolerance else { return nil }
        return EmojiReactionPickerMath.index(atX: location.x - padding, cellWidth: cellSize, spacing: spacing, count: options.count)
    }

    private func toggle() {
        guard let first = options.first else { return }
        let new = selection == nil ? first : nil
        selection = new
        onSelect(new)
    }

    private func choose(_ option: EmojiReactionPickerOption) {
        selection = option
        onSelect(option)
    }
}

// MARK: - Demo

struct EmojiReactionPickerDemo: View {
    @State private var reaction: EmojiReactionPickerOption?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.linearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 280)
                .overlay {
                    Image(systemName: "sun.haze.fill")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            Text("Sunset from the rooftop")
                .font(.title3.weight(.semibold))

            EmojiReactionPicker(selection: $reaction)
                .padding(.top, 72)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmojiReactionPickerDemo()
}
