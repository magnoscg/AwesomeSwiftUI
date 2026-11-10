// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum ToastHostRole: Equatable, Sendable {
    case info, success, warning, error

    var symbol: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: .blue
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }
}

nonisolated struct ToastHostToast: Identifiable, Equatable, Sendable {
    var id = UUID()
    var message: String
    var role = ToastHostRole.info
    var duration = Duration.seconds(3)
}

/// The toasts waiting to be shown, one at a time and in the order they arrived.
nonisolated struct ToastHostQueue: Equatable, Sendable {
    private(set) var toasts: [ToastHostToast] = []
    /// How many toasts may wait behind the one on screen. The oldest waiting one makes room.
    var limit = 3

    var current: ToastHostToast? { toasts.first }

    /// Adds a toast, unless it says the same as the last one, which a double tap would repeat.
    mutating func add(_ toast: ToastHostToast) {
        guard toasts.last?.message != toast.message || toasts.last?.role != toast.role else { return }
        toasts.append(toast)
        if toasts.count > max(limit, 0) + 1 { toasts.remove(at: 1) }
    }

    mutating func remove(id: ToastHostToast.ID) {
        toasts.removeAll { $0.id == id }
    }
}

/// Where views send their toasts. `toastHost()` puts one in the environment:
/// `@Environment(ToastHostCenter.self) private var toasts`, then `toasts.show("Saved", role: .success)`.
@MainActor @Observable final class ToastHostCenter {
    private(set) var queue = ToastHostQueue()
    @ObservationIgnored fileprivate var window: ToastHostWindow?

    func show(_ message: String, role: ToastHostRole = .info, duration: Duration = .seconds(3)) {
        queue.add(ToastHostToast(message: message, role: role, duration: duration))
    }

    func dismiss(_ toast: ToastHostToast) {
        queue.remove(id: toast.id)
    }

    /// Puts the window of the toasts over everything else in `scene`, once.
    fileprivate func attach(to scene: UIWindowScene) {
        guard window?.windowScene !== scene else { return }
        let host = UIHostingController(rootView: ToastHostOverlay(center: self))
        host.view.backgroundColor = .clear

        let window = ToastHostWindow(windowScene: scene)
        window.windowLevel = .alert - 1
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

extension View {
    /// Shows the toasts sent to its `ToastHostCenter` above everything, sheets and full-screen
    /// covers included. Put it once on the root view of a scene.
    ///
    /// The toasts live in a window of their own, so a `tint` or a `preferredColorScheme` set
    /// on your views does not reach them.
    func toastHost() -> some View {
        modifier(ToastHostModifier())
    }
}

private struct ToastHostModifier: ViewModifier {
    @State private var center = ToastHostCenter()

    func body(content: Content) -> some View {
        content
            .background { ToastHostSceneReader(center: center) }
            .environment(center)
    }
}

/// A window that lets every touch through to the app, except those on the toast it shows.
private final class ToastHostWindow: UIWindow {
    var toastFrame = CGRect.null

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        toastFrame.contains(point) ? super.hitTest(point, with: event) : nil
    }
}

/// An invisible view that finds the scene its window belongs to.
private struct ToastHostSceneReader: UIViewRepresentable {
    let center: ToastHostCenter

    func makeUIView(context: Context) -> ToastHostSceneView {
        let view = ToastHostSceneView()
        view.isUserInteractionEnabled = false
        view.onScene = { [center] scene in center.attach(to: scene) }
        return view
    }

    func updateUIView(_ view: ToastHostSceneView, context: Context) {}
}

private final class ToastHostSceneView: UIView {
    var onScene: ((UIWindowScene) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let scene = window?.windowScene { onScene?(scene) }
    }
}

private struct ToastHostOverlay: View {
    let center: ToastHostCenter

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let toast = center.queue.current {
                banner(toast)
                    .id(toast.id)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .task(id: toast.id) {
                        AccessibilityNotification.Announcement(toast.message).post()
                        try? await Task.sleep(for: toast.duration)
                        if !Task.isCancelled { center.dismiss(toast) }
                    }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.25), value: center.queue.current)
    }

    private func banner(_ toast: ToastHostToast) -> some View {
        Label {
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: toast.role.symbol)
                .foregroundStyle(toast.role.color)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { center.window?.toastFrame = $0 }
        .onDisappear { center.window?.toastFrame = .null }
        .onTapGesture { center.dismiss(toast) }
        .gesture(
            DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height < 0 { center.dismiss(toast) }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Dismisses the message")
    }
}

// MARK: - Demo

struct ToastHostDemo: View {
    var body: some View {
        ToastHostDemoScreen()
            .toastHost()
    }
}

private struct ToastHostDemoScreen: View {
    @State private var isEditing = false
    @Environment(ToastHostCenter.self) private var toasts

    var body: some View {
        VStack(spacing: 14) {
            Text("Toasts")
                .font(.largeTitle.bold())
            Text("They show above sheets too, because they live in a window of their own.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            Button("Copy Link") {
                toasts.show("Link copied", role: .success)
            }
            .buttonStyle(.borderedProminent)

            Button("Edit Profile") {
                isEditing = true
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isEditing) {
            ToastHostDemoSheet()
        }
    }
}

private struct ToastHostDemoSheet: View {
    @State private var name = "Alex Rivera"
    @Environment(ToastHostCenter.self) private var toasts
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Button("Save Changes") {
                    toasts.show("Profile saved", role: .success)
                }
                Button("Upload Photo") {
                    toasts.show("No connection. Try again.", role: .error)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ToastHostDemo()
}
