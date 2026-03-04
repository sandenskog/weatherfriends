---
phase: 04-chatt-och-push
plan: "04"
subsystem: push-notifications
tags: [weatherkit, cloud-functions, fcm, push, firestore, ios]
dependency_graph:
  requires: [04-03]
  provides: [PUSH-01]
  affects: [Friend.swift, HotAndColdFriendsApp.swift, functions/src/index.ts]
tech_stack:
  added:
    - WeatherKit .alerts API (iOS)
    - firebase-functions/v2/firestore onDocumentUpdated
  patterns:
    - WeatherAlertService som MainActor bakgrundstjanst (ej @Observable)
    - Deterministisk false-to-true trigger for att undvika duplicerade push
    - Rate-limiting via lastAlertSentAt Firestore-timestamp
key_files:
  created:
    - HotAndColdFriends/Services/WeatherAlertService.swift
    - functions/src/weatherAlertTrigger.ts
  modified:
    - HotAndColdFriends/Models/Friend.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - functions/src/weatherAlertScheduler.ts
    - functions/src/index.ts
decisions:
  - "WeatherAlertService ar MainActor men ej @Observable — bakgrundstjanst behover ingen UI-binding"
  - "onDocumentUpdated triggas vid varje Firestore-uppdatering — false-to-true-kontroll krävs for att undvika duplicerade notiser"
  - "lastAlertSentAt sätts EFTER lyckad FCM-leverans — rate-limiting hoppar over om push misslyckats"
  - "weatherAlertScheduler rensar stale alerts (>24h) som komplement till iOS-klienten"
metrics:
  duration: "3 min"
  completed_date: "2026-03-03"
  tasks: 2
  files: 6
---

# Phase 4 Plan 04: Extremvader-push (PUSH-01) Summary

WeatherKit-baserad extremvader-push: iOS-klient kontrollerar .alerts vid app-start, skriver till Firestore, Cloud Function triggas och skickar FCM med rate-limiting (24h) och personlig ton.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | iOS WeatherAlertService | acd4dd7 | WeatherAlertService.swift, Friend.swift, HotAndColdFriendsApp.swift |
| 2 | Cloud Function weatherAlertTrigger | f29fcde | weatherAlertTrigger.ts, weatherAlertScheduler.ts, index.ts |

## What Was Built

### Task 1: iOS WeatherAlertService

**WeatherAlertService.swift** — Ny service som itererar over alla vänner med koordinater, anropar `WeatherKit.WeatherService.weather(for:including:.alerts)` och skriver `hasActiveAlert`/`alertSummary` till Firestore. Nil/tom array hanteras tyst som `false`. WeatherKit-fel loggas och skippar vannen utan att krascha appen.

**Friend.swift** — Tre nya optionella fält lagda till:
- `var hasActiveAlert: Bool?`
- `var alertSummary: String?`
- `@ServerTimestamp var lastAlertSentAt: Timestamp?`

Befintliga Friend-dokument utan dessa fält fortsätter fungera utan dekodningsfel (Codable-kompatibel).

**HotAndColdFriendsApp.swift** — `@State private var weatherAlertService = WeatherAlertService()` och anrop i `.task{}` efter push-registrering. Misslyckat `fetchFriends` fångas med `try?` för att aldrig blockera app-start.

### Task 2: Cloud Function weatherAlertTrigger

**weatherAlertTrigger.ts** — `onDocumentUpdated` på `users/{uid}/friends/{friendId}`:
- Kontrollerar `false → true` för `hasActiveAlert`
- Rate-limiting: max 1 notis per 24h via `lastAlertSentAt`
- Hämtar ägarens FCM-token från `users/{uid}.fcmToken`
- Skickar FCM med personlig ton: "[Alert] hos [Namn]" / "Extremt väder i [Stad] — hör av dig!"
- Deep link data: `type: "weatherAlert"`, `friendId`, `friendName`, `friendCity`
- Ogiltig token (registration-token-not-registered) rensas automatiskt

**weatherAlertScheduler.ts** — Ersätter placeholder med verklig cleanup-logik: rensar `hasActiveAlert: true` för friends där `lastAlertSentAt` är äldre än 24h. Körs varje timme.

**index.ts** — `onFriendAlertUpdated` exporteras tillsammans med befintliga `onNewMessage`, `checkExtremeWeather` och `guessContactLocations`.

## Verification Results

Alla 10 verifieringspunkter passerar:
1. WeatherAlertService.swift existerar med .alerts-anrop — PASS
2. Friend.swift har hasActiveAlert, alertSummary, lastAlertSentAt — PASS
3. HotAndColdFriendsApp anropar checkAlertsForFriends — PASS
4. weatherAlertTrigger med onDocumentUpdated — PASS
5. hasActiveAlert false→true-kontroll — PASS
6. Rate-limiting (hoursSince < 24) — PASS
7. Personlig notiston ("hor av dig") — PASS
8. weatherAlertScheduler cleanup-logik — PASS
9. index.ts exporterar alla 4 funktioner — PASS
10. TypeScript kompilerar utan fel — PASS

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

Files verified:
- FOUND: HotAndColdFriends/Services/WeatherAlertService.swift
- FOUND: functions/src/weatherAlertTrigger.ts
- FOUND: HotAndColdFriends/Models/Friend.swift (modified)
- FOUND: HotAndColdFriends/App/HotAndColdFriendsApp.swift (modified)
- FOUND: functions/src/weatherAlertScheduler.ts (modified)
- FOUND: functions/src/index.ts (modified)

Commits verified:
- FOUND: acd4dd7 (feat(04-04): iOS WeatherAlertService)
- FOUND: f29fcde (feat(04-04): Cloud Function weatherAlertTrigger)
