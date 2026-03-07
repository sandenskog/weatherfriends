---
phase: 16
slug: invite-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (iOS) + supertest (web) |
| **Config file** | None — XCTest integrated in Xcode, supertest via package.json |
| **Quick run command** | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HotAndColdFriendsTests` |
| **Full suite command** | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command (relevant test class)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | INVT-01 | unit | XCTest: Universal Link URL parsing | No — W0 | pending |
| 16-01-02 | 01 | 1 | INVT-03 | unit | XCTest: InviteService persistent redemption | No — W0 | pending |
| 16-02-01 | 02 | 1 | INVT-02 | integration | `curl -s localhost:80/invite/testtoken \| grep og:title` | No — W0 | pending |
| 16-02-02 | 02 | 1 | INVT-01 | config | Validate AASA JSON structure | No — W0 | pending |
| 16-03-01 | 03 | 2 | INVT-04 | unit | XCTest: clipboard token extraction | No — W0 | pending |
| 16-03-02 | 03 | 2 | INVT-04 | manual | End-to-end deferred deep link flow | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Add test target `HotAndColdFriendsTests` to `project.yml` if not exists
- [ ] `InviteServiceTests.swift` — stubs for INVT-01, INVT-03
- [ ] `ClipboardInviteTests.swift` — stubs for INVT-04
- [ ] `npm install --save-dev supertest` in website/ — for INVT-02 route tests
- [ ] `website/tests/invite.test.js` — stubs for INVT-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Universal Link opens app from iMessage | INVT-01 | Requires physical device + iMessage | Send invite link via iMessage, tap on device with app installed, verify app opens |
| Web fallback renders correctly on mobile Safari | INVT-02 | Visual rendering check | Open invite URL on device without app, verify branding + App Store button |
| Deferred deep link end-to-end | INVT-04 | Requires app install flow | Click invite link > web fallback > App Store > install > open > verify friendship created |
| iOS paste banner appears correctly | INVT-04 | iOS system UI interaction | After install via invite, open app, verify paste banner shows, approve, verify auto-redeem |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
