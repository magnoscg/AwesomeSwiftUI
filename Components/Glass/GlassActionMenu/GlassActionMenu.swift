// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

@available(iOS 26, *)
struct GlassActionItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

/// A floating Liquid Glass button whose actions morph out of it.
///
/// With Reduce Motion on, the actions appear without morphing.
@available(iOS 26, *)
struct GlassActionMenu: View {
    nonisolated private enum GlassID: Hashable, Sendable {
        case toggle
        case item(String)
    }

    let items: [GlassActionItem]

    @State private var isExpanded = false
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .bouncy(duration: 0.5, extraBounce: 0.05)
    }

    var body: some View {
        // Known issue: iOS 27.2 reports the toggle's accessibility frame as the whole
        // stack when expanded. iOS 26.5 reports it correctly.
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 14) {
                if isExpanded {
                    ForEach(items) { item in
                        glassButton(id: .item(item.id), systemImage: item.systemImage, label: item.title) {
                            withAnimation(animation) { isExpanded = false }
                            item.action()
                        }
                    }
                }

                glassButton(
                    id: .toggle,
                    systemImage: "plus",
                    label: isExpanded ? "Close actions" : "Show actions",
                    rotation: isExpanded ? 45 : 0
                ) {
                    withAnimation(animation) { isExpanded.toggle() }
                }
            }
        }
        // The buttons only hold icons. Each icon reads its size under this cap, which keeps a tall stack on screen.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func glassButton(
        id: GlassID,
        systemImage: String,
        label: String,
        rotation: Double = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            GlassActionMenuIcon(systemImage: systemImage, rotation: rotation)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID(id, in: namespace)
    }
}

@available(iOS 26, *)
private struct GlassActionMenuIcon: View {
    let systemImage: String
    let rotation: Double

    @ScaledMetric(relativeTo: .title2) private var size = 58.0

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2.weight(.semibold))
            .rotationEffect(.degrees(rotation))
            .frame(width: size, height: size)
            .contentShape(.circle)
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassActionMenuDemo: View {
    @State private var lastAction = "Tap the button"

    private var items: [GlassActionItem] {
        [
            GlassActionItem(id: "share", title: "Share", systemImage: "square.and.arrow.up") { lastAction = "Share" },
            GlassActionItem(id: "favorite", title: "Favorite", systemImage: "star") { lastAction = "Favorite" },
            GlassActionItem(id: "delete", title: "Delete", systemImage: "trash") { lastAction = "Delete" },
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(colors: [.orange, .pink, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Text(lastAction)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlassActionMenu(items: items)
                .padding(24)
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassActionMenuDemo()
}
