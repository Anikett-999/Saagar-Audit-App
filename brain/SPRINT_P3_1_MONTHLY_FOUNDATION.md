# Sprint P3-1 — Monthly Audit Foundation (Phase 3 kickoff) — ✅ RESOLVED & BUILT (Option C Hybrid)

**Phase**: 3 (Monthly + Escalation + Trends, Weeks 9–11)
**Sprint**: P3-1 (first sprint of Phase 3)
**Author of plan**: Claude (Team Lead), Implemented by Antigravity
**Date**: 2026-09-29
**Branch**: `feature/p3-monthly-foundation` off `phase-3` (Rule 7)
**Status**: ✅ **BUILT & TESTED.** Owner selected **Option C (Hybrid)**. 3 strategic spot-checks seeded (`MC.1`, `MC.2`, `MC.3`, wt total 5), conduct loop wired (S05/S06/S07/S08/S10/S11/S12/S13), role-gated to Owner, 100% authentic Marathi parity. Analyze clean: 0 issues. Test suite: **285/285 green**. Holding for Claude code review per Rule #6.

---

## 1. Team-Lead rationale
Phase 2 completed the daily→weekly verification chain. Phase 3 adds the Owner's tier (Tier 3 monthly), the escalation engine, and trend analytics. P3-1 is the **foundation**: it should let the Owner *conduct and submit a monthly audit*. But before I hand Antigravity a build spec, I have to resolve a genuine contradiction between our two source docs about what a monthly audit *is* — because the two readings produce completely different apps, and R1 forbids me from silently choosing.

## 2. Grounding — what I verified in code + spec
- **Schema needs NO change for the audit record:** `audits.audit_type` CHECK already allows `'monthly'`; `month_number` column exists; `reports.report_type` CHECK already allows `'monthly'`. (Verified in `lib/data/db/schema.dart`.)
- **No monthly checkpoints exist anywhere yet:** `assets/seed/checkpoints.json` has exactly **68 daily + 36 weekly = 104** rows, zero monthly. (Verified.)
- **Monthly conduct is Owner-only**, "first Sunday of each month," Home tile "Start Monthly Audit" (SPEC_APP L271, L1083, permission matrix L300 `Run monthly audit — — ✓`).
- **R5 immutability** applies to monthly audits exactly as daily/weekly (SPEC_APP L335).

## 3. ⛔ BLOCKING R1 CONTRADICTION — the monthly-audit *model* (Owner must rule)
Our two source docs disagree, and neither can be silently overridden:

- **SPEC_WORKBOOK (ground truth, L271–279):** "The Tier 3 audit … **does not repeat the operational checkpoints from Tiers 1 and 2.** Instead it **reads the trend** (are daily scores climbing/sliding? is one SOP repeatedly failing across weeks? are last month's CAPs closed or quietly aged? patterns by day / CRO / brand?) and conducts a **small number of independent spot-checks** — recount safe cash, recount one display tray, recount 15 customer-DB entries — to verify the GM's honesty. Target **95%+ (strategic — qualitative)**." (Quickref L6325 also tags it "strategic — qualitative.")
- **SPEC_APP (implementation DoD, L2734 / L493 / L3483):** "Monthly audit **checkpoints added to seed JSON**. Monthly audit **screens (analogue to weekly)**. … monthly has **its own set** (defined in Phase 3)."

**The conflict:** SPEC_APP implies monthly = a distinct *checkpoint-scored* audit built like the weekly one. The Workbook explicitly says monthly is **not** a repeat of operational checkpoints — it's a **trend-reading + qualitative + small-spot-check** instrument. Per R1, the Workbook wins where they conflict, but "95% qualitative" is not directly computable, and **the concrete monthly items are not enumerated in either doc or the seed** — so I cannot design a scoring engine or seed a checkpoint set without the Owner defining the instrument.

### Options I'm putting to the Owner
- **Option A — Trend-review + qualitative spot-checks (most literal to Workbook).** Monthly audit = a guided Owner review: (i) trend panel (daily/weekly trajectory, repeated-SOP failures, CAP-aging) + (ii) the three fixed independent spot-checks (safe-cash recount, one display-tray recount, 15 customer-DB entries), each Pass/Fail with a note. "95%" is a **qualitative assessment/target**, not a fresh 100-point tally. No new operational checkpoint seed set.
- **Option B — Distinct scored checkpoint set (literal to SPEC_APP DoD).** Monthly = its own seeded checkpoint list scored like weekly. **Requires the Workbook's monthly checkpoint definitions, which do not exist** — they'd have to be authored and Spec-updated first (§17.1 four-way). This also contradicts the Workbook's "does not repeat operational checkpoints."
- **Option C — Hybrid (my recommendation).** The Workbook's three spot-checks become a **small point-scored checklist** (so the audit yields a real, gate-able compliance number toward the 95% target), wrapped with the trend panel + last-month CAP-aging review as read-only strategic context. Faithful to the Workbook's *content*, and buildable/testable like our existing scoring engine. If the Owner wants the score purely qualitative, we fall back to Option A.

**Second gate regardless of A/B/C:** the exact monthly spot-check/checkpoint items + their scoring weights must be **sourced from the Workbook and committed to `brain/` + seed JSON before any UI is built** (Spec-Reading Protocol: "do not design against an unread spec"; §17.1: not-in-Spec ⇒ add to Spec first). If the Workbook's monthly detail lives only in the original `.docx`, Antigravity converts that subsection to markdown under `brain/` first.

## 4. Provisional scope (ONLY valid once §3 is resolved — do not build yet)
Assuming Option A or C, P3-1 would deliver:
- **Monthly conduct flow**, Owner-only, reusing the existing conduct scaffolding parameterized for `audit_type='monthly'` (do NOT fork a second conduct engine; extend the daily/weekly one). Sets `month_number`, `week_number` (first week), `year`.
- **Monthly scoring** per the resolved model (pure, unit-tested; if C, mirror `computeWeeklyScore` structure with the monthly weights).
- **Seed** the monthly items into `checkpoints.json` (`frequency:'monthly'`) from the Workbook-sourced list.
- **Home tile** "Start Monthly Audit" for Owner, gated to the first Sunday/week of the month (spec L1083).
- **Bilingual EN+MR** on every new string (R3/R8), authentic Marathi.
- **R5:** submitted monthly audits immutable; conduct writes a new audit row, never mutates daily/weekly rows.

## 5. Out of scope for P3-1 (Rule 9)
Escalation engine / 7 triggers → **P3-2**. CAP auto-aging job → **P3-3**. Monthly **reports (S21 monthly view) + trend charts (fl_chart)** → **P3-4** (P3-1 only *reads* trend data for the audit context; it does not build the analytics dashboard). WhatsApp/notifications → P3-2. Firebase → Phase 4.

## 6. Guardrails recap
- **R1:** the §3 contradiction is resolved by the Owner in writing before any build; Workbook is ground truth; I will not silently pick a model.
- **R2:** `audits`/`reports` need no schema change; adding monthly checkpoints to seed JSON is a **content** change that must be Workbook-sourced (not invented) — if it needs a checkpoints/scoring structural change, STOP and ask (§4.4 four-way).
- **R3/R8:** real EN+MR for every new string; never guess Marathi → STOP & ask.
- **R4/R5:** monthly scoring matches the resolved spec model exactly; submitted audits immutable.
- **R6:** review-gated push; HOLD until Claude approves. **R7:** work on `feature/p3-monthly-foundation` off `phase-3`; never push Phase-3 app code to `main` until Phase-3 sign-off.
- **R10:** Conventional Commits.

## 7. Immediate next step
This is an **Owner decision**, not an Antigravity task. Claude is raising the §3 question to the Owner now. Once the Owner picks the model (A/B/C), Claude will: (1) record the ruling + reconcile SPEC_APP↔Workbook wording in `brain/`, (2) direct Antigravity to source/commit the monthly item list from the Workbook, then (3) finalize this plan's §4 into a buildable spec. **No monthly code until then.**
