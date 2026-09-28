# Sprint P2-4 — Weekly Report (S20/S21) + §3.6 9-Section Format + PDF + Pattern Detection (T2.4)

**Phase**: 2 (Weekly Audit, Weeks 5–8)
**Sprint**: P2-4 (fourth sprint of Phase 2)
**Author of plan**: Claude (Team Lead)
**Date set**: 2026-09-28
**Branch**: continue on `phase-2`; cut `feature/p2-weekly-report` off `phase-2` (Rule 7 — branches only, never folders).
**Pre-condition (met)**: P2-3 merged to `phase-2` (`e75047b`, HEAD `c70daa6`), 243/243 green per Antigravity's device run, `main` untouched at `5b9408b`. Weekly audit can be conducted, scored (124-pt), and its 7 daily audits GM spot-checked/verified.

---

## 1. Team-Lead rationale
P2-1→P2-3 built the weekly engine, the conduct screens, and the interactive 7-day spot-check. P2-4 produces the **artifact the Owner actually consumes**: a one-page weekly report in the Workbook **Day 3 §3.6 nine-section format**, listed in S20 and read in S21, exportable to PDF. The new *logic* in this sprint is **pattern detection (T2.4)** — spotting a checkpoint that failed on 3+ days across the week and surfacing it as a single "pattern" (with a single suggested Pattern CAP, never N separate ones). Report *generation* is assembly of data we already persist; the discipline here is faithful §3.6 structure, honest empty-states for sections whose source engines land in later phases, and a clean, unit-tested pattern engine.

## 2. Grounding in spec (R1 — Workbook is ground truth)
- **S20 Reports List** (SPEC_APP.md ~L1679): list of weekly reports; each item shows **week-ending date, compliance %, band, headline**; filter by type/year/month; **Owner-only** read-dot (green read / gray unread).
- **S21 Report Detail** (~L1693): read-view **matching Workbook Day 3 §3.6 exactly**. Sections: **headline, compliance table, trend block, findings, patterns, CAPs, escalations, signature**. PDF export button at bottom. "Mark as Read" sets `reports.read_by_owner_at` when viewer is Owner.
- **§3.6 / DoD** (~L2710, L3896): "Weekly report PDF is **1 page** and follows the **9-section format** from Workbook 3.6. PDF export readable."
- **T2.4 Pattern detection** (~L3050): seed 5 daily audits where checkpoint **1.4** fails on days 1,2,3 → run weekly audit → EXPECTED: pattern section includes **"Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed) — pattern"**, and **a single Pattern CAP is auto-suggested, not three separate CAPs.**

The 9 sections map 1:1 to the existing `reports` table columns (§2.3 below): headline · compliance_table · trend_block · findings · patterns · caps_opened · caps_closed · caps_aged · escalations. S21's narrative groups the three CAP buckets under "CAPs" and adds "signature" — render signature from the report's `author_user_id` + submit timestamp (Option A signature-of-record, consistent with P2-3).

## 3. Data model / libs — NO changes needed (R2 guardrail)
I inspected the schema and pubspec:
- **`reports` table already exists** with exactly the 9-section columns (`headline`, `compliance_table_json`, `trend_block_json`, `findings_json`, `patterns_json`, `caps_opened_json`, `caps_closed_json`, `caps_aged_json`, `escalations_json`) plus `author_user_id`, `submitted_at`, `read_by_owner_at`, `pdf_local_path`, `pdf_cloud_url`. **No migration.**
- **`pdf: ^3.10.7` and `printing: ^5.11.1` are already in `pubspec.yaml`.** Use these. **No new libs.**
- If you believe a column or lib is needed, **STOP and ask Claude** (R2 — no silent schema/stack drift; §4.4 four-way applies to any checkpoint/SOP change).

## 4. Scope — what Antigravity builds

### 4.1 Pattern-detection engine (pure, unit-tested = T2.4) — build FIRST
- New pure function in `lib/domain/` (e.g. `pattern_detection.dart`), no I/O. Input: the week's 7 daily audits + their `audit_results` (or a distilled `Map<checkpointId, List<DateTime failedDates>>`). Output: `List<PatternFinding>` where a checkpoint has result `'F'` on **≥3 distinct days** in the week.
- Each `PatternFinding` carries: `checkpointId`, checkpoint code (e.g. "1.4"), count of fail-days, and the **weekday names in order** (Mon, Tue, Wed…). Reuse `isoWeekDates`/weekday derivation — do NOT invent a second weekday scheme.
- Threshold is **3+** (strict `>=3`). A checkpoint failing on exactly 2 days is NOT a pattern.
- **Single-CAP rule (load-bearing, T2.4):** one `PatternFinding` per clustered checkpoint → **one** suggested Pattern CAP, never one-per-day. When wiring CAP suggestion (see 4.4), dedupe by `checkpointId` so three daily Fails of 1.4 yield exactly one Pattern CAP.

### 4.2 Report generation (assemble → persist a `reports` row)
- On weekly-audit submit (or a "Generate Report" action from S10/S12 for a submitted weekly audit — pick the smaller wiring; a submit-time hook is cleanest, but do NOT block submit if generation fails — log and allow regenerate). Build the 9 section payloads as JSON and insert a `reports` row (`report_type='weekly'`, `audit_id`, `author_user_id`, `submitted_at`).
- Section data sources (populate what Phase 2 has; **honest empty-state** for the rest — do NOT fabricate):
  - **headline** — one-line summary: compliance %, band, week-ending date (derive week-ending Sunday from `isoWeekDates`).
  - **compliance_table** — the 124-pt breakdown already computed by `computeWeeklyScore`: daily-avg contribution (/68), weekly-only (/56), per-SOP rows, total_raw/total_max, band.
  - **trend_block** — the 7 daily compliance %s (with missing-day = 0, same rule as the rollup) + weekly total; a small week-over-week delta only if a prior week's report exists, else "—".
  - **findings** — the weekly audit's Fail checkpoints (finding text, SOP, photo count).
  - **patterns** — from 4.1. Empty list → "No cross-day patterns detected this week."
  - **caps_opened** — CAPs created this week (weekly Fails + pattern CAP). If CAP creation is not yet wired for weekly (S15 daily flow reuse), populate from what exists and mark the rest for P2-5; do NOT block.
  - **caps_closed / caps_aged** — CAP verify/close lands in **P2-5**; render an honest "—/none this phase" empty-state now. Do NOT fake.
  - **escalations** — escalation engine is **Phase 3**; render honest empty-state.
  - **signature** — `author_user_id` (GM) + submit timestamp (Option A signature-of-record).
- Repository: add report CRUD to a `report_repository.dart` (create, `getByAuditId`, `listReports(filter)`, `markReadByOwner`). Mirror existing repository patterns; guarded updates.

### 4.3 S20 Reports List + S21 Report Detail (UI)
- **S20**: list weekly reports (week-ending date, compliance %, band chip, headline). Filter by type/year/month. **Owner-only** read-dot (green if `read_by_owner_at != null`, else gray). Role: GM/OWNER see the list; the read-dot column is Owner-relevant. Reuse existing list/card patterns.
- **S21**: render all **9 sections** in §3.6 order, read-only. "Mark as Read" button updates `read_by_owner_at` **only when viewer is Owner** (guard by role). "Export PDF" button at bottom.
- EN+MR parity on every new string (R3/R8) — real Marathi, never guess; STOP and ask if unknown.

### 4.4 PDF export (§3.6, one page)
- Use the existing `pdf` + `printing` packages. Generate a **1-page** weekly report matching the §3.6 nine-section layout; save to `reports.pdf_local_path`; offer share/print via `printing`. Bilingual content should render (ensure a font that supports Devanagari is bundled/loaded — if the default PDF font cannot render Marathi, load a Unicode/Noto Devanagari font asset; if that requires a new asset, that's fine (asset, not a lib/schema change) but note it in the handoff).
- **Pattern CAP suggestion**: surface the single suggested Pattern CAP in the report (and, if the weekly CAP-creation flow exists, create exactly one caps row per pattern). Full CAP **verify/close** is **P2-5** — do not build it here.

## 5. Tests — must be GREEN to close (Rule 5 + R4)
- **T2.4 (canonical)**: seed a week with daily audits where checkpoint **1.4** is `F` on days 1,2,3 → pattern engine returns exactly **one** `PatternFinding` for 1.4 with count 3 and weekdays [Mon, Tue, Wed]; a checkpoint failing on 2 days yields **no** pattern; the suggested-CAP mapping yields **one** CAP for the cluster, not three.
- **Report generation**: given a submitted weekly audit + 7 dailies, a `reports` row is created with all 9 JSON columns populated (or honest-empty for later-phase sections); headline/compliance-table reflect the true 124-pt numbers (reuse T2.1 → 84.5% Poor).
- **S20/S21 widget**: list renders week-ending/compliance/band/headline; Owner read-dot toggles on "Mark as Read"; SM cannot mark read; S21 renders all 9 section headers.
- **PDF**: export produces a non-empty PDF file at `pdf_local_path` (smoke test); Marathi glyphs render (at least assert no exception + file size > 0).
- **Regression (Rule 5)**: all existing tests stay green (243 + new). Canonical daily `81/90=90.0%` and weekly `104.8/124=84.5%` untouched.
- Paste raw `flutter analyze` + `flutter test` into `SESSION_HANDOFF.md`.

## 6. Definition of Done for P2-4
- [ ] Pattern-detection engine implemented as a pure, unit-tested function; T2.4 passes exactly (single pattern, single suggested CAP, correct weekday names).
- [ ] Weekly report generated and persisted to the existing `reports` table (no schema change); 9 sections populated with real data or honest empty-state for later-phase sections.
- [ ] S20 Reports List + S21 Report Detail render the §3.6 9-section format; Owner read-dot + "Mark as Read" (Owner-only) work.
- [ ] 1-page PDF export via existing `pdf`/`printing`; Marathi renders; saved to `pdf_local_path`.
- [ ] EN+MR parity on all new strings (R3/R8), real Marathi.
- [ ] `flutter analyze` 0 issues; `flutter test` all green (243 + new). Raw output pasted.
- [ ] **HOLD for Claude review.** No commit/push of app code until Claude writes `APPROVED — cleared to commit & push` (Rule 6). Never push Phase-2 app code to `main` (Rule 7). Brain-only doc commits exempt.

## 7. Explicitly OUT of scope for P2-4 (Rule 9)
CAP **Verify (S18) / Close (S19)** and GM dashboard → **P2-5**. **Escalation engine / trigger firing** (T3.x) → **Phase 3** (report's escalations section renders empty-state now). **Monthly** reports → Phase 3. Firebase/cloud PDF upload (`pdf_cloud_url`) → Phase 4. Do not re-score or mutate submitted audits (R5). Any tempting addition → append to `docs/v2-wishlist.md` and continue.

## 8. Guardrails recap
- R1: §3.6 report format + T2.4 are ground truth; contradictions → STOP & flag, never silently choose.
- R2: **no schema change** (reports table already fits) and **no new libs** (pdf/printing already present) — STOP & ask if you think otherwise.
- R3/R8: real EN+MR for every new string; never guess Marathi → STOP & ask.
- R5: submitted audits immutable; report generation reads, never mutates, audit rows.
- R6: review-gated push; HOLD until Claude approves.
- R10: Conventional Commits.

## 9. Open decision I've already made (so Antigravity isn't blocked)
Sections whose source engines land in later phases (**caps_closed/aged** partially, **escalations** fully) render an **honest empty-state** ("none this phase / —") in P2-4 rather than being faked or omitted — the 9-section skeleton is complete and future phases fill them in. Rationale: §3.6 requires the 9-section *structure* now; the data for CAP-lifecycle and escalations legitimately does not exist until P2-5/Phase-3. If on-device this proves to need a schema touch, STOP and ask.
