import SwiftUI

// MARK: - BubblePopButton

/// A pill-shaped button with brand gradient and a subtle bounce animation on press.
/// Use this as the primary action button throughout the app.
struct BubblePopButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    @State private var isPressed = false

    var body: some View {
        Text(title)
            .font(.bubbleButton)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .background(background)
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .shadowGlowPrimary()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }

    @ViewBuilder
    private var background: some View {
        if isDestructive {
            Color.bubbleError
        } else {
            LinearGradient(
                colors: [.bubblePrimary, .bubbleSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        BubblePopButton(title: "Get Started") {
            print("primary tapped")
        }

        BubblePopButton(title: "Continue") {
            print("secondary tapped")
        }

        BubblePopButton(title: "Delete Account", action: {
            print("destructive tapped")
        }, isDestructive: true)
    }
    .padding()
}
