import UIKit
import FirebaseCore
import GoogleSignIn
import FacebookCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase konfigureras i HotAndColdFriendsApp.init() för korrekt ordning
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Facebook SDK setup
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Google Sign-In URL handling
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Facebook URL handling as fallback
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
