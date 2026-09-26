# Current Implementation State

## 1. Screen Registry (S01 – S32)
| Screen | Name | Status | Notes |
|---|---|---|---|
| **S01** | Splash | ✅ Complete | Loads language & lockout state, routes to S02/S03/S04 |
| **S02** | Language | ✅ Complete | EN vs MR selection with persistence |
| **S03** | First-time Setup | ✅ Complete | Localized Owner creation, PIN & confirm, no keyboard overflow |
| **S04** | Login | ✅ Complete | Localized, active 1s ticker, EN/MR switcher, durable lockout |
| **S05** | Home | ✅ Complete | Localized, role-aware daily audit for Owner/SM, EN/MR switcher |
| **S06** | Start Daily Audit | ✅ Complete | Localized date picker + CRO duty multi-select |
| **S07** | Checkpoint Screen | ✅ Complete | Localized UI + dynamic cp.text(locale), PASS/FAIL/NA |
| **S08** | Fail Detail | ✅ Complete | Localized, cp.text(locale), CRO select, photo capture gate |
| **S09** | Photo Capture | ✅ Complete | Collapsed into S08 inline camera launcher |
| **S10** | Daily Audit Summary | ✅ Complete | Localized, score card, SOP table, mandatory-photo validation |
| **S11** | Submit Confirmation | ✅ Complete | Localized, animated checkmark, final score, offline sync indicator |
| **S12**    | Audit History | ✅ Complete | Role-scoped (SM own, GM/Owner all), filter chips (All, Daily, Unverified), compliance % pill, band color, fail count, infinite scroll (30/pg), pull-to-refresh |
| **S13**    | Audit Detail | ✅ Complete | Read-only immutable view of submitted audits, score card, SOP breakdown table, expandable checkpoints, non-compliances with photos & linked CAP chip, "+ Create CAP" launch to S15 |
| **S14**    | CAP List | ✅ Complete | Filterable/searchable CAP list, deadline color-coding, S05 nav wired, EN/MR parity |
| **S15**    | CAP Create | ✅ Complete | 10-field template, 5-Whys, 3–5 dynamic action steps, responsible dropdown, deadline picker, EN/MR parity |
| **S16**    | CAP Detail | ✅ Complete | Full CAP view, action checklist, event log timeline, state/role-gated buttons, Phase 2 stubs |
| **S17**    | Mark Done Modal | ✅ Complete | Gated on all actions done, optional reflection notes & evidence photo, atomic markDone + cap_log, full EN/MR parity |
| **S22**    | Reference Index | ✅ Complete | Built-in Store Audit Handbook hub (Appendices A.4–A.7), 4 navigation cards with distinct icons/accents, appendix badges, responsive layout, S05 Home tile wired, EN/MR parity |
| **S23**    | Rating Scale | ✅ Complete | Appendix A.4: 5 compliance bands matching score engine cutoffs (≥95/≥90/≥85/≥80/<80), tier targets table (Tier 1 90%+, 81/90 canonical invariant), strict decimal warning banner ("89.9 is FAIR, not Good"), EN/MR parity |
| **S24**    | Escalation Triggers | ✅ Complete | Appendix A.5: 7 mandatory escalation triggers with thresholds & roles, 4-part message format card, what never escalates rules, 3 worked example message cards with clipboard copy, EN/MR parity |
| **S25**    | Evidence Guide | ✅ Complete | Appendix A.6: 8 evidence comparison pairs (Strong vs Weak evidence cards with distinct icons/colors), context subtitle callout, bottom warning banner ("Every finding must rest on strong evidence..."), manual refresh action, full EN/MR parity |
| **S26**    | Bilingual Glossary | ✅ Complete | Appendix A.7: 65 terms & meanings table with live search across EN, MR, and meanings, Devanagari input support, Wrap responsive layout, zero-match empty state, EN/MR parity |
| **S27**    | Settings Hub | ✅ Complete | Role-filtered list (Owner-only Users), profile badge, real S05 navigation |
| **S28**    | Manage CROs | ✅ Complete | List all, Add/Edit/Deactivate/Reactivate, soft deactivation preserves audit trail, EN/MR parity |
| **S29**    | Manage Users | ✅ Complete | Owner-only, route-guarded, SM/GM creation only (no Owner), bcrypt PINs, soft deactivation, Owner protected, EN/MR parity |
| **S30**    | Change PIN | ✅ Complete | Verifies current PIN via BCrypt.checkpw, bcrypt hash on new PIN, 4-digit validation, mismatch & same-PIN guards, EN/MR parity |
| **S31**    | Language | ✅ Complete | Dedicated screen, live EN/MR switch, persists to users.language_pref, login restore, full EN/MR parity |
| **S32**    | Backup / Export | ✅ Complete | All 14 tables exported to timestamped JSON in Downloads, Owner-only Firestore sync stub (Coming in Phase 4), security advisory, About card, full EN/MR parity |

> **PHASE 1 IS 100% COMPLETE & SIGNED OFF.** All 28 screens (S01–S17, S22–S32) are fully built and verified. Automated suite: 214/214 tests passing across 26 test files. Claude code review: APPROVED. Physical device UAT: verified by owner on device.

> **PHASE 2 KICKED OFF (2026-09-26).** flatten-to-root merged to `main`, CI green (Run #36234413654). Sprint sequence set: **P2-1** Weekly Audit Foundation (score engine + data model + 36 weekly-only seed) → **P2-2** weekly conduct screens → **P2-3** 7-day review + spot check → **P2-4** weekly report S20/S21 + PDF (§3.6) → **P2-5** CAP Verify S18 + Close S19 + GM dashboard. Sprint P2-1 spec: `brain/SPRINT_P2_1_WEEKLY_FOUNDATION.md`. **In flight:** Antigravity implementing P2-1 on `feature/p2-weekly-score-engine` (off `phase-2` off `main`), holding for Claude review per Rule 6.

### Phase 2 screen registry (planned)
| Screen | Name | Status | Notes |
|---|---|---|---|
| **S18** | CAP Verify | ⏳ Planned (P2-5) | GM verifies a done CAP against re-run checkpoint |
| **S19** | CAP Close | ⏳ Planned (P2-5) | GM closes verified CAP; cap_log timeline entry |
| **S20** | Reports List | ⏳ Planned (P2-4) | Weekly report list |
| **S21** | Report Detail | ⏳ Planned (P2-4) | 1-page weekly report, Workbook §3.6 9-section format, PDF export |
| **Weekly conduct** | S6–S10 analogues | ⏳ Planned (P2-2) | `audit_type='weekly'`, 36 weekly-only checkpoints |
| **7-day review** | Daily review + spot check | ⏳ Planned (P2-3) | 7 daily cards, 3 random spot-check checkpoints/day, GM signature |

**Score engine (Phase 2):** `computeWeeklyScore` (§6.5, daily-avg ×0.68 + weekly_raw, missing-day-as-zero) and `computeCumulativeWeeklyVariance` (CW.7, §6.7) — being added to `lib/domain/score_engine.dart` in P2-1. Canonical target: Workbook §5.2 = 104.8/124 = **84.5% Poor** exact (test T2.1).

## 2. Verified Baseline Health
- `flutter analyze`: **0 issues found (Clean baseline)**
- `flutter test`: **214/214 tests passing across 26 test files**:
  - `phase1_integration_test.dart` (2 tests) — Comprehensive Phase 1 end-to-end lifecycle integration: S03 Owner Setup (bcrypt hash verification) -> S04 Login (wrong PIN blocked, correct PIN authenticated) -> S05 Home Dashboard with Rule #8 in-flow EN ⇄ MR language toggle ('दैनिक ऑडिट सुरू करा' assertion) -> S06 Start Daily Audit with CRO duty roster -> S07 Checkpoints & S08 Fail Detail (CP 1.1 PASS with 9.0 weighted pts; CP 1.2 FAIL with TC6 back-button atomicity, mandatory photo gate enforcement, photo attachment via PhotoService seam, atomic commit with 0.0 pts & photo row; CP 1.3 NA modal with reason capture & denominator exclusion) -> S10 Review with live score card matching score engine (90.0% Good, 9.0 / 10.0 pts), SOP breakdown, Fails section, auditor notes -> S11 Submit confirmation with checkmark, 90.0% Good, "Saved to SQLite · Will sync when online" -> Hard Rule #6 Immutability check (asserts StateError on post-submit saveResult and submitAudit); plus TC1 standalone PIN mismatch guard test on S03.
  - `glossary_screen_test.dart` (8 tests) — Screen S26 Bilingual Glossary: all 65 terms & definitions, real-time live search (EN, Devanagari MR, and definition keyword matching), live counter indicator, empty search restore, zero-match empty state with clear button, full Marathi Rule #8 parity, 320x640 narrow-width overflow safety, refresh data action
  - `evidence_screen_test.dart` (4 tests) — Screen S25 Evidence Guide: all 8 comparison pairs (Strong vs Weak evidence), context subtitle callout, bottom warning banner, full Marathi Rule #8 parity, 320x640 narrow-width overflow safety, refresh data action
  - `escalation_triggers_screen_test.dart` (5 tests) — Screen S24 Escalation Triggers: 7 mandatory escalation triggers with thresholds/recipients/timing, 4-part message format card, what never escalates section, 3 worked example cards with copy action, full Marathi Rule #8 parity, 320x640 narrow-width overflow safety, refresh data action
  - `rating_scale_screen_test.dart` (5 tests) — Screen S23 Rating Scale: 5 compliance bands table/cards matching score engine cutoffs, tier targets table (Tier 1 daily, Tier 2 weekly, Tier 3 monthly with canonical 81/90 pts invariant), decimal precision reminder banner ("89.9 is FAIR, not Good"), full Marathi Rule #8 parity, 320x640 narrow-width overflow safety, refresh data action
  - `reference_index_screen_test.dart` (8 tests) — Screen S22 Reference Index: AppBar title & LanguageToggleButton, handbook header banner, 4 navigation cards with titles/subtitles/appendix badges (A.4 Rating Scale, A.5 Escalation, A.6 Evidence, A.7 Glossary), tapping cards navigates to `/reference/rating`, `/reference/escalation`, `/reference/evidence`, `/reference/glossary`, Marathi Rule #8 parity, 320x640 narrow-width overflow safety, S05 Home Reference tile navigation to `/reference`
  - `reference_repository_test.dart` (19 tests) — S22–S26 reference data layer: `rating_scale.json` parsing (5 bands, 3 tier targets, strict score engine cutoffs match, reminder banner), `escalation_triggers.json` parsing (7 triggers, 4-part message format, 3 worked examples for Triggers 1, 3, 5, never-escalates rules), `evidence.json` parsing (8 strong/weak pairs, warning banner), `glossary.json` parsing (exactly 65 bilingual terms & meanings, non-empty validation), glossary search (empty/spaces return all 65, EN term search, Devanagari MR term search, meaning search, acronyms, non-matching), in-memory caching & clearCache
  - `audit_detail_screen_test.dart` (12 tests) — S13 header metadata & read-only lock banner, score card (compliance %, band badge, metric counts), SOP breakdown table with expandable checkpoint inspection, non-compliances list with findings, CRO attribution, photo thumbnails & inspection dialog, linked CAP clickable chip navigating to S16, unlinked fail "+ Create CAP" button navigating to S15 with pre-filled origin parameters, zero-fail clean card, Not Found state, Rule #6 audit immutability (no edit/submit buttons), GM vs SM Verify Audit button visibility, Marathi Rule #8 parity
  - `audit_history_screen_test.dart` (8 tests) — S12 empty state, audit card fields (date, auditor name, score %, band badge, fail count), SM role scoping (own audits only), GM/Owner role scoping (all audits), draft/hidden exclusion, unverified filter chip, card tap navigation to S13, Marathi parity
  - `cap_mark_done_screen_test.dart` (7 tests) — S17 header summary, completed action steps checklist, guard against incomplete steps, optional photo capture + reflection notes submission, photo removal, already-done state guard, Not Found state, Marathi parity
  - `cap_repository_test.dart` (20 tests) — ISO-week formatting, sequential ID generation, createCap validation & atomic writes, toggleAction, markDone guards, optional completion photo persistence with context=cap_progress, role scoping, status filters, search, S13 helpers, listAudits pagination/scoping
  - `cap_detail_screen_test.dart` (11 tests) — S16 full 10 fields read-only inspection, status badge, deadline color-coding, responsible action step toggling, non-responsible permission blocking, Mark Done gating on completion, Phase 2 stubs (Extension/Verify/Close/Reopen), Not Found state, Marathi parity
  - `cap_create_screen_test.dart` (7 tests) — S15 10-field template rendering, pre-fills from fail, mandatory field validation, 3–5 bounded dynamic action steps, empty step validation, atomic creation & navigation to S16, Marathi parity
  - `cap_list_screen_test.dart` (9 tests) — S14 list rendering, empty state, deadline color-coding (overdue/dueSoon/ok), filter chips, search, SM role scoping, GM/Owner unscoped, S15 FAB + S16 card navigation, Marathi parity
  - `score_engine_test.dart` (12 tests) — Canonical score invariant `81 / 90 = 90.0% Good`, band cutoffs, NA handling
  - `backup_export_test.dart` (8 tests) — S32 all 14 tables JSON export, file writing, core sections, Owner-only Firestore sync section with Phase 4 badge, SM hide guard, export AlertDialog, unauthenticated guard, Marathi parity
  - `language_screen_test.dart` (6 tests) — S31 options rendering, selection indicator, live switch + SQLite users.language_pref persistence, unauthenticated guard, login stored pref restore, Marathi parity
  - `change_pin_test.dart` (8 tests) — S30 field rendering, 4-digit validation, same-as-current guard, mismatch guard, BCrypt verification of current PIN, bcrypt update of new PIN, unauthenticated guard, Marathi parity
  - `manage_users_test.dart` (9 tests) — S29 empty state, role badges (Owner/GM/SM), Add User (SM/GM only, bcrypt PIN hash), Owner deactivation blocked in UI & repo, soft-deactivation (history preserved), reactivate user, reset PIN with bcrypt, route guard (non-Owner redirected), Marathi parity
  - `manage_cros_test.dart` (7 tests) — S28 empty state, Active/Inactive distinction, Add dialog + validation, Edit dialog, Deactivation with audit preservation, Reactivation, EN/MR parity
  - `auth_lockout_test.dart` (7 tests) — Rolling 60s window + DEF-01 SharedPreferences reboot persistence
  - `audit_immutability_test.dart` (4 tests) — TC8 Hard Rule #6 immutability & StateError throw on submitted audits
  - `mandatory_photo_gate_test.dart` (5 tests) — Hard Rule #6 mandatory photo gate on fail and submission blocks
  - `user_repository_test.dart` (16 tests) — Single-Owner guard, SM/GM creation, deactivation (no hard delete), PIN change/reset, CRO CRUD & reactivate
  - `settings_hub_test.dart` (5 tests) — S27 Hub role-filtering (Owner sees Manage Users, SM/GM completely hides), About dialog, EN/MR parity
  - `widget_test.dart` (2 tests) — Custom PinNumpad input and backspace widget interactions
- **Rule #8 Dual-Language Parity (DEF-02)**: Complete. 1:1 parity between `app_en.arb` and `app_mr.arb`. S01–S11 and S27 consume `AppLocalizations.of(context)!`. Real-time EN ⇄ मराठी switcher active.
- **DEF-01 PIN Lockout Durability**: Complete. `lockout_until` and `failure_timestamps` persisted to `SharedPreferences`, survives process death and restart.
- **Immutability (TC8)**: Verified via automated tests asserting `StateError` on post-submit modifications.
- **Atomic Fail (TC6)**: `recordFailAndAdvance` enforces finding text and mandatory photos atomically; `submitAudit` blocks submission if required photos are missing.
