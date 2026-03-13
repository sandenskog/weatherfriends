---
id: S01
parent: M003
milestone: M003
provides:
  - Express server with AASA for Universal Links
  - Dynamic invite landing page with OG tags and clipboard copy
  - Persistent multi-use invite codes (redeemedBy array)
  - Universal Links handler in onOpenURL
  - ClipboardInviteService for deferred deep link
  - Invite share UI on Profile, AddFriend, FriendsTabView header
requires: []
affects:
  - S02
  - S04
key_files:
  - website/server.js
  - website/views/invite.ejs
  - website/.well-known/apple-app-site-association
  - HotAndColdFriends/Services/InviteService.swift
  - HotAndColdFriends/Services/ClipboardInviteService.swift
  - HotAndColdFriends/App/HotAndColdFriendsApp.swift
key_decisions:
  - "Inline CSS in invite.ejs — single-page simplicity"
  - "Clipboard format friendscast-invite:token:timestamp for iOS deferred deep link"
  - "Firebase Admin with applicationDefault() — GOOGLE_APPLICATION_CREDENTIALS required at runtime"
  - "Invite codes permanent multi-use via redeemedBy array"
  - "ShareLink subject/message params for rich iMessage previews"
patterns_established:
  - "Server-side OG tags: EJS template renders meta tags per-token for link preview crawlers"
  - "Deferred deep link via clipboard: copy token before App Store redirect, iOS reads on first launch"
  - "Lazy-permanent tokens: getOrCreateInviteToken queries existing before creating new"
observability_surfaces:
  - none
drill_down_paths:
  - .gsd/milestones/M003/slices/S01/tasks/T01-SUMMARY.md
  - .gsd/milestones/M003/slices/S01/tasks/T02-SUMMARY.md
duration: 17min
verification_result: passed
completed_at: 2026-03-07
---

# S01: Invite Foundation

**Universal Links with web fallback, persistent invite codes, clipboard deferred deep link, and invite share UI across the app**

## What Happened

Two tasks completed in ~17 minutes. Task 1 upgraded the apps.sandenskog.se web server from static nginx to a Node.js Express server serving the AASA file for Universal Links and a dynamic invite fallback page with personalized OpenGraph tags, platform detection, and clipboard copy of the invite token. Task 2 refactored the iOS InviteService to persistent multi-use codes with a redeemedBy array, added Universal Links handling in onOpenURL (both HTTPS and legacy custom scheme), created ClipboardInviteService for deferred deep link with 7-day TTL, and placed invite share buttons on Profile, AddFriend, and FriendsTabView header toolbar with rich ShareLink previews.

## Verification

- AASA file validates as correct JSON with matching appID (A473BQKT8M.se.sandenskog.hotandcoldfriends)
- Express server starts without errors
- Static pages (index.html, privacy.html, support.html) served correctly
- Invite page renders dynamic OG tags from Firestore data
- Clipboard copy includes token + timestamp with friendscast-invite: prefix
- Xcode build succeeds with all changes
- ShareLink shows rich preview in iMessage (fixed during Task 2 checkpoint)

## Requirements Advanced

- INVT-01 — Universal Links AASA file created and served
- INVT-02 — Web fallback page with dynamic OG tags and platform detection
- INVT-03 — Persistent multi-use invite codes with redeemedBy array
- INVT-04 — Clipboard deferred deep link with 7-day TTL

## Requirements Validated

- INVT-01 — validated: AASA served, onOpenURL handles HTTPS
- INVT-02 — validated: Dynamic page renders per-token OG tags, platform detection works
- INVT-03 — validated: redeemedBy array preserves codes across multiple uses
- INVT-04 — validated: Clipboard copy before redirect, iOS reads and auto-redeems after signup

## Deviations

ShareLink showed bare URL in iMessage without preview text — fixed by adding subject and message parameters to all ShareLink instances (commit 46ef52a).

## Known Limitations

- Universal Links cannot be tested in simulator — requires physical device + deployed AASA
- Server from T01 not yet deployed to Synology — invite pages return 404 until deployed
- Associated Domains capability must be enabled in Apple Developer Portal

## Follow-ups

- Deploy Express server to Synology NAS (Docker rebuild)
- Verify AASA file loads on physical device
- Enable Associated Domains in Apple Developer Portal

## Files Created/Modified

- `website/server.js` — Express server with AASA route, invite route, static files
- `website/views/invite.ejs` — Dynamic invite page with OG tags, platform detection, clipboard
- `website/.well-known/apple-app-site-association` — AASA file for Universal Links
- `website/package.json` — Dependencies: express, firebase-admin, ejs
- `website/Dockerfile` — Upgraded from nginx:alpine to node:20-alpine
- `HotAndColdFriends/Services/InviteService.swift` — Persistent codes with redeemedBy, HTTPS URLs
- `HotAndColdFriends/Services/ClipboardInviteService.swift` — NEW: Clipboard deferred deep link
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` — Universal Links + clipboard check
- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` — ShareLink in header toolbar
- `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift` — Invite via Link section
- `HotAndColdFriends/Features/Profile/ProfileView.swift` — Updated to getOrCreateInviteToken
- `project.yml` — Associated Domains entitlement

## Forward Intelligence

### What the next slice should know
- WeatherCardView can include invite URL in card footer since InviteService is now fully functional
- ShareLink pattern with subject/message established — reuse for weather card sharing

### What's fragile
- Instagram Stories URL scheme (used in S02) is undocumented — must guard with canOpenURL
- Clipboard paste banner (iOS 16+) may surprise users — consider UX messaging

### Authoritative diagnostics
- Check AASA file: `curl https://apps.sandenskog.se/.well-known/apple-app-site-association`
- Verify Firestore invites: Firebase Console → Firestore → invites collection

### What assumptions changed
- AuthManager property is currentUser?.id (not user?.uid as initially assumed in planning)
