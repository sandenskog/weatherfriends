---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
last_updated: "2026-03-02T15:53:40Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 5
  completed_plans: 5
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-02)

**Core value:** Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.
**Current focus:** Phase 2: Kärnupplevelse

## Current Position

Phase: 2 of 6 (Kärnupplevelse)
Plan: 3 of 3 in current phase
Status: In progress
Last activity: 2026-03-02 — Plan 02-03 komplett. Onboarding-wizard utökad till 4 steg. OnboardingFavoritesView skapad med namn + stad-autocomplete. Vänner sparas till Firestore via FriendService. De 6 första markeras automatiskt som favoriter.

Progress: [████░░░░░░] 55%

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

### Pending Todos

None yet.

### Blockers/Concerns

- [Pre-fas 1]: Bekräfta Facebook SDK 17.x iOS-minimum mot Facebook Developer Portal
- [Pre-fas 1]: Besluta deployment target iOS 17 vs iOS 16 (WeatherKit-minimum) — ARCHITECTURE.md rekommenderar iOS 17
- [Pre-fas 3]: AI-platsgissningskostnad per import-session är okänd — kostnadsuppskattning behövs
- [Pre-fas 4]: Firebase Cloud Functions kräver Blaze-plan (betalplan) — kostnadsuppskattning behövs
- [Pre-fas 6]: Verifiera age-gating-formulär status i App Store Connect (Apple deadline januari 2026)

## Session Continuity

Last session: 2026-03-02
Stopped at: Plan 02-02 tasks klara (FriendListView + AppRouter). Awaiting checkpoint Task 3 (manuell verifiering på device).
Resume file: None
