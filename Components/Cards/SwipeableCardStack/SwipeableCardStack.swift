// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum SwipeableCardStackDirection: Equatable, Sendable {
    case left, right

    var sign: CGFloat { self == .left ? -1 : 1 }
}

enum SwipeableCardStackLogic {
    /// Decides where a released card goes from where its momentum would carry it,
    /// so both a long drag and a short flick count, and a flick back cancels.
    static func direction(predictedEnd: CGFloat, width: CGFloat, threshold: CGFloat = 0.35) -> SwipeableCardStackDirection? {
        guard width > 0, abs(predictedEnd) >= width * threshold else { return nil }
        return predictedEnd > 0 ? .right : .left
    }

    /// One swiped card still flying away, the top card and three behind it.
    /// Empty when the deck shrank below the cards already swiped.
    static func positions(top: Int, count: Int, loops: Bool) -> [Int] {
        guard count > 0 else { return [] }
        let start = max(top - 1, 0)
        let end = loops ? top + 4 : min(top + 4, count)
        return start < end ? Array(start..<end) : []
    }
}

/// A deck of cards. Swipe the top one away to reveal the next.
///
/// With Reduce Motion on, a swiped card fades out instead of flying away.
struct SwipeableCardStack<Item, Card: View>: View {
    let items: [Item]
    var loops = false
    var threshold: CGFloat = 0.35
    var onSwipe: (Item, SwipeableCardStackDirection) -> Void = { _, _ in }
    @ViewBuilder var card: (Item) -> Card

    @State private var top = 0
    @State private var drag = CGSize.zero
    @State private var lastDirection = SwipeableCardStackDirection.right
    @State private var size = CGSize.zero
    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var width: CGFloat { size.width }

    private var hasTopCard: Bool { !items.isEmpty && (loops || top < items.count) }

    private var positions: [Int] {
        SwipeableCardStackLogic.positions(top: top, count: items.count, loops: loops)
    }

    private var dragProgress: CGFloat {
        min(abs(drag.width) / max(width * threshold, 1), 1)
    }

    var body: some View {
        ZStack {
            ForEach(positions, id: \.self) { position in
                let depth = max(CGFloat(position - top) - dragProgress, 0)

                card(items[position % items.count])
                    .scaleEffect(1 - depth * 0.06)
                    .offset(offset(of: position, depth: depth))
                    .rotationEffect(.degrees(rotation(of: position)))
                    .opacity(position < top || position - top > 2 ? 0 : 1)
                    .zIndex(Double(-position))
                    .accessibilityElement(children: .combine)
                    .accessibilityHidden(position != top)
                    .accessibilityAction(named: "Swipe left") { swipe(.left) }
                    .accessibilityAction(named: "Swipe right") { swipe(.right) }
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(.rect)
        .gesture(dragGesture)
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.3)) { drag = .zero }
            }
        }
    }

    private func offset(of position: Int, depth: CGFloat) -> CGSize {
        if position < top {
            return CGSize(width: reduceMotion ? 0 : lastDirection.sign * width * 1.5, height: 0)
        }
        if position == top {
            return CGSize(width: drag.width, height: drag.height * 0.25)
        }
        // Scaling shrinks a card around its center, so move it down by that amount plus the visible peek.
        return CGSize(width: 0, height: depth * (size.height * 0.03 + 14))
    }

    private func rotation(of position: Int) -> Double {
        guard !reduceMotion, width > 0 else { return 0 }
        if position < top { return Double(lastDirection.sign) * 18 }
        return position == top ? Double(drag.width / width) * 14 : 0
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if hasTopCard { drag = value.translation }
            }
            .onEnded { value in
                let predictedEnd = value.predictedEndTranslation.width
                if let direction = SwipeableCardStackLogic.direction(predictedEnd: predictedEnd, width: width, threshold: threshold) {
                    swipe(direction)
                }
            }
    }

    private func swipe(_ direction: SwipeableCardStackDirection) {
        guard hasTopCard else { return }
        let item = items[top % items.count]
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.4)) {
            lastDirection = direction
            top += 1
            drag = .zero
        }
        onSwipe(item, direction)
    }
}

// MARK: - Demo

private struct DemoPlace {
    let name: String
    let symbol: String
    let colors: [Color]
}

struct SwipeableCardStackDemo: View {
    @State private var liked = 0
    @State private var passed = 0

    private let places = [
        DemoPlace(name: "Kyoto", symbol: "leaf.fill", colors: [.pink, .purple]),
        DemoPlace(name: "Reykjavik", symbol: "snowflake", colors: [.cyan, .blue]),
        DemoPlace(name: "Marrakesh", symbol: "sun.max.fill", colors: [.orange, .red]),
        DemoPlace(name: "Lisbon", symbol: "tram.fill", colors: [.yellow, .orange]),
        DemoPlace(name: "Patagonia", symbol: "mountain.2.fill", colors: [.teal, .indigo]),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Text("Where next?")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            SwipeableCardStack(items: places, loops: true) { place, direction in
                if direction == .right { liked += 1 } else { passed += 1 }
            } card: { place in
                cardView(for: place)
            }
            .padding(.horizontal, 32)
            .frame(maxHeight: 500)
            .padding(.bottom, 32)

            HStack(spacing: 32) {
                Label("\(passed)", systemImage: "xmark")
                    .accessibilityLabel("Passed \(passed)")
                Label("\(liked)", systemImage: "heart.fill")
                    .accessibilityLabel("Liked \(liked)")
            }
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.indigo.opacity(0.18), .pink.opacity(0.12)], startPoint: .top, endPoint: .bottom))
    }

    private func cardView(for place: DemoPlace) -> some View {
        VStack(spacing: 16) {
            Image(systemName: place.symbol)
                .font(.system(.largeTitle))
                .imageScale(.large)
                .accessibilityHidden(true)
            Text(place.name)
                .font(.system(.title, design: .rounded, weight: .bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: place.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 32))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }
}

#Preview {
    SwipeableCardStackDemo()
}
