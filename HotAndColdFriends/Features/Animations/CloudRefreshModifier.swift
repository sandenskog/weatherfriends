import SwiftUI

// MARK: - CloudRefreshModifier

/// A custom pull-to-refresh modifier that shows a cloud with rain animation
/// instead of the standard spinner. Falls back to standard `.refreshable`
/// when Reduce Motion is enabled.
struct CloudRefreshModifier: ViewModifier {
    let action: @Sendable () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRefreshing = false

    func body(content: Content) -> some View {
        if reduceMotion {
            // Reduce Motion: use standard refreshable
            content
                .refreshable { await action() }
        } else {
            content
                .refreshable {
                    isRefreshing = true
                    await action()
                    // Small delay so the animation has time to show
                    try? await Task.sleep(for: .milliseconds(400))
                    isRefreshing = false
                }
                .overlay(alignment: .top) {
                    if isRefreshing {
                        CloudRainView()
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            .padding(.top, 8)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
        }
    }
}

// MARK: - CloudRainView

/// A small cloud shape with rain drops falling beneath it.
private struct CloudRainView: View {
    @State private var animateDrops = false

    var body: some View {
        VStack(spacing: 0) {
            // Cloud shape using overlapping ellipses
            cloudShape
                .frame(width: 48, height: 28)

            // Rain drops
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    RainDrop()
                        .frame(width: 3, height: 8)
                        .offset(y: animateDrops ? 12 : 0)
                        .opacity(animateDrops ? 0.0 : 0.8)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.12),
                            value: animateDrops
                        )
                }
            }
            .padding(.top, 2)
        }
        .onAppear {
            animateDrops = true
        }
    }

    private var cloudShape: some View {
        Canvas { context, size in
            let gray = Color(.systemGray4)

            // Main body ellipse
            let mainRect = CGRect(
                x: size.width * 0.15,
                y: size.height * 0.35,
                width: size.width * 0.7,
                height: size.height * 0.65
            )
            context.fill(Ellipse().path(in: mainRect), with: .color(gray))

            // Top-left bump
            let leftBump = CGRect(
                x: size.width * 0.12,
                y: size.height * 0.1,
                width: size.width * 0.4,
                height: size.height * 0.55
            )
            context.fill(Ellipse().path(in: leftBump), with: .color(gray))

            // Top-right bump (taller)
            let rightBump = CGRect(
                x: size.width * 0.38,
                y: 0,
                width: size.width * 0.42,
                height: size.height * 0.65
            )
            context.fill(Ellipse().path(in: rightBump), with: .color(gray))
        }
    }
}

// MARK: - RainDrop Shape

private struct RainDrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Teardrop shape
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: h),
            control: CGPoint(x: w * 1.3, y: h * 0.6)
        )
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: 0),
            control: CGPoint(x: -w * 0.3, y: h * 0.6)
        )
        return path
    }
}

// MARK: - View Extension

extension View {
    /// Adds a custom cloud-and-rain pull-to-refresh animation.
    /// Falls back to standard `.refreshable` when Reduce Motion is enabled.
    func cloudRefreshable(action: @escaping @Sendable () async -> Void) -> some View {
        modifier(CloudRefreshModifier(action: action))
    }
}
