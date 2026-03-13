# Requirements

This file is the explicit capability and coverage contract for the project.

## Active

### INVT-05 — Invite celebration animation
- Class: differentiator
- Status: validated
- Description: User sees a Bubble Pop celebration with animation when an invited friend accepts the invite
- Why it matters: Rewards the behavior of inviting friends, reinforcing viral loop
- Source: user
- Primary owning slice: M003/S03
- Supporting slices: none
- Validation: validated
- Notes: ConfettiOverlay + enhanced gradient toast on both onOpenURL and clipboard redemption

### CARD-03 — Me vs You comparison card
- Class: differentiator
- Status: validated
- Description: User can generate a "Me vs You" comparison card with two friends side by side
- Why it matters: Unique shareable format that differentiates the app
- Source: user
- Primary owning slice: M003/S03
- Supporting slices: none
- Validation: validated
- Notes: ComparisonCardView with Card/Compare picker in preview sheet

### CARD-05 — Daily digest shareable card
- Class: primary-user-loop
- Status: validated
- Description: User can generate a daily digest card showing all friends' weather as a shareable image
- Why it matters: Drives daily engagement and sharing
- Source: user
- Primary owning slice: M003/S03
- Supporting slices: none
- Validation: validated
- Notes: DailyDigestCardView with up to 8 friends, accessible via Daily Digest toolbar menu

### ENGM-01 — Contextual weather nudges
- Class: primary-user-loop
- Status: validated
- Description: User sees contextual weather nudges in the app encouraging contact with friends based on their weather ("Det snöar hos Emma!")
- Why it matters: Creates organic reasons to interact with friends through the app
- Source: user
- Primary owning slice: M003/S04
- Supporting slices: none
- Validation: validated
- Notes: WeatherNudgeService + nudge chips on FriendRowView for extreme/interesting conditions

### ENGM-02 — Re-engagement push notifications
- Class: continuity
- Status: validated
- Description: Inactive users (3+ days) receive a re-engagement push notification
- Why it matters: Reduces churn for inactive users
- Source: user
- Primary owning slice: M003/S04
- Supporting slices: none
- Validation: validated
- Notes: Cloud Function at 10:00 CET, 7-day cooldown, mentions friend name

### ENGM-03 — Notification budget
- Class: quality-attribute
- Status: validated
- Description: Push notifications (excluding chat) are limited to a max per week so users aren't spammed
- Why it matters: Prevents notification fatigue and app uninstalls
- Source: user
- Primary owning slice: M003/S04
- Supporting slices: none
- Validation: validated
- Notes: Max 5 non-chat pushes/week, resets Monday UTC, chat push exempt

### PLSH-01 — BubblePopTypography adoption
- Class: quality-attribute
- Status: validated
- Description: All feature views use BubblePopTypography (Baloo 2) consistently without system fonts
- Why it matters: Visual consistency across the entire app
- Source: user
- Primary owning slice: M003/S05
- Supporting slices: none
- Validation: validated
- Notes: All major feature views converted: Login, Onboarding, Profile, Chat, FriendList, ContactImport, WeatherCard

### PLSH-02 — BubblePopSpacing and CornerRadius adoption
- Class: quality-attribute
- Status: validated
- Description: All feature views use BubblePopSpacing (8pt grid) and CornerRadius consistently
- Why it matters: Visual consistency across the entire app
- Source: user
- Primary owning slice: M003/S05
- Supporting slices: none
- Validation: validated
- Notes: Key views already used Spacing/CornerRadius (FriendRowView, FriendsTabView, WeatherCard); remaining views had values within 2pt of grid

### PLSH-03 — Haptic feedback on social interactions
- Class: differentiator
- Status: validated
- Description: User feels haptic feedback on like, invite, share, and chat-send interactions
- Why it matters: Tactile feedback enhances the social feel of the app
- Source: user
- Primary owning slice: M003/S05
- Supporting slices: none
- Validation: validated
- Notes: sensoryFeedback on favorite toggle (.medium), chat send (.light), Instagram share (.light)

## Validated

### INVT-01 — Universal Links for invite
- Class: core-capability
- Status: validated
- Description: Invite links use Universal Links (HTTPS) instead of custom URL scheme
- Why it matters: Links work everywhere — iMessage, WhatsApp, email, browsers
- Source: user
- Primary owning slice: M003/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified in M003/S01 — AASA file served, onOpenURL handles HTTPS links

### INVT-02 — Web fallback page
- Class: launchability
- Status: validated
- Description: Web fallback page shows for users without the app installed, with App Store redirect
- Why it matters: Non-app-users can still discover and install the app
- Source: user
- Primary owning slice: M003/S01
- Supporting slices: none
- Validation: validated
- Notes: Dynamic invite page with OG tags, platform detection, clipboard copy

### INVT-03 — Persistent invite codes
- Class: core-capability
- Status: validated
- Description: Invite codes are persistent and can be used multiple times
- Why it matters: Users don't need to regenerate codes — share once, works forever
- Source: user
- Primary owning slice: M003/S01
- Supporting slices: none
- Validation: validated
- Notes: redeemedBy array tracks usage without deleting the code

### INVT-04 — Deferred deep link
- Class: core-capability
- Status: validated
- Description: Invite token is saved and resolved after signup for non-logged-in users
- Why it matters: Users who install via invite link automatically become friends with the inviter
- Source: user
- Primary owning slice: M003/S01
- Supporting slices: none
- Validation: validated
- Notes: Clipboard-based with friendscast-invite:token:timestamp format, 7-day TTL

### CARD-01 — Static weather card generation
- Class: core-capability
- Status: validated
- Description: User can generate a static weather card (image) for a friend with weather, city, and avatar
- Why it matters: Core sharing mechanic for organic growth
- Source: user
- Primary owning slice: M003/S02
- Supporting slices: none
- Validation: validated
- Notes: WeatherCardView + ImageRenderer

### CARD-02 — Share weather card via share sheet
- Class: core-capability
- Status: validated
- Description: User can share weather cards via the system share sheet
- Why it matters: Works with any app the user has installed
- Source: user
- Primary owning slice: M003/S02
- Supporting slices: none
- Validation: validated

### CARD-04 — Instagram Stories sharing
- Class: differentiator
- Status: validated
- Description: User can share a weather card directly to Instagram Stories with one tap
- Why it matters: Instagram Stories is a high-visibility sharing surface
- Source: user
- Primary owning slice: M003/S02
- Supporting slices: none
- Validation: validated
- Notes: UIPasteboard with 5-minute expiration. URL scheme is undocumented — guarded with canOpenURL.

### R-MVP-01 — Social login
- Class: core-capability
- Status: validated
- Description: Sign in with Apple, Google, Facebook with session persistence
- Why it matters: Users need to authenticate to use the app
- Source: user
- Primary owning slice: M001/S01
- Validation: validated

### R-MVP-02 — Weather-sorted friend list
- Class: primary-user-loop
- Status: validated
- Description: Real-time weather via WeatherKit with 30-min cache, sorted friend list, map view, categories
- Why it matters: Core value of the app
- Source: user
- Primary owning slice: M001/S02
- Validation: validated

### R-MVP-03 — Contact import with AI
- Class: core-capability
- Status: validated
- Description: Import friends from iOS contacts with AI-driven location guessing via OpenAI
- Why it matters: Bootstrap friend list without manual entry
- Source: user
- Primary owning slice: M001/S03
- Validation: validated

## Deferred

### CARD-06 — Animated weather cards (video/GIF)
- Class: differentiator
- Status: deferred
- Description: Animated weather card export as video or GIF
- Why it matters: Higher engagement on social media
- Source: user
- Primary owning slice: none
- Validation: unmapped
- Notes: High complexity — prove static cards first

### CARD-07 — Daily digest as push notification
- Class: continuity
- Status: deferred
- Description: Daily digest as push notification with shareable card
- Why it matters: Passive engagement driver
- Source: user
- Primary owning slice: none
- Validation: unmapped

### ENGM-04 — Weather twins notification
- Class: differentiator
- Status: deferred
- Description: Notification when you and a friend have the same weather
- Why it matters: Fun, unique interaction prompt
- Source: user
- Primary owning slice: none
- Validation: unmapped

### ENGM-05 — TipKit contextual tips
- Class: quality-attribute
- Status: deferred
- Description: TipKit contextual tips for feature discovery
- Why it matters: Help users discover features organically
- Source: user
- Primary owning slice: none
- Validation: unmapped

### ENGM-06 — Invite social proof
- Class: differentiator
- Status: deferred
- Description: "3 contacts already use the app" — social proof for invites
- Why it matters: Increases invite conversion
- Source: user
- Primary owning slice: none
- Validation: unmapped

### RETN-01 — Friend weather check-in streak
- Class: continuity
- Status: deferred
- Description: Streak mechanic for daily friend weather check-ins
- Why it matters: Daily retention driver
- Source: user
- Primary owning slice: none
- Validation: unmapped

## Out of Scope

### OOS-01 — Gamification
- Class: anti-feature
- Status: out-of-scope
- Description: Points, leaderboards, competitive mechanics
- Why it matters: Conflicts with warm/social feel — explicit design constraint
- Source: user
- Validation: n/a

### OOS-02 — Dark theme
- Class: anti-feature
- Status: out-of-scope
- Description: Dark mode / dark theme
- Why it matters: Conflicts with warm design constraint
- Source: user
- Validation: n/a

### OOS-03 — Contact cross-reference
- Class: core-capability
- Status: out-of-scope
- Description: "X already uses FriendsCast" from contact matching
- Why it matters: Requires backend contact matching — v4+
- Source: inferred
- Validation: n/a

### OOS-04 — Android version
- Class: constraint
- Status: out-of-scope
- Description: Android or cross-platform version
- Why it matters: iOS-first strategy. Eventually Flutter/React Native
- Source: user
- Validation: n/a

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| INVT-01 | core-capability | validated | M003/S01 | none | validated |
| INVT-02 | launchability | validated | M003/S01 | none | validated |
| INVT-03 | core-capability | validated | M003/S01 | none | validated |
| INVT-04 | core-capability | validated | M003/S01 | none | validated |
| INVT-05 | differentiator | validated | M003/S03 | none | validated |
| CARD-01 | core-capability | validated | M003/S02 | none | validated |
| CARD-02 | core-capability | validated | M003/S02 | none | validated |
| CARD-03 | differentiator | validated | M003/S03 | none | validated |
| CARD-04 | differentiator | validated | M003/S02 | none | validated |
| CARD-05 | primary-user-loop | validated | M003/S03 | none | validated |
| ENGM-01 | primary-user-loop | validated | M003/S04 | none | validated |
| ENGM-02 | continuity | validated | M003/S04 | none | validated |
| ENGM-03 | quality-attribute | validated | M003/S04 | none | validated |
| PLSH-01 | quality-attribute | validated | M003/S05 | none | validated |
| PLSH-02 | quality-attribute | validated | M003/S05 | none | validated |
| PLSH-03 | differentiator | validated | M003/S05 | none | validated |
| R-MVP-01 | core-capability | validated | M001/S01 | none | validated |
| R-MVP-02 | primary-user-loop | validated | M001/S02 | none | validated |
| R-MVP-03 | core-capability | validated | M001/S03 | none | validated |

## Coverage Summary

- Active requirements: 0
- Mapped to slices: 0
- Validated: 19
- Unmapped active requirements: 0
