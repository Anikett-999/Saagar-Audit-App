# Sprint P3-3 — CAP Auto-Aging Job (Phase 3) — 🟡 PLAN / CLEARED TO BUILD

**Phase**: 3 (Monthly + Escalation + Trends, Weeks 9–11)
**Sprint**: P3-3 (third sprint of Phase 3)
**Author of plan**: Claude (Team Lead)
**Date**: 2026-09-29
**Branch**: `feature/p3-cap-auto-aging` off `phase-3` (Rule 7)
**Spec**: Workbook Day-4 §4.4 / `brain/spec/07_WORKFLOWS_AND_NOTIFICATIONS.md` §9.1–§9.2 / CAP state-transition table L155–166
**Status**: 🟡 **PLAN — CLEARED TO BUILD.** No schema change required (all fields verified present — see §2). No R2 gate. `workmanager ^0.9.0+3` already in `pubspec.yaml` (locked-stack compliant). This sprint is buildable in full against the current schema; the only new design decisions are the escalation-source wiring (§4) and the verify-pending idempotency guard (§3), both flagged below.

---

## 1. Team-Lead rationale
P3-2 shipped the escalation engine's *audit-triggered* nervous system (T1/T2/T3/T7 + T6 manual). P3-3 gives CAPs a **time-based** nervous system: a daily background job that ages overdue open CAPs and nudges stale done-but-unverified CAPs. Without it, a CAP whose deadline passes just sits `open` forever with no one alerted — the whole corrective-action loop depends on this heartbeat. This is pure downstream logic over data we already write: it **reads** CAPs, **transitions** overdue ones to `aged`, appends a `cap_log` row, and **raises** an escalation one tier up. It touches no audit data (R5-clean) and needs no schema change (R2-clean).

## 2. Grounding — what I verified in code + spec
- **`caps` table (schema.dart L200–226)** already has every field the job needs: `deadline TEXT NOT NULL`, `status ... CHECK (open,done,verified,closed,aged,reopened)` (so `aged` is a legal target), `done_at`, `aged_count INTEGER NOT NULL DEFAULT 0`, `responsible_user_id NOT NULL REFERENCES users(id)`.
- **`cap_log` (L246–254)**: `event ... CHECK (... 'aged' ...)` is legal; `actor_user_id TEXT REFERENCES users(id) ON DELETE SET NULL` is **nullable** and `device_id` is nullable → a **system-run** aging job can insert a log row with `actor_user_id = NULL` (no fake user needed). ✅
- **`escalations` (L283–304)**: `trigger_number CHECK (BETWEEN 0 AND 7)` → **`0` is a legal "system / non-audit-trigger" number** for CAP-aging escalations; `source_type CHECK (... 'cap' ...)` → CAP escalations use `source_type='cap'`, `source_cap_id` set, `source_audit_id` NULL; `raised_by_user_id` is **nullable** → system-raised is fine.
- **Index `idx_caps_deadline ON caps(deadline) WHERE status IN ('open','aged')`** (L338–339) exists → the aging scan is index-backed.
- **`workmanager: ^0.9.0+3`** is in `pubspec.yaml` L60 (locked stack — no new package). No aging/`ageCheck` code exists anywhere yet (grep clean).
- **`CapRepository`** already follows a clean transactional pattern (`extendCap`/`reopenCap` at L610–714 wrap `caps` update + `cap_log` insert in `db.transaction`) — the new `ageOverdueCaps()` must mirror this exactly.
- **`§9.1 ageCheck()` pseudocode** (the contract to implement):
  ```
  open_caps = SELECT * FROM caps WHERE status IN ('open','done')
  for each cap:
    if cap.deadline < today AND cap.status == 'open':
        UPDATE caps SET status='aged', aged_count = aged_count + 1
        INSERT cap_log: event='aged', from='open', to='aged'
        escalate_one_tier_up(cap)          // SM-owned → GM ; GM-owned → Owner
    elif cap.deadline < today AND cap.status == 'done' AND days_since_done > 3:
        escalate('verify_pending', target=verifier_or_GM, urgency='same_day')
  ```

## 3. ⚠️ Two design decisions (no schema change — flagging, not gating)

### 3.1 Verify-pending idempotency (MUST solve — silent-double-raise risk)
The **open→aged** transition is *naturally idempotent*: once a CAP becomes `aged`, the `WHERE status='open'` scan never re-selects it, so it ages exactly once. **But the verify-pending branch does NOT change CAP status** — a `done`, overdue, >3-days-stale CAP stays `done`, so a naive daily job would raise a fresh `verify_pending` escalation **every single day**. That must be guarded.

`EscalationRepository.raise()` idempotency is currently keyed on `(trigger_number, source_audit_id, raised_to_user_id)` **and only fires when `source_audit_id != null`** (repo L44). CAP escalations have `source_audit_id == null`, so today they bypass the guard entirely. **Fix (repo change, no schema change):** extend the idempotency check so that when `sourceAuditId == null && sourceCapId != null`, it guards on `(trigger_number, source_cap_id, raised_to_user_id)` instead. For verify-pending specifically, that means one open escalation per (CAP, recipient) until it is resolved — re-raise only after the prior one is resolved/closed. **Decision:** guard verify-pending on *an existing non-resolved escalation for that CAP*; do not re-raise while one is still `open`/`acknowledged`.

### 3.2 Escalation trigger identity for CAP aging
`createManualEscalation` (engine L312) hardcodes `triggerNumber: 6` / label `'Customer complaint'` — semantically wrong for aging. **Add two dedicated draft builders** on the engine (pure, testable), NOT reusing the T6 manual builder:
- `EscalationEngine.createCapAgedEscalation({cap, responsibleRole, ...})` → `triggerNumber: 0`, `triggerLabel: 'CAP aged'`, `sourceType: 'cap'`, `sourceCapId: cap.id`, `sourceAuditId: null`, target = **one tier up** from `responsibleRole` (SM→GM, GM→Owner; Owner-owned aged CAP → Owner, i.e. stays, per no-higher-tier), `urgency: 'same_day'`, channel per spec (in_app; whatsapp only if spec §9 says so — default in_app).
- `EscalationEngine.createVerifyPendingEscalation({cap, ...})` → `triggerNumber: 0`, `triggerLabel: 'CAP verify pending'`, `sourceType: 'cap'`, `sourceCapId: cap.id`, target = verifier-or-GM, `urgency: 'same_day'`, channel in_app.

Both are `trigger_number = 0` (legal per CHECK 0–7) — the discriminator between them is `trigger_label` + `what_happened`. If the Owner would rather these carry a different number, that is a spec-labelling call, not a blocker; flag it in the handoff but build with `0` as the system default.

### 3.3 "Tier up" recipient resolution
`escalate_one_tier_up` needs the responsible user's **role**. `caps.responsible_user_id → users.role`. Map: `SM → GM`, `GM → Owner`, `Owner → Owner` (cannot escalate above Owner — raise to Owner and let `raise()` idempotency prevent a churn loop). `EscalationRepository.raise()` already resolves `targetRole` ('GM'/'OWNER') to a concrete recipient via `UserRepository`, so the engine only needs to emit the **target role string**, not a user id. Confirm the exact role tokens in `users` seed (`SM`/`GM`/`OWNER`?) before wiring — STOP and ask if the seed tokens differ from these.

## 4. In-scope for P3-3 (buildable now — no schema change)
1. **`CapRepository.ageOverdueCaps({DateTime? asOf})` (transactional, unit-tested).** Selects `caps WHERE status IN ('open','done')`; `asOf` defaults to now (injectable for tests). For each:
   - **open + deadline < asOf** → in one `db.transaction`: `UPDATE caps SET status='aged', aged_count = aged_count + 1 WHERE id=?`; `INSERT cap_log (event='aged', from_status='open', to_status='aged', actor_user_id=NULL, device_id=NULL, note='Auto-aged: deadline <deadline> passed')`. Then return the aged CAP in the result so the caller can raise the escalation **outside** the CAP transaction (so an escalation-delivery failure never rolls back the aging — mirror the P3-2 R5-safe post-submit pattern).
   - **done + deadline < asOf + `daysSinceDone(cap.done_at, asOf) > 3`** → collect as a verify-pending candidate (no status change).
   - Returns a struct: `{ agedCaps: List<Cap>, verifyPendingCaps: List<Cap> }`.
   - Deadline comparison uses **date-only** semantics per spec (`cap.deadline < today`), consistent with existing `getCapCounts` overdue logic (`todayStr = ...substring(0,10)`). Match that exactly so overdue is defined identically across the app.
2. **`CapAgingService.runDailyAging({DateTime? asOf})`** (orchestrator, non-blocking): calls `ageOverdueCaps`, then for each aged CAP raises `createCapAgedEscalation` (tier-up) and for each verify-pending CAP raises `createVerifyPendingEscalation`, each via `EscalationRepository.raise()`, then dispatches notification/in-app per the P3-2 `EscalationService` delivery path. Wrap the escalation loop in try/catch per CAP so one failure doesn't abort the batch.
3. **`EscalationRepository.raise()` idempotency extension** (§3.1): guard on `source_cap_id` when `source_audit_id == null`; for verify-pending, skip if a non-resolved escalation for that CAP already exists.
4. **Two pure engine draft builders** (§3.2) + unit tests (tier-up mapping truth table: SM→GM, GM→Owner, Owner→Owner; verify-pending target; correct labels; `trigger_number==0`; `source_type=='cap'`; English body).
5. **WorkManager registration**: register a periodic task at app start (`main.dart`) — daily cadence, spec §9.1 says **00:05 local**. WorkManager's minimum periodic interval is 15 min and it cannot guarantee an exact clock time; implement as a **daily periodic task** and, inside the callback, no-op if it already ran for today's date (persist a "last aged date" marker so multiple wake-ups in a day age at most once). Document this WorkManager constraint in code comments — do not pretend it fires exactly at 00:05. The callback must open its own DB (background isolate) — confirm `AppDatabase` can be initialised in the WorkManager isolate; if the singleton/isolate boundary is a problem, STOP and ask before hacking around it.
6. **Manual trigger for QA**: expose `CapAgingService.runDailyAging()` callable from a debug/dev entry so Antigravity can test aging on-device without waiting for midnight (the injectable `asOf` also lets unit tests drive it deterministically).
7. **Bilingual EN+MR** for any new **UI chrome** (e.g. an "Aged" filter/badge label on the CAP list, notification title/body strings) — real Marathi, STOP and ask if uncertain (R3/R8). The **escalation message body stays English-only** (R-Escalation, same as P3-2).

## 5. Out of scope for P3-3 (Rule 9)
- **T4 + T5** (inventory-variance & security-flag triggers) → still **P3-2b**, Owner-gated on the two-column schema addition (see §7).
- **Monthly reports (S21) + trend charts (fl_chart)** → **P3-4**.
- **CAP extension UI/rules (§9.2)** — already shipped in the P2-5 CAP lifecycle (`extendCap` exists); P3-3 only must respect it (an extended deadline moves the aging boundary; a CAP cannot be extended once `aged`, which `extendCap`'s status guard already enforces). No new extension work here.
- **Real push / Firebase / server-side scheduling** → Phase 4. P3-3 is local WorkManager + the existing local-notification/WhatsApp/clipboard delivery only.

## 6. Guardrails recap
- **R1:** built to §9.1 pseudocode + state-transition table; the two design calls (§3) are surfaced, not silently chosen.
- **R2:** **no schema change** — all fields verified present; `workmanager` already in the locked stack. The repo idempotency extension is logic, not schema.
- **R3/R8:** real EN+MR for new UI chrome; escalation body English-only by design.
- **R5:** the job only **reads** audits (never), **transitions CAPs** (`open→aged` only — a legal state move, not audit mutation) and **inserts** cap_log/escalation rows; escalation raising happens **outside** the CAP transaction so delivery failure never rolls back an aging.
- **R6:** review-gated. Antigravity builds → `flutter analyze` + `flutter test` (score engine + escalation + new aging tests all green) → pastes raw output → **HOLD**. Claude reviews and writes `APPROVED — cleared to commit & push` before any commit.
- **R7:** work on `feature/p3-cap-auto-aging` off `phase-3`; merge to `phase-3` on approval; never to `main` until Phase-3 sign-off.
- **R10:** Conventional Commits.

## 7. P3-2b R2 gate — still open (Owner ruling carried forward)
The prior Owner answer was *"Decide after Antigravity's confirmations."* Antigravity's confirmations have now landed (P3-2 shipped; cash-variance capture confirmed present). The two triggers **T4 (Inventory variance > 2%)** and **T5 (Security concern flag)** remain blocked on adding two spec-sourced columns — `audits.inventory_variance_pct REAL` and `audit_results.flag_security_concern INTEGER DEFAULT 0 CHECK (0,1)` — **plus** their conduct-flow capture UI. That is a §4.4 four-way change (schema + seed/DoD + spec reconciliation + tests). **Recommendation:** run P3-3 first (zero-risk, no schema change), then take up P3-2b as its own gated sprint so the schema migration + capture UI get proper isolated review. **No T4/T5 code and no schema edit until the Owner authorises the two columns.**

## 8. Build order (once branch is cut)
1. `EscalationEngine.createCapAgedEscalation` + `createVerifyPendingEscalation` (pure) + unit tests (tier-up truth table, labels, trigger_number==0, source_type=='cap', English body). **Tests first.**
2. `CapRepository.ageOverdueCaps({asOf})` (transactional; open→aged + cap_log; returns aged + verify-pending sets) + unit tests with injected `asOf` (aged transition, aged_count increment, no double-age, date-only boundary, done>3-days selection).
3. `EscalationRepository.raise()` idempotency extension for `source_cap_id` + test (no daily re-raise of verify-pending while one is open).
4. `CapAgingService.runDailyAging({asOf})` orchestrator (aging → raise → dispatch, per-CAP try/catch) + integration test.
5. WorkManager daily registration in `main.dart` + "already ran today" marker; background-isolate DB init check (STOP and ask if isolate boundary blocks `AppDatabase`).
6. Bilingual ARB keys for new UI chrome (Aged badge/filter, notification strings).
7. `flutter analyze` + full `flutter test`; paste raw output; **HOLD** for Claude review.

## 9. Immediate next step
Antigravity: cut `feature/p3-cap-auto-aging` off `phase-3` and build in the §8 order. Before wiring the tier-up, **confirm the exact role tokens in the `users` seed** (`SM`/`GM`/`OWNER`?) and **confirm `AppDatabase` can initialise inside the WorkManager background isolate** — report both back in the handoff; STOP and ask if either differs from the assumption in §3.3/§4.5. Build tests-first, run analyze + full test, paste raw output, and HOLD for review. Do not commit until I write `APPROVED — cleared to commit & push`.
