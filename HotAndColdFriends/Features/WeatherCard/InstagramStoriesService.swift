import UIKit

// MARK: - Instagram Stories Service

/// Handles sharing weather card images to Instagram Stories via the
/// `instagram-stories://share` URL scheme and `UIPasteboard`.
///
/// Requires `instagram-stories` in `LSApplicationQueriesSchemes` (Info.plist)
/// so that `canOpenURL` returns `true` on devices with Instagram installed.
@MainActor
final class InstagramStoriesService {

    /// Whether the device can open Instagram Stories (i.e. Instagram is installed
    /// and the URL scheme is declared in Info.plist).
    static var canShareToStories: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Shares an image as a full-screen background sticker to Instagram Stories.
    ///
    /// The image is placed on `UIPasteboard.general` with a 5-minute expiration,
    /// then the Instagram Stories composer is opened via its URL scheme.
    ///
    /// - Parameter image: The card image to share.
    static func shareToStories(image: UIImage) {
        guard let imageData = image.pngData() else { return }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]

        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300)
        ]

        UIPasteboard.general.setItems([pasteboardItems], options: options)

        let bundleId = Bundle.main.bundleIdentifier ?? ""
        guard let url = URL(string: "instagram-stories://share?source_application=\(bundleId)") else { return }
        UIApplication.shared.open(url)
    }
}
