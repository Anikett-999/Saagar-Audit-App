# Defect-Fix Prompt — 2026-09-21

**For**: Antigravity (developer agent)
**From**: Claude (product-side reviewer)
**Context**: Phase 1 (S01–S11) device QA gauntlet complete. This prompt lists the
defects to fix, in priority order, with acceptance criteria. Read
`brain/CURRENT_STATE.md`, `brain/SESSION_HANDOFF.md`, and `brain/PHASE1_TEST_PLAN.md`
first. Keep the locked stack; `flutter test test/score_engine_test.dart` must stay green.

---

## Priority 1 — Localization (Rule #8, DEF-02, re-rated HIGH)
**Problem**: ARB + delegate plumbing existed, but no screen consumed `AppLocalizations`.
Screens hardcoded strings (some English-only, some baked bilingual). Rule #8 dual-language
parity was structurally UNMET.

**Fix**:
1. Author complete 1:1 `app_en.arb` / `app_mr.arb` (authentic Devanagari), full key parity.
2. Refactor ALL S01–S11 screens to consume `AppLocalizations.of(context)!` — zero hardcoded/baked strings.
3. Dynamic seed text via `cp.text(locale)`, `cp.evidence(locale)`, `sop.name(locale)`.
4. Add an EN ⇄ मराठी toggle reachable AFTER onboarding (S05 Home; also S04 Login).

**Acceptance**: Toggle flips every visible string incl. seed text, no restart, no missing keys.
**Status**: DONE (per Antigravity handoff). Re-verify on device (TC9).

## Priority 2 — Lockout durability (Rule #4, DEF-01, re-rated MEDIUM)
**Problem**: 60s rolling-window lockout worked in memory but reset on app process kill/restart.

**Fix**: Persist `lockout_until` and failure timestamps to SharedPreferences; rehydrate on
launch; count down remaining time; clear keys on successful login.

**Acceptance**: TC3 — kill app mid-lockout, relaunch, lockout still active with correct remaining time.
**Status**: DONE (per handoff). Re-verify on device.

## Priority 3 — Automated coverage
Add tests for: immutability `StateError` throw on submitted audits; mandatory-photo gate;
(stretch) S03→S04 auth lifecycle and S07→S10→S11 submit flow.
**Status**: Immutability + mandatory-photo gate DONE. UI-flow tests still open.

## Priority 4 — S10 preview score inflation (preview-only)
**Problem**: `review_submit_screen.dart` counted unmarked checkpoints as PASS in the PREVIEW
score (marks builder + SOP breakdown), inflating the on-screen score of an incomplete audit.
Submit path was already correct.

**Fix**: Skip unmarked checkpoints (`state.results.containsKey(cp.id)`) in both the marks
builder (~L202) and the SOP-breakdown loop (~L476).
**Status**: DONE by Claude 2026-09-21. Antigravity to run `flutter analyze` + `flutter test`
to confirm clean baseline.

---

## Not defects — deferred by scope (do NOT "fix" in Phase 1)
- Remote/cloud sync failing on submit — expected; cloud mirror is Phase 4.
- Failed checkpoints have no CAP creation path — needs S12+ (CAPs workflow), not yet built.
- No UI to create SM/GM users or CROs — needs S27+ (Settings/Users), not yet built.
  These last two are OPERABILITY BLOCKERS for real deployment and are the next real work.
