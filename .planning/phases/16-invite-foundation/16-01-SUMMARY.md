---
phase: 16-invite-foundation
plan: 01
subsystem: infra
tags: [express, firebase-admin, ejs, universal-links, aasa, docker, opengraph]

# Dependency graph
requires: []
provides:
  - Express server on apps.sandenskog.se with AASA for Universal Links
  - Dynamic invite landing page with OG tags and clipboard copy
  - Node.js Docker container replacing nginx
affects: [16-invite-foundation, 17-invite-redemption]

# Tech tracking
tech-stack:
  added: [express, firebase-admin, ejs]
  patterns: [server-side OG tag rendering, clipboard deferred deep link, AASA serving]

key-files:
  created:
    - website/server.js
    - website/views/invite.ejs
    - website/.well-known/apple-app-site-association
    - website/package.json
    - website/.gitignore
    - website/.dockerignore
    - website/public/index.html
    - website/public/privacy.html
    - website/public/support.html
  modified:
    - website/Dockerfile
    - website/.dockerignore

key-decisions:
  - "Inline CSS in invite.ejs instead of external stylesheet — single-page simplicity"
  - "Clipboard uses friendscast-invite:token:timestamp format for iOS app to parse"
  - "Firebase Admin with applicationDefault() credentials — requires GOOGLE_APPLICATION_CREDENTIALS env var at runtime"

patterns-established:
  - "Server-side OG tags: EJS template renders meta tags per-token for link preview crawlers"
  - "Deferred deep link via clipboard: copy token before App Store redirect, iOS app reads on first launch"

requirements-completed: [INVT-01, INVT-02]

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 16 Plan 01: Invite Web Infrastructure Summary

**Express server with AASA Universal Links, dynamic invite pages with server-rendered OG tags, and clipboard-based deferred deep linking**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T08:25:38Z
- **Completed:** 2026-03-07T08:27:30Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Express server replacing nginx with AASA route serving correct appID for Universal Links
- Dynamic invite page rendering personalized OpenGraph tags from Firestore data
- Platform detection showing App Store button for iOS, "iPhone only" message for others
- Clipboard copy of invite token with timestamp before App Store redirect

## Task Commits

Each task was committed atomically:

1. **Task 1: Express server med AASA-fil och statiska sidor** - `c53f002` (feat)
2. **Task 2: Dynamisk invite-sida med OG-tags, plattformsdetektering och clipboard** - `a9547ee` (feat)

## Files Created/Modified
- `website/server.js` - Express server with AASA route, invite route, static file serving
- `website/views/invite.ejs` - Dynamic invite page with OG tags, platform detection, clipboard copy
- `website/.well-known/apple-app-site-association` - AASA file with applinks for invite paths
- `website/package.json` - Dependencies: express, firebase-admin, ejs
- `website/Dockerfile` - Upgraded from nginx:alpine to node:20-alpine
- `website/.gitignore` - Node.js ignore patterns
- `website/.dockerignore` - Docker ignore with @eaDir for Synology
- `website/public/index.html` - Migrated static landing page
- `website/public/privacy.html` - Migrated privacy policy
- `website/public/support.html` - Migrated support page

## Decisions Made
- Inline CSS in invite.ejs rather than external stylesheet — keeps single-page self-contained
- Clipboard format `friendscast-invite:token:timestamp` — iOS app can parse prefix, validate freshness
- Firebase Admin initialized with applicationDefault() — requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON at runtime

## Deviations from Plan

None - plan executed exactly as written.

## User Setup Required

**External services require manual configuration.** Firebase service account needed for Firestore access:
- Generate service account key from Firebase Console -> Project Settings -> Service accounts
- Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable pointing to the JSON key file
- Mount the key file in the Docker container

## Issues Encountered
None

## Next Phase Readiness
- Server ready for deployment to Synology NAS (Docker rebuild needed)
- Plan 02 (invite share UI in iOS app) can proceed independently
- Firebase service account must be configured before invite routes work in production

## Self-Check: PASSED

All 10 created files verified. Both task commits (c53f002, a9547ee) found in git log.

---
*Phase: 16-invite-foundation*
*Completed: 2026-03-07*
