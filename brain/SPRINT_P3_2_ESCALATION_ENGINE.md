# Sprint P3-2 — 7-Trigger Escalation Engine (Phase 3) — 🟡 PLAN / R2 GATE RAISED

**Phase**: 3 (Monthly + Escalation + Trends, Weeks 9–11)
**Sprint**: P3-2 (second sprint of Phase 3)
**Author of plan**: Claude (Team Lead)
**Date**: 2026-09-29
**Branch**: `feature/p3-escalation-engine` off `phase-3` (Rule 7)
**Spec**: SPEC_APP §7 / `brain/spec/06_SCORING_AND_ESCALATION.md` L280–330 / Appendix A.5
**Status**: 🟡 **PLAN — NOT CLEARED TO BUILD IN FULL.** Escalation engine core + Triggers **T1, T2, T3, T7, T6-manual** are buildable against the current schema and are cleared to design. **Triggers T4 and T5 depend on two columns that DO NOT EXIST** in `schema.dart` — this is an **R2 schema-drift gate** the Owner must rule before those two triggers are built. See §3.

---

## 1. Team-Lead rationale
Phase 3 adds the Owner's tier (P3-1 ✅ done), the **escalation engine** (this sprint), CAP auto-aging (P3-3), and trend analytics (P3-4). The escalation engine is the app's "nervous system": after an audit is submitted (and on certain CAP changes), it evaluates threshold breaches and routes an alert to the right person (GM or Owner) at the right urgency, records it in the `escalations` table, raises an in-app notification, and for urgent cases opens a pre-filled WhatsApp message. This is pure downstream logic over data we already write — no change to the scoring engine, no change to audit immutability (R5).

## 2. Grounding — what I verified in code + spec
- **`escalations` table already exists**, fully formed (`schema.dart` L283–305): `trigger_number` (CHECK 0–7), `trigger_label`, `source_type` (`audit|cap|trend|manual`), `source_audit_id`, `source_cap_id`, `raised_by_user_id`, `raised_to_user_id`, `urgency` (`immediate|same_day|same_night|next_audit`), `what_happened`, `evidence`, `impact`, `requested_action`, `status` (`open|acknowledged|resolved`), `raised_at`, `acknowledged_at`, `resolved_at`, `resolution_notes`, `whatsapp_sent` (0|1). Index `idx_escalations_status ON (status, raised_at)` exists. **No table-level schema change is needed for the escalation record itself.**
- **`audits.band`** exists (`excellent|good|fair|poor|critical`) → **T1 buildable.**
- **`audits.cash_variance_rupees`** exists (REAL, added per Spec §6.7 note in `schema.dart` L7–8) and is modelled in `audit.dart` → **T3 buildable at the data layer** (but see §3.3 — verify a capture point exists).
- **`audits.compliance_pct`** + audit history → **T7 (3-week decline) buildable.**
- **`audit_results` (result P/F/NA, checkpoint_id, audit history)** → **T2 (same checkpoint failed ≥5 of last 7 dailies) buildable.**
- **T6** is manual (raised from CAP detail / customer-complaint note, not auto) → buildable as a manual `raise()` entry point.

## 3. ⛔ R2 GATE — two triggers need columns that do not exist (Owner must rule)
Per R2 I must **STOP and ask** before any schema change; I will not silently add columns. Two of the seven triggers reference fields present **only in the spec text**, not in `schema.dart`:

### 3.1 T4 — Inventory variance > 2%
Spec (`06_SCORING_AND_ESCALATION.md` L299–303):
```
if a.audit_type == 'weekly' AND a.inventory_variance_pct > 2.0:
    raise(trigger=4, to=Owner, urgency='same_day', via='whatsapp')
```
**`audits.inventory_variance_pct` does not exist.** The `audits` table has `cash_variance_rupees` but **no inventory-variance column.** Building T4 requires (a) adding the column (schema change — R2), and (b) a **capture point** in the weekly conduct flow for the Owner/GM to enter the measured inventory variance %.

### 3.2 T5 — Security concern flag
Spec (L307–311):
```
for each result in audit_results:
    if result.flag_security_concern == 1:
        raise(trigger=5, to=Owner, urgency='immediate', via='whatsapp')
```
**`audit_results.flag_security_concern` does not exist.** Building T5 requires (a) adding the column (schema change — R2), and (b) a **UI toggle** during conduct so the auditor can flag a checkpoint result as a security concern.

### 3.3 T3 caveat — cash-variance capture
`cash_variance_rupees` is modelled and read (review screen reads it for the CW.7 cumulative panel) but I did **not** confirm a conduct-flow input actually *writes* it. If it is never captured, T3 will silently never fire. **Antigravity to confirm** whether daily conduct captures `cash_variance_rupees`; if not, that capture point is part of T3's scope (no schema change — column exists).

### Precedent & my recommendation
`cash_variance_rupees` was itself a **documented, spec-sourced** addition to `audits` (not a silent drift) — so there is a clean precedent for adding variance/flag fields *when the Owner approves and it is recorded*. My recommendation:

- **Split the sprint. P3-2 (this one) builds the engine + T1, T2, T3, T7, and the T6 manual entry point** — everything the current schema already supports. This lands the whole notification/WhatsApp/escalations-list machinery and 5 of 7 triggers with **zero schema change**.
- **T4 + T5 move to P3-2b**, gated on the Owner approving the two-column addition (`audits.inventory_variance_pct REAL`, `audit_results.flag_security_concern INTEGER DEFAULT 0 CHECK (0,1)`) **plus** their conduct-flow capture UI. That is a §4.4 four-way change (schema + seed/DoD + spec reconciliation + tests) and should not be smuggled into this sprint.

**Owner decision needed:** approve the P3-2 / P3-2b split (recommended), OR authorize the two-column schema addition now so all 7 triggers ship together. **No T4/T5 code and no schema edit until this is ruled.**

## 4. In-scope for P3-2 (buildable now — no schema change)
1. **`EscalationEngine` (pure/deterministic, unit-tested)** — `evaluateAfterAudit(Audit, List<AuditResult>, {history})` returns a `List<EscalationDraft>`. Keep it a **pure function over inputs** (mirror the `score_engine.dart` style) so it is fully testable without a DB. No side effects inside the evaluator.
2. **`EscalationRepository.raise(EscalationDraft)`** — inserts the `escalations` row (status `open`, `raised_at` now), returns the row. Idempotency: do **not** double-raise the same (trigger_number, source_audit_id) — guard on insert. Wrapped in a transaction.
3. **Triggers implemented now:**
   - **T1** — `audit_type=='daily'` AND `band=='critical'` (<80%): → GM, `same_night`. If the critical cause is a cash/inventory SOP fail → **also** Owner, `same_night`, via whatsapp; else in_app. (Determine "cash/inv cause" from failed `audit_results` joined to `checkpoints.sop_id` ∈ {SOP6 cash, SOP7 inventory} — confirm SOP ids against seed.)
   - **T2** — on weekly submit: for each checkpoint, if it failed in **≥5 of the last 7 dailies** → GM, `next_audit`, in_app.
   - **T3** — `daily` AND `abs(cash_variance_rupees) > 500` → GM, `same_day`, whatsapp. If **yesterday's** daily also >500 → **also** Owner, `immediate`, whatsapp. (See §3.3 capture caveat.)
   - **T7** — on weekly submit: last 4 weekly `compliance_pct` strictly declining across 3+ weeks (`w[-3] > w[-2] > w[-1]`, oldest→newest per spec) → Owner, `same_day`, in_app.
   - **T6** — **manual** `raise()` entry point from CAP detail / customer-complaint note (auditor-initiated), routed per spec.
4. **`buildEscalationMessage(EscalationDraft) → EscalationMessage`** — the **4-part** format: **What happened · Evidence · Impact · Requested action**. **CRITICAL (R-Escalation): the message body is ALWAYS in English regardless of the recipient's UI language** — it may be forwarded to the bank / police / Titan corporate. The *in-app chrome* (buttons, list labels) is bilingual EN+MR per R8; the *message content* is English-only by design. Document this explicitly in the ARB comments so it is not "fixed" later as a parity bug.
5. **Delivery:**
   - **In-app notification** via `flutter_local_notifications` (STOP-and-ask R2 check: confirm this package is already in `pubspec.yaml`; if not, adding it is a locked-stack addition needing sign-off — but it is the spec-named mechanism, so flag rather than assume).
   - **WhatsApp deep link** `https://wa.me/{phone}?text={urlencode(message.full)}` opened via `url_launcher` for `via=='whatsapp'` triggers; set `whatsapp_sent=1` on success.
   - **Clipboard copy** fallback ("Copy alert") so the message can be pasted anywhere if WhatsApp is unavailable.
6. **Escalations list UI** — a screen (Owner/GM) listing open escalations with acknowledge/resolve actions writing `status`, `acknowledged_at`, `resolved_at`, `resolution_notes`. Bilingual EN+MR chrome (R8).
7. **Bilingual EN+MR** for every new UI string (R3/R8), authentic Marathi — STOP and ask if any Marathi is uncertain. (Message *body* excepted per §4.4 above.)

## 5. Out of scope for P3-2 (Rule 9)
- **T4 + T5** → **P3-2b** (schema + capture UI, Owner-gated per §3).
- **CAP auto-aging job** → **P3-3**.
- **Monthly reports (S21) + trend charts (fl_chart)** → **P3-4**.
- **Real push / Firebase / server delivery** → Phase 4. P3-2 delivery is local-notification + WhatsApp deep-link + clipboard only.

## 6. Guardrails recap
- **R1:** the §3 field gaps are surfaced to the Owner, not silently designed around; Workbook/Spec is ground truth.
- **R2:** **no schema change** in P3-2 — the escalations table already fits. `flutter_local_notifications` / `url_launcher` presence to be **confirmed in pubspec before use**; adding a new package is a locked-stack decision → flag, don't assume. T4/T5 columns are a separate gated change.
- **R3/R8:** real EN+MR for all new UI chrome; **escalation message body is intentionally English-only** — document, don't treat as a parity defect.
- **R5:** the engine only **reads** submitted audits and **inserts** escalation rows; it never mutates `audits`/`audit_results`/scores.
- **R6:** review-gated. Antigravity builds → `flutter analyze` + `flutter test` → pastes raw output → **HOLD**. Claude reviews and writes `APPROVED — cleared to commit & push` before any commit.
- **R7:** work on `feature/p3-escalation-engine` off `phase-3`; never push Phase-3 app code to `main` until Phase-3 sign-off.
- **R10:** Conventional Commits.

## 7. Build order (once §3 is ruled)
1. `EscalationEngine` pure evaluator + unit tests (T1, T2, T3, T7 truth tables; canonical cases with exact expected trigger/recipient/urgency). **Tests first — this is pure logic.**
2. `EscalationRepository.raise()` + idempotency guard + escalations-list read queries.
3. `buildEscalationMessage` (4-part, English body) + tests asserting the English-only rule.
4. Wire evaluator into the post-submit path (after `submitAudit`, outside the audit's own transaction so a delivery failure never rolls back a submitted audit).
5. Delivery: local notification + `wa.me` deep link + clipboard fallback (confirm packages first).
6. Escalations-list UI + acknowledge/resolve; bilingual ARB keys.
7. `flutter analyze` + full `flutter test`; paste raw output; HOLD for Claude review.

## 8. Immediate next step
This plan is ready for the Owner's ruling on the **§3 R2 gate** (P3-2 / P3-2b split — recommended — vs. authorize both columns now). Antigravity: do **not** build yet. First (a) confirm whether `flutter_local_notifications` + `url_launcher` are in `pubspec.yaml`, (b) confirm the SOP ids for cash/inventory in the seed (for T1/T3 cause detection), and (c) confirm whether daily conduct captures `cash_variance_rupees` (T3 §3.3). Report those three back in the handoff; I'll finalize §4 into the buildable spec once the Owner rules the gate.
