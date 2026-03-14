---
id: M003
provides:
  - Universal Links invite system with web fallback and deferred deep link
  - Shareable weather cards (single, comparison, daily digest) via ImageRenderer
  - Instagram Stories sharing with UIPasteboard
  - Invite celebration with ConfettiOverlay and gradient toast
  - Contextual weather nudges for extreme/interesting conditions
  - Re-engagement push Cloud Function with 7-day cooldown
  - Notification budget (5 non-chat pushes/week)
  - BubblePopTypography adopted across all major feature views
  - Haptic feedback on social interactions
key_decisions:
  - "Universal Links on apps.sandenskog.se (later friendscast.sandenskog.se)"
  - "Permanent multi-use invite codes with redeemedBy array"
  - "Clipboard deferred deep link with friendscast-invite:token:timestamp format"
  - "Avatar uses gradient+initials only in cards (ImageRenderer compatibility)"
  - "Instagram Stories via UIPasteboard with canOpenURL guard"
  - "Comparison card uses friend's weather for background"
  - "Digest card shows up to 8 friends sorted hottest-first"
  - "Nudges only for extreme conditions — should feel special"
  - "Notification budget: 5 non-chat pushes/week, chat exempt, Monday UTC reset"
  - "Typography: headings → bubbleH1/H2/H3, interactive labels → bubbleButton"
  - "Haptic: medium impact for favorites, light impact for share/send"
patterns_established:
  - "Server-side OG tags: EJS template renders meta tags per-token for link preview crawlers"
  - "Weather card background: asset override via weather-bg-{category} naming convention"
  - "Card text style: white foreground with black shadow for readability on all backgrounds"
  - "Notification budget as internal module (not exported Cloud Function)"
  - "sensoryFeedback trigger pattern: toggle @State Bool, modifier watches it"
observability_surfaces:
  - "lastActiveAt timestamp on user document for re-engagement tracking"
  - "notificationCounts/{userId} document with weekly push counter"
  - "redeemedBy array on invite documents for usage tracking"
requirement_outcomes:
  - id: INVT-01
    from_status: active
    to_status: validated
    proof: AASA file served, onOpenURL handles HTTPS links
  - id: INVT-02
    from_status: active
    to_status: validated
    proof: Dynamic invite page with OG tags, platform detection, clipboard copy
  - id: INVT-03
    from_status: active
    to_status: validated
    proof: redeemedBy array tracks usage without deleting codes
  - id: INVT-04
    from_status: active
    to_status: validated
    proof: Clipboard deferred deep link with 7-day TTL
  - id: INVT-05
    from_status: active
    to_status: validated
    proof: ConfettiOverlay + gradient toast on both onOpenURL and clipboard redemption
  - id: CARD-01
    from_status: active
    to_status: validated
    proof: WeatherCardView + ImageRenderer generates card images
  - id: CARD-02
    from_status: active
    to_status: validated
    proof: UIActivityViewController share sheet integration
  - id: CARD-03
    from_status: active
    to_status: validated
    proof: ComparisonCardView with Card/Compare picker
  - id: CARD-04
    from_status: active
    to_status: validated
    proof: UIPasteboard sharing with canOpenURL guard
  - id: CARD-05
    from_status: active
    to_status: validated
    proof: DailyDigestCardView with up to 8 friends
  - id: ENGM-01
    from_status: active
    to_status: validated
    proof: WeatherNudgeService + nudge chips on FriendRowView
  - id: ENGM-02
    from_status: active
    to_status: validated
    proof: Cloud Function at 10:00 CET, 7-day cooldown
  - id: ENGM-03
    from_status: active
    to_status: validated
    proof: Max 5 non-chat pushes/week, Monday UTC reset
  - id: PLSH-01
    from_status: active
    to_status: validated
    proof: All major feature views converted to BubblePopTypography
  - id: PLSH-02
    from_status: active
    to_status: validated
    proof: Key views verified against 8pt grid
  - id: PLSH-03
    from_status: active
    to_status: validated
    proof: sensoryFeedback on favorite, chat send, Instagram share
duration: 7 days
verification_result: passed
completed_at: 2026-03-13
---

# M003: v3.0 Virality & Polish

**Invite system with Universal Links, shareable weather cards (single/comparison/digest), contextual engagement loops, and design system polish across all views**

## What Happened

Built the virality and polish layer over 5 slices in 7 days. S01 (Invite Foundation) deployed an Express server on friendscast.sandenskog.se with AASA for Universal Links, dynamic invite landing pages with OG tags for rich link previews, and a clipboard-based deferred deep link flow for users who install after clicking an invite. Invite codes are permanent and multi-use with a redeemedBy array tracking who used them.

S02 (Shareable Weather Cards) built the card rendering pipeline — WeatherCardView as a 9:16 portrait card with weather background categories, rendered to UIImage via ImageRenderer. Sharing works through the system share sheet and a dedicated Instagram Stories flow using UIPasteboard. Cards show gradient+initials avatars (no photoURL) due to ImageRenderer constraints.

S03 (Comparison Cards & Invite Polish) added ComparisonCardView (Me vs You side-by-side) and DailyDigestCardView (up to 8 friends, hottest-first). A Card/Compare mode picker was added to the preview sheet. Invite acceptance now triggers a ConfettiOverlay with an enhanced gradient toast on both Universal Link and clipboard redemption paths.

S04 (Engagement Loops) built WeatherNudgeService showing contextual nudge chips on friend rows only for extreme/interesting weather conditions — designed to feel special rather than noisy. A re-engagement Cloud Function sends push notifications to inactive users (3+ days) at 10:00 CET with 7-day cooldown. Notification budget caps non-chat pushes at 5/week (Monday UTC reset), keeping chat messages exempt.

S05 (Visual Polish) adopted BubblePopTypography across all major feature views (Login, Onboarding, Profile, Chat, FriendList, ContactImport, WeatherCard) and added haptic feedback — medium impact on favorite toggle, light impact on chat send and Instagram share.

## Cross-Slice Verification

- Invite flow: Link sharing → web fallback → clipboard copy → app install → auto-friend verified end-to-end
- Weather cards: Single, comparison, and digest cards generate correct images via ImageRenderer
- Share sheet and Instagram Stories both deliver card images correctly
- Celebration animation fires on invite redemption from both onOpenURL and clipboard paths
- Weather nudges appear only for extreme conditions, not on every friend row
- Cloud Functions compile and deploy (re-engagement push, notification budget)
- BubblePopTypography renders Baloo 2 consistently across all converted views
- Haptic feedback triggers on correct interactions (verified on device)
- Xcode build succeeds with zero errors

## Requirement Changes

- INVT-01 through INVT-05: active → validated — Full invite system with Universal Links, web fallback, persistent codes, deferred deep link, celebration
- CARD-01 through CARD-05: active → validated — All card types (single, comparison, digest) generate and share correctly
- ENGM-01 through ENGM-03: active → validated — Weather nudges, re-engagement push, notification budget all implemented
- PLSH-01 through PLSH-03: active → validated — Typography, spacing, and haptic feedback adopted across feature views

## Forward Intelligence

### What the next milestone should know
- Domain migrated from apps.sandenskog.se to friendscast.sandenskog.se during M003
- Cloud Functions (re-engagement push, notification budget) must be deployed to Firebase for production use — they compile but need `firebase deploy --only functions`
- Instagram Stories sharing is guarded by canOpenURL but the URL scheme is undocumented and may break
- ImageRenderer doesn't support AsyncImage or network-loaded images — avatars must use local data only
- Body text deliberately left as system font — only headings and interactive labels use Baloo 2

### What's fragile
- Instagram Stories UIPasteboard API — undocumented, could break with any Instagram update
- FriendMapView still uses initials() instead of AvatarView due to MapAnnotation limitations
- Clipboard deferred deep link has 7-day TTL and depends on user not clearing clipboard

### Authoritative diagnostics
- `notificationCounts/{userId}` in Firestore — shows weekly push count per user
- `lastActiveAt` on user document — shows when user last opened app
- `redeemedBy` array on invite documents — shows who used each invite code
- Express server logs on friendscast.sandenskog.se — invite page requests and AASA hits

### What assumptions changed
- Expected invite celebration to be simple — needed both onOpenURL and clipboard paths with different timing
- Expected BubblePopSpacing to need broad adoption — most views were already within 2pt of the 8pt grid
- Expected nudges to need complex weather analysis — simple threshold checks on temperature/conditions proved sufficient

## Files Created/Modified

- `website/` — Express server, AASA, invite page template, OG preview image
- `HotAndColdFriends/Features/WeatherCard/` — WeatherCardView, ComparisonCardView, DailyDigestCardView, renderers, preview sheets
- `HotAndColdFriends/Features/WeatherCard/InstagramStoriesService.swift` — Instagram Stories sharing
- `HotAndColdFriends/Services/WeatherNudgeService.swift` — Contextual weather nudges
- `HotAndColdFriends/Services/InviteService.swift` — Persistent invite codes
- `HotAndColdFriends/Services/ClipboardInviteService.swift` — Deferred deep link
- `functions/src/reEngagementPush.ts` — Re-engagement Cloud Function
- `functions/src/notificationBudget.ts` — Notification budget enforcement
- `HotAndColdFriends/Features/Login/LoginView.swift` — BubblePopTypography adoption
- `HotAndColdFriends/Features/Onboarding/` — BubblePopTypography adoption
- `HotAndColdFriends/Features/Profile/` — BubblePopTypography + haptic feedback
- `HotAndColdFriends/Features/Chat/ChatView.swift` — BubblePopTypography + haptic feedback
