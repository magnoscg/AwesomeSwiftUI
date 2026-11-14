// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum PinchZoomViewMath {
    static func clamp(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }

    /// Follows the value inside the range and resists beyond it, so a gesture can overshoot a little.
    static func rubberBand(_ value: CGFloat, in range: ClosedRange<CGFloat>, resistance: CGFloat = 0.3) -> CGFloat {
        let limit = clamp(value, to: range)
        return limit + (value - limit) * resistance
    }

    /// How far content filling its container can move before showing an empty edge.
    static func maxOffset(scale: CGFloat, size: CGSize) -> CGSize {
        CGSize(width: max((scale - 1) * size.width / 2, 0), height: max((scale - 1) * size.height / 2, 0))
    }

    static func clampedOffset(_ offset: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        let limit = maxOffset(scale: scale, size: size)
        return CGSize(
            width: clamp(offset.width, to: -limit.width...limit.width),
            height: clamp(offset.height, to: -limit.height...limit.height)
        )
    }
}

/// Pinch to zoom and drag to pan. Going past the limits springs back when you let go.
///
/// Double tap toggles the zoom. With Reduce Motion on, it settles without a spring.
struct PinchZoomView<Content: View>: View {
    @Binding var scale: CGFloat
    var minScale: CGFloat = 1
    var maxScale: CGFloat = 4
    @ViewBuilder var content: () -> Content

    @State private var pinch: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var drag = CGSize.zero
    @State private var size = CGSize.zero
    @GestureState private var isGesturing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Gestures report screen points, but layout mirrors in right-to-left layouts: 1 or -1 converts between them.
    private var forward: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }

    private var settle: Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.45, bounce: 0.25)
    }

    private var liveScale: CGFloat {
        PinchZoomViewMath.rubberBand(scale * pinch, in: minScale...maxScale)
    }

    private var liveOffset: CGSize {
        let limit = PinchZoomViewMath.maxOffset(scale: liveScale, size: size)
        return CGSize(
            width: PinchZoomViewMath.rubberBand(offset.width + drag.width, in: -limit.width...limit.width),
            height: PinchZoomViewMath.rubberBand(offset.height + drag.height, in: -limit.height...limit.height)
        )
    }

    var body: some View {
        content()
            .scaleEffect(liveScale)
            .offset(liveOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .clipped()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
                size = newSize
                offset = PinchZoomViewMath.clampedOffset(offset, scale: scale, size: newSize)
            }
            .gesture(zoomAndPan)
            .onChange(of: isGesturing) { _, gesturing in
                if !gesturing { settleGesture() }
            }
            .onTapGesture(count: 2) { zoom(to: scale > minScale ? minScale : min(2, maxScale)) }
            .onChange(of: scale) { _, newScale in
                withAnimation(settle) { offset = PinchZoomViewMath.clampedOffset(offset, scale: newScale, size: size) }
            }
            .accessibilityValue("\(Int((scale * 100).rounded())) percent")
            .accessibilityZoomAction { action in
                zoom(to: scale + (action.direction == .zoomIn ? 0.5 : -0.5))
            }
    }

    private var zoomAndPan: some Gesture {
        MagnifyGesture()
            .simultaneously(with: DragGesture(minimumDistance: 4))
            .updating($isGesturing) { _, state, _ in state = true }
            .onChanged { value in
                if let magnification = value.first?.magnification { pinch = magnification }
                if let translation = value.second?.translation {
                    drag = CGSize(width: translation.width * forward, height: translation.height)
                }
            }
            .onEnded { _ in settleGesture() }
    }

    /// Commits the live pinch and drag. A gesture the system cancels skips `onEnded`, so this
    /// also runs when `isGesturing` resets. Running it twice changes nothing.
    private func settleGesture() {
        let newScale = PinchZoomViewMath.clamp(scale * pinch, to: minScale...maxScale)
        let target = CGSize(width: offset.width + drag.width, height: offset.height + drag.height)
        withAnimation(settle) {
            scale = newScale
            pinch = 1
            drag = .zero
            offset = PinchZoomViewMath.clampedOffset(target, scale: newScale, size: size)
        }
    }

    private func zoom(to target: CGFloat) {
        withAnimation(settle) { scale = PinchZoomViewMath.clamp(target, to: minScale...maxScale) }
    }
}

// MARK: - Demo

struct PinchZoomViewDemo: View {
    @State private var scale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var zoomText: String {
        Double(scale).formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PinchZoomView(scale: $scale) { scene }
                .ignoresSafeArea()

            Text(zoomText)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: .capsule)
                .padding(.bottom, 24)
                .accessibilityLabel("Zoom \(zoomText)")
        }
        .task {
            guard !reduceMotion else { return }
            for target: CGFloat in [2.6, 1, 2.6, 1] {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) { scale = target }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var scene: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .pink, .orange], startPoint: .top, endPoint: .bottom)

            Image(systemName: "sun.max.fill")
                .font(.system(.largeTitle))
                .imageScale(.large)
                .foregroundStyle(.yellow)
                .offset(y: -120)

            Image(systemName: "mountain.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black.opacity(0.45))
                .padding(28)
                .offset(y: 90)
        }
        .accessibilityElement()
        .accessibilityLabel("A mountain at sunset")
    }
}

#Preview {
    PinchZoomViewDemo()
}
