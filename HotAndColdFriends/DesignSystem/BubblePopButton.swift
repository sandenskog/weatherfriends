import SwiftUI

// MARK: - BubblePopButton

/// A pill-shaped button using glass material with a subtle bounce animation on press.
/// Updated to Atmosphere design — no solid color backgrounds.
struct BubblePopButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false
    var isLoading: Bool = false
    var isDisabled: Bool = false

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
            }
        }
        .font(.bubbleButton)
        .foregroundStyle(isDestructive ? Color.bubbleError : Color.atmosphereTextOnSky)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm + Spacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isDestructive ? Color.bubbleError.opacity(0.5) : Color.white.opacity(0.25),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled && !isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    action()
                }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        BubblePopButton(title: "Share My Weather") { }
        BubblePopButton(title: "Delete Account", action: { }, isDestructive: true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: 0x1A85E0))
}
