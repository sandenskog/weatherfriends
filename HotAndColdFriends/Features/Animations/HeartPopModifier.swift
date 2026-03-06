import SwiftUI

// MARK: - HeartPopModifier

/// Animates a "pop" effect when `isActive` changes to `true`.
/// Full animation: scale 1.0 → 0.6 → 1.3 → 1.0 with spring.
/// Reduce Motion: opacity pulse instead of scale.
struct HeartPopModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : scale)
            .opacity(reduceMotion ? opacity : 1.0)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerAnimation()
                }
            }
    }

    private func triggerAnimation() {
        if reduceMotion {
            // Opacity pulse for Reduce Motion
            withAnimation(.easeInOut(duration: 0.15)) {
                opacity = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    opacity = 1.0
                }
            }
        } else {
            // Spring scale sequence: shrink → overshoot → settle
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a heart-pop animation when `isActive` becomes `true`.
    /// Animates scale: 1.0 → 0.6 → 1.3 → 1.0 with spring.
    /// With Reduce Motion: simple opacity pulse.
    func heartPop(isActive: Bool) -> some View {
        modifier(HeartPopModifier(isActive: isActive))
    }
}
