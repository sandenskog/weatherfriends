---
id: T02
parent: S02
milestone: M003
provides:
  - WeatherCardPreviewSheet — preview and sharing UI
  - InstagramStoriesService — Instagram Stories sharing via UIPasteboard
  - Swipe-to-share action on friend list rows
key_files:
  - HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift
  - HotAndColdFriends/Features/WeatherCard/InstagramStoriesService.swift
  - HotAndColdFriends/Features/FriendList/FriendListView.swift
  - HotAndColdFriends/Resources/Info.plist
key_decisions:
  - "AuthManager property is currentUser?.id (not user?.uid)"
  - "Instagram Stories sharing via UIPasteboard with 5-minute expiration"
patterns_established:
  - "Leading swipe actions for share, trailing for favorites"
  - "Preview sheet pattern: render card onAppear, fetch invite token async"
observability_surfaces:
  - none
duration: 2min
verification_result: passed
completed_at: 2026-03-07
blocker_discovered: false
---

# T02: Sharing flow with preview sheet and Instagram Stories

**Swipe-to-share on friend rows opening preview sheet with ShareLink (image + invite URL) and conditional Instagram Stories sharing**

## What Happened

Built InstagramStoriesService with canOpenURL guard and UIPasteboard sharing (5-minute expiration). Created WeatherCardPreviewSheet showing rendered card preview with ShareLink (rendered image + invite URL text) and conditional Instagram Stories button. Added leading-edge swipe action "Share" on friend rows in both favorites and others sections of FriendListView. Configured Info.plist with instagram-stories URL scheme in LSApplicationQueriesSchemes.

## Verification

- Xcode build succeeds
- InstagramStoriesService uses canOpenURL guard correctly
- WeatherCardPreviewSheet renders card and shows sharing options
- Swipe actions appear on friend list rows
- Info.plist includes instagram-stories scheme

## Diagnostics

Test on physical device with Instagram installed for full Stories sharing flow.

## Deviations

AuthManager property: plan assumed `user?.uid` but actual is `currentUser?.id` — adapted in implementation. Trivial fix.

## Known Issues

- Instagram Stories URL scheme is undocumented — guard with canOpenURL
- Sharing flow requires physical device for full testing

## Files Created/Modified

- `HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift` — Preview sheet with card, ShareLink, Instagram button
- `HotAndColdFriends/Features/WeatherCard/InstagramStoriesService.swift` — Instagram Stories via UIPasteboard
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` — Leading swipe action for share
- `HotAndColdFriends/Resources/Info.plist` — instagram-stories URL scheme in LSApplicationQueriesSchemes
