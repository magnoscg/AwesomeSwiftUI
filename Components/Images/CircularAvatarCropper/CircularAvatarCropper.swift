// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// The zoom and position of a photo under the crop window. `offset` is a fraction of the window's
/// diameter, so a crop survives a change of size.
struct CircularAvatarCropperTransform: Equatable, Sendable {
    var zoom: CGFloat = 1
    var offset = CGSize.zero

    /// The photo's size at zoom 1, where its shorter side matches a window of diameter 1.
    static func fillSize(aspectRatio: CGFloat) -> CGSize {
        guard aspectRatio.isFinite else { return CGSize(width: 1, height: 1) }
        let ratio = min(max(aspectRatio, 0.01), 100)
        return ratio >= 1 ? CGSize(width: ratio, height: 1) : CGSize(width: 1, height: 1 / ratio)
    }

    /// Keeps the zoom in range and the window fully covered by the photo.
    func clamped(aspectRatio: CGFloat, maxZoom: CGFloat) -> Self {
        let fill = Self.fillSize(aspectRatio: aspectRatio)
        let safeZoom = min(max(zoom, 1), max(maxZoom, 1))
        let limit = CGSize(width: (fill.width * safeZoom - 1) / 2, height: (fill.height * safeZoom - 1) / 2)
        return Self(
            zoom: safeZoom,
            offset: CGSize(
                width: min(max(offset.width, -limit.width), limit.width),
                height: min(max(offset.height, -limit.height), limit.height)
            )
        )
    }

    /// The part of the photo inside the window, with every value from 0 to 1.
    func normalizedCropRect(aspectRatio: CGFloat) -> CGRect {
        let fill = Self.fillSize(aspectRatio: aspectRatio)
        let shown = CGSize(width: fill.width * zoom, height: fill.height * zoom)
        let size = CGSize(width: 1 / shown.width, height: 1 / shown.height)
        return CGRect(
            x: 0.5 - offset.width / shown.width - size.width / 2,
            y: 0.5 - offset.height / shown.height - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

nonisolated private struct CircularAvatarCropperDim: Shape {
    let diameter: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addEllipse(in: CGRect(x: rect.midX - diameter / 2, y: rect.midY - diameter / 2, width: diameter, height: diameter))
        return path
    }
}

/// A photo you pan and pinch under a fixed circular window to choose an avatar crop.
///
/// Read `normalizedCropRect(aspectRatio:)` from the binding to cut the real image. `aspectRatio`
/// is the photo's width divided by its height. VoiceOver zooms by swiping up or down, and pans
/// with custom actions.
struct CircularAvatarCropper: View {
    let image: Image
    let aspectRatio: CGFloat
    @Binding var crop: CircularAvatarCropperTransform
    var maxZoom: CGFloat = 4
    var windowInset: CGFloat = 24

    @GestureState private var translation = CGSize.zero
    @GestureState private var magnification: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(min(geometry.size.width, geometry.size.height) - 2 * max(windowInset, 0), 1)
            let fill = CircularAvatarCropperTransform.fillSize(aspectRatio: aspectRatio)
            let shown = liveCrop(diameter: diameter)

            image
                .resizable()
                .frame(width: fill.width * diameter, height: fill.height * diameter)
                .scaleEffect(shown.zoom)
                .offset(x: shown.offset.width * diameter, y: shown.offset.height * diameter)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay { window(diameter: diameter) }
                .contentShape(.rect)
                .gesture(pan(diameter: diameter).simultaneously(with: pinch))
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar crop")
        .accessibilityValue("\(Int(crop.clamped(aspectRatio: aspectRatio, maxZoom: maxZoom).zoom * 100)) percent zoom")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: update { $0.zoom += 0.25 }
            case .decrement: update { $0.zoom -= 0.25 }
            @unknown default: break
            }
        }
        .accessibilityActions {
            Button("Move photo left") { update { $0.offset.width -= 0.1 } }
            Button("Move photo right") { update { $0.offset.width += 0.1 } }
            Button("Move photo up") { update { $0.offset.height -= 0.1 } }
            Button("Move photo down") { update { $0.offset.height += 0.1 } }
        }
    }

    private func window(diameter: CGFloat) -> some View {
        ZStack {
            CircularAvatarCropperDim(diameter: diameter)
                .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: diameter, height: diameter)
        }
        .allowsHitTesting(false)
    }

    private func liveCrop(diameter: CGFloat) -> CircularAvatarCropperTransform {
        var shown = crop
        shown.zoom *= magnification
        shown.offset.width += translation.width / diameter
        shown.offset.height += translation.height / diameter
        return shown.clamped(aspectRatio: aspectRatio, maxZoom: maxZoom)
    }

    private func pan(diameter: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                update {
                    $0.offset.width += value.translation.width / diameter
                    $0.offset.height += value.translation.height / diameter
                }
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .updating($magnification) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                update { $0.zoom *= value.magnification }
            }
    }

    private func update(_ change: (inout CircularAvatarCropperTransform) -> Void) {
        var next = crop
        change(&next)
        crop = next.clamped(aspectRatio: aspectRatio, maxZoom: maxZoom)
    }
}

// MARK: - Demo

struct CircularAvatarCropperDemo: View {
    @State private var crop = CircularAvatarCropperTransform()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let aspectRatio: CGFloat = 3 / 4
    private let photo = demoPhoto()
    private let avatarSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            CircularAvatarCropper(image: photo, aspectRatio: aspectRatio, crop: $crop)

            HStack(spacing: 12) {
                avatar
                Spacer(minLength: 0)
                control("Zoom out", systemImage: "minus.magnifyingglass") { $0.zoom -= 0.75 }
                control("Zoom in", systemImage: "plus.magnifyingglass") { $0.zoom += 0.75 }
                control("Reset", systemImage: "arrow.counterclockwise") { $0 = CircularAvatarCropperTransform() }
            }
            .padding(16)
        }
        .background(.black)
        .preferredColorScheme(.dark)
    }

    private var avatar: some View {
        let fill = CircularAvatarCropperTransform.fillSize(aspectRatio: aspectRatio)
        return photo
            .resizable()
            .frame(width: fill.width * avatarSize, height: fill.height * avatarSize)
            .scaleEffect(crop.zoom)
            .offset(x: crop.offset.width * avatarSize, y: crop.offset.height * avatarSize)
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(.circle)
            .accessibilityLabel("Avatar preview")
    }

    private func control(
        _ title: String,
        systemImage: String,
        change: @escaping (inout CircularAvatarCropperTransform) -> Void
    ) -> some View {
        Button {
            var next = crop
            change(&next)
            withAnimation(reduceMotion ? nil : .snappy) {
                crop = next.clamped(aspectRatio: aspectRatio, maxZoom: 4)
            }
        } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 900, height: 1200)
    return Image(size: size, label: Text("Portrait")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [.teal, .blue, .indigo]), startPoint: .zero, endPoint: CGPoint(x: 900, y: 1200))
        )
        context.fill(Path(ellipseIn: CGRect(x: 310, y: 330, width: 280, height: 340)), with: .color(Color(red: 1, green: 0.84, blue: 0.7)))
        context.fill(Path(ellipseIn: CGRect(x: 190, y: 740, width: 520, height: 700)), with: .color(.orange))
        context.fill(Path(CGRect(x: 310, y: 300, width: 280, height: 120)), with: .color(Color(red: 0.25, green: 0.15, blue: 0.1)))
    }
}

#Preview {
    CircularAvatarCropperDemo()
}
