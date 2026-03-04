# Phase 8: Integration Fixes (Gap Closure) - Research

**Researched:** 2026-03-04
**Domain:** SwiftUI deep link timing, Firebase Storage path conventions, SwiftUI environment injection
**Confidence:** HIGH

## Summary

Phase 8 stänger fyra väldefinierade integrationsgap från v1.0 milestone-auditen. Alla fyra fixar är kirurgiska engångsändringar i befintliga filer — inga nya filer, inga nya beroenden, inga arkitekturförändringar. Koden är redan inspekterad och exakta radnummer är kända från 08-CONTEXT.md och auditen.

Den tekniskt svåraste delen är INT-03/FLOW-01 (deep link race condition), eftersom SwiftUI:s `onChange(of:)` triggas synkront vid state-ändring men `viewModel.load()` är asynkron. Fördröjningslogiken måste bevara `openWeatherAlertFriendId` tills `viewModel.isLoading == false`, vilket kräver ett villkor i `onChange` eller ett separerat `onChange`-observer för `isLoading`. De övriga tre fixarna är triviala enradsändringar.

Den enda discretion-frågan gäller exakt implementation av deep link-fördröjningen. Koden i FriendsTabView har redan `viewModel.isLoading` tillgänglig och använder `onChange(of:)` på `openWeatherAlertFriendId` — det naturliga mönstret är att lägga till ett second `onChange(of:)` på `viewModel.isLoading` som triggar navigation när loading slutar och ett väntande friendId finns.

**Primary recommendation:** Implementera alla fyra fixes i en enda plan (08-01). Fixarna är oberoende av varandra och kan göras i valfri ordning inom planen.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Deep link race condition (INT-03/FLOW-01):**
- viewModel måste vara laddad innan deep link-navigation triggas
- Bevara `openWeatherAlertFriendId` tills `viewModel.isLoading == false` — nollställ inte förrän match utförts
- Gäller både push-notis deep links och widget deep links (samma `onOpenURL`-path)
- Ingen visuell ändring — appen ska inte visa extra loading state, bara fördröja navigationen tills data finns

**Storage path mismatch (INT-01):**
- `AuthManager.cleanupUserData()` (rad 196) använder `profileImages/{uid}` — ska vara `profile_images/{uid}.jpg` för att matcha `UserService.uploadProfileImage()` (rad 53)
- Ändra AuthManager till rätt path — inte UserService (UserService har korrekt path)

**Explicit environment injection (INT-02):**
- Lägg till `.environment(userService)` explicit på `ImportReviewView` sheet-presentationer
- Gäller två ställen: `ContactImportView.swift` rad 100 och `OnboardingFavoritesView.swift` rad 451
- Inte funktionellt trasigt idag (SwiftUI inheritance fungerar) men skyddar mot framtida refaktorering

**Dokumentationsfix (DOC):**
- Lägg till `requirements_completed: ["VIEW-02", "PUSH-02"]` i `05-02-SUMMARY.md` metadata
- Värden finns redan i `provides`-fältet — rent dokumentationsgap

### Claude's Discretion
- Exakt implementation av deep link-fördröjning (onChange vs task vs Combine)
- Om fler environment injections bör göras explicit i samma pass

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PUSH-01 | Push-notis vid extremväder hos vän | Deep link race condition fix (INT-03/FLOW-01) säkerställer att push-notis tap navigerar korrekt även vid kall app-start |
| WDGT-01 | iOS hemskärmswidget visar favoriters väder | Samma deep link fix täcker widget URL-scheme deep links via samma `onOpenURL`-handler |
| AUTH-05 | Användare kan radera sitt konto | Storage path fix (INT-01) säkerställer att profilbild raderas korrekt vid kontoborttagning |
| FRND-02 | Användare kan importera vänner från iOS-kontakter | Explicit environment injection (INT-02) på ImportReviewView gör flödet robust mot framtida refaktorering |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI-ramverk | Befintlig stack, `onChange(of:)` two-argument form används redan i projektet |
| Firebase Storage | SDK 11.x | Cloud storage för profilbilder | Befintlig stack — `Storage.storage().reference()` används redan |

### Supporting
Inga nya bibliotek tillkommer i denna fas.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `onChange(of: viewModel.isLoading)` | `.task(id: viewModel.isLoading)` | task(id:) avbryter och återstartar vid varje ändring — overkill för enkel state-check |
| `onChange(of: viewModel.isLoading)` | Combine-publisher | Combine kräver `@State private var cancellables` — onödigt tungt för ett enkelt fall |

**Installation:** Inga nya paketberoenden.

## Architecture Patterns

### Recommended Project Structure
Inga nya filer skapas. Alla ändringar görs i befintliga filer:
```
HotAndColdFriends/
├── Core/Auth/AuthManager.swift          # INT-01: rad 196 — storage path
├── Features/FriendList/FriendsTabView.swift  # INT-03/FLOW-01: deep link fördröjning
├── Features/ContactImport/ContactImportView.swift  # INT-02: rad 99-109 — explicit env
├── Features/Onboarding/OnboardingFavoritesView.swift  # INT-02: rad 450-461 — explicit env
.planning/phases/05-utokade-vyer/05-02-SUMMARY.md  # DOC: requirements_completed
```

### Pattern 1: Deep Link Race Condition Fix — onChange på isLoading

**What:** Lägg till ett andra `onChange`-observer i FriendsTabView som triggar navigation när `viewModel.isLoading` går från `true` till `false` och ett väntande friendId finns.

**When to use:** Kall app-start — `viewModel.load()` hinner inte slutföra innan `openWeatherAlertFriendId` sätts av `onReceive`-lyssnaren i AppRouter.

**Nuvarande kod (FriendsTabView.swift rad 153-160):**
```swift
// NUVARANDE — nollställer oavsett om match hittades eller ej
.onChange(of: openWeatherAlertFriendId) { _, friendId in
    guard let friendId else { return }
    let all = viewModel.favorites + viewModel.others
    if let fw = all.first(where: { $0.friend.id == friendId }) {
        selectedFriendWeather = fw
    }
    openWeatherAlertFriendId = nil  // nollställs alltid — bug vid kall start
}
```

**Rekommenderad fix (diskretionell — onChange på isLoading):**
```swift
// FIX — bevara friendId tills match kan utföras
.onChange(of: openWeatherAlertFriendId) { _, friendId in
    guard let friendId else { return }
    // Vänta om viewModel fortfarande laddar — onChange(of: isLoading) tar vid
    guard !viewModel.isLoading else { return }
    let all = viewModel.favorites + viewModel.others
    if let fw = all.first(where: { $0.friend.id == friendId }) {
        selectedFriendWeather = fw
        openWeatherAlertFriendId = nil
    }
    // Om ingen match — nollställ ändå (ogiltig id)
    if all.first(where: { $0.friend.id == friendId }) == nil {
        openWeatherAlertFriendId = nil
    }
}
.onChange(of: viewModel.isLoading) { _, isLoading in
    // När loading slutar — kontrollera om ett väntande deep link-id finns
    guard !isLoading, let friendId = openWeatherAlertFriendId else { return }
    let all = viewModel.favorites + viewModel.others
    if let fw = all.first(where: { $0.friend.id == friendId }) {
        selectedFriendWeather = fw
    }
    openWeatherAlertFriendId = nil
}
```

**Alternativ — enklare variant (om Claude föredrar):**
```swift
// Kombinera logiken: om loading pågår, gör ingenting alls — isLoading-observer tar vid
.onChange(of: openWeatherAlertFriendId) { _, friendId in
    guard let friendId, !viewModel.isLoading else { return }
    let all = viewModel.favorites + viewModel.others
    selectedFriendWeather = all.first(where: { $0.friend.id == friendId })
    openWeatherAlertFriendId = nil
}
.onChange(of: viewModel.isLoading) { _, isLoading in
    guard !isLoading, let friendId = openWeatherAlertFriendId else { return }
    let all = viewModel.favorites + viewModel.others
    selectedFriendWeather = all.first(where: { $0.friend.id == friendId })
    openWeatherAlertFriendId = nil
}
```

### Pattern 2: Storage Path Fix (INT-01)

**What:** Enradsändring i `AuthManager.cleanupUserData()` rad 196.

**Nuvarande (fel):**
```swift
let storageRef = Storage.storage().reference().child("profileImages/\(uid)")
try? await storageRef.delete()
```

**Fix:**
```swift
let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
try? await storageRef.delete()
```

Path-konventionen matchar `UserService.uploadProfileImage()` (rad 53):
```swift
let ref = storage.reference().child("profile_images/\(uid).jpg")
```

### Pattern 3: Explicit Environment Injection (INT-02)

**What:** Lägg till `.environment(userService)` modifier på `ImportReviewView`-sheets.

`ImportReviewView` deklarerar `@Environment(UserService.self) private var userService` på rad 36. SwiftUI kräver att UserService finns i environment-kedjan. Det finns idag via implicit inheritance från `HotAndColdFriendsApp`, men explicitet gör det robust.

**ContactImportView.swift rad 99-109:**
```swift
// NUVARANDE
.sheet(isPresented: $showReview) {
    ImportReviewView(
        mode: .standard(uid: uid, friendService: friendService),
        contacts: selectedContacts,
        locationGuesses: locationGuesses,
        contactImportService: contactImportService
    ) {
        onImported()
        dismiss()
    }
}

// FIX — lägg till .environment(userService)
```

OBS: `ContactImportView` måste exponera `userService` via `@Environment(UserService.self) private var userService` för att kunna vidarebefordra den till sheet. Kontrollera om den redan finns — om inte, lägg till.

**OnboardingFavoritesView.swift rad 450-461:**
```swift
// NUVARANDE
.sheet(isPresented: $showReview) {
    ImportReviewView(
        mode: .onboarding { newPending in
            pendingFriends.append(contentsOf: newPending)
        },
        contacts: selectedContacts,
        locationGuesses: locationGuesses,
        contactImportService: contactImportService
    ) {
        dismiss()
    }
}
// FIX — lägg till .environment(userService)
```

### Pattern 4: Dokumentationsfix (DOC)

**What:** Uppdatera YAML-frontmatter i `05-02-SUMMARY.md` — lägg till `requirements_completed`-fält.

**Nuvarande 05-02-SUMMARY.md frontmatter (saknar requirements_completed):**
```yaml
dependency_graph:
  requires: ["05-01"]
  provides: ["VIEW-02", "PUSH-02"]
```

**Fix — lägg till under befintlig `requirements:`-sektion:**
```yaml
requirements:
  - VIEW-02
  - PUSH-02
```

Fältet `requirements` finns redan på rad 31-33 i 05-02-SUMMARY.md (verifierat). Det som saknas är att audit-verktyget letar efter `requirements_completed` som separat fält. Lägg till:
```yaml
requirements_completed:
  - VIEW-02
  - PUSH-02
```

### Anti-Patterns to Avoid

- **Nollställ openWeatherAlertFriendId för tidigt:** Nollställning måste ske EFTER match (eller när viewModel är klar och ingen match hittades) — aldrig ovillkorligt vid enter i onChange.
- **Lägg till extra loading UI:** Beslutet är att inte visa extra loading state — appen ska bara vänta tyst.
- **Ändra UserService.uploadProfileImage():** UserService har rätt path. Ändra bara AuthManager.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deep link retry-logik | Custom timer/polling | `onChange(of: viewModel.isLoading)` | SwiftUI state-observers är deterministiska — loading state-ändringen är den naturliga trigger-punkten |
| Storage path-validering | Assertion/test | Direkt sträng-fix | Pathen är statisk och välkänd — ingen generell lösning behövs |

## Common Pitfalls

### Pitfall 1: onChange nollställer id innan viewModel laddat klart
**What goes wrong:** Om `openWeatherAlertFriendId = nil` sker ovillkorligt i `onChange(of: openWeatherAlertFriendId)`, förloras idét permanent vid kall start — ingen andra chans.
**Why it happens:** Ursprungskoden nollställde alltid som sista steg, oavsett om match hittades.
**How to avoid:** Nollställ bara när antingen (a) match utförts, eller (b) viewModel är klar och ingen match finns.
**Warning signs:** Deep link-navigation fungerar vid varm app-start men inte vid kall start.

### Pitfall 2: ContactImportView saknar @Environment(UserService.self)
**What goes wrong:** Om ContactImportView inte har UserService i sin environment kan den inte vidarebefordra den via `.environment(userService)` på sheet.
**Why it happens:** ContactImportView tar idag `uid` och `friendService` som parameters men injicerar inte UserService explicit.
**How to avoid:** Kontrollera ContactImportView — om `@Environment(UserService.self)` saknas, lägg till det innan `.environment(userService)` läggs på sheet.
**Warning signs:** Kompileringsfel "type 'UserService' has no member" eller runtime crash med "No observable of type UserService found".

### Pitfall 3: Fel YAML-fält i 05-02-SUMMARY.md
**What goes wrong:** Om `requirements_completed` läggs under fel rubrik eller med fel indragning, parsar audit-verktyget det inte.
**Why it happens:** YAML är indragnings-känsligt.
**How to avoid:** Lägg `requirements_completed` på toppnivå i frontmatter-blocket (ej nestlat under `dependency_graph`).

### Pitfall 4: Storage-sökväg med trailing slash istället för .jpg
**What goes wrong:** Firebase Storage `.delete()` misslyckas tyst (try?) om sökvägen inte matchar exakt. Ändringen måste vara `profile_images/{uid}.jpg` (med .jpg-suffix och underscore).
**Why it happens:** Original-koden använde camelCase `profileImages` utan suffix.
**How to avoid:** Kopiera path-strängen exakt från UserService.swift rad 53: `"profile_images/\(uid).jpg"`.

## Code Examples

### FriendsTabView — exakt befintlig onChange (att ersätta)
```swift
// Källa: FriendsTabView.swift rad 153-160
.onChange(of: openWeatherAlertFriendId) { _, friendId in
    guard let friendId else { return }
    let all = viewModel.favorites + viewModel.others
    if let fw = all.first(where: { $0.friend.id == friendId }) {
        selectedFriendWeather = fw
    }
    openWeatherAlertFriendId = nil
}
```

### AuthManager — exakt befintlig rad (att ändra)
```swift
// Källa: AuthManager.swift rad 196
let storageRef = Storage.storage().reference().child("profileImages/\(uid)")
try? await storageRef.delete()
```

### UserService — referens-path (korrekt, ej ändra)
```swift
// Källa: UserService.swift rad 53
let ref = storage.reference().child("profile_images/\(uid).jpg")
```

### ContactImportView — sheet-presentation (att utöka)
```swift
// Källa: ContactImportView.swift rad 99-109
.sheet(isPresented: $showReview) {
    ImportReviewView(
        mode: .standard(uid: uid, friendService: friendService),
        contacts: selectedContacts,
        locationGuesses: locationGuesses,
        contactImportService: contactImportService
    ) {
        onImported()
        dismiss()
    }
}
```

### ImportReviewView — @Environment-deklaration
```swift
// Källa: ImportReviewView.swift rad 36
@Environment(UserService.self) private var userService
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `onChange(of:perform:)` single-arg | `onChange(of:) { old, new in }` two-arg | iOS 17 | Two-arg form används redan i projektet — ingen ändring behövs |

**Deprecated/outdated:**
- Inget relevant för denna fas.

## Open Questions

1. **Har ContactImportView redan @Environment(UserService.self)?**
   - What we know: Vyn tar `uid` och `friendService` som init-parametrar. UserService injiceras inte explicit synligt i filen (kontrollerat).
   - What's unclear: Om `@Environment(UserService.self)` behöver läggas till i ContactImportView för att `.environment(userService)` ska kunna vidarebefordras.
   - Recommendation: Planner ska lägga till `@Environment(UserService.self) private var userService` i ContactImportView som del av INT-02-uppgiften — även om det i teorin kan finnas via inheritance, krävs explicit property för att kunna referera till det i `.environment()`-callsiten.

2. **Ska requirements_completed läggas till som nytt fält eller är det ett rename av requirements?**
   - What we know: `requirements` finns redan i 05-02-SUMMARY.md rad 31-33 med värdena VIEW-02 och PUSH-02. Audit letar specifikt efter `requirements_completed`.
   - What's unclear: Om audit-verktyget accepterar enbart `requirements` eller kräver `requirements_completed`.
   - Recommendation: Lägg till `requirements_completed` som nytt fält parallellt med befintliga fält — bevara `requirements` som det är.

## Sources

### Primary (HIGH confidence)
- Direkt kodinspekt av källfiler — AuthManager.swift rad 196, UserService.swift rad 53, FriendsTabView.swift rad 153-160, ContactImportView.swift rad 99-109, OnboardingFavoritesView.swift rad 450-461, ImportReviewView.swift rad 36, HotAndColdFriendsApp.swift
- v1.0-MILESTONE-AUDIT.md — exakta gap-beskrivningar INT-01, INT-02, INT-03, FLOW-01 med radnummer
- 08-CONTEXT.md — låsta beslut från /gsd:discuss-phase

### Secondary (MEDIUM confidence)
- SwiftUI `onChange(of:)` two-argument form: tillgänglig iOS 17+ — matchar projektets deployment target (iOS 17+)

### Tertiary (LOW confidence)
- Inga LOW-confidence claims i denna fas.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all kod är direkt inspekterad, inga antaganden
- Architecture: HIGH — exakta radnummer och kodfragment verifierade mot källfiler
- Pitfalls: HIGH — härledda direkt från audit-fynd och befintlig kod

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (stabil kod, inga rörliga delar)
