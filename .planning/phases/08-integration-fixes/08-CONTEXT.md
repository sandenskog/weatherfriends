# Phase 8: Integration Fixes - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminera 4 kvarstående integrationsgap identifierade i v1.0 milestone audit: deep link race condition vid kall start, storage path mismatch vid kontoborttagning, fragil environment inheritance, och dokumentationsgap. Inga nya features — enbart bugfixar och cleanup.

</domain>

<decisions>
## Implementation Decisions

### Deep link race condition (INT-03/FLOW-01)
- viewModel måste vara laddad innan deep link-navigation triggas
- Bevara `openWeatherAlertFriendId` tills `viewModel.isLoading == false` — nollställ inte förrän match utförts
- Gäller både push-notis deep links och widget deep links (samma `onOpenURL`-path)
- Ingen visuell ändring — appen ska inte visa extra loading state, bara fördröja navigationen tills data finns

### Storage path mismatch (INT-01)
- `AuthManager.cleanupUserData()` (rad 196) använder `profileImages/{uid}` — ska vara `profile_images/{uid}.jpg` för att matcha `UserService.uploadProfileImage()` (rad 53)
- Ändra AuthManager till rätt path — inte UserService (UserService har korrekt path)

### Explicit environment injection (INT-02)
- Lägg till `.environment(userService)` explicit på `ImportReviewView` sheet-presentationer
- Gäller två ställen: `ContactImportView.swift` rad 100 och `OnboardingFavoritesView.swift` rad 451
- Inte funktionellt trasigt idag (SwiftUI inheritance fungerar) men skyddar mot framtida refaktorering

### Dokumentationsfix (DOC)
- Lägg till `requirements_completed: ["VIEW-02", "PUSH-02"]` i `05-02-SUMMARY.md` metadata
- Värden finns redan i `provides`-fältet — rent dokumentationsgap

### Claude's Discretion
- Exakt implementation av deep link-fördröjning (onChange vs task vs Combine)
- Om fler environment injections bör göras explicit i samma pass

</decisions>

<specifics>
## Specific Ideas

Alla 4 fixar är direkt härledda från v1.0-MILESTONE-AUDIT.md med exakta filreferenser och radnummer. Ingen tolkning behövs.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HotAndColdFriendsApp.swift`: onOpenURL-handler postar `NotificationCenter.default.post(name: .openWeatherAlert)` med friendId
- `FriendsTabView`: lyssnar på openWeatherAlert notification och navigerar — här sitter race condition

### Established Patterns
- Environment injection via `.environment()` modifier på rot-nivå i `HotAndColdFriendsApp`
- `@Environment(UserService.self)` för DI i vyer
- `viewModel.isLoading` pattern finns redan i FriendsTabView

### Integration Points
- `AuthManager.cleanupUserData()` rad 196: storage path att fixa
- `ContactImportView.swift` rad 100: sheet-presentation av ImportReviewView
- `OnboardingFavoritesView.swift` rad 451: sheet-presentation av ImportReviewView
- `05-02-SUMMARY.md`: metadata-fält att uppdatera

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-integration-fixes*
*Context gathered: 2026-03-04*
