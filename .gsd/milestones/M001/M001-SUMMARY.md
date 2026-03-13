---
id: M001
provides:
  - Complete iOS app with social login, weather-sorted friend list, contact import, chat, push, widget
key_decisions:
  - Native Swift/SwiftUI for best performance
  - Firebase backend for rapid development
  - iOS Contacts with AI location guessing
  - Auth UID in conversations (not Friend.id)
  - Deterministic conversation ID (sorted UIDs joined with _)
patterns_established:
  - "@Observable @MainActor on all services and ViewModels"
  - "Service injection via parameter (not @Environment in ViewModels)"
  - "Cloud Function proxy for third-party APIs (OpenAI)"
  - "ImportReviewMode enum for shared view with different flows"
observability_surfaces:
  - none
requirement_outcomes:
  - id: R-MVP-01
    from_status: active
    to_status: validated
    proof: Social login with Apple/Google/Facebook working with session persistence
  - id: R-MVP-02
    from_status: active
    to_status: validated
    proof: Weather-sorted friend list with WeatherKit, map view, categories
  - id: R-MVP-03
    from_status: active
    to_status: validated
    proof: Contact import with AI location guessing via OpenAI Cloud Function
duration: 3 days
verification_result: passed
completed_at: 2026-03-04
---

# M001: v1.0 Hot & Cold Friends MVP

**Complete iOS weather-friends app with social login, real-time weather, contact import, chat, push notifications, and home screen widget**

## What Happened

Built the complete MVP in 3 days across 13 phases and 24 plans. Foundation phase established SwiftUI + Firebase architecture with social auth (Apple/Google/Facebook). Core experience added weather-sorted friend list with WeatherKit and 30-min cache. Contact import used iOS Contacts with AI-driven location guessing via OpenAI Cloud Function proxy. Real-time chat (1-to-1 + group) with push notifications, moderation (App Store requirement), and weather reactions. Three views (sorted list, MapKit map, weather categories), daily weather summary, iOS widget, animated weather illustrations, and account deletion.

Five gap-closure phases (4.1–4.5) addressed integration issues discovered after main phases — primarily auth UID vs Friend.id confusion that required three fixes. Milestone audit caught remaining tech debt leading to Phase 7 (cleanup) and Phase 8 (integration fixes).

## Cross-Slice Verification

- All 24 plans executed and committed with atomic task commits
- Xcode build verified at each phase
- Auth flow tested with all three providers
- Chat verified with real Firestore listeners
- Push notifications tested via Firebase Console
- Widget rendered correctly in simulator

## Requirement Changes

- R-MVP-01: active → validated — Social login with session persistence confirmed
- R-MVP-02: active → validated — Weather-sorted list, map, categories all working
- R-MVP-03: active → validated — Contact import with AI location guessing functional

## Forward Intelligence

### What the next milestone should know
- BubblePopTypography/Spacing only partially adopted — explicit "adopt in all views" scope needed
- lookupAuthUid based on displayName is not unique — needs invite link replacement

### What's fragile
- WeatherAlertService.checkAlertsForFriends only runs at cold start — needs proper scheduling
- Auth UID vs Friend.id distinction is critical and was a recurring source of bugs

### What assumptions changed
- displayName-based friend lookup assumed unique names — proved unreliable, replaced in M002

## Files Created/Modified

- `HotAndColdFriends/` — Complete iOS app source (7,576 lines Swift)
- `functions/` — Firebase Cloud Functions (TypeScript)
- `project.yml` — Xcode project generation config
- `HotAndColdFriendsWidget/` — iOS home screen widget
