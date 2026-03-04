import SwiftUI

// MARK: - Shadow Scale (View Modifiers)

extension View {

    /// Small shadow — subtle elements, list rows.
    /// CSS: `0 2px 8px rgba(45,49,66,0.06)`
    func shadowSm() -> some View {
        self.shadow(
            color: Color(red: 0.176, green: 0.192, blue: 0.259).opacity(0.06),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    /// Medium shadow — cards, buttons, active elements.
    /// CSS: `0 8px 24px rgba(45,49,66,0.08)`
    func shadowMd() -> some View {
        self.shadow(
            color: Color(red: 0.176, green: 0.192, blue: 0.259).opacity(0.08),
            radius: 12,
            x: 0,
            y: 8
        )
    }

    /// Large shadow — modals, popovers, bottom sheets.
    /// CSS: `0 16px 48px rgba(45,49,66,0.10)`
    func shadowLg() -> some View {
        self.shadow(
            color: Color(red: 0.176, green: 0.192, blue: 0.259).opacity(0.1),
            radius: 24,
            x: 0,
            y: 16
        )
    }

    /// Primary glow — active primary buttons, favorites, highlighted elements.
    /// CSS: `0 8px 24px rgba(255,107,138,0.25)`
    func shadowGlowPrimary() -> some View {
        self.shadow(
            color: Color.bubblePrimary.opacity(0.25),
            radius: 12,
            x: 0,
            y: 8
        )
    }

    /// Accent glow — special interactions, accent highlights.
    /// CSS: `0 8px 24px rgba(255,217,61,0.25)`
    func shadowGlowAccent() -> some View {
        self.shadow(
            color: Color.bubbleAccent.opacity(0.25),
            radius: 12,
            x: 0,
            y: 8
        )
    }
}
