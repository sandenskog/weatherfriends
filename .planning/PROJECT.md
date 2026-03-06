# Hot & Cold Friends

## What This Is

En iOS-app som visar din vänlista organiserad utifrån vädret där dina vänner befinner sig. Importera vänner från iOS-kontakter (med AI-driven platsgissning) eller via invite-länk, se deras väder i realtid, och chatta med dem — med vädret som naturlig samtalsöppnare. Appen har tre vyer (sorterad lista, karta, kategorier), push-notiser, hemskärmswidget och ett komplett Bubble Pop design system med temperaturzon-gradienter, spring-animationer och custom väderikoner.

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
- ✓ Bubble Pop design system (färgpalett, typografi, spacing, shadows, 5 temperaturzoner) — v2.0
- ✓ Custom väderikoner (14 SVG), app-ikon, logotyp, empty state-illustrationer — v2.0
- ✓ AvatarView med temperaturzon-gradient i alla vyer — v2.0
- ✓ BubblePopButton med pill-form, gradient och bounce — v2.0
- ✓ Chattbubblor med gradient och asymmetrisk border radius — v2.0
- ✓ Väder-stickers i chatt — v2.0
- ✓ Tab-switcher med pill-form, glow och scale-animation — v2.0
- ✓ Widgets med temperaturzon-gradient bakgrund — v2.0
- ✓ Spring-animationer (hjärt-pop, konfetti, sticker-bounce, tab-glow, cloud refresh) — v2.0
- ✓ Reduce Motion-stöd i alla animationer — v2.0
- ✓ Invite-länk-system (ersätter displayName-match) — v2.0
- ✓ WeatherAlertService i SwiftUI environment — v2.0
- ✓ Robust kontoborttagning med orphaned messages cleanup — v2.0

### Active

## Current Milestone: v3.0 Virality & Polish

**Goal:** Gör appen visuellt komplett, bygg invite-upplevelse som driver viralitet, och skapa delnings- och engagemangs-loopar.

**Target features:**
- Visual polish — full adoption av BubblePopTypography/Spacing/CornerRadius i alla vyer
- Invite-upplevelse — enklare flöde, visuellt tilltalande, incitament att bjuda in
- Delningsbara väderkort — snygga bilder att dela på Instagram/iMessage
- In-app engagement loops — nudges, reaktioner och triggers som driver interaktion

### Out of Scope

- Realtids-GPS-spårning av vänner — privacy-risk, appen handlar om väder på känd stad
- Video/röstsamtal — fokus på textchatt
- Social feed/flöde — kontaktbaserad vy, inte flödesbaserad
- Crowdsourcad väderrapportering — kräver kritisk massa
- Gamification — strider mot varm/social känsla
- Android-version — iOS-first, eventuellt Flutter/React Native
- Mörk designtema — strider mot varm, social känsla

## Context

Shipped v2.0 med 8 846 rader Swift + Firebase Cloud Functions (TypeScript).
Tech stack: SwiftUI (iOS 17+), Firebase (Auth, Firestore, Storage, Cloud Functions, FCM), WeatherKit, MapKit, WidgetKit.
AI-platsgissning via OpenAI gpt-4o-mini (Cloud Function proxy).
2 milestones shipped: v1.0 (13 faser, 24 planer) + v2.0 (7 faser, 13 planer). Totalt 55 krav satisfierade.

Bubble Pop Design System fullt implementerat:
- 5 temperaturzoner med gradienter: Tropical (>28°), Warm (20-28°), Cool (10-20°), Cold (0-10°), Arctic (<0°)
- Baloo 2 typografi, 8pt spacing grid, shadow-skala
- 14 custom SVG väderikoner, app-ikon, logotyp, empty state-illustrationer
- AvatarView, BubblePopButton, chattbubblor med gradient, tab-switcher med glow
- Spring-animationer med Reduce Motion-stöd
- Invite-länk-system för vänförfrågningar

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
| lookupAuthUid via displayName-match | Enklaste lösningen utan invite-system | ✓ Replaced — invite-länk i v2.0 |
| Invite-länk med 12-char UUID-prefix | Unikt, delbart, deep-link-kompatibelt | ✓ Good — v2.0 |
| Bubble Pop Design System | Varm, social känsla med temperaturzoner | ✓ Good — v2.0 |
| AvatarView som enda avatar-komponent | Konsekvent gradient-avatarer i alla vyer | ✓ Good — v2.0 |
| MotionReducer pattern | Centralt Reduce Motion-stöd för alla animationer | ✓ Good — v2.0 |

## Constraints

- **Plattform**: iOS only, SwiftUI — kräver Xcode och Apple Developer Account
- **Backend**: Firebase (Blaze-plan krävs för Cloud Functions)
- **Väder-API**: Apple WeatherKit (500K gratis anrop/mån)
- **App Store**: Måste uppfylla Apples review-riktlinjer (privacy, data handling, UGC-moderering)
- **Design**: Varm, social känsla — ej minimalistisk/monokromatisk

---
*Last updated: 2026-03-06 after v3.0 milestone started*
