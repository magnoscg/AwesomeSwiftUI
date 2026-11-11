// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct FloatingActionMenuItem {
    let title: String
    let systemImage: String
    var tint: Color = .indigo
    let action: () -> Void
}

enum FloatingActionMenuMath {
    /// The offset of an item on an arc. Angles use screen coordinates: 180 is left and 270 is up.
    static func offset(index: Int, count: Int, radius: Double, startDegrees: Double, endDegrees: Double) -> CGSize {
        guard count > 0, (0..<count).contains(index) else { return .zero }
        let fraction = count == 1 ? 0.5 : Double(index) / Double(count - 1)
        let radians = (startDegrees + (endDegrees - startDegrees) * fraction) * .pi / 180
        let length = max(radius, 0)
        return CGSize(width: cos(radians) * length, height: sin(radians) * length)
    }

    /// The radius, grown when needed so that neighbouring items do not overlap, but not past `limit`.
    static func fittedRadius(_ radius: Double, itemSize: Double, count: Int, startDegrees: Double, endDegrees: Double, limit: Double = .infinity) -> Double {
        guard count > 1 else { return radius }
        let step = abs(endDegrees - startDegrees) / Double(count - 1) * .pi / 180
        let chordPerRadius = 2 * sin(step / 2)
        guard chordPerRadius > 0.01 else { return radius }
        return max(radius, min((itemSize + 6) / chordPerRadius, limit))
    }

    /// The largest radius that keeps every item at least `inset` away from the edges of `container`.
    static func radiusLimit(center: CGPoint, container: CGSize, inset: Double, count: Int, startDegrees: Double, endDegrees: Double) -> Double {
        (0..<count).reduce(.infinity) { limit, index in
            let unit = offset(index: index, count: count, radius: 1, startDegrees: startDegrees, endDegrees: endDegrees)
            return min(
                limit,
                reach(along: unit.width, before: center.x - inset, after: container.width - center.x - inset),
                reach(along: unit.height, before: center.y - inset, after: container.height - center.y - inset)
            )
        }
    }

    private static func reach(along direction: Double, before: Double, after: Double) -> Double {
        if direction < -0.001 { return before / -direction }
        if direction > 0.001 { return after / direction }
        return .infinity
    }
}

/// A plus button that turns into a close icon and fans out its actions around it.
///
/// The fan opens up and to the left by default, for a button in the bottom-trailing corner.
/// With more than four items it widens so they do not overlap, until it reaches the edge of the screen.
/// In the corner of a phone at the default text size, the default fan fits seven actions at 320 points
/// wide and nine at 393. Any more stay on screen but overlap, so use a list for longer menus.
/// With Reduce Motion on, the actions appear in place without moving.
struct FloatingActionMenu: View {
    let items: [FloatingActionMenuItem]
    var tint: Color = .indigo
    var startDegrees = 180.0
    var endDegrees = 270.0

    var body: some View {
        FloatingActionMenuStage(items: items, tint: tint, startDegrees: startDegrees, endDegrees: endDegrees)
            // The buttons only hold icons. The stage reads its sizes under this cap, which keeps the fan on screen.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct FloatingActionMenuStage: View {
    let items: [FloatingActionMenuItem]
    let tint: Color
    let startDegrees: Double
    let endDegrees: Double

    @State private var isOpen = false
    @ScaledMetric(relativeTo: .title2) private var buttonSize = 60.0
    @ScaledMetric(relativeTo: .title2) private var itemSize = 50.0
    @ScaledMetric(relativeTo: .title2) private var radius = 112.0
    @State private var containerFrame = CGRect.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                itemButton(item, index: index)
            }

            Button {
                withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) { isOpen.toggle() }
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .rotationEffect(.degrees(isOpen ? 135 : 0))
                    .foregroundStyle(FloatingActionMenuContrastingForeground(background: tint))
                    .frame(width: buttonSize, height: buttonSize)
                    .background(tint.gradient, in: Circle())
                    .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOpen ? "Close menu" : "Open menu")
        }
        .background {
            // Centred on the button and as big as its container, so one frame gives both.
            Color.clear
                .containerRelativeFrame([.horizontal, .vertical])
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { containerFrame = $0 }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
    }

    private func itemButton(_ item: FloatingActionMenuItem, index: Int) -> some View {
        let offset = FloatingActionMenuMath.offset(
            index: index,
            count: items.count,
            radius: FloatingActionMenuMath.fittedRadius(
                radius,
                itemSize: itemSize,
                count: items.count,
                startDegrees: startDegrees,
                endDegrees: endDegrees,
                limit: FloatingActionMenuMath.radiusLimit(
                    center: CGPoint(x: containerFrame.midX, y: containerFrame.midY),
                    container: containerFrame.size,
                    inset: itemSize / 2 + 8,
                    count: items.count,
                    startDegrees: startDegrees,
                    endDegrees: endDegrees
                )
            ),
            startDegrees: startDegrees,
            endDegrees: endDegrees
        )

        return Button {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) { isOpen = false }
            item.action()
        } label: {
            Image(systemName: item.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(FloatingActionMenuContrastingForeground(background: item.tint))
                .frame(width: itemSize, height: itemSize)
                .background(item.tint, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHidden(!isOpen)
        .allowsHitTesting(isOpen)
        .scaleEffect(isOpen ? 1 : 0.4)
        .opacity(isOpen ? 1 : 0)
        .offset(isOpen ? offset : .zero)
        .animation(
            reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.32).delay(isOpen ? Double(index) * 0.04 : 0),
            value: isOpen
        )
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct FloatingActionMenuContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct FloatingActionMenuDemo: View {
    @State private var lastAction = "Tap the plus button"

    private var items: [FloatingActionMenuItem] {
        [
            FloatingActionMenuItem(title: "Share", systemImage: "square.and.arrow.up", tint: .blue) { lastAction = "Shared" },
            FloatingActionMenuItem(title: "Photo", systemImage: "camera.fill", tint: .pink) { lastAction = "Photo added" },
            FloatingActionMenuItem(title: "Note", systemImage: "note.text", tint: .orange) { lastAction = "Note added" },
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(lastAction)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingActionMenu(items: items)
                .padding(28)
        }
    }
}

#Preview {
    FloatingActionMenuDemo()
}
