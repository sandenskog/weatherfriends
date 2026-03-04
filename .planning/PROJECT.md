# Hot & Cold Friends

## What This Is

En iOS-app som visar din vänlista organiserad utifrån vädret där dina vänner befinner sig. Importera vänner från iOS-kontakter (med AI-driven platsgissning), se deras väder i realtid, och chatta med dem — med vädret som naturlig samtalsöppnare. Appen har tre vyer (sorterad lista, karta, kategorier), push-notiser, hemskärmswidget och animerade väderillustrationer.

## Core Value

Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## Requirements

### Validated

- ✓ Sign in with Apple, Google, Facebook — v1.0
- ✓ Session persistence — v1.0
- ✓ Kontoborttagning (App Store-krav) — v1.0
- ✓ Profil med namn, bild och stad — v1.0
- ✓ Visa andra användares profiler — v1.0
- ✓ Manuellt lägga till vän + kontaktimport med AI-platsgissning — v1.0
- ✓ 6 favoriter överst, favoriter vid onboarding — v1.0
- ✓ Realtidsväder med WeatherKit + 30-min cache — v1.0
- ✓ Animerade väderillustrationer — v1.0
- ✓ Vädersorterad lista, kartvy (MapKit), grupperade väderkort — v1.0
- ✓ Live exempeldata vid first run — v1.0
- ✓ 1-till-1 chatt och gruppchattar med väderreaktioner — v1.0
- ✓ Rapportera/blockera (App Store-krav) — v1.0
- ✓ Push: extremväder, daglig sammanfattning, chattmeddelande — v1.0
- ✓ iOS hemskärmswidget — v1.0

### Active

#### Current Milestone: v2.0 — Bubble Pop Design + Tech Debt

**Goal:** Implementera det kompletta Bubble Pop design systemet och åtgärda v1.0 tech debt.

**Target features:**
- Bubble Pop design system (färgpalett, typografi, komponenter, animationer)
- Custom väderikoner (SVG → SF Symbols/assets)
- Ny app-ikon och logotyp
- Empty state-illustrationer
- Baloo 2 custom font
- Temperaturzon-gradienter på avatarer, kort, widgets
- Pill-knappar med bounce-animationer
- Chattbubblor med gradient
- Väder-stickers i chatt
- Tech debt: lookupAuthUid → invite-system
- Tech debt: WeatherAlertService i SwiftUI environment
- Tech debt: Orphaned messages cleanup vid kontoborttagning

### Out of Scope

- Realtids-GPS-spårning av vänner — privacy-risk, appen handlar om väder på känd stad
- Video/röstsamtal — fokus på textchatt
- Social feed/flöde — kontaktbaserad vy, inte flödesbaserad
- Crowdsourcad väderrapportering — kräver kritisk massa
- Gamification — strider mot varm/social känsla
- Android-version — iOS-first, eventuellt Flutter/React Native
- Mörk designtema — strider mot varm, social känsla

## Context

Shipped v1.0 med 7 576 rader Swift + Firebase Cloud Functions (TypeScript).
Tech stack: SwiftUI (iOS 17+), Firebase (Auth, Firestore, Storage, Cloud Functions, FCM), WeatherKit, MapKit, WidgetKit.
AI-platsgissning via OpenAI gpt-4o-mini (Cloud Function proxy).
13 faser (inkl. 5 gap-closure), 24 planer, 29 krav satisfierade.

Design pack levererat: "Bubble Pop Design System" i `Design/friendscast-design-pack/`:
- `specs/ui-spec-and-components.html` — komplett designspec med Swift-referenskod
- `svg-icons/` — 14 väderikoner (sol, moln, regn, snö, åska m.fl.)
- `svg-ui/` — app-ikon, logotyp, empty state-illustrationer
- Typsnitt: Baloo 2 (rubriker/knappar) + Inter/SF Pro (brödtext)
- 5 temperaturzoner med gradienter: Tropical (>28°), Warm (20-28°), Cool (10-20°), Cold (0-10°), Arctic (<0°)
- 8pt spacing grid, pill-knappar, spring-animationer, konfetti, bounce-in

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native Swift/SwiftUI | Bäst prestanda och native iOS-känsla | ✓ Good |
| Firebase backend | Snabbt att komma igång, FCM-integration, social auth | ✓ Good |
| iOS Contacts istf social API-import | Facebook/Instagram/Snapchat saknar vänimport-API | ✓ Good — AI-platsgissning kompenserar |
| Apple WeatherKit | Gratis 500K anrop/mån, ingen nyckelhantering | ✓ Good |
| iOS 17+ deployment target | @Observable, async/await, CLLocationUpdate | ✓ Good |
| OpenAI via Cloud Function proxy | Skyddar API-nyckel, server-side validering | ✓ Good |
| xcodegen för projektgenerering | CLI-baserat, project.yml versionsstyrd | ✓ Good |
| Auth UID i konversationer (ej Friend.id) | Korrekt participant-matchning i chattar | ✓ Good — krävde gap-closure |
| lookupAuthUid via displayName-match | Enklaste lösningen utan invite-system | ⚠️ Revisit i v2 (ej unikt) |

## Constraints

- **Plattform**: iOS only, SwiftUI — kräver Xcode och Apple Developer Account
- **Backend**: Firebase (Blaze-plan krävs för Cloud Functions)
- **Väder-API**: Apple WeatherKit (500K gratis anrop/mån)
- **App Store**: Måste uppfylla Apples review-riktlinjer (privacy, data handling, UGC-moderering)
- **Design**: Varm, social känsla — ej minimalistisk/monokromatisk

---
*Last updated: 2026-03-04 after v2.0 milestone start*
