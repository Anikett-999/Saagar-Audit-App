# Sprint P3-4 — Monthly Reports (S21) + Multi-Week Trend Analytics (fl_chart) — 🟢 PLAN / CLEARED TO BUILD

**Phase**: 3 (Monthly + Escalation + Trends, Weeks 9–11) — **FINAL Phase-3 build**
**Sprint**: P3-4
**Author of plan**: Claude (Team Lead)
**Date**: 2026-09-30
**Branch**: `feature/p3-monthly-reports-trends` off `phase-3` (Rule 7)
**Spec**: SPEC_WORKBOOK §3.7 (report format) + §4.1/§4.5 (trend scoring & the three patterns) + Tier-3 monthly description (L271–289) / `brain/spec/03_S12_S21_AUDITS_CAPS_REPORTS.md` S20–S21 / OVERVIEW.md Phase-3 scope
**Status**: 🟢 **CLEARED TO BUILD.** No schema change (`reports.report_type` already allows `'monthly'`; the 8 JSON payload columns already exist; `fl_chart ^1.2.0` already in the locked stack). No R2 gate. One spec-derivation note + graceful-degradation requirement flagged in §3.

---

## 1. Team-Lead rationale
This is the last brick of Phase 3. P3-1 shipped the **monthly conduct** (Owner-only, Option-C hybrid: 3 strategic spot-checks MC.1/MC.2/MC.3, scored toward 95%+). P2-4 shipped the **weekly report** (S20 list + S21 detail + bilingual PDF) with per-SOP rollup and a 7-day trend block. What is missing — and what P3-4 delivers — is (a) the **monthly report** (S21 monthly view) and (b) the **multi-week trend analytics with charts** that the Tier-3 monthly audit exists to surface. Per Option C (Owner ruling, 2026-09-29), the monthly audit's *own* score is intentionally small (3 spot-checks); its value is **strategic trend reading** — so the monthly report is fundamentally a trend document, and this is where `fl_chart` earns its place in the stack. All of it is **downstream, read-only analytics over data we already persist** (submitted audits + weekly reports) — no change to scoring, conduct, or immutability.

## 2. Grounding — what I verified in code + spec
- **Schema — NO change (verified by grounding pass):** `reports` table (`schema.dart` §4.12) already has `report_type CHECK IN ('weekly','monthly')` and eight free-form JSON blobs (`compliance_table_json`, `trend_block_json`, `findings_json`, `patterns_json`, `caps_opened_json`, `caps_closed_json`, `caps_aged_json`, `escalations_json`) + `headline`, `pdf_local_path`, `read_by_owner_at`. A monthly report reuses all of these as-is. `Report` model already documents "weekly | monthly" and has typed deserializers.
- **`fl_chart ^1.2.0`** is in `pubspec.yaml` (locked stack) with **zero existing usage in `lib/`** — P3-4 is the first chart. No new package (R2-clean).
- **Monthly audits exist & are scored:** Option-C hybrid — `MC.1` recount safe cash (wt2, SOP2, photo-on-fail), `MC.2` recount one display tray (wt2, SOP7, photo-on-fail), `MC.3` audit 15 customer-DB entries (wt1, SOP4). Scored by the existing pure engine toward the 95% (excellent) target. Conduct/submit wired (S05 Owner card, S06/S10/S11/S12/S13). `AuditRepository.findByMonth(monthNumber, year, auditType)` exists.
- **Weekly report already stores what the multi-week series needs:** `generateWeeklyReport` writes `compliance_table_json` with **per-SOP `sop_rows`** and `trend_block_json` with `daily_pcts`/`daily_dates`/`weekly_pct`/`prev_week_pct`/`wow_delta`. So a monthly trend series can be **assembled by reading the last N weekly reports' `compliance_table_json → sop_rows`** — no new per-audit data required.
- **`ReportRepository`** has `generateWeeklyReport`, `getById`, `getByAuditId`, `listReports({reportType, year, month})`, `markReadByOwner`, `updatePdfPath` — but **no `generateMonthlyReport`**.
- **Trend spec (§4.1/§4.5):** 4-week moving average (`avg of past four weekly scores`, computed at week end); "volatility is the finding"; and **three patterns the monthly report must surface**: (1) **slow slide** — 3+ consecutive weeks of negative movement even if above target; (2) **single-SOP decay** — one SOP failing ≥1 checkpoint every week for 4 consecutive weeks while the aggregate stays healthy → **"use the rolling four-week per-SOP graph"**; (3) **day-of-week clustering** — Fri/Sat consistently 3–5 pts below Mon–Thu. `pattern_detection.dart` currently has only `detectWeeklyPatterns` (intra-week) — none of the three multi-week patterns exist yet.
- **S20/S21 screens** live in `lib/ui/screens/reports/` (`reports_list_screen.dart`, `report_detail_screen.dart`); both are currently hardcoded to `report_type='weekly'`. PDF: `lib/services/weekly_report_pdf_service.dart` takes a **generic `Report`** (reusable for monthly).

## 3. ⚠️ Design notes (no gate — flagging, not blocking)
1. **Monthly report is spec-*derived*, not spec-*templated*.** The Workbook formally specs only the weekly 7-section report; there is no "§3.8 monthly report" table. Per Option C + Tier-3 intent, the monthly report = the weekly section skeleton **re-weighted toward trend**: headline (monthly spot-check score + strategic judgment), a **multi-week trend block** (the star of the report), the three detected trend patterns as findings, and the month's CAP-aging + escalation rollup. I am documenting this derivation here so it is a **recorded reconciliation** (R1), consistent with how §3.7 already diverged (code stores 9 payloads vs spec's 7). If the Owner has a specific monthly layout in mind, STOP and ask — but this derivation is faithful and buildable.
2. **Graceful degradation with < 4 weeks of data (REQUIRED).** The 4-week MA and per-SOP decay pattern need 4 weekly reports to exist for the month/window. Early in a store's life that won't hold. Charts and pattern detection **must degrade honestly** — show "insufficient data (need N weeks)" empty states exactly like the weekly report's honest empty CAP states, never crash or fabricate a line. Unit-test the < 4-week path.
3. **MoM delta is a reasonable derivation, not a named spec field.** WoW delta is specced (weekly §2). I'll include a **month-over-month** delta (this month's 4-week-MA vs last month's) as a derived headline stat; flag it as derived, not spec-mandated.

## 4. In-scope for P3-4 (buildable now — no schema change)
1. **Trend analytics module (pure, deterministic, unit-tested FIRST).** A new `lib/domain/trend_analytics.dart` (mirror the `score_engine.dart` / `pattern_detection.dart` pure style):
   - `buildWeeklySeries(List<Report> weeklyReports)` → ordered series of `{weekEnding, overallPct, perSopPct{sopId: pct}}` read from each report's `compliance_table_json`/`trend_block_json`.
   - `fourWeekMovingAverage(series)` → MA series (§4.1).
   - `detectSlowSlide(series)`, `detectSingleSopDecay(series, weeklyResultsPerWeek)`, `detectDayOfWeekClustering(dailyAudits)` → the three §4.5 patterns, each returning a typed finding (or none).
   - All functions total/side-effect-free; **truth-table tests first** with canonical cases (incl. the §4.1 "92/88/94/89 → volatility is the finding" case and the <4-week insufficient-data path).
2. **`ReportRepository.generateMonthlyReport({monthlyAuditId, authorUserId})`** — mirrors `generateWeeklyReport`:
   - Fetch the monthly audit + its `MC.*` results (the spot-check score).
   - Fetch the month's **weekly reports** (via `listReports(reportType:'weekly', year, month)`) → feed the trend module.
   - Fetch CAPs **opened/closed/aged during the month** and **escalations raised during the month** (reuse the weekly report's CAP/escalation query helpers, widened from week to month range).
   - Assemble into the existing JSON blobs: `headline` (monthly score + band + MoM movement + one-line strategic judgment), `compliance_table_json` (the 3 MC spot-checks + a month rollup of weekly overall/per-SOP averages), `trend_block_json` (**multi-week series + 4-week MA + per-SOP series** — the chart's data source), `findings_json` (the detected patterns), `patterns_json`, `caps_opened/closed/aged_json`, `escalations_json`. `report_type='monthly'`. Upsert by `getByAuditId` (idempotent, like weekly).
   - Trigger it on **monthly audit submit** (parallel to the weekly trigger in `review_submit_screen.dart`), non-blocking/post-submit (R5-safe, same pattern as escalation dispatch).
3. **fl_chart trend charts (first chart in the app).** A reusable chart widget (`lib/ui/widgets/trend_chart.dart` or similar):
   - **Overall compliance line** across the month's weeks + the 4-week MA overlay.
   - **Rolling per-SOP line graph** (§4.5 — the graph the spec explicitly names for single-SOP decay), one line per SOP across weeks, with the decaying SOP highlighted.
   - Light theme, bilingual axis/legend labels, honest empty state when < required weeks. Reads only from the monthly report's `trend_block_json` (so the chart is offline and deterministic).
4. **S21 Report Detail — monthly view.** Extend `report_detail_screen.dart` to render a `report_type=='monthly'` report: strategic headline, the trend charts (§4.3), the three-pattern findings, CAP-aging + escalation rollup, signature. Keep the weekly rendering intact (branch on `report.reportType`).
5. **S20 Report List — monthly.** Extend `reports_list_screen.dart`: add the **Monthly** type filter (+ year/month filters per spec S20), list monthly reports alongside weekly, Owner read/unread dot.
6. **PDF export for monthly.** Extend `weekly_report_pdf_service.dart` (it already takes a generic `Report`) — or add a thin monthly variant — to render the monthly report (charts may render as a static image/table in the PDF; a rendered fl_chart-to-image or a compact tabular trend is acceptable — pick the simpler that stays 1–2 pages and bilingual). Confirm approach in the handoff before over-engineering chart-to-image.
7. **Bilingual EN+MR** for every new string (R3/R8), authentic Marathi — STOP and ask if any Marathi is uncertain.

## 5. Out of scope for P3-4 (Rule 9)
- **No new escalation triggers** — the 7-trigger engine is complete (T1–T7 + T6 manual). A declining-trend already fires T7; P3-4 only *visualises* trends, it does not add alerts.
- **No scoring/conduct changes** — monthly scoring (Option C) is done; P3-4 does not touch `score_engine.dart` or the conduct flow.
- **Quarterly (12-week MA) analytics, exports to Excel, cross-store comparison** → not in Phase 3.
- **Real push / Firebase / cloud PDF upload** → Phase 4.

## 6. Guardrails recap
- **R1:** monthly-report layout is a **recorded derivation** from the weekly template + Tier-3 intent (§3.1) — surfaced here, not silently invented; Workbook remains ground truth. Owner may override the layout.
- **R2:** **no schema change** (reports table + JSON blobs already fit; `report_type` allows `'monthly'`); **no new package** (`fl_chart` already locked in). If any structural need appears, STOP and ask.
- **R3/R8:** real EN+MR for all new UI + chart labels; report bodies follow the existing bilingual report convention.
- **R4:** scoring untouched — `score_engine_test.dart` stays green.
- **R5:** report generation only **reads** submitted audits/weekly reports and **inserts/updates** a `reports` row; monthly generation runs **post-submit, non-blocking** so it can never roll back a submitted audit. No mutation of any audit.
- **R6:** review-gated. Antigravity builds → `flutter analyze` + full `flutter test` (score engine + trend truth tables + monthly report + <4-week degradation all green) → pastes raw output → **HOLD**. Claude reviews → `APPROVED — cleared to commit & push`.
- **R7:** `feature/p3-monthly-reports-trends` off `phase-3`; merge to `phase-3` on approval; **`main` stays at `0cb2e55`** until the Phase-3 sign-off merge.
- **R10:** Conventional Commits.

## 7. Build order
1. `lib/domain/trend_analytics.dart` (pure) + **truth-table tests first** (weekly series build, 4-week MA, three §4.5 patterns, volatility case, <4-week insufficient-data path).
2. `ReportRepository.generateMonthlyReport(...)` + month-range CAP/escalation queries + upsert idempotency + tests (assembles all JSON blobs; honest empty states).
3. Wire monthly generation into the monthly-audit post-submit path (non-blocking).
4. `trend_chart.dart` fl_chart widget (overall + per-SOP + MA overlay; bilingual; empty state).
5. S21 detail monthly branch (charts + patterns + rollup) — keep weekly intact.
6. S20 list monthly filter (type/year/month) + read/unread.
7. Monthly PDF export (confirm chart-render approach in handoff first).
8. Bilingual ARB keys; `flutter gen-l10n`.
9. `flutter analyze` + full `flutter test`; paste raw output; **HOLD** for review.

## 8. Immediate next step
Antigravity: cut `feature/p3-monthly-reports-trends` off `phase-3` and build in the §7 order (analytics + tests FIRST). Before building the monthly PDF, **report your intended approach for rendering the trend chart into the PDF** (fl_chart-to-image vs. a compact tabular trend) so I can confirm it stays simple, 1–2 pages, and bilingual. Build tests-first, run `analyze` + full `test`, paste raw output, and HOLD. Do not commit until I write `APPROVED — cleared to commit & push`.

## 9. After P3-4 — Phase-3 sign-off
Once P3-4 is approved and merged to `phase-3`, Phase 3 is feature-complete (monthly foundation, 7-trigger escalation engine, CAP auto-aging, monthly reports + trends). The next step is the **Phase-3 sign-off merge `phase-3` → `main`** (the first `main` update since the Phase-2 sign-off at `0cb2e55`), gated on a full green suite and my review — then **Phase 4** (Firestore cloud mirror + Play Store internal track) begins.
