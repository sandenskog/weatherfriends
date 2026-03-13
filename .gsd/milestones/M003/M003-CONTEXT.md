# M003: v3.0 Virality & Polish — Context

## Goal

Make the app visually complete, build an invite experience that drives virality, and create sharing and engagement loops.

## Why This Milestone

v1.0 and v2.0 built the complete feature set and design system. v3.0 focuses on growth: making it easy and rewarding to invite friends, share weather content, and stay engaged. Without virality loops, the app depends entirely on organic discovery.

## Key Context

- **Codebase:** 8,846 lines Swift + Firebase Cloud Functions (TypeScript)
- **Design system:** Bubble Pop fully implemented but only partially adopted in feature views
- **Invite system:** Basic invite links exist from v2.0 — v3.0 upgrades to Universal Links + web fallback
- **Web infrastructure:** Express server on apps.sandenskog.se (Docker/Synology) — serves AASA, invite pages, static content
- **Constraints:** Warm, social feel — no minimalist/monochromatic. No gamification. iOS only.

## Tech Debt Carried Forward

- BubblePopTypography only in 3/~11 feature views
- BubblePopSpacing/CornerRadius only in 2 views
- FriendMapView uses initials() instead of AvatarView (MapAnnotation limitation)
- lookupAuthUid deprecated but still present
- Firestore collectionGroup("friends") composite index unverified
