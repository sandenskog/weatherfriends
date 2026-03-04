import SwiftUI

// MARK: - WeatherCondition

enum WeatherCondition {
    case sun, clouds, rain, snow, thunder

    static func from(symbolName: String) -> WeatherCondition {
        if symbolName.contains("sun") || symbolName.contains("clear") { return .sun }
        if symbolName.contains("cloud") && !symbolName.contains("rain") && !symbolName.contains("snow") && !symbolName.contains("thunder") { return .clouds }
        if symbolName.contains("rain") || symbolName.contains("drizzle") { return .rain }
        if symbolName.contains("snow") || symbolName.contains("sleet") { return .snow }
        if symbolName.contains("thunder") || symbolName.contains("lightning") { return .thunder }
        return .clouds // fallback
    }
}

// MARK: - WeatherAnimationView

struct WeatherAnimationView: View {
    let condition: WeatherCondition
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            staticIcon
        } else {
            switch condition {
            case .sun: SunPulseView()
            case .clouds: CloudDriftView()
            case .rain: ParticleAnimationView(type: .rain)
            case .snow: ParticleAnimationView(type: .snow)
            case .thunder: ThunderFlashView()
            }
        }
    }

    private var staticIcon: some View {
        Image(systemName: sfSymbol)
            .font(.system(size: 16))
            .foregroundStyle(.white.opacity(0.5))
            .frame(width: 40, height: 40)
    }

    private var sfSymbol: String {
        switch condition {
        case .sun: return "sun.max.fill"
        case .clouds: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunder: return "cloud.bolt.fill"
        }
    }
}

// MARK: - SunPulseView

private struct SunPulseView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.18))
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Circle()
                .fill(Color.yellow.opacity(0.08))
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2),
                    value: isPulsing
                )
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .onAppear { isPulsing = true }
    }
}

// MARK: - CloudDriftView

private struct CloudDriftView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                // Moln 1 — rör sig med ~20s cykel
                let x1 = (CGFloat(t.truncatingRemainder(dividingBy: 20)) / 20.0) * (w + 20) - 10
                let cloud1 = CGRect(x: x1 - 14, y: h * 0.35, width: 28, height: 14)
                let cloud1b = CGRect(x: x1 - 8, y: h * 0.28, width: 20, height: 14)
                var path1 = Path()
                path1.addEllipse(in: cloud1)
                path1.addEllipse(in: cloud1b)
                context.fill(path1, with: .color(.white.opacity(0.35)))

                // Moln 2 — lite förskjutet och annorlunda tempo
                let t2 = (t + 10.0).truncatingRemainder(dividingBy: 25)
                let x2 = CGFloat(t2 / 25.0) * (w + 16) - 8
                let cloud2 = CGRect(x: x2 - 10, y: h * 0.55, width: 20, height: 10)
                let cloud2b = CGRect(x: x2 - 5, y: h * 0.48, width: 14, height: 10)
                var path2 = Path()
                path2.addEllipse(in: cloud2)
                path2.addEllipse(in: cloud2b)
                context.fill(path2, with: .color(.white.opacity(0.25)))
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - Particle

private struct Particle: Identifiable {
    let id = UUID()
    let startX: CGFloat     // 0...1 normaliserad x-position
    let duration: Double    // sekunder per loop
    let size: CGFloat       // partikelstorlek
    let drift: CGFloat      // horisontell drift (0 för regn, ±0.1 för snö)

    static func initial(count: Int, type: ParticleType) -> [Particle] {
        (0..<count).map { _ in
            Particle(
                startX: CGFloat.random(in: 0...1),
                duration: type == .rain
                    ? Double.random(in: 0.8...1.5)
                    : Double.random(in: 2.0...4.0),
                size: type == .rain ? 2 : 3,
                drift: type == .rain ? 0 : CGFloat.random(in: -0.1...0.1)
            )
        }
    }
}

// MARK: - ParticleType

enum ParticleType {
    case rain, snow
}

// MARK: - ParticleAnimationView

private struct ParticleAnimationView: View {
    let type: ParticleType
    private let particles: [Particle]

    init(type: ParticleType) {
        self.type = type
        self.particles = Particle.initial(count: 18, type: type)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let progress = CGFloat(now.truncatingRemainder(dividingBy: particle.duration) / particle.duration)
                    let x = (particle.startX + particle.drift * progress) * size.width
                    let y = progress * size.height

                    if type == .rain {
                        // Capsule — vertikal linje
                        let rect = CGRect(
                            x: x - 0.5,
                            y: y - 3,
                            width: 1.5,
                            height: 6
                        )
                        let path = Path(CGPath(roundedRect: rect, cornerWidth: 0.75, cornerHeight: 3, transform: nil))
                        context.fill(path, with: .color(.white.opacity(0.6)))
                    } else {
                        // Cirkel — snöflingor
                        let rect = CGRect(
                            x: x - particle.size / 2,
                            y: y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )
                        let path = Path(ellipseIn: rect)
                        context.fill(path, with: .color(.white.opacity(0.55)))
                    }
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - ThunderFlashView

private struct ThunderFlashView: View {
    @State private var flashOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Mörk bakgrund
            Circle()
                .fill(Color(white: 0.15, opacity: 0.25))

            // Flash-effekt
            Circle()
                .fill(Color.white.opacity(flashOpacity))
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .onAppear {
            scheduleFlash()
        }
    }

    private func scheduleFlash() {
        let delay = Double.random(in: 3.0...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeIn(duration: 0.08)) {
                flashOpacity = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.12)) {
                    flashOpacity = 0.0
                }
                // Dubbel-blixt — klassiskt åskväder
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.06)) {
                        flashOpacity = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            flashOpacity = 0.0
                        }
                        scheduleFlash()
                    }
                }
            }
        }
    }
}
