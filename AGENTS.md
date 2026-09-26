# Saagar Audit App — AI Agent Instructions (Claude & Antigravity)

Welcome to the **Saagar Audit App** repository.

## 🧠 Shared Brain & Context Directory
All project specifications, architectural decisions, database schemas, scoring logic, and session handoffs are maintained inside the **`brain/`** directory in this repository:

- **[`brain/OVERVIEW.md`](brain/OVERVIEW.md)**: Objective, stores (`WLMHW` & `HEMW`), user roles, and 4-phase delivery plan.
- **[`brain/TECH_STACK_AND_RULES.md`](brain/TECH_STACK_AND_RULES.md)**: Locked tech stack (Riverpod, GoRouter, sqflite, bcrypt, offline-first) and operational rules.
- **[`brain/DATABASE_SCHEMA.md`](brain/DATABASE_SCHEMA.md)**: The 14 SQLite tables, relationships, and seed data.
- **[`brain/SCORING_AND_LOGIC.md`](brain/SCORING_AND_LOGIC.md)**: Pure math scoring engine, NA handling, strict band cutoffs, and canonical test expectations.
- **[`brain/CURRENT_STATE.md`](brain/CURRENT_STATE.md)**: Status of screens S01–S32 and list of open issues.
- **[`brain/SESSION_HANDOFF.md`](brain/SESSION_HANDOFF.md)**: Chronological handoff register.
- **[`brain/PHASE1_TEST_PLAN.md`](brain/PHASE1_TEST_PLAN.md)**: TC1–TC9 QA gauntlet, coverage gaps, defect register.
- **[`brain/FIX_PROMPT_2026-09-21.md`](brain/FIX_PROMPT_2026-09-21.md)**: Priority-ordered defect-fix prompt.
- **[`brain/SPEC_APP.md`](brain/SPEC_APP.md)** / **[`brain/SPEC_WORKBOOK.md`](brain/SPEC_WORKBOOK.md)** / **[`brain/SPEC_QUICKREF.md`](brain/SPEC_QUICKREF.md)**: Full spec (converted from Documentation `.docx`).
- **[`brain/SPRINT_S27_S32_SETTINGS.md`](brain/SPRINT_S27_S32_SETTINGS.md)**: Active sprint plan — Settings, User & CRO management.

## 🤝 Agent Roster & Coordination
Two AI agents share this ONE `brain/` folder. It is the single source of truth between them.

- **Claude — Senior Developer & Team Lead of this project.** Claude owns the technical direction: reviews everything Antigravity ships, guides the team, safeguards architecture and the locked stack, keeps the `brain/` docs authoritative, and makes sure development is going well and staying on-spec. Claude designs the next step each session, does targeted code fixes and reviews, and holds the quality bar. Claude CANNOT run Flutter in-session — every build/test result Claude cites comes from Antigravity's device runs, and Claude labels them as such.
- **Antigravity — Developer (reports to Claude).** Implements/refactors Flutter code against the plan Claude sets, runs `flutter analyze`/`flutter test` on the device, and pastes raw output back into the handoff for the record.

Coordination rules (both agents):
1. **Read `brain/CURRENT_STATE.md` + `brain/SESSION_HANDOFF.md` before doing anything.** Assume the other agent may have changed things since your last turn.
2. **Every `brain/SESSION_HANDOFF.md` entry MUST start with `**Author**: Claude` or `**Author**: Antigravity`** and a date, so authorship is never ambiguous.
3. **Append, don't overwrite.** Add a new dated handoff entry rather than editing another agent's past entry. Fix stale facts in `CURRENT_STATE.md` (the living status), not by rewriting history.
4. **Label unverified claims.** Claude marks anything not independently executed as "per Antigravity's run, not re-verified." Antigravity pastes raw command output.
5. **Hand the baton explicitly.** Claude ends each session by setting the next step; Antigravity ends each session by reporting what was built + raw test output. Both close their handoff entry with a clear "Next Immediate Task."

## 📖 Spec-Reading Protocol (each session, before planning the next step)
1. Locate the product spec / design doc (see `brain/OVERVIEW.md` for the 4-phase plan; the full workbook is `Saagar_P1_App_Spec_v1.docx`).
2. **If the spec is machine-readable** (`.md`, or readable text), read the relevant phase before designing the next step.
3. **If the spec is NOT readable** in-session (binary `.docx`/`.pdf` that can't be parsed cleanly), Claude instructs Antigravity to convert it to Markdown and commit it under `brain/` (e.g. `brain/SPEC_PHASE_X.md`) so both agents can read it. Do not design against an unread spec.
4. Read phase-by-phase, not the whole book each time — pull the phase that matches the current sprint.

## Mandatory Operating Protocol
1. **Always read `brain/CURRENT_STATE.md` and `brain/SESSION_HANDOFF.md`** before writing any code.
2. **Do NOT save context or memory outside this project.** Everything stays in `brain/`.
3. **Keep `brain/SESSION_HANDOFF.md` updated** at the end of every conversation with what was changed and what remains.
4. **Adhere to the locked stack**: No Firebase Auth, no drift/isar, no Bloc/Provider.
5. **Score tests must always pass**: `flutter test test/score_engine_test.dart` must always be green.
6. **Review-gated push after every screen or sprint**: Never sit un-backed-up — but pushing is gated on Claude's approval. The flow is fixed:
   1. Antigravity builds the screen/milestone, runs `flutter analyze` + `flutter test`, and pastes raw output into `SESSION_HANDOFF.md`. **Antigravity does NOT commit or push yet.**
   2. **Claude reviews** the code and the raw test output and either requests changes or writes an explicit **"APPROVED — cleared to commit & push"** line in the handoff.
   3. Only **after** Claude's written approval does Antigravity `git add` the reviewed files + brain updates, commit with a descriptive message, and `git push origin main`.
   4. Antigravity then pastes the raw `git status` + `git log --oneline` back into the handoff as the push record.
   Rationale: Claude is Team Lead and quality gate; nothing enters the permanent history without a review. **Never force-push.** The only exception is a pure `brain/`-docs/handoff commit (no app code), which Antigravity may push without a code review since there is nothing to review.
7. **Repo layout & phase-naming rule (spec §15.2 / §15.4):**
   The Flutter app lives at the **repository root** (`lib/`, `test/`, `android/`, `assets/`, `pubspec.yaml`, etc. sit directly in the repo root). There is **one** app that grows across phases. **`phase-1`…`phase-4` are Git BRANCH names ONLY — never folders.** Never create a `phase-N/` directory and never copy the app into a per-phase folder. New phase work happens on a `phase-N` branch (with `feature/*` branches off it), then merges to `main` when signed off.

