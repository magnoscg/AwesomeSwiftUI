// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct ProviderSignInButtonStackOption: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let icon: Image
    var background: Color = .indigo
    var foreground: Color = .white
    let authenticate: @MainActor () async -> Void
}

/// A stack of full-width sign-in buttons. Each shows its own spinner while it authenticates,
/// and the others wait until it is done.
///
/// For Sign in with Apple, use the system `SignInWithAppleButton`: Apple's guidelines require it.
struct ProviderSignInButtonStack: View {
    let options: [ProviderSignInButtonStackOption]
    var spacing: CGFloat = 12

    @State private var loadingID: ProviderSignInButtonStackOption.ID?
    @State private var running: Task<Void, Never>?
    @ScaledMetric(relativeTo: .headline) private var minimumHeight = 54.0
    @ScaledMetric(relativeTo: .headline) private var iconSize = 24.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: max(spacing, 0)) {
            ForEach(options) { option in
                button(for: option)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: loadingID)
        .onDisappear {
            running?.cancel()
            running = nil
            loadingID = nil
        }
    }

    private func button(for option: ProviderSignInButtonStackOption) -> some View {
        let isLoading = loadingID == option.id
        let isWaiting = loadingID != nil && !isLoading

        return Button {
            start(option)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(option.foreground)
                    } else {
                        option.icon
                            .resizable()
                            .scaledToFit()
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: iconSize, height: iconSize)

                Text(option.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .foregroundStyle(option.foreground)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .background(option.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isWaiting ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        // Not `disabled`, which would also dim the button that is signing in.
        .allowsHitTesting(loadingID == nil)
        .accessibilityLabel(option.title)
        .accessibilityValue(isLoading ? "Signing in" : "")
    }

    private func start(_ option: ProviderSignInButtonStackOption) {
        guard loadingID == nil else { return }
        loadingID = option.id
        let authenticate = option.authenticate

        running = Task {
            await authenticate()
            guard !Task.isCancelled else { return }
            loadingID = nil
            running = nil
        }
    }
}

// MARK: - Demo

struct ProviderSignInButtonStackDemo: View {
    @State private var status = "Choose how to sign in"

    private var options: [ProviderSignInButtonStackOption] {
        [
            option("passkey", "Continue with Passkey", symbol: "person.badge.key.fill", color: .indigo),
            option("email", "Continue with Email", symbol: "envelope.fill", color: .teal),
            option("phone", "Continue with Phone", symbol: "phone.fill", color: .pink),
        ]
    }

    private func option(_ id: String, _ title: LocalizedStringResource, symbol: String, color: Color) -> ProviderSignInButtonStackOption {
        ProviderSignInButtonStackOption(id: id, title: title, icon: Image(systemName: symbol), background: color) {
            do {
                try await Task.sleep(for: .seconds(1.4))
            } catch {
                return
            }
            status = "Signed in with \(id)"
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "lock.shield.fill")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)

            Text(status)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.center)

            ProviderSignInButtonStack(options: options)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProviderSignInButtonStackDemo()
}
