// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum ShutterCaptureButtonMode: String, CaseIterable, Identifiable, Sendable {
    case photo = "Photo"
    case video = "Video"

    var id: Self { self }
}

/// A camera shutter with a photo and video toggle.
///
/// In photo mode a tap calls `onCapture` and flashes a ring. In video mode a tap
/// toggles `isRecording`. With Reduce Motion on, the shape changes without moving.
struct ShutterCaptureButton: View {
    @Binding var mode: ShutterCaptureButtonMode
    @Binding var isRecording: Bool
    var onCapture: () -> Void = {}

    @State private var captureCount = 0
    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize = 80.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGFloat { min(scaledSize, 120) }
    private var animation: Animation? { reduceMotion ? nil : .snappy(duration: 0.25) }

    private var label: String {
        switch mode {
        case .photo: "Take photo"
        case .video: isRecording ? "Stop recording" : "Start recording"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 28) {
                ForEach(ShutterCaptureButtonMode.allCases) { option in
                    Button {
                        withAnimation(animation) { mode = option }
                    } label: {
                        // A word is too small to hit. The padding widens what answers to a
                        // touch, and the same padding taken back keeps the layout as it was.
                        Text(option.rawValue)
                            .padding(13)
                            .contentShape(.rect)
                            .padding(-13)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(mode == option ? Color.yellow : Color.white)
                    .accessibilityAddTraits(mode == option ? .isSelected : [])
                }
            }
            .disabled(isRecording)
            .opacity(isRecording ? 0.4 : 1)

            Button(action: shutterTapped) {
                ZStack {
                    Circle().strokeBorder(.white, lineWidth: 4)

                    if captureCount > 0, !reduceMotion {
                        ShutterCaptureButtonFlash().id(captureCount)
                    }
                }
                .frame(width: size, height: size)
                .contentShape(.circle)
            }
            .buttonStyle(ShutterCaptureButtonStyle(mode: mode, isRecording: isRecording, size: size, reduceMotion: reduceMotion))
            .accessibilityLabel(label)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: captureCount)
            .sensoryFeedback(.selection, trigger: isRecording)
        }
    }

    private func shutterTapped() {
        switch mode {
        case .photo:
            captureCount &+= 1
            onCapture()
        case .video:
            withAnimation(animation) { isRecording.toggle() }
        }
    }
}

/// Draws the inner shape: it shrinks while pressed and becomes a square while recording.
private struct ShutterCaptureButtonStyle: ButtonStyle {
    let mode: ShutterCaptureButtonMode
    let isRecording: Bool
    let size: CGFloat
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        let innerSize = size * (isRecording ? 0.42 : 0.82)

        return configuration.label
            .background {
                RoundedRectangle(cornerRadius: isRecording ? 8 : innerSize / 2)
                    .fill(mode == .video ? Color.red : Color.white)
                    .frame(width: innerSize, height: innerSize)
                    .scaleEffect(configuration.isPressed && !reduceMotion ? 0.86 : 1)
                    .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.15), value: configuration.isPressed)
            }
    }
}

private struct ShutterCaptureButtonFlash: View {
    @State private var isExpanded = false

    var body: some View {
        Circle()
            .stroke(.white, lineWidth: 3)
            .scaleEffect(isExpanded ? 1.4 : 1)
            .opacity(isExpanded ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) { isExpanded = true }
            }
    }
}

// MARK: - Demo

struct ShutterCaptureButtonDemo: View {
    @State private var mode = ShutterCaptureButtonMode.photo
    @State private var isRecording = false
    @State private var photos = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [.teal, .indigo, .purple], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        Image(systemName: "mountain.2.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .overlay(alignment: .top) {
                        Text(isRecording ? "Recording" : "^[\(photos) photo](inflect: true)")
                            .font(.footnote.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isRecording ? Color.red : Color.black.opacity(0.4), in: .capsule)
                            .padding(14)
                    }
                    .accessibilityHidden(true)

                ShutterCaptureButton(mode: $mode, isRecording: $isRecording) { photos += 1 }
            }
            .padding(16)
        }
    }
}

#Preview {
    ShutterCaptureButtonDemo()
}
