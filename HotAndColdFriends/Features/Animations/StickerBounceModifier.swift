import SwiftUI

// MARK: - StickerBounceModifier

/// Animates a bounce-in effect for sticker views on appear.
/// Full animation: fade in + slide up + overshoot scale with spring.
/// Reduce Motion: simple fade in only.
struct StickerBounceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1.0 : 0.0)
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : 20))
            .scaleEffect(reduceMotion ? 1.0 : (appeared ? 1.0 : 0.8))
            .onAppear {
                if reduceMotion {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        appeared = true
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                        appeared = true
                    }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a bounce-in animation on appear: fade + slide up + overshoot scale.
    /// With Reduce Motion: simple fade in.
    func stickerBounce() -> some View {
        modifier(StickerBounceModifier())
    }
}
