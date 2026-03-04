# Phase 7: Tech Debt Cleanup - Research

**Researched:** 2026-03-04
**Domain:** SwiftUI Dependency Injection / Dead Code Removal / Documentation Fixes
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### DI-fixar
- ConversationListView ska använda `@Environment` FriendService istället för throwaway-instans
- ConversationListViewModel ska ta emot UserService via parameter-injection (skapar idag egen `UserService()` på rad 14)

#### Dead code
- Debug-print i FriendListViewModel.swift ska bort (kan redan vara fixad — verifieras vid execution)
- `from(friendWeather:)` i WidgetFriendEntry+AppExtension.swift ska bort

#### Dokumentation
- 05-02-SUMMARY.md ska inkludera VIEW-02 och PUSH-02 i frontmatter (redan fixat — verifieras)

### Claude's Discretion
- Hela implementationen — alla ändringar är exakt specificerade, inga designval behövs

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CHAT-01 | Användare kan skicka 1-till-1 meddelanden till vänner | DI-fixar i ConversationListView/ViewModel förbättrar integration quality — FriendService används korrekt, UserService injiceras |
| CHAT-02 | Användare kan skapa och delta i gruppchattar | Samma DI-fix berör ConversationListViewModel som hanterar både 1-till-1 och gruppchatt |
</phase_requirements>

## Summary

Phase 7 är en exakt specificerad cleanup-fas utan designbeslut. Alla fem success criteria är konkreta kodändringar med kända filer och rader. Fasen är uppdelad i tre domäner: DI-brott (2 ändringar), dead code (2 borttagningar) och dokumentationsverifiering (1 kontroll).

Kodinspektionen avslöjar att några av ändringarna kan redan vara genomförda. Debug-print i FriendListViewModel.swift existerar inte — filen innehåller inga print()-anrop alls. 05-02-SUMMARY.md innehåller redan VIEW-02 och PUSH-02 i frontmatterfältet `provides`. De tre återstående ändringarna (FriendService @Environment i ConversationListView, UserService parameter-injection i ConversationListViewModel, borttagning av `from(friendWeather:)`) kräver faktisk kodförändring.

**Primary recommendation:** Verifiera alla fem success criteria mot aktuell kod vid execution-start, markera redan-klara som done och genomför resterande ändringar i en enda wave utan risk för regressions.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `@Environment` | iOS 17+ | Dependency injection av Observable services | Established pattern i hela appen — alla services injiceras via @Environment i root |
| Swift `@Observable` macro | Swift 5.9+ | Observable state för services och view models | Projektbeslut: iOS 17+ deployment target, @Observable används genomgående |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Observation (Swift) | — | Importeras explicit i ViewModel-filer | Alla @Observable-annoterade klasser |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@Environment` FriendService | `FriendService()` throwaway | Throwaway skapar ny instans per view — ingen delad state, bryter DI-mönstret |
| Parameter-injection UserService | `@Environment` UserService | Projekt pattern: ViewModels tar services via load()-parameter, ej @Environment direkt i VM |

## Architecture Patterns

### Established DI Pattern i projektet

Projektet använder ett konsekvent mönster:

1. **Services**: Skapas i `HotAndColdFriendsApp.init()` som `@State`, injiceras i view-hierarkin via `.environment(service)`
2. **Views**: Hämtar services via `@Environment(ServiceType.self)`
3. **ViewModels**: Tar services som parametrar i `load()` eller metoder — äger INTE egna service-instanser

```swift
// Korrekt mönster (FriendsTabView — referensexempel)
@Environment(FriendService.self) private var friendService
@State private var viewModel = FriendListViewModel()

// I .task{}:
await viewModel.load(uid: uid, friendService: friendService, weatherService: weatherService)
```

### Anti-Patterns to Avoid
- **Throwaway service i .task{}**: `friendService: FriendService()` — skapar ny, oinjectad instans utan delade Firestore-kopplingar
- **Service som property i ViewModel**: `private var userService = UserService()` — VM bör inte äga service-instanser

### Pattern: Parameter-injection i ViewModel

FriendListViewModel är referensimplementationen:
```swift
// FriendListViewModel.swift — gör SÅ HÄR
func load(uid: String, friendService: FriendService, weatherService: AppWeatherService) async {
    // använder friendService som parameter, äger den ej
}
```

ConversationListViewModel ska följa samma mönster — `userService` ska tas som parameter i `load()` och `refreshUsersMap()`.

## Konkreta ändringar att göra

### Fix 1: ConversationListView — @Environment FriendService

**Problem:** Rad 41 i ConversationListView.swift:
```swift
await viewModel.load(uid: currentUid, chatService: chatService, friendService: FriendService())
//                                                                              ^^^^^^^^^^^^^ NYINSTANS
```

**Fix:** Lägg till `@Environment(FriendService.self) private var friendService` och använd den:
```swift
@Environment(FriendService.self) private var friendService

// I .task{}:
await viewModel.load(uid: currentUid, chatService: chatService, friendService: friendService)
```

FriendService är redan registrerad i `HotAndColdFriendsApp` med `.environment(friendService)` — inga root-ändringar behövs.

### Fix 2: ConversationListViewModel — UserService via parameter

**Problem:** Rad 14 i ConversationListViewModel.swift:
```swift
private var userService = UserService()  // BRYTER DI-MÖNSTRET
```

**Fix:** Ta bort property, lägg till `userService`-parameter i `load()` och skicka vidare till `refreshUsersMap`:
```swift
// Ta bort: private var userService = UserService()

func load(uid: String, chatService: ChatService, friendService: FriendService, userService: UserService) async {
    // ...
    await refreshUsersMap(conversations: chatService.conversations, currentUid: uid, userService: userService)
}

private func refreshUsersMap(conversations: [Conversation], currentUid: String, userService: UserService) async {
    // ...
    if let user = try? await userService.fetchUser(uid: uid) {
        usersMap[uid] = user
    }
}
```

Notera: `refreshUsersMapIfNeeded()` kallas från ConversationListView via `onChange` — den behöver också `userService`-parametern, eller så hanteras detta annorlunda (se Open Questions).

### Fix 3: Dead code from(friendWeather:) i WidgetFriendEntry+AppExtension.swift

**Problem:** Hela filen `WidgetFriendEntry+AppExtension.swift` innehåller en extension med `from(friendWeather:)` som är dead code. Metoden skapades i Phase 6 men funktionaliteten är nu inbyggd direkt i `FriendListViewModel.updateWidgetData()`.

**Fix:** Ta bort hela filen. Verifiera att `from(friendWeather:)` inte anropas någonstans:
```bash
grep -r "from(friendWeather" HotAndColdFriends/
```

Projektet kan inte ta bort filen utan att verifiera inga anrop existerar.

### Fix 4: Debug-print i FriendListViewModel (verifiering)

**Status vid kodinspektionen:** INGA print()-anrop finns i FriendListViewModel.swift. Denna fix är sannolikt redan genomförd.

Det finns print-satser i FriendService.swift (raderna 37-38) — dessa är diagnostiska felutskrifter vid decode-fel och är INTE target för denna fas.

### Fix 5: 05-02-SUMMARY.md frontmatter (verifiering)

**Status vid kodinspektionen:** REDAN KLAR. Filen innehåller:
```yaml
dependency_graph:
  provides: ["VIEW-02", "PUSH-02"]
```
VIEW-02 och PUSH-02 finns i frontmatter. Ingen åtgärd behövs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DI-verifiering | Manuell runtime-check | `@Environment` compile-time | Kompileringsfel om service saknas i hierarkin |
| Service-livscykel | Custom lifecycle | SwiftUI `@State` i App root | Delar instans via hela view-hierarkin automatiskt |

## Common Pitfalls

### Pitfall 1: refreshUsersMapIfNeeded saknar userService-parameter

**What goes wrong:** `onChange(of: chatService.conversations)` kallar `refreshUsersMapIfNeeded()` — om den metoden också behöver userService måste anropet uppdateras i ConversationListView.

**Why it happens:** Kedjad parameter-injection kräver att ALLA anropsplatser uppdateras simultaneously.

**How to avoid:** Lägg `@Environment(UserService.self) private var userService` i ConversationListView och skicka till ALLA anrop till viewModel som behöver det.

**Warning signs:** Kompileringsfel på `refreshUsersMapIfNeeded` om signaturen ändrats men anropsstället inte uppdaterats.

### Pitfall 2: Filen WidgetFriendEntry+AppExtension.swift tas bort men används fortfarande

**What goes wrong:** Om `from(friendWeather:)` anropas från något ställe kraschar compilern.

**How to avoid:** Sök igenom hela kodbasen med grep innan borttagning. Verifiering: `grep -r "from(friendWeather"` bör returnera noll träffar utöver definitionen.

### Pitfall 3: xcodegen måste köras om efter filborttagning

**What goes wrong:** `project.pbxproj` refererar fortfarande till borttagen fil — build-fel.

**Why it happens:** Projektbeslut: xcodegen används för projektgenerering. Filer måste registreras/avregistreras via `project.yml` + xcodegen-körning.

**How to avoid:** Ta bort filreferens från `project.yml` och kör xcodegen efter filborttagning. Kontrollera att build lyckas innan commit.

## Code Examples

### Referensexempel: FriendsTabView (korrekt DI-mönster)

```swift
// FriendsTabView.swift — etablerat mönster att följa
struct FriendsTabView: View {
    @Environment(FriendService.self) private var friendService
    @Environment(AppWeatherService.self) private var weatherService
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = FriendListViewModel()

    var body: some View {
        // ...
        .task {
            await viewModel.load(uid: uid, friendService: friendService, weatherService: weatherService)
        }
    }
}
```

### Hur UserService injiceras i app-roten

```swift
// HotAndColdFriendsApp.swift
@State private var userService: UserService

var body: some Scene {
    WindowGroup {
        AppRouter()
            .environment(userService)  // Tillgänglig via @Environment i alla vyer
    }
}
```

UserService finns redan i environment-kedjjan — ConversationListView kan hämta den direkt.

## Validation Architecture

> workflow.nyquist_validation är inte satt i config.json — sektionen inkluderas ej.

## Open Questions

1. **refreshUsersMapIfNeeded — behöver den UserService som parameter?**
   - What we know: Metoden delegerar till `refreshUsersMap` som anropar `userService.fetchUser`
   - What's unclear: Om userService tas bort som property och blir parameter i load(), behöver `refreshUsersMapIfNeeded` också userService-parametern
   - Recommendation: Ja — lägg till `userService: UserService`-parameter i `refreshUsersMapIfNeeded` och uppdatera anropsstället i `onChange` i ConversationListView. Alternativt: lagra userService lokalt i `load()` via capture — men parameter-injection är renare.

2. **from(friendWeather:) — anropas den någonstans?**
   - What we know: FriendListViewModel.updateWidgetData() implementerar samma logik inline
   - Grep-sökning: Ej utförd i research (sker vid execution)
   - Recommendation: Kör `grep -r "from(friendWeather"` som första steg i execution — om noll träffar, ta bort filen direkt.

## Sources

### Primary (HIGH confidence)
- Direktläsning av källkod: `ConversationListView.swift`, `ConversationListViewModel.swift`, `WidgetFriendEntry+AppExtension.swift`, `FriendListViewModel.swift`, `HotAndColdFriendsApp.swift`, `FriendsTabView.swift`
- Direktläsning av `.planning/phases/05-utokade-vyer/05-02-SUMMARY.md`

### Secondary (MEDIUM confidence)
- Projektbeslut från STATE.md: `[Phase 04-01]`, `[Phase 05-01]` — bekräftar parameter-injection som etablerat mönster

### Tertiary (LOW confidence)
- Inga externa källor behövdes — all information finns i kodbasen

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verifierat direkt mot källkod
- Architecture: HIGH — mönstret är dokumenterat i STATE.md och implementerat i FriendsTabView
- Pitfalls: HIGH — xcodegen-kravet bekräftat i STATE.md, övriga från kodinspektionen

**Research date:** 2026-03-04
**Valid until:** Stabil — inga externa bibliotek, kodbasen ändras ej utan commits
