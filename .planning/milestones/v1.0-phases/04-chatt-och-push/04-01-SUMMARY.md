---
phase: 04-chatt-och-push
plan: 01
subsystem: chat
tags: [firestore, firebase, fcm, push-notifications, swift, swiftui, observable]

# Dependency graph
requires:
  - phase: 03-kontaktimport
    provides: FriendService och Friend-modell som ChatService indirekt relaterar till
  - phase: 01-foundation
    provides: AppDelegate, HotAndColdFriendsApp, AppRouter-mönster, @Observable-tjänster

provides:
  - Conversation, ChatMessage (med MessageType/WeatherStickerData), Report Firestore Codable-modeller
  - ChatService med realtidslyssnare (conversations + messages), send/block/report-metoder
  - MainTabView med Vänner/Chattar-flikar
  - Uppdaterad AppRouter som renderar MainTabView vid authenticated
  - FCM-tokenhantering via MessagingDelegate (sparas till Firestore users/{uid}/fcmToken)
  - Push-notis deep link via Notification.Name.openChat
  - ConversationListView-placeholder för Plan 04-02
affects: [04-02, 04-03]

# Tech tracking
tech-stack:
  added: [FirebaseMessaging, UserNotifications]
  patterns:
    - "@Observable @MainActor class ChatService — samma mönster som FriendService"
    - "nonisolated(unsafe) för ListenerRegistration — deinit-kompatibilitet Swift 6"
    - "TabView med .tabItem{} (iOS 17 compatible, inte iOS 18+ Tab()-syntax)"
    - "Notification.Name.openChat för push-notis deep link till konversation"

key-files:
  created:
    - HotAndColdFriends/Models/Conversation.swift
    - HotAndColdFriends/Models/ChatMessage.swift
    - HotAndColdFriends/Models/Report.swift
    - HotAndColdFriends/Services/ChatService.swift
    - HotAndColdFriends/Core/Navigation/MainTabView.swift
    - HotAndColdFriends/Features/Chat/ConversationListView.swift
  modified:
    - HotAndColdFriends/Core/Navigation/AppRouter.swift
    - HotAndColdFriends/App/AppDelegate.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - project.yml

key-decisions:
  - "ConversationListView skapas som placeholder (Plan 04-02 implementerar fullt) — möjliggör kompilering av MainTabView direkt"
  - "push-notis deep link via NotificationCenter (.openChat) — undviker StateObject-komplikationer i AppDelegate"
  - "registerForPushNotifications() anropas via .task{} i WindowGroup — säkert timing efter app-init"
  - "Deterministiskt konversations-ID: sorted UIDs joined med _ — möjliggör idempotent getOrCreateDirectConversation"
  - "limit(toLast: 50) för message-lyssnare — begränsar Firestore-reads vid öppnande av konversation"

patterns-established:
  - "ChatService: startListening/stopListening lifecycle-mönster för Firestore snapshot listeners"
  - "MessagingDelegate sparar token direkt till Firestore — ingen Cloud Function behövs för token-registrering"

requirements-completed: [CHAT-01, CHAT-02, CHAT-04, CHAT-05]

# Metrics
duration: 3min
completed: 2026-03-03
---

# Phase 4 Plan 01: Chatt datalager och navigation Summary

**Firestore Codable-modeller (Conversation/ChatMessage/Report), ChatService med snapshot listeners/block/rapport, MainTabView med Vänner/Chattar-flikar, FCM-token till Firestore och push deep link via NotificationCenter**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-03T12:40:31Z
- **Completed:** 2026-03-03T12:43:50Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Tre Firestore Codable-modeller (Conversation, ChatMessage med MessageType/WeatherStickerData, Report) skapade
- ChatService med realtidslyssnare, skicka text/väder-sticker, blockering och rapportering
- MainTabView med Vänner/Chattar-flikar ersätter FriendListView i AppRouter
- FCM-token sparas automatiskt till Firestore vid token-refresh via MessagingDelegate
- Push-notis tap öppnar rätt konversation via Notification.Name.openChat deep link

## Task Commits

Varje task committades atomärt:

1. **Task 1: Conversation, ChatMessage, Report-modeller och ChatService** - `172b5b7` (feat)
2. **Task 2: MainTabView, AppRouter, FCM-setup och project.yml** - `0bf4c0b` (feat)

**Plan metadata:** (skapas i nästa steg)

## Files Created/Modified
- `HotAndColdFriends/Models/Conversation.swift` - Firestore Codable model: participants, lastMessage-fält
- `HotAndColdFriends/Models/ChatMessage.swift` - ChatMessage med MessageType enum och WeatherStickerData
- `HotAndColdFriends/Models/Report.swift` - Rapport-modell för App Store Guideline 1.2
- `HotAndColdFriends/Services/ChatService.swift` - @Observable @MainActor service: snapshot listeners, CRUD, block, report
- `HotAndColdFriends/Core/Navigation/MainTabView.swift` - TabView med Vänner/Chattar-flikar
- `HotAndColdFriends/Features/Chat/ConversationListView.swift` - Placeholder för Plan 04-02
- `HotAndColdFriends/Core/Navigation/AppRouter.swift` - Renderar MainTabView, .openChat NotificationCenter-lyssnare
- `HotAndColdFriends/App/AppDelegate.swift` - MessagingDelegate + UNUserNotificationCenterDelegate, FCM-token
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` - ChatService i environment, push-registrering via .task{}
- `project.yml` - FirebaseMessaging tillagt som SPM-beroende

## Decisions Made
- ConversationListView som placeholder möjliggör kompilering redan i Plan 04-01 utan att ta in Plan 04-02-vyer
- Deterministiskt konversations-ID (`[uid1, uid2].sorted().joined(separator: "_")`) för idempotent getOrCreateDirectConversation
- push deep link via NotificationCenter (.openChat) — undviker StateObject-komplikationer i AppDelegate
- `.task{}` på WindowGroup för push-registrering — säker timing efter Firebase-init
- `limit(toLast: 50)` för message-lyssnare för att begränsa Firestore-reads

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required
- FCM kräver att APNs-certifikat konfigureras i Firebase Console innan push-notiser fungerar på fysisk enhet (hanteras i Plan 04-03)
- Push-notistillstånd begärs från användaren vid app-start via registerForPushNotifications()

## Next Phase Readiness
- Alla modeller och ChatService är redo för Plan 04-02 (konversations- och meddelandevyer)
- FCM-token-sparning och push deep link är redo för Plan 04-03 (Cloud Functions och push-konfiguration)
- ConversationListView-placeholder ersätts med full implementering i Plan 04-02

## Self-Check: PASSED

All created files verified on disk. Both task commits (172b5b7, 0bf4c0b) confirmed in git log.

---
*Phase: 04-chatt-och-push*
*Completed: 2026-03-03*
