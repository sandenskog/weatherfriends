---
phase: 12-tech-debt
plan: 01
subsystem: auth
tags: [invite-link, deep-link, firestore, swiftui, share-sheet]

requires:
  - phase: 11-animations
    provides: confettiOverlay modifier for AddFriendSheet

provides:
  - InviteService with token CRUD (create, redeem, lookup)
  - Invite-link based friend adding (replaces displayName search)
  - ShareLink invite generation in ProfileView
  - onOpenURL handler for hotandcold://invite/<token>
  - Mutual friendship creation via invite redemption
  - Contact-imported friend merge on invite redemption

affects: [12-tech-debt]

tech-stack:
  added: []
  patterns: [invite-token-flow, deep-link-routing]

key-files:
  created:
    - HotAndColdFriends/Services/InviteService.swift
  modified:
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - HotAndColdFriends/Features/FriendList/AddFriendSheet.swift
    - HotAndColdFriends/Features/Profile/ProfileView.swift
    - HotAndColdFriends/Services/UserService.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift

key-decisions:
  - "Invite tokens are 12-char lowercase UUID prefixes stored as Firestore doc IDs in 'invites' collection"
  - "lookupAuthUid kept for ContactImportService/OnboardingViewModel backward compat but marked deprecated"
  - "Invite doc deleted after redemption (one-time use tokens)"
  - "Contact-imported friends auto-merged on invite redemption (authUid updated instead of duplicate)"

patterns-established:
  - "Invite-link flow: generate token -> share URL -> paste & redeem -> mutual friendship"
  - "Deep link routing: onOpenURL dispatches by url.host (friend vs invite)"

requirements-completed: [DEBT-01]

duration: 5min
completed: 2026-03-06
---

# Phase 12 Plan 01: Invite Link System Summary

**Invite-link friend flow replacing displayName lookups, with InviteService CRUD, ShareLink in ProfileView, and onOpenURL token redemption**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-06T13:19:24Z
- **Completed:** 2026-03-06T13:24:44Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created InviteService with create/redeem/lookup methods and Firestore-backed invite tokens
- Replaced name+city search in AddFriendSheet with invite-link paste-and-redeem flow
- Added invite link generation and iOS Share Sheet integration to ProfileView
- Integrated onOpenURL handler for hotandcold://invite/ deep links with mutual friendship creation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InviteService and integrate invite URL handling** - `4bd28ce` (feat)
2. **Task 2: Update AddFriendSheet to invite flow and add share button to ProfileView** - `aa81a3b` (feat)

## Files Created/Modified
- `HotAndColdFriends/Services/InviteService.swift` - New service: invite token CRUD, redemption with mutual friendship, contact-import merge
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` - Added InviteService to environment, expanded onOpenURL for invite handling
- `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift` - Rewritten: paste invite link/token instead of name+city search
- `HotAndColdFriends/Features/Profile/ProfileView.swift` - Added generate/share invite link button with ShareLink
- `HotAndColdFriends/Services/UserService.swift` - Marked lookupAuthUid as deprecated
- `HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift` - Added comment about contact-import lookup intent

## Decisions Made
- Used 12-char lowercase UUID prefix as token format (simple, sufficient uniqueness for invite use case)
- Invite documents deleted after redemption (one-time use) to prevent duplicate friendships
- Contact-imported friends with matching displayName get their authUid updated on redemption instead of creating duplicates
- lookupAuthUid kept (not removed) for backward compatibility with ContactImportService and OnboardingViewModel
- weatherAlertService was already in environment (plan noted it as missing but it was present)

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- No iOS Simulator installed - built with `generic/platform=iOS` destination instead (build verification successful)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Invite-link system complete and integrated
- Ready for remaining tech debt tasks in phase 12

---
*Phase: 12-tech-debt*
*Completed: 2026-03-06*
