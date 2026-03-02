# Stack Research

**Domain:** Social weather iOS app (native SwiftUI, managed backend)
**Researched:** 2026-03-02
**Confidence:** MEDIUM-HIGH (core stack HIGH, social API constraints MEDIUM)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.x (Xcode 16+) | Primary language | Apple-native, mandatory for App Store, strict concurrency in Swift 6 eliminates data races |
| SwiftUI | iOS 15+ | UI framework | Modern declarative UI, required for any new iOS social app, @Observable macro simplifies state |
| Firebase iOS SDK | 12.10.0 (Feb 2026) | Backend-as-a-Service | Auth + Firestore + FCM in one SDK, best real-time chat performance for social apps, mature iOS integration |
| Xcode | 16.2+ | IDE | Required. SPM support for Firebase requires Xcode 16.2+ |

**Why Firebase over Supabase for this project:**
Firebase wins for real-time chat (600ms RTT on Realtime DB vs 1500ms on Firestore), push notifications via FCM, and social auth (Google, Facebook, Apple) all in one SDK. The NoSQL data model suits message streams naturally. Supabase's SQL strengths (joins, RLS) are less relevant here — friend relationships and chat messages are the primary data structures, not complex relational queries. For an MVP social app prioritizing speed to market and real-time feel, Firebase is the correct choice.

---

### Backend Services (Firebase)

| Service | Purpose | Why |
|---------|---------|-----|
| Firebase Authentication | Social login (Apple, Google, Facebook) | Handles OAuth token exchange, session management, App Store compliance — all in one |
| Cloud Firestore | User profiles, friend lists, app state | Flexible document model, offline sync, real-time listeners. Use for profile data and friend graph |
| Firebase Realtime Database | Chat messages | Lower latency than Firestore (600ms vs 1500ms RTT), better suited for message stream updates |
| Firebase Cloud Messaging (FCM) | Push notifications | Official APNs bridge, handles delivery receipts, topic subscriptions for weather alerts |
| Firebase Remote Config | Feature flags, example data at first run | Control first-run demo data without app releases |

**Note on Firestore vs Realtime Database split:** Use Firestore for user/friend data (richer queries, offline support), Realtime Database for chat (lower latency). Both can coexist in one Firebase project.

---

### Weather API

| Service | Tier | Calls | Why Recommended |
|---------|------|-------|-----------------|
| Apple WeatherKit | Included in Apple Developer membership ($99/yr) | 500,000/month free | Native Swift SDK, no API key management, privacy-first (no user tracking), required attribution only. Best fit for iOS-first app. Upgrade plans from $49.99/month for 1M calls |

**Why WeatherKit over alternatives:**
- Included with Apple Developer membership you already need for App Store distribution
- 500K free calls/month is sufficient for early-stage social app
- Native Swift async/await integration — no third-party SDK needed
- Privacy-preserving (location not tracked between requests) — relevant for App Store review
- Attribution required: must display "Weather" Apple trademark in UI

**WeatherKit minimum iOS requirement:** iOS 16. This sets the deployment target for the entire app.

**Fallback option (if WeatherKit quota insufficient):** WeatherAPI.com — 1 million calls/month free, $9.99/month paid. REST-based JSON. Good global coverage. Keep as a backup for heavy load.

**Open-Meteo is NOT recommended** for this use case despite being free — no commercial use allowed, requires attribution, and lacks the precipitation/hourly granularity needed for a polished social weather card.

---

### Social Login

| Provider | SDK | Scope available |
|----------|-----|-----------------|
| Sign in with Apple | AuthenticationServices (Apple native) | name, email. MANDATORY: Apple requires this when any third-party login is offered |
| Google Sign-In | Firebase Auth (built-in) | profile, email |
| Facebook Login | Facebook iOS SDK (facebook/facebook-ios-sdk) | public_profile, email, user_friends (restricted — see critical note) |

**Critical: Facebook friend_list limitation.** `user_friends` permission only returns friends who have ALSO installed your app AND granted the same permission. It does NOT return the user's full Facebook friends list. This is a hard platform constraint since Graph API v2.0 (2014) and is not changing. This fundamentally affects the friend-import feature design.

**Snapchat Login Kit:** Available scopes are limited to `user.display_name`, `user.external_id`, `user.bitmoji.avatar`. No friend list access available. Snapchat cannot be used for friend import — only for login identity.

**Instagram:** The Basic Display API (personal account read access) reached end-of-life December 4, 2024. All remaining APIs target business accounts only. Instagram friend/follower import for a consumer app is not possible through official APIs as of 2026.

**Implication for "friend import" feature:** The social import model must shift from bulk friend-list import to an in-app friend discovery model (invite via contact/phone number, find by username, or share a join link). Facebook can surface mutual app users over time, not upfront bulk import. This is a significant architectural constraint the roadmap must address.

---

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FacebookSDKLoginKit | 17.x (via SPM) | Facebook OAuth login + user_friends discovery | Always — needed for Facebook auth |
| GoogleSignIn-iOS | 8.x (via SPM) | Google OAuth | Always — cleaner than Firebase Auth's built-in Google flow |
| AuthenticationServices | iOS 13+ (Apple native) | Sign in with Apple | Always — mandatory for App Store |
| UserNotifications | iOS 10+ (Apple native) | Local + push notification permission management | Always |

**Note:** No third-party chat UI framework needed. Build chat UI in SwiftUI directly — Firebase's real-time listeners plus SwiftUI state management give you everything required without adding a dependency like Stream or Sendbird.

---

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 16.2+ | IDE + Swift Package Manager | Minimum required for Firebase 12.x SPM |
| Swift Package Manager | Dependency management | Use instead of CocoaPods or Carthage. Firebase fully supports SPM. Snapchat Snap Kit may require CocoaPods — check before planning |
| Firebase Emulator Suite | Local development | Emulate Auth, Firestore, Realtime DB, and FCM locally. Essential for testing without hitting production quotas |
| Fastlane | iOS build automation | Code signing, TestFlight uploads, App Store submission automation |
| TestFlight | Beta distribution | Standard Apple beta channel, required before App Store submission |

---

## Installation

```bash
# In Xcode: File > Add Package Dependencies
# Core Firebase (select modules needed):
https://github.com/firebase/firebase-ios-sdk
# Select: FirebaseAuth, FirebaseFirestore, FirebaseDatabase,
#          FirebaseMessaging, FirebaseRemoteConfig

# Facebook SDK:
https://github.com/facebook/facebook-ios-sdk
# Select: FacebookLogin

# Google Sign-In:
https://github.com/google/GoogleSignIn-iOS
# Select: GoogleSignIn

# WeatherKit: built into Apple frameworks — no package needed
# AuthenticationServices: built into Apple frameworks — no package needed
```

---

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|-------------------------|
| Backend | Firebase | Supabase | If you need complex relational queries, SQL familiarity, or want to avoid Google lock-in. Not better for real-time chat or this project's specific needs |
| Weather API | WeatherKit | WeatherAPI.com | If app needs to support iOS 15 (WeatherKit requires iOS 16), or if call volume exceeds 500K/month before upgrading |
| Weather API | WeatherKit | OpenWeatherMap | If you need enterprise SLA, detailed air quality data. OpenWeatherMap 3.0 paid plan from $40/month. Free tier is 1000 calls/day only |
| Architecture | MVVM + @Observable | TCA (The Composable Architecture) | If team grows large and needs enforced unidirectional state management. TCA adds boilerplate overhead not justified for a solo/small team iOS project |
| Chat UI | Custom SwiftUI | Stream Chat SDK / Sendbird | If chat becomes a primary product focus with threads, reactions, moderation. Not needed for v1 |
| Auth | Firebase Auth | Auth0 | If you need enterprise SSO, custom identity providers, or fine-grained permissions. Unnecessary complexity for a consumer social app |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CocoaPods | Deprecated dependency manager, slow builds, poor Xcode 16 support. Firebase officially recommends SPM | Swift Package Manager |
| Supabase for chat | Supabase Realtime uses PostgreSQL replication + websockets — higher latency (no hard number but architecturally slower than Firebase Realtime DB for message streams). Also lacks FCM integration | Firebase Realtime Database for messages |
| Instagram API for friend import | Instagram Basic Display API reached end-of-life December 4, 2024. No personal account APIs exist | Phone number / contact matching via user invitation instead |
| Snapchat for friend import | Login Kit scopes don't include friends list. Snap Kit is login-only | Snapchat login for identity only, not social graph |
| UIKit | Adds complexity, requires bridging to SwiftUI. SwiftUI is mature enough for all required UI patterns as of iOS 16 | SwiftUI throughout |
| Third-party chat framework (Stream, Sendbird) | ~$400-1000/month at scale, overkill for v1 chat. Firebase already handles real-time messaging | Firebase Realtime Database + custom SwiftUI chat view |
| OpenWeatherMap free tier for production | Only 1000 calls/day free. A social app with 50 users checking weather for 20 friends each = 1000 calls/day immediately | WeatherKit (500K/month free with dev membership) |

---

## Stack Patterns by Variant

**If deployment target is iOS 15 (maximum reach):**
- Cannot use WeatherKit (requires iOS 16)
- Use WeatherAPI.com instead (REST, 1M calls/month free)
- Lose native Swift weather integration but maintain broad compatibility

**If deployment target is iOS 16+ (recommended):**
- Use WeatherKit natively
- Access to newer SwiftUI features (NavigationStack, etc.)
- ~90%+ of active iPhones run iOS 16+ as of 2025

**If chat needs to scale beyond MVP:**
- Migrate chat from Firebase Realtime Database to a dedicated solution (Stream Chat, Sendbird) only at that point
- Firebase Realtime Database handles tens of thousands of concurrent users without issues

**If friend import is needed before network effects kick in:**
- Implement phone number/contact matching as the primary friend discovery
- Use Apple's CNContactStore framework for contacts access
- Users manually enter city/country for friends who haven't joined yet (matches PROJECT.md onboarding model)

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Firebase iOS SDK 12.x | iOS 15.0+ | Breaking change from 11.x (was iOS 13+). Confirmed from official release notes |
| WeatherKit | iOS 16.0+ | Apple native. Sets minimum deployment target |
| facebook-ios-sdk 17.x | iOS 16+ | Verify before locking — check Facebook developer portal |
| GoogleSignIn-iOS 8.x | iOS 13+ | Broad compatibility |
| Swift 6 | Xcode 16+ | Required for strict concurrency. Firebase 12.x is Swift 6 compatible |

**Recommended deployment target: iOS 16** — covers WeatherKit, Firebase 12.x, modern SwiftUI, and ~90%+ of active devices.

---

## Sources

- Firebase iOS SDK release notes (official, HIGH confidence): https://firebase.google.com/support/release-notes/ios — Version 12.10.0 confirmed Feb 25, 2026, iOS 15 minimum
- Firebase/firebase-ios-sdk GitHub releases (HIGH confidence): Latest version 12.10.0
- Apple WeatherKit documentation (official, HIGH confidence): https://developer.apple.com/weatherkit/ — 500K calls/month free, iOS 16 minimum, attribution required
- Facebook Graph API user_friends limitation (MEDIUM confidence, multiple corroborating sources): Only returns mutual app users since Graph API v2.0
- Snapchat Login Kit scopes (official docs, HIGH confidence): https://developers.snap.com/snap-kit/login-kit/overview — No friends list scope available
- Instagram Basic Display API end-of-life (official, HIGH confidence): EOL December 4, 2024
- Firebase vs Supabase real-time comparison (MEDIUM confidence, multiple sources agree): Firebase Realtime DB ~600ms RTT vs Firestore ~1500ms
- SwiftUI @Observable macro (Apple official docs, HIGH confidence): https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro
- Apple Sign in with Apple requirement (MEDIUM confidence): Required when any third-party login offered, as of App Store guidelines
- Open-Meteo non-commercial restriction (HIGH confidence): https://open-meteo.com — Free for non-commercial only

---

## Critical Constraint Summary

The biggest unresolved risk is the social friend import model. The planned "import from Facebook/Instagram/Snapchat" feature as described in PROJECT.md is not achievable through official APIs:

1. Facebook: Returns only mutual app users, not full friend list
2. Instagram: No consumer API exists post-December 2024
3. Snapchat: No friend list scope in Login Kit

The roadmap must plan for an alternative friend discovery strategy. The most viable approach is phone contact matching (users grant contacts permission, backend hashes phone numbers and matches against registered users) or a manual "add by username/invite link" flow. This is a design decision that affects the entire onboarding phase.

---

*Stack research for: Hot & Cold Friends — social weather iOS app*
*Researched: 2026-03-02*
