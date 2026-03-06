import SwiftUI

// MARK: - ConfettiParticle

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat          // 0...1 normalized start X
    let size: CGFloat        // point size
    let color: Color
    let shape: ParticleShape
    let rotation: Double     // initial rotation degrees
    let rotationSpeed: Double
    let fallSpeed: CGFloat   // points per second
    let swayAmplitude: CGFloat
    let swayFrequency: CGFloat
    let delay: Double        // seconds before appearing

    enum ParticleShape {
        case circle
        case rectangle
        case iconSun
        case iconSnow
        case iconRain
    }
}

// MARK: - ConfettiOverlay

/// A confetti overlay that spawns temperature-zone-colored particles.
/// Particles fall downward with gravity, sway, and fade out after ~2 seconds.
/// Hidden entirely when Reduce Motion is enabled.
struct ConfettiOverlay: View {
    @Binding var isActive: Bool
    let zone: TemperatureZone

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [ConfettiParticle] = []
    @State private var elapsedTime: TimeInterval = 0
    @State private var startDate: Date?

    private let duration: TimeInterval = 2.2
    private let particleCount = 45

    var body: some View {
        if reduceMotion {
            // Reduce Motion: show nothing
            Color.clear
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { timeline in
                Canvas { context, size in
                    guard let start = startDate else { return }
                    let elapsed = timeline.date.timeIntervalSince(start)

                    for particle in particles {
                        let t = elapsed - particle.delay
                        guard t > 0 else { continue }

                        let progress = t / duration
                        guard progress < 1.0 else { continue }

                        // Position
                        let startX = particle.x * size.width
                        let sway = sin(t * Double(particle.swayFrequency)) * Double(particle.swayAmplitude)
                        let x = startX + sway

                        // Gravity: accelerate downward
                        let gravity: CGFloat = 180
                        let y: CGFloat = -20 + CGFloat(t) * particle.fallSpeed + 0.5 * gravity * CGFloat(t * t)

                        guard y < size.height + 20 else { continue }

                        // Fade out in last 40% of life
                        let opacity = progress > 0.6 ? 1.0 - ((progress - 0.6) / 0.4) : 1.0

                        let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * t)

                        context.opacity = opacity
                        context.translateBy(x: x, y: y)
                        context.rotate(by: rotation)

                        switch particle.shape {
                        case .circle:
                            let rect = CGRect(x: -particle.size / 2, y: -particle.size / 2,
                                              width: particle.size, height: particle.size)
                            context.fill(Circle().path(in: rect), with: .color(particle.color))

                        case .rectangle:
                            let rect = CGRect(x: -3, y: -5, width: 6, height: 10)
                            context.fill(Rectangle().path(in: rect), with: .color(particle.color))

                        case .iconSun:
                            let symbol = context.resolve(Image(systemName: "sun.max.fill"))
                            context.draw(symbol, at: .zero)

                        case .iconSnow:
                            let symbol = context.resolve(Image(systemName: "snowflake"))
                            context.draw(symbol, at: .zero)

                        case .iconRain:
                            let symbol = context.resolve(Image(systemName: "drop.fill"))
                            context.draw(symbol, at: .zero)
                        }

                        // Reset transforms
                        context.rotate(by: -rotation)
                        context.translateBy(x: -x, y: -y)
                    }
                }
            }
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active {
                    spawnParticles()
                    startDate = Date()
                    // Auto-deactivate after duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.3) {
                        isActive = false
                        particles = []
                        startDate = nil
                    }
                }
            }
        }
    }

    // MARK: - Particle Generation

    private func spawnParticles() {
        let colors = particleColors(for: zone)
        let shapes: [ConfettiParticle.ParticleShape] = [
            .circle, .circle, .circle,
            .rectangle, .rectangle, .rectangle,
            .iconSun, .iconSnow, .iconRain
        ]

        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 6...10),
                color: colors.randomElement() ?? zone.color,
                shape: shapes.randomElement() ?? .circle,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180),
                fallSpeed: CGFloat.random(in: 60...140),
                swayAmplitude: CGFloat.random(in: 10...30),
                swayFrequency: CGFloat.random(in: 2...5),
                delay: Double.random(in: 0...0.4)
            )
        }
    }

    private func particleColors(for zone: TemperatureZone) -> [Color] {
        [
            zone.color,
            zone.color.opacity(0.7),
            zone.color.opacity(1.0).saturated(),
            .white.opacity(0.8)
        ]
    }
}

// MARK: - Color Extension (Saturation Helper)

private extension Color {
    func saturated() -> Color {
        // Return a slightly different shade by mixing with white
        self.opacity(0.9)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a confetti overlay that triggers when `isActive` becomes true.
    /// Particles are colored based on the given temperature zone.
    /// Hidden entirely when Reduce Motion is enabled.
    func confettiOverlay(isActive: Binding<Bool>, zone: TemperatureZone) -> some View {
        overlay {
            ConfettiOverlay(isActive: isActive, zone: zone)
        }
    }
}
