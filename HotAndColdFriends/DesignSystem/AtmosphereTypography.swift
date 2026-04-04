import SwiftUI

// MARK: - Atmosphere Typography

// Nunito font is used where available.
// TODO: Bundle Nunito-ExtraBold.ttf, Nunito-SemiBold.ttf, Nunito-Regular.ttf via Info.plist
// until bundled, all styles fall back to .system(.rounded) at matching weight.

extension Font {

    // MARK: Atmosphere Display

    /// Hero temperature — ExtraBold 80pt rounded
    static var atmosphereDisplayTemp: Font {
        // TODO: replace with .custom("Nunito-ExtraBold", size: 80) once font is bundled
        .system(size: 80, weight: .heavy, design: .rounded)
    }

    /// City name — SemiBold 18pt rounded
    static var atmosphereCity: Font {
        // TODO: .custom("Nunito-SemiBold", size: 18)
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    /// Weather condition — Regular 15pt rounded
    static var atmosphereCondition: Font {
        // TODO: .custom("Nunito-Regular", size: 15)
        .system(size: 15, weight: .regular, design: .rounded)
    }

    /// Friend name label — SemiBold 16pt rounded
    static var atmosphereFriendName: Font {
        // TODO: .custom("Nunito-SemiBold", size: 16)
        .system(size: 16, weight: .semibold, design: .rounded)
    }

    /// Friend temperature — ExtraBold 22pt rounded
    static var atmosphereFriendTemp: Font {
        // TODO: .custom("Nunito-ExtraBold", size: 22)
        .system(size: 22, weight: .heavy, design: .rounded)
    }

    /// Friend city label — Regular 13pt rounded
    static var atmosphereFriendCity: Font {
        // TODO: .custom("Nunito-Regular", size: 13)
        .system(size: 13, weight: .regular, design: .rounded)
    }

    /// Section header — Medium 11pt (apply .textCase(.uppercase) at call site)
    static var atmosphereSectionHeader: Font {
        // TODO: .custom("Nunito-Medium", size: 11)
        .system(size: 11, weight: .medium, design: .rounded)
    }

    // MARK: Legacy Tokens (kept so existing callers compile without change)

    /// H1 — maps to atmosphere city-scale heading
    static var bubbleH1: Font {
        // TODO: .custom("Nunito-ExtraBold", size: 28)
        .system(size: 28, weight: .heavy, design: .rounded)
    }

    /// H2 — section titles
    static var bubbleH2: Font {
        // TODO: .custom("Nunito-SemiBold", size: 22)
        .system(size: 22, weight: .semibold, design: .rounded)
    }

    /// H3 — card titles
    static var bubbleH3: Font {
        // TODO: .custom("Nunito-SemiBold", size: 18)
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    /// Button labels
    static var bubbleButton: Font {
        // TODO: .custom("Nunito-SemiBold", size: 15)
        .system(size: 15, weight: .semibold, design: .rounded)
    }

    /// Large temperature display
    static var bubbleTemperature: Font {
        // TODO: .custom("Nunito-ExtraBold", size: 24)
        .system(size: 24, weight: .heavy, design: .rounded)
    }

    /// Small temperature — widget, badge
    static var bubbleTemperatureSmall: Font {
        // TODO: .custom("Nunito-Bold", size: 16)
        .system(size: 16, weight: .bold, design: .rounded)
    }

    /// Body text
    static var bubbleBody: Font { .system(size: 15, weight: .regular, design: .rounded) }

    /// Secondary captions
    static var bubbleCaption: Font { .system(size: 12, weight: .regular, design: .rounded) }

    /// Small text — timestamps, footnotes
    static var bubbleFootnote: Font { .system(size: 11, weight: .regular, design: .rounded) }
}
