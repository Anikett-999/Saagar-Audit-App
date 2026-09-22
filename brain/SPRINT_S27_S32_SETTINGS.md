# Sprint Design — S27–S32 Settings, User & CRO Management

- **Author**: Claude (Senior Developer & Team Lead)
- **Date**: 2026-09-21
- **For**: Antigravity (Developer) to implement against this plan.
- **Grounding**: `brain/SPEC_APP.md` §S27–S32 (lines ~1751–1809), role matrix (lines ~305–324), `brain/DATABASE_SCHEMA.md` (`users`, `cros` tables). Read those before coding.

## Why this sprint first
Two hard deployment blockers, both live here:
1. **No UI to create SM/GM users or CROs.** The app has exactly one Owner (from S03 first-time setup) and no way to add the Store Managers who actually run daily audits, nor the CROs who get attributed to findings. Until this exists, the app cannot be handed to a real store.
2. Everything else (CAPs, reference, reports) assumes users and CROs already exist.

So we build the Settings hub (S27) and its two management screens (S28 Manage CROs, S29 Manage Users) first, then the three simpler settings screens (S30 Change PIN, S31 Language, S32 Backup/Export).

## Current code reality (verified this session)
- **CRO side is half-built**: `data/models/cro.dart`, `data/repositories/cro_repository.dart` exist. Repo has `listActive()`, `add()`, `deactivate()`. **Missing**: `listAll()` (S28 must show inactive too), `update()` / edit, and a reactivate path. No CRO management UI.
- **User side does not exist**: no `data/models/user.dart`, no `user_repository.dart`. Auth reads the users table directly via `auth_provider.dart`. A `UserRepository` must be created.
- **No settings routes**: `app.dart` `routerProvider` stops at `s11_submitted`. S27–S32 routes must be added.
- **S05 Home** currently shows a "coming in week 3+" snackbar for the Settings tile — replace with real navigation to S27.
- **Locked stack**: Riverpod + GoRouter + sqflite + bcrypt. No new deps needed. Reuse the existing bcrypt path used in S03/S04 for PIN hashing.

## Schema (already in DB — do not migrate)
- `users`: `id` (UUID PK), `name`, `role` ('SM'|'GM'|'OWNER'), `pin_hash`, `language_pref`, `phone`, `is_active`, `created_at`, `last_login_at`, `created_by`
- `cros`: `id` (UUID PK), `name`, `counter` ('Titan'|'Helios'), `shift` ('morning'|'afternoon'|'flexible'), `is_active`, `joined_at`

## Build order & acceptance criteria

### 1. Data layer (no UI)
- **`data/models/user.dart`** — immutable model + `fromMap`/`toMap`, mirroring `cro.dart` conventions.
- **`data/repositories/user_repository.dart`** (singleton like `CroRepository`):
  - `listAll()` — all users incl. inactive, ordered by name.
  - `addUser({name, role, phone, pinHash, createdBy})` — role must be 'SM' or 'GM' only (never a 2nd Owner).
  - `deactivate(id)` / `reactivate(id)` — never hard-delete (audit-trail integrity per spec §S29).
  - `resetPin(id, newPinHash)`.
  - `changePin(id, newPinHash)` (used by S30).
  - `updateLanguagePref(id, lang)` (used by S31).
  - Guard: `addUser` throws if role=='OWNER'; enforce "cannot have more than 1 Owner" (spec §S29).
- **Extend `CroRepository`**: add `listAll()`, `update({id,name,counter,shift})`, `reactivate(id)`.
- **Tests (Antigravity writes + runs)**: `user_repository_test.dart` — assert the no-2nd-Owner guard throws, deactivate keeps the row, resetPin changes the hash. Keep score/auth suites green.

### 2. S27 — Settings hub
- New screen `ui/screens/s27_settings/settings_screen.dart`, route `s27_settings`.
- Role-filtered list (read current role from `auth_provider`): Manage CROs (all), Manage Users (**Owner only** — hide for SM/GM), Change PIN (all), Language (all), Backup & Export (all; Owner sees sync controls), About.
- Wire S05 Home Settings tile → `context.goNamed('s27_settings')` (remove the placeholder snackbar).
- **All strings via `AppLocalizations`** (Rule #8 — no hardcoded text; add new ARB keys to both `app_en.arb` and `app_mr.arb` in parity).

### 3. S28 — Manage CROs (SM, GM, Owner)
- Table of CROs (name, counter, shift, active badge) with edit + deactivate/reactivate actions and a "+ Add CRO" button opening a form (name, counter Titan/Helios, shift, is_active toggle).
- Deactivating retains history but removes from dropdowns — verify the S06/S08 CRO pickers still call `listActive()` so deactivated CROs disappear there but remain on past audits.

### 4. S29 — Manage Users (Owner only)
- Route-guard: if current role != OWNER, redirect/deny.
- Table of users with role badge. Owner actions: add SM/GM (PIN set at creation, bcrypt-hashed), deactivate, reset PIN. No delete. Enforce single-Owner rule in the UI too (hide "add Owner").

### 5. S30 — Change PIN (all) / S31 — Language (all) / S32 — Backup & Export
- S30: current / new / confirm PIN; verify current against stored hash, bcrypt the new one via `changePin`.
- S31: EN/मराठी toggle writing `users.language_pref`; reuse existing `localeProvider`. (In-app switcher already exists on Home/Login — S31 is the canonical Settings entry.)
- S32: export whole DB as JSON to Downloads (Owner-only sees Firestore sync status/force-sync — **stub/disabled in Phase 1**, cloud is Phase 4; label it clearly so it isn't mistaken for done).

## Guardrails for this sprint
- Do NOT add Firestore now (Phase 4). S32 sync controls are visible-but-disabled stubs only.
- Every new user-facing string must exist in both ARB files (Rule #8).
- `flutter analyze` clean + `flutter test` green (paste raw output in handoff).

## Next Immediate Task (Antigravity)
Start with **Section 1 (data layer)** — build `User` model, `UserRepository`, extend `CroRepository`, and write/run `user_repository_test.dart`. Report back with raw `flutter test` output before moving to the UI screens, so I can review the data layer against spec before we build on it.
