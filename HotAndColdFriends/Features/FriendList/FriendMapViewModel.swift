import Foundation
import UIKit
import Observation

@Observable
@MainActor
class FriendMapViewModel {
    var loadedImages: [String: UIImage] = [:]
    var isLoading = false

    func preloadImages(for friendWeathers: [FriendWeather]) async {
        isLoading = true
        defer { isLoading = false }

        let urls = friendWeathers.compactMap { $0.friend.photoURL }
            .filter { loadedImages[$0] == nil }

        await withTaskGroup(of: (String, UIImage?).self) { group in
            for urlString in Set(urls) {
                group.addTask {
                    guard let url = URL(string: urlString),
                          let (data, _) = try? await URLSession.shared.data(from: url),
                          let image = UIImage(data: data) else {
                        return (urlString, nil)
                    }
                    return (urlString, image)
                }
            }
            for await (urlString, image) in group {
                if let image {
                    loadedImages[urlString] = image
                }
            }
        }
    }
}
