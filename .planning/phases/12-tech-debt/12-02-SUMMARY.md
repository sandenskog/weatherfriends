---
phase: 12-tech-debt
plan: 02
subsystem: auth, ui
tags: [swiftui, environment, firestore, collectionGroup, weather-alerts, account-deletion]

# Dependency graph
requires:
  - phase: 11-animations
    provides: CloudRefreshModifier for pull-to-refresh
provides:
  - WeatherAlertService in SwiftUI environment chain
  - Alert check on pull-to-refresh (not just cold-start)
  - Resilient cleanupUserData with reverse friend cleanup
  - Invite document cleanup on account deletion
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resilient multi-step cleanup: do/catch per step, collect errors, continue"
    - "collectionGroup query for reverse relationship cleanup"

key-files:
  created: []
  modified:
    - HotAndColdFriends/Features/FriendList/FriendListView.swift
    - HotAndColdFriends/Features/FriendList/FriendsTabView.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - HotAndColdFriends/Core/Auth/AuthManager.swift
    - HotAndColdFriends/Services/WeatherAlertService.swift

key-decisions:
  - "Added @Observable to WeatherAlertService — required for @Environment(Type.self) injection pattern"
  - "cleanupUserData no longer throws on individual step failure — continues cleanup and only logs errors"

patterns-established:
  - "Resilient cleanup: each Firestore operation in its own do/catch, non-critical ops use try?"

requirements-completed: [DEBT-02, DEBT-03]

# Metrics
duration: 4min
completed: 2026-03-06
---

# Phase 12 Plan 02: Alert Refresh & Robust Cleanup Summary

**WeatherAlertService injected in SwiftUI environment for pull-to-refresh alert checks, and cleanupUserData made resilient with reverse friend list cleanup via collectionGroup query**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-06T13:19:12Z
- **Completed:** 2026-03-06T13:23:13Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Pull-to-refresh now triggers weather alert check after refreshing friend data (previously only at cold-start)
- Account deletion cleanup is resilient to partial network failures (each step wrapped in do/catch)
- Deleted users are removed from other users' friend lists via Firestore collectionGroup query
- Unused invite documents are cleaned up on account deletion

## Task Commits

Each task was committed atomically:

1. **Task 1: Inject WeatherAlertService in environment and trigger alert check on pull-to-refresh** - `a319bfa` (feat)
2. **Task 2: Make cleanupUserData robust and add reverse friend list cleanup** - `919bb98` (feat)

## Files Created/Modified
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` - Added @Environment(WeatherAlertService.self) and alert check in cloudRefreshable
- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` - Added @Environment(WeatherAlertService.self) for environment chain
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` - Added .environment(weatherAlertService) to modifier chain
- `HotAndColdFriends/Services/WeatherAlertService.swift` - Added @Observable macro (required for @Environment injection)
- `HotAndColdFriends/Core/Auth/AuthManager.swift` - Rewrote cleanupUserData with resilient do/catch pattern, reverse friend cleanup, and invite cleanup

## Decisions Made
- Added @Observable to WeatherAlertService since it was missing but required for the @Environment(Type.self) injection pattern used throughout the app
- cleanupUserData collects errors per step but never throws — ensures maximum cleanup even with partial failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added @Observable to WeatherAlertService**
- **Found during:** Task 1 (WeatherAlertService environment injection)
- **Issue:** WeatherAlertService lacked @Observable macro, causing @Environment(WeatherAlertService.self) to fail compilation with "no exact matches in call to initializer"
- **Fix:** Added @Observable macro to WeatherAlertService class declaration
- **Files modified:** HotAndColdFriends/Services/WeatherAlertService.swift
- **Verification:** Build succeeds
- **Committed in:** a319bfa (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Auto-fix necessary for compilation. No scope creep.

## Issues Encountered
None beyond the deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- WeatherAlertService fully integrated in environment chain
- Account deletion cleanup is production-ready with resilient error handling
- Note: Firestore collectionGroup("friends") requires a composite index on "authUid" field — ensure this exists in Firebase console

---
*Phase: 12-tech-debt*
*Completed: 2026-03-06*
