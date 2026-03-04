---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
last_updated: "2026-03-04T18:04:57.518Z"
progress:
  total_phases: 13
  completed_phases: 13
  total_plans: 24
  completed_plans: 24
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-02)

**Core value:** Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.
**Current focus:** Phase 6: Polish och App Store

## Current Position

Phase: 08-integration-fixes
Plan: 1 of 1 in current phase
Status: Plan 01 Complete
Last activity: 2026-03-04 — Plan 08-01 komplett. Deep link race condition fixad (dubbel onChange), storage path normaliserad (profile_images/{uid}.jpg), explicit environment injection på ImportReviewView-sheets.

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 6 min
- Total execution time: 12 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation | 1 | 7 min | 7 min |
| 2. Kärnupplevelse | 2 | 9 min | 4.5 min |

**Recent Trend:**
- Last 5 plans: 6 min
- Trend: n/a (för lite data)

*Updated after each plan completion*
| Phase 01-foundation P02 | 16 | 2 tasks | 4 files |
| Phase 01-foundation P03 | 10 | 2 tasks | 12 files |
| Phase 02-karnupplevelse P01 | 4 | 2 tasks | 8 files |
| Phase 02-karnupplevelse P02 | 5 | 2 tasks | 5 files |
| Phase 02-karnupplevelse P03 | 5 | 2 tasks | 4 files |
| Phase 02-karnupplevelse P04 | 3 | 2 tasks | 3 files |
| Phase 03-kontaktimport P01 | 6 | 2 tasks | 7 files |
| Phase 03-kontaktimport P02 | 5 | 2 tasks | 8 files |
| Phase 03-kontaktimport P02 | 15 | 3 tasks | 8 files |
| Phase 04-chatt-och-push P01 | 3 | 2 tasks | 10 files |
| Phase 04-chatt-och-push P02 | 2 | 2 tasks | 8 files |
| Phase 04-chatt-och-push P03 | 5 | 2 tasks | 3 files |
| Phase 04-chatt-och-push P04 | 3 | 2 tasks | 6 files |
| Phase 04.1-onboarding-kontaktimport P01 | 4 | 2 tasks | 5 files |
| Phase 04.2-chatt-uid-mismatch P01 | 6 | 2 tasks | 2 files |
| Phase 04.3-push-deeplink-techdebt P01 | 2 | 2 tasks | 8 files |
| Phase 04.4-authuid-population P01 | 2 | 2 tasks | 5 files |
| Phase 04.5-vanprofil-docs P01 | 4 | 2 tasks | 4 files |
| Phase 05-utokade-vyer P01 | 4 | 2 tasks | 5 files |
| Phase 05-utokade-vyer P02 | 3 | 2 tasks | 4 files |
| Phase 06-polish-app-store P02 | 5 | 1 tasks | 11 files |
| Phase 06-polish-app-store P01 | 7 | 2 tasks | 7 files |
| Phase 08-integration-fixes P01 | 5 | 2 tasks | 5 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Research]: Social API-vänimport (Facebook/Instagram/Snapchat) är omöjlig — ersätts med iOS Contacts + AI-platsgissning
- [Research]: Firebase väljs över Supabase (lägre latens för chatt, FCM-integration, social auth i samma SDK)
- [Research]: Apple WeatherKit väljs som väder-API (gratis 500K anrop/mån, inget nyckelhantering)
- [Research]: iOS 17+ sätts som deployment target för att kunna använda @Observable fullt ut
- [Research]: OpenAI-anrop MÅSTE gå via Firebase Cloud Function proxy — aldrig direkt från iOS-appen
- [01-01]: FirebaseFirestoreSwift är integrerat i FirebaseFirestore från SDK 11.x — ej separat SPM-paket
- [01-01]: nonisolated(unsafe) används för listenerHandle i AuthManager för deinit-kompatibilitet
- [01-01]: xcodegen valdes för Xcode-projektgenerering via CLI (project.yml versionsstyrd)
- [Phase 01-02]: NSObject-arv krävs i AuthManager för ASAuthorizationControllerDelegate/PresentationContextProviding
- [Phase 01-02]: xcodegen måste köras om när nya Swift-filer skapas — projekt plockar inte upp dem automatiskt
- [Phase 01-02]: Facebook-cancelled hanteras tyst i LoginViewModel — inget felmeddelande till användaren
- [Phase 01-03]: OnboardingViewModel skriver direkt till Firestore via .document(uid).setData() — UserService.createUserProfile kräver @DocumentID som inte kan sättas vid skapande
- [Phase 01-03]: CLLocationUpdate.liveUpdates() (iOS 17+) används för GPS — async-stream-baserad API, ingen delegate
- [Phase 01-03]: UserService injiceras som @Environment i appens rot (HotAndColdFriendsApp) för enkel tillgång i hela hierarkin
- [Phase 01-03]: FirebaseApp.configure() måste anropas i App.init() — inte i body — för att undvika SIGABRT-krasch vid cold start
- [Phase 01-03]: LocationService sorterar geo-sökresultat efter location score för att prioritera städer framför gator och adresser
- [Phase 02-01]: WeatherKit-metoderna heter .hourly/.daily (inte .hourlyForecast/.dailyForecast) i WeatherKit SDK
- [Phase 02-01]: Firestore count-aggregation snapshot.count är NSNumber — använd .intValue istället för Int(truncatingIfNeeded:)
- [Phase 02-01]: AppWeatherService döps (ej WeatherService) för att undvika namnkollision med WeatherKit.WeatherService
- [Phase 02-02]: Color.temperatureColor placerades som extension i FriendRowView.swift — ingen extra fil behövdes
- [Phase 02-02]: Logga ut-knapp i .topBarLeading i FriendListView — mer direkt åtkomst än att gömma i profil-sheet
- [Phase 02-02]: WeatherDetailSheet tar @Environment(AppWeatherService.self) och injiceras explicit vid sheet-presentering
- [Phase 02-03]: PendingFriend-struct definieras inuti OnboardingFavoritesView.swift — ingen separat fil behövs för lokalt scoped struct
- [Phase 02-03]: completeOnboarding() tar FriendService som parameter för att hålla konsekvent injektionsmönster
- [Phase 02-03]: Forecast<DayWeather>? konverteras till [DayWeather] via .map { Array($0) } ?? [] (WeatherKit-typfix)
- [Phase 02-04]: WTHR-02 (animerade väderillustrationer) tillhör Phase 6 — inte Phase 2 — och avmarkerades som completed i REQUIREMENTS.md
- [Phase 03-01]: nonisolated används på CNContactStore och static keysToFetch i ContactImportService — krävs för Swift 6-kompatibel Task.detached
- [Phase 03-01]: ContactImportOnboardingWrapper som privat struct i OnboardingFavoritesView — onboarding har inget uid, importerar som PendingFriend istället för Firestore
- [Phase 03-02]: Kontakter med fullständig adress returneras direkt med high confidence — sparar OpenAI-tokens
- [Phase 03-02]: defineSecret('OPENAI_API_KEY') används istället för deprecated functions.config() — modern Firebase v2 API
- [Phase 03-02]: saveReviewedContacts() är primärmetod för kontaktimport med stad/koordinater — saveImportedContacts() behålls som legacy
- [Phase 03-02]: Kontakter med fullständig adress returneras direkt med high confidence — sparar OpenAI-tokens
- [Phase 03-02]: defineSecret('OPENAI_API_KEY') används i stället för deprecated functions.config() — modern Firebase v2 API
- [Phase 03-02]: saveReviewedContacts() är primärmetod för kontaktimport med stad/koordinater — saveImportedContacts() behålls som legacy
- [Phase 04-01]: ConversationListView skapas som placeholder för kompilering i Plan 04-01 — Plan 04-02 implementerar fullt
- [Phase 04-01]: Deterministiskt konversations-ID: sorted UIDs joined med _ — idempotent getOrCreateDirectConversation
- [Phase 04-01]: Push deep link via NotificationCenter (.openChat) — undviker StateObject-komplikationer i AppDelegate
- [Phase 04-01]: registerForPushNotifications() anropas via .task{} i WindowGroup — säker timing efter Firebase-init
- [Phase 04-02]: NavigationPath istallet for @State path: stodjer bade deeplink (openConversationId) och programmatisk navigation
- [Phase 04-02]: @Bindable var vm = viewModel i body — kravs for @Observable binding-stod i SwiftUI
- [Phase 04-02]: Friend.id som pseudo-uid i konversationsdeltagare — undviker uid-falt i Friend-modellen
- [Phase 04-03]: weatherAlertScheduler implementeras som placeholder i v1 — full WeatherKit-integration kräver iOS-klienten som sätter hasActiveAlert i Firestore
- [Phase 04-03]: Alternativ A (iOS-klient sätter hasActiveAlert) väljs över Alternativ B (Cloud Function anropar WeatherKit REST API) — undviker JWT-hantering med .p8-nyckel i Cloud Functions
- [Phase 04-03]: APNs Authentication Key laddas upp med Production-environment — säkerställer push-leverans för alla iOS-builds
- [Phase 04-04]: WeatherAlertService är MainActor men ej @Observable — bakgrundstjänst behöver ingen UI-binding
- [Phase 04-04]: onDocumentUpdated triggas vid varje Firestore-uppdatering — false-to-true-kontroll krävs för att undvika duplicerade notiser
- [Phase 04-04]: lastAlertSentAt sätts EFTER lyckad FCM-leverans — rate-limiting hoppar över om push misslyckats
- [Phase 04-04]: weatherAlertScheduler rensar stale alerts (>24h) som komplement till iOS-klienten
- [Phase 04.1-01]: ImportReviewMode enum (.standard/.onboarding) valts for en vy som hanterar bada flöden med mode-switch i saveAll() — undviker kod-duplicering
- [Phase 04.1-01]: CLGeocoder körs sekventiellt med ny instans per anrop i buildReviewItems() — API är ej thread-safe för parallella anrop
- [Phase 04.2-chatt-uid-mismatch]: authUid är String? (optional) — befintliga dokument och demo-vänner saknar fältet och avkodas som nil utan krasch
- [Phase 04.2-chatt-uid-mismatch]: Konversationsdeltagare identifieras alltid med Firebase Auth UID — aldrig Firestore doc-ID
- [Phase 04.3-01]: openWeatherAlert-deep-link foljer exakt samma NotificationCenter-monster som openChat — undviker StateObject-komplikationer i AppDelegate
- [Phase 04.3-01]: fcmToken laggs till som optional Codable-property i AppUser — Codable hoppar over nil-optionals sa befintliga dokument utan fcmToken avkodas utan krasch
- [Phase 04.3-01]: Cold start deep link stods ej i v1 — om vanlistan inte ar laddad nar push-tap sker, ignoreras det tyst (samma beslut som chat-deep-link)
- [Phase 04.3-01]: saveImportedContacts (legacy) och uploadContactPhoto borttagna helt — ersatta av saveReviewedContacts i plan 03-02
- [Phase 04.4-authuid-population]: lookupAuthUid anvander try? (ej throws) — natverk- och timeout-fel returnerar nil utan att blockera Friend-skapande
- [Phase 04.4-authuid-population]: ContactImportService.saveReviewedContacts utokad med userService-parameter — konsekvent med service-injection via parameter (ej @Environment)
- [Phase 04.5-vanprofil-docs]: FriendProfileView tar Friend direkt — all data i modellen, inga nätverksanrop behövs
- [Phase 04.5-vanprofil-docs]: .buttonStyle(.plain) krävs för tappbar profilsektion i sheet — undviker blå tint-färg på text
- [Phase 04.5-vanprofil-docs]: Stackade sheets fungerar korrekt iOS 17+ — WeatherDetailSheet kan presentera FriendProfileView
- [Phase 05-01]: FriendsTabView äger FriendListViewModel — data laddas en gång och delas med karta och kategorier via parametrar
- [Phase 05-01]: UIImage-cache i FriendMapViewModel — undviker AsyncImage-renderingsproblem i MapKit Annotation-closure
- [Phase 05-01]: FriendListView refaktorerad till dum vy med parametrar (viewModel, uid, services) — alla toolbar/sheets lyfts till FriendsTabView
- [Phase 05-01]: MainTabView ersätter NavigationStack-wrapping med FriendsTabView som hanterar NavigationStack internt
- [Phase 05-02]: WeatherCategory.allCases ordning tropical first (varmast) till arctic sist (kallast) — matchar FriendListView sortering
- [Phase 05-02]: DailyWeatherNotificationService är @MainActor men ej @Observable — bakgrundstjänst utan UI-binding (samma mönster som WeatherAlertService)
- [Phase 05-02]: schedule() anropas i .task{} efter viewModel.load() — enklare än onChange(of: isLoading)
- [Phase 06-polish-app-store]: WidgetFriendEntry är ren Codable-struct — from(friendWeather:) flyttades till FriendListViewModel för att undvika kompilationsfel i widget-target
- [Phase 06-polish-app-store]: Profilbilder exkluderas från widget v1 — AsyncImage fungerar ej i WidgetKit, initialer visas istället
- [Phase 06-polish-app-store]: Widget deep links återanvänder .openWeatherAlert Notification.Name (AppRouter) — navigerar till väderdetalj utan ny NotificationCenter-hantering
- [Phase 06-01]: WeatherAnimationView visas som 40x40-ring bakom profilbild (34x34) i ZStack — animation syns som subtil levande ram
- [Phase 06-01]: WidgetFriendEntry+AppExtension.swift skapad som app-only extension — from(friendWeather:) kräver FriendWeather som ej finns i widget-target
- [Phase 06-01]: cleanupUserData körs FÖRE user.delete() — data raderas även vid timing-kantfall
- [Phase 06-01]: revokeAppleToken() kallas före user.delete() för Apple-användare — Apples App Store-krav
- [Phase 07-01]: UserService injiceras som parameter till viewModel-metoder (ej @Environment direkt i ViewModel) — konsekvent med hela appens mönster
- [Phase 07-01]: WidgetFriendEntry+AppExtension.swift raderas — from(friendWeather:) anropades aldrig från annan fil (verifierat med grep)
- [Phase 08-01]: Dubbel onChange används istället för extra @State loading-flag — ren lösning utan visuell ändring
- [Phase 08-01]: profile_images/{uid}.jpg matchar UserService.uploadProfileImage exakt — storage path normaliserad
- [Phase 08-01]: @Environment(UserService.self) läggs explicit på varje sheet som presenterar ImportReviewView — ingen fragil inheritance-kedja

### Pending Todos

None yet.

### Blockers/Concerns

- [Pre-fas 1]: Bekräfta Facebook SDK 17.x iOS-minimum mot Facebook Developer Portal
- [Pre-fas 1]: Besluta deployment target iOS 17 vs iOS 16 (WeatherKit-minimum) — ARCHITECTURE.md rekommenderar iOS 17
- [Pre-fas 3]: AI-platsgissningskostnad per import-session är okänd — kostnadsuppskattning behövs
- [Pre-fas 4]: Firebase Cloud Functions kräver Blaze-plan (betalplan) — kostnadsuppskattning behövs
- [Pre-fas 6]: Verifiera age-gating-formulär status i App Store Connect (Apple deadline januari 2026)

## Session Continuity

Last session: 2026-03-04
Stopped at: Completed 08-integration-fixes-01-PLAN.md. Deep link race condition, storage path mismatch, explicit environment injection och dokumentationsfix åtgärdade. Alla v1.0 integrationsgap stängda.
Resume file: None
