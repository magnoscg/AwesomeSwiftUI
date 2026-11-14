// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A weather screen: the place and the temperature now, the next hours and the next days over an animated sky.
///
/// The large header fades as the forecast scrolls and a single line takes its place at the top.
/// Each day of the daily forecast draws its low and high as a bar over the span of the whole
/// week, colored from cold to warm, with a dot at the current temperature on the first day.
/// Rain and snow fall over the sky; with Reduce Motion on, they hold still. Temperatures are
/// shown in the unit of the person's region.
///
/// The model takes what WeatherKit gives, `Measurement<UnitTemperature>` and `Date`, so a
/// real forecast fills it without conversions.
struct WeatherForecastScreen: View {
    /// The forecast to show.
    let forecast: WeatherForecastScreenForecast
    /// How far the forecast scrolls, in points, before the header has become a single line.
    var collapseDistance: CGFloat = 120

    @State private var collapse: Double = 0
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize: CGFloat = 96

    private let cardSpacing: CGFloat = 12

    var body: some View {
        ZStack {
            WeatherForecastScreenSky(condition: forecast.condition, isDaylight: forecast.isDaylight)

            // The single line sits above the scroll view, which clips the cards
            // under it instead of letting them pass behind the text.
            VStack(spacing: 0) {
                compactHeader
                    .opacity(collapse)
                    .accessibilityHidden(collapse < 0.5)

                ScrollView {
                    VStack(spacing: cardSpacing) {
                        header
                            .opacity(1 - collapse)
                            .scaleEffect(1 - collapse * 0.12, anchor: .top)
                            .accessibilityHidden(collapse >= 0.5)

                        WeatherForecastScreenHourlyCard(hours: forecast.hours)
                        WeatherForecastScreenDailyCard(days: forecast.days, current: forecast.temperature)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                // The transform returns the progress itself, so scrolling past the header stops updating the view.
                .onScrollGeometryChange(for: Double.self) { geometry in
                    WeatherForecastScreenMath.collapse(
                        offset: geometry.contentOffset.y + geometry.contentInsets.top,
                        distance: collapseDistance
                    )
                } action: { _, progress in
                    collapse = progress
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text(forecast.location)
                .font(.title.weight(.medium))

            Text(forecast.temperature.weatherText)
                .font(.system(size: temperatureSize, weight: .thin))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(forecast.condition.title)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            if let today = forecast.days.first {
                Text("H:\(today.high.weatherText)  L:\(today.low.weatherText)")
                    .font(.title3.weight(.medium))
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var compactHeader: some View {
        VStack(spacing: 0) {
            Text(forecast.location)
                .font(.title3.weight(.medium))

            Text("\(forecast.temperature.weatherText) · \(Text(forecast.condition.title))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Model

/// What the sky is doing, which picks its symbol, its colors and what falls from it.
nonisolated enum WeatherForecastScreenCondition: Sendable, CaseIterable {
    case clear, partlyCloudy, cloudy, rain, snow, thunderstorm

    var title: LocalizedStringResource {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorms"
        }
    }

    /// The name of the SF Symbol for this sky, by day or by night.
    func symbolName(isDaylight: Bool = true) -> String {
        switch self {
        case .clear: isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        }
    }
}

/// The forecast for one hour.
nonisolated struct WeatherForecastScreenHour: Identifiable, Sendable {
    /// The start of the hour.
    let date: Date
    /// The sky in that hour.
    let condition: WeatherForecastScreenCondition
    /// The temperature in that hour, in any unit; it is shown in the region's.
    let temperature: Measurement<UnitTemperature>
    /// Whether the sun is up, which picks the day or the night symbol.
    var isDaylight = true

    var id: Date { date }
}

/// The forecast for one day.
nonisolated struct WeatherForecastScreenDay: Identifiable, Sendable {
    /// Any moment of the day; only its day is shown.
    let date: Date
    /// The sky for most of the day.
    let condition: WeatherForecastScreenCondition
    /// The lowest temperature of the day, in any unit.
    let low: Measurement<UnitTemperature>
    /// The highest temperature of the day, in any unit.
    let high: Measurement<UnitTemperature>
    /// The chance of rain or snow, from 0 to 1. Shown under the symbol from ``shownChance`` up.
    var precipitationChance: Double = 0

    /// The chance of rain or snow from which a day shows it.
    static let shownChance = 0.2

    var showsPrecipitation: Bool { precipitationChance >= Self.shownChance }

    var id: Date { date }
}

/// Everything the screen shows.
nonisolated struct WeatherForecastScreenForecast: Sendable {
    /// The name of the place, shown as it is.
    let location: String
    /// The sky now, which picks the colors of the sky and what falls from it.
    let condition: WeatherForecastScreenCondition
    /// Whether the sun is up now, which picks the colors of the sky.
    var isDaylight = true
    /// The temperature now.
    let temperature: Measurement<UnitTemperature>
    /// The coming hours, the first being now.
    let hours: [WeatherForecastScreenHour]
    /// The coming days, the first being today, whose low and high head the screen.
    let days: [WeatherForecastScreenDay]
}

nonisolated extension Measurement where UnitType == UnitTemperature {
    /// The temperature as a weather report writes it, in whole degrees of the region's unit: "21°".
    fileprivate var weatherText: String {
        let unit = UnitTemperature(forLocale: .current, usage: .weather)
        return "\(Int(converted(to: unit).value.rounded()).formatted())°"
    }

    fileprivate var celsius: Double { converted(to: .celsius).value }
}

// MARK: - Math

/// The geometry of the range bars and the collapsing header, in degrees Celsius and in fractions.
nonisolated enum WeatherForecastScreenMath {
    /// The span of a week: from the lowest low to the highest high, or nil without days.
    static func span(of days: [WeatherForecastScreenDay]) -> ClosedRange<Double>? {
        guard let low = days.map(\.low.celsius).min(), let high = days.map(\.high.celsius).max() else { return nil }
        return min(low, high)...max(low, high)
    }

    /// Where a temperature falls in a span, from 0 at its low end to 1 at its high end.
    static func fraction(of value: Double, in span: ClosedRange<Double>) -> Double {
        let width = span.upperBound - span.lowerBound
        guard width > 0 else { return 0.5 }
        return min(max((value - span.lowerBound) / width, 0), 1)
    }

    /// The part of the track a day covers. A week of one temperature fills the whole track.
    static func bar(low: Double, high: Double, in span: ClosedRange<Double>) -> ClosedRange<Double> {
        guard span.upperBound > span.lowerBound else { return 0...1 }
        let start = fraction(of: min(low, high), in: span)
        let end = fraction(of: max(low, high), in: span)
        return start...end
    }

    /// How collapsed the header is, from 0 at rest to 1 once the forecast has scrolled `distance`.
    static func collapse(offset: CGFloat, distance: CGFloat) -> Double {
        guard distance > 0 else { return offset > 0 ? 1 : 0 }
        return min(max(Double(offset / distance), 0), 1)
    }
}

// MARK: - Cards

/// The gap between the parts of a card and around each of its rows.
private let weatherForecastScreenGap: CGFloat = 10

private struct WeatherForecastScreenCard<Content: View>: View {
    let title: LocalizedStringResource
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: weatherForecastScreenGap) {
            Label { Text(title) } icon: { Image(systemName: systemImage) }
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.7))

            Divider()
                .overlay(.white.opacity(0.25))

            content
        }
        .padding(14)
        // A shade under the material keeps the dimmer text of the cards readable over a light sky.
        .background(Color.black.opacity(0.18), in: .rect(cornerRadius: 18))
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
        .environment(\.colorScheme, .dark)
    }
}

private struct WeatherForecastScreenHourlyCard: View {
    let hours: [WeatherForecastScreenHour]

    /// One height for every symbol, so the temperatures under them line up.
    @ScaledMetric(relativeTo: .title3) private var symbolHeight: CGFloat = 28

    var body: some View {
        WeatherForecastScreenCard(title: "Hourly Forecast", systemImage: "clock") {
            ScrollView(.horizontal) {
                HStack(spacing: 22) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                        VStack(spacing: weatherForecastScreenGap) {
                            Group {
                                if index == 0 {
                                    Text("Now")
                                } else {
                                    Text(hour.date, format: .dateTime.hour())
                                }
                            }
                            .font(.subheadline.weight(.semibold))

                            Image(systemName: hour.condition.symbolName(isDaylight: hour.isDaylight))
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                                .frame(height: symbolHeight)
                                .accessibilityLabel(Text(hour.condition.title))

                            Text(hour.temperature.weatherText)
                                .font(.title3.weight(.medium))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct WeatherForecastScreenDailyCard: View {
    let days: [WeatherForecastScreenDay]
    let current: Measurement<UnitTemperature>

    @ScaledMetric(relativeTo: .body) private var dayWidth: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var temperatureWidth: CGFloat = 40
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(\.colorSchemeContrast) private var contrast

    /// Dimmer than the high, as the low is the less telling of the two, unless Increase Contrast is on.
    private var lowColor: Color { contrast == .increased ? .white : .white.opacity(0.72) }

    var body: some View {
        WeatherForecastScreenCard(title: "10-Day Forecast", systemImage: "calendar") {
            if let span = WeatherForecastScreenMath.span(of: days) {
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        row(day, isToday: index == 0, span: span)

                        if index < days.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.18))
                        }
                    }
                }
            }
        }
    }

    private func row(_ day: WeatherForecastScreenDay, isToday: Bool, span: ClosedRange<Double>) -> some View {
        // From xxLarge the columns no longer fit side by side on a narrow iPhone, so the bar takes a line of its own.
        Group {
            if dynamicTypeSize >= .xxLarge {
                VStack(alignment: .leading, spacing: weatherForecastScreenGap) {
                    HStack {
                        dayName(of: day, isToday: isToday)
                        Spacer()
                        symbol(of: day)
                    }

                    HStack(spacing: 12) {
                        Text(day.low.weatherText)
                            .foregroundStyle(lowColor)
                        rangeBar(of: day, isToday: isToday, span: span)
                        Text(day.high.weatherText)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    dayName(of: day, isToday: isToday)
                        .frame(width: dayWidth, alignment: .leading)

                    symbol(of: day)
                        .frame(width: temperatureWidth)

                    Text(day.low.weatherText)
                        .foregroundStyle(lowColor)
                        .frame(width: temperatureWidth, alignment: .trailing)

                    rangeBar(of: day, isToday: isToday, span: span)

                    Text(day.high.weatherText)
                        .frame(width: temperatureWidth, alignment: .trailing)
                }
            }
        }
        .font(.body.weight(.medium))
        .monospacedDigit()
        .padding(.vertical, weatherForecastScreenGap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label(for: day, isToday: isToday))
    }

    private func dayName(of day: WeatherForecastScreenDay, isToday: Bool) -> some View {
        Group {
            if isToday {
                Text("Today")
            } else {
                Text(day.date, format: .dateTime.weekday(.abbreviated))
            }
        }
        .font(.body.weight(.semibold))
    }

    private func symbol(of day: WeatherForecastScreenDay) -> some View {
        VStack(spacing: 0) {
            Image(systemName: day.condition.symbolName())
                .symbolRenderingMode(.multicolor)
                .font(.title3)

            if day.showsPrecipitation {
                Text(day.precipitationChance, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1))
            }
        }
    }

    private func rangeBar(of day: WeatherForecastScreenDay, isToday: Bool, span: ClosedRange<Double>) -> some View {
        WeatherForecastScreenRangeBar(
            range: WeatherForecastScreenMath.bar(low: day.low.celsius, high: day.high.celsius, in: span),
            span: span,
            marker: isToday ? WeatherForecastScreenMath.fraction(of: current.celsius, in: span) : nil
        )
    }

    private func label(for day: WeatherForecastScreenDay, isToday: Bool) -> Text {
        let name = isToday ? Text("Today") : Text(day.date, format: .dateTime.weekday(.wide))
        let temperatures = Text("Low \(day.low.weatherText), high \(day.high.weatherText)")
        guard day.showsPrecipitation else {
            return Text("\(name), \(Text(day.condition.title)), \(temperatures)")
        }
        let chance = day.precipitationChance.formatted(.percent.precision(.fractionLength(0)))
        return Text("\(name), \(Text(day.condition.title)), \(chance) chance of precipitation, \(temperatures)")
    }
}

/// A day's low to high over the week's track, painted with the week's cold-to-warm gradient.
private struct WeatherForecastScreenRangeBar: View {
    let range: ClosedRange<Double>
    let span: ClosedRange<Double>
    let marker: Double?

    private let height: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.15))

                let barWidth = min(width, max(height, width * (range.upperBound - range.lowerBound)))

                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    .mask(alignment: .leading) {
                        // A day at the top of the week still shows its whole capsule inside the track.
                        Capsule()
                            .frame(width: barWidth)
                            .offset(x: min(width * range.lowerBound, width - barWidth))
                    }

                if let marker {
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(.black.opacity(0.35), lineWidth: 1.5))
                        .frame(width: height + 2, height: height + 2)
                        .offset(x: width * marker - (height + 2) / 2)
                }
            }
        }
        .frame(height: height)
        .frame(minWidth: 60)
    }

    /// The colors of the temperatures across the week, so a warmer day shows warmer colors.
    private var gradientColors: [Color] {
        let samples = 5
        return (0..<samples).map { index in
            let fraction = Double(index) / Double(samples - 1)
            let celsius = span.lowerBound + (span.upperBound - span.lowerBound) * fraction
            return WeatherForecastScreenRangeBar.color(forCelsius: celsius)
        }
    }

    private static let palette: [(celsius: Double, color: Color)] = [
        (-10, Color(red: 0.45, green: 0.55, blue: 1)),
        (0, Color(red: 0.35, green: 0.80, blue: 1)),
        (10, Color(red: 0.42, green: 0.90, blue: 0.70)),
        (20, Color(red: 1, green: 0.84, blue: 0.30)),
        (30, Color(red: 1, green: 0.55, blue: 0.20)),
        (40, Color(red: 1, green: 0.26, blue: 0.24)),
    ]

    private static func color(forCelsius celsius: Double) -> Color {
        guard let first = palette.first, let last = palette.last else { return .white }
        if celsius <= first.celsius { return first.color }
        if celsius >= last.celsius { return last.color }
        let upper = palette.firstIndex { $0.celsius >= celsius } ?? palette.count - 1
        let lower = palette[upper - 1]
        let fraction = (celsius - lower.celsius) / (palette[upper].celsius - lower.celsius)
        return lower.color.mix(with: palette[upper].color, by: fraction)
    }
}

// MARK: - Sky

/// The sky behind the forecast: a gradient for the condition and the time of day, and what falls from it.
private struct WeatherForecastScreenSky: View {
    let condition: WeatherForecastScreenCondition
    let isDaylight: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .animation(.easeInOut(duration: 0.8), value: colors)

            if let fall = WeatherForecastScreenFall(condition: condition) {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
                    Canvas { context, size in
                        let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                        fall.draw(in: &context, size: size, time: time)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: condition)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Dark enough down to the header's line of highs and lows for white text to keep a contrast of 4.5:1.
    private var colors: [Color] {
        switch (condition, isDaylight) {
        case (_, false):
            [Color(red: 0.03, green: 0.05, blue: 0.16), Color(red: 0.13, green: 0.17, blue: 0.36)]
        case (.clear, true):
            [Color(red: 0.12, green: 0.36, blue: 0.74), Color(red: 0.33, green: 0.58, blue: 0.89)]
        case (.partlyCloudy, true):
            [Color(red: 0.17, green: 0.36, blue: 0.64), Color(red: 0.47, green: 0.62, blue: 0.80)]
        case (.cloudy, true):
            [Color(red: 0.24, green: 0.31, blue: 0.41), Color(red: 0.52, green: 0.58, blue: 0.66)]
        case (.rain, true), (.thunderstorm, true):
            [Color(red: 0.15, green: 0.20, blue: 0.29), Color(red: 0.33, green: 0.40, blue: 0.50)]
        case (.snow, true):
            [Color(red: 0.24, green: 0.32, blue: 0.45), Color(red: 0.58, green: 0.66, blue: 0.78)]
        }
    }
}

/// What falls from the sky: streaks of rain or flakes of snow, in two depths.
nonisolated private struct WeatherForecastScreenFall {
    private let isSnow: Bool
    private let count: Int

    init?(condition: WeatherForecastScreenCondition) {
        switch condition {
        case .rain: isSnow = false; count = 90
        case .thunderstorm: isSnow = false; count = 140
        case .snow: isSnow = true; count = 70
        case .clear, .partlyCloudy, .cloudy: return nil
        }
    }

    func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        var near = Path()
        var far = Path()
        let speed: Double = isSnow ? 45 : 620
        let travel = size.height + 40

        for index in 0..<count {
            let isNear = index % 3 == 0
            let depth: Double = isNear ? 1 : 0.6
            let fallen = (noise(index, 1) * travel + time * speed * depth).truncatingRemainder(dividingBy: travel) - 20
            let x = noise(index, 2) * size.width

            if isSnow {
                let sway = sin(time * (0.6 + noise(index, 3)) + noise(index, 4) * 2 * .pi) * 10 * depth
                let radius = (1.2 + noise(index, 5) * 1.8) * depth
                let flake = Path(ellipseIn: CGRect(x: x + sway - radius, y: fallen - radius, width: radius * 2, height: radius * 2))
                if isNear { near.addPath(flake) } else { far.addPath(flake) }
            } else {
                let length = 14 * depth
                var streak = Path()
                streak.move(to: CGPoint(x: x, y: fallen))
                streak.addLine(to: CGPoint(x: x - length * 0.12, y: fallen + length))
                if isNear { near.addPath(streak) } else { far.addPath(streak) }
            }
        }

        if isSnow {
            context.fill(far, with: .color(.white.opacity(0.5)))
            context.fill(near, with: .color(.white.opacity(0.9)))
        } else {
            context.stroke(far, with: .color(.white.opacity(0.22)), lineWidth: 1)
            context.stroke(near, with: .color(.white.opacity(0.4)), lineWidth: 1.4)
        }
    }

    /// A repeatable pseudo-random value in 0..<1 for one drop and one property.
    private func noise(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 127.1 + salt * 311.7) * 43_758.5453
        return value - floor(value)
    }
}

// MARK: - Demo

struct WeatherForecastScreenDemo: View {
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @State private var step = 0

    private let skies: [(condition: WeatherForecastScreenCondition, isDaylight: Bool, celsius: Double)] = [
        (.clear, true, 22),
        (.partlyCloudy, true, 19),
        (.rain, true, 14),
        (.snow, true, -1),
        (.clear, false, 12),
    ]

    var body: some View {
        WeatherForecastScreen(forecast: forecast(for: skies[step]))
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
            // A scroll view keeps the drag to itself, so the first scroll stops the demo too.
            .onScrollPhaseChange { _, phase in
                if phase != .idle { isAutoPlaying = false }
            }
            .task {
                while isAutoPlaying {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard !Task.isCancelled, isAutoPlaying else { return }
                    step = (step + 1) % skies.count
                }
            }
    }

    private func forecast(
        for sky: (condition: WeatherForecastScreenCondition, isDaylight: Bool, celsius: Double)
    ) -> WeatherForecastScreenForecast {
        let calendar = Calendar.current
        let now = calendar.dateInterval(of: .hour, for: .now)?.start ?? .now
        let today = calendar.startOfDay(for: now)
        let offsets: [Double] = [0, 1, 1, 2, 2, 1, 0, -1, -2, -2, -3, -3]
        let conditions: [WeatherForecastScreenCondition] = [.partlyCloudy, .rain, .cloudy, .clear, .clear, .thunderstorm, .rain, .cloudy, .partlyCloudy, .clear]
        let lows: [Double] = [-5, -4, -2, -6, -3, -1, -4, -5, -3, -2]
        let highs: [Double] = [3, 5, 2, 4, 7, 6, 1, 3, 5, 6]
        let chances: [Double] = [0.1, 0.6, 0.3, 0, 0, 0.8, 0.5, 0.2, 0, 0]

        let hours = (0..<12).map { index in
            let date = calendar.date(byAdding: .hour, value: index, to: now) ?? now
            let hour = calendar.component(.hour, from: date)
            return WeatherForecastScreenHour(
                date: date,
                condition: index == 0 ? sky.condition : conditions[index % conditions.count],
                temperature: Measurement(value: sky.celsius + offsets[index], unit: .celsius),
                isDaylight: index == 0 ? sky.isDaylight : (7..<20).contains(hour)
            )
        }

        let days = (0..<10).map { index in
            WeatherForecastScreenDay(
                date: calendar.date(byAdding: .day, value: index, to: today) ?? today,
                condition: index == 0 ? sky.condition : conditions[index],
                low: Measurement(value: sky.celsius + lows[index], unit: .celsius),
                high: Measurement(value: sky.celsius + highs[index], unit: .celsius),
                precipitationChance: chances[index]
            )
        }

        return WeatherForecastScreenForecast(
            location: "Lisbon",
            condition: sky.condition,
            isDaylight: sky.isDaylight,
            temperature: Measurement(value: sky.celsius, unit: .celsius),
            hours: hours,
            days: days
        )
    }
}

#Preview {
    WeatherForecastScreenDemo()
}
