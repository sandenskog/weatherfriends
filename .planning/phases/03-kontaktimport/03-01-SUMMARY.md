---
phase: 03-kontaktimport
plan: "01"
subsystem: ui
tags: [contacts, CNContactStore, firebase-storage, firebase-functions, swiftui, import]

# Dependency graph
requires:
  - phase: 02-karnupplevelse
    provides: FriendService.addFriend, FriendService.removeDemoFriends, FriendService.fetchFriends

provides:
  - ContactImportService med CNContactStore-åtkomst, kontakthämtning och Firebase Storage-uppladdning
  - ContactImportView med sökfält, alfabetiska sektioner och multi-select checkboxar
  - ContactImportRow med checkbox, profilbild/initialer, namn och stad-hint
  - ContactImportOnboardingWrapper för onboarding-kontext (PendingFriend utan uid)
  - NSContactsUsageDescription i Info.plist
  - FirebaseFunctions SPM-beroende i project.yml

affects:
  - 03-02-PLAN (AI-platsgissning via FirebaseFunctions — beroendet är lagt)
  - OnboardingFavoritesView (importknapp tillagd)
  - FriendListView (plus-meny tillagd)

# Tech tracking
tech-stack:
  added:
    - Contacts framework (CNContactStore, enumerateContacts)
    - FirebaseFunctions (SPM-beroende, används i 03-02)
  patterns:
    - nonisolated på CNContactStore och static keysToFetch för Swift 6-kompatibilitet
    - Task.detached för synkront enumerateContacts utan att blockera MainActor
    - ContactImportOnboardingWrapper som privat struct i OnboardingFavoritesView för onboarding-kontext

key-files:
  created:
    - HotAndColdFriends/Services/ContactImportService.swift
    - HotAndColdFriends/Features/ContactImport/ContactImportView.swift
    - HotAndColdFriends/Features/ContactImport/ContactImportRow.swift
  modified:
    - HotAndColdFriends/Resources/Info.plist
    - project.yml
    - HotAndColdFriends/Features/FriendList/FriendListView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift

key-decisions:
  - "nonisolated används på CNContactStore och keysToFetch för att undvika Swift 6-isoleringsfel i Task.detached"
  - "ContactImportOnboardingWrapper som privat struct i OnboardingFavoritesView — onboarding har inget uid, kontakter läggs till som PendingFriend"
  - "Max 50 kontakter per import-batch — rimlig gräns för UX och Firestore-prestanda"
  - "Importera kontakter-knapp placeras OVANFÖR Lägg till manuellt i onboarding — kontaktimport är primär åtgärd"
  - "Demo-vänner rensas automatiskt vid första riktiga import om de är det enda som finns"

patterns-established:
  - "Task.detached för CNContactStore.enumerateContacts (synkront API på bakgrundstråd)"
  - "nonisolated let för CNContactStore och static arrays i @MainActor-klasser"
  - "ContactImportOnboardingWrapper-mönster för kontextspecifika wrappers utan uid"

requirements-completed:
  - FRND-01
  - FRND-02

# Metrics
duration: 6min
completed: "2026-03-02"
---

# Phase 03 Plan 01: Kontaktimport Summary

**CNContactStore-import med multi-select UI, alfabetiska sektioner och dubblettdetektering integrerat i FriendListView-meny och OnboardingFavoritesView**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-02T22:26:19Z
- **Completed:** 2026-03-02T22:32:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- ContactImportService med CNContactStore-åtkomst, korrekt tillståndshantering (.limited iOS 18+), bakgrundstråds-enumeration och Firebase Storage-uppladdning
- ContactImportView med sökfält, alfabetiska sektioner, multi-select checkboxar, dubblettdetektering ("Redan tillagd") och max 50 per batch-begränsning
- FriendListView plus-knapp ersatt med Menu (Lägg till manuellt / Importera kontakter)
- OnboardingFavoritesView har primär "Importera från kontakter"-knapp med ContactImportOnboardingWrapper som lägger till PendingFriend utan uid

## Task Commits

Varje task committerades atomärt:

1. **Task 1: Info.plist + project.yml + ContactImportService** - `b196a33` (feat)
2. **Task 2: ContactImportView + ContactImportRow + meny-integration** - `6d456c2` (feat)

**Plan metadata:** Skapas i detta steg

## Files Created/Modified

- `HotAndColdFriends/Services/ContactImportService.swift` (167 rader) — CNContactStore-åtkomst, kontakthämtning, Firebase Storage-uppladdning, saveImportedContacts
- `HotAndColdFriends/Features/ContactImport/ContactImportView.swift` (172 rader) — Fullskärms-sheet med sökfält, alfabetiska sektioner, multi-select, dubblettdetektering
- `HotAndColdFriends/Features/ContactImport/ContactImportRow.swift` (67 rader) — Rad med checkbox, profilbild/initialer, namn, stad-hint och "Redan tillagd"-markering
- `HotAndColdFriends/Resources/Info.plist` — NSContactsUsageDescription tillagd
- `project.yml` — FirebaseFunctions SPM-beroende tillagd
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` — Plus-knapp ersatt med Menu, sheet för ContactImportView tillagd
- `HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift` — Importera-knapp, sheet, ContactImportOnboardingWrapper

## Decisions Made

- `nonisolated` på `CNContactStore` och `static keysToFetch` för att undvika Swift 6-isoleringsvarningar/fel i `Task.detached`-kontext. Kompilatorn varnade att MainActor-isolerade egenskaper inte kan nås från utanför aktorn — detta är ett fel i Swift 6-läge.
- `ContactImportOnboardingWrapper` som en privat struct inuti `OnboardingFavoritesView.swift` eftersom onboarding saknar uid (profilen skapas vid "Slutför"). Kontakter läggs till som `PendingFriend` istället för direkt till Firestore.
- Max 50 kontakter per import-batch för rimlig UX och Firestore-prestanda.
- "Importera från kontakter"-knapp placeras OVANFÖR "Lägg till en vän" i onboarding — kontaktimport är det snabbaste sättet att komma igång.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixade Swift 6 actor-isolationsvarningar i ContactImportService**
- **Found during:** Task 1 (build-verifiering)
- **Issue:** `keysToFetch` (static) och `store` var MainActor-isolerade men nåddes från `Task.detached` (utanför aktorn). Kompilatorn varnade att detta är fel i Swift 6-läge.
- **Fix:** Markerade `keysToFetch` som `nonisolated static` och `store` som `nonisolated private let`. Kopierade dessutom `self.store` till en lokal variabel före Task.detached för att undvika capture-problem.
- **Files modified:** HotAndColdFriends/Services/ContactImportService.swift
- **Verification:** Build utan actor-isolationsvarningar från ContactImportService
- **Committed in:** b196a33 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — Swift 6 actor isolation)
**Impact on plan:** Nödvändig fix för Swift 6-kompatibilitet. Ingen scope-krypning.

## Issues Encountered

Inga övriga problem. Build lyckades utan fel på båda tasks.

## User Setup Required

**Firebase Blaze-plan krävs för plan 03-02** (AI-platsgissning via Cloud Functions kräver utgående nätverksanrop till OpenAI).

Se plan-frontmatter `user_setup` för instruktioner:
- Firebase Console -> Project Settings -> Usage and billing -> Modify plan -> Blaze

## Next Phase Readiness

- Kontaktimport-infrastruktur komplett och testad (kompilerar utan fel)
- FirebaseFunctions SPM-beroende redan tillagd — redo för plan 03-02
- ContactImportService.uploadContactPhoto() redo att användas i 03-02 (AI-platsgissning + bilduppladdning)
- Plan 03-02 kan direkt konsumera ContactImportService och ImportableContact-typen

---
*Phase: 03-kontaktimport*
*Completed: 2026-03-02*
