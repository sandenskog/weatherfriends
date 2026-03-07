---
phase: 16-invite-foundation
verified: 2026-03-07T10:15:00Z
status: passed
score: 12/12 must-haves verified
---

# Phase 16: Invite Foundation Verification Report

**Phase Goal:** Invite-lankar fungerar overallt dar lankar kan delas och leder nya anvandare hela vagen till appen och vanskapen
**Verified:** 2026-03-07T10:15:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

Success Criteria from ROADMAP.md:

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | User kan skicka invite-lank via iMessage/WhatsApp och mottagaren kan klicka den for att oppna appen direkt | VERIFIED | ShareLink on 3 locations (FriendsTabView:117, ProfileView:65, AddFriendSheet), AASA with applinks in .well-known/apple-app-site-association, Associated Domains in project.yml:72, onOpenURL handler in App.swift:44-57 |
| SC-2 | User utan appen installerad ser webbsida med App Store-lank och app-branding | VERIFIED | website/views/invite.ejs renders full page with OG tags, platform detection (iOS btn vs "iPhone only" message), App Store link, FriendsCast branding |
| SC-3 | User som installerar appen via invite-lank blir automatiskt van med inbjudaren efter signup (deferred deep link) | VERIFIED | ClipboardInviteService.swift:50 checkAndRedeemIfNeeded called in App.swift:88-93, clipboard parsed with friendscast-invite: prefix, auto-redeems via InviteService.redeemInvite |
| SC-4 | Invite-kod kan anvandas av flera personer utan att bli ogiltig | VERIFIED | InviteDocument has redeemedBy:[String] array (InviteService.swift:10), redeemInvite uses FieldValue.arrayUnion (line 182-184), no delete call |

Plan 01 must_haves truths:

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T1 | AASA-filen serveras korrekt med application/json content-type | VERIFIED | server.js:19-22 sets Content-Type and sendFile |
| T2 | Invite-lank med giltig token visar personlig sida med inbjudarens namn och stad | VERIFIED | server.js:29-48 Firestore lookup + render, invite.ejs:142-150 shows senderName and senderCity |
| T3 | Invite-lank med ogiltig token visar generisk 404-sida | VERIFIED | server.js:31-32 returns 404 with valid:false, invite.ejs:174-178 shows "no longer valid" |
| T4 | OpenGraph-meta-taggar renderas server-side per token | VERIFIED | invite.ejs:6-18 conditional OG tags with senderName, senderCity, token |
| T5 | iOS-besokare ser App Store-knapp, Android/desktop ser "iPhone only" | VERIFIED | server.js:37-38 UA detection, invite.ejs:157-171 conditional rendering |
| T6 | Clipboard-copy av invite-token sker innan App Store-redirect | VERIFIED | invite.ejs:188-222 redirectToAppStore with clipboard.writeText + 500ms delay + fallback |

Plan 02 must_haves truths:

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T7 | Invite-kod ar permanent -- raderas INTE efter redemption | VERIFIED | InviteService.swift:182 uses arrayUnion, no .delete() call anywhere |
| T8 | Flera personer kan anvanda samma invite-kod | VERIFIED | redeemedBy is [String] array, arrayUnion appends new UIDs |
| T9 | Invite-lank anvander HTTPS Universal Link | VERIFIED | InviteService.swift:89 returns https://apps.sandenskog.se/invite/ |
| T10 | Appen hanterar bade Universal Links och gamla custom scheme-lankar | VERIFIED | App.swift:44-79 handles both apps.sandenskog.se and hotandcold:// |
| T11 | Clipboard-check sker bara en gang | VERIFIED | ClipboardInviteService.swift:15-18 UserDefaults flag, guard at line 56 |
| T12 | Invite-kod tillganglig pa tre stallen: Profil, AddFriend, header | VERIFIED | ProfileView:65 ShareLink, AddFriendSheet ShareLink, FriendsTabView:117 ShareLink |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `website/server.js` | Express server with AASA, invite, static | VERIFIED | 60 lines, Firestore lookup, AASA route, static files, ejs rendering |
| `website/views/invite.ejs` | Dynamic invite page with OG tags, clipboard | VERIFIED | 226 lines, server-rendered OG tags, platform detection, clipboard JS with fallback |
| `website/.well-known/apple-app-site-association` | AASA file with applinks | VERIFIED | Valid JSON, appIDs: A473BQKT8M.se.sandenskog.hotandcoldfriends, /invite/* path |
| `website/Dockerfile` | Node.js Docker image | VERIFIED | node:20-alpine, npm ci, copies all dirs, EXPOSE 80 |
| `website/package.json` | Dependencies: express, firebase-admin, ejs | VERIFIED | All three deps present with correct versions |
| `HotAndColdFriends/Services/InviteService.swift` | Persistent codes, HTTPS URL, redeemedBy | VERIFIED | 186 lines, redeemedBy array, getOrCreateInviteToken, HTTPS URL, arrayUnion |
| `HotAndColdFriends/Services/ClipboardInviteService.swift` | Clipboard check with friendscast-invite: | VERIFIED | 86 lines, prefix parsing, 7-day TTL, UserDefaults one-time check, toast properties |
| `HotAndColdFriends/App/HotAndColdFriendsApp.swift` | Universal Links + clipboard in onOpenURL | VERIFIED | 119 lines, onOpenURL for both URL types, clipboard check in .task, toast overlay |
| `project.yml` | Associated Domains entitlement | VERIFIED | applinks:apps.sandenskog.se present at line 73 |
| `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` | ShareLink in header toolbar | VERIFIED | ShareLink at line 117-125 with invite URL, getOrCreateInviteToken in .task |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| server.js | Firestore invites | firebase-admin SDK | WIRED | Line 29: db.collection('invites').doc(token).get() |
| server.js | invite.ejs | res.render | WIRED | Lines 32, 40: res.render('invite', {...}) |
| AASA | iOS app | appIDs matching bundle ID | WIRED | A473BQKT8M.se.sandenskog.hotandcoldfriends in AASA |
| App.swift | InviteService | onOpenURL -> redeemInvite | WIRED | Lines 51-56: inviteService.redeemInvite(token:...) |
| ClipboardInviteService | InviteService | clipboard -> redeemInvite | WIRED | Line 70: inviteService.redeemInvite(...) |
| project.yml | AASA | Associated Domains | WIRED | applinks:apps.sandenskog.se matches AASA host |
| FriendsTabView | InviteService | ShareLink with invite URL | WIRED | Line 206: inviteService.getOrCreateInviteToken, line 207: inviteService.inviteURL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| INVT-01 | 01, 02 | Universal Links (HTTPS) instead of custom URL scheme | SATISFIED | AASA file, Associated Domains, HTTPS inviteURL, onOpenURL handler |
| INVT-02 | 01 | Web fallback page with App Store redirect | SATISFIED | invite.ejs with platform detection, OG tags, clipboard copy, App Store button |
| INVT-03 | 02 | Persistent multi-use invite codes | SATISFIED | redeemedBy array, arrayUnion, no delete, getOrCreateInviteToken |
| INVT-04 | 02 | Deferred deep link via clipboard after signup | SATISFIED | ClipboardInviteService with friendscast-invite: prefix, 7-day TTL, one-time check |

No orphaned requirements found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| - | - | - | - | No anti-patterns found |

No TODO/FIXME/PLACEHOLDER comments. No stub implementations. No empty handlers. All artifacts are substantive.

### Human Verification Required

### 1. Universal Links End-to-End

**Test:** Deploy server to Synology, open invite link on physical iPhone
**Expected:** Link opens directly in app (if installed) or shows invite web page (if not)
**Why human:** Universal Links require deployed AASA + physical device; cannot test in simulator

### 2. Clipboard Deferred Deep Link Flow

**Test:** On web invite page, tap "Get FriendsCast", install app, sign up
**Expected:** After signup, automatically become friends with inviter; toast shows "You are now friends with [name]!"
**Why human:** Requires real App Store install flow and clipboard persistence across app boundary

### 3. ShareLink Preview in iMessage

**Test:** Share invite link from any of the 3 locations via iMessage
**Expected:** Rich link preview with sender name and city (from OG tags)
**Why human:** iMessage link preview rendering is platform-specific

### Gaps Summary

No gaps found. All 12 observable truths verified. All 10 artifacts exist, are substantive, and are properly wired. All 4 requirements (INVT-01 through INVT-04) are satisfied. All 7 key links are wired. No anti-patterns detected.

The phase goal "invite-lankar fungerar overallt dar lankar kan delas och leder nya anvandare hela vagen till appen och vanskapen" is achieved at the code level. Server deployment to Synology and physical device testing are the remaining steps for end-to-end validation (infrastructure, not code).

---

_Verified: 2026-03-07T10:15:00Z_
_Verifier: Claude (gsd-verifier)_
