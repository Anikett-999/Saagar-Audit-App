# Migration: Flatten App to Repo Root (`phase-1/` → root)

**Author**: Claude (Team Lead)
**Date**: 2026-09-26
**Status**: HANDED OFF to Antigravity — awaiting execution on a branch, then Claude review before merge to `main`.
**Owner of decision**: Sagar (approved Option A on 2026-09-26).

---

## 0. TRANSITION NOTE — READ THIS FIRST (both agents)

> ⚠️ **The Flutter app is being moved OUT of `phase-1/` and UP to the repository root.**
>
> During and after this migration, **file paths change**. If you are searching for a source
> file (e.g. `lib/...`, `test/...`, `pubspec.yaml`, `android/...`, `Documentation/...`) and you
> look inside **`phase-1/` and find nothing — look at the REPOSITORY ROOT instead.**
>
> - OLD path: `Saagar Audit App/phase-1/lib/ui/screens/...`
> - NEW path: `Saagar Audit App/lib/ui/screens/...`
>
> `brain/` was always at the root and does NOT move. Only the app moves.
>
> Once the migration commit is merged to `main`, the `phase-1/` folder should no longer exist.
> If you still see it, the migration is mid-flight — check `SESSION_HANDOFF.md` for status.

---

## 1. Why (decision record)

Spec §15.2 places the Flutter app at the **repository root** (`saagar-audit-app/` with `lib/`,
`test/`, `android/`, `assets/`, `docs/`, `builds/`, `pubspec.yaml` directly inside it — **no
`phase-1/` wrapper folder**). Spec §15.4 defines `phase-1`…`phase-4` as **long-lived Git
BRANCHES off `main`**, not directories.

The current on-disk layout wraps the whole app inside `phase-1/`, which is a deviation from spec.
Left as-is, it invites a fatal mistake at Phase 2 start: creating a sibling `phase-2/` folder and
**copying the entire app into it**, forking the codebase. That would make it impossible to keep
"all Phase 1 tests green in Phase 2" without maintaining two copies.

**Decision (Option A):** move the app to the repo root so structure matches spec, and enforce a
naming rule that phases are branches only.

---

## 2. The naming rule to codify (Antigravity: add this)

Add the following rule to **both** `AGENTS.md` and `CLAUDE.md` (root copies), under the operating
protocol section, verbatim:

> **Repo layout & phase-naming rule (spec §15.2 / §15.4):**
> The Flutter app lives at the **repository root** (`lib/`, `test/`, `android/`, `assets/`,
> `pubspec.yaml`, etc. sit directly in the repo root). There is **one** app that grows across
> phases. **`phase-1`…`phase-4` are Git BRANCH names ONLY — never folders.** Never create a
> `phase-N/` directory and never copy the app into a per-phase folder. New phase work happens on a
> `phase-N` branch (with `feature/*` branches off it), then merges to `main` when signed off.

---

## 2A. BACKUP / RESTORE POINT — MANDATORY Step 0 (do this FIRST, before anything)

Before touching a single file, create a permanent, named restore point and push it off-machine so
we can return to the exact current known-good state if the migration goes wrong.

1. **Confirm the tree is clean and up to date** (nothing uncommitted to lose):
   ```
   git checkout main
   git pull origin main
   git status        # must be "working tree clean"
   git log --oneline -1
   ```
2. **Create a permanent tag** at the current known-good commit (Phase 1 signed-off state):
   ```
   git tag -a pre-flatten-2026-09-26 -m "Known-good state before flatten-to-root migration (Phase 1 signed off)"
   git push origin pre-flatten-2026-09-26
   ```
3. **Create a backup branch** at the same commit and push it (belt-and-suspenders):
   ```
   git branch backup/pre-flatten-2026-09-26
   git push -u origin backup/pre-flatten-2026-09-26
   ```
4. **Record the commit hash** of this restore point in `SESSION_HANDOFF.md` (e.g. `f05b7f4`) so it's
   written down, not just in Git.

> ✅ After Step 0 you have **three** ways back to today's state: the tag `pre-flatten-2026-09-26`,
> the branch `backup/pre-flatten-2026-09-26`, and the untouched `main` — all pushed to GitHub.

### Restore procedure (if the migration fails or we change our minds)

Because the migration happens on `chore/flatten-to-root` and is NOT merged to `main` until Claude
approves, the simplest rollback is just to abandon the branch:
```
git checkout main          # main was never touched
git branch -D chore/flatten-to-root
```
If something was already merged and needs undoing, reset to the tagged restore point (Claude must
approve any history operation; **never force-push without Sagar's explicit OK**):
```
git checkout main
git reset --hard pre-flatten-2026-09-26     # local only
# pushing this back requires Sagar's explicit approval — do NOT force-push unilaterally
```
The tag and backup branch on `origin` remain valid restore points regardless.

---

## 3. Migration procedure (Antigravity executes on the device)

Do this on a **dedicated branch**, never directly on `main`, **and only after Step 0 (§2A) is
done**. It is fully reversible: if anything goes wrong, delete the branch and `main` is untouched.
**No force-push at any point.**

1. **Branch off main:**
   ```
   git checkout main
   git pull origin main
   git checkout -b chore/flatten-to-root
   ```

2. **Clean generated artifacts first** (so only real source moves):
   ```
   cd phase-1
   flutter clean
   ```
   This drops `build/`, `.dart_tool/`, etc. Do NOT move `build/`, `.gradle/`, `.idea/`,
   `.dart_tool/`, `local.properties`, or `*.iml` — they are machine-generated and regenerate.

3. **Move tracked source up one level with `git mv`** (preserves history / rename detection).
   Move everything Git tracks inside `phase-1/` to the repo root: `lib/`, `test/`,
   `integration_test/` (if present), `android/` (only tracked parts), `ios/`, `assets/`,
   `Documentation/`, `l10n.yaml`, `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock`,
   `.metadata`, `devtools_options.yaml`, and the `.github/` folder.
   - Use `git mv <path> ../<path>` per top-level entry (or script it). Verify with `git status`
     that moves are detected as renames, not delete+add.

4. **Resolve the 4 file collisions by hand** (root already has these; `phase-1/` has its own):
   - `.gitignore` — keep the Flutter-project `.gitignore` from `phase-1/` at root (merge in any
     root-specific ignores). Make sure `build/`, `.dart_tool/`, `.idea/`, `*.iml`,
     `android/local.properties`, `.gradle/` stay ignored.
   - `CLAUDE.md` — **keep the ROOT version** (shared-brain instructions). Fold anything unique from
     `phase-1/CLAUDE.md` into it, then delete the phase-1 copy.
   - `AGENTS.md` — same: keep root version, merge + delete the phase-1 copy.
   - `README.md` — keep one; merge useful content; delete the duplicate.
   Do NOT blind-overwrite — inspect both, merge intentionally.

5. **Delete the stale CI workflow.** `.github/workflows/apk.yml` is a Capacitor/npm build
   (`npm install`, `npx cap`) — it does not apply to a Flutter app. Remove it. Keep
   `android-build.yml`. (Note: moving `.github/` to the repo root is what actually *activates* CI —
   GitHub only reads `.github/workflows/` at the repo root, so it was dormant while nested in
   `phase-1/`.)

6. **Fix stale `phase-1/` path references in `brain/` docs.** At minimum update:
   - `brain/OVERVIEW.md` (`phase-1/Documentation/...` → `Documentation/...`)
   - any `brain/*.md` that names `phase-1/lib/...`, `phase-1/test/...`, etc.
   Grep the brain folder for `phase-1/` and fix each. (The historical `SESSION_HANDOFF.md` entries
   that *describe* past work may keep their old paths — do not rewrite history; only fix
   forward-looking references and `CURRENT_STATE.md`.)

7. **Verify — this is the acceptance gate:**
   ```
   flutter pub get
   flutter analyze
   flutter test
   ```
   **Required result: 214/214 tests green, analyze clean.** Paste the RAW output into
   `SESSION_HANDOFF.md`. Confirm the `android-build.yml` CI job goes green on the branch.

8. **HOLD for Claude review.** Do NOT merge or push to `main` yet. Post the raw analyze/test output
   + `git status` + `git log --oneline` in `SESSION_HANDOFF.md`. Claude reviews and writes the
   explicit `APPROVED — cleared to commit & push` line.

9. **After Claude's written approval:** merge the branch to `main` (fast-forward or merge commit),
   `git push origin main`, then paste the raw `git status` + `git log --oneline` back into the
   handoff as the push record.

---

## 4. Why the fix is safe (guarantee basis)

- **Dart imports don't break:** they are `package:saagar_audit_app/...` or relative *within* `lib/`.
  The folder moves as one unit, so those resolve unchanged.
- **The only fragile layer is config/CI**, and the `flutter test` (214/214) + green CI run on the
  branch is the *proof* it worked — the guarantee is by verification, not by hope.
- **Fully reversible:** it's a branch. If wrong, delete the branch; `main` is untouched.
- **History preserved:** `git mv` keeps rename detection so `git log --follow <file>` traces each
  file across the move. No history rewrite, no force-push.

---

## 5. Definition of Done for this migration

- [ ] **Step 0 backup done:** tag `pre-flatten-2026-09-26` + branch `backup/pre-flatten-2026-09-26` pushed to `origin`; restore-point hash recorded in handoff.
- [ ] App source now at repo root; `phase-1/` folder gone.
- [ ] 4 collision files reconciled (no lost content).
- [ ] `apk.yml` removed; `android-build.yml` at root and green.
- [ ] `brain/` forward-looking `phase-1/` path refs fixed.
- [ ] Naming rule added to `AGENTS.md` + `CLAUDE.md`.
- [ ] `flutter analyze` clean + `flutter test` 214/214 (raw output in handoff).
- [ ] Claude review + written APPROVED line.
- [ ] Merged to `main` and pushed; push record pasted in handoff.
