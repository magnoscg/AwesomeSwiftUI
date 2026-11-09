// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

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
}

/// A plus button that turns into a close icon and fans out its actions around it.
///
/// The fan opens up and to the left by default, for a button in the bottom-trailing corner.
/// With Reduce Motion on, the actions appear in place without moving.
struct FloatingActionMenu: View {
    let items: [FloatingActionMenuItem]
    var tint: Color = .indigo
    var startDegrees = 180.0
    var endDegrees = 270.0

    @State private var isOpen = false
    @ScaledMetric(relativeTo: .title2) private var buttonSize = 60.0
    @ScaledMetric(relativeTo: .title2) private var itemSize = 50.0
    @ScaledMetric(relativeTo: .title2) private var radius = 112.0
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
                    .foregroundStyle(.white)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(tint.gradient, in: Circle())
                    .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOpen ? "Close menu" : "Open menu")
        }
        // The buttons only hold icons. Capping their growth keeps the fan on screen.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
    }

    private func itemButton(_ item: FloatingActionMenuItem, index: Int) -> some View {
        let offset = FloatingActionMenuMath.offset(
            index: index,
            count: items.count,
            radius: radius,
            startDegrees: startDegrees,
            endDegrees: endDegrees
        )

        return Button {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) { isOpen = false }
            item.action()
        } label: {
            Image(systemName: item.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
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
