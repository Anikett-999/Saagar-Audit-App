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
| **S13**    | Audit Detail | ⏳ Scheduled | Read-only view of submitted audits, checkpoints breakdown & WhatsApp share |
| **S14**    | CAP List | ✅ Complete | Filterable/searchable CAP list, deadline color-coding, S05 nav wired, EN/MR parity |
| **S15**    | CAP Create | ✅ Complete | 10-field template, 5-Whys, 3–5 dynamic action steps, responsible dropdown, deadline picker, EN/MR parity |
| **S16**    | CAP Detail | ✅ Complete | Full CAP view, action checklist, event log timeline, state/role-gated buttons, Phase 2 stubs |
| **S17**    | Mark Done Modal | ✅ Complete | Gated on all actions done, optional reflection notes & evidence photo, atomic markDone + cap_log, full EN/MR parity |
| **S22–S26**| Reference Data | ⏳ Scheduled | Rating scale, escalation triggers, glossary |
| **S27**    | Settings Hub | ✅ Complete | Role-filtered list (Owner-only Users), profile badge, real S05 navigation |
| **S28**    | Manage CROs | ✅ Complete | List all, Add/Edit/Deactivate/Reactivate, soft deactivation preserves audit trail, EN/MR parity |
| **S29**    | Manage Users | ✅ Complete | Owner-only, route-guarded, SM/GM creation only (no Owner), bcrypt PINs, soft deactivation, Owner protected, EN/MR parity |
| **S30**    | Change PIN | ✅ Complete | Verifies current PIN via BCrypt.checkpw, bcrypt hash on new PIN, 4-digit validation, mismatch & same-PIN guards, EN/MR parity |
| **S31**    | Language | ✅ Complete | Dedicated screen, live EN/MR switch, persists to users.language_pref, login restore, full EN/MR parity |
| **S32**    | Backup / Export | ✅ Complete | All 14 tables exported to timestamped JSON in Downloads, Owner-only Firestore sync stub (Coming in Phase 4), security advisory, About card, full EN/MR parity |

> **Sprint S12–S17 (CAPs Workflow) is ACTIVE. Steps 1–6 complete (S12 built, 151/151 tests passing across 18 test files); holding for Claude review before push.**

## 2. Verified Baseline Health
- `flutter analyze`: **0 issues found (Clean baseline)**
- `flutter test`: **151/151 tests passing across 18 test files**:
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
