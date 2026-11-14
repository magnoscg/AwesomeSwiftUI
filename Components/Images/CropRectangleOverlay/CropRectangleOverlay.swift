// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A part of the crop frame that can be dragged. Rectangles are normalized, from 0 to 1.
enum CropRectangleOverlayHandle: CaseIterable, Hashable, Sendable {
    case body, top, right, bottom, left, topLeft, topRight, bottomRight, bottomLeft

    private var movesLeft: Bool { self == .left || self == .topLeft || self == .bottomLeft }
    private var movesRight: Bool { self == .right || self == .topRight || self == .bottomRight }
    private var movesTop: Bool { self == .top || self == .topLeft || self == .topRight }
    private var movesBottom: Bool { self == .bottom || self == .bottomLeft || self == .bottomRight }

    func adjusting(_ rect: CGRect, by delta: CGSize, minimumSide: CGFloat) -> CGRect {
        if self == .body {
            return CGRect(
                x: min(max(rect.minX + delta.width, 0), max(1 - rect.width, 0)),
                y: min(max(rect.minY + delta.height, 0), max(1 - rect.height, 0)),
                width: rect.width,
                height: rect.height
            )
        }

        let side = min(max(minimumSide, 0.01), 1)
        var left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY
        if movesLeft { left = max(min(left + delta.width, right - side), 0) }
        if movesRight { right = min(max(right + delta.width, left + side), 1) }
        if movesTop { top = max(min(top + delta.height, bottom - side), 0) }
        if movesBottom { bottom = min(max(bottom + delta.height, top + side), 1) }
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    /// The touch area for this handle around a crop frame in points.
    func hitArea(around rect: CGRect, grip: CGFloat) -> CGRect {
        let half = grip / 2
        switch self {
        case .body: return rect.insetBy(dx: min(half, rect.width / 2), dy: min(half, rect.height / 2))
        case .top: return CGRect(x: rect.minX + half, y: rect.minY - half, width: max(rect.width - grip, 0), height: grip)
        case .bottom: return CGRect(x: rect.minX + half, y: rect.maxY - half, width: max(rect.width - grip, 0), height: grip)
        case .left: return CGRect(x: rect.minX - half, y: rect.minY + half, width: grip, height: max(rect.height - grip, 0))
        case .right: return CGRect(x: rect.maxX - half, y: rect.minY + half, width: grip, height: max(rect.height - grip, 0))
        case .topLeft: return CGRect(x: rect.minX - half, y: rect.minY - half, width: grip, height: grip)
        case .topRight: return CGRect(x: rect.maxX - half, y: rect.minY - half, width: grip, height: grip)
        case .bottomLeft: return CGRect(x: rect.minX - half, y: rect.maxY - half, width: grip, height: grip)
        case .bottomRight: return CGRect(x: rect.maxX - half, y: rect.maxY - half, width: grip, height: grip)
        }
    }

    /// A rectangle that fits inside the unit square, whatever was passed in.
    static func sanitized(_ rect: CGRect) -> CGRect {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        let fitted = rect.standardized.intersection(unit)
        return fitted.isNull || fitted.isEmpty ? unit : fitted
    }
}

nonisolated private struct CropRectangleOverlayDim: Shape {
    let hole: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRect(hole)
        return path
    }
}

/// A crop frame with draggable corners and edges over an image, dimming what is outside it.
///
/// `crop` is normalized, from 0 to 1, and changes when a drag ends. `aspectRatio` is the image's
/// width divided by its height. VoiceOver moves and resizes the frame with custom actions.
struct CropRectangleOverlay: View {
    private struct ActiveDrag: Equatable {
        let handle: CropRectangleOverlayHandle
        let delta: CGSize
    }

    let image: Image
    let aspectRatio: CGFloat
    @Binding var crop: CGRect
    var minimumSide: CGFloat = 0.15

    @GestureState private var drag: ActiveDrag?

    /// How far a VoiceOver action moves or resizes the frame, as a fraction of the image.
    private let adjustmentStep: CGFloat = 0.05

    private var committed: CGRect { CropRectangleOverlayHandle.sanitized(crop) }

    private var shown: CGRect {
        guard let drag else { return committed }
        return drag.handle.adjusting(committed, by: drag.delta, minimumSide: minimumSide)
    }

    var body: some View {
        image
            .resizable()
            .aspectRatio(aspectRatio.isFinite ? max(aspectRatio, 0.01) : 1, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    cropInterface(in: geometry.size)
                }
            }
            // A photo is not mirrored in right-to-left layouts, so neither is the crop drawn over it.
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Crop area")
            .accessibilityValue(accessibilityDescription)
            .accessibilityActions { accessibilityButtons }
    }

    private func cropInterface(in size: CGSize) -> some View {
        let frame = CGRect(
            x: shown.minX * size.width,
            y: shown.minY * size.height,
            width: shown.width * size.width,
            height: shown.height * size.height
        )

        return ZStack {
            CropRectangleOverlayDim(hole: frame)
                .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))
            thirds(in: frame)
                .stroke(.white.opacity(0.5), lineWidth: 0.5)
            Path(frame)
                .stroke(.white, lineWidth: 1.5)
            brackets(in: frame)
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            ForEach(CropRectangleOverlayHandle.allCases, id: \.self) { handle in
                let area = handle.hitArea(around: frame, grip: 44)
                Color.clear
                    .frame(width: area.width, height: area.height)
                    .contentShape(.rect)
                    .gesture(dragGesture(for: handle, in: size))
                    .position(x: area.midX, y: area.midY)
            }
        }
    }

    private func thirds(in frame: CGRect) -> Path {
        Path { path in
            for part in [CGFloat(1) / 3, CGFloat(2) / 3] {
                path.move(to: CGPoint(x: frame.minX + frame.width * part, y: frame.minY))
                path.addLine(to: CGPoint(x: frame.minX + frame.width * part, y: frame.maxY))
                path.move(to: CGPoint(x: frame.minX, y: frame.minY + frame.height * part))
                path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY + frame.height * part))
            }
        }
    }

    private func brackets(in frame: CGRect) -> Path {
        let length = min(22, min(frame.width, frame.height) / 2)
        return Path { path in
            for (corner, x, y) in [
                (CGPoint(x: frame.minX, y: frame.minY), length, length),
                (CGPoint(x: frame.maxX, y: frame.minY), -length, length),
                (CGPoint(x: frame.maxX, y: frame.maxY), -length, -length),
                (CGPoint(x: frame.minX, y: frame.maxY), length, -length),
            ] {
                path.move(to: CGPoint(x: corner.x + x, y: corner.y))
                path.addLine(to: corner)
                path.addLine(to: CGPoint(x: corner.x, y: corner.y + y))
            }
        }
    }

    private func dragGesture(for handle: CropRectangleOverlayHandle, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($drag) { value, state, _ in
                state = ActiveDrag(handle: handle, delta: normalized(value.translation, in: size))
            }
            .onEnded { value in
                crop = handle.adjusting(committed, by: normalized(value.translation, in: size), minimumSide: minimumSide)
            }
    }

    private func normalized(_ translation: CGSize, in size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGSize(width: translation.width / size.width, height: translation.height / size.height)
    }

    private var accessibilityDescription: String {
        let parts = [("left", committed.minX), ("top", committed.minY), ("width", committed.width), ("height", committed.height)]
        return parts.map { "\($0.0) \(Int(($0.1 * 100).rounded())) percent" }.joined(separator: ", ")
    }

    @ViewBuilder private var accessibilityButtons: some View {
        adjustment("Move left", .body, dx: -adjustmentStep, dy: 0)
        adjustment("Move right", .body, dx: adjustmentStep, dy: 0)
        adjustment("Move up", .body, dx: 0, dy: -adjustmentStep)
        adjustment("Move down", .body, dx: 0, dy: adjustmentStep)
        adjustment("Make wider", .right, dx: adjustmentStep, dy: 0)
        adjustment("Make narrower", .right, dx: -adjustmentStep, dy: 0)
        adjustment("Make taller", .bottom, dx: 0, dy: adjustmentStep)
        adjustment("Make shorter", .bottom, dx: 0, dy: -adjustmentStep)
    }

    private func adjustment(_ title: String, _ handle: CropRectangleOverlayHandle, dx: CGFloat, dy: CGFloat) -> some View {
        Button(title) {
            crop = handle.adjusting(committed, by: CGSize(width: dx, height: dy), minimumSide: minimumSide)
        }
    }
}

// MARK: - Demo

struct CropRectangleOverlayDemo: View {
    private static let initialCrop = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

    @State private var crop = initialCrop
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let photo = demoPhoto()

    var body: some View {
        CropRectangleOverlay(image: photo, aspectRatio: 4 / 5, crop: $crop)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                HStack {
                    Text("\(Int((crop.width * 100).rounded()))% × \(Int((crop.height * 100).rounded()))%")
                        .font(.headline.monospacedDigit())
                    Spacer()
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        withAnimation(reduceMotion ? nil : .snappy) { crop = Self.initialCrop }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .background(.black)
            .preferredColorScheme(.dark)
    }
}

private func demoPhoto() -> Image {
    let size = CGSize(width: 800, height: 1000)
    return Image(size: size, label: Text("Coastline")) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [.cyan, .blue, .indigo]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 1000))
        )
        context.fill(Path(ellipseIn: CGRect(x: 120, y: 130, width: 180, height: 180)), with: .color(.yellow.opacity(0.9)))

        var shore = Path()
        shore.move(to: CGPoint(x: 800, y: 1000))
        shore.addLine(to: CGPoint(x: 0, y: 1000))
        shore.addCurve(to: CGPoint(x: 800, y: 420), control1: CGPoint(x: 360, y: 820), control2: CGPoint(x: 460, y: 560))
        shore.closeSubpath()
        context.fill(shore, with: .color(Color(red: 0.95, green: 0.8, blue: 0.55)))
    }
}

#Preview {
    CropRectangleOverlayDemo()
}
