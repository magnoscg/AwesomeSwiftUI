// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct LongPressRadialMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

/// A long press opens a ring of actions. Drag onto one and let go to choose it.
///
/// VoiceOver offers the same actions in its Actions list. With Reduce Motion on,
/// the ring fades in place.
struct LongPressRadialMenu<Label: View>: View {
    let items: [LongPressRadialMenuItem]
    var radius: CGFloat = 104
    var minimumDuration = 0.35
    var tint: Color = .indigo
    var accessibilityTitle = "Actions"
    @ViewBuilder var label: () -> Label

    private enum Press: Equatable {
        case idle
        case pressing
        case open(CGSize)
    }

    @GestureState private var press = Press.idle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    private var isOpen: Bool {
        if case .open = press { return true }
        return false
    }

    private var hoveredIndex: Int? {
        guard case .open(let translation) = press else { return nil }
        return LongPressRadialMenuMath.index(translation: translation, count: items.count, radius: radius)
    }

    var body: some View {
        label()
            .scaleEffect(press == .idle || reduceMotion ? 1 : 0.9)
            .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.3), value: press == .idle)
            .contentShape(.rect)
            .overlay { ring.allowsHitTesting(false).accessibilityHidden(true) }
            .gesture(gesture)
            .sensoryFeedback(.impact(weight: .medium), trigger: isOpen) { _, nowOpen in nowOpen }
            .sensoryFeedback(.selection, trigger: hoveredIndex)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityTitle)
            .accessibilityActions {
                ForEach(items) { item in
                    Button(item.title, action: item.action)
                }
            }
    }

    private var ring: some View {
        ZStack {
            LongPressRadialMenuBubbles(items: items, radius: radius, tint: tint, isOpen: isOpen, hoveredIndex: hoveredIndex)
                // The bubbles sit on a fixed radius, so they read their size under this cap. The title below does not.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            if let hoveredIndex, items.indices.contains(hoveredIndex) {
                // Its bottom edge clears the largest bubble, so a taller title grows away from the ring.
                Text(items[hoveredIndex].title)
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: .capsule)
                    .alignmentGuide(VerticalAlignment.center) { $0[.bottom] }
                    .offset(y: -(radius + 48))
            }
        }
    }

    private var gesture: some Gesture {
        LongPressGesture(minimumDuration: max(minimumDuration, 0))
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($press) { value, state, _ in
                switch value {
                case .first(true): state = .pressing
                case .second(true, let drag): state = .open(layoutTranslation(drag?.translation ?? .zero))
                default: state = .idle
                }
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value,
                      let index = LongPressRadialMenuMath.index(translation: layoutTranslation(drag.translation), count: items.count, radius: radius),
                      items.indices.contains(index)
                else { return }
                items[index].action()
            }
    }

    /// Gestures report screen points, but layout mirrors in right-to-left layouts.
    private func layoutTranslation(_ translation: CGSize) -> CGSize {
        layoutDirection == .rightToLeft ? CGSize(width: -translation.width, height: translation.height) : translation
    }
}

private struct LongPressRadialMenuBubbles: View {
    let items: [LongPressRadialMenuItem]
    let radius: CGFloat
    let tint: Color
    let isOpen: Bool
    let hoveredIndex: Int?

    @ScaledMetric(relativeTo: .title3) private var bubbleSize = 56.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            let isHovered = hoveredIndex == index
            let offset = LongPressRadialMenuMath.offset(index: index, count: items.count, radius: radius)

            Image(systemName: item.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isHovered ? .white : tint)
                .frame(width: bubbleSize, height: bubbleSize)
                .background(isHovered ? AnyShapeStyle(tint) : AnyShapeStyle(.regularMaterial), in: .circle)
                .scaleEffect(reduceMotion ? 1 : (isOpen ? (isHovered ? 1.2 : 1) : 0.3))
                .offset(isOpen || reduceMotion ? offset : .zero)
                .opacity(isOpen ? 1 : 0)
                .animation(
                    reduceMotion
                        ? .easeInOut(duration: 0.15)
                        : .spring(duration: 0.35, bounce: 0.4).delay(isOpen ? Double(index) * 0.02 : 0),
                    value: isOpen
                )
                .animation(reduceMotion ? nil : .spring(duration: 0.2), value: isHovered)
        }
    }
}

enum LongPressRadialMenuMath {
    /// How far the finger must travel, as a share of the radius, to reach the ring.
    static let deadZone = 0.45

    /// The direction of an item in radians, clockwise from the top.
    static func angle(index: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }
        return 2 * .pi * Double(index) / Double(count)
    }

    static func offset(index: Int, count: Int, radius: CGFloat) -> CGSize {
        let angle = angle(index: index, count: count)
        return CGSize(width: sin(angle) * radius, height: -cos(angle) * radius)
    }

    /// The item nearest the finger, or `nil` while the finger is still near the center.
    static func index(translation: CGSize, count: Int, radius: CGFloat) -> Int? {
        guard count > 0, radius > 0 else { return nil }
        guard hypot(translation.width, translation.height) >= radius * deadZone else { return nil }

        let clockwise = atan2(translation.width, -translation.height)
        let positive = clockwise < 0 ? clockwise + 2 * .pi : clockwise
        let step = 2 * .pi / Double(count)
        return Int((positive / step).rounded()) % count
    }
}

// MARK: - Demo

struct LongPressRadialMenuDemo: View {
    @State private var lastAction = "Hold, then drag"

    private var items: [LongPressRadialMenuItem] {
        [
            LongPressRadialMenuItem(id: "camera", title: "Camera", systemImage: "camera.fill") { lastAction = "Camera" },
            LongPressRadialMenuItem(id: "note", title: "Note", systemImage: "note.text") { lastAction = "Note" },
            LongPressRadialMenuItem(id: "share", title: "Share", systemImage: "square.and.arrow.up") { lastAction = "Share" },
            LongPressRadialMenuItem(id: "star", title: "Favorite", systemImage: "star.fill") { lastAction = "Favorite" },
            LongPressRadialMenuItem(id: "trash", title: "Delete", systemImage: "trash.fill") { lastAction = "Delete" },
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Text(lastAction)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 48)
                Spacer()
            }

            LongPressRadialMenu(items: items) {
                Image(systemName: "plus")
                    .font(.title.bold())
                    .foregroundStyle(.indigo)
                    .frame(width: 84, height: 84)
                    .background(.white, in: .circle)
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
            }
        }
    }
}

#Preview {
    LongPressRadialMenuDemo()
}
