// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct FloatingDockBarItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let colors: [Color]
    let action: () -> Void
}

enum FloatingDockBarMath {
    /// Grows smoothly from 1 at `spread` away from the finger to `maxScale` right under it.
    static func scale(distance: CGFloat, spread: CGFloat, maxScale: CGFloat) -> CGFloat {
        guard spread > 0, maxScale > 1 else { return 1 }
        let normalized = min(abs(distance) / spread, 1)
        let falloff = cos(normalized * .pi / 2)
        return 1 + (maxScale - 1) * falloff * falloff
    }

    /// Shrinks the icons when they would not all fit in the space available.
    static func iconSize(preferred: CGFloat, available: CGFloat, count: Int, spacing: CGFloat, padding: CGFloat) -> CGFloat {
        guard count > 0, available > 0 else { return max(preferred, 0) }
        let usable = available - 2 * padding - CGFloat(count - 1) * spacing
        return max(min(preferred, usable / CGFloat(count)), 20)
    }

    static func centerX(index: Int, iconSize: CGFloat, spacing: CGFloat) -> CGFloat {
        iconSize / 2 + CGFloat(index) * (iconSize + spacing)
    }
}

/// A row of icons that magnify under the finger, in the style of the macOS dock.
///
/// With Reduce Motion on, the magnification is small and has no spring. The dock only
/// holds icons, so it stops growing past the larger text sizes.
struct FloatingDockBar: View {
    let items: [FloatingDockBarItem]
    var maxScale: CGFloat = 1.6

    var body: some View {
        FloatingDockBarStage(items: items, maxScale: maxScale)
            // The stage reads its icon size under this cap.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct FloatingDockBarStage: View {
    let items: [FloatingDockBarItem]
    let maxScale: CGFloat

    private let spacing: CGFloat = 12
    private let padding: CGFloat = 12

    @GestureState private var fingerX: CGFloat?
    @State private var availableWidth: CGFloat = 0
    @ScaledMetric(relativeTo: .title2) private var preferredIconSize = 56.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    private var effectiveMaxScale: CGFloat { reduceMotion ? min(maxScale, 1.15) : maxScale }

    private var rowWidth: CGFloat {
        CGFloat(items.count) * iconSize + CGFloat(max(items.count - 1, 0)) * spacing
    }

    private var iconSize: CGFloat {
        FloatingDockBarMath.iconSize(preferred: preferredIconSize, available: availableWidth, count: items.count, spacing: spacing, padding: padding)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                iconButton(item, scale: scale(at: index))
                    .zIndex(Double(scale(at: index)))
            }
        }
        // Simultaneous, so the buttons inside keep working for taps and VoiceOver.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0).updating($fingerX) { value, state, _ in
                // Gestures report screen points, but the row of icons mirrors in right-to-left layouts.
                state = layoutDirection == .rightToLeft ? rowWidth - value.location.x : value.location.x
            }
        )
        .padding(padding)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 26))
        .padding(.top, iconSize * max(effectiveMaxScale - 1, 0))
        // minWidth 0 makes this the width on offer, even while the icons are too wide for it.
        .frame(minWidth: 0, maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.72), value: fingerX)
    }

    private func scale(at index: Int) -> CGFloat {
        guard let fingerX else { return 1 }
        let center = FloatingDockBarMath.centerX(index: index, iconSize: iconSize, spacing: spacing)
        return FloatingDockBarMath.scale(distance: fingerX - center, spread: (iconSize + spacing) * 2.2, maxScale: effectiveMaxScale)
    }

    private func iconButton(_ item: FloatingDockBarItem, scale: CGFloat) -> some View {
        Button(action: item.action) {
            RoundedRectangle(cornerRadius: iconSize * 0.25)
                .fill(LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: item.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(scale, anchor: .bottom)
        .accessibilityLabel(item.title)
    }
}

// MARK: - Demo

struct FloatingDockBarDemo: View {
    @State private var opened = "Drag across the dock"

    private var items: [FloatingDockBarItem] {
        [
            FloatingDockBarItem(id: "mail", title: "Mail", systemImage: "envelope.fill", colors: [.cyan, .blue]) { opened = "Mail" },
            FloatingDockBarItem(id: "photos", title: "Photos", systemImage: "photo.fill", colors: [.yellow, .orange]) { opened = "Photos" },
            FloatingDockBarItem(id: "music", title: "Music", systemImage: "music.note", colors: [.pink, .red]) { opened = "Music" },
            FloatingDockBarItem(id: "notes", title: "Notes", systemImage: "note.text", colors: [.mint, .green]) { opened = "Notes" },
            FloatingDockBarItem(id: "settings", title: "Settings", systemImage: "gearshape.fill", colors: [.gray, .indigo]) { opened = "Settings" },
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            FloatingDockBar(items: items)
                .padding(.horizontal, 16)
        }
        .overlay(alignment: .top) {
            Text(opened)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 60)
        }
    }
}

#Preview {
    FloatingDockBarDemo()
}
