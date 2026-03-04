---
phase: 03-kontaktimport
plan: 02
subsystem: ui
tags: [firebase-functions, openai, gpt-4o-mini, swift, swiftui, ios, contacts, location]

# Dependency graph
requires:
  - phase: 03-01
    provides: ContactImportService, ContactImportView, ImportableContact, FriendService
  - phase: 02-01
    provides: LocationService med stad-autocomplete
provides:
  - Firebase Cloud Function guessContactLocations (TypeScript, europe-west1, OpenAI gpt-4o-mini)
  - LocationGuess, ReviewedContact, ContactPayload typer i ContactImportService.swift
  - guessLocations() metod via httpsCallable("guessContactLocations")
  - saveReviewedContacts() med stad/koordinater och demo-rensning
  - ImportReviewView med konfidens-färgkodning och inline stad-korrigering
  - Uppdaterat importflöde i ContactImportView (AI-gissning -> review)
affects: [deployment, firebase-setup, openai-setup]

# Tech tracking
tech-stack:
  added: [firebase-functions v6, firebase-admin v12, openai v4, typescript v5, nodejs 20]
  patterns:
    - Firebase Cloud Function callable med defineSecret (modern v2 API)
    - Graceful AI-fallback (returnerar unknown vid OpenAI-fel, aldrig throw)
    - Konfidens-baserad färgkodning (high=grön, medium=gul, low=orange, unknown=röd)
    - Direktretur för kontakter med fullständig adress (token-optimering)

key-files:
  created:
    - functions/src/index.ts
    - functions/package.json
    - functions/tsconfig.json
    - functions/.gitignore
    - firebase.json
    - HotAndColdFriends/Features/ContactImport/ImportReviewView.swift
  modified:
    - HotAndColdFriends/Services/ContactImportService.swift
    - HotAndColdFriends/Features/ContactImport/ContactImportView.swift

key-decisions:
  - "Kontakter med fullständig adress returneras direkt med high confidence — sparar OpenAI-tokens"
  - "Graceful fallback vid OpenAI-fel: returnerar unknown confidence istället för att kasta fel"
  - "defineSecret('OPENAI_API_KEY') används i stället för functions.config() (modern Firebase v2 API)"
  - "region europe-west1 satt i Cloud Function — måste matcha Swift-klienten Functions.functions(region:)"
  - "saveImportedContacts() behålls som legacy-metod — saveReviewedContacts() är den nya primärmetoden"

patterns-established:
  - "Firebase callable functions: Functions.functions(region: 'europe-west1').httpsCallable(name)"
  - "Review-flöde: AI-gissning -> showReview=true (graceful fallback vid CF-fel)"
  - "Konfidens-färgkodning: confidenceColor(_ confidence: String) -> Color (green/yellow/orange/red)"

requirements-completed: [FRND-01, FRND-02, FRND-03]

# Metrics
duration: 15min (inkl. deployment-checkpoint)
completed: 2026-03-03
---

# Phase 3 Plan 02: Kontaktimport — AI-platsgissning och Review-vy

**Firebase Cloud Function med OpenAI gpt-4o-mini för batchvis platsgissning, plus ImportReviewView med konfidens-färgkodning och inline stad-korrigering via LocationService**

## Performance

- **Duration:** ~15 min (inkl. mänsklig deployment-checkpoint)
- **Started:** 2026-03-02T22:38:22Z
- **Completed:** 2026-03-03
- **Tasks:** 3 av 3 (komplett — deployment bekräftad)
- **Files modified:** 8

## Accomplishments

- Firebase Cloud Function `guessContactLocations` (TypeScript) exporterad med OpenAI gpt-4o-mini, defineSecret, region europe-west1 och batch-optimering (direktretur för kontakter med fullständig adress)
- ContactImportService utökad med `guessLocations()` via httpsCallable, `saveReviewedContacts()` med stad/koordinater och automatisk demo-rensning, samt stödtyper LocationGuess och ReviewedContact
- ImportReviewView skapad med konfidens-färgkodning (grön/gul/orange/röd), include/exclude-toggle per kontakt och inline stad-korrigering via LocationService autocomplete
- ContactImportView uppdaterad med reviewflöde: Importera-knapp triggar AI-gissning med laddningsindikator "Analyserar...", graceful fallback vid Cloud Function-fel

## Task Commits

1. **Task 1: Firebase Cloud Function + Swift-side callable** - `5a5b062` (feat)
2. **Task 2: ImportReviewView + uppdaterat importflöde** - `cc7c37d` (feat)
3. **Task 3: Deploya Cloud Function och sätt OpenAI API-nyckel** - Mänskligt checkpoint, bekräftat av Richard (2026-03-03)

**Plan metadata:** `f3734cc` (docs: checkpoint-commit)

## Files Created/Modified

- `functions/src/index.ts` - Cloud Function guessContactLocations med OpenAI och batchlogik
- `functions/package.json` - Node.js-beroenden: firebase-functions v6, firebase-admin v12, openai v4
- `functions/tsconfig.json` - TypeScript-konfiguration för Cloud Functions
- `functions/.gitignore` - Ignorerar lib/ och node_modules/
- `firebase.json` - Firebase-konfiguration med functions-källa
- `HotAndColdFriends/Features/ContactImport/ImportReviewView.swift` - Ny review-vy med ReviewItem-modell, konfidens-färger och stad-korrigering
- `HotAndColdFriends/Services/ContactImportService.swift` - Lagt till LocationGuess, ReviewedContact, guessLocations(), saveReviewedContacts()
- `HotAndColdFriends/Features/ContactImport/ContactImportView.swift` - Uppdaterat importflöde med isGuessing-state och ImportReviewView-sheet

## Decisions Made

- Kontakter med fullständig adress returneras direkt med "high" confidence (ingen AI-kostnad)
- Graceful fallback vid OpenAI-fel: returnerar "unknown" istället för att kasta fel — review visas ändå
- `defineSecret("OPENAI_API_KEY")` används (modern Firebase v2 API, inte deprecated functions.config())
- Region `europe-west1` satt i Cloud Function — måste matcha Swift-klienten
- `saveImportedContacts()` behålls som legacy — `saveReviewedContacts()` är primärmetoden

## Deviations from Plan

Inga — plan exekverades exakt som skriven.

## Issues Encountered

- iPhone 16 Simulator saknas i miljön — använde iPhone 17 Simulator istället för xcodebuild-verifiering. BUILD SUCCEEDED.

## User Setup Required

Task 3 var ett mänskligt checkpoint som slutforts av Richard (2026-03-03):

1. Firebase Blaze-plan verifierades
2. Firebase CLI installerades och inloggning gjordes
3. npm-beroenden installerades i functions/
4. OpenAI API-nyckel sattes som Firebase secret via `firebase functions:secrets:set OPENAI_API_KEY`
5. Cloud Function deployades via `firebase deploy --only functions`
6. Richard bekräftade deployment med meddelandet "deployat"

## Next Phase Readiness

- Fas 3 (Kontaktimport) komplett i sin helhet — alla 3 tasks klara
- Cloud Function guessContactLocations deployad och aktiv i Firebase (europe-west1)
- Komplett importflöde: kontaktval -> AI-gissning -> review med korrigering -> spara
- Redo for fas 4 (Chattfunktion) — inga blockerare

---
*Phase: 03-kontaktimport*
*Completed: 2026-03-02*
