// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Wraps a photo, usually an `Image`. A double tap throws a heart at the finger and marks it as liked.
///
/// With Reduce Motion on, the heart appears in place and fades out.
struct DoubleTapHeartOverlay<Content: View>: View {
    @Binding var isLiked: Bool
    var tint: Color = .pink
    /// Throws a heart without a touch, for demos. Each new value throws one more.
    var programmaticBurst: DoubleTapHeartOverlayRequest? = nil
    @ViewBuilder var content: () -> Content

    @State private var hearts: [DoubleTapHeartOverlayBurst] = []
    @State private var size = CGSize.zero
    @Environment(\.layoutDirection) private var layoutDirection

    private let maximumHearts = 12

    var body: some View {
        content()
            .overlay {
                ZStack {
                    ForEach(hearts) { heart in
                        DoubleTapHeartOverlayHeart(rotation: heart.rotation, tint: tint) {
                            hearts.removeAll { $0.id == heart.id }
                        }
                        .position(heart.location)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .contentShape(.rect)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .gesture(
                SpatialTapGesture(count: 2).onEnded { value in
                    // Gestures report screen points, but `position` mirrors in right-to-left layouts.
                    let x = layoutDirection == .rightToLeft ? size.width - value.location.x : value.location.x
                    throwHeart(at: CGPoint(x: x, y: value.location.y))
                }
            )
            .onChange(of: programmaticBurst) { _, request in
                guard let request else { return }
                throwHeart(at: CGPoint(x: request.point.x * size.width, y: request.point.y * size.height))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: hearts.count) { old, new in new > old }
            .accessibilityAction(named: isLiked ? "Unlike" : "Like") { isLiked.toggle() }
    }

    private func throwHeart(at location: CGPoint) {
        hearts.append(DoubleTapHeartOverlayBurst(location: location, rotation: .random(in: -18...18)))
        if hearts.count > maximumHearts { hearts.removeFirst() }
        isLiked = true
    }
}

struct DoubleTapHeartOverlayRequest: Equatable {
    let id = UUID()
    let point: UnitPoint
}

struct DoubleTapHeartOverlayBurst: Identifiable {
    let id = UUID()
    let location: CGPoint
    let rotation: Double
}

private struct DoubleTapHeartOverlayHeart: View {
    let rotation: Double
    let tint: Color
    let onFinish: () -> Void

    @State private var scale = 0.3
    @State private var opacity = 0.0
    @State private var rise = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.largeTitle)
            .imageScale(.large)
            .scaleEffect(1.6)
            .foregroundStyle(tint.gradient)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(scale)
            .rotationEffect(.degrees(reduceMotion ? 0 : rotation))
            .offset(y: rise)
            .opacity(opacity)
            .onAppear(perform: run)
    }

    private func run() {
        if reduceMotion {
            scale = 1
            opacity = 1
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 0
            } completion: {
                onFinish()
            }
            return
        }

        withAnimation(.spring(duration: 0.3, bounce: 0.55)) {
            scale = 1
            opacity = 1
        } completion: {
            withAnimation(.easeIn(duration: 0.35).delay(0.15)) {
                rise = -70
                scale = 0.8
                opacity = 0
            } completion: {
                onFinish()
            }
        }
    }
}

// MARK: - Demo

struct DoubleTapHeartOverlayDemo: View {
    @State private var isLiked = false
    @State private var burst: DoubleTapHeartOverlayRequest?
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                DoubleTapHeartOverlay(isLiked: $isLiked, programmaticBurst: burst) {
                    placeholderPhoto
                }

                HStack(spacing: 14) {
                    Button {
                        isLiked.toggle()
                    } label: {
                        // The icon is too small to hit. The padding widens what answers to a
                        // touch, and the same padding taken back keeps the row as it was.
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isLiked ? .pink : .primary)
                            .symbolEffect(.bounce, value: isLiked)
                            .padding(10)
                            .contentShape(.rect)
                            .padding(-10)
                    }
                    .accessibilityLabel(isLiked ? "Unlike" : "Like")

                    Text(isLiked ? "You liked this" : "Double tap the photo")
                        .font(.headline)

                    Spacer()
                }
                .padding(18)
            }
            .background(.background)
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .padding(20)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await playHearts()
        }
    }

    // Only the demo plays by itself, because a real double tap needs a finger.
    private func playHearts() async {
        let points = [UnitPoint(x: 0.5, y: 0.45), UnitPoint(x: 0.28, y: 0.28), UnitPoint(x: 0.72, y: 0.62)]
        while isAutoPlaying {
            for point in points {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled, isAutoPlaying else { return }
                burst = DoubleTapHeartOverlayRequest(point: point)
            }
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled, isAutoPlaying else { return }
            isLiked = false
        }
    }

    private var placeholderPhoto: some View {
        LinearGradient(colors: [.orange, .pink, .purple], startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity, maxHeight: 520)
            .overlay(alignment: .bottom) {
                Image(systemName: "mountain.2.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .scaleEffect(2.6)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 80)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sun.max.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow.opacity(0.85))
                    .padding(28)
            }
            .accessibilityElement()
            .accessibilityLabel("Photo of mountains at sunset")
    }
}

#Preview {
    DoubleTapHeartOverlayDemo()
}
