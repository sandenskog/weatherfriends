# Phase 3: Kontaktimport - Context

**Gathered:** 2026-03-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Importera vänner från iOS-kontakter med AI-driven platsgissning, plus manuellt tillägg som fallback. Användaren kan snabbt fylla appen med vänner via CNContactStore och AI gissar plats baserat på adress, telefonnummer och e-post. Kontakter utan platsdata hanteras gracefully med manuell plats som fallback.

Chatt, push-notiser och sociala plattformsimport (Facebook, Instagram, Snapchat) tillhör andra faser.

</domain>

<decisions>
## Implementation Decisions

### Import-flöde
- Multi-select lista med checkboxar — användaren bockar i vilka kontakter som ska importeras
- Sökfält överst + alfabetiska sektioner med snabb-scroll (som iOS Kontakter-appen)
- Tillgänglig BÅDE i onboarding (steg 4) OCH i vänlistan (FriendListView) via "+"-knapp
- Kontakter utan platsdata visas ändå — importeras med "Okänd plats", användaren kan lägga till stad manuellt efteråt via stad-autocomplete

### AI-platsgissning UX
- Auto-accept: AI:ns förslag accepteras automatiskt vid import, sedan visas sammanfattning där användaren kan korrigera fel
- Färgkodning av konfidens: grönt = hög (adress), gult = medel (landsnummer), rött = låg/saknar data
- Redigering via befintlig stad-autocomplete (LocationService) — konsekvent med onboarding
- AI-gissning körs direkt vid import (inte som separat steg) — sömlös upplevelse med laddningsindikator

### Manuellt tillägg
- "+"-knapp i FriendListView visar meny: "Lägg till manuellt" / "Importera kontakter"
- Manuellt formulär: bara namn + stad (med autocomplete) — matchar befintlig Friend-modell
- Onboarding steg 4 utökas med "Importera från kontakter"-knapp bredvid manuellt tillägg
- Demo-vänner auto-rensas vid första riktiga vän (manuell eller import)

### Kontaktvisning
- Importlistan visar: namn, profilbild (från kontaktkortet), stad-hint (flagga/landsnummer eller "Adress finns")
- Redan tillagda kontakter visas gråmarkerade med "Redan tillagd" — transparent dubbletthantering
- Kontaktens profilbild sparas till Firebase Storage och används som photoURL på Friend-modellen

### Claude's Discretion
- Övre gräns för antal kontakter per import-batch (balans mellan AI-kostnad och UX)
- Exakt layout och spacing i import-vyn
- Laddningsindikator-design under AI-gissning
- Felhantering vid CNContactStore-nekat tillstånd
- Firebase Cloud Function-arkitektur för AI-proxyn

</decisions>

<specifics>
## Specific Ideas

- Import-listan ska kännas som iOS Kontakter-appen: sökfält + alfabetiska sektioner
- AI-gissningen ska vara "osynlig" — den körs automatiskt, användaren ser bara resultatet
- Konfidens-färgerna guidar användaren: "granska de gula/röda, resten är troligen rätt"
- Stad-autocomplete (LocationService) återanvänds konsekvent i alla vän-relaterade formulär

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LocationService` (MKLocalSearchCompleter): Stad-autocomplete med koordinater — används för manuellt tillägg och korrigering av AI-förslag
- `FriendService`: Komplett Firestore CRUD (addFriend, updateFriend, removeFriend, toggleFavorite) — sparar importerade kontakter
- `OnboardingFavoritesView` + `PendingFriend`: Formulärpattern med namn + stad — kan utökas med import-knapp
- `DemoFriendService.removeDemoFriends()`: Rensar demo-vänner — anropas vid första riktiga vän
- `Friend`-modell: displayName, photoURL, city, cityLatitude/Longitude, isFavorite, isDemo — alla fält som behövs

### Established Patterns
- `@Observable @MainActor`-mönster för services (FriendService, LocationService)
- PendingFriend-struct för temporär data → Friend-modell vid commit till Firestore
- Firestore subcollection `users/{uid}/friends/` för vändata
- LocationService.resolveLocation() → CLPlacemark med koordinater

### Integration Points
- `FriendListView`: Behöver "+"-knapp med meny (manuellt/import)
- `OnboardingFavoritesView`: Utökas med "Importera kontakter"-knapp
- `OnboardingViewModel.completeOnboarding()`: Tar FriendService som parameter — samma pattern för import
- Firebase Storage: Ny integration för profilbilder (photoURL-fältet finns redan på Friend-modellen)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-kontaktimport*
*Context gathered: 2026-03-02*
