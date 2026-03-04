import SwiftUI

// MARK: - Bubble Pop Typography

extension Font {

    // MARK: Headings (Baloo 2)

    /// H1 — large headings, city name in map view.
    /// Baloo 2 ExtraBold 28pt, scales with largeTitle.
    static var bubbleH1: Font {
        .custom("Baloo2-ExtraBold", size: 28, relativeTo: .largeTitle)
    }

    /// H2 — section titles.
    /// Baloo 2 Bold 22pt, scales with title2.
    static var bubbleH2: Font {
        .custom("Baloo2-Bold", size: 22, relativeTo: .title2)
    }

    /// H3 — card titles, dialog titles.
    /// Baloo 2 Bold 18pt, scales with title3.
    static var bubbleH3: Font {
        .custom("Baloo2-Bold", size: 18, relativeTo: .title3)
    }

    // MARK: Interactive (Baloo 2)

    /// Buttons, tab labels.
    /// Baloo 2 SemiBold 15pt, scales with body.
    static var bubbleButton: Font {
        .custom("Baloo2-SemiBold", size: 15, relativeTo: .body)
    }

    /// Large temperature display values.
    /// Baloo 2 ExtraBold 24pt, scales with title2.
    static var bubbleTemperature: Font {
        .custom("Baloo2-ExtraBold", size: 24, relativeTo: .title2)
    }

    /// Small temperature text — widget, badge.
    /// Baloo 2 Bold 16pt, scales with callout.
    static var bubbleTemperatureSmall: Font {
        .custom("Baloo2-Bold", size: 16, relativeTo: .callout)
    }

    // MARK: Body text (SF Pro / system)

    /// Body text. Uses system .body for optimal legibility.
    static var bubbleBody: Font { .body }

    /// Secondary captions.
    static var bubbleCaption: Font { .caption }

    /// Small text — timestamps, footnotes.
    static var bubbleFootnote: Font { .footnote }
}
