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

// MARK: - MotionReducer Environment Helper

/// Provides a read-only accessor for accessibilityReduceMotion.
/// Use in views that need manual branching (e.g., hiding confetti entirely).
enum MotionReducer {
    // Note: Cannot provide a static property for @Environment.
    // Views should use @Environment(\.accessibilityReduceMotion) directly
    // for manual branching, and the .motionReduced() modifier for animation switching.
}

// MARK: - View Extensions

extension View {
    /// Chooses between a spring animation and a crossfade based on Reduce Motion setting.
    ///
    /// - Parameters:
    ///   - animation: The full animation to use when Reduce Motion is off.
    ///   - reducedAnimation: The simplified animation when Reduce Motion is on.
    ///     Defaults to a 0.25s crossfade.
    ///   - value: The value to animate changes of.
    func motionReduced<V: Equatable>(
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.6),
        reducedAnimation: Animation = .easeInOut(duration: 0.25),
        value: V
    ) -> some View {
        modifier(MotionReducedModifier(
            animation: animation,
            reducedAnimation: reducedAnimation,
            value: value
        ))
    }

    /// Applies no animation normally, but uses a crossfade when Reduce Motion is enabled.
    func crossfadeIfReduced<V: Equatable>(value: V) -> some View {
        modifier(CrossfadeIfReducedModifier(value: value))
    }
}
