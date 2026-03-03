---
phase: 04-chatt-och-push
plan: 02
subsystem: ui
tags: [swiftui, firestore, firebase, chat, observable, weatherkit]

# Dependency graph
requires:
  - phase: 04-chatt-och-push/04-01
    provides: ChatService, Conversation/ChatMessage/Report-modeller, MainTabView, ConversationListView-placeholder

provides:
  - ConversationListView — navigerbar konversationslista med profilbilder, senaste meddelande, tidsstämpel och vänners väderikon
  - ConversationListViewModel — usersMap (uid->AppUser), blockedUserIds, filteredConversations
  - ChatView — iMessage-stil chattvy med WeatherHeaderView, ScrollViewReader och meddelandeinmatningsfält
  - ChatViewModel — participantUsers, send/sendSticker-metoder, conversationTitle
  - ChatBubbleView — blå/grå bubblor, contextMenu med Rapportera och Blockera
  - WeatherHeaderView — asynkron vaderladdning för 1-till-1 (centrerad) och grupp (horisontell scrollview)
  - NewConversationSheet — 1-till-1 direkt-öppning + grupp multi-select med checkboxes och gruppnamn
  - WeatherStickerView — kompakt kort med temperaturfärgad gradient, SF Symbol och gradsymbol
  - WeatherStickerPickerView — "Mitt väder" + alla deltagares väder att skicka som sticker
affects: [04-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Bindable var vm = viewModel i body — nödvändigt för @Observable i SwiftUI binding-kontext"
    - "ScrollViewReader + onChange(of: messages.count) för auto-scroll till senaste meddelande"
    - "NavigationPath för programmatisk navigation från deeplink och ny konversation"
    - "task(id:) på enskilda rader för asynkron vaderladdning per deltagare"
    - "ContentUnavailableView för tomma states — iOS 17+ native API"

key-files:
  created:
    - HotAndColdFriends/Features/Chat/ConversationListViewModel.swift
    - HotAndColdFriends/Features/Chat/ChatViewModel.swift
    - HotAndColdFriends/Features/Chat/ChatBubbleView.swift
    - HotAndColdFriends/Features/Chat/WeatherHeaderView.swift
    - HotAndColdFriends/Features/Chat/ChatView.swift
    - HotAndColdFriends/Features/Chat/NewConversationSheet.swift
    - HotAndColdFriends/Features/Chat/WeatherStickerView.swift
  modified:
    - HotAndColdFriends/Features/Chat/ConversationListView.swift

key-decisions:
  - "NavigationPath istallet for @State var path for att stodja bade interaktiv navigation och deeplink-navigation"
  - "@Bindable var vm = viewModel i body — krävs for @Observable binding-stod i SwiftUI (TextField $vm.messageText)"
  - "Friend.id används som pseudo-uid i konversationer — direktlösning utan uid-fält i Friend-modellen"
  - "WeatherStickerPickerView som struct i WeatherStickerView.swift — undviker extra fil for intern vy"
  - "task(id: user.id) for vaderladdning i WeatherHeaderView — säkerställer reload om deltagare byts"

patterns-established:
  - "ChatBubbleView tar onReport/onBlock callbacks för separation av UI och business logic"
  - "ConversationListViewModel.filteredConversations — filter körs i ViewModel, inte i View"

requirements-completed: [CHAT-01, CHAT-02, CHAT-03, CHAT-04, CHAT-05]

# Metrics
duration: 2min
completed: 2026-03-03
---

# Phase 4 Plan 02: Chattgränssnittet Summary

**SwiftUI iMessage-stil chattvy med realtidsmeddelanden, temperaturfärgad väder-header, blockering/rapportering via contextMenu, ny konversation-sheet med 1-till-1 och grupp, och väder-stickers med gradient-kort**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-03T12:46:12Z
- **Completed:** 2026-03-03T12:48:31Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- ConversationListView ersätter placeholder med fullständig navigerbar lista (profilbild, senaste meddelande, väderikon)
- ChatView med iMessage-stil bubblor (blå/höger för egna, grå/vänster för andras), realtids-scroll och väder-header
- ChatBubbleView med contextMenu: Rapportera (alltid, App Store Guideline 1.2) + Blockera (bara andras)
- NewConversationSheet med 1-till-1 direktnavigering och grupp multi-select med checkboxes
- WeatherStickerView + WeatherStickerPickerView för att skicka väder-stickers från egna/andras koordinater

## Task Commits

Varje task committades atomärt:

1. **Task 1: ConversationListView, ChatView med iMessage-bubblor och vaderheader** - `d7eef83` (feat)
2. **Task 2: NewConversationSheet, WeatherStickerView och xcodegen** - `4285135` (feat)

**Plan metadata:** (skapas i nästa steg)

## Files Created/Modified
- `HotAndColdFriends/Features/Chat/ConversationListView.swift` - Ersatt placeholder med fullständig lista
- `HotAndColdFriends/Features/Chat/ConversationListViewModel.swift` - usersMap, blockedUserIds, filteredConversations
- `HotAndColdFriends/Features/Chat/ChatView.swift` - Chattvy med header + meddelanden + inmatning
- `HotAndColdFriends/Features/Chat/ChatViewModel.swift` - participantUsers, send/sendSticker
- `HotAndColdFriends/Features/Chat/ChatBubbleView.swift` - iMessage-bubblor med contextMenu
- `HotAndColdFriends/Features/Chat/WeatherHeaderView.swift` - Asynkron väder per deltagare
- `HotAndColdFriends/Features/Chat/NewConversationSheet.swift` - 1-till-1 + grupp-skapande
- `HotAndColdFriends/Features/Chat/WeatherStickerView.swift` - Gradient-kort + picker

## Decisions Made
- NavigationPath (istallet for @State path: [String]) ger stöd för deeplink (openConversationId) och programmatisk navigation sida vid sida
- @Bindable var vm = viewModel krävs för att binda @Observable till SwiftUI TextField ($vm.messageText)
- Friend.id används som pseudo-uid i konversationsdeltagare — undviker uid-fält i Friend-modellen (enklaste lösningen för appens skala)
- WeatherStickerPickerView definierades som intern struct i WeatherStickerView.swift — inga extra filer
- task(id: user.id) i WeatherHeaderView säkerställer att väder laddas om om deltagare byts

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Alla 8 Features/Chat/*.swift-filer klara och inkluderade i projektet via xcodegen
- ChatView, WeatherHeaderView och ChatBubbleView redo för manuell testning mot Firestore
- NewConversationSheet och WeatherStickerPickerView beror på att FriendService är injicerad i environment (hanteras i AppDelegate/HotAndColdFriendsApp)
- Plan 04-03: FCM-push + Cloud Functions kan nu byggas ovanpå detta gränssnittslagret

## Self-Check: PASSED

---
*Phase: 04-chatt-och-push*
*Completed: 2026-03-03*
