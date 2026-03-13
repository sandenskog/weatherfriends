---
id: T01
parent: S01
milestone: M003
provides:
  - Express server on apps.sandenskog.se with AASA for Universal Links
  - Dynamic invite landing page with server-rendered OG tags
  - Node.js Docker container replacing nginx
key_files:
  - website/server.js
  - website/views/invite.ejs
  - website/.well-known/apple-app-site-association
  - website/package.json
  - website/Dockerfile
key_decisions:
  - "Inline CSS in invite.ejs — single-page simplicity"
  - "Clipboard format friendscast-invite:token:timestamp"
  - "Firebase Admin with applicationDefault() credentials"
patterns_established:
  - "Server-side OG tag rendering via EJS templates"
  - "Deferred deep link via clipboard copy before App Store redirect"
observability_surfaces:
  - none
duration: 2min
verification_result: passed
completed_at: 2026-03-07
blocker_discovered: false
---

# T01: Express server with AASA and dynamic invite pages

**Express server replacing nginx with AASA Universal Links route, dynamic invite pages with server-rendered OG tags, platform detection, and clipboard deferred deep link**

## What Happened

Created Express server (website/server.js) with firebase-admin for Firestore access, ejs templating for dynamic invite pages, and static file serving for existing HTML pages. AASA file created with correct appID for Universal Links on /invite/* paths. Invite page renders personalized OpenGraph meta tags from Firestore data (sender name, city), detects platform via User-Agent, and copies invite token to clipboard before App Store redirect. Dockerfile upgraded from nginx:alpine to node:20-alpine. Existing static pages moved to website/public/.

## Verification

- AASA file validates as correct JSON with correct appID
- package.json loads without errors
- EJS template renders OG tags correctly with test data
- Clipboard copy logic includes token + timestamp with friendscast-invite: prefix

## Diagnostics

- AASA file: `cat website/.well-known/apple-app-site-association | python3 -m json.tool`
- Server start: `cd website && node server.js` (requires GOOGLE_APPLICATION_CREDENTIALS)

## Deviations

None — plan executed exactly as written.

## Known Issues

None.

## Files Created/Modified

- `website/server.js` — Express server with AASA route, invite route, static file serving
- `website/views/invite.ejs` — Dynamic invite page with OG tags, platform detection, clipboard copy
- `website/.well-known/apple-app-site-association` — AASA file with applinks for invite paths
- `website/package.json` — Dependencies: express, firebase-admin, ejs
- `website/Dockerfile` — Upgraded from nginx:alpine to node:20-alpine
- `website/.gitignore` — Node.js ignore patterns
- `website/.dockerignore` — Docker ignore with @eaDir for Synology
- `website/public/index.html` — Migrated static landing page
- `website/public/privacy.html` — Migrated privacy policy
- `website/public/support.html` — Migrated support page
