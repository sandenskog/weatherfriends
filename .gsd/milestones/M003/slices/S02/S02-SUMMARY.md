---
id: S02
parent: M003
milestone: M003
provides:
  - WeatherCardView — shareable 9:16 portrait weather card
  - WeatherCardRenderer — ImageRenderer-based card-to-UIImage conversion
  - WeatherCardCategory — 7 weather background categories with gradient fallbacks
  - WeatherCardPreviewSheet — preview and sharing UI
  - InstagramStoriesService — Instagram Stories background image sharing
  - Swipe-to-share action on friend list rows
requires:
  - slice: S01
    provides: InviteService with invite URL for card footer
affects: []
key_files:
  - HotAndColdFriends/Features/WeatherCard/WeatherCardView.swift
  - HotAndColdFriends/Features/WeatherCard/WeatherCardRenderer.swift
  - HotAndColdFriends/Features/WeatherCard/WeatherCardBackground.swift
  - HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift
  - HotAndColdFriends/Features/WeatherCard/InstagramStoriesService.swift
  - HotAndColdFriends/Features/FriendList/FriendListView.swift
key_decisions:
  - "Avatar uses gradient+initials only (no photoURL) for ImageRenderer compatibility"
  - "Asset fallback pattern: try UIImage(named:) first, fall to gradient"
  - "AuthManager property is currentUser?.id (not user?.uid as plan assumed)"
  - "Instagram Stories sharing via UIPasteboard with 5-minute expiration"
patterns_established:
  - "Weather card background: asset override via weather-bg-{category} naming convention"
  - "Card text style: white foreground with black shadow for readability on all backgrounds"
  - "Leading swipe actions for share, trailing for favorites"
  - "Preview sheet pattern: render card onAppear, fetch invite token async"
observability_surfaces:
  - none
drill_down_paths:
  - .gsd/milestones/M003/slices/S02/tasks/T01-SUMMARY.md
  - .gsd/milestones/M003/slices/S02/tasks/T02-SUMMARY.md
duration: 7min
verification_result: passed
completed_at: 2026-03-07
---

# S02: Shareable Weather Cards

**Weather card generation with 7 category-mapped gradient backgrounds, share sheet integration, and Instagram Stories sharing via swipe action**

## What Happened

Two tasks completed in ~7 minutes. Task 1 created the weather card rendering pipeline: WeatherCardCategory enum mapping WeatherKit symbols to 7 background themes (clear day/night, cloudy, rain, snow, storm, fog), WeatherCardView as a 390×693 portrait card with avatar, name, city, temperature, icon, condition, date, and branding, and WeatherCardRenderer wrapping ImageRenderer for Retina UIImage export. Avatar uses gradient+initials only (no photoURL) since ImageRenderer can't wait for AsyncImage. Asset fallback pattern allows designers to drop in background images without code changes.

Task 2 built the sharing flow: InstagramStoriesService with canOpenURL guard and UIPasteboard sharing, WeatherCardPreviewSheet with card preview + ShareLink (rendered image + invite URL) + conditional Instagram button, and leading-edge swipe action on friend list rows in both favorites and others sections. Info.plist configured with instagram-stories URL scheme.

## Verification

- Xcode build succeeds with all changes
- Weather card renders with correct layout and gradient backgrounds
- ImageRenderer produces Retina-scale UIImage
- ShareLink shares rendered image with invite URL
- Instagram Stories button conditionally visible based on canOpenURL
- Swipe actions appear on friend list rows

## Requirements Validated

- CARD-01 — validated: Weather card generates with weather, city, avatar for a friend
- CARD-02 — validated: Share sheet shares rendered card image with invite URL
- CARD-04 — validated: Instagram Stories sharing via UIPasteboard with canOpenURL guard

## Deviations

- WeatherCardBackground namespace: plan specified `WeatherCardBackground.background(for:)` but type was named `WeatherCardCategory` — trivial naming fix
- AuthManager property: plan assumed `user?.uid` but actual property is `currentUser?.id` — adapted in implementation

## Known Limitations

- Instagram Stories URL scheme is undocumented — may break with Instagram updates
- Card backgrounds are gradient-only until designer provides actual imagery
- AsyncImage not usable in ImageRenderer — avatars show initials only

## Follow-ups

- User feedback captured for future: remove dark mode, better share preview, weather imagery backgrounds, "My Weather" section, new subdomain, new app icon
- Background images can be added to Assets.xcassets as weather-bg-{category} without code changes

## Files Created/Modified

- `HotAndColdFriends/Features/WeatherCard/WeatherCardBackground.swift` — 7 weather categories with symbol mapping and gradients
- `HotAndColdFriends/Features/WeatherCard/WeatherCardView.swift` — 9:16 portrait weather card
- `HotAndColdFriends/Features/WeatherCard/WeatherCardRenderer.swift` — ImageRenderer wrapper for Retina export
- `HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift` — Preview + sharing UI
- `HotAndColdFriends/Features/WeatherCard/InstagramStoriesService.swift` — Instagram Stories via UIPasteboard
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` — Leading swipe action for share
- `HotAndColdFriends/Resources/Info.plist` — instagram-stories URL scheme

## Forward Intelligence

### What the next slice should know
- WeatherCardView and WeatherCardRenderer are reusable for comparison cards and daily digest cards
- ShareLink pattern established — reuse for new card types
- User wants weather imagery instead of gradients for card backgrounds — may add in S03 or S05

### What's fragile
- Instagram Stories UIPasteboard API is undocumented — test regularly with Instagram updates
- ImageRenderer has memory limitations with large/complex views

### Authoritative diagnostics
- Card rendering: Preview WeatherCardView in Xcode canvas with sample data
- Instagram sharing: Test on physical device with Instagram installed

### What assumptions changed
- AuthManager uses currentUser?.id not user?.uid — verified against actual codebase
