---
id: T02
parent: S01
milestone: M003
provides:
  - Persistent multi-use invite codes (redeemedBy array)
  - Universal Links handler in onOpenURL
  - ClipboardInviteService for deferred deep link
  - Invite share UI on Profile, AddFriend, FriendsTabView header
  - Associated Domains entitlement
key_files:
  - HotAndColdFriends/Services/InviteService.swift
  - HotAndColdFriends/Services/ClipboardInviteService.swift
  - HotAndColdFriends/App/HotAndColdFriendsApp.swift
  - project.yml
key_decisions:
  - "Invite codes permanent multi-use via redeemedBy array"
  - "ShareLink subject/message params for rich iMessage previews"
  - "One-time clipboard check via UserDefaults flag"
patterns_established:
  - "Lazy-permanent tokens: getOrCreateInviteToken queries existing before creating new"
  - "Clipboard deferred deep link: friendscast-invite:token:timestamp format with 7-day TTL"
observability_surfaces:
  - none
duration: 15min
verification_result: passed
completed_at: 2026-03-07
blocker_discovered: false
---

# T02: iOS invite system with persistent codes, Universal Links, and deferred deep link

**Refactored InviteService to permanent multi-use codes, added Universal Links handler, clipboard deferred deep link service, and invite share UI on three app surfaces**

## What Happened

Refactored InviteService from delete-on-redeem to persistent multi-use codes with redeemedBy array. Updated invite URLs from custom scheme (hotandcold://) to HTTPS Universal Links (apps.sandenskog.se/invite/). Created ClipboardInviteService that checks for friendscast-invite: prefix in clipboard on first app launch with 7-day TTL validation. Added Universal Links handler in HotAndColdFriendsApp.onOpenURL supporting both HTTPS and legacy custom scheme. Placed ShareLink invite buttons on ProfileView, AddFriendSheet, and FriendsTabView header toolbar.

Post-checkpoint fix: Added subject and message parameters to all ShareLink instances for rich iMessage previews (bare URL was showing without preview text).

## Verification

- Xcode build succeeds with all changes
- InviteService creates/retrieves persistent invite codes
- ClipboardInviteService validates token format and TTL
- ShareLink shows rich preview with subject/message params
- Associated Domains entitlement added to project.yml

## Diagnostics

- Invite codes: Firebase Console → Firestore → invites collection
- Universal Links: Requires physical device + deployed AASA file (cannot test in simulator)

## Deviations

ShareLink showed bare URL in iMessage — fixed by adding subject/message params (commit 46ef52a). Minor UX polish, no scope creep.

## Known Issues

- Universal Links cannot be tested in simulator
- Server not yet deployed — invite pages return 404 until Synology deployment

## Files Created/Modified

- `HotAndColdFriends/Services/InviteService.swift` — Persistent codes with redeemedBy, HTTPS URLs, getOrCreateInviteToken
- `HotAndColdFriends/Services/ClipboardInviteService.swift` — NEW: Clipboard deferred deep link with TTL
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` — Universal Links + clipboard check + toast overlay
- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` — ShareLink in header toolbar
- `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift` — Invite via Link section
- `HotAndColdFriends/Features/Profile/ProfileView.swift` — Updated to getOrCreateInviteToken
- `project.yml` — Associated Domains entitlement (applinks:apps.sandenskog.se)
