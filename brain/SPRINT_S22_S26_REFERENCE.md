# Sprint Plan — S22–S26 Reference Data Tab

**Author**: Claude — Senior Developer & Team Lead
**Date**: 2026-09-24
**Spec source**: `brain/spec/04_S22_S26_REFERENCE_DATA.md` (Spec §5 S22–S26 + §11 content)
**Status**: ACTIVE — supersedes the completed `SPRINT_S12_S17_CAPS.md`.

## 1. Objective
Ship the offline Reference tab: the app's built-in copy of Workbook Appendices A.4–A.7, so the SM can reach the rating scale, escalation triggers, evidence rules, and glossary at 9:15 PM when the paper cards are gone. Five screens (S22 index + S23–S26 content), all offline, all EN/MR.

## 2. Locked design decisions (do not deviate without Claude sign-off)
1. **Content lives in bundled JSON assets, NOT SQLite and NOT ARB.** Spec §11 is explicit: reference content ships as JSON so it can be updated in a future APK without code changes. Create under `assets/reference/`:
   - `rating_scale.json` — 5 bands + 3 tier targets + critical reminder.
   - `escalation_triggers.json` — 7 triggers + 4-part message format + 3 worked examples.
   - `evidence.json` — 8 strong + 8 weak types + bottom warning.
   - `glossary.json` — array of `{en, mr, meaning_en, meaning_mr}` (65 rows).
   Each content object carries BOTH languages inline (e.g. `{"band_en": "...", "band_mr": "..."}`), selected at render time by current locale. Register the folder in `pubspec.yaml` assets.
2. **Screen chrome (titles, section headers, search placeholder, empty states) goes through ARB** with strict 1:1 `app_en.arb`/`app_mr.arb` parity (Rule #8). Reference *content* does not go through ARB — it is data. Keep the parity check green by only adding chrome keys.
3. **S23 band ranges are a mirror of the score engine, not a new source of truth.** The rating table MUST read ≥95 Excellent / ≥90 Good / ≥85 Fair / ≥80 Poor / <80 Critical, matching `domain/score_engine.dart` and `bandColor`. If the JSON ever disagrees with the engine, the engine wins — flag it, don't fork the cutoffs. Tier 1 daily = 90%+, 81/90 (must not contradict the canonical `81/90 = 90.0% Good` invariant).
4. **Read-only.** No writes anywhere in this tab. No DB access at all except none is needed — pure asset reads.
5. **Reuse existing patterns**: `AppColors`, card/table styling from S13, `LanguageToggleButton` in each AppBar, `Wrap`/`Expanded` overflow discipline (Marathi strings are long — tables must not overflow on ~360dp).
6. **Entry point**: wire a "Reference" tile on S05 Home (mirror the existing Audit History / CAP List tiles) routing to `/reference`. Confirm placement in the S05 build before adding.

## 3. Data layer
- `lib/data/reference_repository.dart` (or `reference_service.dart`) — loads + caches the four JSON assets via `rootBundle.loadString` + `json.decode`, exposes typed models:
  `RatingScale`, `EscalationTriggers`, `EvidenceGuide`, `List<GlossaryEntry>`.
- Glossary search helper: `filter(query)` — case-insensitive `contains` across en, mr, meaning_en, meaning_mr; empty query returns all 65; accepts Latin + Devanagari.
- Models under `lib/data/models/reference/`.

## 4. Routes (add to `lib/app.dart`, all auth-guarded like existing routes)
- `/reference` → `s22_reference_index` → `ReferenceIndexScreen`
- `/reference/rating` → `s23_rating_scale`
- `/reference/escalation` → `s24_escalation_triggers`
- `/reference/evidence` → `s25_evidence`
- `/reference/glossary` → `s26_glossary`

## 5. Step breakdown (each step = one reviewable unit under Rule 6)
Cadence is unchanged from the CAPs sprint: build → `flutter analyze` + `flutter test` → paste RAW output into `SESSION_HANDOFF.md` → **HOLD** → Claude reads the actual code and writes `APPROVED — cleared to commit & push` → Antigravity commits + pushes → pastes git record.

- **Step 1 — Reference data layer + assets.** Author the four JSON files with full A.4–A.7 content (both languages), register in pubspec, build the repository + models + glossary search. Unit tests: all four assets parse; glossary has exactly 65 rows; search filters correctly (EN term, MR term, meaning, empty=all, Devanagari input). No UI yet.
- **Step 2 — S22 Reference Index + routing + Home entry point.** 4 cards → S23–S26; wire all 5 routes; add the Home tile. Widget tests: 4 cards render, each navigates, Marathi parity.
- **Step 3 — S23 Rating Scale.** 5-band color-coded table + tier targets table + critical reminder banner. Assert band ranges match the engine.
- **Step 4 — S24 Escalation Triggers.** 7-trigger table + 4-part message format + 3 examples.
- **Step 5 — S25 Evidence.** Strong vs weak two-column table (8/8) + bottom warning.
- **Step 6 — S26 Glossary.** 65-row table + live search box (case-insensitive, EN/MR/meaning, Latin+Devanagari). Widget tests for the filter.

(S23 and S25 are static render-only; if Antigravity wants to batch Steps 3+5 into one review unit that is acceptable — propose it in the handoff first. S26 stays its own step because of the search logic.)

## 6. Definition of done (sprint)
All five screens built, routed, reachable from Home, EN/MR (chrome via ARB parity, content via bilingual JSON), overflow-safe on 360dp, `flutter analyze` clean, full suite green, `score_engine_test.dart` still 12/12, S23 cutoffs verified against the engine. Then a **final Phase 1 TC1–TC9 integration pass** per `PHASE1_TEST_PLAN.md` closes Phase 1.

## 7. First task for Antigravity
**Step 1 — Reference data layer + assets.** Do not start UI until Step 1 is approved.
