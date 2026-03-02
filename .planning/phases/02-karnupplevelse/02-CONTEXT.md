# Phase 2: Kärnupplevelse - Context

**Gathered:** 2026-03-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Appen visar vädret hos vänner, sorterat från varmast till kallast, med live exempeldata redan vid first run. Kärnvärdet demonstrerat utan att behöva importera kontakter. Inkluderar WeatherService med cache, vädersorterad listvy, demo-data och favoriter med onboarding-steg.

</domain>

<decisions>
## Implementation Decisions

### Väderkortens design
- Kompakta rader i listan: profilbild, namn, stad, temperatur + väderikon
- Minimal info i listvy — temperatur och ikon räcker
- Tap på rad öppnar expanderad vädervy som sheet (prognos, vind, fuktighet etc.)
- Temperaturtext färgkodad: röd/orange för varmt, blå för kallt — gradient baserat på temperatur

### Demo-upplevelsen (first run)
- 8–10 fiktiva vänner med internationell mix av städer (Tokyo, Kapstaden, New York, Sydney, Stockholm etc.)
- Riktigt väder hämtas för demo-vännernas städer via WeatherKit
- Transparent markering — tydlig "Exempeldata"-indikator så användaren vet att det inte är riktiga vänner
- Manuell borttagning via en "Ta bort exempeldata"-knapp — användaren bestämmer själv
- Demo-data visas som fallback om användaren hoppar över favorit-steget i onboarding

### Favoriter & sortering
- Separat sektion "Favoriter" överst i listan med egen rubrik
- Övriga vänner listas under i en andra sektion
- Båda sektionerna sorteras varmast → kallast (temperatursortering genomgående)
- Swipe på rad för att lägga till/ta bort som favorit (iOS-standardgest)
- Max 6 favoriter — vid försök att lägga till 7:e visas meddelande: "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."

### Onboarding för favoriter
- Eget steg i befintlig onboarding-wizard (efter namn/foto/stad)
- Namn + stad-autocomplete per vän (återanvänder befintlig LocationService med MKLocalSearchCompleter)
- Valfritt steg — "Hoppa över"-knapp tillgänglig (demo-data visas istället)
- Valfritt antal vänner att lägga till, de 6 första blir automatiskt favoriter

### Claude's Discretion
- Exakt färgskala för temperaturfärgkodning (gradient-intervall)
- Design av den expanderade vädervyn (sheet-layout, vilken detaljinfo som visas)
- Demo-vännernas namn och exakta städer
- Loading states och skeletons
- Väder-ikonval (SF Symbols eller anpassade)
- Swipe-action-design (färg, ikon, animation)
- "Ta bort exempeldata"-knappens placering och design

</decisions>

<specifics>
## Specific Ideas

- Listan ska vara den primära vyn — öppna appen och direkt se vänners väder
- Ljus, minimalistisk design (konsekvent med befintlig profilvy)
- Celsius som standard

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LocationService`: Stad-autocomplete med MKLocalSearchCompleter + resolveLocation() för koordinater — återanvänds direkt i favorit-onboarding
- `AppUser`: Har redan `cityLatitude`/`cityLongitude` redo för WeatherKit-anrop
- `ProfileView`: Profilbild-rendering (AsyncImage + initialsCircle) kan återanvändas i väderkort
- `UserService`: Firestore CRUD-mönster (@Observable, async/await) — mall för nya services

### Established Patterns
- MVVM med `@Observable` och `@State private var viewModel`
- `@Environment` för dependency injection (AuthManager, UserService)
- SwiftUI sheets med `.presentationDetents` och `.presentationDragIndicator`
- Async data loading via `.task { }` modifier
- Felhantering med `LocalizedError` enums
- Svenska felmeddelanden och UI-text

### Integration Points
- `MainTabView` i AppRouter.swift är placeholder markerad "ersätts i fas 2" — här ska FriendListView in
- `AuthManager.currentUser` ger tillgång till inloggad användares stad/koordinater
- `OnboardingView` (steg-wizard) behöver utökas med favorit-steg
- `AppRouter` hanterar auth-state routing — ingen ändring behövs

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-karnupplevelse*
*Context gathered: 2026-03-02*
