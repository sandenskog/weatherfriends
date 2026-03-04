import SwiftUI

// MARK: - Spacing (8pt grid)

/// 8-point spacing grid constants for consistent layout.
enum Spacing {
    /// 4pt — tight gaps, icon padding
    static let xs: CGFloat = 4

    /// 8pt — compact spacing, chip gaps
    static let sm: CGFloat = 8

    /// 16pt — standard content padding
    static let md: CGFloat = 16

    /// 24pt — section gaps
    static let lg: CGFloat = 24

    /// 32pt — large section separation
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius

/// Corner radius scale matching the Bubble Pop design system.
enum CornerRadius {
    /// 12pt — compact elements (chips, small badges)
    static let sm: CGFloat = 12

    /// 20pt — cards, input fields
    static let md: CGFloat = 20

    /// 28pt — large cards, bottom sheets
    static let lg: CGFloat = 28

    /// 50pt — pill-shaped buttons, large badges
    static let xl: CGFloat = 50

    /// 9999pt — fully circular (use .clipShape(Circle()) when possible)
    static let round: CGFloat = 9999
}
