# Sprint P3-2b — Triggers T4 (Inventory Variance) & T5 (Security Flag) — 🟢 PLAN / R2 GATE CLEARED BY OWNER

**Phase**: 3 (Monthly + Escalation + Trends, Weeks 9–11)
**Sprint**: P3-2b (completes the 7-trigger escalation engine begun in P3-2)
**Author of plan**: Claude (Team Lead)
**Date**: 2026-09-30
**Branch**: `feature/p3-t4-t5-triggers` off `phase-3` (Rule 7)
**Spec**: SPEC_APP §7 / `brain/spec/06_SCORING_AND_ESCALATION.md` L299–311 / Appendix A.5 / OVERVIEW.md Phase-3 scope ("7-trigger Escalation Engine")
**Status**: 🟢 **CLEARED TO BUILD.** The **Owner has ruled on the P3-2 R2 gate (2026-09-30): build T4 + T5 first, then continue queued Phase-3 work.** This authorises the two spec-sourced schema columns. This is a **§4.4 four-way change** (schema + model/capture + spec reconciliation + tests) — build carefully, tests-first, and HOLD for review per Rule 6.

---

## 1. Owner ruling (records the R2 decision)
The P3-2 plan raised an R2 gate: T4 and T5 reference two fields present only in the spec text, not in `schema.dart`, so per R2 I stopped and asked before any schema change. **On 2026-09-30 the Owner ruled: complete the two missing alerts (T4 & T5) first, then continue the next queued work.** The Owner also confirmed (correctly, per `OVERVIEW.md`) that the full 7-trigger engine — T4 and T5 included — is **Phase-3 scope**, not deferrable to Phase 4. This sprint therefore adds the two columns **with the Owner's explicit authorisation and this written record**, consistent with the existing `cash_variance_rupees` precedent (a documented, spec-sourced column addition — not silent drift).

## 2. Grounding — what I verified in code + spec
- **Schema today**: `audits` (schema.dart L130–157) has `cash_variance_rupees REAL` but **no `inventory_variance_pct`**. `audit_results` (L162–172) has `result/finding_text/cro_id` but **no `flag_security_concern`**. `Schema.currentVersion == 2` (L17).
- **Spec logic** (`06_SCORING_AND_ESCALATION.md` L299–311):
  - **T4** — `if audit_type == 'weekly' AND inventory_variance_pct > 2.0: raise(trigger=4, to=Owner, urgency='same_day', via='whatsapp')`
  - **T5** — `for each result: if result.flag_security_concern == 1: raise(trigger=5, to=Owner, urgency='immediate', via='whatsapp')`
- **Engine is ready for these**: `escalation_engine.dart` L64–65 already carries the placeholder note "Triggers 4 … and 5 … are deferred to P3-2b." `evaluateAfterAudit` already receives `audit`, `results`, `checkpoints` — everything T4/T5 need. `EscalationRepository.raise()` idempotency guards on `(trigger_number, source_audit_id, raised_to_user_id)`, so multiple T5 rows (one per flagged result) must be discriminated by `what_happened` the same way T2 is (L44–58) — **plan for that.**
- **Capture-point precedent (the template to copy exactly)**: `cash_variance_rupees` flows end-to-end as `review_submit_screen.dart` (numeric input, L175 `cashVarianceRupees: cashVariance`) → `draft_audit_provider.submitAudit({cashVarianceRupees})` (L287/378/392) → `audit_repository` (L276/292 writes `'cash_variance_rupees'`) → `audit.dart` model (L21/50/78/109/138/166). **T4's `inventory_variance_pct` mirrors this exactly**, gated to `audit_type=='weekly'`.
- **`audit_results` model** (`audit_result.dart`): fields `id/auditId/checkpointId/result/weightedPoints/findingText/croId/createdAt`. **T5 adds `flagSecurityConcern`** to this model + its `fromMap`/`toMap`/`copyWith`, written wherever results are persisted (draft_audit_provider result-write path).
- **R5 note**: both new columns are written **at/through submit**, before the audit is immutable, exactly like `cash_variance_rupees` — no post-submit mutation of a submitted audit.

## 3. Schema change (§4.4 item 1 — Owner-authorised)
Bump `Schema.currentVersion` **2 → 3**. Two additive, nullable/defaulted columns — safe `ALTER TABLE ... ADD COLUMN` (no table rebuild, no data loss):
```sql
ALTER TABLE audits        ADD COLUMN inventory_variance_pct REAL;
ALTER TABLE audit_results ADD COLUMN flag_security_concern  INTEGER NOT NULL DEFAULT 0 CHECK (flag_security_concern IN (0,1));
```
- **Fresh installs**: add both columns to the `CREATE TABLE` statements in `schema.dart` (`_audits`, `_auditResults`) so `onCreate` builds v3 directly. Document each with a `-- spec §7 T4/T5` comment mirroring the existing `cash_variance_rupees` doc note (schema.dart L7–8, L128).
- **Existing devices (v2→v3)**: add an `if (oldVersion < 3) { ... }` branch in `database.dart onUpgrade` running the two `ALTER TABLE`s. **Guard idempotently** (the codebase already uses defensive `onOpen` re-checks) — wrap in a "column exists?" check via `PRAGMA table_info` or `ALTER` inside try/catch so a partially-migrated device can't crash. Note: SQLite `ALTER TABLE ADD COLUMN` with `NOT NULL` **requires a DEFAULT** — the `DEFAULT 0` above satisfies that; verify the CHECK is accepted on ADD COLUMN (SQLite allows column-level CHECK on ADD COLUMN).
- **`DATABASE_SCHEMA.md`**: update the `audits` and `audit_results` table docs + the migration note (§4.4 item 3 — spec reconciliation).

## 4. Capture UI (§4.4 item 2 — the reason T4/T5 were gated, not just schema)
Adding columns is worthless if nothing writes them. Both need a conduct/review capture point, bilingual EN+MR (R3/R8, real Marathi — STOP and ask if uncertain):

### 4.1 T4 — Inventory variance % (weekly only)
- A **numeric input** on the **weekly** review/submit path, shown **only when `audit_type=='weekly'`** (daily audits must not show it). Mirror the existing closing-cash-variance input in `review_submit_screen.dart`. Label e.g. EN "Inventory Variance (%)" / MR authentic. Optional field (nullable) — if blank, T4 simply never fires (like T3 when no cash variance).
- Thread it through `submitAudit({..., inventoryVariancePct})` → repository → `audits.inventory_variance_pct`.
- **Confirm**: is inventory variance measured during the weekly count and known at review time? If the Workbook says it's captured elsewhere (e.g. a specific weekly checkpoint), wire it there instead — **Antigravity to confirm the exact weekly capture location against the Workbook before choosing the input's home.** STOP and ask if ambiguous (R1).

### 4.2 T5 — Security-concern flag (per checkpoint result)
- A **toggle/checkbox** during conduct so the auditor can mark **any** checkpoint result as a security concern (independent of P/F/NA — a security worry can accompany a Pass). Most naturally lives on the checkpoint conduct card and/or the fail-detail screen; it sets `flag_security_concern=1` on that `audit_results` row.
- Thread through the result-write path in `draft_audit_provider` so it persists per result.
- **R5**: the flag is set during conduct/before submit; once submitted the audit (and its results) are immutable.

## 5. Engine wiring (§4.4 — the actual triggers)
Add to `EscalationEngine.evaluateAfterAudit` (pure, deterministic, tests-first):
- **T4** — `if (audit.auditType == 'weekly' && (audit.inventoryVariancePct ?? 0) > 2.0)` → one draft: `triggerNumber:4`, label `'Inventory variance > 2%'`, `sourceType:'audit'`, `targetRole:'OWNER'`, `urgency:'same_day'`, `deliveryChannel:'whatsapp'`, English 4-part body citing the measured %.
- **T5** — `for each result where flagSecurityConcern == true` → one draft **per flagged result**: `triggerNumber:5`, label `'Security concern'`, `sourceType:'audit'`, `targetRole:'OWNER'`, `urgency:'immediate'`, `deliveryChannel:'whatsapp'`, body citing the specific checkpoint. **Idempotency**: extend `EscalationRepository.raise()` T2-style `what_happened` discrimination to also apply to `triggerNumber==5` (multiple flagged checkpoints each get their own row) — do **not** collapse them.
- Remove the "deferred to P3-2b" note at engine L64–65 and update the class doc to list T4/T5 as implemented.
- **Message body English-only** (R-Escalation) — same as every other trigger.

## 6. Tests (§4.4 item 4 — must be green before review)
1. **Engine truth tables** (pure, no DB): T4 fires at `inventory_variance_pct > 2.0` on weekly, **does not** fire at exactly `2.0`, does not fire on daily/monthly, does not fire when null; T5 raises one draft per flagged result and zero when none flagged; both target Owner with correct urgency/channel; English body asserted.
2. **Idempotency**: two flagged checkpoints → two distinct T5 rows (via `what_happened` discrimination); re-raising the same flagged result → no duplicate.
3. **Migration test**: open a v2 DB, run the upgrade, assert both columns exist and existing rows default correctly (`flag_security_concern=0`, `inventory_variance_pct=NULL`); assert `score_engine_test.dart` and all existing suites stay green (no regression from the schema bump).
4. **Capture persistence**: submitting a weekly audit with an inventory variance writes the column; flagging a checkpoint writes `flag_security_concern=1`.
5. **ARB parity** guard for the new capture-UI keys (EN+MR).

## 7. Guardrails recap
- **R1:** built to the spec pseudocode; the one open question (exact weekly inventory-variance capture location) is surfaced for Antigravity to confirm against the Workbook, not silently chosen.
- **R2:** schema change is **explicitly Owner-authorised** and recorded here (§1) — not silent drift. No new packages. Version bump 2→3 with a real migration + fresh-install CREATE update.
- **R3/R8:** real EN+MR for the new capture UI; escalation body English-only by design.
- **R4:** scoring is untouched — the score engine must stay green after the schema bump (regression test in §6.3).
- **R5:** both fields captured at/before submit; submitted audits/results remain immutable.
- **R6:** review-gated. Antigravity builds → `flutter analyze` + full `flutter test` → pastes raw output → **HOLD**. Claude reviews (schema migration + capture wiring + engine + tests) and writes `APPROVED — cleared to commit & push` before any commit.
- **R7:** `feature/p3-t4-t5-triggers` off `phase-3`; merge to `phase-3` on approval; never to `main` until Phase-3 sign-off.
- **R10:** Conventional Commits.

## 8. Build order
1. Schema: bump `currentVersion` 2→3, update `_audits`/`_auditResults` CREATE statements, add `onUpgrade` v2→v3 ALTER branch (idempotent). Migration test green first.
2. Models: add `inventoryVariancePct` to `Audit` and `flagSecurityConcern` to `AuditResult` (+ fromMap/toMap/copyWith); repository/provider write paths.
3. Engine: implement T4 + T5 in `evaluateAfterAudit`; remove the deferral note. **Truth-table tests first.**
4. `raise()` idempotency: extend `what_happened` discrimination to `triggerNumber==5`.
5. Capture UI: weekly inventory-variance input + per-checkpoint security-flag toggle; bilingual ARB keys.
6. `flutter analyze` + full `flutter test` (score engine + escalation + new T4/T5 + migration all green); paste raw output; **HOLD** for review.

## 9. Immediate next step & confirmation requested
Antigravity: cut `feature/p3-t4-t5-triggers` off `phase-3` and build in the §8 order. **Before wiring the T4 input, confirm against the Workbook where weekly inventory variance is actually measured/entered** (review screen vs. a dedicated weekly checkpoint) and report it in the handoff — STOP and ask if the Workbook is ambiguous rather than guessing. Build tests-first, run `analyze` + full `test`, paste raw output, and HOLD. Do not commit until I write `APPROVED — cleared to commit & push`.

## 10. After P3-2b (queued Phase-3 work — per Owner "then continue next queued work")
- **P3-4** — Monthly Reports (S21 monthly view) + multi-week compliance **trend analytics with `fl_chart`** (already in the locked stack). Read-only over existing data; no schema change expected. This is the last Phase-3 build before the Phase-3 sign-off merge to `main`.
