# Saagar Audit App — AI Agent Instructions (Claude & Antigravity)

## 🧠 Shared Brain & Context Directory
All project specifications, architectural decisions, database schemas, scoring logic, and session handoffs are located at:
`../brain/` (relative to `phase-1/`):

- **[`../brain/OVERVIEW.md`](../brain/OVERVIEW.md)**: Objective, stores (`WLMHW` & `HEMW`), user roles, and 4-phase delivery plan.
- **[`../brain/TECH_STACK_AND_RULES.md`](../brain/TECH_STACK_AND_RULES.md)**: Locked tech stack (Riverpod, GoRouter, sqflite, bcrypt, offline-first) and operational rules.
- **[`../brain/DATABASE_SCHEMA.md`](../brain/DATABASE_SCHEMA.md)**: The 14 SQLite tables, relationships, and seed data.
- **[`../brain/SCORING_AND_LOGIC.md`](../brain/SCORING_AND_LOGIC.md)**: Pure math scoring engine, NA handling, strict band cutoffs, and canonical test expectations.
- **[`../brain/CURRENT_STATE.md`](../brain/CURRENT_STATE.md)**: Status of screens S01–S32 and list of open issues.
- **[`../brain/SESSION_HANDOFF.md`](../brain/SESSION_HANDOFF.md)**: Chronological handoff register.

## Mandatory Operating Protocol
1. **Always read `../brain/CURRENT_STATE.md` and `../brain/SESSION_HANDOFF.md`** before writing any code.
2. **Do NOT save context or memory outside this project.** Everything stays in `brain/`.
3. **Keep `../brain/SESSION_HANDOFF.md` updated** at the end of every conversation with what was changed and what remains.
4. **Adhere to the locked stack**: No Firebase Auth, no drift/isar, no Bloc/Provider.
5. **Score tests must always pass**: `flutter test test/score_engine_test.dart` must always be green.
