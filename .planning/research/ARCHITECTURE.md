# Architecture Patterns: v3.0 Virality & Polish

**Domain:** Viral sharing, invite experience, and engagement loops for existing SwiftUI + Firebase weather social app
**Researched:** 2026-03-06
**Confidence:** HIGH (based on existing codebase analysis + verified Apple APIs)

## Current Architecture Summary

The app follows a clean MVVM pattern with `@Observable` services injected via SwiftUI `.environment()`. All services are `@MainActor` and instantiated in `HotAndColdFriendsApp.init()`:

```
HotAndColdFriendsApp
  |-- AuthManager
  |-- UserService
  |-- FriendService
  |-- ChatService
  |-- AppWeatherService (WeatherKit, 30-min cache)
  |-- WeatherAlertService
  |-- InviteService
```

**Backend:** Firebase Cloud Functions (TypeScript, europe-west1) with 4 functions:
- `guessContactLocations` -- OpenAI proxy (onCall)
- `onNewMessage` -- Chat push notifications (onDocumentCreated)
- `onFriendAlertUpdated` -- Weather alert push (onDocumentUpdated)
- `checkExtremeWeather` -- Stale alert cleanup (onSchedule, every 60 min)

**Design System:** Bubble Pop with 5 temperature zones (`TemperatureZone`), gradients, `AvatarView`, `BubblePopButton`, `BubblePopTypography`/`BubblePopSpacing`/`BubblePopShadows`.

**Deep linking:** `hotandcold://invite/<token>` and `hotandcold://friend/<id>` handled in `onOpenURL`.

**Existing invite flow:** Profile -> Generate invite link -> ShareLink. Token is 12-char UUID prefix stored in `invites/{token}`, deleted after redemption. Redeemer pastes token/URL in AddFriendSheet.

---

## Recommended Architecture for v3.0

### Overview: New and Modified Components

| Component | Type | New/Modified | Responsibility |
|-----------|------|--------------|----------------|
| `WeatherCardView` | SwiftUI View | **NEW** | Renders the shareable weather card layout (not displayed in app) |
| `WeatherCardRenderer` | Service | **NEW** | Wraps `ImageRenderer` to produce UIImage from WeatherCardView |
| `ShareService` | Service | **NEW** | Coordinates sharing flows (weather cards + invite cards) |
| `InviteCardView` | SwiftUI View | **NEW** | Visual invite card for share sheet preview |
| `NudgeService` | Service | **NEW** | Client-side nudge state tracking and display logic |
| `NudgeBannerView` | SwiftUI View | **NEW** | Non-intrusive nudge banner for FriendListView |
| `engagementNudgeScheduler` | Cloud Function | **NEW** | Server-side scheduled nudge push notifications |
| `InviteService` | Service | **MODIFIED** | Persistent invite codes, richer invite data |
| `WeatherDetailSheet` | SwiftUI View | **MODIFIED** | Add share button for weather cards |
| `ProfileView` | SwiftUI View | **MODIFIED** | Always-visible invite share, streamlined flow |
| `FriendsTabView` | SwiftUI View | **MODIFIED** | Add invite button in toolbar, nudge banner |
| `AppUser` | Model | **MODIFIED** | Add `inviteCode` and `lastActiveAt` fields |
| `HotAndColdFriendsApp` | App Entry | **MODIFIED** | Inject new services, track lastActiveAt |
| `UserService` | Service | **MODIFIED** | Add `updateLastActive()` method |

### Environment Injection (follows existing pattern)

```swift
// In HotAndColdFriendsApp:
@State private var shareService = ShareService()
@State private var nudgeService = NudgeService()

var body: some Scene {
    WindowGroup {
        AppRouter()
            .environment(shareService)
            .environment(nudgeService)
            // ... all existing environments unchanged
    }
}
```

---

## Feature 1: Shareable Weather Cards

### Architecture Decision

Use SwiftUI `ImageRenderer` (available since iOS 16, stable API) for client-side image generation. No server-side rendering needed.

**Why client-side:**
- Zero latency (no network roundtrip)
- Full access to Bubble Pop design system (colors, typography, icons, gradients)
- No Cloud Functions cold start or Node.js canvas complexity
- No additional backend cost

**Confidence:** HIGH -- `ImageRenderer` is a stable, well-documented Apple API verified in official docs.

### Data Flow

```
User taps "Share" on WeatherDetailSheet
  --> WeatherCardRenderer receives FriendWeather data
  --> Creates WeatherCardView (off-screen SwiftUI view)
  --> ImageRenderer(@MainActor) renders view to UIImage at 3x scale
  --> ShareService presents ShareLink with rendered image
  --> User shares to Instagram/iMessage/WhatsApp etc.
```

### New Components

#### `WeatherCardView` -- Rendered to image, never displayed in app

```swift
struct WeatherCardView: View {
    let friendName: String
    let city: String
    let temperatureCelsius: Double
    let conditionSymbol: String
    let conditionDescription: String
    let format: CardFormat

    // Reuses existing DesignSystem:
    // - TemperatureZone(celsius:) for gradient background
    // - WeatherIconMapper.icon(for:size:) for condition icon
    // - BubblePopTypography (.bubbleH1, .bubbleH3, etc.)
    // - App logo watermark for brand awareness

    var body: some View {
        // Full-bleed temperature zone gradient background
        // Large temperature display
        // Weather icon + condition text
        // Friend name + city
        // Subtle "FriendsCast" watermark at bottom
    }
}

enum CardFormat {
    case story    // 9:16 aspect ratio (360x640pt, rendered at 3x = 1080x1920px)
    case square   // 1:1 aspect ratio (360x360pt, rendered at 3x = 1080x1080px)
}
```

**Card dimensions rationale:**
- Story (9:16): Instagram Stories, WhatsApp Status, Snapchat
- Square (1:1): Instagram feed, iMessage, general sharing
- Render at 3x scale for retina quality on all devices

#### `WeatherCardRenderer`

```swift
@MainActor
class WeatherCardRenderer {
    func renderCard(for friendWeather: FriendWeather, format: CardFormat) -> UIImage? {
        let celsius = friendWeather.temperatureCelsius ?? 0
        let view = WeatherCardView(
            friendName: friendWeather.friend.displayName,
            city: friendWeather.friend.city,
            temperatureCelsius: celsius,
            conditionSymbol: friendWeather.symbolName,
            conditionDescription: friendWeather.conditionDescription,
            format: format
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0  // Critical: default is 1.0, which looks fuzzy
        return renderer.uiImage
    }
}
```

**Critical constraint:** `ImageRenderer.scale` is isolated to `@MainActor`. All rendering must happen on main actor. This aligns perfectly with the existing `@MainActor` service pattern.

#### `ShareService`

```swift
@Observable
@MainActor
class ShareService {
    private let cardRenderer = WeatherCardRenderer()

    func weatherCardImage(for fw: FriendWeather, format: CardFormat) -> UIImage? {
        cardRenderer.renderCard(for: fw, format: format)
    }

    func inviteCardImage(displayName: String, city: String, inviteCode: String) -> UIImage? {
        let view = InviteCardView(
            displayName: displayName,
            city: city,
            inviteCode: inviteCode
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
```

### Integration Points

| Existing Component | Change Required | Details |
|--------------------|-----------------|---------|
| `WeatherDetailSheet` | Add share button | Toolbar trailing button or BubblePopButton below header. Renders card on tap, presents `ShareLink`. |
| `FriendRowView` | Add context menu | `.contextMenu { Button("Share weather") { ... } }` for quick sharing from list. |
| `DesignSystem/*` | No changes | WeatherCardView reuses all existing design tokens. |
| `Info.plist` | Add `LSApplicationQueriesSchemes` | Add `instagram-stories` for direct Instagram sharing. |

### Instagram Stories Deep Integration

```swift
func shareToInstagramStories(image: UIImage) {
    guard let url = URL(string: "instagram-stories://share"),
          UIApplication.shared.canOpenURL(url) else { return }

    let pasteboardItems: [[String: Any]] = [[
        "com.instagram.sharedSticker.backgroundImage": image.pngData()!
    ]]
    UIPasteboard.general.setItems(pasteboardItems)
    UIApplication.shared.open(url)
}
```

Requires `instagram-stories` in `LSApplicationQueriesSchemes` in Info.plist.

---

## Feature 2: Enhanced Invite Flow

### Current Problems

1. **Token is ephemeral** -- deleted after one use, user must regenerate each time
2. **Custom URL scheme only** -- `hotandcold://` requires app to be installed, no web fallback
3. **No visual preview** -- sharing a plain URL looks unappealing in iMessage/WhatsApp
4. **Invite buried in Profile** -- low discoverability, requires navigation to Profile tab

### Recommended Changes

#### A. Persistent Invite Code

Each user gets a permanent invite code stored on their `users/{uid}` document.

**Model change (AppUser):**
```swift
struct AppUser: Codable, Identifiable {
    // ... existing fields ...
    var inviteCode: String?       // NEW: permanent invite code
    var lastActiveAt: Timestamp?  // NEW: for nudge scheduling
}
```

**Modified InviteService:**
```swift
func getOrCreateInviteCode(for uid: String) async throws -> String {
    let user = try await userService.fetchUser(uid: uid)
    if let existing = user?.inviteCode {
        return existing
    }
    let code = String(UUID().uuidString.prefix(12)).lowercased()
    try await db.collection("users").document(uid).updateData(["inviteCode": code])

    // Also create/update the invite lookup document
    let invite = InviteDocument(
        senderUid: uid,
        senderDisplayName: user?.displayName ?? "",
        senderCity: user?.city ?? ""
    )
    try db.collection("invites").document(code).setData(from: invite)

    return code
}
```

**Invite redemption change:** Do NOT delete the invite doc after use. Add a `redemptionCount` field for analytics instead. The guard against duplicate friendships already exists in `redeemInvite()`.

**Firestore schema:**
```
invites/{code}
  senderUid: String
  senderDisplayName: String
  senderCity: String
  createdAt: Timestamp
  + redemptionCount: Number     // NEW: track viral spread
```

#### B. Universal Links (Replaces custom URL scheme for external sharing)

Firebase Dynamic Links was deprecated and sunset August 2025. Use Apple Universal Links directly.

**Setup required:**
1. Register a domain (e.g., `friendscast.app` or subdomain of `sandenskog.se`)
2. Host `apple-app-site-association` (AASA) file at `https://domain/.well-known/apple-app-site-association`
3. Add Associated Domains entitlement: `applinks:friendscast.app`

**AASA file content:**
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "A473BQKT8M.se.sandenskog.hotandcoldfriends",
      "paths": ["/invite/*"]
    }]
  }
}
```

**Modified URL handling:**
```swift
.onOpenURL { url in
    // Handle both custom scheme (existing) and universal links (new)
    let token: String?
    if url.scheme == "hotandcold", url.host == "invite" {
        token = url.pathComponents.dropFirst().first
    } else if url.host == "friendscast.app", url.pathComponents.contains("invite") {
        token = url.pathComponents.last
    } else {
        token = nil
    }

    if let token {
        Task {
            guard let uid = authManager.currentUser?.id else { return }
            try? await inviteService.redeemInvite(
                token: token, redeemerUid: uid,
                friendService: friendService, userService: userService
            )
        }
    }
    // ... existing friend deep link handling
}
```

**Web fallback:** The Universal Link domain should serve a simple landing page that redirects to the App Store when the app isn't installed. A static HTML page hosted on the Synology NAS or a simple Cloudflare Pages site works.

**Confidence:** MEDIUM -- Universal Links setup requires domain configuration and AASA hosting, which is well-documented but needs careful testing.

#### C. Visual Invite Card (InviteCardView)

```swift
struct InviteCardView: View {
    let displayName: String
    let city: String
    let inviteCode: String

    var body: some View {
        // Gradient background (bubblePrimary -> bubbleSecondary)
        // "Join me on FriendsCast!"
        // Sender avatar + name + city
        // Invite code or QR code
        // App Store badge
    }
}
```

Rendered via `ShareService.inviteCardImage()` and shared alongside the Universal Link URL.

#### D. Prominent Invite Placement

| Location | Implementation | When Shown |
|----------|---------------|------------|
| `FriendsTabView` toolbar | Toolbar button (person.badge.plus) | Always |
| `FriendListView` empty state | Replace current empty state with invite-focused CTA | When 0 real friends |
| Post-add celebration | Alert/sheet after successful invite redemption | After adding friend |
| `AddFriendSheet` | Add "Share your invite link" section above token input | Always |

---

## Feature 3: Engagement/Nudge System

### Architecture: Hybrid Client + Server

| Concern | Where | Why |
|---------|-------|-----|
| Push notification scheduling | Server (Cloud Function) | Runs when app is closed, accesses all users |
| In-app nudge display | Client (NudgeService) | Contextual, based on current view state |
| Nudge state tracking | Client (UserDefaults) + Server (Firestore) | Local for UI, server for push timing |

### Server-Side: New Cloud Function

**File:** `functions/src/engagementNudgeScheduler.ts`

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const engagementNudge = onSchedule(
  {
    schedule: "every day 09:00",
    region: "europe-west1",
    timeZone: "Europe/Stockholm",
  },
  async (_event) => {
    const db = getFirestore();
    const cutoff = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000); // 3 days ago

    // Query users inactive for 3+ days
    const usersSnap = await db.collection("users")
      .where("lastActiveAt", "<", cutoff)
      .get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      if (!fcmToken) continue;

      // Rate-limit: max 1 nudge per 3 days
      const lastNudge = userData.lastNudgeSentAt?.toDate();
      if (lastNudge && (Date.now() - lastNudge.getTime()) < 3 * 24 * 60 * 60 * 1000) continue;

      // Fetch a friend's weather for personalization
      const friendsSnap = await userDoc.ref.collection("friends")
        .where("isDemo", "==", false)
        .limit(1)
        .get();

      const friendName = friendsSnap.docs[0]?.data()?.displayName ?? "your friends";

      // Send personalized nudge
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "What's the weather like?",
          body: `See what it's like at ${friendName}'s place!`,
        },
        apns: { payload: { aps: { sound: "default" } } },
      });

      await userDoc.ref.update({ lastNudgeSentAt: FieldValue.serverTimestamp() });
    }
  }
);
```

**Export from index.ts:**
```typescript
export { engagementNudge } from "./engagementNudgeScheduler";
```

**Firestore index needed:** Composite index on `users` collection: `lastActiveAt ASC`.

### Client-Side: NudgeService

```swift
@Observable
@MainActor
class NudgeService {
    private let defaults = UserDefaults.standard

    enum NudgeType: String, CaseIterable {
        case inviteFriends       // < 3 friends
        case shareWeatherCard    // Viewed weather detail 3+ times without sharing
        case enableNotifications // Notifications not granted
    }

    func activeNudge(friendCount: Int, hasNotifications: Bool) -> NudgeType? {
        if !hasNotifications && !isDismissed(.enableNotifications) {
            return .enableNotifications
        }
        if friendCount < 3 && !isDismissed(.inviteFriends) {
            return .inviteFriends
        }
        if weatherDetailViewCount >= 3 && !isDismissed(.shareWeatherCard) {
            return .shareWeatherCard
        }
        return nil
    }

    func dismiss(_ nudge: NudgeType) {
        defaults.set(true, forKey: "nudge_dismissed_\(nudge.rawValue)")
    }

    private func isDismissed(_ nudge: NudgeType) -> Bool {
        defaults.bool(forKey: "nudge_dismissed_\(nudge.rawValue)")
    }

    var weatherDetailViewCount: Int {
        get { defaults.integer(forKey: "weather_detail_view_count") }
        set { defaults.set(newValue, forKey: "weather_detail_view_count") }
    }
}
```

### NudgeBannerView (displayed in FriendsTabView)

```swift
struct NudgeBannerView: View {
    let nudge: NudgeService.NudgeType
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            // Icon + message based on nudge type
            // Action button (BubblePopButton style)
            // Dismiss "X" button
        }
        .padding(Spacing.md)
        .background(Color.bubblePrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}
```

### lastActiveAt Tracking

**UserService addition:**
```swift
func updateLastActive(uid: String) async throws {
    try await db.collection("users").document(uid).updateData([
        "lastActiveAt": FieldValue.serverTimestamp()
    ])
}
```

**Integration in HotAndColdFriendsApp:**
```swift
.task {
    delegate.registerForPushNotifications()
    if let uid = authManager.currentUser?.id {
        // NEW: Track app open for nudge scheduling
        try? await userService.updateLastActive(uid: uid)

        // Existing: check weather alerts
        let friends = (try? await friendService.fetchFriends(uid: uid)) ?? []
        await weatherAlertService.checkAlertsForFriends(uid: uid, friends: allFriends)
    }
}
```

---

## Patterns to Follow

### Pattern 1: Service Injection via Environment (existing pattern)

All new services (`ShareService`, `NudgeService`) follow the `@Observable @MainActor` pattern and are injected via `.environment()`. This is the established pattern in the codebase -- no new DI mechanism needed.

### Pattern 2: ImageRenderer for All Shareable Content

Use a single `ShareService` that owns the rendering logic for both weather cards and invite cards. Centralizes scale/quality settings and prevents scattered ImageRenderer instances.

### Pattern 3: Cloud Function per Concern (existing pattern)

The new `engagementNudgeScheduler.ts` follows the same structure as existing functions: one file, one export, independent scaling. Exported from `index.ts`.

### Pattern 4: Rate-Limiting via Firestore Timestamps (existing pattern)

Both the weather alert system and the new nudge system use Firestore timestamp fields (`lastAlertSentAt`, `lastNudgeSentAt`) for rate-limiting. Consistent, simple, no additional infrastructure.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Server-Side Image Rendering

**What:** Rendering weather card images on the server (Cloud Functions).
**Why bad:** Cold starts add latency, image rendering in Node.js requires canvas/sharp, increases cost and complexity.
**Instead:** Client-side `ImageRenderer` -- instant, uses full SwiftUI stack, zero server changes.

### Anti-Pattern 2: Firebase Dynamic Links

**What:** Using Firebase Dynamic Links for invite URLs.
**Why bad:** Deprecated and sunset August 2025. No longer available.
**Instead:** Apple Universal Links with AASA file on app domain.

### Anti-Pattern 3: Aggressive Push Notifications

**What:** Sending frequent nudge notifications (daily or more).
**Why bad:** Users disable notifications or uninstall. iOS throttles excessive notifications. Social weather app should feel warm, not spammy.
**Instead:** Max 1 nudge per 3 days. Only when genuinely relevant. Always respect user preferences.

### Anti-Pattern 4: Ephemeral Invite Tokens

**What:** Deleting invite tokens after single use (current behavior).
**Why bad:** Forces users to regenerate links each time. Breaks sharing flow -- user shares a link, second friend tries it, it's already used.
**Instead:** Persistent invite codes per user. Track redemptions for analytics, but never delete the lookup document.

---

## Firestore Schema Changes Summary

```
users/{uid}
  + inviteCode: String              // Permanent invite code
  + lastActiveAt: Timestamp         // Updated on each app open
  + lastNudgeSentAt: Timestamp      // Rate-limiting for push nudges

invites/{code}                      // NO LONGER DELETED on redemption
  senderUid: String
  senderDisplayName: String
  senderCity: String
  createdAt: Timestamp
  + redemptionCount: Number         // Track viral spread

// New composite index:
// users: lastActiveAt ASC (for nudge scheduler query)
```

---

## Build Order (Dependency-Based)

### Phase 1: Shareable Weather Cards (self-contained, no backend changes)
1. `WeatherCardView` -- SwiftUI view for rendering
2. `WeatherCardRenderer` -- ImageRenderer wrapper
3. `ShareService` -- sharing coordination, environment injection
4. Integration: share button in `WeatherDetailSheet`
5. Integration: context menu on `FriendRowView`
6. Instagram Stories support (Info.plist + URL scheme)

### Phase 2: Enhanced Invite Flow (Firestore schema change + potential domain setup)
1. Add `inviteCode` field to `AppUser` model
2. Modify `InviteService` for persistent codes (stop deleting on redemption)
3. `InviteCardView` -- visual invite card for sharing
4. Move invite CTA to toolbar + empty state + post-add celebration
5. Universal Links setup (AASA file, entitlements, web fallback page)

### Phase 3: Engagement/Nudge System (depends on Phase 2 for invite nudges)
1. Add `lastActiveAt` tracking to `UserService` + app entry point
2. `NudgeService` -- client-side nudge display logic
3. `NudgeBannerView` -- in-app nudge banner in FriendsTabView
4. `engagementNudgeScheduler` Cloud Function
5. Export from `index.ts`, deploy, create Firestore index

**Phase ordering rationale:**
- Phase 1 is entirely client-side with no backend changes or schema migrations
- Phase 2 requires Firestore schema changes that Phase 3 depends on (`lastActiveAt`, `inviteCode`)
- Phase 3 nudges reference invite functionality (e.g., "Invite more friends" nudge)

---

## Sources

- [ImageRenderer | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) -- HIGH confidence
- [ImageRenderer.scale | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer/scale) -- HIGH confidence
- [Hacking with Swift: SwiftUI ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) -- HIGH confidence
- [AppCoda: ImageRenderer in SwiftUI](https://www.appcoda.com/imagerenderer-swiftui/) -- MEDIUM confidence
- [Swift with Majid: ImageRenderer](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/) -- MEDIUM confidence
- [Firebase: Schedule Functions](https://firebase.google.com/docs/functions/schedule-functions) -- HIGH confidence
- [Firebase: Cloud Messaging iOS](https://firebase.google.com/docs/cloud-messaging/ios/get-started) -- HIGH confidence
- [Hacking with Swift: ShareLink](https://www.hackingwithswift.com/books/ios-swiftui/how-to-let-the-user-share-content-with-sharelink) -- HIGH confidence
- [SwiftUI Lab: Renderers and Their Tricks](https://swiftui-lab.com/swiftui-renders/) -- MEDIUM confidence
