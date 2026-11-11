// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum DownloadPillProgressState: Equatable {
    case idle
    case downloading(Double)
    case finished
}

/// A capsule button that shrinks into a progress ring while downloading, then shows a checkmark.
struct DownloadPillProgress: View {
    var title: LocalizedStringResource = "Download"
    let state: DownloadPillProgressState
    var tint: Color = .blue
    let action: () -> Void

    @ScaledMetric(relativeTo: .headline) private var height: CGFloat = 46
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        guard case .downloading(let progress) = state, progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }

    private var stage: Int {
        switch state {
        case .idle: 0
        case .downloading: 1
        case .finished: 2
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                switch state {
                case .idle:
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(DownloadPillProgressContrastingForeground(background: background))
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                case .downloading:
                    ring.transition(.scale(scale: 0.6).combined(with: .opacity))
                case .finished:
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(DownloadPillProgressContrastingForeground(background: background))
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .frame(minWidth: height, minHeight: height)
            .background(background, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.25), value: stage)
        .sensoryFeedback(.success, trigger: stage) { _, new in new == 2 }
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityText)
    }

    private var background: Color {
        switch state {
        case .idle: tint
        case .downloading: tint.opacity(0.14)
        case .finished: .green
        }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.25), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.12), value: fraction)
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: height * 0.22, height: height * 0.22)
        }
        .frame(width: height * 0.62, height: height * 0.62)
    }

    private var accessibilityText: String {
        switch state {
        case .idle: "Not downloaded"
        case .downloading: "Downloading, \(fraction.formatted(.percent.precision(.fractionLength(0))))"
        case .finished: "Finished"
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct DownloadPillProgressContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct DownloadPillProgressDemo: View {
    @State private var state = DownloadPillProgressState.idle
    @State private var downloadID = 0

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "shippingbox.fill")
                .font(.system(.largeTitle, weight: .semibold))
                .imageScale(.large)
                .foregroundStyle(.white)
                .padding(26)
                .background(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 26, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("Field Guide")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("482 MB")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DownloadPillProgress(state: state, action: tapped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .task(id: downloadID) {
            guard state == .downloading(0) else { return }
            for step in 1...40 {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, state != .idle else { return }
                state = .downloading(Double(step) / 40)
            }
            state = .finished
        }
    }

    private func tapped() {
        switch state {
        case .idle:
            state = .downloading(0)
            downloadID += 1
        case .downloading, .finished:
            state = .idle
        }
    }
}

#Preview {
    DownloadPillProgressDemo()
}
