// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// Shrinks and dims a button while it is pressed, then springs back.
///
/// With Reduce Motion on, the button only dims.
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.94
    var pressedOpacity: Double = 0.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.spring(duration: 0.3, bounce: 0.45), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

// MARK: - Demo

struct PressableButtonStyleDemo: View {
    @State private var likes = 0

    var body: some View {
        VStack(spacing: 28) {
            Text(likes == 1 ? "1 like" : "\(likes) likes")
                .font(.largeTitle.bold())
                .contentTransition(.numericText())

            Button {
                withAnimation { likes += 1 }
            } label: {
                Label("Like", systemImage: "heart.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 20)
                    .background(.pink.gradient, in: .capsule)
            }
            .buttonStyle(.pressable)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PressableButtonStyleDemo()
}
