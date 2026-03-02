# Architecture Research

**Domain:** Social weather iOS app with real-time chat, friend import, and AI-driven location inference
**Researched:** 2026-03-02
**Confidence:** MEDIUM

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        iOS CLIENT (SwiftUI)                          │
├──────────────┬────────────────┬──────────────┬───────────────────────┤
│  Views       │  ViewModels    │  Services    │  Models               │
│  ─────────── │  ──────────    │  ─────────── │  ──────────────────── │
│  FriendList  │  FriendVM      │  WeatherSvc  │  Friend               │
│  MapView     │  MapVM         │  ChatSvc     │  Message              │
│  ChatView    │  ChatVM        │  AuthSvc     │  WeatherData          │
│  OnboardingV │  OnboardingVM  │  FriendSvc   │  ChatConversation     │
│  WeatherCard │  WeatherCardVM │  LocationSvc │  UserProfile          │
└──────────────┴────────────────┴──────────────┴───────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌────────────────┐ ┌──────────────┐ ┌───────────────────────┐
│   Firebase     │ │  Weather API │ │  AI Location Service  │
│  ─────────────  │ │  ──────────  │ │  ─────────────────── │
│  Auth          │ │  OpenWeather │ │  OpenAI API           │
│  Firestore     │ │  / WeatherAPI│ │  (location inference  │
│  FCM (push)    │ │              │ │   from profile data)  │
└────────────────┘ └──────────────┘ └───────────────────────┘
         │
┌────────────────────────────────────┐
│     Social Import Adapters         │
│  Facebook Graph API  (limited)     │
│  Instagram Basic Display (limited) │
│  Manual contact import fallback    │
└────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Views | Render UI, handle user gestures, pass intents to ViewModel | SwiftUI structs, no business logic |
| ViewModels | Orchestrate data, hold state, call Services | @Observable class, async/await methods |
| Services | Communicate with external APIs and Firebase | Protocol-based, injectable, testable |
| Models | Plain value types representing domain entities | Swift structs conforming to Codable |
| Firebase Auth | Social login, session management | FirebaseAuth SDK, Firebase UI |
| Firestore | Friends list, user profiles, chat messages | Collections + subcollections |
| FCM | Push notifications for chat and weather alerts | APNs-backed, token stored in Firestore |
| Weather Service | Fetch current weather for friend locations | URLSession + async/await, 30-min cache |
| AI Location Service | Infer city/country from profile data at import | OpenAI API via secure backend proxy |
| MapKit | Display friends on a map with weather-annotated pins | Native MapKit, Marker annotations |

## Recommended Project Structure

```
WeatherFriends/
├── App/
│   ├── WeatherFriendsApp.swift   # App entry point, DI container setup
│   └── AppDelegate.swift         # FCM token handling, APNs registration
│
├── Features/                     # Feature modules (one folder per screen flow)
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   └── FavoritePickerView.swift
│   ├── FriendList/
│   │   ├── FriendListView.swift
│   │   ├── FriendListViewModel.swift
│   │   └── WeatherCardView.swift
│   ├── Map/
│   │   ├── FriendMapView.swift
│   │   └── FriendMapViewModel.swift
│   ├── Chat/
│   │   ├── ConversationListView.swift
│   │   ├── ChatView.swift
│   │   └── ChatViewModel.swift
│   ├── FriendImport/
│   │   ├── ImportSourceView.swift
│   │   ├── ImportViewModel.swift
│   │   └── LocationInferenceService.swift
│   └── Auth/
│       ├── LoginView.swift
│       └── AuthViewModel.swift
│
├── Services/                     # Shared services (injected via Environment)
│   ├── WeatherService.swift      # Wraps weather API, caches responses
│   ├── FriendService.swift       # Firestore CRUD for friends
│   ├── ChatService.swift         # Firestore real-time listener for messages
│   ├── AuthService.swift         # Firebase Auth wrapper
│   ├── NotificationService.swift # FCM token, notification scheduling
│   └── AILocationService.swift   # Calls backend proxy → OpenAI
│
├── Models/                       # Pure data types, no logic
│   ├── Friend.swift
│   ├── WeatherData.swift
│   ├── Message.swift
│   ├── Conversation.swift
│   └── UserProfile.swift
│
├── Core/                         # Shared utilities and extensions
│   ├── NetworkClient.swift       # URLSession wrapper (async/await)
│   ├── Cache.swift               # Simple TTL cache for weather data
│   ├── DependencyContainer.swift # Service locator / DI
│   └── Extensions/
│
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### Structure Rationale

- **Features/**: Feature-first organization means each screen flow is self-contained. A developer working on Chat never needs to touch FriendList files.
- **Services/**: Shared services are protocol-based so ViewModels depend on abstractions, enabling unit testing with mock implementations.
- **Models/**: Plain structs kept outside features so any ViewModel can reference them without circular imports.
- **Core/**: Cross-cutting infrastructure (networking, caching, DI) lives here, not inside any feature.

## Architectural Patterns

### Pattern 1: MVVM with @Observable (iOS 17+)

**What:** Each SwiftUI View gets a dedicated ViewModel marked `@Observable`. Views observe only the properties they access — no wasted re-renders.
**When to use:** All screens. This is the standard SwiftUI architecture as of iOS 17.
**Trade-offs:** Requires iOS 17+ minimum target. Simpler and more performant than the legacy `ObservableObject` / `@Published` approach.

**Example:**
```swift
@Observable
final class FriendListViewModel {
    var friends: [Friend] = []
    var isLoading = false
    private let friendService: FriendServiceProtocol
    private let weatherService: WeatherServiceProtocol

    init(friendService: FriendServiceProtocol, weatherService: WeatherServiceProtocol) {
        self.friendService = friendService
        self.weatherService = weatherService
    }

    func loadFriends() async {
        isLoading = true
        defer { isLoading = false }
        friends = await friendService.fetchFriends()
        // Weather is fetched lazily per card to avoid N+1 API calls at startup
    }
}

struct FriendListView: View {
    @State private var viewModel = FriendListViewModel(
        friendService: DependencyContainer.shared.friendService,
        weatherService: DependencyContainer.shared.weatherService
    )

    var body: some View {
        List(viewModel.friends) { friend in
            WeatherCardView(friend: friend)
        }
        .task { await viewModel.loadFriends() }
    }
}
```

### Pattern 2: Protocol-Based Services with Dependency Injection

**What:** All external dependencies (Firebase, weather API, OpenAI) are hidden behind Swift protocols. ViewModels receive dependencies via init. A `DependencyContainer` singleton wires everything together at startup.
**When to use:** Every service. This is non-negotiable for testability and for replacing real services with mocks during testing or the first-run demo state.
**Trade-offs:** Slight boilerplate for defining protocols, but required for writing unit tests and for swapping live/demo data providers.

**Example:**
```swift
protocol WeatherServiceProtocol {
    func weather(for location: String) async throws -> WeatherData
}

// Live implementation
final class WeatherService: WeatherServiceProtocol {
    private let cache = Cache<String, WeatherData>(ttl: 1800) // 30 min
    func weather(for location: String) async throws -> WeatherData {
        if let cached = cache[location] { return cached }
        let data = try await networkClient.fetch(WeatherEndpoint(location: location))
        cache[location] = data
        return data
    }
}

// Demo implementation (used at first-run before user has friends)
final class DemoWeatherService: WeatherServiceProtocol {
    func weather(for location: String) async throws -> WeatherData {
        return WeatherData.demoData(for: location)
    }
}
```

### Pattern 3: Firestore Real-Time Listeners in ChatService

**What:** The ChatService attaches a Firestore `addSnapshotListener` to the active conversation's messages subcollection. New messages arrive in real time without polling.
**When to use:** Chat screen only. Do not use real-time listeners everywhere — each listener costs a Firestore read and keeps a websocket open.
**Trade-offs:** Must detach listeners when views disappear (onDisappear / task cancellation) to avoid memory leaks and unnecessary billing.

**Example:**
```swift
final class ChatService: ChatServiceProtocol {
    private var listener: ListenerRegistration?

    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping ([Message]) -> Void
    ) {
        listener = Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap {
                    try? $0.data(as: Message.self)
                } ?? []
                onUpdate(messages)
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
```

## Data Flow

### Request Flow: Loading Friend Weather Data

```
User opens FriendListView
    ↓
FriendListView.task { await viewModel.loadFriends() }
    ↓
FriendListViewModel → FriendService.fetchFriends()
    ↓
FriendService → Firestore: users/{uid}/friends collection
    ↓
Return [Friend] with city/country fields
    ↓
FriendListViewModel.friends = [Friend]  (View re-renders)
    ↓
Each WeatherCardView appears → WeatherCardViewModel.loadWeather()
    ↓
WeatherService: check TTL cache → hit? return cached : fetch from API
    ↓
WeatherData returned → WeatherCardView shows temperature, icon, conditions
```

### Request Flow: Sending a Chat Message

```
User types message and taps Send
    ↓
ChatView calls viewModel.send(text:)
    ↓
ChatViewModel → ChatService.send(message:toConversation:)
    ↓
ChatService: write to Firestore conversations/{id}/messages (new document)
    ↓
Firestore snapshot listener (already attached) fires
    ↓
ChatService calls onUpdate([Message]) callback
    ↓
ChatViewModel.messages updated → ChatView re-renders with new message
    ↓
FCM triggers push notification to recipient via Cloud Function
```

### Request Flow: AI Location Inference at Import

```
User initiates import from social platform
    ↓
ImportViewModel receives contact list (names, bios, phone prefixes, etc.)
    ↓
ImportViewModel → AILocationService.inferLocations(contacts:)
    ↓
AILocationService: batch contacts → POST to secure backend proxy
    ↓
Backend proxy → OpenAI Chat Completions API
    ↓
Response: [{name, inferredCity, inferredCountry, confidence}]
    ↓
ImportViewModel presents results for user confirmation
    ↓
User confirms/adjusts locations → FriendService.saveFriends(friends:)
    ↓
Friends saved to Firestore with city/country set
```

### State Management

```
DependencyContainer (singleton, created at app launch)
    │ provides services to...
    ▼
ViewModels (@Observable, owned by Views via @State)
    │ update published properties →
    ▼
SwiftUI Views (re-render only accessed properties — iOS 17 precision tracking)
    │ user actions →
    ▼
async methods on ViewModel → Service calls → Firestore / APIs
```

### Key Data Flows Summary

1. **Weather data:** Pulled lazily per friend card, cached 30 minutes with in-memory TTL cache. No background refresh on list mount — avoids N+1 API calls.
2. **Chat messages:** Pushed in real time via Firestore snapshot listener. Listener attached on ChatView appear, detached on disappear.
3. **Friend list:** Fetched once on app open from Firestore, cached in ViewModel. Refreshed on pull-to-refresh.
4. **Push notifications:** FCM token stored in users/{uid} document. Cloud Function sends FCM message when new Firestore message is written.
5. **First-run demo state:** DemoWeatherService + DemoFriendService inject static live-looking data until user completes onboarding. Swapped for live services after onboarding completes.

## Firestore Data Model

```
users/{uid}
  ├── displayName, email, photoURL, fcmToken
  ├── friends/{friendId}
  │     ├── name, photoURL
  │     ├── city, country (set during import or manually)
  │     └── locationConfidence: "ai" | "manual" | "unknown"
  └── conversations/{conversationId}    ← reference only, not messages
        └── (lightweight: lastMessage, unreadCount, partnerId)

conversations/{conversationId}
  ├── participantIds: [uid1, uid2]
  ├── lastMessage, lastMessageAt
  └── messages/{messageId}
        ├── senderId, text, timestamp
        └── (no read receipts in v1)
```

**Conversation ID convention:** Concatenate two sorted UIDs: `min(uid1, uid2) + "_" + max(uid1, uid2)`. Deterministic — starting a conversation never creates duplicates.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Firebase Auth | SDK + FirebaseUI for social login flows | Handles Google, Facebook, Apple Sign In |
| Firestore | SDK with snapshot listeners for chat; one-time fetch for friends | Enable offline persistence for resilience |
| Firebase Cloud Messaging | SDK + APNs token upload; Cloud Functions trigger sends | Requires p8 key uploaded to Firebase console |
| Weather API (OpenWeather or WeatherAPI.com) | URLSession + async/await, TTL cache | Cache 30 min; global coverage required |
| OpenAI API | Called via secure backend proxy, NOT directly from app | Exposing API key in iOS app violates OpenAI ToS |
| MapKit | Native SwiftUI Map view with custom Marker annotations | No external dependency needed |
| Apple Sign In | ASAuthorizationController (required if Facebook/Google offered) | Apple policy: must offer if other social logins exist |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| View → ViewModel | Direct method calls + @Observable binding | Views never talk to Services directly |
| ViewModel → Service | Protocol methods, async/await | Services are injected, not instantiated in VM |
| Service → Firebase | Firebase SDK | Firestore, Auth, FCM all use official iOS SDK |
| Service → Weather API | URLSession (no third-party HTTP lib needed) | Keep it native for reduced dependency surface |
| ChatService → FCM | Via Cloud Function (server-side trigger) | Client never sends FCM messages directly |

## Build Order Implications

Based on component dependencies, build in this order:

1. **Auth + User Profile** — everything else requires a logged-in user. Firebase Auth with Apple Sign In is the foundation.
2. **Firestore data layer + Friend model** — the friend list with city/country is required before weather can be displayed.
3. **Weather Service + Friend List View** — first meaningful screen. Validates weather API choice and card design.
4. **Onboarding + Demo Data** — first-run experience with 6 favorites. DemoWeatherService lets this be built without real friends.
5. **Map View** — depends on friends-with-locations being in place. MapKit annotations are straightforward once data exists.
6. **Chat (Firestore listeners + UI)** — real-time architecture is the most complex feature. Build after core list is stable.
7. **Push Notifications (FCM + Cloud Functions)** — depends on chat being functional. Cloud Functions required server-side.
8. **AI Location Import** — depends on auth, friend model, and backend proxy. OpenAI integration adds external dependency risk.
9. **Social Platform Import** — highest API uncertainty (Facebook/Instagram restrictions). Build last when core value is proven.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Current architecture is fine. Single Firestore project, no sharding. |
| 1k-10k users | Add Firestore security rules audit. Weather API costs increase — verify caching is effective. FCM at this scale is still free tier. |
| 10k-100k users | Weather API costs become significant — consider a thin backend that caches weather responses server-side. Firestore pricing predictable with well-structured data model. |
| 100k+ users | Backend weather cache becomes mandatory. Consider moving AI location inference to async queue rather than on-demand. Firestore at this scale is proven (used by major apps). |

### Scaling Priorities

1. **First bottleneck:** Weather API rate limits and cost. Each friend card fetches separately. Shared server-side cache (even a simple Cloud Function) eliminates redundant calls for popular cities.
2. **Second bottleneck:** Firestore reads for friend lists. Denormalizing weather into friend documents (refreshed by a scheduled Cloud Function) would eliminate per-card weather fetches entirely.

## Anti-Patterns

### Anti-Pattern 1: Fetching Weather for All Friends on List Load

**What people do:** On `FriendListView` appear, call weather API for every friend simultaneously.
**Why it's wrong:** 20 friends = 20 parallel API calls at startup. Hits rate limits, wastes quota, slows perceived load time.
**Do this instead:** Fetch weather lazily as each `WeatherCardView` appears on screen (`.task` modifier on card). Or prefetch only the 6 favorites first, others on scroll.

### Anti-Pattern 2: Firestore Snapshot Listeners on Every View

**What people do:** Attach real-time listeners to friend lists, weather data, and chat all at once.
**Why it's wrong:** Each listener keeps a websocket connection open and triggers a read on every write. Costs money and drains battery.
**Do this instead:** Use real-time listeners only for chat (where instant updates matter). Friends and weather use one-time fetch + manual refresh.

### Anti-Pattern 3: Calling OpenAI Directly from the iOS App

**What people do:** Put the OpenAI API key in the app bundle or Keychain, call the API directly from Swift.
**Why it's wrong:** API key can be extracted from the IPA. OpenAI explicitly forbids this in their ToS. Exposes billing to abuse.
**Do this instead:** Route AI calls through a thin backend proxy (Firebase Cloud Function or a Supabase Edge Function). The iOS app sends a Firebase-authenticated request; the backend holds the API key.

### Anti-Pattern 4: Storing Messages as Array Fields in Firestore Documents

**What people do:** Store all messages for a chat as an array field on the conversation document.
**Why it's wrong:** Firestore document limit is 1MB. A long chat fills this and writes fail silently until the limit is hit.
**Do this instead:** Use a `messages` subcollection under each conversation document. Each message is its own document.

### Anti-Pattern 5: Skipping Demo Data for First-Run

**What people do:** Build the real data flow first, add demo data "later."
**Why it's wrong:** First impression of the app is an empty list. Users churn before adding friends. Demo data is a product requirement, not a nice-to-have.
**Do this instead:** Implement `DemoFriendService` and `DemoWeatherService` before building the real services. They share the same protocol, so swapping is trivial.

## Sources

- Modern iOS architecture (MVVM + @Observable): [Medium — Modern iOS Architecture 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f), [Medium — MVVM + @Observable iOS 17](https://medium.com/@sayefeddineh/understanding-observable-in-ios-17-the-future-of-swiftui-state-management-9085fe9c3ed8) — MEDIUM confidence (multiple sources agree)
- Firebase social login + architecture: [Firebase Auth iOS Docs](https://firebase.google.com/docs/auth/ios/start), [Firebase Facebook Login](https://firebase.google.com/docs/auth/ios/facebook-login) — HIGH confidence (official docs)
- Firestore data model: [Firebase Data Model Docs](https://firebase.google.com/docs/firestore/data-model), [Firestore chat structure](https://medium.com/@henryifebunandu/cloud-firestore-db-structure-for-your-chat-application-64ec77a9f9c0) — HIGH confidence (official docs + community)
- FCM push notifications iOS: [Firebase FCM iOS Get Started](https://firebase.google.com/docs/cloud-messaging/ios/get-started) — HIGH confidence (official docs)
- MapKit SwiftUI annotations: [Apple MapKit for SwiftUI Docs](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui) — HIGH confidence (official docs)
- OpenAI Swift integration + security: [MacPaw/OpenAI package](https://github.com/MacPaw/OpenAI), [Holdapp SwiftUI + OpenAI](https://www.holdapp.com/blog/ai-apps-swiftui-with-openai-api) — MEDIUM confidence (official GitHub + community)
- URLSession async/await networking: [avanderlee.com URLSession async/await](https://www.avanderlee.com/concurrency/urlsession-async-await-network-requests-in-swift/) — MEDIUM confidence (well-known iOS blog, widely cited)
- Weather API caching strategy: [Weather Company API architecture](https://www.weathercompany.com/blog/build-a-scalable-api-architecture-with-smart-strategies/) — MEDIUM confidence (vendor docs)

---
*Architecture research for: Hot & Cold Friends — social weather iOS app*
*Researched: 2026-03-02*
