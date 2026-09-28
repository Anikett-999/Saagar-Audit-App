# Sprint P2-2 — Weekly Audit Conduct Screens (S6–S11 weekly analogues)

**Phase**: 2 (Weekly Audit, Weeks 5–8)
**Sprint**: P2-2 (second sprint of Phase 2)
**Author of plan**: Claude (Team Lead)
**Date set**: 2026-09-27
**Branch**: continue on `phase-2`; cut `feature/p2-weekly-conduct` off `phase-2` (Rule 7 — branches only, never folders).
**Pre-condition (met)**: P2-1 merged to `phase-2` (edd54b5), 228/228 green — `computeWeeklyScore`, `computeCumulativeWeeklyVariance`, SOP9 + 36 weekly checkpoints, v2 migration all in.

---

## 1. Team-Lead rationale
P2-1 proved the weekly *engine + data*. P2-2 puts a face on it: let the GM actually **conduct** a weekly audit over the 36 weekly-only checkpoints and submit it with a real score. The daily conduct screens (S6 Start → S7 Checkpoint → S8 Fail Detail → S9 Photo → S10 Review → S11 Confirm) already exist and the data layer is **already parameterized** by `audit_type` / `frequency` (schema `audits.audit_type`, `checkpoints.frequency`; `checkpoint_repository` filters on `frequency`; `audit_repository.createAudit` takes `auditType`). So this sprint is **reuse-and-parameterize, not rebuild**. Do NOT fork a parallel set of weekly screen files.

## 2. Scope — what Antigravity builds

### 2.1 Entry point (S5 Home / S6 Start)
- Add a "Start Weekly Audit" affordance for GM role (per spec, weekly audit is GM-run). Guard by role — SM sees daily only; GM sees both. Reuse existing role gating.
- S6 Start Audit: when launched in weekly mode, create/resume an `audits` row with `audit_type='weekly'`, `week_number` + `year` set via the **same ISO-week helper `cap_repository` already uses** (R2 — do not add a second week-numbering scheme). One in-progress weekly audit per (store, week) — reuse the existing "resume in-progress" guard that daily uses (`audit_repository` line ~32 dedupe on `audit_date/audit_type`; extend the weekly equivalent keyed on week_number/year).

### 2.2 Checkpoint flow (S7 / S8 / S9) — parameterize by frequency
- S7 Checkpoint list/stepper: load checkpoints with `frequency='weekly'` (36 rows), grouped by SOP in this order: **SOP6 Cash ★, SOP7 Inventory ★, SOP8 Service, SOP9 Operations** (or the spec's stated conduct order if it differs — verify against Workbook Day 3 before finalizing; if it conflicts, STOP and flag R1). Show P/F/NA exactly as daily.
- S8 Fail Detail: finding text (required, ≤200 chars), optional CRO, photo section. **R7 enforced:** Cash (SOP6) and Inventory (SOP7) weekly Fails require ≥1 photo — the seed already sets `requires_photo_on_fail=1` on CW.* and IW.*, so the *existing* S8 logic that reads `checkpoint.requires_photo_on_fail` should already do the right thing. Confirm it does; do not hardcode SOP ids.
- S9 Photo Capture: unchanged — reused as-is.

### 2.3 Review & Submit (S10) — wire in `computeWeeklyScore`
- The weekly review screen must show the **true 124-point weekly score**, not just the 56 weekly-only points. To do that it needs the 7 daily percentages for the audited week:
  - Fetch the 7 daily `audits` rows for `week_number`/`year` with `status IN ('submitted','verified')`; missing day → push `0.0` (T2.2). This is a **headless data fetch**, not the interactive 7-day spot-check UI (that is P2-3).
  - Call `computeWeeklyScore(dailyPcts, weeklyMarks)` → show compliance %, band, `total_raw/total_max`, and a per-SOP breakdown. Show the daily-average contribution (/68) and weekly-only (/56) as two sub-lines so the GM understands the split.
  - Also surface `computeCumulativeWeeklyVariance` for CW.7 (net ₹ + breach flag) as a read-only line if the 7 daily cash variances are available; if not available this sprint, show "—" and defer — do not block submit on it.
- Submit behaviour mirrors daily S10: validate mandatory photos on Cash/Inventory Fails; write `audits` row (`status='submitted'`, scores, band, counts); **R5 immutability** once submitted. CAP creation for weekly Fails reuses the daily CAP flow (S15) — deferred-CAP option identical to daily.
- **OUT of P2-2:** the escalation engine run on submit (Phase 3) — leave the hook but do not implement triggers.

### 2.4 Confirmation (S11)
- Reuse S11 Submitted Confirmation; just reflect "Weekly Audit — Week N, [year]".

### 2.5 History (S12) — un-hardcode the daily filter
- `audit_repository` line ~228 hardcodes `audit_type = 'daily'` in the history query. Generalize so weekly audits also appear in S12 (filter/tab by type, or show both). Small change — do it here so submitted weekly audits are visible. S13 Audit Detail already renders `audit_type`; confirm it renders a weekly audit read-only correctly.

## 3. Data model / R2 guardrail
No schema changes expected — `audits` already has `audit_type`, `week_number`, `year`. If you believe a column is needed, **STOP and ask Claude** (R2, no silent schema drift). No new libs.

## 4. Tests — must be GREEN to close (Rule 5 + R4)
- Widget/controller test: starting a weekly audit loads exactly 36 `frequency='weekly'` checkpoints, grouped by the 4 SOPs (10/8/6/12).
- S8: a Cash (CW.*) or Inventory (IW.*) Fail with no photo blocks submit; a SOP9/SOP8 Fail does not require a photo.
- S10 integration: given 7 seeded daily audits + weekly marks matching the T2.1 fixture, the review screen's computed score equals **84.5% Poor** (reuse the T2.1 numbers — engine already covered by unit tests, here assert the *wiring* pulls daily pcts and feeds the engine correctly, incl. a missing-day→0 case = T2.2).
- Regression (Rule 5): all **228** existing tests stay green; canonical daily `81/90 = 90.0%` and weekly `104.8/124 = 84.5%` unit tests untouched and green.
- Paste raw `flutter analyze` + `flutter test` output into `SESSION_HANDOFF.md`.

## 5. Definition of Done for P2-2
- [ ] GM can start → conduct (36 weekly checkpoints) → review → submit a weekly audit end-to-end on device.
- [ ] Review screen shows the real 124-pt weekly score via `computeWeeklyScore` (daily-avg pulled headlessly; missing day = 0).
- [ ] R7 mandatory-photo enforced on Cash/Inventory weekly Fails via the data flag (not hardcoded ids).
- [ ] Submitted weekly audits appear in S12 history and render read-only in S13.
- [ ] `flutter analyze` 0 issues; `flutter test` all green (228 + new). Raw output pasted.
- [ ] **HOLD for Claude review.** No commit/push of app code until Claude writes `APPROVED — cleared to commit & push` (Rule 6). Brain-only doc commits exempt.

## 6. Explicitly OUT of scope for P2-2 (Rule 9)
Interactive **7-day daily review + spot-check** UI where GM opens each daily audit and verifies against photos/registers, plus GM signature (**P2-3**). Weekly **report + PDF / §3.6 9-section format + Pattern detection T2.4** (**P2-4**). CAP Verify S18 / Close S19 / GM dashboard (**P2-5**). Escalation engine / trigger firing (**Phase 3**). Any tempting addition → append to `docs/v2-wishlist.md` and continue.

## 7. Open decision I've already made (so Antigravity isn't blocked)
Weekly review shows the **full 124-pt score** (pull daily audits headlessly), rather than only the 56 weekly-only points. Rationale: a weekly audit's headline number *is* the combined score in Workbook §5.2 / T2.1; showing only 56 would misrepresent it and duplicate rework in P2-4. The interactive spot-check that lets the GM *challenge* those daily scores stays in P2-3. If on-device this proves to need a schema touch, STOP and ask.
