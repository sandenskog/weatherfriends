# Phase 1: Foundation - Research

**Researched:** 2026-03-02
**Domain:** Firebase Authentication (Apple/Google/Facebook) + Firestore + SwiftUI
**Confidence:** HIGH (core stack), MEDIUM (Facebook SDK specifics)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Login-skärmen**
- Kort splash med appnamn/logga och tagline, sedan login-knappar nedanför
- Mjuk gradient (vitt till ljusblått) som antyder vädertema
- Tre login-knappar staplade vertikalt: Apple först, sedan Google, sedan Facebook
- Alla knappar lika framträdande (Apple HIG-krav)

**Onboarding-flöde**
- Stegvis wizard med separata skärmar: 1) Namn, 2) Profilbild, 3) Stad/land
- Profilbild är valfri — en generisk avatar/initial visas som default
- Namn och stad/land krävs för att slutföra onboarding

**Profilvisning**
- Andras profiler visas som halvmodal (sheet) som glider upp från botten
- Minimal info i Fas 1: rund profilbild + namn + stad/land
- Edit-knapp visas på egen profil för att redigera
- Profilbilder visas som runda cirklar genomgående i appen

**Platsinmatning**
- Sökfält med autocomplete (börja skriva → få förslag)
- Specificitetnivå: stad + land (t.ex. "Stockholm, Sverige")
- GPS som hjälp: be om platstillstånd, förifyll förslaget, användaren bekräftar
- Plats kan ändras fritt via profilredigering utan bekräftelsedialog

**Integration points (from code context)**
- Firebase Auth som backend för alla tre login-providers
- Firestore för användar- och profildata
- Apple MapKit/CLGeocoder eller liknande för plats-autocomplete

### Claude's Discretion
- Tagline-text på login-skärmen
- Fotoval-metod för profilbild (kamerarulle och/eller kamera)
- Progress-indikator-stil i onboarding-wizarden
- Felhantering vid misslyckad login
- Default-avatar/initial-design

### Deferred Ideas (OUT OF SCOPE)
Ingen — diskussionen höll sig inom fasens scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | Användare kan logga in med Sign in with Apple | Firebase OAuthProvider + ASAuthorizationController + SHA256-nonce; fungerar fullt med FirebaseAuth 12.x |
| AUTH-02 | Användare kan logga in med Google Sign-In | GoogleSignIn-iOS 9.1.0 + GIDSignIn.sharedInstance.signIn(withPresenting:) + GoogleAuthProvider.credential |
| AUTH-03 | Användare kan logga in med Facebook Login | Facebook iOS SDK 18.x + FBSDKLoginManager + FacebookAuthProvider.credential |
| AUTH-04 | Användarsession bevaras mellan app-starter | Firebase Auth hanterar session-persistens automatiskt via Keychain; addStateDidChangeListener i @Observable AuthManager |
| PROF-01 | Användare kan skapa profil med namn och profilbild | SwiftUI PhotosPicker + Firebase Storage + Firestore users-collection med Codable |
| PROF-02 | Användare kan ange sin stad/land | MKLocalSearchCompleter (MapKit, ingen API-nyckel) + CLLocationManager för GPS-förfyllning |
| PROF-03 | Användare kan visa andra användares profilers | Firestore read av annan användares document + SwiftUI .sheet med presentationDetents |
</phase_requirements>

---

## Summary

Firebase Auth 12.x (kräver iOS 15+) är den enda rimliga autentiseringslösningen för ett iOS-projekt 2026 som ska stödja Apple, Google och Facebook. Alla tre providers är testade och dokumenterade mot Firebase och installeras via Swift Package Manager. Session-persistens är inbyggd i Firebase Auth och kräver ingen extra konfiguration — en `addStateDidChangeListener`-lyssnare i en `@Observable`-klass är allt som behövs.

För stad/land-autocomplete är **MKLocalSearchCompleter** (MapKit) det rätta valet — det kräver ingen API-nyckel, har ingen rate limit och är fullt integrerat i iOS-ekosystemet. GPS-förfyllning görs med `CLLocationManager` och det moderna async/await-API:et (`CLLocationUpdate.liveUpdates()`) som finns från iOS 17+. Firestore med Swift Codable och `@DocumentID`/`@ServerTimestamp` property wrappers ger ren datamodellering.

Det kritiska arkitekturbeslutet i fas 1 är att etablera rätt navigationsmodell — **NavigationStack med typ-säker routing** och en uppdelad vy-hierarki (auth-flöde vs. main-flöde) kontrollerad av `authState` i en root-level `AuthManager`. Fas 1 sätter arkitekturmönstret som alla efterföljande faser bygger på.

**Primary recommendation:** Använd Firebase iOS SDK 12.x via SPM, @Observable AuthManager med auth-state listener, MKLocalSearchCompleter för plats-autocomplete, och NavigationStack-baserad routing med tydlig separation av auth- och main-flöde.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Firebase iOS SDK | 12.10.0 (feb 2026) | Auth + Firestore + Storage | Officiell SDK, kräver iOS 15+, enda rimliga valet för Firebase-projekt |
| GoogleSignIn-iOS | 9.1.0 | Google Sign-In OAuth | Googles officiella iOS-SDK, installeras separat från Firebase |
| Facebook iOS SDK | 18.0.3 (feb 2026) | Facebook Login | Facebooks officiella SDK, kräver iOS 12+ |
| MapKit (inbyggt) | iOS 17+ | MKLocalSearchCompleter | Ingen API-nyckel, ingen kostnad, inbyggt i iOS |
| CoreLocation (inbyggt) | iOS 17+ | GPS-förfyllning | Inbyggt, async/await-API tillgängligt från iOS 17 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FirebaseFirestoreSwift | Del av Firebase SDK | @DocumentID, @ServerTimestamp, Codable | Alltid — för ren Firestore-datamodellering |
| FirebaseStorage | Del av Firebase SDK | Lagring av profilbilder | Profilbilduppladdning i PROF-01 |
| CryptoKit (inbyggt) | iOS 13+ | SHA256-hash för Sign in with Apple nonce | Krävs av Apple-specifikationen för nonce-generering |
| AuthenticationServices (inbyggt) | iOS 13+ | ASAuthorizationController för Sign in with Apple | Apple HIG-krav |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MKLocalSearchCompleter | Google Places API | Google kräver API-nyckel och kostar pengar per request; MapKit är gratis och täcker behovet |
| Firebase Storage | Cloudinary | Firebase Storage är enklare att säkra med Security Rules; Cloudinary är overkill för profilbilder |
| @Observable (iOS 17+) | ObservableObject | @Observable kräver iOS 17+ vilket redan är deployment target; renare och modernare |
| NavigationStack | UINavigationController | NavigationStack är SwiftUI-native och typ-säkert från iOS 16+ |

**Installation (SPM i Xcode — File > Add Packages):**
```
Firebase: https://github.com/firebase/firebase-ios-sdk.git
  Välj: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift, FirebaseStorage

Google Sign-In: https://github.com/google/GoogleSignIn-iOS.git
  Välj: GoogleSignIn, GoogleSignInSwift

Facebook: https://github.com/facebook/facebook-ios-sdk.git
  Välj: FacebookCore, FacebookLogin
```

---

## Architecture Patterns

### Recommended Project Structure

```
HotAndColdFriends/
├── App/
│   ├── HotAndColdFriendsApp.swift   # @main, FirebaseApp.configure(), UIApplicationDelegateAdaptor
│   └── AppDelegate.swift            # GIDSignIn URL handling, Facebook applicationDidBecomeActive
├── Core/
│   ├── Auth/
│   │   ├── AuthManager.swift        # @Observable, auth state listener, login methods
│   │   └── AuthState.swift          # Enum: .unauthenticated, .authenticating, .authenticated(User)
│   └── Navigation/
│       └── AppRouter.swift          # Root NavigationStack, auth vs main routing
├── Features/
│   ├── Login/
│   │   ├── LoginView.swift          # Splash + tre login-knappar
│   │   └── LoginViewModel.swift     # Hanterar loading states per provider
│   ├── Onboarding/
│   │   ├── OnboardingView.swift     # Wizard container
│   │   ├── OnboardingNameView.swift
│   │   ├── OnboardingPhotoView.swift
│   │   ├── OnboardingLocationView.swift
│   │   └── OnboardingViewModel.swift
│   └── Profile/
│       ├── ProfileView.swift        # Halvmodal sheet för andra användares profil
│       ├── EditProfileView.swift    # Redigera egen profil
│       └── ProfileViewModel.swift
├── Models/
│   └── AppUser.swift               # Firestore Codable user model
├── Services/
│   ├── UserService.swift           # Firestore CRUD för users-collection
│   └── LocationService.swift       # MKLocalSearchCompleter + CLLocationManager
└── Resources/
    ├── GoogleService-Info.plist    # Firebase config (läggs till manuellt, ej i git)
    └── Assets.xcassets
```

### Pattern 1: @Observable AuthManager med Firebase Auth Listener

**What:** En singleton-liknande `@Observable`-klass som lyssnar på Firebase Auth state och exponerar `currentUser` och `authState` till hela appen via `@Environment`.

**When to use:** Root-nivå i appen — sätts som `@Environment`-objekt i `HotAndColdFriendsApp`.

**Example:**
```swift
// Source: Firebase Auth iOS dokumentation + @Observable pattern (iOS 17+)
@Observable
@MainActor
class AuthManager {
    var currentUser: AppUser?
    var authState: AuthState = .unauthenticated

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.authState = .authenticated(user)
                    await self?.fetchOrCreateUserProfile(uid: user.uid)
                } else {
                    self?.authState = .unauthenticated
                    self?.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let handle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
```

### Pattern 2: Sign in with Apple med Firebase (nonce-flöde)

**What:** Apple kräver en kryptografisk nonce som SHA256-hashas innan den skickas till Apple, men raw-versionen skickas till Firebase. Kritisk säkerhetsdetalj.

**When to use:** Alltid för Sign in with Apple — Apple HIG-krav, App Store kräver Sign in with Apple om appen erbjuder tredjepartslogin.

**Example:**
```swift
// Source: Firebase Auth iOS/Apple dokumentation + swiftsenpai.com (verifierat mot Firebase docs)
import CryptoKit
import AuthenticationServices

// 1. Generera nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            return random
        }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

// 2. Initiera Apple-inloggning
func signInWithApple() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)  // SHA256-hash skickas till Apple

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}

// 3. I ASAuthorizationControllerDelegate
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let nonce = currentNonce,
          let appleIDToken = appleIDCredential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }

    // rawNonce (ej hash) skickas till Firebase
    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                    rawNonce: nonce,
                                                    fullName: appleIDCredential.fullName)
    Auth.auth().signIn(with: credential) { result, error in
        // Hanteras av auth state listener
    }
}
```

### Pattern 3: Google Sign-In med Firebase

**What:** GIDSignIn kräver en UIViewController för att presentera OAuth-flödet — i SwiftUI hämtas den från fönsterhierarkin.

**Example:**
```swift
// Source: Firebase Auth iOS/Google dokumentation + swiftsenpai.com
func signInWithGoogle() async throws {
    guard let clientID = FirebaseApp.app()?.options.clientID else { return }
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else { return }

    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

    guard let idToken = result.user.idToken?.tokenString else { return }
    let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                   accessToken: result.user.accessToken.tokenString)
    try await Auth.auth().signIn(with: credential)
}
```

### Pattern 4: Facebook Login med Firebase

**What:** Facebook SDK kräver AppDelegate-setup och URL-hantering. FBSDKLoginManager används programmatiskt (ingen FBSDKLoginButton krävs).

**Example:**
```swift
// Source: Firebase Auth iOS/Facebook dokumentation
func signInWithFacebook() async throws {
    let loginManager = LoginManager()

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else { return }

    let result = try await withCheckedThrowingContinuation { continuation in
        loginManager.logIn(permissions: ["email", "public_profile"],
                          from: rootVC) { result, error in
            if let error = error { continuation.resume(throwing: error); return }
            guard let result = result, !result.isCancelled else {
                continuation.resume(throwing: AuthError.cancelled); return
            }
            continuation.resume(returning: result)
        }
    }

    guard let tokenString = result.token?.tokenString else { return }
    let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
    try await Auth.auth().signIn(with: credential)
}
```

### Pattern 5: MKLocalSearchCompleter för stad-autocomplete

**What:** `@Observable` wrapper runt `MKLocalSearchCompleter` med delegate-pattern för asynkrona resultat.

**Example:**
```swift
// Source: Apple Developer Documentation + levelup.gitconnected.com (verifierat)
@Observable
class LocationService: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [MKLocalSearchCompletion] = []
    var queryFragment: String = "" {
        didSet { completer.queryFragment = queryFragment }
    }

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address  // Begränsa till adresser (städer ingår)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filtrera till städer/länder genom att kolla title/subtitle-kombination
        suggestions = completer.results.filter { result in
            result.subtitle.contains(",") || result.subtitle.isEmpty
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }

    // Hämta koordinater för vald stad (behövs för väderdata i fas 2)
    func resolveLocation(_ completion: MKLocalSearchCompletion) async -> CLPlacemark? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        return response?.mapItems.first?.placemark
    }
}
```

### Pattern 6: Firestore User Profile med Codable

**What:** Firestore Swift Codable med `@DocumentID` och `@ServerTimestamp` för automatisk mappning.

**Example:**
```swift
// Source: Firebase Firestore Swift Codable dokumentation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?  // Mappas till Firestore document ID (= Firebase Auth UID)
    var displayName: String
    var photoURL: String?        // URL till Firebase Storage
    var city: String             // "Stockholm, Sverige"
    var cityLatitude: Double?    // Sparas för väderdata i fas 2
    var cityLongitude: Double?
    var authProvider: String     // "apple" | "google" | "facebook"
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?

    var profileImageURL: URL? {
        guard let urlString = photoURL else { return nil }
        return URL(string: urlString)
    }
}

// Spara användarprofil
func createUserProfile(_ user: AppUser) async throws {
    guard let id = user.id else { return }
    try await Firestore.firestore()
        .collection("users")
        .document(id)
        .setData(from: user, merge: true)  // merge: true för att inte skriva över vid uppdatering
}

// Hämta användarprofil
func fetchUser(uid: String) async throws -> AppUser? {
    let document = try await Firestore.firestore()
        .collection("users")
        .document(uid)
        .getDocument()
    return try document.data(as: AppUser.self)
}
```

### Anti-Patterns to Avoid

- **Direkt användning av `Auth.auth().currentUser` i vyer:** Gå alltid via `AuthManager` — `currentUser` kan vara nil om listenern inte hunnit avfyras.
- **Spara Apple-användarens namn vid varje inloggning:** Apple skickar bara `fullName` vid FÖRSTA inloggning — spara det i Firestore omedelbart, annars är det borta.
- **Blocka main thread med sync Firestore-anrop:** Använd alltid `async/await` eller kompletteringsblock.
- **`GIDSignIn` utan URL-hantering i AppDelegate:** Google Sign-In kräver `GIDSignIn.sharedInstance.handle(url)` i `application(_:open:options:)` — utan detta fungerar OAuth-redirecten inte.
- **Facebook SDK utan `ApplicationDelegate.shared.application` i AppDelegate:** Krävs för att SDK:et ska fungera korrekt.
- **Skippa Firestore Security Rules:** Standard-regler är öppna — sätt rätt rules INNAN data börjar skrivas.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session-persistens | Egen Keychain-lagring av tokens | Firebase Auth (inbyggt) | Firebase hanterar token-refresh, Keychain, och multi-device edge cases |
| City autocomplete | Egen sökning mot externt API | MKLocalSearchCompleter | Ingen kostnad, ingen rate limit, inbyggt i iOS, täcker globala städer |
| Nonce-generering för Apple login | Enkel random-sträng | SecRandomCopyBytes + SHA256 | Apple kräver kryptografisk nonce — svag implementation ger MissingOrInvalidNonce-fel |
| Bildkomprimering | Manuell JPEG-komprimering med magiska värden | `jpegData(compressionQuality: 0.75)` | Välkänt trade-off; Firebase Storage Extension kan också resize server-side |
| Auth-routing | Komplex navigationskod | AuthState enum + NavigationStack | Enkel state machine är lättare att underhålla och testa |

**Key insight:** Firebase Auth löser token-livscykel, multi-device sessioner och säker lagring åt dig — att bygga detta från scratch tar veckor och introducerar säkerhetshål.

---

## Common Pitfalls

### Pitfall 1: Apple Sign-In — Namn sparas bara vid första login

**What goes wrong:** `appleIDCredential.fullName` är `nil` vid alla inloggningar efter den första. Användaren verkar inte ha ett namn.
**Why it happens:** Apple skickar av integritetsskäl bara användardata (namn, e-post) vid FÖRSTA OAuth-godkännande.
**How to avoid:** Spara `fullName` i Firestore *omedelbart* i `authorizationController:didCompleteWithAuthorization:` — kolla om `displayName` redan finns i Firestore (= returning user), och om det saknas, spara från Apple-credential.
**Warning signs:** Nya testanvändare får namn, men om du rensar appen och loggar in igen saknas namn.

### Pitfall 2: Google Sign-In URL-hantering saknas

**What goes wrong:** OAuth-flödet öppnar Safari, men appen tar aldrig emot callback. Inloggning hänger eller failar tyst.
**Why it happens:** Google Sign-In använder en custom URL scheme för OAuth redirect. Utan `GIDSignIn.sharedInstance.handle(url)` i AppDelegate ignoreras denna URL.
**How to avoid:** Implementera `application(_:open:options:)` i AppDelegate och lägg till URL-scheme från `REVERSED_CLIENT_ID` i `GoogleService-Info.plist` till Xcode-projektets URL Types.
**Warning signs:** Inloggning fungerar i simulator men inte alltid, eller hänger utan felmeddelande.

### Pitfall 3: Facebook SDK — Info.plist-konfiguration

**What goes wrong:** Appen kraschar vid uppstart eller Facebook-inloggning fungerar inte alls.
**Why it happens:** Facebook SDK kräver `FacebookAppID`, `FacebookClientToken` och `FacebookDisplayName` i `Info.plist`, samt en URL scheme (`fbAPP_ID`). Saknas dessa crashar SDK:et vid init.
**How to avoid:** Lägg till alla obligatoriska Info.plist-nycklar under Facebook SDK-setup. Verifiera med `ApplicationDelegate.shared.application` i AppDelegate.
**Warning signs:** Crash vid cold start, eller felmeddelande om saknad App ID.

### Pitfall 4: SwiftUI + UIApplicationDelegateAdaptor krävs för Firebase

**What goes wrong:** `GIDSignIn.sharedInstance.handle(url)` och `ApplicationDelegate.shared.application` anropas aldrig — OAuth och Facebook fungerar inte.
**Why it happens:** SwiftUI-appar har ingen automatisk AppDelegate. Firebase-dokumentationen tar upp detta men lätt förbisett.
**How to avoid:** Skapa `AppDelegate.swift` med `UIApplicationDelegate` och lägg `@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate` i `@main`-structen.
**Warning signs:** Google/Facebook-inloggning fungerar aldrig i SwiftUI-app utan detta.

### Pitfall 5: MKLocalSearchCompleter — City vs. Address-resultat

**What goes wrong:** Autocomplete returnerar specifika gatuadresser istället för städer — dålig UX för stad/land-inmatning.
**Why it happens:** Standard `resultTypes` inkluderar `.pointsOfInterest` och specifika adresser.
**How to avoid:** Sätt `completer.resultTypes = .address` och filtrera resultat baserat på `subtitle` (länder/regioner har korta subtitles). Alternativt använd `MKLocalSearchCompleter` med `filterType = MKSearchCompletionFilterType.locationsOnly`.
**Warning signs:** Förslag som "Kungsgatan 5, Stockholm" istället för "Stockholm, Sverige".

### Pitfall 6: Firestore Security Rules — Default är öppet

**What goes wrong:** All data i Firestore är läs- och skrivbar för alla — säkerhetshål i produktion.
**Why it happens:** Firebase skapar testmode-regler som tillåter all access i 30 dagar. Glöms lätt.
**How to avoid:** Sätt produktionsregler FÖR FÖRSTA DEPLOY:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;  // Fas 3: vänner behöver läsa profiler
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Warning signs:** Firebase Console varnar om osäkra rules. Kolla alltid Rules-fliken.

---

## Code Examples

Verified patterns from official sources:

### Firebase-setup i SwiftUI App

```swift
// Source: Firebase iOS Add to Project dokumentation
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(  // Facebook SDK
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Google Sign-In URL handling
        if GIDSignIn.sharedInstance.handle(url) { return true }
        // Facebook URL handling
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}

@main
struct HotAndColdFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authManager)
        }
    }
}
```

### Root Navigation med Auth-routing

```swift
// Source: NavigationStack pattern (iOS 16+) + AuthManager
struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView()
        case .authenticating:
            ProgressView()
        case .needsOnboarding:
            OnboardingView()
        case .authenticated:
            MainTabView()
        }
    }
}
```

### Halvmodal profil-sheet (PROF-03)

```swift
// Source: presentationDetents dokumentation (iOS 16+)
struct SomeView: View {
    @State private var showProfile = false
    var user: AppUser

    var body: some View {
        Button("Visa profil") { showProfile = true }
            .sheet(isPresented: $showProfile) {
                ProfileView(user: user)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
    }
}
```

### Profilbild uppladdning till Firebase Storage

```swift
// Source: Firebase Storage + PhotosPicker dokumentation
import PhotosUI

@Observable
class OnboardingViewModel {
    var selectedPhotoItem: PhotosPickerItem?
    var profileImage: UIImage?

    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        profileImage = image
    }

    func uploadProfileImage(uid: String) async throws -> String {
        guard let image = profileImage,
              let imageData = image.jpegData(compressionQuality: 0.75) else {
            throw ProfileError.noImage
        }

        let ref = Storage.storage().reference()
            .child("profile_images/\(uid).jpg")

        let _ = try await ref.putDataAsync(imageData)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ObservableObject + @Published | @Observable (Observation framework) | iOS 17 / Swift 5.9 | Renare syntax, bättre prestanda, inga onödiga re-renders |
| PHPickerViewController UIViewRepresentable | PhotosPicker (native SwiftUI) | iOS 16 | Ingen UIViewRepresentable-boilerplate behövs |
| Manual Keychain storage | Firebase Auth inbyggd persistens | Sedan Firebase Auth v1 | Hanteras automatiskt |
| Navigation med NavigationView | NavigationStack med type-safe routing | iOS 16 | Programmatisk navigation, deeplinks, enklare state |
| CLLocationManager med delegate | CLLocationUpdate.liveUpdates() async | iOS 17 | Modernare, async/await-kompatibelt |
| GIDSignIn delegate-pattern | GIDSignIn async/await | GoogleSignIn-iOS 6+ | Renare kod utan delegate-boilerplate |
| Half-sheet UISheetPresentationController | presentationDetents SwiftUI | iOS 16 | Ingen UIKit-wrap behövs |

**Deprecated/outdated:**
- `GIDSignIn.sharedInstance()` (old ObjC-style): Ersatt av `GIDSignIn.sharedInstance` (property, ej metod)
- `user.authentication.idToken`: Ersatt av `user.idToken?.tokenString` i nya Google SDK
- `OAuthProvider.credential(withProviderID:)`: ObjC-API, använd `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)` i Swift

---

## Open Questions

1. **Facebook SDK iOS-minimum vs. Firebase-minimum**
   - What we know: Facebook iOS SDK 18.x kräver iOS 12+; Firebase iOS SDK 12.x kräver iOS 15+
   - What's unclear: Projektet väljer iOS 17 som deployment target (från STATE.md) — alla tre SDK:er är kompatibla
   - Recommendation: iOS 17 är korrekt deployment target; bekräfta på Facebook Developer Portal att SDK 18.x fungerar på iOS 17

2. **Apple Sign-In — krav vid andra third-party providers**
   - What we know: Apple ändrade sin policy i januari 2024 — Sign in with Apple är INTE längre obligatoriskt om man erbjuder tredjepartslogin, men appen ska erbjuda ett "privacy-focused" alternativ
   - What's unclear: Sign in with Apple räknas som ett sådant alternativ; med Apple + Google + Facebook uppfylls kravet
   - Recommendation: Erbjud alla tre som planerat — inget App Store-problem

3. **Firestore Security Rules för andras profiler (PROF-03)**
   - What we know: Fas 3 (vänner) behöver läsa andra användares profiler
   - What's unclear: Ska alla autentiserade användare kunna läsa alla profiler, eller bara vänner?
   - Recommendation: I Fas 1, tillåt read för alla autentiserade (`request.auth != null`) — begränsa till vänner i Fas 3 när friend-modellen är etablerad

4. **Firestore koordinatlagring i Fas 1**
   - What we know: Väderdata (Fas 2) behöver lat/long för WeatherKit-anrop
   - What's unclear: Ska koordinater sparas vid platsinmatning i Fas 1?
   - Recommendation: Ja — spara `cityLatitude`/`cityLongitude` redan i Fas 1 via MKLocalSearchCompleter → MKLocalSearch → CLPlacemark. Fas 2 kan då direkt använda koordinaterna utan ny geocoding.

---

## Sources

### Primary (HIGH confidence)
- [Firebase Apple SDK Release Notes](https://firebase.google.com/support/release-notes/ios) — version 12.10.0, iOS 15+ minimum, feb 2026
- [Firebase Auth iOS/Apple](https://firebase.google.com/docs/auth/ios/apple) — Sign in with Apple nonce-flöde
- [Firebase Auth iOS/Google](https://firebase.google.com/docs/auth/ios/google-signin) — GIDSignIn + Firebase credential
- [Firebase Auth iOS/Facebook](https://firebase.google.com/docs/auth/ios/facebook-login) — FBSDKLoginManager + Firebase credential
- [Facebook iOS SDK CHANGELOG](https://raw.githubusercontent.com/facebook/facebook-ios-sdk/main/CHANGELOG.md) — version 18.0.3, iOS 12+ minimum
- [Apple MKLocalSearchCompleter](https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter) — officiell dokumentation
- [Firebase Firestore Swift Codable](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping) — @DocumentID, @ServerTimestamp

### Secondary (MEDIUM confidence)
- [swiftsenpai.com: Sign in with Apple Firebase](https://swiftsenpai.com/development/sign-in-with-apple-firebase-auth/) — nonce-kod verifierad mot Firebase docs
- [swiftsenpai.com: Google Sign-In Firebase](https://swiftsenpai.com/development/google-sign-in-firebase-authentication/) — GIDSignIn-flöde
- [9to5Mac: Apple removes Sign in with Apple requirement](https://9to5mac.com/2024/01/27/sign-in-with-apple-rules-app-store/) — policybyte jan 2024
- [levelup.gitconnected: MKLocalSearchCompleter SwiftUI](https://levelup.gitconnected.com/implementing-address-autocomplete-using-swiftui-and-mapkit-c094d08cda24) — @Observable pattern
- [donnywals.com: presentationDetents](https://www.donnywals.com/presenting-a-partially-visible-bottom-sheet-in-swiftui-on-ios-16/) — iOS 16 half-sheet
- [GoogleSignIn-iOS releases](https://github.com/google/GoogleSignIn-iOS/releases) — version 9.1.0

### Tertiary (LOW confidence)
- GoogleSignIn-iOS 9.1.0 minimum iOS version — Swift Package Index anger iOS 12+, men exakt krav ej bekräftat mot officiell README

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Firebase 12.10.0 och Facebook SDK 18.0.3 bekräftade via officiella release notes; GoogleSignIn 9.1.0 bekräftad via GitHub releases
- Architecture: HIGH — @Observable, NavigationStack och presentationDetents är stabila iOS 17+ API:er
- Pitfalls: HIGH — nonce-kravet och Apple-namnproblemet är dokumenterade i Firebase officiella docs; AppDelegate-kravet är Standard SwiftUI-kunskap
- MKLocalSearchCompleter: MEDIUM — inga direkta begränsningar hittade, men filtreringen av city vs. address kan kräva justering

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (stabil stack, men Firebase-versioner rullar snabbt)
