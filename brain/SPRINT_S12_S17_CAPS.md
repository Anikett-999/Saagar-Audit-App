# Sprint Plan — CAPs Workflow (Screens S12–S17)

> **Author**: Claude (Senior Developer & Team Lead) — 2026-09-22
> **Spec source**: `brain/spec/03_S12_S21_AUDITS_CAPS_REPORTS.md` (Spec §5, Screens S12–S21)
> **Schema**: `lib/data/db/schema.dart` (`caps`, `cap_actions`, `cap_log`, `audits`, `audit_results`, `photos`)
> **Status when planned**: Sprint S27–S32 complete; 89/89 tests green; repo live & private.

---

## 1. Scope of THIS sprint

This sprint delivers the **daily-audit → corrective-action loop** that is the reason Phase 1 exists: an auditor finds a Fail, opens a CAP with a 5-Whys root-cause, works the action steps, and marks it done. Plus the read-only audit history that feeds it.

**IN scope (build now):**
- **S12 — Audit History**: list of submitted audits, role-scoped, newest first.
- **S13 — Audit Detail**: read-only mirror of the S10 review layout for a submitted audit, with its linked CAP(s) surfaced.
- **S14 — CAP List**: filterable/searchable list of CAPs, deadline-sorted, color-coded.
- **S15 — CAP Create**: the 10-field CAP template (5-Whys + dynamic action steps), auto CAP-ID.
- **S16 — CAP Detail**: full CAP view, action checklist, log timeline, role/state-gated action buttons.
- **S17 — CAP Mark Done**: modal to confirm all actions done → `status='done'`.

**OUT of scope (defer — do NOT build, only stub):**
- **S18 Verify / S19 Close**: these are GM/Owner verification actions. Per spec they re-run the verification checkpoint. **Stub only**: on S16, the "Verify CAP" (status=done) and "Close CAP" (status=verified) buttons render for GM/Owner but are **disabled with a "Coming next" affordance**, OR route to a lightweight placeholder. Full S18/S19 come in their own mini-sprint right after this one. Rationale: keeps this sprint shippable and reviewable; verification has its own photo-gate + fail-branch logic that deserves dedicated design.
- **Push notifications** (S15/S17 spec mentions them): Phase 4 (no cloud yet). Leave a `// TODO(phase4): notify responsible/GM` marker where the spec calls for a push. Do NOT add any notification dependency.
- **Request Extension / Reopen** (S16): stub/hide for now — later mini-sprint.
- **S20/S21 Reports**: Phase 2+. Not this sprint.
- **PDF export / WhatsApp share** on S13: Phase 2 per spec ("Export PDF" is listed but the report/PDF engine is Phase 2). **Hide or disable** these buttons on S13 for now with no PDF dependency added. (S13 itself — the read-only view — is Phase 1.)

> If Antigravity believes any deferred item is trivially includable, raise it in the handoff BEFORE building — do not silently expand scope.

---

## 2. Data layer (build FIRST, before any screen)

No `Cap` model or `CapRepository` exists yet. Build them following the existing singleton pattern in `audit_repository.dart` / `user_repository.dart` (`XxxRepository._(); static final instance = XxxRepository._();`, `AppDatabase.instance.db`, `const Uuid().v4()`, UTC ISO-8601 timestamps).

### 2.1 Models (`lib/data/models/`)
- **`cap.dart`** — immutable `Cap` mirroring the `caps` columns exactly (all 10 template fields + status/timestamps + `aged_count`, `extension_count`). `fromMap`/`toMap`, plus convenience getters: `isOpen`, `isDone`, `isVerified`, `isClosed`, and a `deadlineStatus` helper enum-ish (`overdue` / `dueSoon` / `ok`) computed from `deadline` vs now (red = past, amber = today/tomorrow, green = 3+ days).
- **`cap_action.dart`** — immutable, mirrors `cap_actions` (`id, cap_id, sequence, action_text, is_done, done_at, done_by, done_notes`).
- **`cap_log_entry.dart`** — immutable, mirrors `cap_log` (`id, cap_id, event, from_status, to_status, actor_user_id, device_id, timestamp, note`).

### 2.2 `CapRepository` (`lib/data/repositories/cap_repository.dart`)
All writes that change CAP state MUST also write a `cap_log` row **in the same transaction** (`db.transaction((txn) async {...})`) so the timeline can never drift from the status. Methods:

- `Future<String> generateNextCapId(DateTime originDate)` — format **`CAP-{year}-W{ISO_week}-{nn}`**. Reuse the ISO-week algorithm already in `audit_repository.dart` (`_isoWeek`) — **extract it to a shared helper** (e.g. `lib/domain/iso_week.dart`) and have both repos call it rather than duplicating. `nn` = zero-padded next sequence for that year+week (count existing caps whose id starts with `CAP-{year}-W{week}-` + 1).
- `Future<Cap> createCap({... all 10 fields ..., required List<String> actionSteps})` — one transaction: INSERT `caps` (`status='open'`, `opened_at=now`), INSERT one `cap_actions` row per step (sequence 1..n), INSERT `cap_log` (`event='created'`, `from_status=NULL`, `to_status='open'`). Validate: `problem_statement`, `why_1`, `root_cause`, `responsible_user_id`, `deadline`, `verification_method` non-empty; **3–5 action steps** (throw `ArgumentError` otherwise); responsible user must be SM/GM/OWNER (never a CRO — CROs aren't users anyway, but guard the role).
- `Future<List<Cap>> listCaps({required AuthUser viewer, CapFilter filter, String? search})` — **role scoping**: SM sees CAPs where `responsible_user_id = viewer.id` OR `origin` audit was authored by them; GM/OWNER see all. Sort by deadline ascending, aged first. Filter maps to status groups: All / Open (`open`,`reopened`) / Done-pending-verify (`done`) / Aged (`aged` or past-deadline open) / Closed (`closed`,`verified`). Search matches `problem_statement`/CAP id.
- `Future<Cap?> getById(String capId)`, `Future<List<CapAction>> actionsFor(String capId)` (ordered by sequence), `Future<List<CapLogEntry>> logFor(String capId)` (ordered by timestamp).
- `Future<void> toggleAction({required String actionId, required bool done, required String userId, String? notes})` — sets `is_done`, `done_at`, `done_by`; writes `cap_log` `event='action_done'`. Only the responsible user may check (enforce in UI; repo takes userId for the log).
- `Future<void> markDone({required String capId, required String userId, String? doneNotes})` — **guard**: throw `StateError` unless `status='open'`/`'reopened'` AND every `cap_actions.is_done=1`. Transaction: UPDATE `caps` (`status='done'`, `done_at=now`), INSERT `cap_log` (`event='marked_done'`, `from_status='open'`, `to_status='done'`). `// TODO(phase4): notify GM`.
- Also expose read helpers S13 needs: `Future<List<Cap>> capsForAudit(String auditId)` and `Future<Cap?> capForResult(String resultId)` so the audit-detail screen can show "linked CAP".

### 2.3 `AuditRepository` additions (for S12/S13)
The current repo has no list query. Add:
- `Future<List<Audit>> listAudits({required AuthUser viewer, AuditHistoryFilter filter, int limit = 30, int offset = 0})` — `status IN ('submitted','verified')` (never `draft`/`hidden`), role-scoped (SM → `auditor_id = viewer.id`; GM/OWNER → all), `ORDER BY submitted_at DESC`, paged. Filter chips: All / Daily / Unverified (Weekly/Monthly are Phase 2/3 — render chips disabled).
- Reuse existing `resultsForAudit`, `photosForResult` for S13.

> **Immutability stays intact**: S13 is strictly read-only. No new write path may touch a submitted audit. The existing `StateError` guard in `saveResult`/`submitAudit` must remain green (`audit_immutability_test.dart`).

---

## 3. Build order (each step: build → analyze → test → paste raw output → HOLD for Claude approval → then push)

Per **Rule 6 (review-gated push)**: build and test each screen, paste raw `flutter analyze` + `flutter test` into the handoff, and **do NOT commit/push until Claude writes `APPROVED — cleared to commit & push`**. One reviewable unit per step below.

1. **Step 1 — Data layer**: models (`Cap`, `CapAction`, `CapLogEntry`), shared `iso_week.dart`, `CapRepository`, `AuditRepository.listAudits`. Ship with a **repository unit test** (`test/cap_repository_test.dart`): CAP-ID generation & weekly sequencing, createCap writes caps+actions+log atomically, markDone guard (throws if actions incomplete), role scoping in listCaps. This is the foundation — review before any UI.
2. **Step 2 — S14 CAP List** (build before S12/S13 so the CAP loop is testable end-to-end early): filter chips, search, deadline color-coding, FAB → S15, tap → S16, auto-refresh on entry. Register route `s14_cap_list`; add entry point from S05 Home and/or S27 Settings as appropriate (check S05 for the natural nav slot — confirm with Claude if unclear).
3. **Step 3 — S15 CAP Create**: 10-field form, 5 Whys (Why 1 required), dynamic 3–5 action-step rows (add/remove), responsible dropdown (SM/GM/OWNER active users via `UserRepository.listActive`), deadline picker defaulting to origin audit date +7 days (or today+7 if free-standing), verification-method dropdown from daily checkpoints. Create → `CapRepository.createCap` → navigate to S16. When launched from a Fail (S08/S10 or S13), pre-fill origin fields.
4. **Step 4 — S16 CAP Detail**: status badge, deadline countdown, all 10 fields read-only, action checklist (checkable only by responsible user → `toggleAction`), `cap_log` timeline, role/state-gated buttons. "Mark CAP Done" (responsible + status open + all actions done) → S17. **Stub** Verify/Close/Extend/Reopen per §1.
5. **Step 5 — S17 Mark Done modal**: confirm-all-actions modal, optional done-notes, optional completion photo (`photos.context='cap_progress'`, reuse `PhotoService`) → `CapRepository.markDone` → back to S16 showing 'done'.
6. **Step 6 — S12 Audit History**: list via `listAudits`, filter chips (Daily active; Weekly/Monthly disabled), each row: date/type/auditor/compliance%/band color/fail count/status; tap → S13; paginate 30 + infinite scroll.
7. **Step 7 — S13 Audit Detail**: read-only reuse of S10's score card + SOP breakdown widgets (extract shared widgets if S10 has them inline — prefer reuse over copy). Show each Fail's finding text + photos + **linked CAP chip** (via `capForResult`); if a Fail has no CAP, offer "Create CAP" → S15 pre-filled. PDF/WhatsApp buttons **hidden/disabled** (Phase 2). GM/Owner "Verify" button hidden (Phase 2).

> Steps 6–7 come after the CAP loop because S13's "linked CAP" and "create CAP from fail" depend on the CAP layer existing. If Antigravity prefers S12/S13 first for momentum, that's acceptable *only* if the data layer (Step 1) is done — flag the reordering in the handoff.

---

## 4. Cross-cutting requirements (apply to every screen)

- **Locked stack**: Riverpod + GoRouter + sqflite + bcrypt, offline-first. No Firebase, no drift/isar, no Bloc/Provider. No new heavy deps; CAP-ID/date logic is pure Dart. Photos reuse existing `PhotoService`.
- **Rule #8 dual-language parity**: every user-facing string in BOTH `app_en.arb` and `app_mr.arb`, consumed via `AppLocalizations.of(context)!`, then `flutter gen-l10n`. The spec doc has Marathi for every label — use it. CAP status names, filter chips, 5-Whys labels, buttons — all localized.
- **Role gating** matches spec exactly: SM = own/assigned; GM/OWNER = all. CROs are never CAP-responsible.
- **Audit-trail integrity**: every CAP state change writes a `cap_log` row in the same transaction. Never hard-delete a CAP. Submitted audits stay immutable.
- **Score engine untouched**: `flutter test test/score_engine_test.dart` must stay green (canonical 81/90 = 90.0%).

---

## 5. Definition of Done for the sprint
- S12–S17 built, routed, and navigable from Home/Settings.
- The full loop works on-device: submit a daily audit with a Fail → open a CAP from that Fail → check off actions → mark done → see it in CAP List under "Done (pending verify)" and in the CAP's log timeline.
- `flutter analyze` clean; full `flutter test` green including new `cap_repository_test.dart` and per-screen widget tests (list rendering, create validation, mark-done guard, role scoping, EN/MR parity — mirror the depth of the S27–S32 suites).
- `brain/CURRENT_STATE.md` updated (S12–S17 → Complete); each step's raw logs + Claude approval recorded in `SESSION_HANDOFF.md`.
- S18/S19 (+ extension/reopen) explicitly noted as the next mini-sprint.
