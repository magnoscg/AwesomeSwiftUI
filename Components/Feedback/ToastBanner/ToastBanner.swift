// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// The capsule shown by the `.toast(isPresented:)` modifier.
struct ToastBanner: View {
    let message: String
    var systemImage: String = "checkmark.circle.fill"
    var tint: Color = .green

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint.gradient)
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }
}

private struct ToastBannerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let systemImage: String
    let tint: Color
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    ToastBanner(message: message, systemImage: systemImage, tint: tint)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: message) { await announceAndDismiss() }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.3), value: isPresented)
    }

    private func announceAndDismiss() async {
        AccessibilityNotification.Announcement(message).post()
        do {
            try await Task.sleep(for: .seconds(duration))
        } catch {
            return
        }
        isPresented = false
    }
}

extension View {
    /// Slides a banner in from the top, announces it to VoiceOver and dismisses it after `duration` seconds.
    ///
    /// With Reduce Motion on, the banner fades instead of sliding.
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        systemImage: String = "checkmark.circle.fill",
        tint: Color = .green,
        duration: Double = 2.2
    ) -> some View {
        modifier(ToastBannerModifier(
            isPresented: isPresented,
            message: message,
            systemImage: systemImage,
            tint: tint,
            duration: duration
        ))
    }
}

// MARK: - Demo

struct ToastBannerDemo: View {
    @State private var showsToast = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint.opacity(0.35), .teal.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "doc.text.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.teal.gradient)
                    .accessibilityHidden(true)

                Text("Quarterly notes")
                    .font(.title2.bold())

                Button {
                    showsToast = true
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(.teal.gradient, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toast(isPresented: $showsToast, message: "Changes saved")
    }
}

#Preview {
    ToastBannerDemo()
}
