// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A full-screen page that follows a downward drag and leaves when released past a threshold.
///
/// Remove the view from `onDismiss`. With Reduce Motion on, the page does not scale and
/// leaves at once. VoiceOver users dismiss it with the escape gesture.
struct DragToDismissScreen<Content: View>: View {
    var threshold: CGFloat = 140
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    @GestureState private var liveOffset: CGFloat = 0
    @State private var settledOffset: CGFloat = 0
    @State private var isDismissing = false
    @State private var screenHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat {
        DragToDismissScreenMath.progress(offset: settledOffset + liveOffset, threshold: threshold)
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(reduceMotion ? 1 : 1 - 0.1 * progress)
            .opacity(1 - 0.3 * progress)
            .offset(y: settledOffset + liveOffset)
            .gesture(dragGesture)
            .allowsHitTesting(!isDismissing)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
            .accessibilityElement(children: .contain)
            .accessibilityAction(.escape) { dismiss(from: 0) }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .updating($liveOffset) { value, state, _ in
                state = max(value.translation.height, 0)
            }
            .onEnded { value in
                let translation = max(value.translation.height, 0)
                let shouldDismiss = DragToDismissScreenMath.shouldDismiss(
                    translation: translation,
                    predicted: value.predictedEndTranslation.height,
                    threshold: threshold
                )
                if shouldDismiss {
                    dismiss(from: translation)
                } else {
                    // Takes over from the gesture state, which resets without animating.
                    settledOffset = translation
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2)) {
                        settledOffset = 0
                    }
                }
            }
    }

    private func dismiss(from offset: CGFloat) {
        guard !isDismissing else { return }
        isDismissing = true

        if reduceMotion {
            onDismiss()
            return
        }

        settledOffset = offset
        withAnimation(.easeIn(duration: 0.25), completionCriteria: .logicallyComplete) {
            settledOffset = max(screenHeight, threshold * 4)
        } completion: {
            onDismiss()
        }
    }
}

enum DragToDismissScreenMath {
    /// How far the drag has gone towards the threshold, from 0 to 1.
    static func progress(offset: CGFloat, threshold: CGFloat) -> CGFloat {
        guard threshold > 0 else { return offset > 0 ? 1 : 0 }
        return min(max(offset, 0) / threshold, 1)
    }

    /// A long drag dismisses, and so does a quick flick that was heading far enough.
    static func shouldDismiss(translation: CGFloat, predicted: CGFloat, threshold: CGFloat) -> Bool {
        guard translation > 0 else { return false }
        return translation >= threshold || predicted >= threshold * 2
    }
}

// MARK: - Demo

struct DragToDismissScreenDemo: View {
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.14)
                .ignoresSafeArea()

            Button("Open", systemImage: "arrow.up.left.and.arrow.down.right") {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { isOpen = true }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)

            if isOpen {
                DragToDismissScreen(onDismiss: { isOpen = false }) {
                    page
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
    }

    private var page: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: 44, height: 5)
                    .accessibilityHidden(true)

                Spacer()

                Image(systemName: "sun.horizon.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .accessibilityHidden(true)

                Text("Golden Hour")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Pull down to close")
                    .font(.headline)
                    .opacity(0.85)

                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.top, 12)
        }
    }
}

#Preview {
    DragToDismissScreenDemo()
}
