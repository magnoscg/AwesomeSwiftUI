// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum ChatBubbleShapeSide: Sendable {
    case leading, trailing
}

/// Where a message sits inside a run of messages from the same sender.
nonisolated enum ChatBubbleShapePosition: Sendable {
    case single, first, middle, last
}

/// A message bubble with a tail, whose corners tighten where messages are grouped.
///
/// The tail is drawn just outside the shape's rect, so leave about 8 points beside it.
/// Corners and tail animate when a bubble's position changes.
nonisolated struct ChatBubbleShape: Shape {
    var side: ChatBubbleShapeSide = .trailing
    private var radii: RectangleCornerRadii
    private var tail: CGFloat

    private let tailWidth: CGFloat = 7

    init(
        side: ChatBubbleShapeSide = .trailing,
        position: ChatBubbleShapePosition = .single,
        radius: CGFloat = 18,
        tightRadius: CGFloat = 5
    ) {
        self.side = side
        radii = ChatBubbleShapeLogic.radii(for: position, radius: radius, tightRadius: tightRadius)
        tail = ChatBubbleShapeLogic.hasTail(position) ? 1 : 0
    }

    var animatableData: AnimatablePair<RectangleCornerRadii.AnimatableData, CGFloat> {
        get { AnimatablePair(radii.animatableData, tail) }
        set {
            radii.animatableData = newValue.first
            tail = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let path = outline(width: rect.width, height: rect.height)
        let placed = side == .trailing
            ? path
            : path.applying(CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -rect.width, y: 0))
        return placed.offsetBy(dx: rect.minX, dy: rect.minY)
    }

    /// One closed outline, with the tail on the right. The left side is its mirror image.
    private func outline(width: CGFloat, height: CGFloat) -> Path {
        let limit = min(width, height) / 2
        let topLeft = min(max(radii.topLeading, 0), limit)
        let topRight = min(max(radii.topTrailing, 0), limit)
        let bottomRight = min(max(radii.bottomTrailing, 0), limit)
        let bottomLeft = min(max(radii.bottomLeading, 0), limit)

        // The bottom right corner is two curves that meet at `tip`. With no tail they
        // form an ordinary rounded corner, and the tail pulls them out to a point.
        let cornerStart = CGPoint(x: width, y: height - bottomRight)
        let cornerEnd = CGPoint(x: width - bottomRight, y: height)
        let corner = CGPoint(x: width, y: height)
        let firstControl = midpoint(cornerStart, corner)
        let secondControl = midpoint(corner, cornerEnd)
        let roundedTip = midpoint(firstControl, secondControl)

        var path = Path()
        path.move(to: CGPoint(x: topLeft, y: 0))
        path.addLine(to: CGPoint(x: width - topRight, y: 0))
        path.addArc(tangent1End: CGPoint(x: width, y: 0), tangent2End: CGPoint(x: width, y: topRight), radius: topRight)
        path.addLine(to: cornerStart)
        path.addQuadCurve(
            to: blend(roundedTip, CGPoint(x: width + tailWidth, y: height), tail),
            control: blend(firstControl, CGPoint(x: width, y: height - 2), tail)
        )
        path.addQuadCurve(
            to: cornerEnd,
            control: blend(secondControl, CGPoint(x: width - 2, y: height - 1), tail)
        )
        path.addLine(to: CGPoint(x: bottomLeft, y: height))
        path.addArc(tangent1End: CGPoint(x: 0, y: height), tangent2End: CGPoint(x: 0, y: height - bottomLeft), radius: bottomLeft)
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        path.addArc(tangent1End: .zero, tangent2End: CGPoint(x: topLeft, y: 0), radius: topLeft)
        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        blend(a, b, 0.5)
    }

    private func blend(_ a: CGPoint, _ b: CGPoint, _ amount: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
    }
}

nonisolated enum ChatBubbleShapeLogic {
    static func hasTail(_ position: ChatBubbleShapePosition) -> Bool {
        position == .single || position == .last
    }

    /// The corners, as if the tail were on the right.
    static func radii(for position: ChatBubbleShapePosition, radius: CGFloat, tightRadius: CGFloat) -> RectangleCornerRadii {
        let tightTop = position == .middle || position == .last
        let tightBottom = position == .first || position == .middle
        return RectangleCornerRadii(
            topLeading: radius,
            bottomLeading: radius,
            bottomTrailing: tightBottom ? tightRadius : radius,
            topTrailing: tightTop ? tightRadius : radius
        )
    }

    /// Works out each message's position from who sent it.
    static func positions<Sender: Equatable>(for senders: [Sender]) -> [ChatBubbleShapePosition] {
        senders.indices.map { index in
            let joinsPrevious = index > senders.startIndex && senders[index - 1] == senders[index]
            let joinsNext = index + 1 < senders.endIndex && senders[index + 1] == senders[index]
            switch (joinsPrevious, joinsNext) {
            case (false, false): return .single
            case (false, true): return .first
            case (true, true): return .middle
            case (true, false): return .last
            }
        }
    }
}

// MARK: - Demo

struct ChatBubbleShapeDemo: View {
    @State private var visibleCount = ChatBubbleShapeDemo.messages.count
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let messages: [(isMine: Bool, text: String)] = [
        (false, "Are you coming tonight?"),
        (true, "Yes!"),
        (true, "Running a little late"),
        (true, "Save me a seat"),
        (false, "Of course"),
        (false, "Front row, near the stage"),
        (true, "You are the best"),
    ]

    private var visible: ArraySlice<(isMine: Bool, text: String)> {
        Self.messages.prefix(visibleCount)
    }

    var body: some View {
        let positions = ChatBubbleShapeLogic.positions(for: visible.map(\.isMine))

        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.offset) { index, message in
                    bubble(message.text, isMine: message.isMine, position: positions[index])
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .defaultScrollAnchor(.bottom)
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                visibleCount = Self.messages.count
                return
            }
            while !Task.isCancelled {
                for count in 1...Self.messages.count {
                    guard !Task.isCancelled else { return }
                    withAnimation(.snappy(duration: 0.3)) { visibleCount = count }
                    try? await Task.sleep(for: .seconds(0.45))
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func bubble(_ text: String, isMine: Bool, position: ChatBubbleShapePosition) -> some View {
        Text(text)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isMine ? Color.white : Color.primary)
            .background(
                isMine ? AnyShapeStyle(.blue) : AnyShapeStyle(.quaternary),
                in: ChatBubbleShape(side: isMine ? .trailing : .leading, position: position)
            )
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
            .padding(.top, position == .single || position == .first ? 14 : 2)
    }
}

#Preview {
    ChatBubbleShapeDemo()
}
