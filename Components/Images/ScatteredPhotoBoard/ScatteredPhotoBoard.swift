// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct ScatteredPhotoBoardPhoto: Identifiable {
    let id: String
    let image: Image
    let caption: String
}

enum ScatteredPhotoBoardLayout {
    /// A repeatable pseudo-random number from -0.5 to 0.5.
    private static func noise(_ index: Int, salt: Double) -> Double {
        let value = sin(Double(index % 10_000) * 12.9898 + salt) * 43_758.5453
        return value - value.rounded(.down) - 0.5
    }

    static func angle(index: Int) -> Double {
        noise(index, salt: 7) * 18
    }

    /// Keeps a card's center inside the board, or in its middle if the card does not fit.
    static func clamped(_ point: CGPoint, card: CGSize, board: CGSize) -> CGPoint {
        func clamp(_ value: CGFloat, side: CGFloat, length: CGFloat) -> CGFloat {
            guard length > side else { return length / 2 }
            return min(max(value, side / 2), length - side / 2)
        }
        return CGPoint(x: clamp(point.x, side: card.width, length: board.width), y: clamp(point.y, side: card.height, length: board.height))
    }

    /// A slightly jittered grid position, so the same photos always land in the same place.
    static func center(index: Int, count: Int, card: CGSize, board: CGSize) -> CGPoint {
        guard count > 0 else { return CGPoint(x: board.width / 2, y: board.height / 2) }
        let columns = max(Int(Double(min(count, 10_000)).squareRoot().rounded(.up)), 1)
        let rows = count / columns + (count.isMultiple(of: columns) ? 0 : 1)
        let cell = CGSize(width: board.width / CGFloat(columns), height: board.height / CGFloat(rows))

        let point = CGPoint(
            x: (CGFloat(index % columns) + 0.5 + noise(index, salt: 1) * 0.35) * cell.width,
            y: (CGFloat(index / columns) + 0.5 + noise(index, salt: 3) * 0.35) * cell.height
        )
        return clamped(point, card: card, board: board)
    }
}

/// Photos scattered at slight angles on a board. Touching one brings it to the front, and it can
/// be dragged anywhere on the board.
///
/// VoiceOver reads each caption and offers an action to bring the photo to the front. With
/// Reduce Motion on, a card does not lift while dragged.
struct ScatteredPhotoBoard: View {
    private struct ActiveDrag {
        let id: String
        let translation: CGSize
    }

    let photos: [ScatteredPhotoBoardPhoto]
    var cardWidth: CGFloat = 150

    @State private var offsets: [String: CGSize] = [:]
    @State private var stacking: [String] = []
    @GestureState private var drag: ActiveDrag?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let space = "ScatteredPhotoBoard"

    private var cardSize: CGSize {
        let width = max(cardWidth, 1)
        return CGSize(width: width, height: width * 1.2)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    card(photo, index: index)
                        .position(position(of: photo, index: index, board: geometry.size))
                        .zIndex(depth(of: photo, index: index))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .coordinateSpace(.named(space))
        }
    }

    private func card(_ photo: ScatteredPhotoBoardPhoto, index: Int) -> some View {
        let isDragged = drag?.id == photo.id
        let lifted = isDragged && !reduceMotion

        return VStack(spacing: 6) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    photo.image
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
            Text(photo.caption)
                .font(.caption.weight(.medium))
                .foregroundStyle(.black.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(width: cardSize.width)
        .background(.white, in: .rect(cornerRadius: 4))
        .shadow(color: .black.opacity(lifted ? 0.4 : 0.25), radius: lifted ? 16 : 6, y: lifted ? 10 : 3)
        .contentShape(.rect)
        .gesture(dragGesture(for: photo))
        .scaleEffect(lifted ? 1.06 : 1)
        .rotationEffect(.degrees(lifted ? 0 : ScatteredPhotoBoardLayout.angle(index: index)))
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isDragged)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(photo.caption)
        .accessibilityAddTraits(.isImage)
        .accessibilityAction(named: "Bring to front") { bringToFront(photo) }
    }

    private func dragGesture(for photo: ScatteredPhotoBoardPhoto) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
            .updating($drag) { value, state, _ in
                state = ActiveDrag(id: photo.id, translation: value.translation)
            }
            .onChanged { _ in bringToFront(photo) }
            .onEnded { value in
                let saved = offsets[photo.id] ?? .zero
                offsets[photo.id] = CGSize(width: saved.width + value.translation.width, height: saved.height + value.translation.height)
            }
    }

    private func position(of photo: ScatteredPhotoBoardPhoto, index: Int, board: CGSize) -> CGPoint {
        let home = ScatteredPhotoBoardLayout.center(index: index, count: photos.count, card: cardSize, board: board)
        let saved = offsets[photo.id] ?? .zero
        let live = drag?.id == photo.id ? drag?.translation ?? .zero : .zero
        return ScatteredPhotoBoardLayout.clamped(
            CGPoint(x: home.x + saved.width + live.width, y: home.y + saved.height + live.height),
            card: cardSize,
            board: board
        )
    }

    private func depth(of photo: ScatteredPhotoBoardPhoto, index: Int) -> Double {
        guard let rank = stacking.firstIndex(of: photo.id) else { return Double(index) }
        return Double(photos.count + rank)
    }

    private func bringToFront(_ photo: ScatteredPhotoBoardPhoto) {
        guard stacking.last != photo.id else { return }
        stacking.removeAll { $0 == photo.id }
        stacking.append(photo.id)
    }
}

// MARK: - Demo

struct ScatteredPhotoBoardDemo: View {
    private let photos = [
        demoPhoto("Lisbon", [.orange, .pink], "sun.max.fill"),
        demoPhoto("Oslo", [.cyan, .blue], "snowflake"),
        demoPhoto("Kyoto", [.pink, .purple], "leaf.fill"),
        demoPhoto("Quito", [.green, .teal], "mountain.2.fill"),
        demoPhoto("Cairo", [.yellow, .orange], "sparkles"),
    ]

    var body: some View {
        ScatteredPhotoBoard(photos: photos)
            .background {
                LinearGradient(
                    colors: [Color(red: 0.72, green: 0.55, blue: 0.38), Color(red: 0.55, green: 0.39, blue: 0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}

private func demoPhoto(_ caption: String, _ colors: [Color], _ symbol: String) -> ScatteredPhotoBoardPhoto {
    let size = CGSize(width: 400, height: 400)
    let image = Image(size: size, label: Text(caption)) { context in
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 400, y: 400))
        )
        var icon = context.resolve(Image(systemName: symbol))
        icon.shading = .color(.white.opacity(0.9))
        context.draw(icon, in: CGRect(x: 120, y: 120, width: 160, height: 160))
    }
    return ScatteredPhotoBoardPhoto(id: caption, image: image, caption: caption)
}

#Preview {
    ScatteredPhotoBoardDemo()
}
