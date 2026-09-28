# Sprint P2-5 — CAP Verify (S18) + CAP Close (S19) + Extend/Reopen + GM Dashboard (Phase-2 finale)

**Phase**: 2 (Weekly Audit, Weeks 5–8)
**Sprint**: P2-5 (fifth and FINAL sprint of Phase 2)
**Author of plan**: Claude (Team Lead)
**Date set**: 2026-09-28
**Branch**: continue on `phase-2`; cut `feature/p2-cap-lifecycle` off `phase-2` (Rule 7 — branches only, never folders).
**Pre-condition (met)**: P2-4 merged to `phase-2` (`c534128` feat + `b57e341` docs), 254/254 green per Antigravity's device run, `main` untouched at `5b9408b`. Weekly report generates, S20/S21 render the §3.6 nine-section format, bilingual 1-page PDF exports, and the pattern engine (T2.4) suggests exactly **one** Pattern CAP per clustered checkpoint.

---

## 1. Team-Lead rationale
Phase 1 built the CAP *creation* half of the loop: S14 List, S15 Create (5-Why), S16 Detail, S17 Mark Done — a CAP goes `open → done`. P2-4 produced the artifact that *suggests* CAPs (weekly Fails + the single Pattern CAP). P2-5 **closes the loop**: the GM/Owner re-runs the checkpoint's `verification_method`, confirms it now passes, and drives the CAP `done → verified → closed` — plus the two off-happy-path exits (verification fails → **extend** or **reopen**). This is the spec's S18/S19 and Workbook Day 4 §4.3. It is the last thing Phase 2 needs to be a complete audit→finding→CAP→verify→close cycle. It also **consumes** the Pattern CAP P2-4 emits, so the pattern feature becomes end-to-end, not just a report line.

## 2. Grounding in spec (R1 — Workbook is ground truth)
- **S18 CAP Verify** (SPEC_APP.md ~L1653): "GM/Owner re-runs the `verification_method` checkpoint and confirms it now passes. **Mandatory photo if `requires_photo_on_fail=1`** on that checkpoint. If verification passes: `caps.status='verified'`, `verified_at=now`, `verified_by`; `cap_log: 'verified'`. If verification **fails**: prompt to either **extend** the CAP or **re-open at Plan phase** (Workbook Day 4 §4.3)."
- **S19 CAP Close** (~L1667): "Final close after verification. Quick confirmation dialog. Updates `status='closed'`, `closed_at=now`, `closed_by`." (Only a `verified` CAP may be closed.)
- **S16 Detail transitions** (~L1627): S16 already exposes **Verify / Close / Request Extension / Reopen** as **Phase-2 stubs** (currently `onPressed: null`). P2-5 wires them.
- **CAP state machine** (schema, verified against `lib/data/db/schema.dart`): `caps.status IN (open, done, verified, closed, aged, reopened)`; `cap_log.event IN (created, action_done, marked_done, verified, closed, extended, aged, reopened)`. All target states + log events **already exist**.

Legal transitions this sprint implements (all forward, all already in the CHECK):
- `done → verified` (Verify pass) — GM/Owner
- `verified → closed` (Close) — GM/Owner
- `done → reopened` (Verify fail → reopen at Plan) — GM/Owner
- `done → done` + `extension_count++` (Verify fail → extend, new deadline) — GM/Owner
- `closed → reopened` (already stubbed for **Owner** in S16) — Owner only

## 3. Data model / libs — NO changes needed (R2 guardrail)
I inspected `lib/data/db/schema.dart` and `lib/data/repositories/cap_repository.dart`:
- `caps` has **every column** these transitions need: `status`, `done_at`, `verified_at`, `verified_by`, `closed_at`, `closed_by`, `extension_count`, `latest_extension_reason`, `aged_count`. **No migration.**
- `cap_log.event` CHECK already permits `verified`, `closed`, `extended`, `reopened`. **No migration.**
- `photos` already supports CAP-context rows (`cap_id`, `context='cap_progress'`); reuse for the mandatory verify photo (use `context='cap_verify'` — a value, not a schema change).
- **No new libs.** Verify photo reuses the existing camera/photo widgets from S09/S17.
- If you believe a column/event/lib is needed, **STOP and ask Claude** (R2 — no silent schema/stack drift; a new `cap_log.event` value WOULD be a CHECK change → §4.4 four-way).

## 4. ⚠️ BLOCKING NAMING RECONCILIATION (R1) — resolve in code as part of this sprint
P2-3's **7-Day Review** screen took the l10n prefix **`s18*`** (`s18SevenDayReviewTitle` … `s18VerifyAndSignButton`, 20+ keys), but **spec S18 = CAP Verify**. The 7-Day Review is an *unnumbered* Phase-2 "Day 6" screen — it is not a spec S-number. Leaving it on `s18*` guarantees confusion the moment CAP Verify (the real S18) lands.

**Team-Lead decision (R1, spec is ground truth):**
- **Free the `s18*` namespace for the real S18 (CAP Verify).** Rename the 7-Day Review keys `s18* → weeklyReview*` (mechanical: rename in `app_en.arb` + `app_mr.arb`, update the ~5 call-sites in `seven_day_review_screen.dart`, regenerate l10n). **No behavior/string-content change** — same EN+MR text, new keys. This keeps the already-approved P2-3 Marathi intact.
- New CAP Verify keys use prefix **`s18*`** (e.g. `s18CapVerifyTitle`), CAP Close uses **`s19*`**. This restores spec S-number ↔ screen alignment.
- If Antigravity finds a spec line that actually assigns the 7-Day Review an S-number, **STOP and flag R1** instead of renaming.

*(This is a rename/refactor of P2-3-approved strings, so it's called out explicitly rather than done silently — Rule 3/append discipline. It touches only l10n keys + call-sites, not logic or the verify/immutability paths.)*

## 5. Scope — what Antigravity builds

### 5.1 Repository: CAP lifecycle transitions (build FIRST, unit-test) — mirror `markDone`
Add to `cap_repository.dart`, each mirroring the existing `markDone` guarded-transaction pattern (getById → status guard → `txn`: update `caps` + insert `cap_log` + optional photo; throw `StateError` on wrong status):
- **`verifyCap({capId, verifierId, photoPath?})`** — guard `status=='done'` (else throw). Set `status='verified'`, `verified_at=now`, `verified_by=verifierId`. Insert `cap_log` event `'verified'` (from_status `done`). If the origin checkpoint has `requires_photo_on_fail=1`, a **non-empty `photoPath` is MANDATORY** — throw if missing (mirror the R7 gate philosophy); persist the photo row with `context='cap_verify'`.
- **`closeCap({capId, closerId})`** — guard `status=='verified'` (else throw). Set `status='closed'`, `closed_at=now`, `closed_by=closerId`. Insert `cap_log` event `'closed'` (from_status `verified`).
- **`extendCap({capId, actorId, newDeadline, reason})`** — guard `status IN ('done','open','reopened')`. Keep status (verify-fail→extend leaves it `done`; a plain extension from open keeps `open`), set `deadline=newDeadline`, `extension_count = extension_count + 1`, `latest_extension_reason=reason`. Insert `cap_log` event `'extended'`. `reason` is required (non-empty) — throw if blank.
- **`reopenCap({capId, actorId, reason})`** — guard `status IN ('done','closed')`. Set `status='reopened'` (reopen at Plan phase). Insert `cap_log` event `'reopened'`. (Closed→reopened is **Owner-only** per S16 stub; done→reopened from a failed verify is GM/Owner — enforce the role at the UI layer, not the repo, but document it.)
- **R5-adjacent:** none of these mutate the origin audit, its `audit_results`, scores, or counts — they touch only `caps`/`cap_log`/`photos`. Do NOT recompute any audit.

### 5.2 S18 — CAP Verify screen (NEW; GM/Owner only)
- Entry: from S16 Detail "Verify" button (currently stubbed) when `cap.status=='done'` and role ∈ {GM, OWNER}. Route e.g. `/cap/:id/verify`, role-gated (SM → back/home; null → login).
- Show: CAP id, problem statement, the **`verification_method`** text (EN/MR), origin checkpoint code + text, deadline. A clear "does it pass now?" affirmation.
- If the origin checkpoint `requires_photo_on_fail=1`: show a **mandatory** photo capture (reuse S09/S17 photo widget); block "Confirm Verified" until a photo exists.
- **Pass** → `verifyCap(...)` → back to S16 showing `verified` badge.
- **Fail** → present two choices per §4.3: **Extend** (date picker + required reason → `extendCap`, stays `done`) or **Reopen at Plan** (required reason → `reopenCap` → `reopened`). Do NOT auto-supersede or re-score anything.
- EN+MR on every new string (R3/R8), real Marathi — STOP and ask if unknown.

### 5.3 S19 — CAP Close screen/dialog (NEW; GM/Owner only)
- Entry: from S16 "Close" button when `cap.status=='verified'` and role ∈ {GM, OWNER}. A **quick confirmation dialog** (spec says "Quick confirmation dialog") is sufficient — does not need a full screen. On confirm → `closeCap(...)` → S16 shows `closed` badge.
- Reopen (Owner-only) from `closed` reuses `reopenCap` behind the already-present S16 Owner Reopen stub.

### 5.4 Wire S16 stub buttons
Enable the four disabled buttons in `s16_cap_detail/cap_detail_screen.dart` with correct status+role gating:
- **Verify** — visible/enabled when `status=='done'` AND GM/Owner → S18.
- **Close** — visible/enabled when `status=='verified'` AND GM/Owner → S19 dialog.
- **Request Extension** — enabled when `status IN ('open','done','reopened')` AND GM/Owner → extend flow.
- **Reopen** — enabled when `status=='closed'` AND **Owner** (existing rule) → reopen flow.
Refresh S16 after each transition so the status badge + log update live.

### 5.5 GM Dashboard (Phase-2 scope: CAP oversight)
- A GM/Owner-facing dashboard summarizing CAP health for the store(s): counts by status (open, done/awaiting-verification, verified, closed, **overdue** = deadline < today & not closed, **aged**), and a "CAPs awaiting my verification" list (status=`done`) as the primary call-to-action, deep-linking to S18. Reuse existing list/card patterns and the `listCaps(filter)` repo (filters open/overdue/closed already exist; add an `awaitingVerification` = `status='done'` filter if not present — that's a query, not a schema change).
- Keep it read-focused + navigational; no new analytics engine. EN+MR parity.
- **Consume the Pattern CAP:** ensure a `is_pattern=1` CAP (created from P2-4's single suggestion) flows through this same Verify/Close lifecycle and shows a "Pattern" marker on its S16/dashboard card, so the T2.4 loop is end-to-end.

## 6. Tests — must be GREEN to close (Rule 5 + R4)
- **Verify happy path**: a `done` CAP → `verifyCap` → `status='verified'`, `verified_at`/`verified_by` set; `cap_log` gains one `verified` row (from `done`).
- **Verify photo gate**: origin checkpoint `requires_photo_on_fail=1` + no photo → `verifyCap` throws; with photo → succeeds and a `context='cap_verify'` photo row is written.
- **Close happy path**: a `verified` CAP → `closeCap` → `status='closed'`, `closed_at`/`closed_by`; `cap_log` `closed` (from `verified`). Closing a non-`verified` CAP throws.
- **Verify-fail → extend**: `extendCap` bumps `extension_count`, sets new `deadline` + `latest_extension_reason`, stays `done`, logs `extended`; blank reason throws.
- **Verify-fail → reopen** and **closed → reopen (Owner)**: `reopenCap` sets `reopened`, logs `reopened`; guard rejects illegal source states.
- **Pattern CAP end-to-end**: the single `is_pattern=1` CAP from T2.4 can be marked done → verified → closed through the same methods.
- **Role gates (widget)**: SM sees no Verify/Close/Extend/Reopen actions; Reopen shown only to Owner on a `closed` CAP.
- **Naming reconciliation**: 7-Day Review renders identical EN+MR after the `s18*→weeklyReview*` rename (snapshot the visible strings); l10n regenerates with 0 analyze issues.
- **R5 / immutability**: none of the CAP transitions alter any `audits`/`audit_results`/scores. Canonical daily `81/90=90.0%` and weekly `104.8/124=84.5%` untouched.
- **Regression (Rule 5)**: all existing tests stay green (254 + new).
- Paste raw `flutter analyze` + `flutter test` into `SESSION_HANDOFF.md`.

## 7. Definition of Done for P2-5
- [ ] `s18*→weeklyReview*` rename done; spec S18=CAP Verify / S19=CAP Close alignment restored; P2-3 strings unchanged in content.
- [ ] `verifyCap` / `closeCap` / `extendCap` / `reopenCap` implemented, guarded, R5-safe, unit-tested; mandatory verify-photo gate honored when `requires_photo_on_fail=1`.
- [ ] S18 Verify screen + S19 Close dialog built, GM/Owner-gated; verify-fail offers extend/reopen per §4.3.
- [ ] S16 stub buttons wired with correct status+role gating; badge/log refresh live.
- [ ] GM Dashboard shows CAP status counts + "awaiting my verification" deep-linking to S18; Pattern CAP flows end-to-end with a Pattern marker.
- [ ] EN+MR parity on all new strings (R3/R8), real Marathi.
- [ ] `flutter analyze` 0 issues; `flutter test` all green (254 + new). Raw output pasted.
- [ ] **HOLD for Claude review.** No commit/push of app code until Claude writes `APPROVED — cleared to commit & push` (Rule 6). Never push Phase-2 app code to `main` (Rule 7). Brain-only doc commits exempt.

## 8. Explicitly OUT of scope for P2-5 (Rule 9)
**Escalation engine / trigger firing** (T3.x — e.g. auto-aging jobs, overdue escalation notifications) → **Phase 3**. **Monthly reports** → Phase 3. **Push notifications** (spec's "notify GM on marked done / awaiting verification") → **Phase 4** (leave the existing `TODO(phase4)`). **Auto-aging** (`status→aged` background job) → Phase 3; P2-5 may *display* an overdue/aged count but does not run an aging job. Firebase/cloud sync → Phase 4. Do not re-score or mutate submitted audits (R5). Any tempting addition → append to `docs/v2-wishlist.md` and continue.

## 9. Guardrails recap
- R1: S18/S19 spec + Day 4 §4.3 are ground truth; the S18 naming collision is reconciled toward spec (§4); contradictions → STOP & flag.
- R2: **no schema change** (caps/cap_log/photos already fit) and **no new libs** — a new `cap_log.event` value would be a CHECK change → STOP & ask (§4.4 four-way).
- R3/R8: real EN+MR for every new string; never guess Marathi → STOP & ask.
- R5: submitted audits immutable; CAP transitions touch only caps/cap_log/photos, never audit rows/scores.
- R7: honor the mandatory-photo gate on verify when the origin checkpoint requires it; never weaken the existing photo gate.
- R6: review-gated push; HOLD until Claude approves.
- R10: Conventional Commits.

## 10. Open decisions I've already made (so Antigravity isn't blocked)
1. **S19 is a confirmation dialog, not a full screen** — spec says "Quick confirmation dialog"; a full route is unnecessary. If Antigravity finds this awkward alongside the S18 route, a thin S19 route is acceptable, but the dialog is preferred.
2. **Verify photo uses `context='cap_verify'`** (a new `photos.context` *value*, not a schema change) to distinguish from `cap_progress`. If any CHECK constrains `photos.context` to an enum, STOP and ask (I did not see one, but confirm on device).
3. **Aging is display-only in P2-5** — show overdue/aged counts from existing data; the background aging *job* is Phase 3. If the dashboard needs a stored `aged` transition to show anything, render "overdue" (computed from `deadline < today`) instead of mutating status.
