# Phase 6: Polish och App Store - Research

**Researched:** 2026-03-04
**Domain:** WidgetKit, SwiftUI-animationer, Firebase Auth konto-radering, Privacy Manifests, App Store-submission
**Confidence:** HIGH (kärndomäner), MEDIUM (Apple age rating, Privacy manifest-detaljer)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Widget-design:**
- Visar enbart favoriter (konsekvent med appens favoritlogik)
- Tre storlekar: small (1 favorit), medium (3–4 favoriter), large (alla 6 favoriter)
- Per vän visas: profilbild, temperatur och SF Symbol väderikon
- Tappbar per vän — deep link öppnar den vännens väderdetalj i appen
- WidgetKit-target behöver läggas till i project.yml med App Group för delad data

**Väderanimationer:**
- Subtila SwiftUI-native animationer (inga externa beroenden som Lottie)
- Visas bakom profilbilden i FriendRowView (40x40 cirkel-area)
- Grundläggande 5 vädertyper: sol, moln, regn, snö, åska
- Respektera iOS "Reduce Motion" accessibility-inställning automatiskt (UIAccessibility.isReduceMotionEnabled)

**Konto-radering:**
- Full radering: Firestore-profil (users/), vänner (friends/), chattar/meddelanden (conversations/ + messages/), profilbild i Firebase Storage, Firebase Auth-konto
- Enkel bekräftelse: "Vill du verkligen radera ditt konto?"-dialog med röd knapp
- Placering: längst ner i befintlig ProfilView
- Re-autentisering: bara vid behov — försök radera, om Firebase ger "requires-recent-login"-fel, be användaren logga in igen

**App Store-metadata:**
- App-namn: "Hot & Cold Friends"
- Kategorier: Primär: Väder, Sekundär: Social Networking
- Åldersmärkning: Claude bedömer vad Apple godtar givet chatt med rapport/blockering

### Claude's Discretion
- Exakt animationsimplementation (partikelsystem, timing, easing)
- Privacy manifest-innehåll (baserat på faktiska API-anrop)
- Widget uppdateringsfrekvens (TimelineProvider-policy)
- App Store-åldersmärkning (bedömning av Apples riktlinjer)
- Skärmdumpar och marknadsföringstext (manuellt steg — inte del av kodfasen)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-05 | Användare kan radera sitt konto (App Store-krav) | Firebase Auth deleteUser() + provider-specifik re-auth (Apple token revocation, Google re-auth, Facebook re-auth) + Firestore/Storage cleanup |
| WTHR-02 | Animerade väderillustrationer bakom vännens profilbild | SwiftUI Canvas + TimelineView för partiklar (regn/snö) + withAnimation för sol/moln/åska + @Environment(\.accessibilityReduceMotion) |
| WDGT-01 | iOS hemskärmswidget visar favoriters väder | WidgetKit target i project.yml + App Group + UserDefaults shared data + TimelineProvider + widgetURL deep links |
</phase_requirements>

---

## Summary

Phase 6 täcker tre distinkt tekniska domäner plus App Store-submission. Alla tre är väldefinierade iOS-mönster med starkt stöd i official docs och etablerade community-lösningar.

**WidgetKit** är den mest komplexa komponenten. Den kräver ett separat Xcode-target, App Group-konfiguration i entitlements för båda targets, och en arkitektur där huvudappen skriver väderdata till delad UserDefaults som widgeten sedan läser synkront i TimelineProvider. Widget-extensioner kan inte göra nätverksanrop till Firestore eller WeatherKit direkt under rendering — data måste förhandas av huvudappen. Tre storlekar (small/medium/large) kräver anpassade layouter med `@Environment(\.widgetFamily)`.

**SwiftUI-animationer** för väder är genomförbara med enbart native SwiftUI utan externa beroenden (Canvas + TimelineView för partiklar, withAnimation för enklare effekter). Det kritiska mönstret för Reduce Motion är `@Environment(\.accessibilityReduceMotion)` som ger ett Bool. Värdet bör läsas i varje animationskomponent och skickas vidare som parameter — inte kollas via UIAccessibility statiskt — för att respektera SwiftUI:s reaktiva uppdatering när inställningen ändras.

**Konto-radering** med Firebase Auth har ett specifikt problem för Apple Sign In: att kalla `user.delete()` räcker inte — Apple kräver att appen kallar `Auth.auth().revokeToken(withAuthorizationCode:)` separat. Authorization code är bara tillgänglig vid inloggning, vilket innebär att re-autentisering alltid krävs för Apple-användare. För Google och Facebook räcker det att skapa ny credential via provider-inloggning och kalla `user.reauthenticate(with:)`.

**Primary recommendation:** Börja med konto-radering (minst beroenden, lägst risk), fortsätt med animationer (modifiering av befintlig FriendRowView), avsluta med widget (eget target, mest komplex setup) och App Store-submission parallellt.

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| WidgetKit | iOS 17+ (inbyggd) | Hemskärmswidget | Apples officiella widget-framework, enda godkända sättet |
| SwiftUI Canvas + TimelineView | iOS 15+ (inbyggd) | Partikelbaserade animationer | Native, ingen extra dependency, performant |
| Firebase Auth (deleteUser) | 11.x (befintlig) | Konto-radering | Redan integrerat i projektet |
| Firebase Firestore (batch delete) | 11.x (befintlig) | Radera användardata | WriteBatch för atomisk multi-dokument-radering |
| Firebase Storage (delete) | 11.x (befintlig) | Radera profilbild | StorageReference.delete() |
| App Groups (UserDefaults) | iOS 12+ (inbyggd) | Dela data app ↔ widget | Standardmönster för widget-datadelning |
| AuthenticationServices (revokeToken) | iOS 15+ (inbyggd) | Apple token revocation | Apple-krav vid konto-radering för Sign in with Apple |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| WidgetCenter | iOS 14+ (inbyggd) | Trigga widget-uppdatering från app | Anropas efter att huvudappen uppdaterat delad UserDefaults |
| @Environment(\.widgetFamily) | iOS 14+ (inbyggd) | Anpassa layout per widgetstorlek | I WidgetEntryView för small/medium/large-layouter |
| @Environment(\.accessibilityReduceMotion) | iOS 13+ (inbyggd) | Respektera Reduce Motion | I varje animationskomponent |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI Canvas (animationer) | Vortex (twostraws/Vortex) | Vortex ger enklare API men är extern dependency — CONTEXT.md förbjuder externa beroenden |
| Vortex (animationer) | Lottie | Lottie kräver fördesignade JSON-filer — CONTEXT.md förbjuder externa beroenden |
| App Groups + UserDefaults (widget-data) | Firebase Firestore i widget | Firestore listeners fungerar inte reliabelt i widget-extension runtime |

---

## Architecture Patterns

### Widget: Projektstruktur i project.yml

```yaml
targets:
  HotAndColdFriends:        # befintligt target
    # ... befintlig konfiguration ...
    entitlements:
      properties:
        com.apple.security.application-groups:
          - group.se.sandenskog.hotandcoldfriends

  HotAndColdFriendsWidget:  # nytt target
    type: app-extension
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: HotAndColdFriendsWidget
        excludes:
          - "**/@eaDir"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: se.sandenskog.hotandcoldfriends.widget
        INFOPLIST_FILE: HotAndColdFriendsWidget/Info.plist
    entitlements:
      path: HotAndColdFriendsWidget/HotAndColdFriendsWidget.entitlements
      properties:
        com.apple.security.application-groups:
          - group.se.sandenskog.hotandcoldfriends
    dependencies:
      - target: HotAndColdFriends
```

**Obs:** App Group-ID måste registreras i Apple Developer Portal och läggas till i båda targets provisioning profiles.

### Widget: Datadelning via App Groups

Huvudappen skriver till delad UserDefaults när väderdata uppdateras:

```swift
// Source: Apple Developer Documentation / WidgetKit
let sharedDefaults = UserDefaults(suiteName: "group.se.sandenskog.hotandcoldfriends")!

// Kodning: Codable-array av WidgetFriendEntry
struct WidgetFriendEntry: Codable {
    let id: String
    let displayName: String
    let city: String
    let photoURL: String?
    let temperatureCelsius: Double?
    let symbolName: String
    let temperatureColor: [Double]  // RGB-komponenter för Color.temperatureColor
}

// I AppWeatherService efter väderuppdatering:
let entries = favorites.compactMap { friendWeather -> WidgetFriendEntry? in
    // bygg entry från FriendWeather
}
if let data = try? JSONEncoder().encode(entries) {
    sharedDefaults.set(data, forKey: "widgetFavorites")
}
WidgetCenter.shared.reloadTimelines(ofKind: "HotAndColdFriendsWidget")
```

Widgeten läser synkront i TimelineProvider:

```swift
// Source: Apple Developer Documentation / WidgetKit TimelineProvider
struct WeatherTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.se.sandenskog.hotandcoldfriends")!
        let entries: [WidgetFriendEntry]
        if let data = defaults.data(forKey: "widgetFavorites"),
           let decoded = try? JSONDecoder().decode([WidgetFriendEntry].self, from: data) {
            entries = decoded
        } else {
            entries = []
        }
        let entry = WeatherEntry(date: Date(), friends: entries)
        // Uppdatera var 30:e minut (synkar med AppWeatherService cache)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### Widget: Deep Links

Small widget — hela widgeten är en enda länk:
```swift
// Source: Apple Developer Documentation / WidgetKit
.widgetURL(URL(string: "hotandcold://friend/\(friend.id)")!)
```

Medium/Large widget — per-vän tappbar zon:
```swift
// Source: Apple Developer Documentation / WidgetKit
Link(destination: URL(string: "hotandcold://friend/\(friend.id)")!) {
    FriendWidgetCell(entry: friend)
}
```

Huvudappen hanterar URL via `.onOpenURL`:
```swift
// I HotAndColdFriendsApp eller RootView
.onOpenURL { url in
    // Parsa "hotandcold://friend/<id>" och navigera till FriendWeatherDetail
}
```

URL-schema registreras i Info.plist (CFBundleURLSchemes).

### Animationer: WeatherAnimationView

Ny komponent som kapslar in vädertyp + Reduce Motion:

```swift
// Pattern: SwiftUI Canvas + TimelineView för partiklar
struct WeatherAnimationView: View {
    let condition: WeatherCondition  // sol, moln, regn, snö, åska
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            // Statisk ikon (SF Symbol) — ingen animation
            conditionIcon
        } else {
            switch condition {
            case .rain, .snow:
                ParticleAnimationView(condition: condition)
            case .sun:
                SunPulseView()
            case .clouds:
                CloudDriftView()
            case .thunder:
                ThunderFlashView()
            }
        }
    }
}
```

Partikelanimationer med Canvas + TimelineView:
```swift
// Source: Hacking with Swift / TimelineView + Canvas pattern
struct ParticleAnimationView: View {
    let condition: WeatherCondition  // .rain eller .snow
    @State private var particles: [Particle] = Particle.initial(count: 20)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Uppdatera partikelpositioner baserat på elapsed time
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let progress = (now.truncatingRemainder(dividingBy: particle.duration)) / particle.duration
                    let x = particle.startX * size.width
                    let y = progress * size.height
                    // Rita partikel (raindrop: capsule, snowflake: circle)
                    context.fill(
                        condition == .rain ?
                            Path(capsuleIn: CGRect(x: x, y: y, width: 2, height: 6)) :
                            Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)),
                        with: .color(.white.opacity(0.7))
                    )
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}
```

### Animationer: Integration i FriendRowView

`WeatherAnimationView` läggs BAKOM profilbilden med ZStack:

```swift
// Modifiering av FriendRowView.profileImage
@ViewBuilder
private var profileImage: some View {
    ZStack {
        // Animationslagret bakom
        WeatherAnimationView(condition: weatherCondition)
            .frame(width: 40, height: 40)
            .clipShape(Circle())

        // Profilbilden ovanpå (befintlig kod)
        if let urlString = friendWeather.friend.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }
    .frame(width: 40, height: 40)
    .clipShape(Circle())
}
```

WeatherCondition mappas från FriendWeather.symbolName (SF Symbol-namn):
```swift
enum WeatherCondition {
    case sun, clouds, rain, snow, thunder

    static func from(symbolName: String) -> WeatherCondition {
        if symbolName.contains("sun") || symbolName.contains("clear") { return .sun }
        if symbolName.contains("cloud") && !symbolName.contains("rain") && !symbolName.contains("snow") { return .clouds }
        if symbolName.contains("rain") || symbolName.contains("drizzle") { return .rain }
        if symbolName.contains("snow") || symbolName.contains("sleet") { return .snow }
        if symbolName.contains("thunder") || symbolName.contains("lightning") { return .thunder }
        return .clouds  // fallback
    }
}
```

### Konto-radering: deleteAccount() i AuthManager

Mönster: försök radera → fånga "requires-recent-login" → re-autentisera → försök igen:

```swift
// AuthManager.deleteAccount()
func deleteAccount() async throws {
    guard let user = Auth.auth().currentUser else { throw DeleteAccountError.noUser }

    // 1. Rensa Firestore och Storage INNAN Firebase Auth-radering
    let uid = user.uid
    try await cleanupUserData(uid: uid)

    // 2. Försök radera Firebase Auth-konto
    do {
        // Apple Sign In kräver token revocation FÖRE user.delete()
        if let appleProvider = user.providerData.first(where: { $0.providerID == "apple.com" }) {
            try await revokeAppleToken()
        }
        try await user.delete()
    } catch let error as NSError
        where error.code == AuthErrorCode.requiresRecentLogin.rawValue {
        // Kräver ny inloggning — kasta vidare för att UI ska hantera det
        throw DeleteAccountError.requiresRecentLogin
    }
}

// Rensa all användardata
private func cleanupUserData(uid: String) async throws {
    let db = Firestore.firestore()
    let batch = db.batch()

    // users/<uid>
    batch.deleteDocument(db.collection("users").document(uid))

    // friends/<uid>/friendsList/* — kräver sub-collection loop
    let friendsSnapshot = try await db.collection("friends").document(uid)
        .collection("friendsList").getDocuments()
    for doc in friendsSnapshot.documents {
        batch.deleteDocument(doc.reference)
    }
    batch.deleteDocument(db.collection("friends").document(uid))

    try await batch.commit()

    // conversations och messages — ta bort konversationer där uid är deltagare
    // (komplex query — se implementation-noter nedan)

    // Firebase Storage — profilbild
    let storageRef = Storage.storage().reference().child("profileImages/\(uid)")
    try? await storageRef.delete()  // try? — bild kanske inte existerar
}
```

**Apple token revocation** — Apple-krav, saknas i nuvarande AuthManager:

```swift
// Source: Firebase Authentication iOS docs / Apple sign-in token revocation
private func revokeAppleToken() async throws {
    // Kräver re-autentisering med Apple för att få authorization code
    let nonce = randomNonceString()
    currentNonce = nonce

    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = []
    request.nonce = sha256(nonce)

    let authorization = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<ASAuthorization, Error>) in
        self.appleSignInContinuation = continuation
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let authorizationCode = appleIDCredential.authorizationCode,
          let codeString = String(data: authorizationCode, encoding: .utf8) else {
        throw DeleteAccountError.appleTokenRevocationFailed
    }

    try await Auth.auth().revokeToken(withAuthorizationCode: codeString)
}
```

**Google re-autentisering** om requiresRecentLogin:
```swift
// Re-autentisera Google-användare
func reauthenticateGoogle() async throws {
    guard let clientID = FirebaseApp.app()?.options.clientID else { return }
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    guard let vc = rootViewController() else { return }
    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: vc)
    guard let idToken = result.user.idToken?.tokenString else { return }
    let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: result.user.accessToken.tokenString
    )
    try await Auth.auth().currentUser?.reauthenticate(with: credential)
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Widget-layout per storlek | Custom size-check logik | `@Environment(\.widgetFamily)` | Apple-standard, robust mot framtida storlekar |
| Widget-uppdatering från app | Poll-mekanism | `WidgetCenter.shared.reloadTimelines(ofKind:)` | Enda godkända sättet att trigga widget-reload |
| App Group-data | Egna IPC-mekanismer | `UserDefaults(suiteName:)` | Systemhanterat, atomiskt, inga race conditions |
| Reduce Motion-detektering | UIAccessibility.isReduceMotionEnabled (statisk) | `@Environment(\.accessibilityReduceMotion)` | SwiftUI-reaktivt — uppdateras om användaren ändrar inställning |
| Partikelanimationer | SpriteKit eller externa bibliotek | Canvas + TimelineView (native SwiftUI) | Native, CONTEXT.md förbjuder externa beroenden |
| Apple token revocation | Hoppa över den | `Auth.auth().revokeToken(withAuthorizationCode:)` | App Store-krav — avsaknad gör att appen avvisas |

---

## Common Pitfalls

### Pitfall 1: Widget kan inte göra nätverksanrop vid rendering

**What goes wrong:** Widgeten försöker anropa Firebase eller WeatherKit i TimelineProvider, vilket antingen kraschar eller ger tomma data.
**Why it happens:** Widget-extensions körs i en begränsad sandbox. Nätverksanrop i `getTimeline()` är möjliga men opålitliga och långsamma — systemet kan timeout:a widget-reload.
**How to avoid:** All data måste skrivas till delad UserDefaults av huvudappen INNAN widgeten behöver det. TimelineProvider läser endast lokalt.
**Warning signs:** Tom widget vid cold start, widget visar inte uppdaterad data.

### Pitfall 2: App Group måste aktiveras i Developer Portal

**What goes wrong:** Appen kompilerar men widgeten får inte åtkomst till delade UserDefaults (`UserDefaults(suiteName:)` returnerar nil eller är isolerad).
**Why it happens:** App Group-entitlement kräver explicit registrering i Apple Developer Portal under Identifiers, och båda targets måste ha rätt provisioning profile.
**How to avoid:** Registrera App Group ID i Developer Portal → lägg till i båda appens och widgetens App ID:n → generera nya provisioning profiles → kör xcodegen.
**Warning signs:** `UserDefaults(suiteName: "group...")` returnerar data i appen men nil i widgeten.

### Pitfall 3: Apple Sign In-radering utan token revocation

**What goes wrong:** Appen klarar intern test men avvisas i App Store Review pga. saknad Apple token revocation.
**Why it happens:** Apple kräver sedan juni 2022 att appar med Sign in with Apple kallar revoke-API vid konto-radering. Firebase `user.delete()` triggar INTE detta automatiskt.
**How to avoid:** Implementera explicit `Auth.auth().revokeToken(withAuthorizationCode:)` INNAN `user.delete()` för Apple-användare.
**Warning signs:** Apple Developer Forum-post om att "appaen avvisades" trots att Firebase Auth-kontot raderades korrekt.

### Pitfall 4: Conversations/messages-radering kräver batched reads

**What goes wrong:** Konto-radering lämnar kvar konversationer och meddelanden i Firestore, vilket bryter GDPR/App Store-krav om fullständig dataradering.
**Why it happens:** Konversationer är collections utan enkel query på "participants contains uid" (Firestore stöder inte array-contains-delete).
**How to avoid:** Query `conversations` collection med `.whereField("participants", arrayContains: uid)`, iterera och batch-radera documents + subcollections (messages). OBS: `WriteBatch` stöder max 500 operationer — chunka stora datamängder.
**Warning signs:** Firestore-regler loggar att raderade användares dokument fortfarande finns kvar.

### Pitfall 5: widgetURL fungerar enbart på small widgets

**What goes wrong:** Utvecklaren lägger `.widgetURL()` på enskilda views i medium/large widget och förväntar sig per-element navigation — men hela widgeten beter sig som en enda länk.
**Why it happens:** `.widgetURL()` gäller hela widgetens tap-yta oavsett var i vyhierarkin den placeras. Medium/large kräver `Link(destination:)` för per-element deep links.
**How to avoid:** Small: `.widgetURL(url)` på root view. Medium/Large: `Link(destination: url) { ... }` per vän-cell.
**Warning signs:** Alla vänner i medium widget navigerar till samma destination.

### Pitfall 6: Privacy manifest för app-specifika API:er

**What goes wrong:** Appen avvisas med ITMS-91061 eller ITMS-91053 även om Firebase och andra SDKs har egna manifests.
**Why it happens:** Firebase SDK 11.x inkluderar egna PrivacyInfo.xcprivacy per modul. Men appen själv måste deklarera de API:er som APP-KODEN (inte SDKs) anropar — t.ex. om appen direkt anropar UserDefaults, FileManager.attributesOfItem, eller liknande.
**How to avoid:** Inspektera apptargetets källkod för Required Reason APIs. Lägg till app-nivå PrivacyInfo.xcprivacy i Resources/ om sådana API:er används.
**Warning signs:** ITMS-91053 "Missing API Declaration" email från App Store Connect.

---

## Code Examples

### WidgetKit: Minimal komplett widget

```swift
// Source: Apple Developer Documentation / WidgetKit

import WidgetKit
import SwiftUI

// 1. Entry (data-struct som TimelineEntry)
struct WeatherEntry: TimelineEntry {
    let date: Date
    let friends: [WidgetFriendEntry]
}

// 2. TimelineProvider
struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), friends: [])
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (WeatherEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.se.sandenskog.hotandcoldfriends")!
        let friends: [WidgetFriendEntry]
        if let data = defaults.data(forKey: "widgetFavorites"),
           let decoded = try? JSONDecoder().decode([WidgetFriendEntry].self, from: data) {
            friends = decoded
        } else {
            friends = []
        }
        let entry = WeatherEntry(date: Date(), friends: friends)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// 3. Widget-vy
struct WeatherWidgetEntryView: View {
    let entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(friends: Array(entry.friends.prefix(1)))
        case .systemMedium:
            MediumWidgetView(friends: Array(entry.friends.prefix(4)))
        default:
            LargeWidgetView(friends: entry.friends)
        }
    }
}

// 4. Widget-konfiguration
@main
struct HotAndColdFriendsWidget: Widget {
    let kind = "HotAndColdFriendsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hot & Cold Friends")
        .description("Se vädret hos dina vänner.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### Animationer: Reduce Motion-mönster

```swift
// Source: Hacking with Swift / SwiftUI accessibilityReduceMotion
struct SunPulseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "sun.max.fill")
            .foregroundStyle(.yellow.opacity(0.6))
            .scaleEffect(scale)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
    }
}
```

### Konto-radering: ProfilView UI

```swift
// Längst ner i ProfilView.body, inuti isOwnProfile-blocket
if isOwnProfile {
    // ... befintlig redigera-knapp ...

    // Konto-radering
    Button(role: .destructive) {
        showDeleteConfirmation = true
    } label: {
        Label("Radera konto", systemImage: "trash")
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
    .padding(.horizontal)
    .padding(.bottom, 24)
    .alert("Radera konto?", isPresented: $showDeleteConfirmation) {
        Button("Radera", role: .destructive) {
            Task { await deleteAccount() }
        }
        Button("Avbryt", role: .cancel) {}
    } message: {
        Text("Ditt konto och all din data raderas permanent. Åtgärden kan inte ångras.")
    }
}
```

### Privacy Manifest: Minimal PrivacyInfo.xcprivacy för appen

```xml
<!-- Source: Apple Developer Documentation / Privacy manifest files -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults — används för widget-datadelning via App Groups -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
                <!-- CA92.1: Access info from the same app that wrote the info -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Obs:** Firebase SDK 11.x inkluderar egna PrivacyInfo.xcprivacy per modul (FirebaseCore, FirebaseMessaging etc.) via SPM. Dessa bundlas automatiskt och behöver inte dupliceras. App-manifesten behöver bara deklarera API:er som APP-KODEN direkt anropar.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| INTENTConfiguration (intents) för widget | StaticConfiguration + AppIntents (iOS 17+) | iOS 17 | Enklare setup, inga INTENTExtension-targets behövs |
| functions.config() i Firebase Cloud Functions | defineSecret() | Firebase Functions v2 (2023) | Redan implementerat i projektet (fas 3) |
| 12+ / 17+ åldersratings | 13+ / 16+ / 18+ | Juli 2025 | Appen bör troligen 4+ eller 9+ — påverkar formulär i App Store Connect |
| Statisk privacy manifest-kontroll | Automatisk ITMS-felmail | Maj 2024 | Submission blockeras om manifest saknas |

**Deprecated/outdated:**
- `INTENTExtension` target för widgets: ersatt av AppIntents-direkt-integration i iOS 16+. Projektet behöver inte detta.
- `TimelineProvider.placeholder()` med dummy-data: fortfarande giltigt men `placeholder(in:)` bör vara snabb och synkron.

---

## App Store: Åldersrating och Submission

### Rekommenderad åldersrating: 4+

**Motivering:** Appen har chatt med rapport/blockering och utan moderering av okände. Apple Age Rating-systemet (uppdaterat juli 2025) innefattar 4+, 9+, 13+, 16+, 18+. Appar med chatt listas vanligtvis som "Contains: Allows User Interaction". Det ÄLDRE systemet (12+/17+) är ersatt — gamla guider som säger "17+" för chatt-appar är föråldrade.

Faktorer som höjer ratingen (som appen SAKNAR): explicit innehåll, anonyma chattar, ej verifierade kontakter. Faktorn som potentiellt höjer till 9+: chatt utan fullständig moderering. Med rapport/blockering implementerat (CHAT-04, CHAT-05) är 4+ försvarbart. Bedömning: 4+, men AppStore Connect-formuläret avgör slutgiltigt.

### Submission-flöde
1. `Product → Archive` i Xcode (kräver distribution provisioning profile)
2. `Validate App` — fångar ITMS-91061 (privacy manifest) och andra pre-submission-fel
3. `Distribute App → App Store Connect`
4. TestFlight: lägg till interna testare, invänta bearbetning (~15 min), testa på fysisk iPhone
5. App Store: fyll i metadata (beskrivning, skärmdumpar, age rating)
6. Submit for Review

**Screenshot-krav 2025:** Minst 1 skärmdump i 6.5" eller 6.9" format för iPhone. Inga separata krav per enhetstyp längre.

**Builds måste kompileras med iOS 18 SDK** (Xcode 16+) — projektet använder `xcodeVersion: "16"` i project.yml, detta är redan korrekt.

---

## Open Questions

1. **Conversations-radering: query-strategi**
   - What we know: Firestore stöder `.whereField("participants", arrayContains: uid)` för att hitta konversationer
   - What's unclear: Strukturen på `messages`-subcollections kan kräva Cloud Function för fullständig radering av subcollections (Firestore deleteDocument() raderar inte subcollections automatiskt)
   - Recommendation: Implementera klient-sidan radering av documents + subcollections. Om antalet meddelanden är stort, acceptera att subcollections kräver en Cloud Function för atomic cleanup. Alternativt: sätt en `deleted: true`-flagga på conversation-dokumentet och radera sub-data via bakgrundsjobb.

2. **Widget profilbilder: AsyncImage fungerar inte i WidgetKit**
   - What we know: WidgetKit-views stöder inte `AsyncImage` för nätverksbilder — bilder måste laddas av huvudappen och cachas lokalt
   - What's unclear: Exakt mekanism — antingen spara bilddata i shared UserDefaults (memory-intensivt) eller skriva till delad App Group container-fil
   - Recommendation: Spara profilbilder som Data till App Group container (`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`) med friend.id som filnamn. Widgeten läser filen som UIImage.

3. **Widget update-frekvens: systembegränsning**
   - What we know: Apple begränsar widget-uppdateringar till ~40-70 per dag för en given widget. `.after(Date())` triggar omedelbar uppdatering men räknas mot budgeten.
   - What's unclear: Exakta gränser och hur WidgetCenter.reloadTimelines räknas
   - Recommendation: Sätt TimelinePolicy till `.after` 30 minuter (matchar AppWeatherService cache). `WidgetCenter.reloadTimelines(ofKind:)` från appen räknas separat och är mer frikostig.

4. **Age rating: Apple deadline januari 2026**
   - What we know: STATE.md noterar "Verifiera age-gating-formulär status i App Store Connect (Apple deadline januari 2026)" — deadline som blockar uppdaterings-submissions
   - What's unclear: Om befintligt App Store Connect-konto behöver uppdatera age rating-svar till nytt system INNAN first submission
   - Recommendation: Kontrollera age rating-formuläret tidigt i App Store Connect. Det nya 2025-systemet kräver nya svar per app.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: WidgetKit/TimelineProvider — https://developer.apple.com/documentation/widgetkit/timelineprovider
- Apple Developer Documentation: WidgetCenter.reloadTimelines — https://developer.apple.com/documentation/widgetkit/widgetcenter/reloadtimelines(ofkind:)
- Apple Developer Documentation: Offering account deletion — https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Hacking with Swift: accessibilityReduceMotion — https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting
- Firebase iOS SDK GitHub: PrivacyInfo.xcprivacy examples — https://github.com/firebase/firebase-ios-sdk/blob/main/FirebaseCore/Sources/Resources/PrivacyInfo.xcprivacy
- Apple Developer Documentation: Adding privacy manifest — https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk

### Secondary (MEDIUM confidence)
- tanaschita.com: WidgetKit patterns med App Groups — https://tanaschita.com/20220905-building-widgets-for-ios-applications-with-widgetkit-and-swiftui/
- Firebase Developers (Medium): Deleting User Account & Revoke Access Token — https://medium.com/firebase-developers/deleting-user-account-revoke-access-token-0e30d7a351bb
- Apple App Store Review Guidelines: Section 5.1.1(v) account deletion — https://developer.apple.com/app-store/review/guidelines/
- Apple Age Ratings update 2025: https://developer.apple.com/news/?id=ks775ehf

### Tertiary (LOW confidence)
- ASO World: Apple age rating 2025 update — https://asoworld.com/blog/apple-app-store-age-rating-update-developer-guide/ (behöver verifieras mot Apple Developer Portal vid submission)
- GitHub: firebase-ios-sdk issue #9906 — Apple token revocation feature request (historisk kontext för varför revokeToken implementerades)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — WidgetKit/SwiftUI är väldefinierade iOS 17-API:er med officiell dokumentation
- Architecture: HIGH — Mönster (App Groups, TimelineProvider, Canvas+TimelineView) är väletablerade och beprövade
- Account deletion (Firebase+Apple): HIGH — Officiell Firebase-dokumentation + Apple developer guidelines
- Privacy manifests: MEDIUM — Firebase SDK inkluderar egna manifests (HIGH), men exakt innehåll i app-manifest varierar per implementation (MEDIUM)
- App Store age rating: MEDIUM — Nytt system juli 2025, exakt rating beror på App Store Connect-formulär-svar

**Research date:** 2026-03-04
**Valid until:** 2026-06-04 (WidgetKit/SwiftUI stabilt, Firebase SDK kan uppdateras, App Store-krav kan ändras)
