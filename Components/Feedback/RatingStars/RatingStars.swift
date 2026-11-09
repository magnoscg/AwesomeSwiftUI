// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum RatingStarsValue {
    /// Keeps a rating between zero and the number of stars.
    static func clamped(_ rating: Int, maximum: Int) -> Int {
        min(max(rating, 0), max(maximum, 0))
    }
}

/// A row of tappable stars. Each star pops with a spring when it fills.
///
/// VoiceOver treats the row as one adjustable value. With Reduce Motion on, the stars only change color.
struct RatingStars: View {
    @Binding var rating: Int
    var maximum: Int = 5
    var color: Color = .orange

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...max(maximum, 1), id: \.self) { star in
                starButton(star)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) of \(maximum) stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = RatingStarsValue.clamped(rating + 1, maximum: maximum)
            case .decrement: rating = RatingStarsValue.clamped(rating - 1, maximum: maximum)
            @unknown default: break
            }
        }
    }

    private func starButton(_ star: Int) -> some View {
        let isFilled = star <= rating

        return Button {
            rating = RatingStarsValue.clamped(star, maximum: maximum)
        } label: {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(isFilled ? AnyShapeStyle(color.gradient) : AnyShapeStyle(.quaternary))
                .animation(.easeOut(duration: 0.15), value: isFilled)
                .phaseAnimator([1.0, 1.4], trigger: isFilled) { view, scale in
                    view.scaleEffect(isFilled && !reduceMotion ? scale : 1)
                } animation: { scale in
                    scale > 1 ? .easeOut(duration: 0.1) : .spring(duration: 0.4, bounce: 0.6)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Demo

struct RatingStarsDemo: View {
    @State private var rating = 0
    @State private var isAutoPlaying = true

    /// Any change made by the user, by touch or VoiceOver, ends the automatic rating.
    private var userRating: Binding<Int> {
        Binding(
            get: { rating },
            set: { newValue in
                isAutoPlaying = false
                rating = newValue
            }
        )
    }

    private var caption: String {
        ["Tap a star", "Terrible", "Not great", "It was fine", "Really good", "Loved it"][rating]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange.opacity(0.25), .pink.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .imageScale(.large)
                    .foregroundStyle(.orange.gradient)
                    .accessibilityHidden(true)

                Text("How was your dinner?")
                    .font(.title2.bold())

                RatingStars(rating: userRating)

                Text(caption)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.default, value: rating)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: .rect(cornerRadius: 28))
            .padding(24)
        }
        .task(id: isAutoPlaying) {
            guard isAutoPlaying else { return }
            let script = [3, 5, 2, 4]
            var step = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
                rating = script[step % script.count]
                step += 1
            }
        }
    }
}

#Preview {
    RatingStarsDemo()
}
