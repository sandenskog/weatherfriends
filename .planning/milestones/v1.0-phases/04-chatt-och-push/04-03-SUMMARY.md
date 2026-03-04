---
phase: 04-chatt-och-push
plan: "03"
subsystem: api
tags: [firebase, cloud-functions, fcm, push-notifications, apns, ios, typescript, firestore]

# Dependency graph
requires:
  - phase: 04-01
    provides: FCM-registrering i iOS-appen (AppDelegate + project.yml), ChatService, konversationsmodeller

provides:
  - Cloud Function chatPushTrigger (onDocumentCreated) — FCM-push vid nya chattmeddelanden med blockerings-kontroll och token-cleanup
  - Cloud Function weatherAlertScheduler (onSchedule) — placeholder för extremväder-notiser i v1
  - APNs Authentication Key uppladdad till Firebase Console — push kan levereras till iOS-enheter

affects:
  - 05-utokade-vyer
  - 06-polish-och-app-store

# Tech tracking
tech-stack:
  added:
    - firebase-admin/messaging (getMessaging, sendEachForMulticast)
    - firebase-functions/v2/firestore (onDocumentCreated)
    - firebase-functions/v2/scheduler (onSchedule)
    - APNs Authentication Key (.p8) via Firebase Console Cloud Messaging
  patterns:
    - Firestore-trigger-mönster: onDocumentCreated för realtids-sideeffekter
    - Blockerings-kontroll i push-flöde: mottagare filtreras mot avsändarens blockedUsers-subkollektion
    - Token-cleanup pattern: oregistrerade FCM-tokens rensas automatiskt med FieldValue.delete()
    - Placeholder-funktion med tydlig kommentar för framtida iOS-klientintegration

key-files:
  created:
    - functions/src/chatPushTrigger.ts
    - functions/src/weatherAlertScheduler.ts
  modified:
    - functions/src/index.ts

key-decisions:
  - "weatherAlertScheduler implementeras som placeholder i v1 — full WeatherKit-integration kräver iOS-klienten som sätter hasActiveAlert i Firestore"
  - "Alternativ A (iOS-klient sätter hasActiveAlert i Firestore) väljs över Alternativ B (Cloud Function anropar WeatherKit REST API direkt) — enklare, undviker JWT-hantering med .p8-nyckel i Cloud Functions"
  - "APNs Authentication Key laddas upp med Production-environment (inte sandbox) — säkerställer push-leverans för alla iOS-builds"

patterns-established:
  - "Blockerings-kontroll: hämta mottagare -> filtrera blockedUsers -> hämta FCM-tokens -> skicka"
  - "FCM-payload med data.type='chat' och data.conversationId för deep link-stöd i iOS-appen"

requirements-completed: [PUSH-01, PUSH-03]

# Metrics
duration: ~5min
completed: 2026-03-03
---

# Phase 4 Plan 03: Cloud Functions push-notiser Summary

**FCM-pushfunktion via onDocumentCreated-trigger med blockerings-kontroll och token-cleanup, APNs-nyckel uppladdad till Firebase Console**

## Performance

- **Duration:** ~5 min (exkl. manuell APNs-konfiguration)
- **Started:** 2026-03-03
- **Completed:** 2026-03-03
- **Tasks:** 2 (1 auto + 1 human-action checkpoint)
- **Files modified:** 3

## Accomplishments
- chatPushTrigger.ts — Firestore onDocumentCreated-trigger som skickar FCM-push till alla konversationsdeltagare utom avsändaren, med blockerings-kontroll och automatisk token-cleanup vid TokenNotRegistered-fel
- weatherAlertScheduler.ts — Skapad som välkommenterad placeholder för v1; full implementation väntar på iOS-klientsidan som ska sätta hasActiveAlert i Firestore
- APNs Authentication Key (.p8) uppladdad till Firebase Console med Key ID och Team ID A473BQKT8M — push-notiser kan nu levereras till iOS-enheter via FCM

## Task Commits

Varje task committades atomärt:

1. **Task 1: Cloud Functions — chatPushTrigger och weatherAlertScheduler** - `2945604` (feat)
2. **Task 2: Ladda upp APNs Authentication Key till Firebase Console** - Human action (ingen kod-commit)

**Plan metadata:** Se final commit (docs)

## Files Created/Modified
- `functions/src/chatPushTrigger.ts` — Firestore-trigger: hämtar deltagare, filtrerar blockerade, hämtar FCM-tokens, skickar FCM med senderName/text/conversationId, rensar ogiltiga tokens
- `functions/src/weatherAlertScheduler.ts` — Schemalagd onSchedule-funktion (placeholder med tydlig kommentar för framtida iOS-klient-integration)
- `functions/src/index.ts` — Uppdaterad med export av onNewMessage och checkExtremeWeather (behåller befintlig guessContactLocations)

## Decisions Made

- **weatherAlertScheduler som placeholder:** Full WeatherKit REST API-integration från Cloud Functions kräver .p8-nyckel som Firebase Secret och komplex JWT-hantering. Valt att implementera iOS-klient-driven approach (Alternativ A) där klienten sätter hasActiveAlert i Firestore — Cloud Function triggas sedan av den Firestore-ändringen. Placeholder dokumenterar detta tydligt för framtida implementation.
- **APNs Production-environment:** Nyckeln laddades upp med Production (inte Development/Sandbox) för att säkerställa att push fungerar för alla iOS-builds, inklusive TestFlight och App Store.

## Deviations from Plan

Inga avvikelser — planen exekverades exakt som skriven, inklusive rekommendationen att implementera weatherAlertScheduler som placeholder för v1.

## Issues Encountered

Inga — Task 1 (kod) och Task 2 (manuell APNs-konfiguration) exekverades utan problem.

## User Setup Required

**APNs Authentication Key är uppladdad** (Task 2 genomförd):
- .p8-fil uppladdad till Firebase Console -> Project Settings -> Cloud Messaging -> Apple app configuration
- Key ID och Team ID (A473BQKT8M) konfigurerade
- Environment: Production

**Återstående för full push-funktionalitet:**
- Cloud Functions måste deployas: `cd functions && firebase deploy --only functions`
- iOS-klienten behöver implementera hasActiveAlert-skrivning till Firestore för att aktivera extremväder-notiser (weatherAlertScheduler Alternativ A)

## Next Phase Readiness

Fas 4 (Chatt och Push) är nu komplett:
- Datamodeller och ChatService (plan 04-01)
- Chattgränssnitt med 8 SwiftUI-vyer (plan 04-02)
- Push-notiser via Cloud Functions och APNs-konfiguration (plan 04-03)

Fas 5 (Utökade Vyer) kan påbörjas: MapKit-kartvy, grupperade väderkort, daglig sammanfattning.

## Self-Check: PASSED

- `functions/src/chatPushTrigger.ts` — FOUND
- `functions/src/weatherAlertScheduler.ts` — FOUND
- `functions/src/index.ts` — FOUND (modified)
- Commit `2945604` — FOUND

---
*Phase: 04-chatt-och-push*
*Completed: 2026-03-03*
