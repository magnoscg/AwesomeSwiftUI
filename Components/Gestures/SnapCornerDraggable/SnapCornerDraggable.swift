// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum SnapCornerDraggableCorner: CaseIterable, Hashable, Sendable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    var title: String {
        switch self {
        case .topLeading: "top left"
        case .topTrailing: "top right"
        case .bottomLeading: "bottom left"
        case .bottomTrailing: "bottom right"
        }
    }

    /// The corner of the quadrant a point falls in, in a container of the given size.
    static func nearest(to point: CGPoint, in size: CGSize) -> Self {
        switch (point.x < size.width / 2, point.y < size.height / 2) {
        case (true, true): .topLeading
        case (false, true): .topTrailing
        case (true, false): .bottomLeading
        case (false, false): .bottomTrailing
        }
    }
}

/// A floating view you drag anywhere. It springs to the nearest corner of the safe area when
/// released, taking the speed of the flick into account.
///
/// Use it as an overlay: the empty space lets touches through. VoiceOver offers an action for
/// each corner, and with Reduce Motion on it moves there without a spring.
struct SnapCornerDraggable<Content: View>: View {
    @Binding var corner: SnapCornerDraggableCorner
    var inset: CGFloat = 16
    @ViewBuilder var content: () -> Content

    @State private var containerSize = CGSize.zero
    @GestureState private var translation = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let space = "SnapCornerDraggable"

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.3)
    }

    var body: some View {
        content()
            .offset(translation)
            .animation(animation, value: translation == .zero)
            .gesture(drag)
            .accessibilityElement(children: .combine)
            .accessibilityActions {
                ForEach(SnapCornerDraggableCorner.allCases.filter { $0 != corner }, id: \.self) { target in
                    Button("Move to \(target.title)") {
                        withAnimation(animation) { corner = target }
                    }
                }
            }
            .padding(max(inset, 0))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment)
            .coordinateSpace(.named(space))
            .onGeometryChange(for: CGSize.self) { $0.size } action: { containerSize = $0 }
    }

    private var drag: some Gesture {
        DragGesture(coordinateSpace: .named(space))
            .updating($translation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let target = SnapCornerDraggableCorner.nearest(to: value.predictedEndLocation, in: containerSize)
                withAnimation(animation) { corner = target }
            }
    }
}

// MARK: - Demo

struct SnapCornerDraggableDemo: View {
    @State private var corner = SnapCornerDraggableCorner.bottomTrailing

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .accessibilityHidden(true)
                Text("On a call")
                    .font(.title.bold())
                Text("Drag the tile to any corner")
                    .font(.subheadline)
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            SnapCornerDraggable(corner: $corner) {
                tile
            }
        }
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
            .frame(width: 120, height: 170)
            .shadow(color: .black.opacity(0.3), radius: 14, y: 8)
            .accessibilityLabel("Your camera, \(corner.title)")
    }
}

#Preview {
    SnapCornerDraggableDemo()
}
