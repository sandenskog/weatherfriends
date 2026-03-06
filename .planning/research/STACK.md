# Stack Research: v3.0 Virality & Polish

**Domain:** iOS social weather app — shareable image generation, invite deep linking, in-app engagement
**Researched:** 2026-03-06
**Confidence:** HIGH

## Scope

This research covers ONLY new stack additions for v3.0. The existing validated stack (SwiftUI iOS 17+, Firebase 11.x, WeatherKit, MapKit, WidgetKit, OpenAI proxy, Bubble Pop Design System) is not re-evaluated.

Three capability areas:
1. **Shareable weather cards** — generating images from SwiftUI views, sharing to Instagram/iMessage
2. **Improved invite flows** — Universal Links replacing custom URL scheme, web fallback
3. **In-app engagement** — contextual tips, nudges, engagement triggers

---

## Recommended Stack Additions

### 1. Shareable Image Generation

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `ImageRenderer` (SwiftUI) | iOS 16+ (already available) | Convert SwiftUI views to UIImage/CGImage | Native Apple API, zero dependencies. Renders any SwiftUI view including Bubble Pop gradients, AvatarView, custom weather icons. No third-party library needed. |
| `ShareLink` (SwiftUI) | iOS 16+ (already in use) | Present system share sheet | Already used in ProfileView for invite links. Extend to share generated weather card images with Transferable protocol. |
| Instagram Stories URL scheme | N/A | Direct share to Instagram Stories | Uses `instagram-stories://share` with pasteboard data. Supports background image + sticker overlay + gradient background colors. ~20 lines of code — no SDK needed. |

**Key insight:** No new packages needed. `ImageRenderer` + `ShareLink` are built into SwiftUI and already available at the iOS 17 deployment target. The weather card is just a SwiftUI view — design it with Bubble Pop components, render to image, share.

#### ImageRenderer Pattern

```swift
// 1. Design the card as a normal SwiftUI view
struct WeatherCard: View { ... }

// 2. Render to UIImage (must be on @MainActor)
let renderer = ImageRenderer(content: WeatherCard(friend: friend))
renderer.scale = UIScreen.main.scale  // Retina resolution
let image = renderer.uiImage

// 3. Share via ShareLink or Instagram Stories
```

**Important:** `ImageRenderer` runs on `@MainActor`. For complex views, render asynchronously to avoid blocking the UI. The renderer handles gradients, shadows, and custom fonts — all Bubble Pop components will render correctly.

#### Instagram Stories Integration

Requires adding to Info.plist:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram-stories</string>
</array>
```

Share via pasteboard with keys:
- `com.instagram.sharedSticker.backgroundImage` — weather card as PNG data
- `com.instagram.sharedSticker.stickerImage` — optional FriendsCast logo overlay
- `com.instagram.sharedSticker.backgroundTopColor` / `backgroundBottomColor` — fallback gradient (use temperature zone colors)

Always guard with `UIApplication.shared.canOpenURL(URL(string: "instagram-stories://share")!)` before showing the Instagram share option.

---

### 2. Universal Links (Invite Deep Linking)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Universal Links (Apple) | iOS 9+ | HTTPS-based deep links | Replaces current `hotandcold://` custom URL scheme for invite links. More secure (domain-verified), works everywhere links are shared (iMessage, Instagram, email), falls back to web if app not installed. |
| `apple-app-site-association` | N/A | JSON file on web server | Associates the domain with the app. Hosted at `https://<domain>/.well-known/apple-app-site-association`. |
| Associated Domains entitlement | Xcode capability | Register domain in app | Add `applinks:<domain>` to Associated Domains. |

#### Why Migrate from Custom URL Scheme

The current `hotandcold://invite/<token>` scheme has critical virality problems:

1. **iMessage strips custom schemes** — links become unclickable plain text
2. **Instagram/social media block custom schemes** — links don't work when shared
3. **No web fallback** — if app isn't installed, nothing happens (dead end for new users)
4. **No deferred deep linking** — user installs app but loses the invite context

Universal Links (`https://friendscast.app/invite/<token>`) solve all four problems:
- Clickable everywhere (it's just an HTTPS URL)
- Falls back to web page with App Store link if app not installed
- App opens directly if installed (no browser intermediate)

#### What's Needed

**On the app side:**
- Add Associated Domains entitlement with `applinks:<domain>`
- Handle Universal Links in `onOpenURL` (same modifier, different URL format)
- Change `InviteService.inviteURL()` to return HTTPS URL

**On the server side (existing Docker website on Synology):**
1. Serve `/.well-known/apple-app-site-association` with `Content-Type: application/json`
2. Add `/invite/<token>` route — redirects to App Store if app not detected, or shows invite preview page

**AASA file content:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "A473BQKT8M.se.sandenskog.hotandcoldfriends",
        "paths": ["/invite/*"]
      }
    ]
  }
}
```

**Important:** Apple's CDN caches this file. Changes can take 24-48 hours to propagate. Test with Apple's AASA validator during development.

#### Keep Custom URL Scheme for Internal Use

The `hotandcold://friend/<id>` scheme for widget deep links should remain — it's internal (widget to app) and doesn't go through external platforms.

#### No Third-Party Deep Link Service Needed

Firebase Dynamic Links shut down August 25, 2025 — do NOT use. Branch.io, AppsFlyer, etc. are overkill for an iOS-only app with a single link type (invites). Native Universal Links with a simple web fallback is the correct approach: free, no SDK dependency, no third-party privacy implications.

---

### 3. In-App Engagement & Nudges

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| TipKit (Apple) | iOS 17+ (exact match with target) | Contextual in-app tips and feature discovery | Native Apple framework. Declarative API matching SwiftUI patterns. Handles display frequency, eligibility rules, and dismissal persistence automatically. |
| UNUserNotificationCenter (local) | iOS 10+ (already used) | Scheduled local notification nudges | Already in use for push. Local notifications for engagement nudges ("3 friends have weather changes today!") without server involvement. |
| `sensoryFeedback` (SwiftUI) | iOS 17+ (exact match) | Haptic feedback on engagement actions | Native modifier for haptic responses on shares, reactions, invite accepts. Enhances tactile feel of social interactions. |

#### TipKit Use Cases for FriendsCast

| Tip | Trigger | Where |
|-----|---------|-------|
| "Share a weather card" | After viewing 3+ friend details | WeatherDetailView |
| "Invite friends to see their weather" | Friend count < 5 | FriendListView |
| "Try the map view" | After 5 list view sessions | Tab area |
| "React to weather changes" | First extreme weather event | Weather alert banner |
| "Add to favorites" | After chatting with same friend 3 times | Friend row |

#### Why TipKit Over Custom Tooltips

- Apple handles persistence — tips don't re-show after dismissal across sessions
- Built-in frequency throttling — `.daily`, `.weekly`, `.monthly` presets
- Parameter-based rules — trigger tips based on user behavior counters
- Native popover and inline styles matching iOS design language
- Optional CloudKit sync across devices
- Zero custom state management code needed

#### TipKit Setup

```swift
// In HotAndColdFriendsApp.init():
try? Tips.configure([
    .displayFrequency(.daily)  // Max one tip per day
])

// Define a tip:
struct ShareWeatherCardTip: Tip {
    var title: Text { Text("Share this weather") }
    var message: Text? { Text("Create a beautiful card to share with friends") }
    var image: Image? { Image(systemName: "square.and.arrow.up") }

    @Parameter static var friendViewCount: Int = 0

    var rules: [Rule] {
        #Rule(Self.$friendViewCount) { $0 >= 3 }
    }
}
```

#### Local Notification Nudges

Extend existing notification infrastructure for engagement:
- "You haven't checked your friends' weather today" — morning reminder (user-configurable)
- "Weather changed dramatically for 3 friends" — triggered by weather check
- Re-engagement after 3 days of inactivity

Use `UNMutableNotificationContent` + `UNCalendarNotificationTrigger` / `UNTimeIntervalNotificationTrigger`. No new framework needed.

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Firebase Dynamic Links | **Shut down August 25, 2025.** Non-functional. | Universal Links with web fallback |
| Branch.io / AppsFlyer / deep link SDKs | Overkill for iOS-only app with single link type. Adds SDK dependency, privacy consent requirements, and cost. | Native Universal Links |
| Third-party image generation (server-side) | `ImageRenderer` handles everything natively with zero latency. Server rendering adds complexity and cost for no benefit. | SwiftUI `ImageRenderer` |
| Custom tooltip/tip libraries | TipKit is purpose-built by Apple for this exact use case. Custom solutions require state management, persistence, and frequency logic you'd have to build yourself. | Apple TipKit |
| IGStoryKit (SPM package) | Wrapper around Instagram's URL scheme — the underlying code is ~20 lines. Not worth a dependency. | Direct Instagram Stories URL scheme |
| Additional animation libraries (Lottie, etc.) | AnimationKit local package + SwiftUI spring animations already cover all needs. | Existing AnimationKit + SwiftUI `.spring()` |
| Analytics SDKs (Mixpanel, Amplitude) | Premature. Firebase Analytics (already included in Firebase SDK) handles basic event tracking. Add dedicated analytics only when product-market fit is proven. | Firebase Analytics |
| Snap Kit sharing | Snapchat sharing SDK adds complexity and another dependency. Instagram Stories has 10x the sharing volume for weather content. Snapchat can be added later if demand exists. | Instagram Stories + general ShareLink |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Universal Links | Custom URL scheme (current `hotandcold://`) | Keep only for internal widget-to-app deep links. Never for externally shared links. |
| `ImageRenderer` | Server-side rendering (Cloud Function + Puppeteer/Sharp) | Only if cards need to be generated without the app (e.g., for link preview images in OG meta tags). Could be a future enhancement. |
| TipKit | Custom SwiftUI overlay system | Only if needing to target iOS 16 or earlier. Since target is iOS 17+, always use TipKit. |
| Direct Instagram URL scheme | IGStoryKit SPM package | Never — the abstraction adds no value for a single integration point. |
| `ShareLink` | `UIActivityViewController` wrapper | Only if needing to exclude specific share targets or add custom activities. ShareLink covers all v3.0 needs. |
| Local notification nudges | Server-triggered push via FCM | Use FCM for real-time events (friend weather alerts). Use local notifications for time-based engagement (daily check-in reminders). |

---

## Configuration Changes Required

### project.yml Additions

```yaml
# Add entitlements file reference
settings:
  base:
    # ... existing settings unchanged ...
    CODE_SIGN_ENTITLEMENTS: HotAndColdFriends/HotAndColdFriends.entitlements

# Or add via entitlements section (xcodegen syntax)
targets:
  HotAndColdFriends:
    entitlements:
      path: HotAndColdFriends/HotAndColdFriends.entitlements
      properties:
        com.apple.developer.associated-domains:
          - "applinks:friendscast.app"  # Replace with actual domain
```

### Info.plist Additions

```xml
<!-- Instagram Stories sharing capability check -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram-stories</string>
</array>
```

### New Swift Imports

```swift
import TipKit  // For in-app tips — new addition
// ImageRenderer, ShareLink, sensoryFeedback are in SwiftUI — no new import
```

### App Initialization

```swift
// Add to HotAndColdFriendsApp.init():
try? Tips.configure([
    .displayFrequency(.daily)
])
```

---

## Version Compatibility

| Component | Minimum iOS | Available in Target (17+) | Notes |
|-----------|-------------|--------------------------|-------|
| ImageRenderer | iOS 16 | Yes | Use `@MainActor` context. Set `.scale` for Retina output. |
| ShareLink | iOS 16 | Yes | Already in use in ProfileView. |
| TipKit | iOS 17 | Yes | Exact match with deployment target. |
| Universal Links | iOS 9 | Yes | Universally supported. Requires HTTPS domain with valid cert. |
| Instagram Stories URL scheme | iOS 10 | Yes | Requires Instagram app installed. Guard with `canOpenURL`. |
| sensoryFeedback modifier | iOS 17 | Yes | Exact match with deployment target. |
| UNUserNotificationCenter | iOS 10 | Yes | Already in use for push notifications. |

**All recommended technologies are available at the iOS 17 deployment target. No minimum version changes needed.**

---

## Integration Points with Existing Stack

| New Capability | Integrates With | How |
|----------------|----------------|-----|
| Weather card rendering | Bubble Pop Design System | Card view uses temperature zone gradients, AvatarView, BubblePopTypography, custom weather icons |
| Weather card rendering | WeatherKit data | Renders friend's current weather (temp, condition, icon) into visual card |
| Weather card rendering | Friend model | Card includes friend name, city, avatar with gradient |
| Universal Links | InviteService | Change `inviteURL(token:)` to return `https://<domain>/invite/<token>` instead of `hotandcold://invite/<token>` |
| Universal Links | HotAndColdFriendsApp `onOpenURL` | Same handler, parse HTTPS URLs in addition to custom scheme |
| Universal Links | Website Docker container | Add AASA file + invite route to existing Synology-hosted website |
| Universal Links | Synology reverse proxy | Follow existing pattern (reverse proxy + Let's Encrypt cert) |
| TipKit | FriendListView, WeatherDetailView, MapView | Attach `.popoverTip()` modifiers to relevant UI elements |
| TipKit | User behavior tracking | Increment `@Parameter` counters on friend views, shares, chats |
| Local notifications | WeatherAlertService | Extend existing service with engagement-type local notifications |
| Instagram sharing | ImageRenderer output | Generated weather card image feeds into Instagram Stories pasteboard |
| sensoryFeedback | BubblePopButton, share actions, invite accept | Add `.sensoryFeedback(.success, ...)` on key interactions |

---

## Domain/Hosting for Universal Links

Universal Links require an HTTPS domain with the AASA file. Based on existing infrastructure:

**Recommended approach:** Use the existing FriendsCast website (Docker on Synology). It already has a landing page — add:
1. `/.well-known/apple-app-site-association` JSON file
2. `/invite/<token>` route with web fallback (show invite info + App Store button)
3. SSL certificate via Synology Let's Encrypt (already documented in CLAUDE.md)

This requires a domain (verify if one exists for the website, or set one up following the existing Synology pattern).

---

## Summary: What Changes

| Category | Before (v2.0) | After (v3.0) |
|----------|---------------|--------------|
| Image generation | None | `ImageRenderer` for weather cards |
| Sharing | `ShareLink` for invite URL only | `ShareLink` for images + Instagram Stories direct share |
| Deep linking | `hotandcold://` custom scheme | Universal Links (HTTPS) for invites, custom scheme kept for widgets |
| In-app guidance | None | TipKit for contextual feature discovery |
| Engagement nudges | Push notifications only | Push + local notification engagement nudges |
| Haptics | None | `sensoryFeedback` on key interactions |
| New packages | — | **Zero new packages** |
| New Apple frameworks | — | TipKit (1 new import) |

**The most significant finding: all v3.0 capabilities can be achieved with zero new third-party dependencies.** Everything needed is built into iOS 17 and SwiftUI. The only infrastructure change is adding Universal Links support to the existing website.

---

## Sources

- [Apple ImageRenderer documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) — official API reference (HIGH confidence)
- [Apple TipKit documentation](https://developer.apple.com/documentation/tipkit/) — official framework reference (HIGH confidence)
- [Apple Universal Links documentation](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app) — official setup guide (HIGH confidence)
- [SwiftLee — Universal Links implementation](https://www.avanderlee.com/swiftui/universal-links-ios/) — practical SwiftUI implementation (HIGH confidence)
- [tanaschita — Universal Links in SwiftUI](https://tanaschita.com/ios-universal-links-swiftui/) — SwiftUI-specific handling (HIGH confidence)
- [Hacking with Swift — ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) — practical tutorial (HIGH confidence)
- [Hacking with Swift — ShareLink](https://www.hackingwithswift.com/books/ios-swiftui/sharing-an-image-using-sharelink) — image sharing tutorial (HIGH confidence)
- [Firebase Dynamic Links shutdown](https://chottulink.com/blog/firebase-dynamic-links-shut-down-5-best-alternatives-for-2026/) — confirms August 25, 2025 shutdown (MEDIUM confidence)
- [Instagram Stories sharing from iOS](https://medium.com/@danielcrompton5/share-content-to-an-instagram-story-from-an-ios-app-d55b1e10e68a) — URL scheme implementation (MEDIUM confidence)
- [Instagram Stories SwiftUI PoC](https://gist.github.com/shaundon/28d121931eab29d4feb1f61b21b60e28) — working code example (MEDIUM confidence)
- [Codakuma — Instagram Stories in SwiftUI](https://codakuma.com/instagram-stories-sharing-swiftui/) — SwiftUI-specific guide (MEDIUM confidence)
- [Universal Links vs Custom URL Schemes 2026](https://dev.to/marko_boras_64fe51f7833a6/universal-deep-links-2026-complete-guide-36c4) — comparison and best practices (MEDIUM confidence)
- [Mastering TipKit](https://fatbobman.com/en/posts/mastering-tipkit-basic/) — comprehensive TipKit guide (MEDIUM confidence)

---
*Stack research for: FriendsCast v3.0 Virality & Polish*
*Researched: 2026-03-06*
