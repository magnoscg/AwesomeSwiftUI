// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum BottomDrawerSnapping {
    /// The stop closest to where a drag would come to rest. A drag upwards has a negative `predictedDrag`.
    static func stop(from current: CGFloat, predictedDrag: CGFloat, stops: [CGFloat]) -> CGFloat {
        let projected = current - predictedDrag
        return stops.min { abs($0 - projected) < abs($1 - projected) } ?? current
    }

    /// The stop `step` places away from `current`, held at the ends. With no stops it keeps `current`.
    static func stop(from current: CGFloat, step: Int, stops: [CGFloat]) -> CGFloat {
        let sorted = stops.sorted()
        guard !sorted.isEmpty else { return current }
        let index = sorted.firstIndex(of: current) ?? 0
        return sorted[min(max(index + step, 0), sorted.count - 1)]
    }

    /// Keeps the drawer between its lowest and highest stop while it is dragged.
    static func clamped(_ value: CGFloat, stops: [CGFloat]) -> CGFloat {
        guard let lowest = stops.min(), let highest = stops.max() else { return value }
        return min(max(value, lowest), highest)
    }
}

/// A drawer that rests on detents, given as fractions of the available height.
///
/// Place it above your content in a `ZStack`. The whole drawer is draggable, so keep scrolling
/// content out of it. VoiceOver adjusts the handle. With Reduce Motion on, the drawer snaps without a spring.
struct BottomDrawer<Content: View>: View {
    @Binding var detent: CGFloat
    var detents: [CGFloat] = [0.16, 0.5, 0.88]
    @ViewBuilder var content: Content

    @State private var dragTranslation: CGFloat = 0
    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2)
    }

    var body: some View {
        GeometryReader { proxy in
            let total = max(proxy.size.height, 1)
            let visible = BottomDrawerSnapping.clamped(detent - dragTranslation / total, stops: detents)

            VStack(spacing: 0) {
                handle
                content
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: (detents.max() ?? 1) * total, alignment: .top)
            .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
            .shadow(color: .black.opacity(0.18), radius: 18, y: -4)
            .contentShape(.rect)
            .offset(y: total * (1 - visible))
            .gesture(dragGesture(total: total))
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: isDragging) { _, dragging in
            if !dragging { withAnimation(animation) { dragTranslation = 0 } }
        }
    }

    private var handle: some View {
        Capsule()
            .fill(.secondary)
            .frame(width: 40, height: 5)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
            .accessibilityElement()
            .accessibilityLabel("Drawer")
            .accessibilityValue("Position \(sortedIndex + 1) of \(detents.count)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: moveDetent(by: 1)
                case .decrement: moveDetent(by: -1)
                @unknown default: break
                }
            }
    }

    private var sortedDetents: [CGFloat] { detents.sorted() }
    private var sortedIndex: Int { sortedDetents.firstIndex(of: detent) ?? 0 }

    private func moveDetent(by step: Int) {
        withAnimation(animation) { detent = BottomDrawerSnapping.stop(from: detent, step: step, stops: detents) }
    }

    private func dragGesture(total: CGFloat) -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { dragTranslation = $0.translation.height }
            .onEnded { value in
                let target = BottomDrawerSnapping.stop(
                    from: detent,
                    predictedDrag: value.predictedEndTranslation.height / total,
                    stops: detents
                )
                withAnimation(animation) {
                    detent = target
                    dragTranslation = 0
                }
            }
    }
}

// MARK: - Demo

struct BottomDrawerDemo: View {
    @State private var detent: CGFloat = 0.16

    private let places = [
        ("Harbor Coffee", "cup.and.saucer.fill", Color.brown),
        ("City Library", "books.vertical.fill", Color.indigo),
        ("Riverside Park", "leaf.fill", Color.green),
        ("Old Town Bakery", "birthday.cake.fill", Color.pink),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .cyan, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Image(systemName: "mappin.and.ellipse")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.white)
                .shadow(radius: 6)
                .offset(y: -180)
                .accessibilityHidden(true)

            BottomDrawer(detent: $detent) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Nearby")
                        .font(.title2.bold())

                    ForEach(places, id: \.0) { name, symbol, color in
                        Label {
                            Text(name).font(.headline)
                        } icon: {
                            Image(systemName: symbol).foregroundStyle(color.gradient)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
        }
    }
}

#Preview {
    BottomDrawerDemo()
}
