import SwiftUI

// MARK: - MotionReducedModifier

/// Central ViewModifier that provides Reduce Motion fallback for all animations.
/// Uses `@Environment(\.accessibilityReduceMotion)` to switch between a spring animation
/// and a crossfade (opacity-based) animation automatically.
struct MotionReducedModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation
    let value: V

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: value)
    }
}

// MARK: - CrossfadeIfReducedModifier

/// Convenience modifier that applies no explicit animation normally,
/// but switches to a crossfade when Reduce Motion is enabled.
struct CrossfadeIfReducedModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: V

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .easeInOut(duration: 0.25) : nil, value: value)
    }
}

