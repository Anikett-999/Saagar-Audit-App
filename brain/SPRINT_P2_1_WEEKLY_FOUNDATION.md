# Sprint P2-1 — Weekly Audit Foundation (score engine + data model + seed)

**Phase**: 2 (Weekly Audit, Weeks 5–8)
**Sprint**: P2-1 (first sprint of Phase 2)
**Author of plan**: Claude (Team Lead)
**Date set**: 2026-09-26
**Branch**: `phase-2` off `main`, feature branch `feature/p2-weekly-score-engine` off `phase-2` (Rule 7 — branches only, never folders)
**Pre-condition (met)**: flatten-to-root merged to `main` (e7222fa) and CI 100% green — confirmed by Sagar 2026-09-26.

---

## 1. Why this sprint is first (Team-Lead rationale)
Phase 1 locked the daily score engine and its canonical invariant (81/90 = 90.0% Good) **before** any UI. We repeat that discipline for Phase 2: the highest-risk, spec-pinned pieces are the weekly math (`computeWeeklyScore`, §6.5) and the canonical 84.5% Poor invariant (Workbook §5.2 / Spec §6.6 / test T2.1). Prove the engine and the data model first; every later UI sprint (conduct screens, 7-day review, report, CAP verify/close) then builds on a green foundation.

**No screens ship in P2-1.** Pure data + pure functions + tests only.

## 2. Scope — what Antigravity builds

### 2.1 Data model (reuse, do not drift)
- Weekly audits reuse the existing `audits` / `audit_results` tables with `audit_type='weekly'`, `week_number`, `year`. No new columns beyond what already exists in `lib/data/db/schema.dart` unless §5/§6.5 forces it — if you think a column is needed, **STOP and ask Claude** (R2: no silent schema drift).
- `reports` table already exists in schema (row 12). No report generation this sprint — leave it untouched; P2-4 owns it.
- Confirm `week_number` derivation uses the same ISO-week helper already used by `cap_repository` (CAP IDs use ISO week). Reuse it; do not add a second week-numbering scheme.

### 2.2 Seed — 36 weekly-only checkpoints
Add 36 rows to `assets/seed/checkpoints.json` with `frequency='weekly'`, verified 1:1 against Workbook Day 3 and QuickRef Card 2:
- **Operations Weekly** (O.1–O.10): raw 10, weight 1× → 10 wt, sop grouping per spec.
- **Cash Weekly ★** (CW.1–CW.8): raw 8, weight 2× → 16 wt.
- **Reporting & Service Weekly** (RS.1–RS.6): raw 6, weight 1× → 6 wt.
- **Inventory Weekly ★** (IW.1–IW.12): raw 12, weight 2× → 24 wt.
- Weekly-only weighted total = **56**. (Daily-average contributes the other 68 → 124 max.)
- Set `allows_na`, `requires_photo_on_fail` per each checkpoint's nature; Cash/Inventory weekly Fails follow the same mandatory-photo rule as daily Cash/Inventory (R7) — confirm the exact list with Claude before finalizing.

> **R3 HARD STOP — Marathi is required at insertion, no placeholders.**
> The existing daily seed rows still carry English text in `text_mr` (e.g. 1.1 "Uniform clean and well-fitted" duplicated). Do **NOT** replicate that placeholder pattern for the 36 weekly rows. Every new weekly checkpoint needs real EN **and** MR (`text_en`/`text_mr`, `evidence_en`/`evidence_mr`) at the moment the row is added. If you do not have Sagar's Marathi for any weekly checkpoint, **STOP and ask** — do not guess, do not English-duplicate. (Separately flagged to Sagar: the pre-existing daily `text_mr` placeholders are a Phase-1 debt to clean up; tracked, not part of P2-1.)

### 2.3 Score engine — add to `lib/domain/score_engine.dart` (pure, no IO)
Implement per Spec §6.5–§6.7. Keep the existing daily engine untouched.

**`computeWeeklyScore`** (§6.5):
1. Daily-average contribution (out of 68):
   - `week_dates` = the 7 dates of the audited week.
   - For each date: if a `daily` audit exists with `status IN ('submitted','verified')`, push its `compliance_pct`; **else push 0.0** (missing day = 0%, T2.2).
   - `avg_daily = sum(daily_pcts) / 7`
   - `daily_contribution = round1(avg_daily / 100 * 68)`  ← round to 1 decimal HERE (gives 61.8, not 61.83).
2. Weekly-only checkpoints (max 56):
   - `weekly_raw = sum(weighted_points where result='P')`
   - `weekly_max = sum(weight where result IN ('P','F'))`  ← NA excluded from max (matches daily engine).
3. Combine:
   - `total_raw = daily_contribution + weekly_raw`
   - `total_max = 68 + weekly_max`  (124 if no weekly NAs)
   - `compliance_pct = round1(total_raw / total_max * 100)`
   - `band = bandFromCompliance(compliance_pct)`  ← reuse existing strict-cutoff function.

**Rounding order is load-bearing.** Round the daily contribution to 1 decimal first, then combine, then round the final pct to 1 decimal. Any other order can produce 84.4/84.6 and fail T2.1.

**`computeCumulativeWeeklyVariance`** (CW.7, §6.7): signed sum of daily cash variances across the 7 dates (+ over, − short); flag when the cumulative magnitude breaches the CW.7 threshold. Pure function taking the 7 daily variance values; the trigger/escalation side is Phase 3 — this sprint only computes and returns the number + a boolean breach flag.

Keep the engine DB-free: pass in the 7 daily percentages and the list of weekly `CheckpointMark`s (reuse the existing `CheckpointMark`/`Verdict` types). The repository layer wires DB → engine → `audits` row, mirroring how daily submission already works.

## 3. Tests — must be GREEN to close the sprint (Rule 5 + R4)
Add `test/weekly_score_engine_test.dart`:
- **T2.1 (canonical, EXACT):** daily pcts `[92.2, 91.1, 90.0, 88.8, 93.3, 89.7, 91.4]` + weekly-only Ops 7/10, Cash 10/16, R&S 4/6, Inv 22/24 → `daily_contribution=61.8`, `total_raw=104.8`, `total_max=124`, `compliance_pct=84.5`, `band=Band.poor`. Must match to the decimal.
- **T2.2 (missing day = 0%):** 6 days @ 90%, day 3 absent → `avg=(90*6+0)/7=77.1%`, `daily_contribution=52.4`.
- **Boundary tests:** assert the 84.4 / 84.5 / 84.6 rounding boundary behaves per `round1`; assert NA weekly checkpoints are excluded from `total_max`.
- **CW.7:** cumulative variance sums signed values correctly and sets the breach flag at the threshold.

Regression (Rule 5): `flutter test test/score_engine_test.dart` (daily 81/90 = 90.0% invariant) stays green, and **all 214 Phase-1 tests still pass**.

## 4. Definition of Done for P2-1
- [ ] `flutter analyze` → 0 issues (paste raw output).
- [ ] `flutter test` → all Phase-1 (214) + new weekly tests green (paste raw output).
- [ ] `flutter test test/weekly_score_engine_test.dart` green; T2.1 shows 84.5% Poor exactly (paste raw).
- [ ] Canonical daily invariant still green (paste raw).
- [ ] 36 weekly checkpoints in seed with real EN+MR (or open STOP-and-ask items listed).
- [ ] **HOLD for Claude review.** Do NOT commit/push app code until Claude writes `APPROVED — cleared to commit & push` in `SESSION_HANDOFF.md` (Rule 6). Brain-only doc commits are exempt.

## 5. Explicitly OUT of scope for P2-1 (Rule 9)
Weekly conduct UI (P2-2), 7-day review + spot check (P2-3), weekly report + PDF / §3.6 9-section format + Pattern detection T2.4 (P2-4), CAP Verify S18 / Close S19 / GM dashboard (P2-5), and the escalation engine (Phase 3). Any tempting addition → append to `docs/v2-wishlist.md` and continue.
