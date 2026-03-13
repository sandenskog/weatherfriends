---
id: M002
provides:
  - Bubble Pop Design System with 5 temperature zones
  - Custom weather icons (14 SVG), app icon, logo, empty state illustrations
  - Spring animations with Reduce Motion support
  - Invite link system replacing displayName match
  - Robust account deletion with orphaned messages cleanup
key_decisions:
  - AvatarView as single avatar component everywhere
  - MotionReducer pattern for centralized Reduce Motion support
  - Invite link system with 12-char UUID prefix tokens
  - "@Observable + @Environment for services (WeatherAlertService)"
  - "Design system tokens in enums (BubblePopColors, Typography, Spacing, Shadows)"
patterns_established:
  - "AvatarView as sole avatar component — no manual initialsCircle()"
  - "MotionReducer + spring animations with automatic Reduce Motion fallback"
  - "InviteService with UUID-prefix tokens in Firestore invites collection"
  - "Temperature zone gradients driving colors, avatars, and backgrounds"
observability_surfaces:
  - none
requirement_outcomes: []
duration: 5 days
verification_result: passed
completed_at: 2026-03-06
---

# M002: v2.0 Bubble Pop Design + Tech Debt

**Complete design system with temperature-zone gradients, custom SVG icons, spring animations, invite link system, and tech debt cleanup**

## What Happened

Built the Bubble Pop Design System over 7 phases and 13 plans in 5 days. Design Foundation (Phase 9) established the color palette, Baloo 2 typography, 8pt spacing grid, shadow scale, and 5 temperature zones (Tropical >28°, Warm 20-28°, Cool 10-20°, Cold 0-10°, Arctic <0°). Components phase (Phase 10) built AvatarView, BubblePopButton, chat bubbles with gradient, tab-switcher with glow, and weather stickers. Animations phase (Phase 11) added spring animations (heart-pop, confetti, sticker-bounce, tab-glow, pull-to-refresh cloud) all with Reduce Motion support via MotionReducer ViewModifier.

Tech Debt (Phase 12) replaced displayName-based friend lookup with invite link system and added robust account deletion. Three gap-closure phases (13-15) addressed BubblePopButton adoption, AvatarView consistency, and design system cleanup discovered by milestone audit.

## Cross-Slice Verification

- All design tokens (colors, typography, spacing, shadows) compile and render correctly
- AvatarView adopted in all views — no remaining manual initialsCircle() calls
- Reduce Motion tested with accessibility setting toggled
- Invite link system creates, shares, and redeems tokens via Firestore
- Account deletion cascades to orphaned messages

## Forward Intelligence

### What the next milestone should know
- BubblePopTypography only adopted in 3 of ~11 feature views — explicit adoption scope needed
- BubblePopSpacing/CornerRadius only adopted in 2 views
- FriendMapView uses initials() instead of AvatarView (MapAnnotation limitation)
- lookupAuthUid marked deprecated but kept for backward compatibility
- Firestore collectionGroup("friends") composite index must be verified in Firebase console

### What's fragile
- MapAnnotation doesn't fully support AvatarView — FriendMapView needs workaround
- Instagram Stories URL scheme is undocumented — may break with Instagram updates

### What assumptions changed
- Expected design token adoption to be part of building tokens — proved to be a separate explicit task
- Expected milestone audit to find few issues — found 6 verification gaps requiring 3 extra phases

## Files Created/Modified

- `HotAndColdFriends/Design/` — Design system tokens and components
- `HotAndColdFriends/Features/` — Updated views with design system
- `Design/` — SVG weather icons, app icon, logo, illustrations
- `AnimationKit/` — Spring animation package
