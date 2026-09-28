# Sprint P2-3 — Interactive 7-Day Daily Review + Spot-Check + GM Verify/Signature

**Phase**: 2 (Weekly Audit, Weeks 5–8)
**Sprint**: P2-3 (third sprint of Phase 2)
**Author of plan**: Claude (Team Lead)
**Date set**: 2026-09-28
**Branch**: continue on `phase-2`; cut `feature/p2-spotcheck` off `phase-2` (Rule 7 — branches only, never folders).
**Pre-condition (met)**: P2-2 merged to `phase-2` (6738b62), plus S10/S13 overflow polish approved 2026-09-28. 235/235 green per Antigravity's device run. Weekly conduct end-to-end works; weekly Review already pulls the 7 daily audits **headlessly** to compute the 124-pt score.

---

## 1. Team-Lead rationale
P2-2 let the GM *conduct* a weekly audit and see the real 124-pt score, where the daily-average contribution was pulled **headlessly** (GM never sees or challenges the individual daily audits). P2-3 makes that step **interactive**: the GM opens the week, sees the 7 daily audits as cards, and can *spot-check* a day — the app surfaces 3 randomly-selected checkpoints from that day's audit, the GM verifies them against the original photos/registers, and on completion the daily audit is stamped **GM-verified** with the GM's signature. This is the spec's T2.3 workflow and the Phase-2 "Day 6" screen. It is the accountability layer on top of the P2-2 rollup.

## 2. Grounding in spec (R1 — Workbook is ground truth)
- **T2.3** (SPEC_APP.md ~L3033): "GM opens weekly audit, taps Day 3. App shows **3 randomly-selected checkpoints** from day 3 for spot check. GM marks all 3 as Verified. EXPECTED: Day 3 daily audit now shows **GM-verified status. GM signature recorded.**"
- Phase-2 Day 6 screen: 7-day daily review — GM sees 7 daily audits as cards, opens each for spot check, validates against original photos/registers, GM signature.
- **Random selection**: spec says "3 randomly-selected checkpoints." Treat "3" and "random" as load-bearing. If the audited day has <3 marked checkpoints (shouldn't happen for a submitted daily = 68), select min(3, available). Seed the RNG per (audit_id) is NOT required by spec — use a fresh random draw each time the spot-check is opened, unless §-level guidance says otherwise. If you find a spec line pinning determinism, STOP and flag R1.

## 3. ⛔ BLOCKING DATA-MODEL GATE — resolve BEFORE any UI (R2 + Spec §4.4 four-way)
I inspected `lib/data/db/schema.dart`. Status quo:
- `audits.status` already allows `'verified'`; `audits.verified_at` and `audits.verifier_id` **already exist**. → Marking a daily audit GM-verified needs **NO schema change**. Good.
- **There is NO signature storage anywhere** (grep `signature` across `lib/` = 0 hits) and **NO spot-check record table**. The spec's "GM signature recorded" and the audit trail of *which 3 checkpoints were spot-checked and their verify results* have nowhere to live.

**Decision required before building — do NOT silently pick one (R2, no silent schema drift):**
Three candidate approaches, in my recommended order:

- **Option A (Claude's lean recommendation): verification-only, no new table, no signature blob.**
  Record GM verification on the existing `audits` columns: set `status='verified'`, `verified_at`, `verifier_id` on the *daily* audit. Represent the "signature" as the authenticated GM identity + timestamp (`verifier_id` + `verified_at`) rather than a drawn/image signature. Spot-check selections are ephemeral UI (not persisted). Records **who verified and when**, satisfies "GM-verified status" literally, minimal footprint, zero migration.
  *Risk:* does not persist *which* 3 checkpoints were spot-checked, nor a hand-drawn signature. If the owner reads "signature" as a captured signature image, this under-delivers.

- **Option B: verification + persisted spot-check trail (new `spot_checks` table).**
  Option A **plus** a new `spot_checks` table (`id, audit_id, checkpoint_id, verified_by, verified_at, result`) capturing the 3 draws and their verdicts. This is a real schema addition → triggers the **Spec §4.4 FOUR-WAY update** (Workbook + Spec + JSON/seed n/a + versioned migration v2→v3) and §17.1 (not in Spec ⇒ must be added to Spec first). Better audit trail; heavier.

- **Option C: Option B + a signature capture (image/points blob on the verification record).**
  Adds a literal captured-signature artifact. Most faithful to "signature recorded" if the owner means a drawn signature; largest scope (signature-capture widget + storage + the same four-way).

**Antigravity: do NOT start UI until Claude posts the chosen option in `SESSION_HANDOFF.md`.** I am raising this to the owner. My working default if the owner is silent is **Option A** (identity+timestamp as the "signature"), because it needs no migration and the authenticated GM identity is a defensible signature-of-record for a v2 app; but because "signature" is explicitly in the spec, this is an R1/§4.4 decision I will confirm, not assume. If we go B/C, the schema change is a v3 migration and a Spec update lands **first**.

## 4. Scope — what Antigravity builds (AFTER §3 is resolved)

### 4.1 7-day daily review screen (new; Phase-2 "Day 6")
- Entry: from the weekly audit (S10 Review, or a dedicated tab) the GM opens a **7-Day Review**. Show the 7 daily audits for the audit's `week_number`/`year` as cards: date + weekday, compliance %, band chip, and a status badge (**Submitted** / **GM-verified** / **Missing**). Reuse the same headless fetch P2-2 already uses (`findSubmittedDailyAuditsForWeek`) — do NOT add a second query path. Missing day → a disabled "No audit submitted" card (cannot spot-check a day that has no daily audit).
- Role gate: **GM/OWNER only** (SM does not spot-check). Reuse existing role gating.
- EN+MR strings for every new label (R3/R8) — real Marathi, no guesses. If a string's Marathi is unknown, STOP and ask.

### 4.2 Spot-check flow (T2.3)
- GM taps a submitted day → app draws **3 random checkpoints** from that day's `audit_results` and shows each with: checkpoint text (EN/MR), the day's recorded verdict (P/F/NA), finding text, and any attached photos (so the GM verifies against original evidence). Reuse S09/photo-view widgets read-only.
- GM marks each of the 3 **Verified** (or flags a discrepancy — see below). All 3 verified → the day's daily audit is stamped per the §3 decision (Option A: `status='verified'`, `verified_at`, `verifier_id`).
- **Discrepancy handling**: spec T2.3 only exercises the happy path (all 3 Verified). If the GM finds a checkpoint doesn't match evidence, do the **minimum**: allow "Flag discrepancy" that records a note and **withholds** verification (day stays `submitted`, not `verified`). Do NOT auto-supersede or re-score the daily audit here (R5 immutability — a submitted daily is immutable; corrections are supersession, which is out of P2-3 scope). Anything beyond a flag → `docs/v2-wishlist.md`.

### 4.3 GM verify + signature write
- On all-3-verified, write the verification per §3 decision. **R5:** verification transitions `submitted → verified` (an allowed forward transition already in the schema CHECK); it must NOT mutate any `audit_results`, scores, or counts of the daily audit. Only `status`/`verified_at`/`verifier_id` (+ spot-check/signature rows if Option B/C).
- Repository: add `verifyDailyAudit({auditId, verifierId})` to `audit_repository.dart` that sets the three columns with a guard `WHERE id=? AND status='submitted'` (mirrors the `submitAudit` guarded-update pattern; throw if 0 rows). Do NOT allow re-verifying an already-verified or hidden audit.

### 4.4 Reflect verified status upstream
- S12 history + S13 detail: a GM-verified daily audit should render its **verified** badge (verifier + timestamp). S13 already renders `audit_type`/status — confirm it shows verified metadata read-only. Small wiring only.
- The weekly Review's daily-average is **unaffected** — verification does not change `compliance_pct`, so the 124-pt score is stable whether or not days are verified. (Do not recompute on verify.)

## 5. Tests — must be GREEN to close (Rule 5 + R4)
- **T2.3 happy path**: seed a week with 7 submitted daily audits; open 7-day review → 7 cards with correct status. Spot-check Day 3: draw 3 checkpoints, mark all Verified → Day 3 audit `status='verified'`, `verifier_id`/`verified_at` set; the other 6 stay `submitted`.
- **Random selection**: the 3 checkpoints are drawn from that day's marked results, count == 3 (or min(3, n)), no duplicates.
- **R5 immutability**: verifying a daily audit does NOT change its `raw_score`/`compliance_pct`/`audit_results`/counts; attempting to verify a `hidden` or already-`verified` audit is rejected.
- **Score stability**: the weekly 124-pt score for the week is identical before and after spot-check verification (re-assert T2.1 numbers hold).
- **Discrepancy**: flagging a discrepancy leaves the day `submitted` (not `verified`).
- **Regression (Rule 5)**: all existing tests stay green (235 + new). Canonical daily `81/90=90.0%` and weekly `104.8/124=84.5%` untouched.
- Paste raw `flutter analyze` + `flutter test` into `SESSION_HANDOFF.md`.

## 6. Definition of Done for P2-3
- [ ] §3 data-model gate resolved by Claude in writing (Option A/B/C) **before** UI started.
- [ ] GM can open a week → see 7 daily cards → spot-check a day (3 random checkpoints) → verify → day shows GM-verified with signature-of-record per §3.
- [ ] Verification is a pure `submitted→verified` transition; no daily score/result mutation (R5).
- [ ] Verified status/badge visible in the 7-day review, S12, and S13.
- [ ] EN+MR parity on all new strings (R3/R8), real Marathi.
- [ ] `flutter analyze` 0 issues; `flutter test` all green (235 + new). Raw output pasted.
- [ ] **HOLD for Claude review.** No commit/push of app code until Claude writes `APPROVED — cleared to commit & push` (Rule 6). Never push Phase-2 app code to `main` (Rule 7). Brain-only doc commits exempt.

## 7. Explicitly OUT of scope for P2-3 (Rule 9)
Weekly **report + PDF / §3.6 9-section format**, and **Pattern detection T2.4** (same checkpoint failing 3+ days → single Pattern CAP) → **P2-4**. CAP Verify S18 / Close S19 / GM dashboard → **P2-5**. Escalation engine / trigger firing (T3.x) → **Phase 3**. Re-scoring or superseding a daily audit as a result of a spot-check discrepancy → wishlist, not this sprint. Any tempting addition → append to `docs/v2-wishlist.md` and continue.

## 8. Guardrails recap
- R1: T2.3/Day-6 spec is ground truth; contradictions → STOP & flag, never silently choose.
- R2: locked stack; **no schema change without the §3 decision + (if B/C) a v2→v3 migration and Spec §4.4 four-way update landed first.**
- R3/R8: real EN+MR for every new string; never guess Marathi → STOP & ask.
- R5: submitted daily audits immutable; verify is a status transition only.
- R6: review-gated push; HOLD until Claude approves.
- R7: unaffected here (no new Fail capture), but do not weaken the existing photo gate.
- R10: Conventional Commits.
