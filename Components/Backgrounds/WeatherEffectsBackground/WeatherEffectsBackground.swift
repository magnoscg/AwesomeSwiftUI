// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// An animated sky for a kind of weather: sun, stars, clouds, rain, storm, snow or fog.
///
/// Changing ``weather`` fades the sky and its effects into the new ones. Lightning follows a
/// fixed schedule of at most two flashes every few seconds, never more than three a second.
/// With Reduce Motion on, everything holds still and lightning never flashes. The sun sits in
/// the top trailing corner, so it moves to the left in a right-to-left layout.
///
/// It draws behind content, ignores the safe area and takes no touches, and VoiceOver skips it.
struct WeatherEffectsBackground: View {
    /// The weather to draw.
    var weather: WeatherEffectsBackgroundWeather

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(colors: weather.skyColors, startPoint: .top, endPoint: .bottom)

                // One identity per weather, so a change fades the old effects out and the new ones in.
                ForEach([weather], id: \.self) { weather in
                    WeatherEffectsBackgroundLayers(weather: weather, time: time, flashes: !reduceMotion)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 1), value: weather)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A kind of weather the background can draw.
nonisolated enum WeatherEffectsBackgroundWeather: String, CaseIterable, Sendable {
    case clearDay, clearNight, cloudy, rain, thunderstorm, snow, fog

    /// The name of the weather, for a label next to it.
    var title: LocalizedStringResource {
        switch self {
        case .clearDay: "Clear"
        case .clearNight: "Clear Night"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .thunderstorm: "Thunderstorm"
        case .snow: "Snow"
        case .fog: "Fog"
        }
    }

    fileprivate var skyColors: [Color] {
        switch self {
        case .clearDay: [Color(red: 0.11, green: 0.38, blue: 0.80), Color(red: 0.46, green: 0.72, blue: 0.96)]
        case .clearNight: [Color(red: 0.02, green: 0.03, blue: 0.13), Color(red: 0.10, green: 0.13, blue: 0.34)]
        case .cloudy: [Color(red: 0.33, green: 0.40, blue: 0.52), Color(red: 0.62, green: 0.68, blue: 0.76)]
        case .rain: [Color(red: 0.14, green: 0.19, blue: 0.27), Color(red: 0.33, green: 0.40, blue: 0.49)]
        case .thunderstorm: [Color(red: 0.06, green: 0.07, blue: 0.13), Color(red: 0.20, green: 0.22, blue: 0.34)]
        case .snow: [Color(red: 0.36, green: 0.44, blue: 0.58), Color(red: 0.70, green: 0.76, blue: 0.85)]
        case .fog: [Color(red: 0.46, green: 0.49, blue: 0.56), Color(red: 0.70, green: 0.72, blue: 0.75)]
        }
    }
}

// MARK: - Math

/// The timing of the effects: where a moving thing wraps around, and when lightning flashes.
nonisolated enum WeatherEffectsBackgroundMath {
    /// The seconds after which the lightning schedule repeats.
    static let lightningCycle: Double = 6

    /// A position moved back inside `0..<travel`, so what leaves one edge comes back at the other.
    static func wrap(_ position: Double, over travel: Double) -> Double {
        guard travel > 0 else { return 0 }
        let remainder = position.truncatingRemainder(dividingBy: travel)
        return remainder < 0 ? remainder + travel : remainder
    }

    /// The brightness of the lightning at a moment, from 0 when dark to 1 at the peak of a flash.
    static func flash(at time: Double) -> Double {
        let moment = wrap(time, over: lightningCycle)
        for strike in strikes where moment >= strike.start && moment < strike.start + strike.duration {
            return sin(.pi * (moment - strike.start) / strike.duration)
        }
        return 0
    }

    /// Two strikes close together, as lightning often comes, early in each cycle.
    private static let strikes: [(start: Double, duration: Double)] = [(0.4, 0.18), (0.75, 0.22)]
}

// MARK: - Layers

/// The effects of one weather at one moment.
private struct WeatherEffectsBackgroundLayers: View {
    let weather: WeatherEffectsBackgroundWeather
    let time: Double
    let flashes: Bool

    var body: some View {
        ZStack {
            switch weather {
            case .clearDay:
                WeatherEffectsBackgroundSun(time: time)
            case .clearNight:
                canvas { WeatherEffectsBackgroundStars.draw(in: &$0, size: $1, time: time) }
            case .cloudy:
                canvas { WeatherEffectsBackgroundClouds.draw(in: &$0, size: $1, time: time, color: .white, opacity: 0.5) }
            case .rain:
                canvas { WeatherEffectsBackgroundClouds.draw(in: &$0, size: $1, time: time, color: .white, opacity: 0.25) }
                canvas { WeatherEffectsBackgroundRain.draw(in: &$0, size: $1, time: time, drops: 110) }
            case .thunderstorm:
                canvas { WeatherEffectsBackgroundClouds.draw(in: &$0, size: $1, time: time, color: .black, opacity: 0.5) }
                if flashes {
                    canvas { WeatherEffectsBackgroundLightning.draw(in: &$0, size: $1, time: time) }
                }
                canvas { WeatherEffectsBackgroundRain.draw(in: &$0, size: $1, time: time, drops: 170) }
            case .snow:
                canvas { WeatherEffectsBackgroundSnow.draw(in: &$0, size: $1, time: time) }
            case .fog:
                canvas { WeatherEffectsBackgroundFog.draw(in: &$0, size: $1, time: time) }
            }
        }
    }

    private func canvas(_ draw: @escaping (inout GraphicsContext, CGSize) -> Void) -> some View {
        Canvas { context, size in draw(&context, size) }
    }
}

/// The property of a particle a pseudo-random value decides.
nonisolated private enum WeatherEffectsBackgroundTrait: Double {
    case x = 1, y, size, speed, phase, offset, extra
}

/// A repeatable pseudo-random value in 0..<1 for one particle and one of its properties.
nonisolated private func weatherEffectsBackgroundNoise(_ index: Int, _ trait: WeatherEffectsBackgroundTrait) -> Double {
    let value = sin(Double(index) * 127.1 + trait.rawValue * 311.7) * 43_758.5453
    return value - floor(value)
}

// MARK: - Sun

/// A glow in the top trailing corner with slow rays turning around it.
private struct WeatherEffectsBackgroundSun: View {
    let time: Double

    private let diameter: CGFloat = 520

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width / 2
                let rays = 14

                context.drawLayer { rayContext in
                    rayContext.addFilter(.blur(radius: 12))
                    rayContext.translateBy(x: center.x, y: center.y)
                    rayContext.rotate(by: .radians(time * 0.05))
                    for ray in 0..<rays {
                        let angle = Double(ray) / Double(rays) * 2 * .pi
                        let spread = 0.07 + weatherEffectsBackgroundNoise(ray, .size) * 0.05
                        let length = radius * (0.7 + weatherEffectsBackgroundNoise(ray, .extra) * 0.3)
                        var wedge = Path()
                        wedge.move(to: .zero)
                        wedge.addLine(to: CGPoint(x: cos(angle - spread) * length, y: sin(angle - spread) * length))
                        wedge.addLine(to: CGPoint(x: cos(angle + spread) * length, y: sin(angle + spread) * length))
                        wedge.closeSubpath()
                        let shimmer = 0.10 + 0.06 * sin(time * 0.8 + Double(ray))
                        rayContext.fill(wedge, with: .color(.white.opacity(shimmer)))
                    }
                }

                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.9), Color(red: 1, green: 0.93, blue: 0.7).opacity(0.45), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: radius * 0.56
                    )
                )
            }
            .frame(width: diameter, height: diameter)
            .offset(x: diameter * 0.32, y: -diameter * 0.32)
        }
    }
}

// MARK: - Stars

nonisolated private enum WeatherEffectsBackgroundStars {
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        for index in 0..<120 {
            let x = weatherEffectsBackgroundNoise(index, .x) * size.width
            let y = weatherEffectsBackgroundNoise(index, .y) * size.height * 0.7
            let radius = 0.5 + weatherEffectsBackgroundNoise(index, .size) * 1.3
            let twinkle = 0.55 + 0.45 * sin(time * (0.8 + weatherEffectsBackgroundNoise(index, .speed) * 1.6) + Double(index))
            let star = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            context.fill(star, with: .color(.white.opacity(twinkle)))
        }
    }
}

// MARK: - Clouds

nonisolated private enum WeatherEffectsBackgroundClouds {
    /// Soft clouds in three bands, the higher ones slower, drifting toward the trailing edge.
    /// The soft ellipses that make up one cloud.
    private static let puffs = 4

    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double, color: Color, opacity: Double) {
        let cloudWidth = size.width * 0.9
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 28))
            for index in 0..<7 {
                let band = Double(index % 3)
                let speed = 8 + band * 7
                let travel = size.width + cloudWidth
                let x = WeatherEffectsBackgroundMath.wrap(
                    weatherEffectsBackgroundNoise(index, .x) * travel + time * speed,
                    over: travel
                ) - cloudWidth
                let y = size.height * (0.05 + band * 0.12) + weatherEffectsBackgroundNoise(index, .y) * 40
                var cloud = Path()
                for puff in 0..<puffs {
                    let seed = index * puffs + puff
                    let puffWidth = cloudWidth * (0.35 + weatherEffectsBackgroundNoise(seed, .size) * 0.25)
                    let puffX = x + cloudWidth * Double(puff) * 0.18
                    let puffY = y + weatherEffectsBackgroundNoise(seed, .offset) * 36 - 18
                    cloud.addEllipse(in: CGRect(x: puffX, y: puffY, width: puffWidth, height: puffWidth * 0.42))
                }
                layer.fill(cloud, with: .color(color.opacity(opacity)))
            }
        }
    }
}

// MARK: - Rain

nonisolated private enum WeatherEffectsBackgroundRain {
    /// How far drops look: their length and speed against the near ones.
    private static let farDepth = 0.6

    /// The part of each splash's cycle in which it is seen spreading.
    private static let splashTime = 0.3

    /// Streaks in two depths, the near ones longer and faster, and splashes where they land.
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double, drops: Int) {
        var near = Path()
        var far = Path()
        let travel = size.height + 60

        for index in 0..<drops {
            let isNear = index % 3 == 0
            let depth: Double = isNear ? 1 : farDepth
            let y = WeatherEffectsBackgroundMath.wrap(
                weatherEffectsBackgroundNoise(index, .y) * travel + time * 700 * depth,
                over: travel
            ) - 30
            let x = weatherEffectsBackgroundNoise(index, .x) * (size.width + 40) - 20
            let length = 18 * depth
            var streak = Path()
            streak.move(to: CGPoint(x: x, y: y))
            streak.addLine(to: CGPoint(x: x - length * 0.15, y: y + length))
            if isNear { near.addPath(streak) } else { far.addPath(streak) }
        }
        context.stroke(far, with: .color(.white.opacity(0.22)), lineWidth: 1)
        context.stroke(near, with: .color(.white.opacity(0.5)), lineWidth: 1.4)

        for index in 0..<(drops / 4) {
            let phase = WeatherEffectsBackgroundMath.wrap(time * 1.6 + weatherEffectsBackgroundNoise(index, .phase), over: 1)
            guard phase < splashTime else { continue }
            let grown = phase / splashTime
            let x = weatherEffectsBackgroundNoise(index, .offset) * size.width
            let y = size.height - 8 - weatherEffectsBackgroundNoise(index, .extra) * 70
            let width = 4 + grown * 14
            let splash = Path(ellipseIn: CGRect(x: x - width / 2, y: y - width * 0.12, width: width, height: width * 0.24))
            context.stroke(splash, with: .color(.white.opacity(0.4 * (1 - grown))), lineWidth: 1)
        }
    }
}

// MARK: - Lightning

nonisolated private enum WeatherEffectsBackgroundLightning {
    /// The width of the blue glow around a bolt, and how far it blurs.
    private static let glowWidth: CGFloat = 6

    /// A flash over the whole sky and, at its brightest, a jagged bolt from the top.
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let flash = WeatherEffectsBackgroundMath.flash(at: time)
        guard flash > 0 else { return }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash * 0.45)))

        guard flash > 0.3 else { return }
        let cycle = Int(floor(time / WeatherEffectsBackgroundMath.lightningCycle))
        var x = size.width * (0.2 + weatherEffectsBackgroundNoise(cycle, .x) * 0.6)
        var y: Double = 0
        var bolt = Path()
        bolt.move(to: CGPoint(x: x, y: y))
        for step in 0..<9 {
            x += (weatherEffectsBackgroundNoise(cycle * 10 + step, .offset) - 0.5) * 60
            y += size.height * 0.065
            bolt.addLine(to: CGPoint(x: x, y: y))
        }
        context.drawLayer { glow in
            glow.addFilter(.blur(radius: glowWidth))
            glow.stroke(bolt, with: .color(Color(red: 0.75, green: 0.8, blue: 1).opacity(flash)), lineWidth: glowWidth)
        }
        context.stroke(bolt, with: .color(.white.opacity(flash)), lineWidth: 2)
    }
}

// MARK: - Snow

nonisolated private enum WeatherEffectsBackgroundSnow {
    /// Flakes in two depths that fall slowly and sway from side to side.
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        var near = Path()
        var far = Path()
        let travel = size.height + 20

        for index in 0..<130 {
            let isNear = index % 3 == 0
            let depth: Double = isNear ? 1 : 0.5
            let y = WeatherEffectsBackgroundMath.wrap(
                weatherEffectsBackgroundNoise(index, .y) * travel + time * 50 * depth,
                over: travel
            ) - 10
            let sway = sin(time * (0.5 + weatherEffectsBackgroundNoise(index, .speed)) + weatherEffectsBackgroundNoise(index, .phase) * 2 * .pi) * 14 * depth
            let x = weatherEffectsBackgroundNoise(index, .x) * size.width + sway
            let radius = (1.3 + weatherEffectsBackgroundNoise(index, .size) * 2) * depth
            let flake = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            if isNear { near.addPath(flake) } else { far.addPath(flake) }
        }
        context.fill(far, with: .color(.white.opacity(0.55)))
        context.fill(near, with: .color(.white.opacity(0.9)))
    }
}

// MARK: - Fog

nonisolated private enum WeatherEffectsBackgroundFog {
    /// Wide, heavily blurred bands that drift slowly across the lower sky.
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let bandWidth = size.width * 1.6
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 30))
            for index in 0..<8 {
                let travel = size.width + bandWidth
                let direction: Double = index.isMultiple(of: 2) ? 1 : -1
                let x = WeatherEffectsBackgroundMath.wrap(
                    weatherEffectsBackgroundNoise(index, .x) * travel + time * (5 + Double(index) * 2) * direction,
                    over: travel
                ) - bandWidth
                let y = size.height * (0.18 + Double(index) * 0.1)
                let band = Path(ellipseIn: CGRect(x: x, y: y, width: bandWidth, height: size.height * 0.14))
                layer.fill(band, with: .color(.white.opacity(0.5)))
            }
        }
    }
}

// MARK: - Demo

struct WeatherEffectsBackgroundDemo: View {
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @State private var weather = WeatherEffectsBackgroundWeather.clearDay

    var body: some View {
        WeatherEffectsBackground(weather: weather)
            .overlay(alignment: .bottom) {
                Picker("Weather", selection: $weather) {
                    ForEach(WeatherEffectsBackgroundWeather.allCases, id: \.self) { weather in
                        Text(weather.title).tag(weather)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
                .padding(.horizontal, 6)
                .background(.ultraThinMaterial, in: .capsule)
                .environment(\.colorScheme, .dark)
                .padding(.bottom, 40)
            }
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
            .task {
                while isAutoPlaying {
                    try? await Task.sleep(for: .seconds(1.8))
                    guard !Task.isCancelled, isAutoPlaying else { return }
                    let all = WeatherEffectsBackgroundWeather.allCases
                    let next = ((all.firstIndex(of: weather) ?? 0) + 1) % all.count
                    weather = all[next]
                }
            }
    }
}

#Preview {
    WeatherEffectsBackgroundDemo()
}
