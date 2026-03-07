---
phase: 16-invite-foundation
plan: 02
subsystem: invite
tags: [universal-links, deep-link, clipboard, sharelink, swiftui, firebase]

# Dependency graph
requires:
  - phase: 16-invite-foundation
    provides: Invite web page with AASA, clipboard JS, OG meta tags
provides:
  - Persistent multi-use invite codes (redeemedBy array)
  - Universal Links handler in onOpenURL
  - Clipboard deferred deep link service
  - Invite share UI on 3 locations (Profile, AddFriend, FriendsTabView header)
  - Associated Domains entitlement in project.yml
affects: [16-invite-foundation remaining plans, deploy pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns: [lazy-permanent invite tokens, clipboard deferred deep link with TTL]

key-files:
  created:
    - HotAndColdFriends/Services/ClipboardInviteService.swift
  modified:
    - HotAndColdFriends/Services/InviteService.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - HotAndColdFriends/Features/FriendList/FriendsTabView.swift
    - HotAndColdFriends/Features/FriendList/AddFriendSheet.swift
    - HotAndColdFriends/Features/Profile/ProfileView.swift
    - project.yml

key-decisions:
  - "Invite codes are permanent and multi-use via redeemedBy array instead of delete-on-redeem"
  - "ShareLink with subject/message params for rich iMessage previews"

patterns-established:
  - "Lazy-permanent tokens: getOrCreateInviteToken queries existing before creating new"
  - "Clipboard deferred deep link: friendscast-invite:token:timestamp format with 7-day TTL"

requirements-completed: [INVT-01, INVT-03, INVT-04]

# Metrics
duration: 15min
completed: 2026-03-07
---

# Phase 16 Plan 02: iOS Invite System Summary

**Persistent multi-use invite codes with Universal Links handler, clipboard deferred deep link, and ShareLink on Profile/AddFriend/header**

## Performance

- **Duration:** ~15 min (across checkpoint)
- **Started:** 2026-03-07T08:30:00Z
- **Completed:** 2026-03-07T09:00:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Refactored InviteService to persistent multi-use codes with redeemedBy array (no more delete-on-redeem)
- Universal Links handler in onOpenURL supporting both HTTPS (apps.sandenskog.se) and legacy custom scheme
- ClipboardInviteService for deferred deep link with 7-day TTL and one-time check
- Invite share button visible on all 3 locations: ProfileView, AddFriendSheet, FriendsTabView header toolbar
- Rich iMessage previews with ShareLink subject/message params

## Task Commits

Each task was committed atomically:

1. **Task 1: Refaktorera InviteService for persistenta koder och Universal Links** - `9d3706b` (feat)
2. **Task 2: Universal Links-handler, clipboard deferred deep link och UI-uppdateringar** - `6d59ec6` (feat)
3. **Task 3: Verifiera invite-system i Xcode** - checkpoint (human-verify, approved)

**Post-checkpoint fix:** `46ef52a` — ShareLink preview text for rich iMessage previews (fixed by orchestrator)

## Files Created/Modified
- `HotAndColdFriends/Services/InviteService.swift` - Persistent invite codes with redeemedBy, HTTPS URLs, getOrCreateInviteToken
- `HotAndColdFriends/Services/ClipboardInviteService.swift` - NEW: Clipboard deferred deep link with TTL validation
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` - Universal Links + custom scheme handler, clipboard check on startup, toast overlay
- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` - ShareLink invite button in header toolbar
- `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift` - Invite via Link section with ShareLink
- `HotAndColdFriends/Features/Profile/ProfileView.swift` - Updated to getOrCreateInviteToken
- `project.yml` - Associated Domains entitlement (applinks:apps.sandenskog.se)

## Decisions Made
- Invite codes are permanent and multi-use (redeemedBy array replaces delete-on-redeem)
- ShareLink uses subject/message params for rich previews in iMessage and other share targets
- Clipboard deferred deep link uses friendscast-invite:token:timestamp format with 7-day TTL
- One-time clipboard check via UserDefaults flag (not on every app start)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ShareLink bare URL in iMessage**
- **Found during:** Task 3 checkpoint (human verification)
- **Issue:** iMessage showed bare URL without preview text
- **Fix:** Added subject and message parameters to all ShareLink instances
- **Files modified:** ProfileView.swift, AddFriendSheet.swift, FriendsTabView.swift
- **Committed in:** `46ef52a` (fixed by orchestrator during checkpoint)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Minor UX polish fix. No scope creep.

## Issues Encountered
- Universal Links cannot be tested in simulator (expected — requires physical device + deployed AASA file)
- Invite link returns 404 when clicked (expected — server from plan 16-01 not yet deployed to Synology)

## User Setup Required

**External services require manual configuration:**
- Associated Domains capability must be enabled in Apple Developer Portal for app ID se.sandenskog.hotandcoldfriends
- Server from plan 16-01 must be deployed to Synology for Universal Links to work end-to-end

## Next Phase Readiness
- iOS invite system complete — all client-side code in place
- Blocked on server deployment (plan 16-01 code exists but needs Synology deploy)
- After deploy: AASA file will be served, Universal Links will activate, invite pages will render

## Self-Check: PASSED

- SUMMARY.md: FOUND
- Commit 9d3706b (Task 1): FOUND
- Commit 6d59ec6 (Task 2): FOUND
- Commit 46ef52a (post-checkpoint fix): FOUND

---
*Phase: 16-invite-foundation*
*Completed: 2026-03-07*
