# Phase 1 QA Test Plan — TC1–TC9 Gauntlet

**Scope**: Phase 1 = Screens S01–S11 only (First-time setup, auth, and the daily-audit
execution loop). CAPs (S12–S17), Reference Data (S22–S26), and Settings/Users
(S27–S32) are OUT OF SCOPE for this plan — they are not built.

**How to read status**: Each case lists Steps, Expected result, and the
last recorded Result. Device runs were performed by Antigravity on a physical
device (POCO 2312BPC51H). Claude reviews source but cannot execute Flutter
in-session, so any "PASS" here is either Antigravity's device observation or a
code-reading judgment — labeled accordingly.

---

## TC1 — First-time Setup (S03)
- **Steps**: Fresh install → language select (S02) → create Owner with name + 4-digit PIN + confirm PIN.
- **Expected**: Owner row persisted with bcrypt-hashed PIN; no keyboard overflow; routes to Login/Home.
- **Result**: PASS (device).

## TC2 — Login with PIN (S04)
- **Steps**: Enter correct PIN on numpad.
- **Expected**: Authenticates, routes to Home (S05). Wrong PIN increments failure counter.
- **Result**: PASS (device).

## TC3 — Lockout after 5 failures within 60s (S04, Rule #4)
- **Steps**: Enter wrong PIN 5 times within 60s → observe 60s lockout → kill and restart app during lockout.
- **Expected**: Numpad disabled, live countdown ticks each second, numpad restored on expiry. Lockout SURVIVES process restart.
- **Result**: Originally FAIL (DEF-01: lockout reset on process restart). REMEDIATED — `auth_lockout_until` + `auth_failure_timestamps` now persisted to SharedPreferences; re-test on device to confirm.

## TC4 — Start Daily Audit (S06)
- **Steps**: From Home tap "Start daily audit" → pick date → select CRO duty roster (multi-select).
- **Expected**: Draft audit created; proceeds to first checkpoint (S07).
- **Result**: PASS (device).

## TC5 — PASS / NA path (S07)
- **Steps**: Mark checkpoints PASS and NA and advance.
- **Expected**: NA excluded from denominator; PASS adds weight; index advances.
- **Result**: PASS (device).

## TC6 — FAIL + mandatory photo + back-button atomicity (S07→S08, Rules #6/#7)
- **Steps**: Mark a checkpoint FAIL → S08 → enter finding, (optional CRO), capture photo for a `requires_photo_on_fail` checkpoint. Also test backing out of S08 before commit.
- **Expected**: Fail committed atomically (result + finding + photo + advance) via `recordFailAndAdvance()`. Backing out writes ZERO rows (no orphan 'F'). Mandatory photo enforced.
- **Result**: PASS (device).

## TC7 — Review & Summary (S10)
- **Steps**: Complete all 68 checkpoints → open S10.
- **Expected**: Live score card, SOP breakdown, fails list with evidence thumbnails, 500-char notes. Submit disabled while incomplete; incomplete-warning banner shown.
- **Result**: PASS (device). NOTE: preview-score inflation on incomplete audits (unmarked = PASS) fixed by Claude 2026-09-21 — re-verify.

## TC8 — Submit & Confirmation (S11) + Immutability (Rule #6)
- **Steps**: Submit a complete audit → observe S11. Then attempt to modify a submitted audit (no UI path exists — must be exercised by automated test).
- **Expected**: Status locked to `'submitted'`, `submitted_at` + final scores/band persisted; S11 shows animated checkmark, final score/band, offline-sync indicator ("Will sync when online"). Any post-submit write throws `StateError`.
- **Result**: Submit + SQLite persist PASS (device). Remote sync fails as expected (cloud mirror is Phase 4). Immutability throw: UNPROVEN on device (no UI path) — now covered by `test/audit_immutability_test.dart`.

## TC9 — Localization (Rule #8)
- **Steps**: Toggle EN ⇄ मराठी; verify all S01–S11 strings and dynamic seed text (checkpoint text, evidence, SOP names) switch; verify a post-onboarding switch control exists.
- **Expected**: 1:1 EN/MR parity via `AppLocalizations`; in-app toggle re-renders with no restart.
- **Result**: Originally FAIL (DEF-02: no post-onboarding toggle; screens hardcoded strings). REMEDIATED — S01–S11 refactored to consume `AppLocalizations.of(context)!`, EN/मराठी toggle added to S04 Login and S05 Home; re-test on device to confirm.

---

## Coverage Gaps (automated)
- S03→S04 auth lifecycle UI flow — no automated test.
- S07→S10→S11 submit UI flow — no automated test.
- Mandatory-photo gate at the UI layer — domain covered (`mandatory_photo_gate_test.dart`), UI not.
- Immutability throw — now covered by `audit_immutability_test.dart` (was the #1 gap).

## Defect Register (see SESSION_HANDOFF.md for full re-ratings)
- **DEF-01** — PIN lockout reset on process restart. Sev: High → re-rated Medium by Claude (60s speed-bump on local PIN, no data exposure). REMEDIATED.
- **DEF-02** — Missing post-onboarding language switch. Sev: Medium → re-rated HIGH by Claude (root cause was no screen consuming `AppLocalizations`, not just a toggle). REMEDIATED.
