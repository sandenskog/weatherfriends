---
phase: 15-design-system-cleanup
plan: 01
subsystem: ui
tags: [swiftui, avatar, design-system, dead-code-removal]

# Dependency graph
requires:
  - phase: 09-design-system
    provides: AvatarView component with temperature-zone gradient
provides:
  - All avatar rendering consolidated through AvatarView
  - MotionReducer dead code removed
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [AvatarView as single avatar component across all views]

key-files:
  created: []
  modified:
    - HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift
    - HotAndColdFriends/Features/Chat/ConversationListView.swift
    - HotAndColdFriends/Features/Profile/FriendProfileView.swift
    - HotAndColdFriends/Features/Profile/EditProfileView.swift
    - HotAndColdFriends/Features/Chat/NewConversationSheet.swift
    - HotAndColdFriends/Features/FriendList/FriendCategoryView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "Group chat icon (person.3.fill) kept as separate branch - AvatarView is for individual users only"
  - "EditProfileView preserves selectedImage branch for photo picker, AvatarView only for fallback"

patterns-established:
  - "All avatar circles must use AvatarView - no manual initialsCircle implementations"

requirements-completed: [COMP-06]

# Metrics
duration: 7min
completed: 2026-03-06
---

# Phase 15 Plan 01: Avatar Migration & Dead Code Cleanup Summary

**All 6 remaining initialsCircle() implementations migrated to AvatarView with temperature-zone gradients, MotionReducer dead code removed**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-06T16:15:23Z
- **Completed:** 2026-03-06T16:22:40Z
- **Tasks:** 2
- **Files modified:** 8 (6 Swift views + 1 deleted file + pbxproj)

## Accomplishments
- Migrated WeatherDetailSheet, ConversationListView, FriendProfileView, EditProfileView, NewConversationSheet, and FriendCategoryView from gray initialsCircle to AvatarView
- WeatherDetailSheet and FriendCategoryView pass actual temperature data for zone-appropriate gradients
- Removed MotionReducedModifier and CrossfadeIfReducedModifier (unused dead code) and their source file
- Build verified clean after all changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate all initialsCircle() to AvatarView** - `acbb64c` (feat)
2. **Task 2: Remove MotionReducer dead code and verify build** - `531daee` (chore)

## Files Created/Modified
- `HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift` - AvatarView with temperature data
- `HotAndColdFriends/Features/Chat/ConversationListView.swift` - AvatarView with nil temperature, kept group icon
- `HotAndColdFriends/Features/Profile/FriendProfileView.swift` - AvatarView with nil temperature
- `HotAndColdFriends/Features/Profile/EditProfileView.swift` - AvatarView fallback, kept photo picker image branch
- `HotAndColdFriends/Features/Chat/NewConversationSheet.swift` - AvatarView with nil temperature
- `HotAndColdFriends/Features/FriendList/FriendCategoryView.swift` - AvatarView with temperature data
- `HotAndColdFriends/Features/Animations/MotionReducer.swift` - Deleted (dead code)
- `HotAndColdFriends.xcodeproj/project.pbxproj` - Removed MotionReducer.swift references

## Decisions Made
- Group chat icon (person.3.fill) kept as separate ZStack branch since AvatarView is for individual users
- EditProfileView preserves the selectedImage branch from PhotosPicker; AvatarView only renders when no local image is selected
- Removed frame/clipShape wrappers around AvatarView calls since AvatarView handles its own sizing internally

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed MotionReducer.swift from Xcode project references**
- **Found during:** Task 2 (Remove MotionReducer dead code)
- **Issue:** Deleting the file caused build failure because pbxproj still referenced it
- **Fix:** Removed 4 MotionReducer references from project.pbxproj (PBXBuildFile, PBXFileReference, PBXGroup, Sources)
- **Files modified:** HotAndColdFriends.xcodeproj/project.pbxproj
- **Verification:** xcodebuild succeeded after removal
- **Committed in:** 531daee (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for build to succeed. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- COMP-06 requirement satisfied: all avatars render via AvatarView with temperature-zone gradient
- Design system is now consistent across all views

---
*Phase: 15-design-system-cleanup*
*Completed: 2026-03-06*
