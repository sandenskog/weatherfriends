---
id: S04
parent: M003
milestone: M003
provides:
  - WeatherNudgeService — contextual nudge text for interesting weather
  - Nudge chips on FriendRowView for extreme/interesting conditions
  - Re-engagement push Cloud Function (daily at 10:00 CET)
  - Notification budget (max 5 non-chat pushes per user per week)
  - lastActiveAt tracking on user document
requires:
  - slice: S01
    provides: Push notification infrastructure (FCM tokens)
affects:
  - S05
key_files:
  - HotAndColdFriends/Services/WeatherNudgeService.swift
  - HotAndColdFriends/Features/FriendList/FriendRowView.swift
  - HotAndColdFriends/Services/UserService.swift
  - HotAndColdFriends/App/HotAndColdFriendsApp.swift
  - functions/src/reEngagementPush.ts
  - functions/src/notificationBudget.ts
  - functions/src/weatherAlertTrigger.ts
key_decisions:
  - "Nudges only for extreme conditions — should feel special, not on every row"
  - "Re-engagement push: 3-day inactivity threshold, 7-day cooldown between sends"
  - "Budget: max 5 non-chat pushes/week, chat push exempt"
  - "lastActiveAt: fire-and-forget on app launch"
patterns_established:
  - "Notification budget as internal module (not exported Cloud Function)"
  - "canSendNotification/recordNotification pattern for budget enforcement"
  - "Weekly budget reset on Monday 00:00 UTC"
observability_surfaces:
  - "Cloud Function logs: sendReEngagementPush sent/skipped counts"
  - "Firestore: users/{uid}.notificationBudget.count for budget inspection"
  - "Firestore: users/{uid}.lastActiveAt for activity tracking"
drill_down_paths: []
duration: 15min
verification_result: passed
completed_at: 2026-03-13
---

# S04: Engagement Loops

**Weather nudge chips, re-engagement push for inactive users, and notification budget limiting non-chat pushes**

## What Happened

Four tasks completed. T01 created WeatherNudgeService — a pure function returning short nudge strings for extreme weather (heatwave, freezing, snow, thunderstorm, heavy rain, beach weather) and added nudge chips to FriendRowView as zone-colored capsules below the city name. T02+T03 built the Cloud Functions: reEngagementPush runs daily at 10:00 CET, queries users inactive 3+ days with a valid FCM token, and sends a personalized push mentioning their top friend's name — guarded by 7-day cooldown and notification budget. notificationBudget provides canSendNotification/recordNotification as an internal module (max 5 non-chat pushes per week, resetting Monday UTC). weatherAlertTrigger was updated to check budget before sending. Chat push remains exempt from budget. T04 added lastActiveAt tracking via UserService.updateLastActive() called fire-and-forget on each app launch.

## Verification

- Xcode build succeeds across all commits
- TypeScript compiles clean (`tsc --noEmit`)
- WeatherNudgeService returns nudge text for extreme conditions, nil for ordinary
- FriendRowView shows nudge chip with zone-colored capsule
- reEngagementPush exports from index.ts
- notificationBudget imported in both weatherAlertTrigger and reEngagementPush
- UserService.updateLastActive added and called from app root

## Requirements Validated

- ENGM-01 — validated: Contextual weather nudge chips on friend rows
- ENGM-02 — validated: Re-engagement push Cloud Function for inactive users
- ENGM-03 — validated: Notification budget (5/week cap) enforced in weatherAlertTrigger and reEngagementPush

## Deviations

None.

## Known Limitations

- Cloud Functions must be deployed (`firebase deploy --only functions`) for re-engagement and budget to take effect
- Re-engagement push references friend displayName only — no weather data from server side
- Notification budget stored on user document — no admin dashboard for monitoring

## Follow-ups

- Deploy Cloud Functions to Firebase
- Consider adding budget info to a future admin dashboard

## Files Created/Modified

- `HotAndColdFriends/Services/WeatherNudgeService.swift` — NEW: nudge text for interesting weather
- `HotAndColdFriends/Features/FriendList/FriendRowView.swift` — Nudge chip below city name
- `HotAndColdFriends/Services/UserService.swift` — updateLastActive method
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` — lastActiveAt tracking on launch
- `functions/src/reEngagementPush.ts` — NEW: daily re-engagement push
- `functions/src/notificationBudget.ts` — NEW: weekly budget enforcement
- `functions/src/weatherAlertTrigger.ts` — Budget check before sending push
- `functions/src/index.ts` — Export sendReEngagementPush

## Forward Intelligence

### What the next slice should know
- All engagement features are in place — S05 only needs to focus on visual polish and haptics
- FriendRowView now has an optional nudge chip that may affect row height — test visual spacing

### What's fragile
- Notification budget counter resets on Monday UTC — may not align with user's local week perception
- Re-engagement push queries all users — could be slow at scale (>10K users)

### Authoritative diagnostics
- Budget: Firestore → users/{uid} → notificationBudget.count
- Activity: Firestore → users/{uid} → lastActiveAt
- Push logs: Firebase Console → Functions → sendReEngagementPush logs

### What assumptions changed
- None — infrastructure patterns from existing Cloud Functions applied cleanly
